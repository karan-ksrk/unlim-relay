// Renders the legacy (pre-Android 8) launcher PNGs from the same painter the
// app uses. Android 8+ uses the vector adaptive icon instead.
//
//   flutter test tool/render_launcher_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/widgets/relay_loop.dart';
import 'package:material_ui/material_ui.dart';

const _densities = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

void main() {
  testWidgets('render launcher icons', (tester) async {
    for (final MapEntry(key: density, value: pixels) in _densities.entries) {
      final bytes = await _render(tester, pixels.toDouble());
      File('android/app/src/main/res/mipmap-$density/ic_launcher.png')
          .writeAsBytesSync(bytes);
    }
    // A large copy for checking the artwork by eye.
    File('build/launcher_icon_preview.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(await _render(tester, 512));
  });
}

Future<List<int>> _render(WidgetTester tester, double size) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: RelayLoop.tileColor,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: CustomPaint(painter: RelayLoopPainter()),
            ),
          ),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  return bytes!;
}
