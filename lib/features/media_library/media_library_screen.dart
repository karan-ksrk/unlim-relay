import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/models/media_enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/media_inventory_repository.dart';
import 'media_access_notice.dart';
import 'media_display.dart';
import 'media_library_providers.dart';
import 'media_scan_controller.dart';
import 'media_thumbnail.dart';
import '../transfer/transfer_controller.dart';

/// Items picked for "Transfer selected". Only pending or failed items can
/// be selected; manual deletion of transferred items comes in Milestone 6.
final librarySelectionProvider =
    NotifierProvider.autoDispose<LibrarySelection, Set<int>>(
      LibrarySelection.new,
    );

class LibrarySelection extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void toggle(int id) => state = state.contains(id)
      ? ({...state}..remove(id))
      : {...state, id};

  void clear() => state = const {};
}

bool _selectable(MediaItem item) =>
    item.status == TransferStatus.pending ||
    item.status == TransferStatus.failed;

/// Sender library: Pending, Transferred and Failed tabs (plan §10).
class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key, this.initialTab = LibraryTab.pending});

  final LibraryTab initialTab;

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The user may have changed photo access in system settings.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(mediaAccessProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(inventoryStatsProvider).value ?? InventoryStats.empty;
    final scan = ref.watch(mediaScanControllerProvider);
    final selection = ref.watch(librarySelectionProvider);
    final paired = ref.watch(pairedDeviceProvider).value != null;
    final transferring = ref.watch(transferControllerProvider).isRunning;

    return DefaultTabController(
      length: LibraryTab.values.length,
      initialIndex: widget.initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          leading: selection.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear selection',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: ref.read(librarySelectionProvider.notifier).clear,
                ),
          title: Text(
            selection.isEmpty
                ? 'Camera library'
                : '${formatCount(selection.length)} selected',
          ),
          actions: [
            if (selection.isNotEmpty)
              IconButton(
                tooltip: paired ? 'Transfer selected' : 'Pair a receiver first',
                icon: const Icon(Icons.send_rounded),
                onPressed: paired && !transferring
                    ? () {
                        ref
                            .read(transferControllerProvider.notifier)
                            .start(itemIds: selection);
                        ref.read(librarySelectionProvider.notifier).clear();
                        context.push(AppRoutes.transfer);
                      }
                    : null,
              )
            else
              IconButton(
                tooltip: 'Scan again',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: scan.isBusy
                    ? null
                    : ref.read(mediaScanControllerProvider.notifier).scan,
              ),
          ],
          bottom: TabBar(
            tabs: [
              for (final tab in LibraryTab.values)
                Tab(text: '${tab.label} (${formatCount(stats.countFor(tab))})'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (scan.isBusy)
              LinearProgressIndicator(
                value: scan.total > 0 ? scan.scanned / scan.total : null,
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: MediaAccessNotice(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final tab in LibraryTab.values) _LibraryTabView(tab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTabView extends ConsumerWidget {
  const _LibraryTabView(this.tab);

  final LibraryTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(libraryTabItemsProvider(tab))) {
      AsyncData(value: final items) when items.isEmpty => _EmptyTab(tab),
      AsyncData(value: final items) => _MediaGrid(items),
      AsyncError(:final error) => Center(child: Text('Could not load: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _MediaGrid extends ConsumerWidget {
  const _MediaGrid(this.items);

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(librarySelectionProvider);
    final selector = ref.read(librarySelectionProvider.notifier);
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selectable = _selectable(item);
        return MediaThumbnail(
          key: ValueKey(item.id),
          item: item,
          selected: selection.contains(item.id),
          onLongPress: selectable ? () => selector.toggle(item.id) : null,
          onTap: selection.isNotEmpty && selectable
              ? () => selector.toggle(item.id)
              : () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _MediaDetails(item),
                ),
        );
      },
    );
  }
}

class _EmptyTab extends ConsumerWidget {
  const _EmptyTab(this.tab);

  final LibraryTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final neverScanned = ref.watch(lastScanAtProvider).value == null;
    final message = switch (tab) {
      LibraryTab.pending when neverScanned =>
        'Scan your camera library to find photos and videos to transfer.',
      LibraryTab.pending => 'Nothing waiting to transfer.',
      LibraryTab.transferred =>
        'Nothing transferred yet. Files show up here once the receiver has '
            'verified and saved them.',
      LibraryTab.failed => 'No failed transfers.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (tab == LibraryTab.pending && neverScanned) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: ref.read(mediaScanControllerProvider.notifier).scan,
                child: const Text('Scan camera library'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaDetails extends StatelessWidget {
  const _MediaDetails(this.item);

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final taken = item.dateTakenMillis;
    final rows = <(String, String)>[
      ('Status', item.status.label),
      if (taken != null)
        (
          'Taken',
          formatDateTime(
            context,
            DateTime.fromMillisecondsSinceEpoch(taken),
          ),
        ),
      ('Size', formatBytes(item.sizeBytes)),
      ('Type', item.mimeType),
      if (item.relativePath != null) ('Folder', item.relativePath!),
      if (item.transferredAt != null)
        ('Transferred', formatDateTime(context, item.transferredAt!)),
      if (item.lastError != null) ('Error', item.lastError!),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
