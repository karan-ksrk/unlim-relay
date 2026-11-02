# LumaSync

*Your memories. Everywhere.*

Local-first photo and video sync between two Android phones. One phone is the
**sender**, the other the **receiver**; received files are verified and saved
to `DCIM/Camera`. See [LumaSync_Flutter_Development_Plan.md](LumaSync_Flutter_Development_Plan.md)
for the full plan.

- Package: `com.ksrk.lumasync`
- Flutter/Dart only — no custom Kotlin/Java. `MainActivity.kt` is the
  unmodified `flutter create` embedding stub.

## Status

- **Milestone 1** (foundation): Riverpod, GoRouter, Drift, Material 3
  (`material_ui`), logging, onboarding, role selection, home, settings.
- **Milestone 2** (media inventory): `photo_manager` behind a `MediaLibrary`
  adapter, permission flow, incremental `DCIM/Camera` scan, Drift
  `media_items` table (schema v2), Pending / Transferred / Failed library.

- **Milestone 3** (pairing): receiver TLS server with a self-signed,
  pinned certificate; QR pairing with one-time secret and approval on both
  phones; token auth; mDNS discovery; connection test with a manifest
  exchange. Schema v3 (`paired_devices`).

- **Milestone 4** (transfer): one file at a time over the TLS session,
  SHA-256 verified on the receiver, published to `DCIM/Camera` and read
  back before the final acknowledgement; retransmit dedupe; daily limit
  (default 100 photos + 5 videos, configurable); progress screen, Transfer
  now / Transfer selected. Schema v4 (`received_files`).

- **Milestone 5** (daily schedule): WorkManager background run at a chosen
  time and days with Wi-Fi/charging/battery constraints, retries, a
  cross-engine transfer lock, result notifications, battery-optimization
  prompt, Run now, last/next run status. Schema v5 (`schedule_settings`,
  `transfer_locks`).

- **Background receiving**: *Ready to receive* runs as a foreground
  service, so the receiver keeps listening with the screen off.

- **Milestone 6** (brand): Relay Loop logo (vector adaptive launcher icon
  with a themed-icon layer), a 2-second launch animation drawn in code
  (tap to skip, fade-only with animations off) and an original launch
  chime synthesized by `tool/generate_launch_sound.py`, muted in silent or
  vibrate mode and switchable in Settings. See [docs/brand.md](docs/brand.md).

- **Milestone 7** (cleanup and hardening, in progress): delete verified,
  unchanged transferred originals from the sender after two confirmations
  (the app's, then Android's), tombstones so deleted files never return as
  pending (schema v6), Select all, Retry all, release signing and
  per-ABI release APKs. See [docs/cleanup.md](docs/cleanup.md) and
  [docs/release.md](docs/release.md). See [docs/schedule.md](docs/schedule.md),
[docs/transfer.md](docs/transfer.md),
[docs/pairing.md](docs/pairing.md),
[docs/device-compatibility.md](docs/device-compatibility.md) and
[docs/permissions.md](docs/permissions.md).

## Development

```sh
flutter pub get
dart run build_runner build   # regenerate Drift code after table changes
flutter analyze
flutter test
flutter run -d <device-id>
```

## Layout

```text
lib/
  app/        app widget, router, theme, shared widgets
  core/       logging, formatters, secrets, network address
  data/       Drift database, models, repositories, plugin adapters
  services/   scan, reconciler, TLS identity, receiver server, sender
              client, wire protocol, schedule planner and job
  background/ WorkManager entry point (separate engine)
  features/   onboarding, home, media_library, pairing, transfer,
              schedule, launch, settings
tool/         launch sound generator, launcher icon renderer
test/
  unit/       repositories, controllers, protocol, migrations
  integration/ real TLS pairing over loopback
  widget/     navigation, library and pairing screens
  fixtures/   in-memory fakes
docs/         pairing, device compatibility, permissions
```
