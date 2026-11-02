import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/schedule.dart';
import '../../data/providers.dart';
import '../../data/repositories/transfer_lock_repository.dart';
import '../../services/scheduled_transfer_job.dart';
import '../media_library/media_library_providers.dart';
import '../transfer/transfer_controller.dart';

final scheduleCoordinatorProvider = Provider<ScheduleCoordinator>(
  (ref) => ScheduleCoordinator(
    schedule: ref.watch(scheduleRepositoryProvider),
    scheduler: ref.watch(backgroundSchedulerProvider),
    locks: ref.watch(transferLockRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

/// Set in the background engine to forward progress to the app.
final scheduledProgressReporterProvider =
    Provider<void Function(Map<String, dynamic>)?>((ref) => null);

final scheduledTransferJobProvider = Provider<ScheduledTransferJob>(
  (ref) => ScheduledTransferJob(
    schedule: ref.watch(scheduleRepositoryProvider),
    coordinator: ref.watch(scheduleCoordinatorProvider),
    locks: ref.watch(transferLockRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    pairing: ref.watch(pairingRepositoryProvider),
    library: ref.watch(mediaLibraryProvider),
    scanner: ref.watch(mediaScanServiceProvider),
    orchestrator: ref.watch(transferOrchestratorProvider),
    notifications: ref.watch(transferNotificationsProvider),
    reportProgress: ref.watch(scheduledProgressReporterProvider),
  ),
);

final scheduleProvider = StreamProvider<(ScheduleSettings, ScheduleStatus)>(
  (ref) => ref.watch(scheduleRepositoryProvider).watch(),
);

final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(transferNotificationsProvider).areEnabled(),
);

final batteryExemptProvider = FutureProvider<bool>(
  (ref) => ref.watch(batteryOptimizationProvider).isExempt(),
);

final scheduleControllerProvider = Provider<ScheduleController>(
  ScheduleController.new,
);

class ScheduleController {
  ScheduleController(this._ref);

  static final _log = Logger('ScheduleController');

  final Ref _ref;

  /// Saves [updated] and re-registers background work. Turning the schedule
  /// on asks for notification permission, so results can be shown.
  Future<void> save(ScheduleSettings updated) async {
    final repository = _ref.read(scheduleRepositoryProvider);
    final current = await repository.readSettings();
    final timingChanged =
        updated.hour != current.hour ||
        updated.minute != current.minute ||
        updated.weekdays.length != current.weekdays.length ||
        !updated.weekdays.containsAll(current.weekdays);
    if (updated.enabled && (!current.enabled || timingChanged)) {
      updated = updated.copyWith(enabledAt: DateTime.now());
    }
    await repository.saveSettings(updated);
    await _ref.read(scheduleCoordinatorProvider).sync();

    if (updated.enabled && !current.enabled) {
      await requestNotifications();
    }
  }

  /// Starts a scheduled-style run in the background now.
  Future<void> runNow() async {
    final settings = await _ref.read(scheduleRepositoryProvider).readSettings();
    await _ref.read(backgroundSchedulerProvider).runNow(settings);
    _ref.read(backgroundRunProvider.notifier).expectRun();
  }

  Future<void> requestNotifications() async {
    try {
      await _ref.read(transferNotificationsProvider).requestPermission();
    } on Object catch (error) {
      _log.warning('Notification permission request failed: $error');
    }
    _ref.invalidate(notificationsEnabledProvider);
  }

  Future<void> requestBatteryExemption() async {
    try {
      await _ref.read(batteryOptimizationProvider).requestExemption();
    } on Object catch (error) {
      _log.warning('Battery exemption request failed: $error');
    }
    _ref.invalidate(batteryExemptProvider);
  }
}

/// A scheduled run seen from the app, which runs in another engine.
class BackgroundRun {
  const BackgroundRun({
    this.fileIndex,
    this.totalFiles,
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.fileName,
  });

  factory BackgroundRun.fromProgress(Map<String, dynamic> progress) =>
      BackgroundRun(
        fileIndex: progress[ScheduledProgress.fileIndex] as int?,
        totalFiles: progress[ScheduledProgress.totalFiles] as int?,
        sentBytes: progress[ScheduledProgress.sentBytes] as int? ?? 0,
        totalBytes: progress[ScheduledProgress.totalBytes] as int? ?? 0,
        fileName: progress[ScheduledProgress.fileName] as String?,
      );

  /// `null` until the first file starts.
  final int? fileIndex;
  final int? totalFiles;
  final int sentBytes;
  final int totalBytes;
  final String? fileName;
}

/// How often the app checks whether a scheduled run is going. `null`
/// disables polling (tests).
final backgroundPollIntervalProvider = Provider<Duration?>(
  (ref) => const Duration(seconds: 3),
);

final backgroundRunProvider =
    NotifierProvider<BackgroundRunWatcher, BackgroundRun?>(
      BackgroundRunWatcher.new,
    );

/// Tracks a scheduled run from the app. The run writes through its own
/// database connection, which doesn't notify this engine's queries, so the
/// watcher also refreshes them while a run is going, when it ends, and when
/// the app returns to the foreground.
class BackgroundRunWatcher extends Notifier<BackgroundRun?> {
  static final _log = Logger('BackgroundRunWatcher');
  static const _refreshEvery = Duration(seconds: 2);

  Timer? _poll;
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _expectedUntil;

  @override
  BackgroundRun? build() {
    unawaited(
      ref
          .read(backgroundSchedulerProvider)
          .listenForProgress(_onProgress)
          .catchError(
            (Object e) => _log.warning('Progress listener failed: $e'),
          ),
    );
    final lifecycle = AppLifecycleListener(
      onResume: () {
        _refreshQueries();
        _startPolling();
      },
      onHide: () => _poll?.cancel(),
    );
    _startPolling();
    ref.onDispose(() {
      _poll?.cancel();
      lifecycle.dispose();
    });
    return null;
  }

  /// "Run now" was tapped: show the run as starting until WorkManager picks
  /// it up.
  void expectRun() {
    _expectedUntil = DateTime.now().add(const Duration(seconds: 30));
    state ??= const BackgroundRun();
  }

  void _startPolling() {
    final interval = ref.read(backgroundPollIntervalProvider);
    if (interval == null) return;
    _poll?.cancel();
    _poll = Timer.periodic(interval, (_) => unawaited(_check()));
  }

  void _onProgress(Map<String, dynamic> progress) {
    if (!ref.mounted) return;
    state = BackgroundRun.fromProgress(progress);
    final now = DateTime.now();
    if (now.difference(_lastRefresh) >= _refreshEvery) {
      _lastRefresh = now;
      _refreshQueries();
    }
  }

  Future<void> _check() async {
    final now = DateTime.now();
    final holder = await ref
        .read(transferLockRepositoryProvider)
        .holder(now: now);
    if (!ref.mounted) return;
    final running = holder == TransferLockOwner.schedule;
    if (running) {
      _expectedUntil = null;
      state ??= const BackgroundRun();
    } else if (state != null &&
        (_expectedUntil == null || now.isAfter(_expectedUntil!))) {
      _expectedUntil = null;
      state = null;
      _refreshQueries();
      ref.invalidate(transferLimitsProvider);
    }
  }

  void _refreshQueries() {
    final db = ref.read(appDatabaseProvider);
    db.markTablesUpdated(db.allTables);
  }
}
