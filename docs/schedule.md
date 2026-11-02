# Daily transfer

Sender only. Settings → **Daily transfer**, or the home tile.

## What a run does

1. Checks it is due, the phone is the sender, a receiver is paired and photo
   access is on. Network and battery are WorkManager constraints
   (`unmetered` when *Wi-Fi only*, else `connected`; `batteryNotLow`
   always; `charging` when *Only while charging*), so Android waits for them
   instead of starting the run.
2. Takes the transfer lock (see below), rescans `DCIM/Camera`, and sends
   pending files within today's limit, newest first, exactly like
   *Transfer now*. Source files are never touched.
3. Records the outcome, posts a notification, and registers the next run.

| Outcome | Meaning | Next run |
| --- | --- | --- |
| Sent | Files delivered | Next scheduled day |
| Nothing to send / Daily limit reached | Nothing left for today | Next scheduled day |
| Deferred | Receiver unreachable, not paired, no photo access, or a manual transfer was running | Every 30 min for the retry window (default 3 h) |
| Stopped | Session broke off, or Android stopped the task | Same as deferred |
| Continuing | Hit the 9-minute budget with files left | Straight away |

A missed time (phone off, Doze) runs as soon as Android allows, until the
next scheduled time. Turning the schedule on, or changing its time or days,
never catches up a time that has already passed that day.

**Run now** starts the same job in the background immediately (its own
unique work), with the same checks and limit.

## How it is built

- `workmanager` one-off work `daily-transfer`, re-registered with
  `ExistingWorkPolicy.replace` after every run, on every app start and on
  every settings change. The planner (`schedule_planner.dart`) is a pure
  function of the settings, the last attempt and the clock.
- A run that registers its successor replaces its own work, so Android
  stops it; it notifies first, and the stop handler waits for it to finish.
  WorkManager can start a moment early; the attempt is then recorded at the
  planned time so the slot isn't run twice.
- The task runs in a separate Flutter engine with its own database
  connection (WAL + busy timeout). Drift can't share an isolate across
  engines, so the app refreshes its queries on resume, while a run is going
  (WorkManager progress events) and when it ends.
- `transfer_locks` is a database lease (2-minute TTL, renewed every 30 s) so
  a scheduled run and a manual transfer never overlap.
- Runs use a `dataSync` foreground service (workmanager's opt-in manifest,
  `workmanager.enableDataSyncForegroundService=true`). Android may refuse
  it from the background unless battery optimization is off for the app;
  the 9-minute budget covers that case.
- In the background engine `photo_manager`'s permission check needs an
  Activity, so access is read through `permission_handler` instead.

## Limits

- Inexact: "around 9:00 PM", never a promise.
- The receiver needs *Ready to receive* on, on the same Wi-Fi. Its screen
  can be off and the app in the background ([receiver.md](receiver.md)), but
  it must not be swiped away from recents. Otherwise the run is deferred and
  files stay pending.
- OEM battery managers (OriginOS included) can delay or skip runs. The
  Schedule screen offers the battery-optimization exemption; some phones
  also need autostart/background activity allowed in system settings.
- Force-stopping the app cancels scheduled work until the app is opened
  again (it re-registers on start).

## Verified on device (2 Nov 2026)

iQOO Neo 9 Pro, Android 16: Run now and a timed run (18:20, 18:30) started
on time as a foreground service, rescanned 4,950 files, recorded "Daily
limit reached" (today's limit was used), posted the result notification and
registered the next day. Not yet exercised on device: a scheduled run that
sends files, and the deferred/retry path (both covered by unit tests).
