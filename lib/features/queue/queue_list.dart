import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/add_to_playlist_sheet.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/song_tile.dart';

/// Cola editable sin detener la musica (requerimiento seccion 4.3).
///
/// Se usa como pestana del reproductor completo y como pantalla propia. Todas
/// las ediciones viajan al motor, que es el dueno de la cola real; la base de
/// datos solo guarda una copia para restaurarla al abrir la aplicacion.
class QueueList extends ConsumerWidget {
  const QueueList({this.showHeader = true, super.key});

  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider);
    final controller = ref.read(playbackProvider.notifier);

    if (state.queue.isEmpty) {
      return const EmptyState(
        icon: Icons.queue_music_outlined,
        title: AppStrings.emptyQueue,
        message: 'Reproduce algo desde la biblioteca para llenar la cola.',
      );
    }

    return Column(
      children: [
        if (showHeader)
          _QueueHeader(
            queue: state.queue,
            onSaveAsPlaylist: () => _saveAsPlaylist(context, ref, state.queue),
            onClear: controller.clearQueue,
          ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: state.queue.length,
            onReorderItem: controller.moveInQueue,
            itemBuilder: (context, index) {
              final song = state.queue[index];
              final isCurrent = index == state.snapshot.currentIndex;

              return Dismissible(
                key: ValueKey('queue-$index-${song.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.remove_circle_outline_rounded),
                ),
                onDismissed: (_) => controller.removeFromQueue(index),
                child: SongTile(
                  song: song,
                  dense: true,
                  showFavorite: false,
                  onTap: () => controller.playQueueIndex(index),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent)
                        Icon(
                          state.isPlaying
                              ? Icons.equalizer_rounded
                              : Icons.pause_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.drag_handle_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveAsPlaylist(
    BuildContext context,
    WidgetRef ref,
    List<Song> queue,
  ) async {
    final name = await promptForPlaylistName(
      context,
      title: AppStrings.saveQueueAsPlaylist,
    );
    if (name == null) return;
    await ref
        .read(playlistRepositoryProvider)
        .create(name, songIds: queue.map((song) => song.id).toList());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lista "$name" creada con ${queue.length} canciones'),
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.queue,
    required this.onSaveAsPlaylist,
    required this.onClear,
  });

  final List<Song> queue;
  final VoidCallback onSaveAsPlaylist;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final totalMs = queue.fold(0, (sum, song) => sum + song.durationMs);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${Formatters.trackCount(queue.length)} · '
              '${Formatters.durationVerbose(totalMs)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.saveQueueAsPlaylist,
            icon: const Icon(Icons.playlist_add_rounded),
            onPressed: onSaveAsPlaylist,
          ),
          IconButton(
            tooltip: AppStrings.clearQueue,
            icon: const Icon(Icons.clear_all_rounded),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
