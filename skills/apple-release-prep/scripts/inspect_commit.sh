#!/usr/bin/env bash
# Build an investigation packet for one commit or PR, for working out what a
# vague commit message actually changed.
#
#   $SKILL/scripts/inspect_commit.sh aa21a85     # a commit sha
#   $SKILL/scripts/inspect_commit.sh 69          # a PR number
#
# The point is triage: separate the files that can change what a person sees
# from the ones that can't, and surface the patterns that usually correspond to
# visible behavior. The reading is still yours; this just cuts the search space.

set -uo pipefail

REF="${1:-}"
if [ -z "$REF" ]; then
  echo "usage: inspect_commit.sh <commit-sha|pr-number>" >&2
  exit 1
fi

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not in a git repo" >&2; exit 1; }
cd "$(git rev-parse --show-toplevel)" || exit 1

section() { printf '\n\n===== %s =====\n' "$1"; }

IS_PR=0
[[ "$REF" =~ ^[0-9]+$ ]] && IS_PR=1

HAVE_GH=0
command -v gh >/dev/null 2>&1 && HAVE_GH=1

section "WHAT THE AUTHOR SAID"
if [ "$IS_PR" -eq 1 ] && [ "$HAVE_GH" -eq 1 ]; then
  gh pr view "$REF" --json number,title,body,author,files \
    --template '#{{.number}} {{.title}} (@{{.author.login}}){{"\n\n"}}{{.body}}{{"\n"}}' \
    2>/dev/null || echo "(could not fetch PR $REF)"
else
  git show -s --format='%H%n%an%n%n%s%n%n%b' "$REF" 2>/dev/null || echo "(unknown ref)"
  # A squash-merged commit usually references its PR; the PR body is often the
  # only place the change was actually described.
  PRNUM="$(git show -s --format='%s%n%b' "$REF" 2>/dev/null | grep -oE '#[0-9]+' | head -1 | tr -d '#')"
  if [ -n "${PRNUM:-}" ] && [ "$HAVE_GH" -eq 1 ]; then
    echo
    echo "--- referenced PR #$PRNUM:"
    gh pr view "$PRNUM" --json title,body --template '{{.title}}{{"\n\n"}}{{.body}}{{"\n"}}' 2>/dev/null
  fi
fi

# Materialize the diff once.
DIFF="$(mktemp)"
trap 'rm -f "$DIFF"' EXIT
if [ "$IS_PR" -eq 1 ]; then
  if [ "$HAVE_GH" -eq 1 ]; then
    gh pr diff "$REF" >"$DIFF" 2>/dev/null
  fi
else
  git show "$REF" >"$DIFF" 2>/dev/null
fi
[ -s "$DIFF" ] || { echo; echo "(no diff available for $REF)"; exit 0; }

FILES="$(grep -E '^\+\+\+ b/' "$DIFF" | sed 's|^+++ b/||' | grep -v '^/dev/null$' | sort -u)"

# Show +/- lines matching a pattern, minus the ones that only moved or changed
# indentation. Re-indentation otherwise floods the string section — the most
# valuable signal here — with lines that did not actually change.
deltas() {
  local pattern="$1" limit="${2:-30}"
  grep -E '^[+-][^+-]' "$DIFF" \
    | grep -E "$pattern" \
    | awk '
        { body = $0; sub(/^[+-][ \t]*/, "", body); gsub(/[ \t]+/, " ", body)
          sign = substr($0, 1, 1)
          seen[body] = seen[body] sign
          order[NR] = body; line[NR] = $0 }
        END { for (i = 1; i <= NR; i++) {
                b = order[i]
                if (b == "" || printed[b]) continue
                # both a + and a - for identical content = a move, not a change
                if (seen[b] ~ /\+/ && seen[b] ~ /-/) { printed[b] = 1; continue }
                print line[i]
              } }' \
    | head -"$limit"
}

section "FILE TRIAGE"
echo "--- can change what a person sees:"
echo "$FILES" | grep -Ei \
  '\.(swift|strings|stringsdict|xcstrings|plist|entitlements|xcassets|json)$|Info\.plist|Localizable' \
  | grep -viE '(/Tests?/|Tests?\.swift$|Mock|Fixture|Preview)' || echo "  (none)"

echo
echo "--- build, tooling, or developer-facing:"
echo "$FILES" | grep -Ei \
  '\.(yml|yaml|xcconfig|pbxproj|resolved|toml|sh|rb)$|\.github/|fastlane/|Package\.swift' || echo "  (none)"

echo
echo "--- usually invisible:"
echo "$FILES" | grep -Ei '(/Tests?/|Tests?\.swift$|Mock|Fixture|Preview)|\.(md|txt)$' || echo "  (none)"

section "DIFFSTAT"
if [ "$IS_PR" -eq 1 ]; then
  grep -cE '^\+[^+]' "$DIFF" | sed 's/^/added lines: /'
  grep -cE '^-[^-]' "$DIFF" | sed 's/^/removed lines: /'
else
  git show --stat --oneline "$REF" 2>/dev/null | tail -40
fi

section "USER-FACING STRINGS ADDED OR REMOVED"
echo "The strongest signal available — these are literally the interface."
echo
deltas 'Text\(|Label\(|navigationTitle|navigationBarTitle|Button\("|\.alert\(|confirmationDialog|LocalizedStringKey|NSLocalizedString|String\(localized|placeholder|\.help\(|accessibilityLabel' 40 | grep . || echo "(none)"

section "NAVIGATION AND STRUCTURE"
deltas 'TabView|Tab\(|NavigationStack|NavigationSplitView|NavigationLink|\.sheet\(|\.popover|\.inspector|\.fullScreenCover|\.toolbar|ToolbarItem' | grep . || echo "(none)"

section "SEARCH, SORT, FILTER, FORMAT"
deltas '\.searchable|searchScopes|\.sorted|SortDescriptor|SortOrder|#Predicate|\.filter\(|DateFormatter|\.formatted|NumberFormatter|capitalized|localizedCapitalized|titlecase|uppercased|lowercased' | grep . || echo "(none)"

section "INTERACTION AFFORDANCES"
deltas 'swipeActions|contextMenu|\.refreshable|keyboardShortcut|onDrag|onDrop|Gesture|sensoryFeedback|hapticFeedback|\.focusable' | grep . || echo "(none)"

section "DEFAULTS, STATE, AND PERSISTENCE"
echo "Changed defaults or storage keys can reset user data on upgrade."
echo
deltas '@AppStorage|@SceneStorage|@Entry|@Model|@Observable|@Query|UserDefaults|ModelContainer|SchemaMigrationPlan|NSPersistentContainer|Codable|CodingKeys' | grep . || echo "(none)"

section "PLATFORM REACH"
echo "A change inside a platform conditional did not ship everywhere."
echo
deltas '#if os\(|#elseif os\(|@available|DEPLOYMENT_TARGET|targetEnvironment' | grep . || echo "(none)"

section "ASYNC AND LOADING BEHAVIOR"
deltas '\.task\(|onAppear|Task \{|async |await |debounce|Timer|cancel\(\)|URLCache|actor |@MainActor' 25 | grep . || echo "(none)"

section "NEXT STEP"
cat <<'EOF'
Read the flagged lines in the visible-bucket files. Classify each delta as
user-visible, review-relevant, or invisible. A large diff producing one visible
item is a normal and correct result — do not pad the notes to match the size of
the changeset.

If it stays ambiguous, ask one specific question with your best reading
attached rather than handing the question back.
EOF
