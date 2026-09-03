#!/usr/bin/env bash
# Assemble a review packet for a pending release-please PR in an Apple app repo.
#
#   $SKILL/scripts/collect.sh            # uses the PR for the current branch
#   $SKILL/scripts/collect.sh 74         # uses PR #74
#
# Every section is best-effort: missing tools or files produce a labeled note
# rather than a failure, because a partial packet you can see the gaps in is
# more useful than an abort.

set -uo pipefail

PR="${1:-}"

section() { printf '\n\n===== %s =====\n' "$1"; }
note() { printf '(%s)\n' "$1"; }

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not inside a git repository. Run from the app repo root."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT" || exit 1

HAVE_GH=0
command -v gh >/dev/null 2>&1 && HAVE_GH=1

section "PR METADATA"
if [ "$HAVE_GH" -eq 1 ]; then
  # shellcheck disable=SC2086
  gh pr view $PR --json number,title,headRefName,baseRefName,url,isDraft,mergeable,state \
    2>/dev/null || note "no PR found for this branch; pass a PR number"
else
  note "gh not installed — skipping PR metadata"
fi

section "PR DIFF (base -> head)"
echo "The release PR should ADD the new version heading and RAISE MARKETING_VERSION."
echo "If this diff shows the newest version being removed, it was taken in reverse."
echo
if [ "$HAVE_GH" -eq 1 ]; then
  # shellcheck disable=SC2086
  gh pr diff $PR 2>/dev/null || note "could not fetch PR diff"
else
  note "gh not installed — try: git diff main...HEAD"
fi

section "LAST RELEASE TAG"
LAST_TAG="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null)"
if [ -n "${LAST_TAG:-}" ]; then
  echo "$LAST_TAG"
else
  note "no tags found"
fi

section "COMMITS SINCE LAST TAG"
echo "Read these against the changelog. chore/refactor/style/perf commits are"
echo "invisible to release-please — check them for user-visible effects."
echo
if [ -n "${LAST_TAG:-}" ]; then
  git log --no-merges --pretty=format:'%h %s' "${LAST_TAG}..HEAD" 2>/dev/null \
    || note "could not list commits"
else
  git log --no-merges --pretty=format:'%h %s' -30
fi

section "DIFFSTAT SINCE LAST TAG"
if [ -n "${LAST_TAG:-}" ]; then
  git diff --stat "${LAST_TAG}..HEAD" 2>/dev/null || note "could not diff"
fi

section "VERSION FILES"
for f in Version.xcconfig .release-please-manifest.json release-please-config.json; do
  if [ -f "$f" ]; then
    echo "--- $f"
    cat "$f"
    echo
  fi
done
find . -name '*.xcconfig' -not -path './.git/*' 2>/dev/null | head -20

section "CHANGELOG (top 40 lines)"
[ -f CHANGELOG.md ] && head -40 CHANGELOG.md || note "no CHANGELOG.md"

section "BUILD NUMBER SOURCES"
echo "App Store Connect rejects uploads whose build number did not increase."
grep -rn 'CURRENT_PROJECT_VERSION' --include='*.xcconfig' --include='*.pbxproj' . 2>/dev/null | head -10
grep -rln 'agvtool\|CURRENT_PROJECT_VERSION\|bump.*build' .github/workflows fastlane 2>/dev/null | head -10

section "APPLE-SENSITIVE FILES PRESENT"
for f in $(find . \( -name 'PrivacyInfo.xcprivacy' -o -name '*.entitlements' -o -name 'Info.plist' \) -not -path './.git/*' 2>/dev/null | head -20); do
  echo "$f"
done

section "CHANGED SENSITIVE FILES SINCE LAST TAG"
if [ -n "${LAST_TAG:-}" ]; then
  git diff --name-only "${LAST_TAG}..HEAD" 2>/dev/null | grep -Ei \
    'Info\.plist|\.entitlements|PrivacyInfo|\.xcconfig|Package\.(swift|resolved)|\.pbxproj|Model\.xcdatamodeld|@Model' \
    || note "none"
fi

section "PERMISSION / PRIVACY SIGNALS IN THE DIFF"
if [ -n "${LAST_TAG:-}" ]; then
  git diff "${LAST_TAG}..HEAD" 2>/dev/null | grep -E '^\+' | grep -Ei \
    'import (CoreLocation|AVFoundation|Photos|EventKit|Contacts|CoreBluetooth|CoreMotion|AppTrackingTransparency|HealthKit)|NS[A-Za-z]+UsageDescription|DEPLOYMENT_TARGET|@Model|NSPersistentContainer|SchemaMigrationPlan|UserDefaults' \
    | head -30 || note "none"
fi

section "EXISTING STORE METADATA"
if [ -d fastlane/metadata ]; then
  find fastlane/metadata -type f -name '*.txt' | head -20
  echo
  echo "--- previous release notes, if any:"
  find fastlane/metadata -name 'release_notes.txt' -exec sh -c 'echo "[$1]"; cat "$1"' _ {} \; 2>/dev/null | head -40
else
  note "no fastlane/metadata — release notes will be presented in chat"
fi

section "END OF PACKET"
