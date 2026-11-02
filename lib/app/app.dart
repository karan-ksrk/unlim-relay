import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../features/launch/launch_intro.dart';
import '../features/pairing/pairing_approval_listener.dart';
import 'router.dart';
import 'theme.dart';
import 'app_info.dart';

class LumaSyncApp extends ConsumerWidget {
  const LumaSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => LaunchIntro(
        child: PairingApprovalListener(
          navigatorKey: rootNavigatorKey,
          child: child!,
        ),
      ),
    );
  }
}
