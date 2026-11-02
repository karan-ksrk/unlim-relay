import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'receiver_controller.dart';

/// Shows the "Allow pairing?" dialog on the receiver from any screen
/// (plan §7: explicit approval on both devices).
class PairingApprovalListener extends ConsumerWidget {
  const PairingApprovalListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      receiverControllerProvider.select((s) => s.pendingApproval),
      (previous, pending) {
        final navigator = navigatorKey.currentState;
        if (pending == null) {
          // Timed out or answered elsewhere: close a dialog left open.
          if (previous != null) navigator?.popUntil((r) => r is! DialogRoute);
          return;
        }
        if (navigator == null) return;
        showDialog<bool>(
          context: navigator.context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.phonelink_lock_rounded),
            title: const Text('Allow pairing?'),
            content: Text(
              '"${pending.request.senderName}" '
              '(${pending.request.remoteAddress}) wants to send photos and '
              'videos to this phone. Only allow a phone you own.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Decline'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ).then(
          (allow) => ref
              .read(receiverControllerProvider.notifier)
              .respondToPairing(allow: allow ?? false),
        );
      },
    );
    return child;
  }
}
