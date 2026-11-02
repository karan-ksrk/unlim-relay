import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../../data/repositories/media_inventory_repository.dart';
import 'media_library_providers.dart';
import 'media_scan_controller.dart';

/// Sender home card: inventory totals, last scan and the scan action.
class CameraLibraryCard extends ConsumerWidget {
  const CameraLibraryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(inventoryStatsProvider).value ?? InventoryStats.empty;
    final lastScanAt = ref.watch(lastScanAtProvider).value;
    final scan = ref.watch(mediaScanControllerProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Camera library',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text('DCIM/Camera', style: muted),
              ],
            ),
            const SizedBox(height: 12),
            if (lastScanAt == null)
              Text('Not scanned yet', style: muted)
            else ...[
              Text(
                '${formatCount(stats.photos)} photos · '
                '${formatCount(stats.videos)} videos · '
                '${formatBytes(stats.totalBytes)}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Last scanned ${formatDateTime(context, lastScanAt)}',
                style: muted,
              ),
            ],
            if (scan.isBusy) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: scan.total > 0 ? scan.scanned / scan.total : null,
              ),
              const SizedBox(height: 8),
              Text(
                scan.phase == ScanPhase.requestingAccess
                    ? 'Waiting for photo access…'
                    : scan.total == 0
                    ? 'Scanning…'
                    : 'Scanning ${formatCount(scan.scanned)} of '
                          '${formatCount(scan.total)}…',
                style: muted,
              ),
            ],
            if (scan.phase == ScanPhase.done && scan.summary != null) ...[
              const SizedBox(height: 8),
              Text(_summaryText(scan), style: muted),
            ],
            if (scan.phase == ScanPhase.failed) ...[
              const SizedBox(height: 8),
              Text(
                'Scan failed: ${scan.error}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: scan.isBusy
                    ? null
                    : ref.read(mediaScanControllerProvider.notifier).scan,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  lastScanAt == null ? 'Scan camera library' : 'Scan again',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _summaryText(MediaScanState scan) {
    final s = scan.summary!;
    final parts = [
      '${formatCount(s.added)} new',
      if (s.changed > 0) '${formatCount(s.changed)} changed',
      if (s.removed > 0) '${formatCount(s.removed)} removed',
      if (s.restored > 0) '${formatCount(s.restored)} back',
    ];
    final seconds = (s.duration.inMilliseconds / 1000).toStringAsFixed(1);
    return 'Scan complete: ${parts.join(', ')} · ${seconds}s';
  }
}
