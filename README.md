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

Daily scheduling is next. See [docs/transfer.md](docs/transfer.md),
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
              client, wire protocol
  features/   onboarding, home, media_library, pairing, settings
test/
  unit/       repositories, controllers, protocol, migrations
  integration/ real TLS pairing over loopback
  widget/     navigation, library and pairing screens
  fixtures/   in-memory fakes
docs/         pairing, device compatibility, permissions
```
