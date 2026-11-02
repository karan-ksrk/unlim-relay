import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/widgets/luma_mark.dart';
import '../../app/app_info.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                children: [
                  const Center(child: LumaMark(size: 88)),
                  const SizedBox(height: 20),
                  Text(
                    appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your memories. Everywhere.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const _Point(
                    icon: Icons.phone_android_rounded,
                    title: 'Two phones, one app',
                    body:
                        'Install $appName on both phones. One sends new camera '
                        'photos and videos; the other receives them.',
                  ),
                  const _Point(
                    icon: Icons.wifi_rounded,
                    title: 'Local Wi-Fi only',
                    body:
                        'Files go straight from phone to phone. Nothing is '
                        'uploaded to a $appName server.',
                  ),
                  const _Point(
                    icon: Icons.verified_rounded,
                    title: 'Originals stay untouched',
                    body:
                        'Every file is copied byte-for-byte and verified. '
                        'Nothing is deleted from the sender unless you choose to.',
                  ),
                  const _Point(
                    icon: Icons.schedule_rounded,
                    title: 'Scheduled runs are best-effort',
                    body:
                        'Android may delay background work to save battery. '
                        'Both phones need to be on the same network, and the '
                        'receiver may need $appName open.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: () => context.go(AppRoutes.role),
                child: const Text('Get started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
