import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/app/router.dart';
import 'package:lumasync/data/models/device_role.dart';

void main() {
  group('redirectForRole', () {
    test('sends users without a role to welcome', () {
      expect(redirectForRole(null, AppRoutes.home), AppRoutes.welcome);
      expect(redirectForRole(null, AppRoutes.settings), AppRoutes.welcome);
    });

    test('lets users without a role move through onboarding', () {
      expect(redirectForRole(null, AppRoutes.welcome), isNull);
      expect(redirectForRole(null, AppRoutes.role), isNull);
    });

    test('sends users with a role out of onboarding', () {
      for (final role in DeviceRole.values) {
        expect(redirectForRole(role, AppRoutes.welcome), AppRoutes.home);
        expect(redirectForRole(role, AppRoutes.role), AppRoutes.home);
      }
    });

    test('leaves users with a role on app screens', () {
      expect(redirectForRole(DeviceRole.sender, AppRoutes.home), isNull);
      expect(redirectForRole(DeviceRole.receiver, AppRoutes.settings), isNull);
    });
  });
}
