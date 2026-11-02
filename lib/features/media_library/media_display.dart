import 'package:material_ui/material_ui.dart';

import '../../data/models/media_enums.dart';

extension LibraryTabDisplay on LibraryTab {
  String get label => switch (this) {
    LibraryTab.pending => 'Pending',
    LibraryTab.transferred => 'Transferred',
    LibraryTab.failed => 'Failed',
  };

  IconData get icon => switch (this) {
    LibraryTab.pending => Icons.hourglass_top_rounded,
    LibraryTab.transferred => Icons.cloud_done_outlined,
    LibraryTab.failed => Icons.error_outline_rounded,
  };
}

extension TransferStatusDisplay on TransferStatus {
  String get label => switch (this) {
    TransferStatus.pending => 'Pending',
    TransferStatus.queued => 'Queued',
    TransferStatus.transferring => 'Transferring',
    TransferStatus.verifying => 'Verifying',
    TransferStatus.publishing => 'Saving on receiver',
    TransferStatus.transferred => 'Transferred',
    TransferStatus.failed => 'Failed',
    TransferStatus.skipped => 'Skipped',
  };
}
