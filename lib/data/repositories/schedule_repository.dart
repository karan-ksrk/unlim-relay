import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/schedule.dart';

/// Persists the daily schedule and the outcome of its last run.
abstract interface class ScheduleRepository {
  Future<ScheduleSettings> readSettings();

  Future<void> saveSettings(ScheduleSettings settings);

  Future<ScheduleStatus> readStatus();

  Stream<(ScheduleSettings, ScheduleStatus)> watch();

  /// Records that a run started at [at].
  Future<void> recordAttempt(DateTime at);

  /// Records how the run that started last ended.
  Future<void> recordOutcome(
    ScheduleOutcome outcome, {
    String? message,
    DateTime? successAt,
  });

  Future<void> recordNextRunEstimate(DateTime? at);
}

class DriftScheduleRepository implements ScheduleRepository {
  DriftScheduleRepository(this._db);

  final AppDatabase _db;

  static const _rowId = 1;

  SimpleSelectStatement<$ScheduleSettingsTableTable, ScheduleRow> get _row =>
      _db.select(_db.scheduleSettingsTable)..where((t) => t.id.equals(_rowId));

  @override
  Future<ScheduleSettings> readSettings() async =>
      _settingsOf(await _row.getSingleOrNull());

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {
    await _ensureRow();
    await _update(
      ScheduleSettingsTableCompanion(
        enabled: Value(settings.enabled),
        hour: Value(settings.hour),
        minute: Value(settings.minute),
        weekdays: Value(_encodeWeekdays(settings.weekdays)),
        wifiOnly: Value(settings.wifiOnly),
        chargingOnly: Value(settings.chargingOnly),
        retryHours: Value(settings.retryHours),
        enabledAt: Value(settings.enabledAt),
      ),
    );
  }

  @override
  Future<ScheduleStatus> readStatus() async =>
      _statusOf(await _row.getSingleOrNull());

  @override
  Stream<(ScheduleSettings, ScheduleStatus)> watch() =>
      _row.watchSingleOrNull().map((row) => (_settingsOf(row), _statusOf(row)));

  @override
  Future<void> recordAttempt(DateTime at) async {
    await _ensureRow();
    await _update(
      ScheduleSettingsTableCompanion(
        lastAttemptAt: Value(at),
        lastOutcome: Value(ScheduleOutcome.running.name),
        lastMessage: const Value(null),
      ),
    );
  }

  @override
  Future<void> recordOutcome(
    ScheduleOutcome outcome, {
    String? message,
    DateTime? successAt,
  }) async {
    await _ensureRow();
    await _update(
      ScheduleSettingsTableCompanion(
        lastOutcome: Value(outcome.name),
        lastMessage: Value(message),
        lastSuccessAt: successAt == null
            ? const Value.absent()
            : Value(successAt),
      ),
    );
  }

  @override
  Future<void> recordNextRunEstimate(DateTime? at) async {
    await _ensureRow();
    await _update(ScheduleSettingsTableCompanion(nextRunEstimate: Value(at)));
  }

  Future<void> _update(ScheduleSettingsTableCompanion changes) async {
    await (_db.update(
      _db.scheduleSettingsTable,
    )..where((t) => t.id.equals(_rowId))).write(changes);
  }

  /// Inserts the default schedule if there is no row yet.
  Future<void> _ensureRow() async {
    const defaults = ScheduleSettings();
    await _db
        .into(_db.scheduleSettingsTable)
        .insert(
          ScheduleSettingsTableCompanion.insert(
            id: const Value(_rowId),
            enabled: defaults.enabled,
            hour: defaults.hour,
            minute: defaults.minute,
            weekdays: _encodeWeekdays(defaults.weekdays),
            wifiOnly: defaults.wifiOnly,
            chargingOnly: defaults.chargingOnly,
            retryHours: defaults.retryHours,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  static ScheduleSettings _settingsOf(ScheduleRow? row) {
    if (row == null) return const ScheduleSettings();
    return ScheduleSettings(
      enabled: row.enabled,
      hour: row.hour,
      minute: row.minute,
      weekdays: _decodeWeekdays(row.weekdays),
      wifiOnly: row.wifiOnly,
      chargingOnly: row.chargingOnly,
      retryHours: row.retryHours,
      enabledAt: row.enabledAt,
    );
  }

  static ScheduleStatus _statusOf(ScheduleRow? row) {
    if (row == null) return ScheduleStatus.none;
    return ScheduleStatus(
      lastAttemptAt: row.lastAttemptAt,
      lastOutcome: ScheduleOutcome.tryParse(row.lastOutcome),
      lastMessage: row.lastMessage,
      lastSuccessAt: row.lastSuccessAt,
      nextRunEstimate: row.nextRunEstimate,
    );
  }

  static String _encodeWeekdays(Set<int> weekdays) =>
      (weekdays.toList()..sort()).join(',');

  static Set<int> _decodeWeekdays(String stored) => {
    for (final part in stored.split(','))
      if (int.tryParse(part) case final day? when day >= 1 && day <= 7) day,
  };
}
