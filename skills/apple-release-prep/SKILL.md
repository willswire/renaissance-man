---
name: apple-release-prep
description: Review a pending release-please pull request for an iOS/macOS/visionOS app and write the App Store listing text for that release. Use this whenever the user mentions a release PR, a release-please branch, a pending version bump, reviewing the CHANGELOG before shipping an Apple app, "What's New" text, App Store release notes, promotional text, subtitle, or keywords — and also when they ask you to look over a release before they tag it, cut a release, or submit a build to App Store Connect, even if they never say "release-please" or "App Store" explicitly. Covers verifying the version bump and changelog against what actually changed, catching Apple-specific release risks (build number, permission strings, privacy manifest, data migrations), and drafting truthful, restrained listing copy.
---

# Apple Release Prep

Two jobs on one body of evidence: decide whether a release-please PR is safe to merge, and write the store text for the release it produces. They share their groundwork — knowing what the app is, then what changed in it — so do them in one pass rather than reconstructing the release twice.

The reason this is worth a skill at all: **release-please's changelog is a function of commit messages, not of the diff.** Everything downstream inherits that. A user-visible change committed as `refactor:` vanishes from the changelog, from the version bump math, and then from the release notes — and the first person to notice is a customer whose workflow changed with no explanation. The review exists to catch what the commit messages failed to say.

## Running the bundled scripts

This skill ships four scripts, and they live with the skill rather than in the app repo. Invoke them by their full path — `$SKILL/scripts/collect.sh`, where `$SKILL` is this skill's own directory (`${CLAUDE_PLUGIN_ROOT}/skills/apple-release-prep` when it loads as part of the renaissance-man plugin). Stay in the app repo while doing so: every script locates the repo from the working directory, and each one is best-effort, so a missing tool produces a labeled gap rather than a failure.

## Phase 1 — Know the app

Start every release with the baseline, not the diff. A release note is a sentence about an app, and written without knowing what the app is it comes out in the codebase's vocabulary rather than the reader's — the failure mode is recognizable and it starts here, not at drafting time.

Read `.release-prep/app-profile.md` if it exists. If it doesn't, build it: run `$SKILL/scripts/survey_app.sh` and follow `references/app-baseline.md`. It records what the app is, who opens it and why, its surfaces and its own vocabulary, what it stores, what it deliberately doesn't do, any affiliation or disclaimer constraints, and the current live listing text.

This is a cached artifact on purpose. What the app *is* changes far more slowly than what changed in it, so build it once and refresh it on the rule in the reference — top-level navigation changed, storage or platform support changed, minimum OS moved, or it's gone stale. Re-deriving it every release is wasted work; trusting a two-year-old profile is worse. Check the version it records against the one under review and decide in a few seconds.

The profile also earns its keep in the review itself: it's what makes "this release removed something the description still advertises" and "this release changed something in the stored-data list" visible at all.

## Phase 2 — Gather the release evidence

Run `$SKILL/scripts/collect.sh` from anywhere inside the app repo. It assembles a review packet: PR metadata, the PR diff, the commits between the last release tag and the PR head, the version files, and pointers to Apple-specific files worth checking. Pass a PR number if the branch isn't checked out (`$SKILL/scripts/collect.sh 74`).

If the tooling isn't available (no `gh`, no repo, user pasted a diff into chat), work from what you have and say plainly which checks you couldn't run. A partial review labeled as partial is useful; a full-sounding review built on half the evidence is not.

**Confirm the diff direction before reading anything into it.** A release PR *adds* a new version heading to the CHANGELOG and raises `MARKETING_VERSION`. If the diff shows the newest version being removed and the version number going down, it was taken in reverse (`head..base`); mentally invert it, and say so. Reviewing a reversed diff produces confident nonsense about a downgrade.

## Phase 3 — Review the release PR

Release-please generated this PR mechanically, so the file changes themselves are rarely where the problem is. Read them for consistency, then spend most of the effort on the gap between what the commits say and what the code did.

**Consistency** (fast, mechanical):
- `.release-please-manifest.json`, `Version.xcconfig`'s `MARKETING_VERSION`, and the new CHANGELOG heading all name the same version.
- The `x-release-please-start-version` / `-end` markers in `Version.xcconfig` are intact. If someone hand-edited the version, the markers drift and future releases silently stop updating the file.
- The compare link in the changelog heading points from the actual previous tag.

**Semver honesty** — the bump comes from commit prefixes, not from behavior. Read the commits and ask whether the prefix told the truth:
- A `fix:` that removes or changes behavior someone depended on is a minor or major change wearing a patch label.
- A `feat:` that drops a feature, changes a data format, or raises the minimum OS version is a breaking change.
- `chore:`, `refactor:`, `style:`, `perf:` are invisible to release-please. Scan those commits specifically for user-visible effects. This is the highest-yield check in the whole review.

**The changelog against the diff.** Walk the commits between tags and ask: is there a user-visible change here that no changelog line covers? And the reverse: does any changelog line describe something the diff doesn't support?

**Investigate the commits whose messages don't say anything.** `feat: SwiftUI improvements` is not evidence — it neither justifies its version bump nor supports a release note, and taking it at face value propagates the vagueness all the way to the store listing. Run `$SKILL/scripts/inspect_commit.sh <sha-or-PR#>` and follow `references/investigating-commits.md` to work out what actually changed. Do this during the review rather than later, because the answer often changes the review itself: the vague commit is where mis-typed semver, a silent platform-conditional fix, and an unnoticed data-default change tend to hide.

**The release against the listing.** Using the profile: did this release remove, rename, or redesign anything the current listing text or screenshots still advertise? And did it change anything in the profile's stored-data list without a migration? Both are silent failures — nothing in the diff flags them, and the first report comes from a confused customer.

**Apple release gates.** These are the ones that cost a rejected build or a bad review, and none of them are visible in the changelog. Read `references/apple-release-checks.md` for what each one looks like and why it bites. In short: build number, new permission usage strings, privacy manifest, deployment target, entitlements, persistence migrations, and platform asymmetry between the iOS and macOS targets.

**Delivering the verdict.** Lead with one of: ship, ship after fixing X, or hold. Then the one or two findings that actually change that decision — not a catalogue. If six things surfaced and four are cosmetic, the four are noise and burying the real one under them is a failure of the review, not thoroughness. "This is clean, merge it" is a complete and frequently correct review; say it and stop.

Findings should name the file or commit and what to do, so the fix doesn't require re-deriving the analysis.

## Phase 4 — Produce the submission packet

The deliverable is every App Store Connect field for this version, in one place, so the person shipping can work straight down it without deciding what still needs writing. Emit the full set every time — including the fields that didn't change — and mark each one, because "unchanged" is information the submitter needs and a silently omitted field reads as an oversight.

Read `references/listing-voice.md` before drafting — it carries the voice, the field rules, and worked examples. The three that matter most: write what a person gets rather than what the commit did; every line traces to a commit, or to what Phase 3's investigation established the commit actually did, never to a guess about what a vague message probably meant; and decide the length before writing, since release notes have no natural stopping point and a bullet per commit is the default failure.

Use this structure:

```
## App Store submission — <App Name> <version>

**Version number** — <from the release PR>
**Copyright** — <holder, year rights obtained>            [unchanged]

**Name** (n/30) — <text>                                   [unchanged | revised]
**Subtitle** (n/30) — <text>                               [unchanged | revised]
**Promotional text** (n/170) — <text>                      [unchanged | revised]
**Keywords** (n/100) — <comma,separated,no,spaces>         [unchanged | revised]

**Description** (n/4000)                                   [unchanged | revised]
<text>

**What's New in This Version** (n/4000)
<text>

**Notes for reviewer** (n/4000)                            [omit if nothing to say]
<text>
```

Character counts go inline as shown — the submitter shouldn't have to check them, and an over-limit field is rejected or silently truncated at submission. Run `$SKILL/scripts/check_limits.py` on the packet rather than counting by hand.

**What changes per release, and what doesn't.** Version number and What's New are always new. Reviewer notes are release-specific when they exist. The rest — name, subtitle, promotional text, keywords, description, copyright — describe the app, come from the profile, and stay put unless the release changed what the app is or the review found the listing now advertises something that no longer exists. Mark those `[unchanged]` and carry the current value through verbatim; revising store text for its own sake costs a review cycle and buys nothing.

If the app ships more than one localization, repeat name, subtitle, promotional text, keywords, description, and What's New per locale, and say plainly if you are supplying only the source locale. Copyright and version number are not localized.

**Writing to disk.** If `fastlane/metadata/` exists, write the fields to their files and name the paths: per-locale text goes in `fastlane/metadata/<locale>/` as `name.txt`, `subtitle.txt`, `promotional_text.txt`, `keywords.txt`, `description.txt`, `release_notes.txt`; `copyright.txt` sits at the `fastlane/metadata/` root since it isn't localized; reviewer notes go in `fastlane/metadata/review_information/notes.txt`. Otherwise present the packet in chat for pasting.

## Working with the user

Show the review before the copy. If the review turns up something that changes what the release *is* — a missing changelog entry, a mis-typed commit — the notes are downstream of that and shouldn't be drafted twice.

When the repo has a history of previous What's New text (`fastlane/metadata/`, past GitHub releases, the current App Store listing), read a couple before drafting. Matching an existing voice beats importing one.

Ask about the app itself only when building or refreshing the profile, and record the answers there. The point of the baseline is that a release is not the moment to be asking what the app does — and nobody should be asked twice.

## Reference files

- `references/app-baseline.md` — what the cached app profile holds, how to build it, and when to refresh it. Read in Phase 1 whenever the profile is missing or stale.
- `references/apple-release-checks.md` — the Apple-specific gates, what each looks like in a diff, and why it matters. Read during Phase 3.
- `references/investigating-commits.md` — how to read a diff for user-visible behavior when the commit message won't say. Read whenever a commit is too vague to review or to write a note from.
- `references/listing-voice.md` — voice, the full field list with limits and localization, copyright and reviewer-notes rules, worked before/after examples. Read before drafting in Phase 4.
