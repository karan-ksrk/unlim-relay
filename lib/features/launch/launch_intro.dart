import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_info.dart';
import '../../app/theme.dart';
import '../../app/widgets/relay_loop.dart';
import '../../data/plugin_adapters/launch_sound.dart';
import '../../data/providers.dart';

/// Plays on cold start. Tests turn it off.
final launchIntroEnabledProvider = Provider<bool>((ref) => true);

final launchSoundProvider = Provider<LaunchSound>(
  (ref) => const AudioplayersLaunchSound(),
);

/// Read in `main` before the first frame, so the sound can start with it.
final initialLaunchSoundProvider = Provider<bool>((ref) => true);

final launchSoundEnabledProvider = NotifierProvider<LaunchSoundSetting, bool>(
  LaunchSoundSetting.new,
);

class LaunchSoundSetting extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialLaunchSoundProvider);

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(settingsRepositoryProvider).saveLaunchSound(enabled);
  }
}

/// The launch animation, drawn over the app while it starts.
///
/// 0–0.5 s the Relay Loop draws itself and settles; 0.35–0.85 s a light
/// travels once around it with a comet tail; at 0.8 s it glows and a ripple
/// spreads as the chime lands; the wordmark rises in letter by letter; at
/// 1.0 s everything lifts away to the app underneath. Tap to skip. With
/// "remove animations" on, it only fades.
class LaunchIntro extends ConsumerStatefulWidget {
  const LaunchIntro({super.key, required this.child});

  final Widget child;

  static const duration = Duration(milliseconds: 1250);

  @override
  ConsumerState<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends ConsumerState<LaunchIntro>
    with SingleTickerProviderStateMixin {
  static final _log = Logger('LaunchIntro');

  /// Where the exit begins, as a fraction of [LaunchIntro.duration].
  static const _exitStart = 0.8;

  late final AnimationController _controller;
  late bool _done;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: LaunchIntro.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _done = true);
            }
          });
    _done = !ref.read(launchIntroEnabledProvider);
    if (_done) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = _exitStart;
      _controller.forward();
      return;
    }
    if (ref.read(launchSoundEnabledProvider)) {
      unawaited(
        ref
            .read(launchSoundProvider)
            .play()
            .catchError((Object e) => _log.warning('Launch sound: $e')),
      );
    }
    _controller.forward();
  }

  void _skip() {
    if (_controller.value < _exitStart) _controller.value = _exitStart;
    _controller.animateTo(1, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => _IntroFrame(t: _controller.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One frame of the intro at [t] (0–1 of [LaunchIntro.duration]).
class _IntroFrame extends StatelessWidget {
  const _IntroFrame({required this.t});

  final double t;

  /// Progress of the window [startMs, endMs] at the current time.
  double _span(int startMs, int endMs, [Curve curve = Curves.linear]) {
    final ms = t * LaunchIntro.duration.inMilliseconds;
    final x = ((ms - startMs) / (endMs - startMs)).clamp(0.0, 1.0);
    return curve.transform(x);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final markSize = math.min(size.width * 0.56, 240.0);

    final draw = _span(0, 500, Curves.easeInOutCubic);
    final settle = _span(0, 600, Curves.easeOutBack);
    final travel = _span(350, 850, Curves.easeInOutSine);
    final pulse = math.sin(math.pi * _span(800, 1050));
    final ripple = _span(820, 1150, Curves.easeOutCubic);
    final exit = _span(1000, 1250, Curves.easeInCubic);

    return Opacity(
      opacity: 1 - exit,
      child: ColoredBox(
        color: RelayLoop.tileColor,
        child: CustomPaint(
          painter: _BackdropPainter(glow: 0.35 + 0.65 * pulse, ripple: ripple),
          child: Transform.scale(
            scale: 1 + 0.08 * exit,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.82 + 0.18 * settle,
                    child: SizedBox.square(
                      dimension: markSize,
                      child: CustomPaint(
                        painter: RelayLoopPainter(
                          progress: draw,
                          packet: t * LaunchIntro.duration.inMilliseconds < 350
                              ? null
                              : RelayLoop.restingPacket + travel,
                          trail: 0.16 * math.sin(math.pi * travel),
                          glow: 0.7 * pulse,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Wordmark(span: _span),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "UNLIM RELAY", rising in letter by letter while its tracking tightens.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.span});

  final double Function(int, int, [Curve]) span;

  @override
  Widget build(BuildContext context) {
    final letters = appName.split('');
    final tracking = 12 - 6 * span(450, 950, Curves.easeOutCubic);
    return Semantics(
      label: appName,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < letters.length; i++)
              _letter(letters[i], i, tracking, boldUntil: appName.indexOf(' ')),
          ],
        ),
      ),
    );
  }

  Widget _letter(
    String char,
    int i,
    double tracking, {
    required int boldUntil,
  }) {
    final appear = span(450 + i * 25, 670 + i * 25, Curves.easeOutCubic);
    return Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - appear)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tracking / 2),
          child: Text(
            char,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: i < boldUntil ? FontWeight.w700 : FontWeight.w300,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft brand glow behind the mark and the ripple when the chime lands.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.glow, required this.ripple});

  final double glow;
  final double ripple;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.7;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LumaColors.indigo.withValues(alpha: 0.28 * glow),
            LumaColors.indigo.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        center,
        size.shortestSide * (0.18 + 0.5 * ripple),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = LumaColors.cyan.withValues(alpha: 0.5 * (1 - ripple)),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.glow != glow || old.ripple != ripple;
}
