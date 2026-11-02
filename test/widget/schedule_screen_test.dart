import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/app.dart';
import 'package:lumasync/app/router.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/repositories/schedule_repository.dart';
import 'package:lumasync/services/scheduled_transfer_job.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_schedule_plugins.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;
  late FakeBackgroundScheduler scheduler;
  late FakeTransferNotifications notifications;

  setUp(() {
    db = memoryDatabase();
    scheduler = FakeBackgroundScheduler();
    notifications = FakeTransferNotifications();
  });
  tearDown(() => db.close());

  Future<void> pumpSchedule(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(
          db: db,
          settings: FakeSettingsRepository(DeviceRole.sender),
          scheduler: scheduler,
          notifications: notifications,
        ),
        child: const LumaSyncApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily transfer'), findsOneWidget, reason: 'home tile');
    await tester.tap(find.text('Daily transfer'));
    await tester.pumpAndSettle();
  }

  testWidgets('turning the schedule on registers it and asks to notify', (
    tester,
  ) async {
    await pumpSchedule(tester);
    expect(find.text('Next run'), findsOneWidget);
    expect(scheduler.scheduledAt, isNull);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Daily transfer'));
    await tester.pumpAndSettle();

    final saved = await DriftScheduleRepository(db).readSettings();
    expect(saved.enabled, isTrue);
    expect(saved.enabledAt, isNotNull);
    expect(scheduler.scheduledAt, isNotNull);
    expect(notifications.permissionRequests, 1);
    expect(find.textContaining('around'), findsWidgets);
  });

  testWidgets('days can be switched off', (tester) async {
    await pumpSchedule(tester);

    await tester.tap(find.byTooltip('Sun'));
    await tester.pumpAndSettle();

    expect(find.text('Mon, Tue, Wed, Thu, Fri, Sat'), findsOneWidget);
    final saved = await DriftScheduleRepository(db).readSettings();
    expect(saved.weekdays, const {1, 2, 3, 4, 5, 6});
  });

  testWidgets('Run now needs a paired receiver', (tester) async {
    await pumpSchedule(tester);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Run now'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('progress from a background run is shown', (tester) async {
    await pumpSchedule(tester);

    scheduler.progressListener!({
      ScheduledProgress.fileIndex: 1,
      ScheduledProgress.totalFiles: 5,
      ScheduledProgress.sentBytes: 1024 * 1024,
      ScheduledProgress.totalBytes: 5 * 1024 * 1024,
      ScheduledProgress.fileName: 'IMG_2.jpg',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('sending 2 of 5'), findsOneWidget);

    // Home shows it too and holds back Transfer now.
    final router = ProviderScope.containerOf(
      tester.element(find.byType(LumaSyncApp)),
    ).read(routerProvider);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.textContaining('sending 2 of 5'), findsOneWidget);
  });
}
