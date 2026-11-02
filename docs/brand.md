# Brand: logo, launch animation, sound

## Logo: Relay Loop

An infinity loop (unlimited) in the brand gradient (cyan `#06B6D4` → indigo
`#4F46E5` → violet `#7C3AED`) with a white light on it (the relay), on a
dark tile `#12111F`. Chosen from five concepts on 2 Nov 2026.

One geometry, a 512-unit path, is used everywhere:

| Where | File |
| --- | --- |
| In-app mark and animation | `lib/app/widgets/relay_loop.dart` (`RelayLoopPainter`, `AppMark`) |
| Adaptive launcher icon (Android 8+) | `res/mipmap-anydpi-v26/ic_launcher.xml`, `res/drawable/ic_launcher_foreground.xml` |
| Themed icon (Android 13+) | `res/drawable/ic_launcher_monochrome.xml` |
| Legacy PNGs (Android 7) | `res/mipmap-*/ic_launcher.png`, rendered by `flutter test tool/render_launcher_icons_test.dart` |

## Launch animation

`lib/features/launch/launch_intro.dart`, drawn over the app on cold start,
1.25 seconds:

| Time | Motion |
| --- | --- |
| 0–0.5 s | The loop draws itself and settles from 82% scale |
| 0.35–0.85 s | The light travels once around it with a comet tail |
| 0.8–1.05 s | Glow pulse and a cyan ripple as the chime lands |
| 0.45–0.95 s | "UNLIM RELAY" rises in letter by letter, tracking tightens |
| 1.0–1.25 s | Lifts away (fade + slight zoom) to the app |

The Android splash (12+ and older) is the plain dark tile color with no
icon, so the system splash hands over to the animation without a jump.
Tap skips it; with "Remove animations" on it only fades and stays silent.

## Launch sound

`assets/sounds/launch.wav` (2.0 s, mono, 44.1 kHz), synthesized from scratch
by `python tool/generate_launch_sound.py` (standard library only, no
third-party audio): a band-passed noise whoosh and a low swell while the
loop draws, then an FM bell chime A5 + E6 with a sparkle at 0.82/0.92 s,
through a small Schroeder reverb.

Played with `audioplayers` in low-latency mode as a notification-type sound
(`USAGE_NOTIFICATION_EVENT`, no audio focus): it follows the notification
volume, is muted in silent/vibrate mode and doesn't pause music. Settings ›
Launch sound turns it off.

Verified on the iQOO (2 Nov 2026): the launcher icon shows, the animation
plays end to end, and Android logged the sound starting on the notification
stream with the intro.

## Startup time

Measured on the Redmi Note 7 Pro, release build, cold start: dark splash
about 0.45 s, animation about 1.15 s, home ready about 1.6 s after the tap.
Debug builds are much slower (about 4.9 s before the first frame, since
Dart isn't compiled ahead of time), so judge launch speed on a release or
profile build. Startup reads run in parallel and WorkManager setup happens
after the first frame.
