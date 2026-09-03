# Investigating a vague commit

`feat: SwiftUI improvements` is not a description of anything. When a commit message won't support an honest changelog entry or release note, the answer is in the diff — but reading a diff for *what changed for a person* is a different job from reading it for correctness, and the default reading habit is the wrong one. Code review asks "is this right?" This asks "would anyone notice?"

Most lines in a typical Apple app diff answer no. The work is finding the few that answer yes.

## Get the right unit of change

The commit as it appears in the changelog may not be the real unit. Squash-merged PRs put an entire feature behind one message, so `aa21a85` and PR #69 are the same thing and the PR body often explains what the message didn't.

```
$SKILL/scripts/inspect_commit.sh aa21a85      # a commit
$SKILL/scripts/inspect_commit.sh 69           # a PR number
```

That produces an investigation packet: the PR title and body, the full diff, files bucketed by whether they can produce visible change, and the high-signal patterns pulled out. Read the PR body first — it's free and frequently answers the question outright.

If a merge commit brings in many commits, investigate the branch's commits rather than the squashed blob; the individual messages are often better than the merge's.

## Triage the files

Sort changed files into three buckets before reading any code. This is most of the speed.

**Can change what a person sees:** views, view models, navigation containers, string catalogs and `.strings` files, `Info.plist`, asset catalogs, entitlements, persistence models, networking and parsing, formatting and sorting helpers.

**Can change what an operator or developer sees:** logging, CI, build settings that don't affect behavior, dependency pins, generated project files.

**Almost never visible:** tests, docs, formatting-only churn, comments, access-level changes, file moves with no content delta.

A diff that's 90% the third bucket with one file from the first is the common shape of a "refactor with one real change buried in it," and finding that one file is the whole task. `git show --stat` sorted by the buckets above usually locates it in seconds.

## Read for behavior deltas

Within the visible-bucket files, these are the signals that reliably correspond to something a user experiences. Ordered by how much they usually mean.

**User-facing strings.** Added, removed, or reworded `Text`, `Label`, `navigationTitle`, button titles, alert and confirmation copy, empty-state and error messages, `LocalizedStringKey` entries. This is the strongest signal available, because these strings *are* the interface. A changed error message means the failure path changed. A new empty state means a case that previously showed nothing now explains itself.

**Navigation and structure.** Tabs added, removed, renamed, or reordered in a `TabView`; `NavigationStack` versus `NavigationSplitView`; sheets becoming pushes or inspectors; a screen that moved. Structural changes are always noticeable even when the code change looks small, because muscle memory breaks.

**Search and filtering.** `.searchable` placement determines which screens show the field and what it searches — moving that modifier up or down the view tree is a visible behavior change with a tiny diff. Same for scope bars, tokens, and any predicate change.

**Ordering, formatting, and defaults.** Sort comparators, date and number formatters, string casing, truncation, default values on `@AppStorage` or `@State`, initial selection. Cheap to change, immediately visible in a list.

**Interaction surface.** Swipe actions, context menus, toolbar items, keyboard shortcuts, pull-to-refresh, drag and drop, haptics. Adding or removing an affordance is a real feature change however it was committed.

**Async and loading behavior.** Task lifecycle, `.task` versus `.onAppear`, debouncing, coalescing concurrent work, cancellation, caching. These usually surface as "it's faster," "it stopped flickering," or "it no longer duplicates things" — worth a note when the old behavior was annoying enough to notice, not otherwise.

**Platform reach.** `#if os(iOS)` / `#if os(macOS)` boundaries and `@available` floors decide which app got the change. A fix inside a platform conditional did not ship everywhere, and notes implying it did are a small lie.

**State ownership and persistence.** `@Observable` migrations, `@Entry` environment defaults, `@Model` changes, `UserDefaults` keys. Usually invisible — but when the thing being stored is user data (bookmarks, favorites, saved searches), a changed default or key can mean state resets on upgrade. That is user-visible in the worst way, and it belongs in the review even when it doesn't belong in the notes.

**Accessibility.** Added labels, traits, Dynamic Type support, VoiceOver ordering. Visible to the people who need it, and worth naming for exactly that reason.

## Classify what you found

Each delta lands in one of three places:

- **User-visible** → eligible for the release notes, phrased as the difference not the change.
- **Review-relevant but not note-worthy** → data migration risk, platform asymmetry, a `fix:` that's actually breaking. Goes in the review, not the store text.
- **Invisible** → gets no line anywhere. Refactors, tests, and internal renames are not release notes, and dressing one up as a feature is how a listing acquires a claim nobody can support.

A big diff frequently produces one user-visible item and a lot of nothing. That result is correct, not a failed investigation — say so plainly rather than padding the notes to match the size of the changeset.

## When the diff genuinely doesn't settle it

Some changes are ambiguous from code alone: a layout rewrite where you can't tell whether the result looks different, a performance change where you can't tell if it's perceptible.

Ask a specific question with your best reading attached, rather than handing the question back:

> #69 moves the publication list views to `@Observable` and rebuilds the detail screen's layout. The only thing I can see changing for a reader is that the detail screen now shows the effective date under the title. Is that the visible change, or did the rebuild alter more than the diff makes obvious?

That is answerable in one line. "What did #69 do?" is not — it makes the person reconstruct work they already did, which is the thing this skill exists to avoid.

If it's not worth resolving — the change really is invisible — leave it out and say you did.

## Feed the finding back

Two follow-ups worth offering once, without lecturing:

**Fix the record where it's cheap.** The CHANGELOG entry in the release PR can be edited on the branch before merge, so a useless line can become a true one. Note the caveat: if release-please regenerates the PR (new commits landing on the base branch), the edit is overwritten, so re-check before merging. The tag and GitHub release inherit whatever the changelog says at merge time, so this is the last cheap moment to correct it.

**Name the pattern, not the person.** If several commits in one release needed investigating, that's a convention problem worth one sentence — a note that scoped messages describing the user-facing effect (`feat(search): search results now group by publication series`) remove this whole step next time. Once. Someone shipping a release does not need a process seminar.
