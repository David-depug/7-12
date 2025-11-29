class BlockedApp {
  const BlockedApp({
    required this.packageName,
    required this.displayName,
  });

  final String packageName;
  final String displayName;

  String serialize() => '$packageName|$displayName';

  factory BlockedApp.deserialize(String raw) {
    if (raw.contains('|')) {
      final parts = raw.split('|');
      return BlockedApp(
        packageName: parts.first,
        displayName: parts.sublist(1).join('|'),
      );
    }
    return BlockedApp(packageName: raw, displayName: raw);
  }
}

