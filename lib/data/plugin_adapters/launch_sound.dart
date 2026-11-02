import 'package:audioplayers/audioplayers.dart';

/// The short sound played with the launch animation.
abstract interface class LaunchSound {
  Future<void> play();
}

/// [LaunchSound] backed by `package:audioplayers`.
///
/// Played as a notification-type sound on the notification stream, so it
/// follows the notification volume and is muted in silent or vibrate mode.
/// It requests no audio focus, so music keeps playing.
class AudioplayersLaunchSound implements LaunchSound {
  const AudioplayersLaunchSound();

  static const asset = 'sounds/launch.wav';
  static const _length = Duration(milliseconds: 2500);

  @override
  Future<void> play() async {
    final player = AudioPlayer();
    await player.play(
      AssetSource(asset),
      volume: 0.6,
      mode: PlayerMode.lowLatency,
      ctx: AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationEvent,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    // Low-latency mode reports no completion; release after the clip.
    Future<void>.delayed(_length, player.dispose);
  }
}
