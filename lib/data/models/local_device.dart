/// This install's identity, shown to and stored by the paired peer.
class LocalDevice {
  const LocalDevice({required this.id, required this.displayName});

  final String id;
  final String displayName;
}
