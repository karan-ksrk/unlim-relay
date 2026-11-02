import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import 'media_library_providers.dart';

final _log = Logger('CleanupFlow');

/// Deletes the selected transferred originals after the user confirms
/// twice: our dialog (counts, size, what it means), then Android's own
/// prompt. Returns whether anything was deleted.
Future<bool> confirmAndDeleteOriginals(
  BuildContext context,
  WidgetRef ref,
  Set<int> ids,
) async {
  final service = ref.read(mediaCleanupServiceProvider);
  final messenger = ScaffoldMessenger.of(context);
  final review = await service.review(ids);
  if (!context.mounted) return false;

  if (review.deletable.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nothing to delete'),
        content: Text(
          review.held.isEmpty
              ? 'None of the selected files can be deleted.'
              : review.held.first.$2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  final receiver = ref.read(pairedDeviceProvider).value?.displayName;
  final count = countOf(review.deletable.length, 'transferred file');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
        ),
        title: Text(
          'Delete $count (${formatBytes(review.bytes)}) from this '
          'phone?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verified copies are recorded on '
              '${receiver ?? 'the receiver'}. This removes the selected '
              'originals from this phone, and Android will ask you to '
              'confirm.',
            ),
            const SizedBox(height: 12),
            Text(
              'The receiver can still delete its copies on its own; this app '
              'can’t keep them there for you.',
              style: theme.textTheme.bodySmall,
            ),
            if (review.held.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${countOf(review.held.length, 'selected file')} will be '
                'kept: ${review.held.first.$2}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return false;

  try {
    final result = await service.delete(review);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.declined
              ? 'Nothing was deleted.'
              : 'Deleted ${countOf(result.deleted, 'file')} · freed '
                    '${formatBytes(result.bytes)}.',
        ),
      ),
    );
    return !result.declined;
  } on Object catch (error, stackTrace) {
    _log.warning('Deleting originals failed', error, stackTrace);
    messenger.showSnackBar(SnackBar(content: Text('Could not delete: $error')));
    return false;
  }
}
