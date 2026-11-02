import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_info.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/media_enums.dart';
import '../../data/models/schedule.dart';
import '../../data/providers.dart';
import '../media_library/media_library_providers.dart';
import 'schedule_controller.dart';
import 'schedule_text.dart';

/// Daily transfer settings and status (plan §9, §12.7).
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily transfer')),
      body: switch (schedule) {
        AsyncData(value: (final settings, final status)) => _ScheduleBody(
          settings: settings,
          status: status,
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ScheduleBody extends ConsumerWidget {
  const _ScheduleBody({required this.settings, required this.status});

  final ScheduleSettings settings;
  final ScheduleStatus status;

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: 'Daily transfer time',
    );
    if (picked == null) return;
    await ref
        .read(scheduleControllerProvider)
        .save(settings.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _pickRetry(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('If a run is deferred'),
        children: [
          RadioGroup<int>(
            groupValue: settings.retryHours,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final hours in ScheduleSettings.retryHourChoices)
                  RadioListTile<int>(
                    value: hours,
                    title: Text(describeRetry(hours)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(scheduleControllerProvider)
        .save(settings.copyWith(retryHours: picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(scheduleControllerProvider);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final time = TimeOfDay(hour: settings.hour, minute: settings.minute);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  Icons.schedule_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Daily transfer'),
                subtitle: Text(
                  settings.enabled
                      ? 'Runs around ${time.format(context)} when Android '
                            'allows'
                      : 'Off',
                ),
                value: settings.enabled,
                onChanged: (enabled) =>
                    controller.save(settings.copyWith(enabled: enabled)),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Time'),
                subtitle: Text(time.format(context)),
                onTap: () => _pickTime(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(describeWeekdays(settings.weekdays), style: muted),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          FilterChip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            label: Text(dayLetter(day)),
                            tooltip: dayName(day),
                            showCheckmark: false,
                            selected: settings.weekdays.contains(day),
                            onSelected: (selected) => controller.save(
                              settings.copyWith(
                                weekdays: selected
                                    ? {...settings.weekdays, day}
                                    : ({...settings.weekdays}..remove(day)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.wifi_rounded),
                title: const Text('Wi-Fi only'),
                subtitle: const Text('Waits for an unmetered network'),
                value: settings.wifiOnly,
                onChanged: (value) =>
                    controller.save(settings.copyWith(wifiOnly: value)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.battery_charging_full_rounded),
                title: const Text('Only while charging'),
                subtitle: const Text('Never runs on low battery either way'),
                value: settings.chargingOnly,
                onChanged: (value) =>
                    controller.save(settings.copyWith(chargingOnly: value)),
              ),
              ListTile(
                leading: const Icon(Icons.replay_rounded),
                title: const Text('Retry'),
                subtitle: Text(describeRetry(settings.retryHours)),
                onTap: () => _pickRetry(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatusCard(settings: settings, status: status),
        const SizedBox(height: 12),
        const _ReliabilityCard(),
      ],
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.settings, required this.status});

  final ScheduleSettings settings;
  final ScheduleStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final now = DateTime.now();
    final run = ref.watch(backgroundRunProvider);
    final stats = ref.watch(inventoryStatsProvider).value;
    final paired = ref.watch(pairedDeviceProvider).value;
    final waiting =
        (stats?.countFor(LibraryTab.pending) ?? 0) +
        (stats?.countFor(LibraryTab.failed) ?? 0);
    final waitingBytes =
        (stats?.bytesFor(LibraryTab.pending) ?? 0) +
        (stats?.bytesFor(LibraryTab.failed) ?? 0);

    String at(DateTime time) =>
        '${relativeDay(time, now)}, ${formatClock(context, time)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _Line(
              label: 'Next run',
              value: switch ((settings.enabled, status.nextRunEstimate)) {
                (false, _) => 'Off',
                (true, final next?) => describeNextRun(context, next, now),
                (true, null) => 'Not planned',
              },
            ),
            _Line(
              label: 'Last run',
              value: switch ((status.lastAttemptAt, status.lastOutcome)) {
                (final time?, final outcome?) =>
                  '${at(time)} · ${describeOutcome(outcome)}',
                _ => 'Never',
              },
            ),
            if (status.lastMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(message, style: muted),
              ),
            _Line(
              label: 'Last successful run',
              value: switch (status.lastSuccessAt) {
                final time? => at(time),
                null => 'Never',
              },
            ),
            _Line(
              label: 'Waiting to send',
              value:
                  '${countOf(waiting, 'file')} · ${formatBytes(waitingBytes)}',
            ),
            if (run != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: run.totalBytes == 0
                    ? null
                    : run.sentBytes / run.totalBytes,
              ),
              const SizedBox(height: 8),
              Text(describeBackgroundRun(run), style: muted),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: run == null && paired != null
                    ? () => ref.read(scheduleControllerProvider).runNow()
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run now'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Runs in the background with the same checks and daily limit '
              'as the schedule. Turn on Ready to receive on the receiver '
              'first.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sending 3 of 20 · 12 MB of 80 MB", or "Starting…".
String describeBackgroundRun(BackgroundRun run) {
  final index = run.fileIndex;
  final total = run.totalFiles;
  if (index == null || total == null) return 'Daily transfer starting…';
  return 'Daily transfer: sending ${index + 1} of $total · '
      '${formatBytes(run.sentBytes)} of ${formatBytes(run.totalBytes)}';
}

class _ReliabilityCard extends ConsumerWidget {
  const _ReliabilityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(scheduleControllerProvider);
    final notifications = ref.watch(notificationsEnabledProvider).value;
    final exempt = ref.watch(batteryExemptProvider).value;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: Text(
              notifications == false
                  ? 'Off: you won’t see run results'
                  : 'Shows when a run finishes, is deferred or fails',
            ),
            trailing: notifications == false
                ? TextButton(
                    onPressed: controller.requestNotifications,
                    child: const Text('Allow'),
                  )
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.battery_saver_outlined),
            title: const Text('Battery optimization'),
            subtitle: Text(
              exempt == true
                  ? 'Unrestricted: runs are less likely to be delayed'
                  : 'Optimized: Android may delay or skip runs. Allowing '
                        'background use costs a little battery.',
            ),
            trailing: exempt == false
                ? TextButton(
                    onPressed: controller.requestBatteryExemption,
                    child: const Text('Allow'),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              'Android starts scheduled work at or after the chosen time, '
              'not exactly on it. The receiver needs Ready to receive on, on '
              'the same Wi-Fi; its screen can be off, but don’t swipe '
              '$appName away from recent apps there. Otherwise the run is '
              'deferred and files stay pending. Some phones also need '
              '“background activity” or autostart allowed for $appName in '
              'system settings.',
              style: small,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
