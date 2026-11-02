import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/transfer_limits.dart';

/// Edits the daily photo and video caps. Returns the new limits, or `null`
/// when cancelled.
Future<TransferLimits?> showTransferLimitsDialog(
  BuildContext context,
  TransferLimits current,
) => showDialog<TransferLimits>(
  context: context,
  builder: (context) => _TransferLimitsDialog(current),
);

class _TransferLimitsDialog extends StatefulWidget {
  const _TransferLimitsDialog(this.current);

  final TransferLimits current;

  @override
  State<_TransferLimitsDialog> createState() => _TransferLimitsDialogState();
}

class _TransferLimitsDialogState extends State<_TransferLimitsDialog> {
  late bool _limitPhotos = widget.current.photosPerDay != null;
  late bool _limitVideos = widget.current.videosPerDay != null;
  late final _photos = TextEditingController(
    text:
        '${widget.current.photosPerDay ?? TransferLimits.defaultPhotosPerDay}',
  );
  late final _videos = TextEditingController(
    text:
        '${widget.current.videosPerDay ?? TransferLimits.defaultVideosPerDay}',
  );

  @override
  void dispose() {
    _photos.dispose();
    _videos.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    return value != null && value >= 0 ? value : null;
  }

  bool get _valid =>
      (!_limitPhotos || _parse(_photos) != null) &&
      (!_limitVideos || _parse(_videos) != null);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily transfer limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caps how many files are sent each day, counted from midnight. '
            'Newest files go first; the rest wait for the next day.',
          ),
          const SizedBox(height: 16),
          _LimitRow(
            label: 'Photos per day',
            enabled: _limitPhotos,
            controller: _photos,
            onEnabledChanged: (value) => setState(() => _limitPhotos = value),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LimitRow(
            label: 'Videos per day',
            enabled: _limitVideos,
            controller: _videos,
            onEnabledChanged: (value) => setState(() => _limitVideos = value),
            onChanged: () => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(
                  TransferLimits(
                    photosPerDay: _limitPhotos ? _parse(_photos) : null,
                    videosPerDay: _limitVideos ? _parse(_videos) : null,
                  ),
                )
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.label,
    required this.enabled,
    required this.controller,
    required this.onEnabledChanged,
    required this.onChanged,
  });

  final String label;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: enabled, onChanged: onEnabledChanged),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: label,
              helperText: enabled ? null : 'No limit',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
