/// The role this install plays. Both phones run the same build and pick a
/// role during onboarding (plan §3).
enum DeviceRole {
  /// Scans the camera library and sends new media.
  sender,

  /// Receives media and publishes it to `DCIM/Camera`.
  receiver;

  /// Parses a stored role name, returning `null` for unknown values.
  static DeviceRole? tryParse(String? value) =>
      value == null ? null : DeviceRole.values.asNameMap()[value];
}
