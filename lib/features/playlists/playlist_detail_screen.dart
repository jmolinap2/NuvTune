import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/playlists/playlist_actions.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/song_actions_sheet.dart';
import 'package:nuvtune/shared/widgets/song_tile.dart';
import 'package:nuvtune/shared/widgets/sort_filter_bar.dart';

/// Detalle de una lista con reordenamiento manual (requerimiento seccion 4.4).
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({required this.playlistId, super.key});

  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final playlist = playlists
        .where((item) => item.id == playlistId)
        .firstOrNull;

    final songIdsAsync = ref.watch(_playlistSongIdsProvider(playlistId));
    final songIds = songIdsAsync.valueOrNull ?? const <int>[];
    final songs = ref.watch(libraryRepositoryProvider).songsByIds(songIds);

    final title = playlist?.name ?? 'Lista';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: playlist == null
                ? null
                : () => showPlaylistActions(
                    context,
                    playlistId: playlistId,
                    playlistName: playlist.name,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          PlayAllHeader(
            count: songs.length,
            subtitle: songs.isEmpty
                ? 'Lista vacía'
                : '${Formatters.trackCount(songs.length)} · '
                      '${Formatters.durationVerbose(songs.fold(0, (sum, song) => sum + song.durationMs))}',
            onPlayAll: () =>
                ref.read(playbackProvider.notifier).playSongs(songs),
            onShuffleAll: () => ref
                .read(playbackProvider.notifier)
                .playSongs(songs, shuffle: true),
          ),
          Expanded(
            child: songs.isEmpty
                ? EmptyState(
                    icon: Icons.playlist_add_rounded,
                    title: 'Esta lista está vacía',
                    message:
                        'Agrega canciones desde la biblioteca con "${AppStrings.addToPlaylist}".',
                    actionLabel: AppStrings.navLibrary,
                    onAction: () => context.go('/library'),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: songs.length,
                    // onReorderItem ya entrega el indice destino ajustado al
                    // hueco que deja el elemento movido.
                    onReorderItem: (oldIndex, newIndex) => ref
                        .read(playlistRepositoryProvider)
                        .move(playlistId, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _PlaylistSongTile(
                        key: ValueKey('playlist-$playlistId-$index-${song.id}'),
                        song: song,
                        index: index,
                        songs: songs,
                        playlistId: playlistId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistSongTile extends ConsumerWidget {
  const _PlaylistSongTile({
    required this.song,
    required this.index,
    required this.songs,
    required this.playlistId,
    super.key,
  });

  final Song song;
  final int index;
  final List<Song> songs;
  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongTile(
      song: song,
      onTap: () => ref
          .read(playbackProvider.notifier)
          .playSongs(songs, startIndex: index),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Más opciones',
            onPressed: () => showSongActions(
              context,
              song: song,
              contextSongs: songs,
              removeFromContextLabel: 'Quitar de la lista',
              onRemoveFromContext: () => ref
                  .read(playlistRepositoryProvider)
                  .removeAt(playlistId, index),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_handle_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// Canciones de una lista concreta, observadas para que el reordenamiento se
/// refleje sin recargar la pantalla.
final _playlistSongIdsProvider = StreamProvider.family<List<int>, int>((
  ref,
  playlistId,
) {
  return ref.watch(playlistRepositoryProvider).watchSongIds(playlistId);
});
