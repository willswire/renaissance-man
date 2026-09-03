# Listing voice and fields

## The stance

Store text is a claim made to a stranger who can immediately check it against the app. That single fact settles most questions of style. Overclaim and the next screen contradicts you. Pad and the reader learns to skip your notes. Say what changed and stop, and people start reading them.

The reader is a person mid-task, not a "user" and not an audience. For a reference or utility app, they opened the store page because something was broken or they wanted to know if it's fixed. Answer that.

**The default failure is length, not dullness.** Release notes have no natural stopping point — every commit volunteers itself as a bullet. Decide how long the notes should be before writing them, based on what actually changed for someone, not on how much work the release took. A release with two things worth mentioning gets two lines. Effort spent is not a story the reader is interested in.

## Voice rules

**Say what a person gets.** The commit describes the fix; the note describes the difference.
- Commit: `fix(search): scope the search field to the Search tab`
- Note: Search stays on the Search tab now instead of following you between tabs.

**Plain verbs, present tense, active voice.** "Search stays put." "Titles read correctly." Not "has been improved," "we have enhanced," "users can now enjoy."

**Every line traces to a commit.** If the commit message is too vague to write a truthful line — "SwiftUI improvements," "misc fixes" — read the diff. If the diff doesn't settle it, ask. Inventing a plausible benefit is how a listing acquires a claim nobody can support, and it's worse than saying less.

**Group the invisible fixes.** A fix for something no one could have noticed doesn't earn its own line. One honest sentence covers them: "Fixed several issues with loading and bookmarks." Name a fix individually only if a user could have hit it and would recognize the description.

**Order by what the reader cares about**, not by commit type and not by size of change. The annoying bug everyone hit outranks the feature three people asked for.

**Don't manufacture significance.** If the release is genuinely small, small notes are the honest output. "Bug fixes and performance improvements" is a cliché because it's usually a lie about a large release; as a description of an actually-small release it's fine, though naming the fixes is better.

**Don't inflate categories.** A bug fix is not a new feature. A refactor that changed nothing visible gets no line at all — the release notes are not a report on the work.

**Keep the internals out.** No commit hashes, PR numbers, issue links, framework names, or internal component names. "Rebuilt the Answers tab" is fine; "migrated AnswersTab to @Observable" is not.

**Avoid:** exclamation marks, superlatives (seamless, powerful, beautiful, delightful, blazing), "we're excited to announce," "under the hood," emoji (unless the app's existing notes use them), and second-person promises about how the reader will feel.

**Sign of a good draft:** someone who used the previous version can read it in fifteen seconds and know whether the thing that bothered them is fixed.

## Field limits

| Field | Limit | Localized | Changes per release? |
|---|---|---|---|
| Version number | — | No | Always — from the release PR |
| What's New | 4000 | Yes | Always. Aim well under 600. |
| Notes for reviewer | 4000 | No | When there's something to say |
| Promotional text | 170 | Yes | Optional; editable without a new version |
| Name | 30 | Yes | Rarely — a rename is a rebrand |
| Subtitle | 30 | Yes | Rarely |
| Keywords | 100 | Yes | Rarely |
| Description | 4000 | Yes | Rarely |
| Copyright | — | No | Only if ownership changed |

Run `$SKILL/scripts/check_limits.py` on anything produced. Over-limit fields get rejected or silently truncated, and it's a two-second check.

Keywords, when they do need attention: don't repeat words already in the app name or subtitle (Apple indexes those separately), don't include the category name, don't use plurals when the singular is indexed, skip conjunctions and spaces to reclaim characters. Competitor and trademarked names are a rejection risk.

## The general fields

Subtitle, keywords, description, and promotional text describe the app, not the release, so they come from the app profile (`references/app-baseline.md`) rather than from the diff. Write them against the profile's "what it is" and "who opens it" lines — if those two are right, these fields nearly write themselves, and if they're vague these fields will be too.

**Subtitle (30).** What the app is for, not a feature list. The name already said what it's called; this says why someone would open it. Don't repeat words from the name — they're indexed separately, so repeating them wastes both the characters and the search coverage.

**Description.** The first two lines show before the "more" cut, and most readers never expand. Put the profile's one-sentence answer there, then what the app does, then — often the most persuasive part for a utility app — what it deliberately doesn't do. No account, no ads, no tracking, works offline: these are real differentiators and they're checkable, which is what makes them land.

Where the profile records an affiliation constraint or required disclaimer, it goes in the description and it is not optional. Implying an official relationship the app doesn't have is a rejection, and for anything handling institutional or government material the problem outlives the App Store.

**Keywords (100).** Draw from the profile's vocabulary section and from the words the intended reader would actually type — including the ones the app doesn't use itself, since people search for what they call the thing. Skip words already in the name or subtitle, skip the category name, skip plurals where the singular is indexed, no spaces after commas. Competitor and trademarked terms are a rejection risk.

**Promotional text (170).** One true sentence about the app as it is today. It's editable without a review submission, which makes it tempting to use for release announcements — resist that, since it outlives the release and a stale announcement is worse than a stable description.



### Release notes — a mixed feature-and-fix release

Given these commits: SwiftUI improvements; Answers tab improvements; stabilize `@Entry` default for BookmarkTracker; coalesce concurrent refreshes into a single import; scope search field to the Search tab; macOS UI fixes; title-case publication titles.

**Bad — the generic App Store draft:**

> We're excited to bring you version 4.7.0! ✨ This release includes a beautifully refreshed SwiftUI experience, an enhanced Answers tab, improved bookmark stability, and various performance optimizations under the hood to make your experience even better. Thanks for using the app!

Nothing here is checkable. "Enhanced," "improved," and "optimizations" describe effort, not outcomes. The reader who came to see whether their bookmark bug is fixed can't tell.

**Bad in the other direction — a bullet per commit:**

> • SwiftUI improvements
> • AnswersTab improvements
> • Stabilize @Entry default for BookmarkTracker
> • Coalesce concurrent refreshes into a single import
> • Scope the search field to the Search tab
> • macOS fixes
> • Title-case publication titles

This is the changelog, not the notes. It leaks internal names, gives equal weight to everything, and asks the reader to translate.

**Good:**

> Search now stays on the Search tab instead of following you around the app.
>
> Publication titles are title-cased, so they're readable at a glance.
>
> The Answers tab has been rebuilt, and the Mac app got a round of interface fixes.
>
> Also fixed: bookmarks occasionally losing their state, and pulling to refresh several times in a row importing the same publications twice.

Four lines, ordered by who's affected, no internal vocabulary, each traceable to a commit. Note the two vague `feat:` commits ("SwiftUI improvements," "AnswersTab improvements") produced exactly one modest clause between them — because that's all the commit messages supported. If the diff showed something specific, the line should say it.

### Promotional text

**Bad:** The most powerful publication reference app on the App Store — now faster and more beautiful than ever!

**Good:** Search and read Air Force publications offline, with bookmarks that stay put.

170 characters is enough for one true sentence about what the app does today. It's the wrong place for a release announcement, since it outlives the release.

### When a release has nothing user-visible

Dependency bumps, CI changes, and internal refactors still produce a version. Say so:

> Internal updates and preparation for upcoming changes. No changes to how the app works.

Honest, short, and it costs nothing. Manufacturing a feature out of a refactor costs credibility with the readers who check.
