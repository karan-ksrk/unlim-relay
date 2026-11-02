# Permissions

Requested only when the user starts the feature that needs them (plan §13).

| Permission | When | Why |
| --- | --- | --- |
| `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` | Sender taps **Scan camera library** | Read camera photos and videos (Android 13+). |
| `READ_EXTERNAL_STORAGE` (max SDK 32) | Same | Declared by `photo_manager` for Android 12 and lower. |
| `READ_MEDIA_VISUAL_USER_SELECTED` | Same | Lets Android 14+ offer "selected photos" access. LumaSync then shows a notice that only selected items will sync. |
| `ACCESS_MEDIA_LOCATION` | Same, no separate dialog | Without it Android serves photos with GPS EXIF redacted, which would break byte-for-byte transfer (plan §6.1). This is not a location permission; LumaSync never asks for device location. |
| `INTERNET` | Always (normal permission, no prompt) | TLS socket between the paired phones on the local network. |
| `CHANGE_WIFI_MULTICAST_STATE` | Always (declared by `bonsoir`, no prompt) | mDNS discovery of the receiver. |
| `CAMERA` | Sender taps **Scan pairing code** (requested by `mobile_scanner`) | Scan the receiver's pairing QR code. |

Not used: `MANAGE_EXTERNAL_STORAGE`, location, Bluetooth, or nearby-device
permissions. Nothing is uploaded to a server.

Receiver publishing to `DCIM/Camera` inserts into MediaStore, which needs no
storage permission on Android 10+. `wakelock_plus` keeps the screen on during
transfers (no permission needed).
