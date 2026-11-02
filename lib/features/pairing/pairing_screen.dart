import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/models/device_role.dart';
import '../../data/providers.dart';
import '../../services/pairing_invite.dart';
import '../onboarding/device_role_controller.dart';
import 'receiver_controller.dart';
import 'sender_link_controller.dart';
import '../../app/app_info.dart';

/// Pair devices (plan §12): QR code on the receiver, scanner on the sender.
class PairingScreen extends ConsumerWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    final paired = ref.watch(pairedDeviceProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          role == DeviceRole.receiver ? 'Pair with sender' : 'Pair with receiver',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == DeviceRole.receiver)
            _ReceiverPairing(paired: paired)
          else
            _SenderPairing(paired: paired),
        ],
      ),
    );
  }
}

class _ReceiverPairing extends ConsumerWidget {
  const _ReceiverPairing({required this.paired});

  final PairedDevice? paired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiverControllerProvider);
    final controller = ref.read(receiverControllerProvider.notifier);
    final invite = state.invite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.message != null) _Banner(text: state.message!, success: true),
        if (state.error != null) _Banner(text: state.error!),
        if (invite != null)
          _InviteCard(
            invite: invite,
            expiresAt: state.inviteExpiresAt,
            onCancel: controller.cancelPairingCode,
          )
        else ...[
          if (paired != null)
            _PairedCard(
              device: paired!,
              onUnpair: () => _confirmUnpair(
                context,
                paired!,
                () => ref.read(pairingRepositoryProvider).revokePairing(),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            paired == null
                ? 'Show a pairing code here, then scan it with $appName on '
                      'the sender phone. Both phones must be on the same Wi-Fi.'
                : 'Pairing a different sender replaces the current one.',
            style: _muted(context),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.phase == ReceiverPhase.starting
                ? null
                : controller.showPairingCode,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: Text(
              state.phase == ReceiverPhase.starting
                  ? 'Preparing secure connection…'
                  : 'Show pairing code',
            ),
          ),
        ],
      ],
    );
  }
}

class _InviteCard extends StatefulWidget {
  const _InviteCard({
    required this.invite,
    required this.expiresAt,
    required this.onCancel,
  });

  final PairingInvite invite;
  final DateTime? expiresAt;
  final VoidCallback onCancel;

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expiresAt?.difference(DateTime.now());
    final expired = remaining != null && remaining.isNegative;
    final countdown = remaining == null || expired
        ? null
        : '${remaining.inMinutes}:'
              '${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Scan with $appName on the sender',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: expired ? 0.2 : 1,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: widget.invite.toUri(),
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              expired
                  ? 'This code has expired.'
                  : countdown == null
                  ? 'Waiting for the sender…'
                  : 'Waiting for the sender · expires in $countdown',
              style: _muted(context),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.invite.host}:${widget.invite.port}',
              style: _muted(context),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

class _SenderPairing extends ConsumerWidget {
  const _SenderPairing({required this.paired});

  final PairedDevice? paired;

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final invite = await context.push<PairingInvite>(AppRoutes.pairScan);
    if (invite == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pair with ${invite.receiverName}?'),
        content: Text(
          'This phone will send its camera photos and videos to '
          '${invite.receiverName} (${invite.host}). You will need to allow '
          'it on the receiver too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pair'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(senderLinkControllerProvider.notifier).pair(invite);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(senderLinkControllerProvider);
    final controller = ref.read(senderLinkControllerProvider.notifier);

    final status = switch (state.phase) {
      SenderLinkPhase.connecting => 'Connecting securely to the receiver…',
      SenderLinkPhase.waitingForApproval =>
        'Waiting for you to allow pairing on the receiver…',
      SenderLinkPhase.testing => 'Testing connection…',
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null) _Banner(text: state.error!),
        if (status != null) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(status, style: _muted(context)),
          const SizedBox(height: 16),
        ],
        if (paired != null) ...[
          _PairedCard(
            device: paired!,
            onUnpair: () => _confirmUnpair(context, paired!, controller.unpair),
          ),
          if (state.testResult case final result?)
            _Banner(
              success: true,
              text:
                  'Connected to ${result.receiverName} at '
                  '${result.host}:${result.port} · round trip '
                  '${result.roundTrip.inMilliseconds} ms. The receiver '
                  'acknowledged a manifest of '
                  '${formatCount(result.acknowledgedFiles)} pending files '
                  '(${formatBytes(result.acknowledgedBytes)}).',
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: state.isBusy ? null : controller.testConnection,
            icon: const Icon(Icons.network_check_rounded),
            label: const Text('Test connection'),
          ),
          const SizedBox(height: 8),
          Text(
            'Sends a test message and a list of up to '
            '${SenderLinkController.testManifestLimit} pending files. No '
            'photos or videos are sent yet.',
            style: _muted(context),
          ),
        ] else ...[
          Text(
            'On the receiver phone, open $appName and tap Show pairing code. '
            'Then scan it here. Both phones must be on the same Wi-Fi.',
            style: _muted(context),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.isBusy ? null : () => _scan(context, ref),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan pairing code'),
          ),
        ],
      ],
    );
  }
}

class _PairedCard extends StatelessWidget {
  const _PairedCard({required this.device, required this.onUnpair});

  final PairedDevice device;
  final VoidCallback onUnpair;

  @override
  Widget build(BuildContext context) {
    final lastSeen = device.lastSeenAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Paired ${formatDateTime(context, device.pairedAt)}',
                        style: _muted(context),
                      ),
                      if (lastSeen != null)
                        Text(
                          'Last contact ${formatDateTime(context, lastSeen)}',
                          style: _muted(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onUnpair, child: const Text('Unpair')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.success = false});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = success ? scheme.primaryContainer : scheme.errorContainer;
    final foreground = success
        ? scheme.onPrimaryContainer
        : scheme.onErrorContainer;
    return Card(
      color: background,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmUnpair(
  BuildContext context,
  PairedDevice device,
  Future<void> Function() unpair,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Unpair ${device.displayName}?'),
      content: const Text(
        'The two phones will stop trusting each other until you pair them '
        'again. No photos or videos are deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Unpair'),
        ),
      ],
    ),
  );
  if (confirmed == true) await unpair();
}

TextStyle? _muted(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
