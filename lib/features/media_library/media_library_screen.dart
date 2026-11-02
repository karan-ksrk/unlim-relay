import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/models/media_enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/media_inventory_repository.dart';
import 'cleanup_flow.dart';
import 'media_access_notice.dart';
import 'media_display.dart';
import 'media_library_providers.dart';
import 'media_scan_controller.dart';
import 'media_thumbnail.dart';
import '../transfer/transfer_controller.dart';

/// Items picked in the current tab: pending or failed ones to transfer,
/// transferred ones to delete from this phone. Cleared on tab change.
final librarySelectionProvider =
    NotifierProvider.autoDispose<LibrarySelection, Set<int>>(
      LibrarySelection.new,
    );

class LibrarySelection extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void toggle(int id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void selectAll(Iterable<int> ids) => state = {...state, ...ids};

  void clear() => state = const {};
}

bool _selectable(MediaItem item, LibraryTab tab) => switch (tab) {
  LibraryTab.transferred => item.status == TransferStatus.transferred,
  _ =>
    item.status == TransferStatus.pending ||
        item.status == TransferStatus.failed,
};

/// Sender library: Pending, Transferred and Failed tabs (plan §10).
class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key, this.initialTab = LibraryTab.pending});

  final LibraryTab initialTab;

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final AppLifecycleListener _lifecycle;
  late final TabController _tabs;

  LibraryTab get _tab => LibraryTab.values[_tabs.index];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: LibraryTab.values.length,
      initialIndex: widget.initialTab.index,
      vsync: this,
    )..addListener(_onTabChanged);
    // The user may have changed photo access in system settings.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(mediaAccessProvider),
    );
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    ref.read(librarySelectionProvider.notifier).clear();
    setState(() {});
  }

  void _selectAll() {
    final items = ref.read(libraryTabItemsProvider(_tab)).value ?? const [];
    ref.read(librarySelectionProvider.notifier).selectAll([
      for (final item in items)
        if (_selectable(item, _tab)) item.id,
    ]);
  }

  void _transfer(Set<int> ids) {
    ref.read(transferControllerProvider.notifier).start(itemIds: ids);
    ref.read(librarySelectionProvider.notifier).clear();
    context.push(AppRoutes.transfer);
  }

  Future<void> _delete(Set<int> ids) async {
    if (await confirmAndDeleteOriginals(context, ref, ids)) {
      ref.read(librarySelectionProvider.notifier).clear();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats =
        ref.watch(inventoryStatsProvider).value ?? InventoryStats.empty;
    final scan = ref.watch(mediaScanControllerProvider);
    final selection = ref.watch(librarySelectionProvider);
    final paired = ref.watch(pairedDeviceProvider).value != null;
    final transferring = ref.watch(transferControllerProvider).isRunning;
    final tab = _tab;
    final failedIds = tab == LibraryTab.failed
        ? [
            for (final item
                in ref.watch(libraryTabItemsProvider(tab)).value ??
                    const <MediaItem>[])
              item.id,
          ]
        : const <int>[];

    return Scaffold(
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
          if (selection.isNotEmpty) ...[
            IconButton(
              tooltip: 'Select all',
              icon: const Icon(Icons.select_all_rounded),
              onPressed: _selectAll,
            ),
            if (tab == LibraryTab.transferred)
              IconButton(
                tooltip: 'Delete from this phone',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(selection),
              )
            else
              IconButton(
                tooltip: paired ? 'Transfer selected' : 'Pair a receiver first',
                icon: const Icon(Icons.send_rounded),
                onPressed: paired && !transferring
                    ? () => _transfer(selection)
                    : null,
              ),
          ] else ...[
            if (failedIds.isNotEmpty)
              IconButton(
                tooltip: paired ? 'Retry all' : 'Pair a receiver first',
                icon: const Icon(Icons.replay_rounded),
                onPressed: paired && !transferring
                    ? () => _transfer(failedIds.toSet())
                    : null,
              ),
            IconButton(
              tooltip: 'Scan again',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: scan.isBusy
                  ? null
                  : ref.read(mediaScanControllerProvider.notifier).scan,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabs,
          // Labels with counts don't fit three equal tabs on a phone.
          isScrollable: true,
          tabAlignment: TabAlignment.center,
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
              controller: _tabs,
              children: [
                for (final tab in LibraryTab.values) _LibraryTabView(tab),
              ],
            ),
          ),
        ],
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
      AsyncData(value: final items) => Column(
        children: [
          if (tab == LibraryTab.transferred) const _CleanupHint(),
          Expanded(
            child: items.isEmpty ? _EmptyTab(tab) : _MediaGrid(items, tab),
          ),
        ],
      ),
      AsyncError(:final error) => Center(child: Text('Could not load: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Explains deletion in the Transferred tab, and what it has freed.
class _CleanupHint extends ConsumerWidget {
  const _CleanupHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deleted = ref.watch(deletedTotalsProvider).value;
    final freed = deleted == null || deleted.files == 0
        ? ''
        : ' Freed so far: ${formatBytes(deleted.bytes)}.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified on the receiver. Long-press to select files to '
              'delete from this phone.$freed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends ConsumerWidget {
  const _MediaGrid(this.items, this.tab);

  final List<MediaItem> items;
  final LibraryTab tab;

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
        final selectable = _selectable(item, tab);
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
          formatDateTime(context, DateTime.fromMillisecondsSinceEpoch(taken)),
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
