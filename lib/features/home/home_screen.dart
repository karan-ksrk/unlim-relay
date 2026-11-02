import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/widgets/luma_mark.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/models/device_role.dart';
import '../../data/providers.dart';
import '../../data/models/media_enums.dart';
import '../../data/repositories/media_inventory_repository.dart';
import '../media_library/camera_library_card.dart';
import '../media_library/media_access_notice.dart';
import '../media_library/media_display.dart';
import '../media_library/media_library_providers.dart';
import '../onboarding/device_role_controller.dart';
import '../pairing/receiver_controller.dart';
import '../transfer/transfer_controller.dart';
import '../transfer/transfer_limits_text.dart';
import '../onboarding/device_role_display.dart';
import '../../app/app_info.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    // The router keeps role-less users in onboarding; this guards the
    // single frame before the redirect lands.
    if (role == null) return const Scaffold();

    final theme = Theme.of(context);
    final stats = role == DeviceRole.sender
        ? ref.watch(inventoryStatsProvider).value ?? InventoryStats.empty
        : InventoryStats.empty;
    final paired = ref.watch(pairedDeviceProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const LumaMark(size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${role.label} phone',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          switch (role) {
                            DeviceRole.sender =>
                              'Sends new camera photos and videos.',
                            DeviceRole.receiver =>
                              'Saves received media to DCIM/Camera.',
                          },
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...switch (role) {
            DeviceRole.sender => [
              _PeerTile(title: 'Receiver', paired: paired),
              const MediaAccessNotice(),
              const CameraLibraryCard(),
              _TransferCard(
                paired: paired != null,
                sendable:
                    stats.countFor(LibraryTab.pending) +
                    stats.countFor(LibraryTab.failed),
              ),
              for (final tab in LibraryTab.values)
                if (tab != LibraryTab.failed || stats.countFor(tab) > 0)
                  _StatusTile(
                    icon: tab.icon,
                    title: tab.label,
                    value: _tabSummary(stats, tab),
                    onTap: () => context.push(AppRoutes.libraryTab(tab)),
                  ),
              const _StatusTile(
                icon: Icons.schedule_rounded,
                title: 'Daily transfer',
                value: 'Off',
              ),
            ],
            DeviceRole.receiver => [
              _PeerTile(title: 'Sender', paired: paired),
              const _ReadyToReceiveTile(),
              const _ReceivedTile(),
              if (ref.watch(receiverControllerProvider).lastManifest
                  case final manifest?)
                _StatusTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Last manifest',
                  value:
                      '${countOf(manifest.fileCount, 'file')} · '
                      '${formatBytes(manifest.totalBytes)}',
                ),
              const _StatusTile(
                icon: Icons.folder_outlined,
                title: 'Destination',
                value: 'DCIM/Camera',
              ),
            ],
          },
        ],
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.title, required this.paired});

  final String title;
  final PairedDevice? paired;

  @override
  Widget build(BuildContext context) {
    return _StatusTile(
      icon: paired == null ? Icons.link_off_rounded : Icons.link_rounded,
      title: title,
      value: paired?.displayName ?? 'Not paired',
      onTap: () => context.push(AppRoutes.pair),
    );
  }
}

class _TransferCard extends ConsumerWidget {
  const _TransferCard({required this.paired, required this.sendable});

  final bool paired;
  final int sendable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfer = ref.watch(transferControllerProvider);
    final theme = Theme.of(context);
    final String hint;
    if (!paired) {
      hint = 'Pair with the receiver to start sending.';
    } else if (sendable == 0) {
      hint = 'Nothing waiting to send.';
    } else {
      hint = '${countOf(sendable, 'file')} waiting. Newest are sent first.';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Transfer', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            const TransferLimitsText(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: transfer.isRunning
                  ? FilledButton.tonalIcon(
                      onPressed: () => context.push(AppRoutes.transfer),
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(
                        switch (transfer.progress) {
                          final p? =>
                            'Sending ${p.fileIndex + 1} of ${p.totalFiles}…',
                          null => 'Connecting…',
                        },
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: paired && sendable > 0
                          ? () {
                              ref
                                  .read(transferControllerProvider.notifier)
                                  .start();
                              context.push(AppRoutes.transfer);
                            }
                          : null,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Transfer now'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedTile extends ConsumerWidget {
  const _ReceivedTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(receivedStatsProvider).value;
    final receiver = ref.watch(receiverControllerProvider);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final last = stats?.lastReceivedAt;

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
                  Icons.download_done_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text('Received', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${countOf(stats?.count ?? 0, 'file')} · '
              '${formatBytes(stats?.totalBytes ?? 0)}',
              style: theme.textTheme.bodyLarge,
            ),
            if (last != null)
              Text('Last saved ${formatDateTime(context, last)}', style: muted),
            if (receiver.receivingName case final name?) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text('Receiving $name…', style: muted),
            ],
            if (receiver.savedThisSession + receiver.failedThisSession > 0) ...[
              const SizedBox(height: 8),
              Text(
                'This session: ${receiver.savedThisSession} saved'
                '${receiver.failedThisSession > 0 ? ', ${receiver.failedThisSession} failed' : ''}',
                style: muted,
              ),
            ],
            if (receiver.lastFailure case final failure?)
              Text(
                failure,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadyToReceiveTile extends ConsumerWidget {
  const _ReadyToReceiveTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiverControllerProvider);
    final theme = Theme.of(context);
    final subtitle = switch (state.phase) {
      ReceiverPhase.off => 'Keeps the screen on while receiving',
      ReceiverPhase.starting => 'Starting…',
      ReceiverPhase.ready => 'Listening on port ${state.port}',
      ReceiverPhase.failed => state.error ?? 'Could not start',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        secondary: Icon(
          state.isReady
              ? Icons.wifi_tethering_rounded
              : Icons.wifi_tethering_off_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Ready to receive'),
        subtitle: Text(subtitle),
        value: state.isReady || state.phase == ReceiverPhase.starting,
        onChanged: state.phase == ReceiverPhase.starting
            ? null
            : ref.read(receiverControllerProvider.notifier).setReady,
      ),
    );
  }
}

String _tabSummary(InventoryStats stats, LibraryTab tab) {
  final count = stats.countFor(tab);
  if (count == 0) return '0';
  return '${formatCount(count)} · ${formatBytes(stats.bytesFor(tab))}';
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
