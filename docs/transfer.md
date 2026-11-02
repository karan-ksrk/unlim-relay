# File transfer

## Session

1. Sender resolves the paired receiver (mDNS, else last known address),
   opens the pinned TLS connection and authenticates with `hello`.
2. Sends a `manifest` of the batch; the receiver acknowledges totals.
3. For each file, one at a time:

```text
sender                                   receiver
fileOffer {transferId, name, size, …}  →
                                       ←  fileAccept
                                          | fileAlreadyPresent {sha256, ackId}
                                          | fileRejected {reason}
data frames (≤64 KiB each)             →  written to private staging, hashed
fileComplete {sha256}                  →  size + SHA-256 checked,
                                          published to DCIM/Camera,
                                          published copy read back and hashed
                                       ←  fileAck {sha256, ackId, savedAs}
                                          | fileRejected {reason, retryable}
```

The sender marks an item **transferred** only on `fileAck` (or
`fileAlreadyPresent`), storing the hash, acknowledgement id and time.

## Integrity and safety

- Source files are streamed from their real path and never modified or
  deleted. ACCESS_MEDIA_LOCATION keeps reads un-redacted.
- Memory is bounded: the sender flushes every 1 MiB; the receiver only reads
  the socket when it is ready, so TCP applies backpressure.
- Incoming bytes go to `<app support>/incoming/*.part`, never the gallery.
  Partial files are deleted on failure and on receiver start.
- Publishing uses `photo_manager`'s editor: a MediaStore insert into
  `DCIM/Camera/` plus a byte copy (no re-encoding). The capture time is
  passed as MediaStore `DATE_TAKEN`; the file's EXIF is untouched.
- The receiver keeps `received_files` (transfer id, source size/mtime,
  SHA-256, MediaStore id). A retransmit of the same version, or the same
  bytes under a new transfer id, is answered without a second copy. If the
  user deleted the receiver's copy, the file is accepted again.
- Name clashes: Android renames (`IMG_x (1).jpg`); nothing is overwritten.

## Daily limit

Default **100 photos and 5 videos per day**, editable in Settings (either
can be "no limit"). Counted from local midnight by `transferredAt`, applies
to *Transfer now*, *Transfer selected* and scheduled runs. Pending
items are sent newest first; the rest wait for the next day.

When files are waiting because of the limit, the transfer screen offers
**Run next batch**: one more batch of the daily size (e.g. 100 photos + 5
videos), newest first, ignoring what was already sent today. Only the user
can trigger it; scheduled runs always respect the limit. Going over shows as
"Today: 200 photos (limit 100)".

## Failure handling

| Case | Result |
| --- | --- |
| Source file gone | Item failed ("no longer on this phone"); batch continues |
| Size or hash mismatch | `fileRejected`; item failed, retried next run |
| Receiver out of space | `fileRejected` with that reason |
| Connection drops mid-file | Item failed, session ends, rest stay pending |
| User cancels | Current item back to pending; nothing published |
| App killed mid-transfer | In-flight items reset to pending on next run |

## Known limits

- `photo_manager` doesn't use `IS_PENDING`, so the gallery could briefly see
  the file while its (already verified) bytes are copied in.
- No proactive free-space check; a full disk is reported when a write fails.
- *Transfer now* keeps the sender's screen on while it runs; scheduled runs
  work in the background. The receiver keeps listening with its screen off
  ([receiver.md](receiver.md)).
