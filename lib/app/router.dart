import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/device_role.dart';
import '../data/models/media_enums.dart';
import '../features/home/home_screen.dart';
import '../features/media_library/media_library_screen.dart';
import '../features/onboarding/device_role_controller.dart';
import '../features/onboarding/role_selection_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/pairing/pairing_screen.dart';
import '../features/pairing/qr_scanner_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transfer/transfer_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const role = '/role';
  static const home = '/home';
  static const settings = '/settings';
  static const library = '/library';
  static const pair = '/pair';
  static const pairScan = '/pair/scan';
  static const transfer = '/transfer';

  static String libraryTab(LibraryTab tab) =>
      Uri(path: library, queryParameters: {'tab': tab.name}).toString();

  static const onboarding = {welcome, role};
}

/// Keeps users without a role inside onboarding, and users with a role out
/// of it. Returns `null` when no redirect is needed.
String? redirectForRole(DeviceRole? role, String location) {
  final inOnboarding = AppRoutes.onboarding.contains(location);
  if (role == null) return inOnboarding ? null : AppRoutes.welcome;
  return inOnboarding ? AppRoutes.home : null;
}

/// Lets app-level listeners (e.g. the pairing approval dialog) show
/// dialogs above whichever screen is open.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final roleListenable = ValueNotifier<DeviceRole?>(ref.read(deviceRoleProvider));
  ref.listen(deviceRoleProvider, (_, next) => roleListenable.value = next);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: roleListenable,
    redirect: (context, state) =>
        redirectForRole(roleListenable.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => MediaLibraryScreen(
          initialTab: LibraryTab.fromName(state.uri.queryParameters['tab']),
        ),
      ),
      GoRoute(
        path: AppRoutes.pair,
        builder: (context, state) => const PairingScreen(),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (context, state) => const QrScannerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.transfer,
        builder: (context, state) => const TransferScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    roleListenable.dispose();
  });
  return router;
});
