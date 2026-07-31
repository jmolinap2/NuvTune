import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';

/// Fila de cancion reutilizada por todas las listas.
///
/// Marca la cancion en reproduccion y las que el dispositivo no puede
/// decodificar (requerimiento seccion 6).
class SongTile extends ConsumerWidget {
  const SongTile({
    required this.song,
    this.onTap,
    this.onMore,
    this.subtitleOverride,
    this.trailing,
    this.dense = false,
    this.showFavorite = true,
    super.key,
  });

  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final String? subtitleOverride;
  final Widget? trailing;
  final bool dense;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final currentSongId =
        ref.watch(playbackProvider.select((state) => state.currentSong?.id));
    final isCurrent = currentSongId == song.id;
    final favorites = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favorites.contains(song.id);

    final subtitle = subtitleOverride ??
        '${song.displayArtist} · ${Formatters.duration(song.durationMs)}';

    return ListTile(
      onTap: song.isSupported ? onTap : null,
      dense: dense,
      leading: CoverArt(song: song, size: dense ? 44 : 52),
      title: Row(
        children: [
          Expanded(
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? scheme.primary
                    : song.isSupported
                        ? null
                        : scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          if (!song.isSupported)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Tooltip(
                message: AppStrings.unsupportedFormat,
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: scheme.error,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: song.isSupported
              ? scheme.onSurfaceVariant
              : scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFavorite && isFavorite)
                Icon(Icons.favorite_rounded, size: 18, color: scheme.primary),
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Más opciones',
                ),
            ],
          ),
    );
  }
}

/// Fila de grupo: album, artista, carpeta, genero o compositor.
class GroupTile extends StatelessWidget {
  const GroupTile({
    required this.title,
    required this.subtitle,
    required this.coverSong,
    this.onTap,
    this.onMore,
    this.icon = Icons.album_rounded,
    super.key,
  });

  final String title;
  final String subtitle;
  final Song? coverSong;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: GroupCover(song: coverSong, size: 52, borderRadius: 12, icon: icon),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onMore == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Más opciones',
            ),
    );
  }
}
