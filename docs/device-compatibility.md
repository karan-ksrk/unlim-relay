# Device compatibility

| Device | Role | OS | Status |
| --- | --- | --- | --- |
| Redmi Note 7 Pro (`violet`) | Receiver | Pixel OS, Android 13 (API 33) | Milestones 1–4 verified 2026-11-02 |
| iQOO Neo 9 Pro (`I2304`) | Sender | OriginOS 6, Android 16 (API 36) | Milestones 1–4 verified 2026-11-02 |

Debug APKs installed over wireless adb.

## Milestone 1 — both phones

- Launches; Impeller renders.
- Onboarding → role selection → home works; role persists across
  force-stop and relaunch.
- Follows system light/dark mode.
- First screen transition in debug builds takes ~2 s (JIT warm-up).

## Milestone 2 — iQOO Neo 9 Pro (sender)

- System photo/video permission dialog shown on first scan; READ_MEDIA_IMAGES,
  READ_MEDIA_VIDEO, READ_MEDIA_VISUAL_USER_SELECTED and ACCESS_MEDIA_LOCATION
  all granted.
- First scan of `DCIM/Camera`: 4,950 files (4,352 JPEG, 1 DNG, 597 MP4) in
  7.5 s, including one size lookup per file.
- Inventory total 40,981,488,846 bytes — identical to the sum of
  `stat -c %s /sdcard/DCIM/Camera/*`.
- Rescan: 0 new, 0 changed, no duplicate rows.
- MediaStore stores this folder's `relative_path` in three casings
  (`DCIM/Camera/` 4,868, `DCIM/camera/` 27, `dcim/camera/` 55). The scan
  filter uses case-insensitive `LIKE`; an exact match would miss 82 files.
- Other DCIM folders (DJI Album, Snapchat, …) are excluded by design.

## Milestone 2 — Redmi Note 7 Pro (receiver)

- Schema v1 → v2 migration ran on the existing install; stored role kept.

## Milestone 3 — pairing, both phones

- Receiver TLS identity generated in ≈2 s on the Redmi; server listening on
  192.168.1.20:47863 and advertising `_lumasync._tcp`.
- iQOO scanned the Redmi's QR code, the Redmi showed the approval dialog,
  and both phones stored the pairing ("iQOO I2304" ↔ "Xiaomi Redmi Note 7
  Pro").
- Schema v2 → v3 migration ran on both phones; the iQOO's 4,950-item
  inventory was kept.
- Connection test over Wi-Fi: authenticated `hello`, ping 18–44 ms, manifest
  of 100 pending files (810 MB) acknowledged with matching totals.
- mDNS: iQOO (Android 16) discovers and resolves the Redmi's service. The
  first build filtered on TXT attributes before resolution and always fell
  back to the stored address; fixed.

## Milestone 4 — file transfer

- Daily limit set to 3 photos / 1 video in Settings for the test, then
  *Transfer now*: the newest 3 JPEGs and 1 MP4 (17.1 MB) were sent in 5 s;
  4,946 deferred by the limit. Limits restored to 100 / 5 afterwards.
- SHA-256 of each source on the iQOO equals the received file on the Redmi
  (`adb shell sha256sum`, raw reads on both sides).
- Redmi MediaStore rows: `relative_path=DCIM/Camera/`, original sizes,
  `datetaken` = original capture time, owner `com.ksrk.lumasync`.
- EXIF Make/Model on the received photo is still iQOO / iQOO Neo9 Pro. The
  test photos have an empty GPS block (camera location tagging appears to be
  off), so GPS preservation is shown by byte identity but not yet exercised
  with real coordinates.
- Schema v3 → v4 migration ran on both phones.
- Not yet tested on device: DNG (the only one is far down the newest-first
  order), connection loss mid-file, receiver storage full.

## Known build warning

`photo_manager` 3.12.0 applies the Kotlin Gradle Plugin. Flutter 3.47 warns
that future versions will refuse to build such plugins. Watch for a
`photo_manager` release that migrates to built-in Kotlin.
