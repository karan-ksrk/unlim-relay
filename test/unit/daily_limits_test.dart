import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/models/transfer_limits.dart';
import 'package:lumasync/services/daily_limits.dart';

import '../fixtures/media_fixtures.dart';

void main() {
  var nextId = 0;
  MediaItem photo() => storedItem(nextId++, scanned('p$nextId'));
  MediaItem video() =>
      storedItem(nextId++, scanned('v$nextId', kind: MediaKind.video));

  test('takes photos and videos up to the default limits', () {
    final candidates = [
      for (var i = 0; i < 120; i++) photo(),
      for (var i = 0; i < 8; i++) video(),
    ];

    final allowance = applyDailyLimits(
      candidates,
      const TransferLimits(),
      photosSentToday: 0,
      videosSentToday: 0,
    );

    expect(
      allowance.selected.where((i) => i.kind == MediaKind.image),
      hasLength(100),
    );
    expect(
      allowance.selected.where((i) => i.kind == MediaKind.video),
      hasLength(5),
    );
    expect(allowance.deferredPhotos, 20);
    expect(allowance.deferredVideos, 3);
  });

  test("what was already sent today comes out of today's allowance", () {
    final allowance = applyDailyLimits(
      [photo(), photo(), video()],
      const TransferLimits(photosPerDay: 100, videosPerDay: 5),
      photosSentToday: 99,
      videosSentToday: 5,
    );

    expect(allowance.selected, hasLength(1));
    expect(allowance.deferredPhotos, 1);
    expect(allowance.deferredVideos, 1);
  });

  test('null means no limit', () {
    final allowance = applyDailyLimits(
      [for (var i = 0; i < 300; i++) photo(), video()],
      const TransferLimits(photosPerDay: null, videosPerDay: 0),
      photosSentToday: 1000,
      videosSentToday: 0,
    );

    expect(allowance.selected, hasLength(300));
    expect(allowance.deferredVideos, 1);
  });

  test('keeps the candidate order', () {
    final items = [video(), photo(), photo()];

    final allowance = applyDailyLimits(
      items,
      const TransferLimits(photosPerDay: 1, videosPerDay: 1),
      photosSentToday: 0,
      videosSentToday: 0,
    );

    expect(allowance.selected, [items[0], items[1]]);
  });

  test('startOfDay is local midnight', () {
    expect(startOfDay(DateTime(2026, 11, 2, 23, 59)), DateTime(2026, 11, 2));
  });
}
