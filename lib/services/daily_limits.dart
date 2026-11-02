import '../data/database/app_database.dart';
import '../data/models/media_enums.dart';
import '../data/models/transfer_limits.dart';

class DailyAllowance {
  const DailyAllowance({
    required this.selected,
    required this.deferredPhotos,
    required this.deferredVideos,
  });

  /// Items to send now, in the given order.
  final List<MediaItem> selected;

  /// Candidates held back until tomorrow by the daily limits.
  final int deferredPhotos;
  final int deferredVideos;

  int get deferred => deferredPhotos + deferredVideos;
}

/// Midnight at the start of [now]'s local day; the daily limits reset here.
DateTime startOfDay(DateTime now) => DateTime(now.year, now.month, now.day);

/// Takes candidates in order until today's photo and video allowances are
/// used up. Counts already sent today come out of the allowance.
DailyAllowance applyDailyLimits(
  List<MediaItem> candidates,
  TransferLimits limits, {
  required int photosSentToday,
  required int videosSentToday,
}) {
  var photosLeft = limits.photosPerDay == null
      ? null
      : (limits.photosPerDay! - photosSentToday).clamp(0, 1 << 31);
  var videosLeft = limits.videosPerDay == null
      ? null
      : (limits.videosPerDay! - videosSentToday).clamp(0, 1 << 31);

  final selected = <MediaItem>[];
  var deferredPhotos = 0;
  var deferredVideos = 0;
  for (final item in candidates) {
    if (item.kind == MediaKind.video) {
      if (videosLeft == null || videosLeft > 0) {
        selected.add(item);
        if (videosLeft != null) videosLeft--;
      } else {
        deferredVideos++;
      }
    } else {
      if (photosLeft == null || photosLeft > 0) {
        selected.add(item);
        if (photosLeft != null) photosLeft--;
      } else {
        deferredPhotos++;
      }
    }
  }
  return DailyAllowance(
    selected: selected,
    deferredPhotos: deferredPhotos,
    deferredVideos: deferredVideos,
  );
}
