import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/database/app_database.dart';
import '../../data/models/media_enums.dart';
import 'media_library_providers.dart';

/// Square grid cell: thumbnail with video and failure badges.
class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final MediaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = ref.watch(thumbnailProvider(item.sourceMediaId)).value;
    final isVideo = item.kind == MediaKind.video;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: item.displayName,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
            else
              ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  isVideo ? Icons.movie_outlined : Icons.image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (isVideo)
              const Positioned(
                right: 4,
                bottom: 4,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 20,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            if (selected) ...[
              ColoredBox(color: scheme.primary.withValues(alpha: 0.35)),
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: scheme.onPrimary,
                  size: 22,
                ),
              ),
            ],
            if (item.status == TransferStatus.failed)
              Positioned(
                left: 4,
                top: 4,
                child: Icon(
                  Icons.error_rounded,
                  color: scheme.error,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
