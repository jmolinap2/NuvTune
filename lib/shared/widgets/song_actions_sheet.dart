import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/add_to_playlist_sheet.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';

/// Menu contextual de una cancion con todas las acciones del requerimiento
/// seccion 4.1.
Future<void> showSongActions(
  BuildContext context, {
  required Song song,
  List<Song>? contextSongs,
  VoidCallback? onRemoveFromContext,
  String? removeFromContextLabel,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SongActionsSheet(
        song: song,
        contextSongs: contextSongs,
        onRemoveFromContext: onRemoveFromContext,
        removeFromContextLabel: removeFromContextLabel,
      ),
    );

class _SongActionsSheet extends ConsumerWidget {
  const _SongActionsSheet({
    required this.song,
    this.contextSongs,
    this.onRemoveFromContext,
    this.removeFromContextLabel,
  });

  final Song song;
  final List<Song>? contextSongs;
  final VoidCallback? onRemoveFromContext;
  final String? removeFromContextLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final favorites = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favorites.contains(song.id);
    final playback = ref.read(playbackProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CoverArt(song: song, size: 52),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${song.displayArtist} · ${Formatters.duration(song.durationMs)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 8),

            if (song.isSupported) ...[
              _Action(
                icon: Icons.play_arrow_rounded,
                label: 'Reproducir',
                onTap: () {
                  Navigator.of(context).pop();
                  playback.playSong(song, within: contextSongs);
                },
              ),
              _Action(
                icon: Icons.playlist_play_rounded,
                label: AppStrings.playNext,
                onTap: () {
                  Navigator.of(context).pop();
                  playback.playNext([song]);
                },
              ),
              _Action(
                icon: Icons.queue_music_rounded,
                label: AppStrings.addToQueue,
                onTap: () {
                  Navigator.of(context).pop();
                  playback.addToQueue([song]);
                },
              ),
            ] else
              ListTile(
                leading: Icon(Icons.error_outline_rounded, color: scheme.error),
                title: const Text(AppStrings.unsupportedFormat),
                subtitle: Text('MIME: ${song.mimeType}'),
              ),

            _Action(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: isFavorite ? 'Quitar de favoritos' : AppStrings.favorite,
              onTap: () {
                Navigator.of(context).pop();
                playback.toggleFavorite(song.id);
              },
            ),
            _Action(
              icon: Icons.playlist_add_rounded,
              label: AppStrings.addToPlaylist,
              onTap: () {
                Navigator.of(context).pop();
                showAddToPlaylistSheet(context, songIds: [song.id]);
              },
            ),

            const Divider(height: 8),

            _Action(
              icon: Icons.edit_rounded,
              label: AppStrings.editInfo,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/song/${song.id}/edit');
              },
            ),
            _Action(
              icon: Icons.album_rounded,
              label: 'Ir al álbum',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/album/${song.albumId}');
              },
            ),
            _Action(
              icon: Icons.person_rounded,
              label: 'Ir al artista',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/artist/${song.artistId}');
              },
            ),
            _Action(
              icon: Icons.info_outline_rounded,
              label: AppStrings.technicalInfo,
              onTap: () {
                Navigator.of(context).pop();
                showTechnicalInfo(context, song: song);
              },
            ),

            const Divider(height: 8),

            _Action(
              icon: Icons.share_rounded,
              label: AppStrings.share,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(engineProvider).api.shareSongs([song.id]);
              },
            ),
            _Action(
              icon: Icons.folder_open_rounded,
              label: AppStrings.showFileLocation,
              onTap: () {
                Navigator.of(context).pop();
                _showFileLocation(context, ref);
              },
            ),
            _Action(
              icon: Icons.folder_off_rounded,
              label: AppStrings.excludeFolder,
              onTap: () {
                Navigator.of(context).pop();
                _confirmExcludeFolder(context, ref);
              },
            ),

            if (onRemoveFromContext != null)
              _Action(
                icon: Icons.playlist_remove_rounded,
                label: removeFromContextLabel ?? AppStrings.removeFromLibrary,
                onTap: () {
                  Navigator.of(context).pop();
                  onRemoveFromContext!();
                },
              ),

            _Action(
              icon: Icons.delete_outline_rounded,
              label: AppStrings.deleteFromDevice,
              destructive: true,
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFileLocation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.showFileLocation),
        content: SelectableText(song.filePath),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(engineProvider).api.revealFile(song.id);
            },
            child: const Text('Abrir en el explorador'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  void _confirmExcludeFolder(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.excludeFolder),
        content: Text(
          'Se dejaran de mostrar las canciones de:\n\n${song.folderPath}\n\n'
          'Los archivos no se eliminan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(libraryProvider.notifier).excludeFolder(song.folderPath);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// El requerimiento seccion 16 exige diferenciar quitar de la biblioteca de
  /// eliminar del dispositivo; esta accion borra el archivo y lo advierte.
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteFromDevice),
        content: Text(
          'Se eliminara el archivo del dispositivo:\n\n${song.title}\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final result =
                  await ref.read(engineProvider).api.deleteSongFile(song.id);
              if (result.outcome == WriteOutcome.success) {
                await ref.read(libraryProvider.notifier).scan();
              }
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : null;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}

/// Vista tecnica del archivo (requerimiento seccion 4.2).
Future<void> showTechnicalInfo(BuildContext context, {required Song song}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TechnicalInfoSheet(song: song),
    );

class _TechnicalInfoSheet extends ConsumerWidget {
  const _TechnicalInfoSheet({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: FutureBuilder<TechnicalInfo>(
        future: ref.read(engineProvider).api.getTechnicalInfo(song.id),
        builder: (context, snapshot) {
          final info = snapshot.data;
          if (info == null) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final rows = <(String, String)>[
            ('Título', song.title),
            ('Artista', song.displayArtist),
            ('Álbum', song.displayAlbum),
            ('Contenedor', info.container),
            ('Codec', info.codec),
            ('Tipo MIME', info.mimeType),
            ('Duración', Formatters.duration(info.durationMs)),
            ('Bitrate', Formatters.bitrate(info.bitrateBps)),
            ('Frecuencia de muestreo', Formatters.sampleRate(info.sampleRateHz)),
            ('Profundidad de bits', Formatters.bitDepth(info.bitsPerSample)),
            ('Canales', Formatters.channels(info.channels)),
            ('Tamaño del archivo', Formatters.fileSize(info.sizeBytes)),
            ('Agregado', Formatters.epochDate(song.dateAdded)),
            ('Modificado', Formatters.epochDate(song.dateModified)),
            ('Carpeta', song.folderPath),
            (
              'Compatibilidad',
              info.isSupported
                  ? 'Reproducible en este dispositivo'
                  : (info.unsupportedReason ?? AppStrings.unsupportedFormat),
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.technicalInfo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
