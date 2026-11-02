import 'dart:async';

import 'package:logging/logging.dart';

import '../core/utils/formatters.dart';
import '../data/models/device_role.dart';
import '../data/models/schedule.dart';
import '../data/plugin_adapters/background_scheduler.dart';
import '../data/plugin_adapters/media_library.dart';
import '../data/plugin_adapters/transfer_notifications.dart';
import '../data/repositories/pairing_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/transfer_lock_repository.dart';
import 'media_scan_service.dart';
import 'schedule_planner.dart';
import 'transfer_errors.dart';
import 'transfer_orchestrator.dart';

/// Keeps the background registration in step with the saved schedule.
class ScheduleCoordinator {
  ScheduleCoordinator({
    required this._schedule,
    required this._scheduler,
    required this._locks,
    required this._settings,
    this._clock = DateTime.now,
  });

  final ScheduleRepository _schedule;
  final BackgroundScheduler _scheduler;
  final TransferLockRepository _locks;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Registers the next run, or cancels it when the schedule is off or this
  /// phone isn't the sender. Returns the planned time.
  ///
  /// The app calls this with [fromRun] false; it then does nothing while a
  /// scheduled run is going, because replacing the work would stop that
  /// run, which registers its successor itself when it ends.
  Future<DateTime?> sync({bool fromRun = false}) async {
    final now = _clock();
    if (!fromRun &&
        await _locks.holder(now: now) == TransferLockOwner.schedule) {
      return (await _schedule.readStatus()).nextRunEstimate;
    }
    final settings = await _schedule.readSettings();
    final next = await _settings.readDeviceRole() == DeviceRole.sender
        ? planNextRun(settings, await _schedule.readStatus(), now)
        : null;
    if (next == null) {
      await _scheduler.cancel();
    } else {
      await _scheduler.scheduleAt(next, settings, now: now);
    }
    await _schedule.recordNextRunEstimate(next);
    return next;
  }
}

/// Background progress, as sent to the app through WorkManager.
abstract final class ScheduledProgress {
  static const fileIndex = 'fileIndex';
  static const totalFiles = 'totalFiles';
  static const sentBytes = 'sentBytes';
  static const totalBytes = 'totalBytes';
  static const fileName = 'fileName';

  static Map<String, dynamic> encode(TransferProgress progress) => {
    fileIndex: progress.fileIndex,
    totalFiles: progress.totalFiles,
    sentBytes: progress.sentBytes,
    totalBytes: progress.totalBytes,
    fileName: ?progress.currentFileName,
  };
}

/// One scheduled run (plan §9): check preconditions, rescan the camera
/// folder, send within today's limits, record the outcome, notify, and
/// register the next run. Never deletes or modifies source files.
class ScheduledTransferJob {
  ScheduledTransferJob({
    required this._schedule,
    required this._coordinator,
    required this._locks,
    required this._settings,
    required this._pairing,
    required this._library,
    required this._scanner,
    required this._orchestrator,
    required this._notifications,
    this._reportProgress,
    this._clock = DateTime.now,
    this.budget = defaultBudget,
  });

  static final _log = Logger('ScheduledTransferJob');

  /// Background work is stopped after 10 minutes unless it runs as a
  /// foreground service, which Android may refuse. Stop before that and
  /// continue in a follow-up run.
  static const defaultBudget = Duration(minutes: 9);

  static const _progressEvery = Duration(seconds: 1);

  final ScheduleRepository _schedule;
  final ScheduleCoordinator _coordinator;
  final TransferLockRepository _locks;
  final SettingsRepository _settings;
  final PairingRepository _pairing;
  final MediaLibrary _library;
  final MediaScanService _scanner;
  final TransferOrchestrator _orchestrator;
  final TransferNotifications _notifications;
  final void Function(Map<String, dynamic> progress)? _reportProgress;
  final DateTime Function() _clock;
  final Duration budget;

  /// [force] is the user's "Run now": it skips the time check. [stopRequested]
  /// is set when Android stops the task early.
  Future<ScheduleOutcome?> run({
    bool force = false,
    bool Function()? stopRequested,
  }) async {
    final startedAt = _clock();
    final settings = await _schedule.readSettings();
    final status = await _schedule.readStatus();
    final isSender = await _settings.readDeviceRole() == DeviceRole.sender;
    if (!isSender || (!force && !isRunDue(settings, status, startedAt))) {
      _log.info('Scheduled run not due; re-registering');
      await _coordinator.sync(fromRun: true);
      return null;
    }

    // WorkManager can start a moment early. Record the planned time so this
    // run counts for its slot and isn't repeated straight after.
    final planned = planNextRun(settings, status, startedAt);
    await _schedule.recordAttempt(
      !force && planned != null && planned.isAfter(startedAt)
          ? planned
          : startedAt,
    );
    ScheduleOutcome outcome;
    String? message;
    String title;
    try {
      (outcome, message, title) = await _attempt(
        startedAt: startedAt,
        stopRequested: stopRequested,
      );
    } on Object catch (error, stackTrace) {
      _log.severe('Scheduled run failed', error, stackTrace);
      (outcome, message, title) = (
        ScheduleOutcome.failed,
        describeTransferError(error),
        'Daily transfer stopped',
      );
    }
    message = _oneLine(message);
    final finished = outcome.isRetryable ? null : _clock();
    await _schedule.recordOutcome(
      outcome,
      message: message,
      successAt: finished,
    );
    _log.info(
      'Scheduled run: ${outcome.name}${message == null ? '' : ' – $message'}',
    );

    // Notify first: registering the next run replaces this task's own
    // unique work, and Android then stops this task.
    if (outcome != ScheduleOutcome.partial) {
      final next = planNextRun(
        await _schedule.readSettings(),
        await _schedule.readStatus(),
        _clock(),
      );
      await _notify(outcome, title, message, next);
    }
    await _coordinator.sync(fromRun: true);
    return outcome;
  }

  Future<(ScheduleOutcome, String?, String)> _attempt({
    required DateTime startedAt,
    bool Function()? stopRequested,
  }) async {
    final receiver = await _pairing.pairedDevice();
    if (receiver == null) {
      return (
        ScheduleOutcome.deferred,
        'Not paired with a receiver.',
        'Daily transfer skipped',
      );
    }
    if (await _library.currentAccess() == MediaAccess.denied) {
      return (
        ScheduleOutcome.deferred,
        'Photo and video access is off. Open the app to allow it.',
        'Daily transfer skipped',
      );
    }

    try {
      return await _locks.whileHolding(
        TransferLockOwner.schedule,
        clock: _clock,
        () => _transfer(receiver.displayName, startedAt, stopRequested),
      );
    } on TransferBusyException {
      return (
        ScheduleOutcome.deferred,
        'Another transfer was running.',
        'Daily transfer deferred',
      );
    }
  }

  Future<(ScheduleOutcome, String?, String)> _transfer(
    String receiverName,
    DateTime startedAt,
    bool Function()? stopRequested,
  ) async {
    try {
      await _scanner.scan();
    } on Object catch (error, stackTrace) {
      // Still send what the last scan found.
      _log.warning('Scan before scheduled transfer failed', error, stackTrace);
    }

    var lastReport = DateTime.fromMillisecondsSinceEpoch(0);
    var outOfTime = false;
    final TransferSummary summary;
    try {
      summary = await _orchestrator.run(
        trigger: TransferTrigger.scheduled,
        onProgress: (progress) {
          final now = _clock();
          if (now.difference(lastReport) < _progressEvery) return;
          lastReport = now;
          _reportProgress?.call(ScheduledProgress.encode(progress));
        },
        isCancelled: () {
          if (stopRequested?.call() ?? false) return true;
          return outOfTime = _clock().difference(startedAt) >= budget;
        },
      );
    } on Object catch (error, stackTrace) {
      _log.warning('Scheduled transfer could not start', error, stackTrace);
      return (
        ScheduleOutcome.deferred,
        describeTransferError(error),
        'Daily transfer deferred',
      );
    }

    final sent = summary.delivered + summary.alreadyPresent;
    final waiting = summary.deferredPhotos + summary.deferredVideos;
    final failedNote = summary.failed > 0
        ? ' ${countOf(summary.failed, 'file')} failed.'
        : '';
    if (summary.error case final error?) {
      return (
        ScheduleOutcome.failed,
        '${sent > 0 ? 'Sent ${countOf(sent, 'file')}, then: ' : ''}$error',
        'Daily transfer stopped',
      );
    }
    if (summary.cancelled) {
      return (
        outOfTime ? ScheduleOutcome.partial : ScheduleOutcome.failed,
        outOfTime
            ? 'Sent ${countOf(sent, 'file')} so far; continuing.'
            : 'Stopped by Android after ${countOf(sent, 'file')}.',
        'Daily transfer stopped',
      );
    }
    if (summary.nothingToSend) {
      return waiting > 0
          ? (
              ScheduleOutcome.limitReached,
              "Today's limit is used up; ${countOf(waiting, 'file')} waiting.",
              'Daily transfer: limit reached',
            )
          : (
              ScheduleOutcome.nothingToSend,
              'Nothing new to send.',
              'Daily transfer: all caught up',
            );
    }
    return (
      ScheduleOutcome.completed,
      '${waiting > 0 ? '${countOf(waiting, 'file')} wait for the next run '
                '(daily limit).' : 'All caught up.'}$failedNote',
      'Sent ${countOf(sent, 'file')} to $receiverName',
    );
  }

  Future<void> _notify(
    ScheduleOutcome outcome,
    String title,
    String? message,
    DateTime? next,
  ) async {
    final retry = outcome.isRetryable && next != null
        ? ' Trying again around ${_clockTime(next)}.'
        : '';
    try {
      await _notifications.showScheduleStatus(title, '${message ?? ''}$retry');
    } on Object catch (error) {
      _log.warning('Notification failed: $error');
    }
  }

  /// Keeps stored and notified messages to a short single line.
  static String? _oneLine(String? message) {
    if (message == null) return null;
    final line = message.split('\n').first.trim();
    return line.length <= 200 ? line : '${line.substring(0, 199)}…';
  }

  static String _clockTime(DateTime at) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }
}
