# The app baseline

Release work is downstream of a question nobody asks out loud: *what is this app, and who is it for?* Skip it and the output degrades in a specific, recognizable way — release notes written in the codebase's vocabulary instead of the reader's, a subtitle that describes a feature list instead of a purpose, keywords guessed from the category, and a description that could belong to any app in the section.

The baseline is also the only way to notice when a release breaks the listing. If the description advertises something this release removed, that's a finding — and it's invisible unless you know what the description says.

The important property: **what the app is changes far more slowly than what changed in it.** So build the profile once, store it, and refresh it on a rule rather than re-deriving it every release. Rebuilding it each time is wasted work; assuming a two-year-old profile still holds is worse.

## Where it lives

`.release-prep/app-profile.md` in the repo. Committing it is usually right — it's a description of the app, useful to anyone who works on it, and keeping it in version control means its history shows how the app's self-description drifted. If the user would rather not commit it, gitignore it; the skill works either way.

## Building it

Run `$SKILL/scripts/survey_app.sh`. It gathers the raw material — README, the `@main` app entry point, top-level navigation, target and platform settings, display name and bundle ID, persistence models, existing store metadata, and the App Store URL if one is discoverable — and prints it as a survey packet.

Then write the profile yourself from that packet. Don't have a script generate the prose: the valuable content is judgment (what this app is *for*, what it deliberately doesn't do), and a template filled from grep produces exactly the generic text the baseline exists to prevent.

Read the README and the top-level view hierarchy properly. Tab names, screen titles, and model type names are where an app's real vocabulary lives.

## What goes in it

Keep it to about a page. This is a working reference, not documentation.

**What it is.** One sentence a stranger would understand, with no internal terms. If you can't write it without listing features, you don't understand the app yet.

**Who uses it, and what they're doing when they open it.** The concrete situation, not a demographic. "An Airman who needs to check a specific paragraph of a publication, often on a phone, often without reliable signal" is usable; "military professionals" is not. Everything in the listing is written to this person.

**Platforms and floor.** Which targets ship, minimum OS per platform, and whether the iOS and macOS listings are separate. This decides whether release notes need to differ per platform.

**Main surfaces.** The tabs or top-level screens and what each is for. This is the map release notes get phrased against — "the Answers tab" means something to a reader only because this list exists.

**The app's own vocabulary.** What it calls the things it handles, taken from the UI rather than the code. Publications, not documents. Bookmarks, not favorites. Getting this wrong is the most common way release notes read as though written by someone who hasn't used the app — because they were.

**What it stores.** Bookmarks, caches, saved searches, settings, offline content. This is the list to check a release's data changes against; anything here is user data that a migration can destroy.

**Network and offline behavior.** What works without a connection, what syncs, what it talks to. Often the single most important claim in the listing for a utility app.

**What it deliberately doesn't do.** Scope boundaries the app has chosen — no account, no ads, no tracking, no sync, not a replacement for the official source. These are frequently the most valuable lines in a listing, and they're also the constraints that keep a description honest.

**Affiliations, disclaimers, and naming constraints.** Whether the app is officially affiliated with an organization whose material it handles, any required disclaimer, and trademarked terms that can't be used in the name, subtitle, or keywords. Getting this wrong in store text is a rejection and, for anything touching a government or institutional source, a real-world problem beyond the App Store. Record it once so every future release inherits it.

**Current listing text.** The live name, subtitle, promotional text, keywords, and the first two lines of the description. Store what's actually published, not what the repo thinks is published — those diverge whenever someone edits in App Store Connect directly. These are the values the submission packet carries through as `[unchanged]`, so a stale copy here becomes a wrong submission.

**Copyright line.** The rights holder and the year the rights were obtained — first publication, not the current year. Recording it stops it being wrongly bumped every January.

**Standing reviewer notes.** The things true of every submission: whether an account is needed and any demo credentials, where the app's content comes from and why it may show it, and any permission whose purpose isn't obvious. Each release adds only what's newly worth saying; this part is inherited.

**Profile metadata.** The app version the profile was built or last verified at, and the date. That's what makes the refresh rule work.

## Refreshing it

Check the recorded version against the release under review, and refresh when any of these hold:

- The release changes top-level navigation, adds or removes a surface, or renames one.
- The release changes what's stored, what works offline, or which platforms ship.
- The release changes the minimum OS version.
- The profile is more than a few minor versions old, or older than about six months.
- The user says the listing changed in App Store Connect.

Otherwise use it as-is and move on. A refresh that changes nothing is a cost with no benefit, and the point of caching this is to stop paying it every release.

When refreshing, update in place and note what changed — a profile whose history shows the app's self-description shifting is more useful than one that's silently overwritten.

## Using it

**Release notes.** Phrase every line in the app's vocabulary and against its surfaces. Check whether the fix reached all shipping platforms before writing notes that imply it did.

**General fields** — subtitle, keywords, description, promotional text. These describe the app, so they come from the profile; the release only decides *whether* they need revisiting. See `references/listing-voice.md`.

**The review.** Two checks that only the profile makes possible: did this release remove or rename something the current listing still advertises, and did it change anything in the "what it stores" list without a migration.
