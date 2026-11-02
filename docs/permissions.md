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
| `POST_NOTIFICATIONS` | Sender turns on **Daily transfer** (or taps Allow on the Schedule screen) | Result notifications, and the foreground-service notification while a run is going. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Sender taps **Allow** next to Battery optimization | System prompt to exempt the app, so scheduled runs are less likely to be delayed or killed. |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `FOREGROUND_SERVICE_SHORT_SERVICE`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE` | Always (declared by `workmanager`, no prompt) | Run the daily transfer as a foreground service, keep it scheduled across reboots, check network constraints. |
| `CAMERA` | Sender taps **Scan pairing code** (requested by `mobile_scanner`) | Scan the receiver's pairing QR code. |

Not used: `MANAGE_EXTERNAL_STORAGE`, location, Bluetooth, or nearby-device
permissions. Nothing is uploaded to a server.

Receiver publishing to `DCIM/Camera` inserts into MediaStore, which needs no
storage permission on Android 10+. `wakelock_plus` keeps the screen on during
manual transfers (no permission needed).

Receiver, while *Ready to receive* is on: a `connectedDevice` foreground
service (`flutter_foreground_task`) with `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_CONNECTED_DEVICE` and `WAKE_LOCK` (no prompts). Android 14+
also requires a network permission for that service type;
`CHANGE_WIFI_MULTICAST_STATE` covers it. Turning the switch on asks for
`POST_NOTIFICATIONS` so the "Ready to receive" notification is visible; the
service runs either way.
