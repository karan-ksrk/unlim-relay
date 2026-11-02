import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/plugin_adapters/media_library.dart';
import 'package:lumasync/data/providers.dart';
import 'package:lumasync/features/media_library/media_scan_controller.dart';

import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  ProviderContainer createContainer(FakeMediaLibrary library) =>
      ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          mediaLibraryProvider.overrideWithValue(library),
        ],
      );

  test('denied access stops before scanning', () async {
    final library = FakeMediaLibrary(
      access: MediaAccess.denied,
      media: [scanned('1')],
    );
    final container = createContainer(library);

    await container.read(mediaScanControllerProvider.notifier).scan();

    expect(
      container.read(mediaScanControllerProvider).phase,
      ScanPhase.accessDenied,
    );
    expect(library.listCalls, 0);
  });

  test('granted access scans and reports a summary', () async {
    final library = FakeMediaLibrary(media: [scanned('1'), scanned('2')]);
    final container = createContainer(library);

    await container.read(mediaScanControllerProvider.notifier).scan();

    final state = container.read(mediaScanControllerProvider);
    expect(state.phase, ScanPhase.done);
    expect(state.summary!.added, 2);
    expect(library.accessRequests, 1);
  });

  test('limited access still scans what is visible', () async {
    final library = FakeMediaLibrary(
      access: MediaAccess.limited,
      media: [scanned('1')],
    );
    final container = createContainer(library);

    await container.read(mediaScanControllerProvider.notifier).scan();

    expect(container.read(mediaScanControllerProvider).summary!.added, 1);
  });
}
