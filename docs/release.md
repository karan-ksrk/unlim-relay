# Release builds

```sh
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (~30 MB) is the
# one for both test phones.
```

## Signing

Release builds are signed with the key in `android/app/upload-keystore.jks`,
configured by `android/key.properties` (alias `upload`, RSA 4096, valid
10,000 days, created 2 Nov 2026). Both files are gitignored. Without
them, release builds fall back to the debug key so the project still builds
on another machine.

**Back up both files somewhere safe.** Every future update must be signed
with the same key; if it is lost, installing a new build means
uninstalling the app first, which deletes its data (pairing, inventory,
history).

Certificate SHA-256:
`3b8e21ffb1f7325b4914d2319c8663fe75134c2cb0473d28be18730c420d4da6`

## Switching the phones to release-signed builds

The phones currently have builds signed with the Android debug key. A
build signed with the release key can't be installed over them: Android
refuses a different signature. Switching means uninstalling first, then
pairing again; the sender's inventory and transfer history start over
(the receiver's dedupe still recognises files it already has).

## Debug vs release speed

Debug builds start much slower (about 4.9 s before the first frame on the
Redmi). Judge performance on a release or profile build.
