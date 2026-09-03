# Apple release gates

The checks that don't show up in a changelog and cost either a rejected upload, a rejected review, or a bad release. Ordered roughly by how often they bite.

Not all of these apply to every release. Skip the ones the diff gives no reason to look at — running all nine every time is how a review turns into a checklist nobody reads.

## Build number

`MARKETING_VERSION` is the number humans see (4.7.0). `CURRENT_PROJECT_VERSION` is the build number, and App Store Connect rejects an upload whose build number isn't higher than every previous upload for that marketing version.

Release-please only manages what its `extra-files` config points at, which is normally the marketing version. So check what bumps the build number: CI (`agvtool`, an `xcodebuild` setting, a GitHub Action step), or a human, or nobody. "Nobody" is the finding — it fails at upload time, after the merge and the tag, which is the most annoying moment to discover it.

## Permission usage strings

Any new API touching camera, microphone, location, contacts, photos, calendar, local network, Bluetooth, tracking, or motion needs its `NS*UsageDescription` key in the Info.plist or build settings. Missing it means the app crashes on first use of that API — and App Review will find it.

In the diff, look for new imports of `CoreLocation`, `AVFoundation`, `Photos`, `EventKit`, `Contacts`, `CoreBluetooth`, `CoreMotion`, `AppTrackingTransparency`, or a new `Network` framework usage that hits the local network. Then check whether the corresponding key exists.

Also worth flagging: an existing usage string that no longer matches what the app does with the data. Review reads those strings.

## Privacy manifest

`PrivacyInfo.xcprivacy` declares collected data types and the reason codes for "required reason" APIs — file timestamps, disk space, system boot time, active keyboards, `UserDefaults`. New use of those APIs, or a new third-party SDK, means the manifest needs updating. Apple emails about this after upload rather than blocking it, so it silently accumulates.

## Deployment target

A raised deployment target in an `xcconfig` or `.pbxproj` cuts off existing users on older OS versions. That is a breaking change no matter what the commit prefix says, and it belongs in the release notes — people whose device stops getting updates deserve to know why. Look for `IPHONEOS_DEPLOYMENT_TARGET`, `MACOSX_DEPLOYMENT_TARGET`, and any new `@available` floors.

## Persistence migrations

For a shipped app this is the one that does real damage. SwiftData `@Model` changes, Core Data model versions, a changed `Codable` shape written to disk, a renamed `UserDefaults` key, a changed App Group container path — any of these can silently discard user data on upgrade.

Additive changes with defaults are usually safe. Renames, type changes, removed properties, and changed relationships are not, unless there's a migration plan (`SchemaMigrationPlan`, a mapping model, or explicit handling in the decoder). Absence of a migration is worth naming even when it turns out to be fine — being wrong here is expensive and being asked is not.

Bookmarks, favorites, saved searches, and offline caches are the usual casualties.

## Entitlements and capabilities

New entitlements (App Groups, iCloud, push, HealthKit, network extensions, hardened-runtime exceptions on macOS) need a matching provisioning profile and, on macOS, may need sandbox exceptions. A capability added in Xcode but not reflected in the entitlements file, or vice versa, fails at signing or at runtime.

## Platform asymmetry

For a shared iOS/macOS codebase, ask which targets each change actually reached. A fix behind `#if os(iOS)` doesn't ship to the Mac, and release notes that imply it did are a small lie that generates support mail. The macOS and iOS listings are separate anyway, so notes may need to differ.

## Feature removal versus the current listing

If the release removes or renames something the App Store description, subtitle, keywords, or screenshots still advertise, the listing is now wrong. Screenshots in particular: a redesigned tab means the screenshots show an app that no longer exists, and that's both a review risk and a bad first impression.

## Review-guideline risk

Worth a look when the release adds: external payment or subscription flows, account creation without a delete-account path, user-generated content without moderation and reporting, third-party login as the only option, ads or tracking, or anything reachable that looks like a beta. Most releases have none of this; when one does, it's better raised before submission than after a rejection.
