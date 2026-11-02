import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/providers.dart';
import 'package:lumasync/features/launch/launch_intro.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;
  late FakeLaunchSound sound;
  late FakeSettingsRepository settings;

  setUp(() {
    db = memoryDatabase();
    sound = FakeLaunchSound();
    settings = FakeSettingsRepository();
  });
  tearDown(() => db.close());

  Future<void> pumpIntro(
    WidgetTester tester, {
    bool soundOn = true,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          launchSoundProvider.overrideWithValue(sound),
          initialLaunchSoundProvider.overrideWithValue(soundOn),
        ],
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const MaterialApp(
            home: LaunchIntro(child: Scaffold(body: Text('Home'))),
          ),
        ),
      ),
    );
  }

  testWidgets('plays once with sound, then reveals the app', (tester) async {
    await pumpIntro(tester);
    await tester.pump();

    expect(sound.plays, 1);
    expect(find.bySemanticsLabel('UNLIM RELAY'), findsOneWidget);

    await tester.pump(LaunchIntro.duration);
    await tester.pump();
    expect(find.bySemanticsLabel('UNLIM RELAY'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the sound setting is respected', (tester) async {
    await pumpIntro(tester, soundOn: false);
    await tester.pump();

    expect(sound.plays, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('a tap skips to the end', (tester) async {
    await pumpIntro(tester);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.bySemanticsLabel('UNLIM RELAY'), warnIfMissed: false);
    // The skip animation's clock starts on the next frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.bySemanticsLabel('UNLIM RELAY'), findsNothing);
  });

  testWidgets('with animations off it only fades, silently', (tester) async {
    await pumpIntro(tester, reduceMotion: true);
    await tester.pump();

    expect(sound.plays, 0);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.bySemanticsLabel('UNLIM RELAY'), findsNothing);
  });

  testWidgets('the launch sound switch is saved', (tester) async {
    final container = ProviderContainer.test(
      overrides: appOverrides(db: db, settings: settings),
    );

    await container.read(launchSoundEnabledProvider.notifier).set(false);

    expect(container.read(launchSoundEnabledProvider), isFalse);
    expect(settings.launchSound, isFalse);
  });
}
