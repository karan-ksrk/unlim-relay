# Receiving in the background

While *Ready to receive* is on, the receiver runs an Android foreground
service (`flutter_foreground_task`, type `connectedDevice`) with a "Ready to
receive" notification. The service has no Dart task of its own; it keeps
the app's process alive and holds a CPU wake lock and a Wi-Fi lock, so the
receiver server in the app's isolate keeps accepting connections when:

- the screen is off or locked,
- another app is open, or
- the phone is in Doze.

It stops when the switch is turned off, when the app is swiped away from
recents (`android:stopWithTask="true"`; the receiver lived in the app's
engine, so the notification would otherwise be lying), or on force-stop.
Opening the app again resumes listening, because the switch is remembered.

If Android refuses to start the service, the app falls back to keeping the
screen on, and the home tile says so ("Keep this screen open").

## Gotcha

The plugin's own `stopWithTask: true` option does not mean "stop when
swiped away": it stops the service as soon as every activity pauses, i.e.
on Home or screen off. It is left unset; the manifest attribute is used
instead.

## Verified on device (2 Nov 2026)

Redmi Note 7 Pro (Pixel OS, Android 13), receiver app on Home, screen off,
`dumpsys deviceidle force-idle` (deep Doze): the iQOO's connection test
connected over TLS in 27 ms and the receiver acknowledged a 100-file
manifest. Process state stayed at foreground service (4).

Not yet verified on device: a full file transfer into a dozing receiver
(today's daily limit was used up), swipe-away stopping the service, and
many hours of standby. The service's partial wake lock costs battery while
the switch is on, so keep the receiver charging for long sessions.
