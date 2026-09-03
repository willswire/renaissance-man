#!/usr/bin/env bash
# Survey an Apple app repo to build (or refresh) the baseline app profile.
#
#   ./survey_app.sh
#
# Prints a survey packet: the README, the app entry point, top-level navigation,
# platform and target settings, vocabulary signals, persistence, and any store
# metadata already in the repo. Write the profile from this by hand — the value
# is in the judgment, and a template filled from grep produces exactly the
# generic text the profile exists to prevent.

set -uo pipefail

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not in a git repo" >&2; exit 1; }
cd "$(git rev-parse --show-toplevel)" || exit 1

section() { printf '\n\n===== %s =====\n' "$1"; }
swift_src() {
  find . -name '*.swift' -not -path './.git/*' -not -path '*/.build/*' \
    -not -path '*/Pods/*' -not -path '*/DerivedData/*' \
    -not -path '*/Tests/*' -not -path '*Tests/*' -not -path '*/Fixtures/*' \
    -not -name '*Tests.swift' -not -name '*Test.swift' -not -name '*Mock*.swift' \
    -not -name '*Preview*.swift' 2>/dev/null
}

section "EXISTING PROFILE"
if [ -f .release-prep/app-profile.md ]; then
  cat .release-prep/app-profile.md
  echo
  echo "(refresh this in place rather than starting over)"
else
  echo "(none — this is a first build)"
fi

section "README"
for f in README.md readme.md docs/README.md; do
  [ -f "$f" ] && { head -80 "$f"; break; }
done

section "APP ENTRY POINT"
grep -rln '@main' --include='*.swift' . 2>/dev/null | grep -vE '/(Tests?|Fixtures)/' | head -3 | while read -r f; do
  echo "--- $f"
  sed -n '1,60p' "$f"
  echo
done

section "TOP-LEVEL NAVIGATION (the app's surfaces)"
echo "Tab labels and screen titles are where the app's real vocabulary lives."
echo
swift_src | xargs grep -hE 'TabView|Tab\(|\.tabItem|navigationTitle|NavigationSplitView|Label\("' 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u | head -40 || echo "(none found)"

section "SCREEN AND VIEW INVENTORY"
swift_src | xargs grep -hoE 'struct [A-Za-z]+(View|Screen|Tab)\b' 2>/dev/null \
  | sort -u | head -40 || echo "(none found)"

section "DISPLAY NAME, BUNDLE ID, PLATFORMS"
grep -rhE 'PRODUCT_NAME|PRODUCT_BUNDLE_IDENTIFIER|INFOPLIST_KEY_CFBundleDisplayName|IPHONEOS_DEPLOYMENT_TARGET|MACOSX_DEPLOYMENT_TARGET|SUPPORTED_PLATFORMS|MARKETING_VERSION|CURRENT_PROJECT_VERSION' \
  --include='*.xcconfig' --include='*.pbxproj' . 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u | head -30 || echo "(none found)"

section "PLATFORM CONDITIONALS IN USE"
echo "Shows whether iOS and macOS meaningfully diverge."
echo
swift_src | xargs grep -hoE '#if os\([A-Za-z]+\)' 2>/dev/null | sort | uniq -c | sort -rn | head -10 || echo "(none)"

section "WHAT IT STORES"
echo "Anything here is user data a migration can destroy."
echo
swift_src | xargs grep -hE '@Model|@AppStorage|@Query|UserDefaults\.|ModelContainer|NSPersistentContainer|FileManager\.default\.urls|\.appGroup|Keychain' 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u | head -30 || echo "(none found)"

section "NETWORK AND OFFLINE BEHAVIOR"
swift_src | xargs grep -hE 'URLSession|URLCache|baseURL|https://|NWPathMonitor|\.cachePolicy|offline' 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u | head -25 || echo "(none found)"

section "PERMISSIONS DECLARED"
grep -rhE 'NS[A-Za-z]+UsageDescription' --include='*.plist' --include='*.xcconfig' --include='*.pbxproj' . 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u | head -20 || echo "(none — the app asks for no sensitive permissions)"

section "DEPENDENCIES"
[ -f Package.swift ] && grep -E '\.package\(' Package.swift | head -20
find . -name 'Package.resolved' -not -path './.git/*' 2>/dev/null | head -2 | while read -r f; do
  grep -oE '"(identity|package)" : "[^"]+"' "$f" 2>/dev/null | head -20
done

section "STORE METADATA IN REPO"
if [ -d fastlane/metadata ]; then
  find fastlane/metadata -name '*.txt' | while read -r f; do
    echo "--- $f"
    head -6 "$f"
    echo
  done
else
  echo "(no fastlane/metadata — the live listing is the source of truth; ask the user"
  echo " for the current name, subtitle, keywords, and first lines of the description)"
fi

section "APP STORE / DISTRIBUTION LINKS"
grep -rhoE 'https://apps\.apple\.com/[^ ")]+' --include='*.md' --include='*.swift' --include='*.json' . 2>/dev/null | sort -u | head -5 || echo "(none found)"

section "AFFILIATION AND DISCLAIMER SIGNALS"
echo "Check these before writing any store text — a wrong affiliation claim is a"
echo "rejection, and for institutional or government material it is worse than that."
echo
grep -rhiE 'not affiliated|disclaimer|official|endorsed|trademark|©|all rights reserved' \
  --include='*.md' --include='*.swift' --include='*.txt' . 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u | head -15 || echo "(none found — ask the user)"

section "NEXT STEP"
cat <<'EOF'
Write .release-prep/app-profile.md from this packet, following this skill's
references/app-baseline.md. Record the app version and date at the top so the
refresh rule works.

The two lines worth the most effort: what the app is, in one sentence with no
internal terms; and who opens it, in what situation. If either needs a feature
list to write, read the README and the main views again before drafting.

Anything the packet can't answer — the live listing text, affiliation
constraints, what the app deliberately doesn't do — ask the user once, and
record the answers so no future release has to ask again.
EOF
