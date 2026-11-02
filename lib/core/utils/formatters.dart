import 'package:material_ui/material_ui.dart';

/// `1536` → `1.5 KB`. Uses binary units, as Android's file manager does.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  if (unit == 0) return '$bytes B';
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

/// `4950` → `4,950`.
String formatCount(int count) => count.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// Localized "Nov 2, 2026, 12:41 PM".
String formatDateTime(BuildContext context, DateTime dateTime) {
  final l10n = MaterialLocalizations.of(context);
  return '${l10n.formatMediumDate(dateTime)}, '
      '${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(dateTime))}';
}

/// `1, 'photo'` → `1 photo`; `4950, 'photo'` → `4,950 photos`.
String countOf(int count, String singular, [String? plural]) =>
    '${formatCount(count)} ${count == 1 ? singular : plural ?? '${singular}s'}';
