import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../data/models/device_role.dart';
import 'device_role_controller.dart';
import 'device_role_display.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  DeviceRole? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    final role = _selected;
    if (role == null) return;
    setState(() => _saving = true);
    try {
      // The router redirects to Home once the role is stored.
      await ref.read(deviceRoleProvider.notifier).select(role);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save role: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.welcome)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Text(
                    'What does this phone do?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose one role per phone. You can change it later in '
                    'Settings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final role in DeviceRole.values)
                    _RoleCard(
                      role: role,
                      selected: _selected == role,
                      onTap: _saving
                          ? null
                          : () => setState(() => _selected = role),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: _selected == null || _saving ? null : _continue,
                child: Text(_saving ? 'Saving…' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final DeviceRole role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: selected ? scheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(role.icon, size: 32, color: scheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.label, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(role.description, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
