import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/app.dart';
import 'package:lumasync/app/router.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/models/transfer_limits.dart';
import 'package:lumasync/data/providers.dart';
import 'package:lumasync/features/transfer/transfer_controller.dart';
import 'package:lumasync/services/transfer_orchestrator.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<ProviderContainer> pumpSender(
    WidgetTester tester,
    FakeSettingsRepository settings,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(db: db, settings: settings),
        child: const LumaSyncApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(LumaSyncApp)));
  }

  testWidgets('home shows the transfer card and today\'s allowance', (
    tester,
  ) async {
    await pumpSender(tester, FakeSettingsRepository(DeviceRole.sender));

    expect(find.text('Transfer now'), findsOneWidget);
    expect(find.text('Today: 0 of 100 photos · 0 of 5 videos'), findsOneWidget);
    expect(
      find.text('Pair with the receiver to start sending.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Transfer now'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('daily limits can be changed in settings', (tester) async {
    final settings = FakeSettingsRepository(DeviceRole.sender);
    await pumpSender(tester, settings);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('100 photos and 5 videos a day'), findsOneWidget);

    await tester.tap(find.text('Daily transfer limit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Photos per day'),
      '40',
    );
    // Turn the video limit off.
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      settings.limits,
      const TransferLimits(photosPerDay: 40, videosPerDay: null),
    );
    expect(find.text('40 photos and unlimited videos a day'), findsOneWidget);
  });

  testWidgets('receiver home shows received totals', (tester) async {
    final container = await pumpSender(
      tester,
      FakeSettingsRepository(DeviceRole.receiver),
    );
    await container
        .read(receivedFilesRepositoryProvider)
        .add(
          ReceivedFilesCompanion.insert(
            senderDeviceId: 's',
            transferId: 's:1',
            sha256: 'a' * 64,
            sizeBytes: 2 * 1024 * 1024,
            originalName: 'IMG_1.jpg',
            publishedMediaId: '1',
            publishedName: 'IMG_1.jpg',
            acknowledgementId: 'ack',
            receivedAt: DateTime(2026, 11, 2, 14),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('Received'), findsOneWidget);
    expect(find.text('1 file · 2.0 MB'), findsOneWidget);
  });

  testWidgets('limit reached offers "Run next batch"', (tester) async {
    final fake = _FakeTransferController(
      const TransferState(
        phase: TransferPhase.done,
        summary: TransferSummary(deferredPhotos: 4745, deferredVideos: 592),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...appOverrides(
            db: db,
            settings: FakeSettingsRepository(DeviceRole.sender),
          ),
          transferControllerProvider.overrideWith(() => fake),
        ],
        child: const LumaSyncApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LumaSyncApp)),
    );
    container.read(routerProvider).push(AppRoutes.transfer);
    await tester.pumpAndSettle();

    expect(find.text("Today's limit is reached"), findsOneWidget);
    expect(find.text('Run next batch'), findsOneWidget);
    expect(
      find.textContaining('100 photos and 5 videos more now'),
      findsOneWidget,
    );

    await tester.tap(find.text('Run next batch'));
    expect(fake.lastExtraBatch, isTrue);
  });
}

class _FakeTransferController extends TransferController {
  _FakeTransferController(this._initial);

  final TransferState _initial;
  bool? lastExtraBatch;

  @override
  TransferState build() => _initial;

  @override
  Future<void> start({Set<int>? itemIds, bool extraBatch = false}) async {
    lastExtraBatch = extraBatch;
  }
}
