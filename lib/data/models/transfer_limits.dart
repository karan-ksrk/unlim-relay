/// Per-day caps on how many files the sender transfers. `null` means no
/// limit. Counts reset at local midnight.
class TransferLimits {
  const TransferLimits({
    this.photosPerDay = defaultPhotosPerDay,
    this.videosPerDay = defaultVideosPerDay,
  });

  static const defaultPhotosPerDay = 100;
  static const defaultVideosPerDay = 5;

  final int? photosPerDay;
  final int? videosPerDay;

  @override
  bool operator ==(Object other) =>
      other is TransferLimits &&
      other.photosPerDay == photosPerDay &&
      other.videosPerDay == videosPerDay;

  @override
  int get hashCode => Object.hash(photosPerDay, videosPerDay);
}
