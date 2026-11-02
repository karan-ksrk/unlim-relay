import 'package:material_ui/material_ui.dart';

import '../../data/models/device_role.dart';
import '../../app/app_info.dart';

extension DeviceRoleDisplay on DeviceRole {
  String get label => switch (this) {
    DeviceRole.sender => 'Sender',
    DeviceRole.receiver => 'Receiver',
  };

  String get description => switch (this) {
    DeviceRole.sender =>
      'This phone takes the photos. $appName finds new camera photos and '
          'videos and sends them to the receiver.',
    DeviceRole.receiver =>
      'This phone keeps the copies. Received files are verified and saved '
          'to DCIM/Camera so your gallery and backup app can see them.',
  };

  IconData get icon => switch (this) {
    DeviceRole.sender => Icons.upload_rounded,
    DeviceRole.receiver => Icons.download_rounded,
  };
}
