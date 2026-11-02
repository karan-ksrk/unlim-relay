enum MediaKind { image, video }

/// Per-file lifecycle (plan §5 and §7).
enum TransferStatus {
  pending,
  queued,
  transferring,
  verifying,
  publishing,
  transferred,
  failed,
  skipped,
}

/// The sender library tabs and the statuses each one lists (plan §10).
enum LibraryTab {
  pending({
    TransferStatus.pending,
    TransferStatus.queued,
    TransferStatus.transferring,
    TransferStatus.verifying,
    TransferStatus.publishing,
  }),
  transferred({TransferStatus.transferred}),
  failed({TransferStatus.failed});

  const LibraryTab(this.statuses);

  final Set<TransferStatus> statuses;

  static LibraryTab fromName(String? name) =>
      LibraryTab.values.asNameMap()[name] ?? LibraryTab.pending;
}
