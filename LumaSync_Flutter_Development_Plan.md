# LumaSync --- Flutter-Only Product & Engineering Plan

**Project:** LumaSync\
**Target devices:** iQOO Neo 9 Pro (sender) → Redmi Note 7 Pro running
Pixel OS (receiver)\
**Primary goal:** Automatically transfer newly captured camera photos
and videos from the sender to the receiver over local Wi-Fi, save them
to the receiver's camera roll, and let Google Photos back up that folder
using the receiver's existing backup settings.

**Implementation constraint:** The application code must be Flutter/Dart
only. Do not write custom Kotlin or Java. Flutter plugins may use native
Android code internally; that is acceptable, provided LumaSync's own
application and feature logic remains in Dart.

------------------------------------------------------------------------

## 1. Product requirements

### 1.1 Sender phone --- iQOO Neo 9 Pro

-   Scan the camera media library, including photos and videos.
-   Identify newly added camera media since the previous scan.
-   Keep every original photo and video on the sender phone.
-   Never automatically delete sender files.
-   Maintain a persistent inventory with clear statuses:
    -   **Pending:** not yet transferred.
    -   **Transferred:** successfully received and verified by the
        receiver.
    -   **Failed:** transfer did not complete; eligible for retry.
    -   **Skipped:** user excluded it or it was already present on the
        receiver.
-   Show transferred and pending items separately in the app.
-   Allow the user to manually delete selected transferred items from
    the sender phone, only after an explicit confirmation.
-   Never delete pending, failed, or unverified items through a bulk
    cleanup action.
-   Support a daily scheduled transfer at a user-selected time.
-   Also support a manual **Transfer now** action.
-   Enforce a configurable daily transfer limit, default **100 photos and
    5 videos per day** (counted from local midnight). It applies to manual
    and scheduled transfers; newest pending items go first and the rest
    wait for the next day. Either limit can be set to "no limit".

### 1.2 Receiver phone --- Redmi Note 7 Pro / Pixel OS

-   Receive files from the paired sender over local Wi-Fi.
-   Save completed photos and videos into public media folders so
    Android's media scanner and Google Photos can discover them:
    -   Photos: `DCIM/Camera/`
    -   Videos: `DCIM/Camera/`
-   Use Android's supported media-storage APIs through a suitable
    Flutter plugin.
-   Do not require the user to manually import each received file.
-   Do not change or falsify the originating camera make/model to
    impersonate another phone or to bypass Google Photos storage
    eligibility.
-   Preserve original capture date/time, GPS when present, orientation,
    image/video bytes, and other metadata by default.
-   Show received-file count, total size, failed files, and last
    successful sync.
-   Avoid duplicate copies when a file is retransmitted.

### 1.3 Google Photos

The app's responsibility ends after safely publishing the received media
into the receiver's camera roll and confirming it is visible to
Android's media library.

Google Photos backup is controlled by Google Photos and the user's
account/device settings. LumaSync must not claim that a file
qualifies for unlimited storage based on edited metadata or guarantee a
particular Google Photos storage entitlement.

------------------------------------------------------------------------

## 2. Important feasibility constraints

### 2.1 Flutter-only does not mean Android has no native components

Flutter/Dart can contain all LumaSync product logic. However, Wi-Fi
discovery, Android media access, background scheduling, notifications,
and foreground execution are exposed through Flutter plugins that
internally bridge to Android APIs.

**Do not create custom Kotlin/Java files.** Select and validate
maintained Flutter plugins for each capability. If a required capability
has no reliable plugin, document the limitation rather than silently
adding native application code.

### 2.2 Daily scheduled transfer is best-effort on Android

Android may defer background work because of Doze, battery optimization,
app standby, manufacturer power management, missing network, or the
receiver being unavailable.

Use a maintained Flutter background-work plugin backed by Android
WorkManager for periodic scheduling. WorkManager periodic work has a
minimum repeat interval of 15 minutes and is not an exact alarm clock. A
daily 8:00 PM schedule means **run at or after the selected time when
Android permits**, not a guaranteed start at exactly 8:00 PM.

For dependable operation: - Ask the user to exempt LumaSync from
battery optimization where the OS offers that option, explaining the
trade-off. - Keep the app's schedule enabled and persist it across
restarts. - Require both devices to be powered on, reachable on the same
local network, and sufficiently charged. - If the receiver is not
available, keep files pending and retry at the next eligible run. - Show
the last scheduled attempt, last successful transfer, and next planned
run. - Do not promise unattended transfer after force-stop; Android can
prevent scheduled work until the user opens the app again. - Do not use
exact-alarm permission unless a future, justified product requirement
truly needs an exact alarm and the permission is appropriate.

### 2.3 Receiver availability

A scheduled sender cannot guarantee delivery if the Redmi is offline,
disconnected from Wi-Fi, asleep with networking restricted, or
LumaSync is force-stopped.

Design the receiver with two modes: 1. **Ready to receive:** user opens
LumaSync and enables receiver availability. 2. **Scheduled receiver
availability:** use only a plugin-backed Android background mechanism
proven to work on the target ROM and Android version. If reliable
background advertising is not possible, clearly require the receiver app
to be open for scheduled transfers.

The MVP should work with both apps open. Add background receiver support
only after device testing.

------------------------------------------------------------------------

## 3. Recommended Flutter architecture

Use a feature-first architecture with clear separation between UI,
application logic, storage, and plugin adapters.

``` text
lumasync/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── docs/
│   ├── architecture.md
│   ├── permissions.md
│   ├── testing.md
│   └── device-compatibility.md
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   ├── core/
│   │   ├── errors/
│   │   ├── logging/
│   │   ├── permissions/
│   │   ├── platform/
│   │   └── utils/
│   ├── data/
│   │   ├── database/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── plugin_adapters/
│   ├── features/
│   │   ├── onboarding/
│   │   ├── pairing/
│   │   ├── media_library/
│   │   ├── transfer/
│   │   ├── schedule/
│   │   ├── transfer_history/
│   │   ├── cleanup/
│   │   └── settings/
│   └── services/
│       ├── media_scan_service.dart
│       ├── device_connection_service.dart
│       ├── transfer_orchestrator.dart
│       ├── integrity_service.dart
│       ├── schedule_service.dart
│       └── receiver_storage_service.dart
└── test/
    ├── unit/
    ├── integration/
    └── fixtures/
```

### Architecture principles

-   Use Riverpod for state management and dependency injection.
-   Use GoRouter for navigation.
-   Use Drift (SQLite) for durable local state and transfer history.
-   Keep plugin-specific APIs behind interfaces so packages can be
    replaced.
-   Use streams for transfer progress and connection state.
-   Use isolates for CPU-intensive hashing if profiling shows UI jank.
-   Never load an entire video or large image into memory; stream files
    in bounded chunks.
-   Keep the same application package ID on both devices; choose Sender
    or Receiver role during onboarding.

------------------------------------------------------------------------

## 4. Flutter package selection

Before implementation, Claude Code must check current package
maintenance, Android support, license, API compatibility, and known
issues. Do not assume a package is suitable merely because it exists on
pub.dev.

Candidate packages:

  -------------------------------------------------------------------------------
  Capability              Candidate                       Notes
  ----------------------- ------------------------------- -----------------------
  State management        `flutter_riverpod`              Application state

  Navigation              `go_router`                     Navigation

  Local database          `drift`                         Inventory, sessions,
                                                          schedules

  SQLite runtime          `sqlite3` / supported Drift     Follow current Drift
                          setup                           Android guidance

  Media access            `photo_manager`                 Query media and obtain
                                                          file access; verify
                                                          write/publish support

  Device discovery / P2P  `nearby_connections` or another Verify Android
                          maintained plugin               compatibility and
                                                          maintenance before
                                                          selection

  Background scheduling   `workmanager`                   Periodic best-effort
                                                          work, not exact-time
                                                          guarantee

  Notifications           `flutter_local_notifications`   Progress and schedule
                                                          status; verify Android
                                                          permission setup

  Hashing                 `crypto`                        SHA-256

  Permissions             `permission_handler`            Request only necessary
                                                          permissions

  File/path utilities     `path`, `path_provider`         Paths and temporary
                                                          staging

  Typed platform APIs     `pigeon`                        Only if a plugin
                                                          adapter needs typed
                                                          channels; no custom
                                                          native implementation
  -------------------------------------------------------------------------------

**Package gate:** If a candidate networking plugin is abandoned,
incompatible with the target Android version, or cannot transfer large
files reliably, evaluate another maintained Flutter plugin. Do not
implement a custom Kotlin plugin under the "Flutter-only" requirement.

------------------------------------------------------------------------

## 5. Media discovery and incremental scanning

Use Android's media library through a Flutter media plugin, not
unrestricted filesystem crawling.

### Scope

Default scope: - Camera photos in `DCIM/Camera` and camera-related
subfolders. - Camera videos in `DCIM/Camera` and camera-related
subfolders.

Provide optional folder selection later. Do not silently include
screenshots, downloads, messaging-app media, or social-media folders in
the default camera migration.

### Media record

``` dart
enum MediaKind { image, video }

enum TransferStatus {
  pending,
  queued,
  transferring,
  verifying,
  transferred,
  failed,
  skipped,
}

class MediaItem {
  final String localId;
  final String uri;
  final String displayName;
  final String mimeType;
  final int sizeBytes;
  final DateTime? dateTaken;
  final DateTime dateModified;
  final String? relativePath;
  final MediaKind kind;
  final String? sha256;
  final TransferStatus status;
  final DateTime firstSeenAt;
  final DateTime? transferredAt;
}
```

The actual implementation should use immutable models and generated
Drift data classes where appropriate.

### Incremental scan algorithm

1.  Query the media library for eligible camera photos and videos.
2.  Read stable media identifiers, URI, filename, MIME type, size,
    capture date, modification date, and relative path.
3.  Upsert records into the local database.
4.  Compare each item with the existing inventory.
5.  New items become `pending`.
6.  Existing `transferred` items remain transferred unless the
    underlying content changed.
7.  If a media item changes, invalidate its previous hash/transfer
    verification and mark it pending again.
8.  Keep items that disappear from MediaStore in history; do not delete
    history automatically.

Do not rely on filename alone as identity. MediaStore IDs can change
after restore or re-indexing. Use a composite identity and content hash
where needed.

------------------------------------------------------------------------

## 6. Metadata and file-integrity policy

### 6.1 Default policy: preserve original media

The safest and most reliable transfer is byte-for-byte copying.
LumaSync should not decode and re-encode images or transcode videos.

Preserve: - Original capture date/time. - GPS coordinates when
present. - Orientation. - Image dimensions and color profile. - EXIF,
XMP, and IPTC data embedded in the file. - Video container metadata,
recording date, codec, frame rate, resolution, and audio tracks.

Do not falsify camera make/model, lens identity, or capture-device
identity. Do not modify metadata to impersonate a different camera or to
manipulate Google Photos backup eligibility.

### 6.2 Hash verification

For every file: 1. Stream the source file through SHA-256. 2. Send the
file. 3. Stream the received file through SHA-256. 4. Compare hashes. 5.
Only publish the received file into the camera roll after successful
verification.

If the hash differs, mark the item failed, retain the sender original,
remove or quarantine the incomplete receiver file, and allow retry.

### 6.3 Filename collisions

If a file with the same name already exists: - If content hash matches,
mark it as already present / skipped. - If content differs, generate a
collision-safe filename, for example `IMG_20261102_120000_1.jpg`. -
Never overwrite a different existing file silently.

------------------------------------------------------------------------

## 7. Pairing and local Wi-Fi transfer

### Pairing

-   Both devices install the same LumaSync build.
-   Sender and receiver select their roles.
-   Receiver advertises availability; sender discovers it.
-   Pair using a QR code or short-lived pairing code.
-   Require explicit approval on both devices for first pairing.
-   Persist a paired-device identity securely.
-   Provide a revoke/unpair action.

### Network strategy

Preferred order: 1. Use a maintained Flutter plugin for peer-to-peer
discovery and transfer if it satisfies the package gate. 2. Otherwise
use a maintained Flutter plugin exposing local network discovery and
TCP/UDP sockets. 3. A user-created Wi-Fi hotspot can be an optional
fallback if both devices can join it.

Do not assume both phones can communicate merely because both have
internet access. They must have a reachable local path. Some guest Wi-Fi
networks enable client isolation and block device-to-device traffic.

### Transfer protocol

Use a versioned protocol with a manifest and per-file acknowledgements.

Example manifest:

``` json
{
  "protocolVersion": 1,
  "sessionId": "generated-session-id",
  "senderDeviceId": "paired-sender-id",
  "files": [
    {
      "transferId": "stable-transfer-id",
      "name": "IMG_20261102_120000.jpg",
      "mimeType": "image/jpeg",
      "sizeBytes": 5242880,
      "dateTakenMillis": 1793613600000,
      "sha256": "hex-digest"
    }
  ]
}
```

The manifest must not include unnecessary GPS coordinates or other
sensitive metadata. File bytes preserve the embedded original metadata.

Per-file lifecycle:

``` text
PENDING
  -> QUEUED
  -> TRANSFERRING
  -> VERIFYING
  -> PUBLISHING
  -> TRANSFERRED
```

Failure path:

``` text
TRANSFERRING / VERIFYING / PUBLISHING
  -> FAILED
  -> PENDING (when retry is requested or scheduled)
```

The receiver sends an acknowledgement only after: - Full file bytes have
arrived. - File size is correct. - SHA-256 matches. - File is
successfully published to the media library.

The sender must not mark a file transferred merely because bytes were
sent. It must receive the receiver's final acknowledgement.

### Bounded streaming

-   Stream from source URI; do not read entire files into RAM.
-   Use bounded buffers.
-   Start with one active file at a time.
-   Benchmark before adding parallel transfers.
-   Persist progress at safe checkpoints.
-   On disconnect, retain the source original and mark the current item
    resumable/failed.
-   If the chosen plugin cannot resume a partial payload safely, restart
    that individual file from byte zero; do not claim true partial
    resume.

------------------------------------------------------------------------

## 8. Receiver publishing to Camera roll

After verification, save files to the receiver's public media library.

Target relative path: - Images: `DCIM/Camera/` - Videos: `DCIM/Camera/`

Use a Flutter plugin that supports creating/publishing media in the
public Android media library. Confirm on the target Redmi ROM that: -
The file is physically stored in the intended public folder. - Android
MediaStore indexes it. - It appears in the system gallery. - Google
Photos can see it when the Camera folder is included in backup settings.

Use a temporary app-private staging location until verification is
complete. Never expose incomplete files to the gallery.

If the selected plugin cannot publish a file safely into `DCIM/Camera`,
treat that as a blocking technical issue. Do not fall back to broad
all-files permission without a documented justification.

------------------------------------------------------------------------

## 9. Daily scheduled transfer

### User experience

Add a Schedule screen with: - Enable/disable daily transfer. - Time
picker (local device time). - Selected weekdays (default: every day). -
Wi-Fi-only toggle (default on). - Charging-only toggle (default off). -
Require receiver availability toggle. - Retry policy. - Last attempt and
last success. - Next eligible run estimate.

Example:

``` text
Daily transfer: ON
Scheduled time: 9:00 PM
Days: Every day
Network: Wi-Fi only
Charging required: No

Last successful transfer: Yesterday, 9:04 PM
Pending: 37 files (1.8 GB)
Next eligible run: Today, around 9:00 PM
```

### Scheduling behavior

-   Use a maintained Flutter WorkManager plugin for periodic background
    execution.
-   Persist the schedule in Drift/DataStore-equivalent local
    preferences.
-   Re-register work after schedule changes and app startup.
-   Use unique work names to avoid duplicate scheduled jobs.
-   At execution, check connectivity, battery constraints, permissions,
    pairing, receiver availability, and pending items.
-   If conditions are not met, record why the run was deferred and leave
    all files pending.
-   Never delete source media after a scheduled transfer.
-   Send a notification when a scheduled run starts, completes, fails,
    or is deferred.
-   Provide a manual **Run now** button.

### Exact-time disclaimer

Android WorkManager is inexact. The app should say "scheduled around
9:00 PM" or "runs when Android allows," not promise an exact start time.
OEM battery managers can further delay background work.

### Receiver scheduling limitation

The sender's scheduled job cannot force the receiver to wake or start
advertising if Android has stopped it. Validate background receiving on
the actual Redmi Pixel OS build. If it is unreliable, require
LumaSync to be open or receiver-ready at the scheduled time and
clearly communicate this in onboarding.

------------------------------------------------------------------------

## 10. Sender inventory and manual deletion

This is a core product requirement.

### Sender tabs

**Pending** - Files not yet transferred. - Failed files eligible for
retry. - Select and transfer now.

**Transferred** - Files acknowledged by the receiver. - Show transfer
date/time and verified status. - Select individual files or select
all. - Manual delete action.

**Failed** - Error details. - Retry selected or retry all.

### Manual deletion safety

Deletion must be a separate, explicit action initiated by the user.

Before deleting: 1. Confirm each selected item is in `transferred`
state. 2. Confirm the receiver's final acknowledgement and verification
are recorded. 3. Show the number of files and total size. 4. Explain
that deletion removes the original from the iQOO phone. 5. Require a
confirmation dialog. 6. Use the media plugin's supported deletion API
and Android's system confirmation flow where required. 7. If deletion is
denied or fails, retain the item and show the error. 8. Keep a
tombstone/history record in LumaSync so the app does not re-add the
deleted file as pending if the media index temporarily lags.

**Never offer "delete all photos after transfer" as an automatic
default.** The user must manually select and confirm deletion.

Suggested confirmation copy:

> Delete 24 transferred files (1.2 GB) from this phone? Verified copies
> are recorded on the receiver. This action removes the selected
> originals from the iQOO phone and may require Android confirmation.

The app cannot guarantee that a receiver copy remains forever after
transfer; the receiver user can independently delete it. State this
clearly before sender cleanup.

------------------------------------------------------------------------

## 11. Database design

Use Drift tables with migrations and indexes.

### `media_items`

-   `id`
-   `sourceMediaId`
-   `sourceUri`
-   `displayName`
-   `mimeType`
-   `sizeBytes`
-   `dateTakenMillis`
-   `dateModifiedMillis`
-   `relativePath`
-   `kind`
-   `sha256`
-   `status`
-   `firstSeenAt`
-   `transferredAt`
-   `receiverAcknowledgementId`
-   `lastError`

### `transfer_sessions`

-   `id`
-   `pairedDeviceId`
-   `startedAt`
-   `finishedAt`
-   `status`
-   `totalFiles`
-   `completedFiles`
-   `failedFiles`
-   `totalBytes`
-   `transferredBytes`
-   `trigger` (`manual` or `scheduled`)

### `paired_devices`

-   `id`
-   `displayName`
-   `platform`
-   `publicKeyFingerprint` or plugin-supported identity
-   `pairedAt`
-   `lastSeenAt`
-   `isTrusted`

Do not store reusable pairing secrets in plaintext. Use secure storage
for credentials/tokens where the selected plugin supports it.

### `schedule_settings`

-   `id`
-   `enabled`
-   `hour`
-   `minute`
-   `weekdays`
-   `wifiOnly`
-   `chargingOnly`
-   `lastAttemptAt`
-   `lastSuccessAt`
-   `nextRunEstimate`

### `transfer_file_events`

-   `id`
-   `mediaItemId`
-   `sessionId`
-   `eventType`
-   `timestamp`
-   `details`

Use event history for troubleshooting, but avoid logging private
metadata or GPS coordinates.

------------------------------------------------------------------------

## 12. UI / UX screens

1.  **Onboarding**
    -   Explain sender/receiver roles.
    -   Explain permissions and background scheduling limitations.
2.  **Home**
    -   Sender or receiver role.
    -   Connection status.
    -   Pending count and transferred count.
    -   Last sync and next scheduled run.
3.  **Pair devices**
    -   QR pairing.
    -   Nearby device discovery.
    -   Trust confirmation.
4.  **Media inventory**
    -   Photos, videos, total size.
    -   Date range.
    -   Camera-folder scope.
5.  **Transfer**
    -   Overall progress.
    -   Current file.
    -   Speed and completed/total count.
    -   Pause/cancel/retry.
6.  **Sender library**
    -   Pending, transferred, failed tabs.
    -   Multi-select.
    -   Manual delete for transferred items only.
7.  **Schedule**
    -   Daily time and weekday controls.
    -   Wi-Fi and charging constraints.
    -   Last run and next eligible run.
8.  **Receiver**
    -   Receiver-ready state.
    -   Received items and storage space.
    -   Destination folder.
9.  **History**
    -   Sessions, counts, errors, verification results.
10. **Settings**

-   Pairing management.
-   Folder scope.
-   Notifications.
-   Battery optimization guidance.
-   Privacy and diagnostics.

------------------------------------------------------------------------

## 13. Permissions and privacy

Request permissions only when the user invokes the feature that needs
them.

Potential Android requirements depend on Android OS version and plugin
implementation: - Read access to photos and videos, including Android's
selected-media access behavior. - Nearby device / Bluetooth / Wi-Fi
permissions required by the selected networking plugin and OS version. -
Notifications on Android versions that require runtime notification
permission. - Media-library write/publish access through
MediaStore-compatible plugin APIs. - Background-work requirements
exposed by the selected scheduling plugin.

Avoid `MANAGE_EXTERNAL_STORAGE` unless absolutely necessary and
justified. Do not ask for location permission merely because GPS
metadata exists in a photo. Do not upload photos, videos, metadata,
hashes, or filenames to a server. Keep transfers local.

------------------------------------------------------------------------

## 14. Failure handling

  -----------------------------------------------------------------------
  Scenario                            Required behavior
  ----------------------------------- -----------------------------------
  Sender Wi-Fi disconnects            Stop safely; retain original; retry
                                      later

  Receiver unavailable                Keep files pending; show receiver
                                      unavailable

  App process killed                  Restore state from database

  Phone reboot                        Re-register schedule when permitted

  Low receiver storage                Stop before publishing; show
                                      required space

  Hash mismatch                       Quarantine/delete incomplete
                                      receiver file; mark failed

  Duplicate file                      Skip only after reliable
                                      identity/hash check

  Same filename, different content    Generate collision-safe name

  Permission revoked                  Pause and request permission when
                                      user returns

  Receiver app force-stopped          Explain that scheduled receive may
                                      not run

  User cancels                        Stop safely and retain source

  Sender deletion rejected            Keep original and report failure
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 15. Testing plan

Test on the actual iQOO Neo 9 Pro and Redmi Note 7 Pro Pixel OS build.

### Functional tests

-   Pair both phones.
-   Scan thousands of photos and videos.
-   Transfer JPEG, HEIC, PNG, DNG, MP4 and supported camera formats.
-   Confirm receiver files appear in `DCIM/Camera`.
-   Confirm Google Photos can see the Camera folder.
-   Confirm original sender files remain after transfer.
-   Confirm transferred/pending/failed status is correct.
-   Confirm manual deletion works only for verified transferred items.
-   Confirm schedule changes replace old scheduled work.

### Reliability tests

-   Turn Wi-Fi off during transfer.
-   Close the app during transfer.
-   Reboot each device.
-   Put devices to sleep.
-   Test battery saver and OEM battery management.
-   Fill receiver storage close to capacity.
-   Transfer duplicate files.
-   Test same filename with different contents.
-   Deny and later grant permissions.
-   Test the receiver app closed and force-stopped.

### Data-integrity tests

For every test file: - Compare source and receiver SHA-256. - Compare
file size. - Confirm embedded capture date/time and GPS remain unchanged
when present. - Confirm image dimensions and video
duration/resolution. - Confirm no image/video recompression occurred.

### Acceptance criteria

-   No source file is automatically deleted.
-   A file is marked transferred only after receiver verification and
    acknowledgement.
-   Repeated syncs do not create duplicate copies.
-   Incomplete files never appear in the receiver's Camera folder.
-   Pending and transferred lists survive app restart.
-   Scheduled jobs are best-effort and limitations are communicated
    honestly.
-   Manual cleanup cannot select pending or failed items.

------------------------------------------------------------------------

## 16. Implementation milestones

### Milestone 1 --- Flutter foundation

-   Create Flutter project.
-   Set up Riverpod, GoRouter, Drift, logging and Material 3.
-   Implement onboarding and sender/receiver role selection.
-   Add unit-test structure.

### Milestone 2 --- Media inventory

-   Integrate media plugin.
-   Request permissions.
-   Scan camera photos/videos.
-   Persist inventory.
-   Build Pending / Transferred / Failed UI.

### Milestone 3 --- Device pairing

-   Evaluate and integrate maintained Flutter networking plugin.
-   Pair devices.
-   Establish secure connection.
-   Exchange a small test message and manifest.

### Milestone 4 --- Reliable file transfer

-   Stream one file at a time.
-   Implement manifest and acknowledgements.
-   Verify SHA-256.
-   Publish into receiver Camera folder.
-   Test image and video formats.

### Milestone 5 --- Daily schedule

-   Integrate WorkManager Flutter plugin.
-   Persist schedule settings.
-   Add Wi-Fi/battery/receiver checks.
-   Add notifications and last-run status.
-   Validate on both actual phones.

### Milestone 6 --- Brand, launch animation and sound

-   Design several original logo concepts for UNLIM RELAY and confirm
    one with the user before building anything on it.
-   Use the chosen logo for the launcher icon (including the Android
    adaptive icon) and the in-app brand mark.
-   Build a short launch animation with modern motion design that
    continues from the native splash, never blocks a cold start for
    long, and can be skipped by tapping.
-   Add an original launch sound effect (generated in-house, no
    third-party audio), played quietly once per cold start; respect
    silent/vibrate mode and provide a setting to turn it off.

### Milestone 7 --- Manual cleanup and hardening

-   Implement transferred-only selection.
-   Add confirmation and Android deletion flow.
-   Add retry, duplicate handling, collision-safe filenames.
-   Run failure and device-reboot tests.
-   Prepare release builds.

------------------------------------------------------------------------

## 17. Instructions for Claude Code

Build this project incrementally. Do not generate the entire application
in one pass.

### Required engineering rules

1.  Flutter/Dart application code only. No custom Kotlin or Java source
    files.
2.  Before selecting packages, inspect current pub.dev package versions,
    maintenance, Android support, APIs, and licenses.
3.  Do not invent plugin APIs. Read package documentation and inspect
    examples before implementation.
4.  Keep all plugin-specific code behind Dart interfaces/adapters.
5.  Do not use fake transfer progress or simulated device discovery in
    production code.
6.  Never mark a file transferred before receiver-side hash verification
    and final acknowledgement.
7.  Never automatically delete source photos/videos.
8.  Manual deletion must be restricted to verified transferred items and
    require explicit confirmation.
9.  Preserve original file bytes and embedded metadata. Do not spoof
    camera identity or manipulate backup eligibility.
10. Do not upload media or metadata to a cloud server.
11. Use streaming I/O and bounded memory for large videos.
12. Add unit tests for repositories, state transitions, scheduling
    decisions, duplicate detection, and transfer protocol.
13. Keep `flutter analyze` and tests passing after each milestone.
14. Document any capability that cannot be implemented reliably using
    maintained Flutter plugins. Do not silently violate the Flutter-only
    constraint.
15. Support Android first; do not add iOS code until Android acceptance
    criteria pass.

### First Claude Code task

Start with **Milestone 1 only**:

-   Inspect the installed Flutter/Dart environment.
-   Create the project with package ID `com.ksrk.lumasync`.
-   Set up the folder structure.
-   Add Riverpod, GoRouter, Drift, Material 3 and logging.
-   Create the theme, router, onboarding, home screen, and
    sender/receiver role selection.
-   Add placeholder repository interfaces for media scanning, pairing,
    transfer and scheduling.
-   Add unit tests for the initial app state and navigation.
-   Run `flutter analyze` and tests.
-   Report files created, commands run, and any environment blockers.

Do not implement networking or file transfer until the Flutter
foundation builds successfully.

------------------------------------------------------------------------

## 18. Definition of done

LumaSync v1.0 is complete when:

-   The same Flutter app runs on both phones.
-   The iQOO scans camera photos and videos.
-   The Redmi can pair and receive them over local Wi-Fi.
-   Verified files are saved into the Redmi's public `DCIM/Camera`
    folder.
-   Google Photos can discover the received files through its existing
    folder backup settings.
-   Original sender files remain untouched until the user manually
    deletes selected transferred items.
-   The app clearly distinguishes pending, transferred, failed and
    skipped files.
-   Daily scheduling works as an Android best-effort background task,
    with honest receiver-availability limitations.
-   Repeated transfers do not create duplicate copies.
-   File integrity is verified using SHA-256.
-   No camera identity spoofing or Google Photos storage-eligibility
    bypass is implemented.

**Product principle:** LumaSync is a private, local-first, scheduled
media synchronization and migration tool. It should prioritize data
integrity, user control, and recoverability over clever shortcuts.
