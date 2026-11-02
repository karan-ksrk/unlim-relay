import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../data/models/device_role.dart';
import '../../data/providers.dart';
import '../onboarding/device_role_controller.dart';
import '../onboarding/device_role_display.dart';
import '../pairing/receiver_controller.dart';
import '../transfer/transfer_controller.dart';
import '../transfer/transfer_limits_text.dart';
import 'transfer_limits_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmChangeRole(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change role?'),
        content: const Text(
          'You will go back to onboarding to pick Sender or Receiver again. '
          'No photos or videos are affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Change role'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(receiverControllerProvider.notifier).setReady(false);
      // The router redirects to onboarding once the role is cleared.
      await ref.read(deviceRoleProvider.notifier).reset();
    }
  }

  Future<void> _editLimits(BuildContext context, WidgetRef ref) async {
    final current = await ref.read(transferLimitsProvider.future);
    if (!context.mounted) return;
    final updated = await showTransferLimitsDialog(context, current);
    if (updated == null) return;
    await ref.read(settingsRepositoryProvider).saveTransferLimits(updated);
    ref.invalidate(transferLimitsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(role?.icon ?? Icons.help_outline_rounded),
            title: const Text('Device role'),
            subtitle: Text(role?.label ?? 'Not set'),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Paired device'),
            subtitle: Text(
              ref.watch(pairedDeviceProvider).value?.displayName ?? 'Not paired',
            ),
            onTap: () => context.push(AppRoutes.pair),
          ),
          if (role == DeviceRole.sender)
            ListTile(
              leading: const Icon(Icons.speed_rounded),
              title: const Text('Daily transfer limit'),
              subtitle: Text(
                switch (ref.watch(transferLimitsProvider).value) {
                  final limits? => describeLimits(limits),
                  null => '…',
                },
              ),
              onTap: () => _editLimits(context, ref),
            ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Change role'),
            onTap: () => _confirmChangeRole(context, ref),
          ),
        ],
      ),
    );
  }
}
