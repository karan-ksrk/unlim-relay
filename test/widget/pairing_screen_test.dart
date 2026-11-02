import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/app.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/providers.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<ProviderContainer> pump(WidgetTester tester, DeviceRole role) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(db: db, settings: FakeSettingsRepository(role)),
        child: const LumaSyncApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(LumaSyncApp)));
  }

  testWidgets('unpaired sender is offered the scanner', (tester) async {
    await pump(tester, DeviceRole.sender);
    expect(find.text('Not paired'), findsOneWidget);

    await tester.tap(find.text('Receiver'));
    await tester.pumpAndSettle();

    expect(find.text('Pair with receiver'), findsOneWidget);
    expect(find.text('Scan pairing code'), findsOneWidget);
  });

  testWidgets('paired sender can test the connection and unpair', (
    tester,
  ) async {
    final container = await pump(tester, DeviceRole.sender);
    await container
        .read(pairingRepositoryProvider)
        .savePairing(
          PairedDevice(
            deviceId: 'r1',
            displayName: 'Redmi Note 7 Pro',
            peerRole: DeviceRole.receiver,
            certificateFingerprint: 'ab' * 32,
            lastKnownHost: '192.168.1.20',
            lastKnownPort: 47863,
            pairedAt: DateTime(2026, 11, 2),
          ),
          authToken: 'token',
        );
    await tester.pumpAndSettle();
    expect(find.text('Redmi Note 7 Pro'), findsOneWidget);

    await tester.tap(find.text('Receiver'));
    await tester.pumpAndSettle();
    expect(find.text('Test connection'), findsOneWidget);

    await tester.tap(find.text('Unpair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpair').last);
    await tester.pumpAndSettle();

    expect(
      await container.read(pairingRepositoryProvider).pairedDevice(),
      isNull,
    );
    expect(find.text('Scan pairing code'), findsOneWidget);
  });

  testWidgets('receiver home shows the Ready to receive switch', (
    tester,
  ) async {
    await pump(tester, DeviceRole.receiver);

    expect(find.text('Ready to receive'), findsOneWidget);
    expect(find.text('Keeps the screen on while receiving'), findsOneWidget);
    expect(find.text('Sender'), findsOneWidget);
  });
}
