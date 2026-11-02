import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/app.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, FakeSettingsRepository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(db: db, settings: repo),
        child: const LumaSyncApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fresh install opens onboarding', (tester) async {
    await pumpApp(tester, FakeSettingsRepository());

    expect(find.text('Your memories. Everywhere.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('choosing a role persists it and opens home', (tester) async {
    final repo = FakeSettingsRepository();
    await pumpApp(tester, repo);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('What does this phone do?'), findsOneWidget);

    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tester.tap(find.text('Sender'));
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(repo.role, DeviceRole.sender);
    expect(find.text('Sender phone'), findsOneWidget);
    expect(find.text('Camera library'), findsOneWidget);
  });

  testWidgets('stored role skips onboarding', (tester) async {
    await pumpApp(tester, FakeSettingsRepository(DeviceRole.receiver));

    expect(find.text('Receiver phone'), findsOneWidget);
    expect(find.text('DCIM/Camera'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('changing role in settings returns to onboarding', (
    tester,
  ) async {
    final repo = FakeSettingsRepository(DeviceRole.sender);
    await pumpApp(tester, repo);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Change role'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Change role'));
    await tester.pumpAndSettle();

    expect(repo.role, isNull);
    expect(find.text('Get started'), findsOneWidget);
  });
}
