# Deleting transferred files from the sender

Plan §10. Library › **Transferred** tab: long-press to select (or Select
all), then the delete icon. Never automatic.

## Safety checks

When the user taps delete, each selected item is checked again:

| Check | If it fails |
| --- | --- |
| Status is *transferred*, with the receiver's SHA-256 and acknowledgement id recorded | Kept: "Not verified by the receiver yet." |
| Not already deleted or gone from the library | Kept: "Already gone from this phone." |
| Still in the media library | Kept: "No longer on this phone." |
| Same size and modification time as when it was verified | Kept: "Changed since it was transferred; transfer it again first." |

Then two confirmations: the app's dialog (number of files, total size, the
receiver's name, that originals are removed from this phone, that the
receiver can delete its own copies independently, and which selected files
are kept and why), then Android's own prompt
(`MediaStore.createDeleteRequest` via `photo_manager`'s `deleteWithIds`),
which deletes all or nothing.

## After deleting

- Rows of deleted files keep their history and get `deleted_at` (schema
  v6) as a tombstone. If a lagging media index still lists a deleted file,
  the scan ignores it rather than adding it back as pending.
- The Transferred tab shows the total freed so far.
- Declining Android's prompt deletes and records nothing.

## What "verified" does and doesn't mean

It means the receiver checked the file's SHA-256 and saved it to
DCIM/Camera at transfer time. It does not mean the receiver still has it:
on 2 Nov 2026 the Redmi held only 59 of the 210 files delivered to it
(most likely removed by Google Photos' "Free up space" or by hand). Delete
from the sender only once the copies are safe where you keep them (for
example backed up in Google Photos).

Other Milestone 7 changes: Select all in every tab, **Retry all** in the
Failed tab, and scrollable tab labels so the counts aren't cut off.
