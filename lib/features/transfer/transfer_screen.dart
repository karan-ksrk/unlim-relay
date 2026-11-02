import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../../services/transfer_orchestrator.dart';
import 'transfer_controller.dart';
import 'transfer_limits_text.dart';
import '../../app/app_info.dart';

/// Transfer progress (plan §12.5): overall progress, current file, speed,
/// counts and cancel.
class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);
    final theme = Theme.of(context);
    final progress = state.progress;

    return PopScope(
      canPop: !state.isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cancel the transfer first, or wait for it to finish.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transfer'),
          automaticallyImplyLeading: !state.isRunning,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isRunning) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.cancelling
                            ? 'Cancelling after the current step…'
                            : progress == null
                            ? 'Connecting to the receiver…'
                            : 'Sending ${progress.fileIndex + 1} of '
                                  '${progress.totalFiles}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress == null || progress.totalBytes == 0
                            ? null
                            : progress.sentBytes / progress.totalBytes,
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${formatBytes(progress.sentBytes)} of '
                          '${formatBytes(progress.totalBytes)} · '
                          '${formatBytes(progress.bytesPerSecond.round())}/s',
                          style: _muted(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress.verifying
                              ? 'Receiver is verifying and saving '
                                    '${progress.currentFileName}…'
                              : '${progress.currentFileName}',
                          style: _muted(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        _Counts(
                          delivered: progress.delivered,
                          alreadyPresent: progress.alreadyPresent,
                          failed: progress.failed,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: state.cancelling ? null : controller.cancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep both phones on the same Wi-Fi with $appName open. '
                'Original files stay on this phone.',
                style: _muted(context),
              ),
            ] else if (state.phase == TransferPhase.failed)
              _ResultCard(
                icon: Icons.error_outline_rounded,
                title: 'Transfer did not start',
                lines: [state.error ?? 'Unknown error'],
                error: true,
              )
            else if (state.summary case final summary?) ...[
              _ResultCard(
                icon: summary.error == null
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                title: _summaryTitle(summary),
                error: summary.error != null,
                lines: [
                  if (!summary.nothingToSend)
                    '${summary.delivered} saved on the receiver'
                        '${summary.alreadyPresent > 0 ? ', ${summary.alreadyPresent} already there' : ''}'
                        '${summary.failed > 0 ? ', ${summary.failed} failed' : ''}.',
                  if (summary.error != null) summary.error!,
                  if (summary.deferredPhotos + summary.deferredVideos > 0)
                    '${countOf(summary.deferredPhotos, 'photo')} and '
                        '${countOf(summary.deferredVideos, 'video')} wait for '
                        'tomorrow because of the daily limit.',
                ],
              ),
              if (summary.deferredPhotos + summary.deferredVideos > 0 &&
                  summary.error == null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => controller.start(extraBatch: true),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Run next batch'),
                ),
                const SizedBox(height: 8),
                Text(switch (ref.watch(transferLimitsProvider).value) {
                  final limits? =>
                    'Sends up to ${describeBatchSize(limits)} more now, '
                        "newest first, even though today's limit is used up.",
                  null => "Sends one more batch now, ignoring today's limit.",
                }, style: _muted(context)),
              ],
            ],
            const SizedBox(height: 8),
            const TransferLimitsText(),
          ],
        ),
      ),
    );
  }

  static String _summaryTitle(TransferSummary summary) {
    if (summary.cancelled) return 'Transfer cancelled';
    if (summary.error != null) return 'Transfer stopped';
    if (summary.nothingToSend) {
      return summary.deferredPhotos + summary.deferredVideos > 0
          ? "Today's limit is reached"
          : 'Nothing to send';
    }
    return 'Transfer complete';
  }
}

class _Counts extends StatelessWidget {
  const _Counts({
    required this.delivered,
    required this.alreadyPresent,
    required this.failed,
  });

  final int delivered;
  final int alreadyPresent;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.check_rounded, size: 18),
          label: Text('$delivered saved'),
        ),
        if (alreadyPresent > 0)
          Chip(
            avatar: const Icon(Icons.done_all_rounded, size: 18),
            label: Text('$alreadyPresent already there'),
          ),
        if (failed > 0)
          Chip(
            avatar: const Icon(Icons.error_outline_rounded, size: 18),
            label: Text('$failed failed'),
          ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.lines,
    this.error = false,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: error ? scheme.error : scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            for (final line in lines) ...[
              const SizedBox(height: 8),
              Text(line),
            ],
          ],
        ),
      ),
    );
  }
}

TextStyle? _muted(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
