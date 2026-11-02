import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/app.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/plugin_adapters/media_library.dart';
import 'package:lumasync/features/media_library/media_thumbnail.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<void> pumpSender(WidgetTester tester, FakeMediaLibrary library) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(
          db: db,
          settings: FakeSettingsRepository(DeviceRole.sender),
          library: library,
        ),
        child: const LumaSyncApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('scanning fills the sender home and library', (tester) async {
    final library = FakeMediaLibrary(
      media: [
        scanned('1', size: 1024 * 1024),
        scanned('2', size: 1024 * 1024),
        scanned('3', size: 2 * 1024 * 1024, kind: MediaKind.video),
      ],
    );
    await pumpSender(tester, library);
    expect(find.text('Not scanned yet'), findsOneWidget);

    await tester.tap(find.text('Scan camera library'));
    await tester.pumpAndSettle();

    expect(find.text('2 photos · 1 videos · 4.0 MB'), findsOneWidget);
    expect(find.text('3 · 4.0 MB'), findsOneWidget);
    expect(find.textContaining('Scan complete: 3 new'), findsOneWidget);

    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(find.text('Pending (3)'), findsOneWidget);
    expect(find.text('Transferred (0)'), findsOneWidget);
    expect(find.byType(MediaThumbnail), findsNWidgets(3));

    await tester.tap(find.byType(MediaThumbnail).first);
    await tester.pumpAndSettle();
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('DCIM/Camera/'), findsOneWidget);
  });

  testWidgets('denied access explains how to fix it', (tester) async {
    await pumpSender(tester, FakeMediaLibrary(access: MediaAccess.denied));

    await tester.tap(find.text('Scan camera library'));
    await tester.pumpAndSettle();

    expect(find.textContaining('needs access to photos'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('Not scanned yet'), findsOneWidget);
  });

  testWidgets('empty transferred tab explains what will appear', (
    tester,
  ) async {
    await pumpSender(tester, FakeMediaLibrary(media: [scanned('1')]));
    await tester.tap(find.text('Scan camera library'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transferred'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing transferred yet'), findsOneWidget);
  });
}
