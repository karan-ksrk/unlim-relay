import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/plugin_adapters/media_library.dart';
import '../../data/providers.dart';
import 'media_library_providers.dart';
import 'media_scan_controller.dart';
import '../../app/app_info.dart';

/// Explains denied or limited photo access and offers a fix. Hidden when
/// access is full or has never been requested.
class MediaAccessNotice extends ConsumerWidget {
  const MediaAccessNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(mediaAccessProvider).value;
    final denied =
        ref.watch(mediaScanControllerProvider).phase == ScanPhase.accessDenied;
    final library = ref.read(mediaLibraryProvider);

    final (String message, List<Widget> actions) = switch (access) {
      MediaAccess.limited => (
        '$appName can only see the photos and videos you selected. Allow '
            'access to all of them to sync your whole camera roll.',
        [
          TextButton(
            onPressed: library.changeLimitedSelection,
            child: const Text('Change selection'),
          ),
          TextButton(
            onPressed: library.openSettings,
            child: const Text('Allow all'),
          ),
        ],
      ),
      MediaAccess.denied when denied => (
        '$appName needs access to photos and videos to find new camera '
            'files. Nothing is uploaded anywhere.',
        [
          TextButton(
            onPressed: library.openSettings,
            child: const Text('Open settings'),
          ),
        ],
      ),
      _ => ('', const <Widget>[]),
    };
    if (actions.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(children: actions),
            ),
          ],
        ),
      ),
    );
  }
}
