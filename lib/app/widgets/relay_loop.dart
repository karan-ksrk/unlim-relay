import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// The Relay Loop mark: an infinity loop (unlimited) with a light travelling
/// along it (the relay). Drawn in a 512-unit square, the same geometry as
/// the launcher icon in `res/drawable/ic_launcher_foreground.xml`.
abstract final class RelayLoop {
  static const units = 512.0;
  static const strokeWidth = 48.0;

  /// Dark tile behind the mark (launcher icon, splash, launch animation).
  static const tileColor = Color(0xFF12111F);

  /// Where the light rests when the mark is still.
  static const restingPacket = 0.6;

  static final Path path = Path()
    ..moveTo(256, 256)
    ..cubicTo(210, 186, 112, 186, 112, 256)
    ..cubicTo(112, 326, 210, 326, 256, 256)
    ..cubicTo(302, 186, 400, 186, 400, 256)
    ..cubicTo(400, 326, 302, 326, 256, 256)
    ..close();

  static final ui.PathMetric metric = path.computeMetrics().first;

  /// Matches the SVG's objectBoundingBox gradient: bottom-left to top-right.
  static final Shader shader = const LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [LumaColors.cyan, LumaColors.indigo, LumaColors.violet],
    stops: [0, 0.55, 1],
  ).createShader(const Rect.fromLTRB(112, 203, 400, 309));
}

/// Paints the mark. [progress] is how much of the loop is drawn (0–1);
/// [packet] is the light's position along the loop, or `null` to hide it;
/// [trail] is the length of its comet tail as a fraction of the loop;
/// [glow] adds a soft halo (0–1).
class RelayLoopPainter extends CustomPainter {
  RelayLoopPainter({
    this.progress = 1,
    this.packet = RelayLoop.restingPacket,
    this.trail = 0,
    this.glow = 0,
    this.packetColor = Colors.white,
  });

  final double progress;
  final double? packet;
  final double trail;
  final double glow;
  final Color packetColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / RelayLoop.units;
    canvas
      ..save()
      ..translate(
        (size.width - RelayLoop.units * scale) / 2,
        (size.height - RelayLoop.units * scale) / 2,
      )
      ..scale(scale);

    final metric = RelayLoop.metric;
    final length = metric.length;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = RelayLoop.strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = progress < 1 ? StrokeCap.round : StrokeCap.butt
      ..shader = RelayLoop.shader;

    final loop = progress >= 1
        ? RelayLoop.path
        : metric.extractPath(0, length * progress.clamp(0, 1));

    if (glow > 0) {
      canvas.drawPath(
        loop,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = RelayLoop.strokeWidth * 1.6
          ..shader = RelayLoop.shader
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 28 * glow)
          ..color = Colors.white.withValues(alpha: glow.clamp(0, 1)),
      );
    }
    if (progress > 0) canvas.drawPath(loop, stroke);

    final at = packet;
    if (at != null) {
      final distance = (at % 1) * length;
      if (trail > 0) {
        final start = distance - trail * length;
        final tail = start >= 0
            ? metric.extractPath(start, distance)
            : (metric.extractPath(length + start, length)
                ..addPath(metric.extractPath(0, distance), Offset.zero));
        canvas.drawPath(
          tail,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = RelayLoop.strokeWidth * 0.42
            ..strokeCap = StrokeCap.round
            ..color = packetColor.withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 20, Paint()..color = packetColor);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(RelayLoopPainter old) =>
      old.progress != progress ||
      old.packet != packet ||
      old.trail != trail ||
      old.glow != glow ||
      old.packetColor != packetColor;
}

/// The brand mark on its dark rounded tile, as on the launcher.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: RelayLoop.tileColor,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: CustomPaint(painter: RelayLoopPainter()),
    );
  }
}
