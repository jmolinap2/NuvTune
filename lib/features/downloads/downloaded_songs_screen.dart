import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/downloads/downloaded_song_mapper.dart';
import 'package:nuvtune/features/downloads/downloads_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Lista de canciones descargadas desde internet, con reproduccion y borrado
/// (feature "buscar y descargar canciones").
class DownloadedSongsScreen extends ConsumerWidget {
  const DownloadedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadedSongsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descargas de internet'),
        actions: [
          IconButton(
            tooltip: 'Buscar canciones',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/downloads/search'),
          ),
        ],
      ),
      body: downloads.isEmpty
          ? EmptyState(
              icon: Icons.download_outlined,
              title: 'Sin descargas',
              message: 'Busca canciones y descárgalas para escucharlas sin conexión.',
              actionLabel: 'Buscar canciones',
              onAction: () => context.push('/downloads/search'),
            )
          : ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final downloaded = downloads[index];
                return ListTile(
                  leading: _DownloadedCover(coverPath: downloaded.coverPath),
                  title: Text(
                    downloaded.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    downloaded.durationMs > 0
                        ? '${downloaded.artist} · ${Formatters.duration(downloaded.durationMs)}'
                        : downloaded.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final songs = downloads.map((d) => d.toSong()).toList();
                    ref
                        .read(playbackProvider.notifier)
                        .playSongs(songs, startIndex: index);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar',
                    onPressed: () =>
                        ref.read(downloadRepositoryProvider).delete(downloaded.id),
                  ),
                );
              },
            ),
    );
  }
}

class _DownloadedCover extends StatelessWidget {
  const _DownloadedCover({required this.coverPath});

  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    final path = coverPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: path == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Icon(Icons.music_note_rounded),
              )
            : Image.file(File(path), fit: BoxFit.cover),
      ),
    );
  }
}
