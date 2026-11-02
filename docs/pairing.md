# Pairing and the secure channel

## Package choice (plan §4 package gate)

| Option | Verdict |
| --- | --- |
| `nearby_connections` 4.3.0 | Not used. Last release 2025-02-19; depends on Google Play Services Nearby and needs Bluetooth, location and nearby-device permissions. |
| `dart:io` TLS sockets | **Used** for the transport. Built into Dart, so no plugin is involved and file streaming in Milestone 4 has full control over buffering. |
| `bonsoir` 7.1.6 | **Used** for mDNS discovery (Android `NsdManager`). Active, MIT. |
| `mobile_scanner` 7.5.0 / `qr_flutter` 4.1.0 | QR scan / render. |
| `flutter_secure_storage` 11.2.0 | Auth token and TLS private key (Android Keystore). |
| `basic_utils` 5.8.2 | Generates the receiver's self-signed certificate. RSA-2048: this library writes NULL algorithm parameters, which is valid for RSA but not ECDSA. |
| `device_info_plus` 13.3.0 | Device name shown during pairing. |

## Flow

1. **Receiver** turns on *Ready to receive* (or opens *Pair with sender*). On
   first use it generates an RSA-2048 key and 10-year self-signed certificate
   on a background isolate (≈2 s on the Redmi Note 7 Pro) and keeps both in
   secure storage, so the fingerprint stays stable.
2. It listens with TLS on port 47863 (any free port if taken) and advertises
   `_lumasync._tcp` with TXT `id=<deviceId>`.
3. *Show pairing code* displays a QR code:
   `lumasync://pair?v=1&id&n&h&p&fp=<cert SHA-256>&s=<one-time secret>`.
   The secret expires after 5 minutes and is consumed by the first valid
   attempt.
4. **Sender** scans it, confirms, and connects with TLS while accepting
   **only** the certificate whose SHA-256 equals `fp`. No CA is trusted, so a
   man-in-the-middle can't substitute a certificate.
5. Sender sends `pairRequest` with the secret. The receiver checks it in
   constant time and asks its user to **Allow** or **Decline** (60 s).
6. On approval the receiver issues a random 256-bit auth token. The sender
   stores it in secure storage; the receiver stores only its SHA-256.
7. Later sessions: sender finds the receiver by mDNS (falls back to the last
   known address), connects with the pinned certificate, sends `hello` with
   the token. Unknown or revoked tokens get `error: unauthorized`.

Unpair on either side deletes the row (and the sender's token); the other
side's next connection is refused.

## Wire format

5-byte header (1-byte frame type, 4-byte big-endian length) + payload, max
1 MiB per frame. Type 1 = JSON control message, type 2 = file data
(Milestone 4). Messages: `pairRequest`, `pairAccepted`, `pairRejected`,
`hello`, `helloAccepted`, `ping`/`pong`, `manifest`, `manifestAck`, `error`.
The manifest carries name, MIME type, size, capture time and (from M4)
SHA-256 — never GPS.

## Limits

- The receiver must have LumaSync open with *Ready to receive* on (plan §2.3
  MVP). The switch is remembered: reopening the app (or an update) resumes
  listening automatically. Background receiving is evaluated later.
- A refused connection (receiver app closed or switch off) gets its own
  message telling the user to turn on *Ready to receive*.
- One paired peer per phone; pairing again replaces it.
- Android `NsdManager` delivers TXT records only after resolution, so the
  sender resolves every `_lumasync._tcp` service and matches the id
  afterwards.
