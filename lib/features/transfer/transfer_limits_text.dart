import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/transfer_limits.dart';
import 'transfer_controller.dart';

/// "Today: 37 of 100 photos · 2 of 5 videos".
class TransferLimitsText extends ConsumerWidget {
  const TransferLimitsText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(transferLimitsProvider).value;
    final today = ref.watch(transferredTodayProvider).value;
    if (limits == null || today == null) return const SizedBox.shrink();
    return Text(
      'Today: ${usageText(today.photos, limits.photosPerDay, 'photo')} · '
      '${usageText(today.videos, limits.videosPerDay, 'video')}',
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  static String usageText(int used, int? limit, String noun) {
    if (limit == null) return '${countOf(used, noun)} (no limit)';
    // Over the limit after "Run next batch".
    if (used > limit) {
      return '${countOf(used, noun)} (limit ${formatCount(limit)})';
    }
    return '${formatCount(used)} of ${countOf(limit, noun)}';
  }
}

/// "100 photos and 5 videos a day".
String describeLimits(TransferLimits limits) =>
    '${describeBatchSize(limits)} a day';

/// "100 photos and 5 videos": one daily batch.
String describeBatchSize(TransferLimits limits) {
  String part(int? limit, String noun) =>
      limit == null ? 'unlimited ${noun}s' : countOf(limit, noun);
  return '${part(limits.photosPerDay, 'photo')} and '
      '${part(limits.videosPerDay, 'video')}';
}
