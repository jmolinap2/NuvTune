import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/playlists/gift_editor_sheet.dart';
import 'package:nuvtune/features/playlists/m3u.dart';
import 'package:nuvtune/shared/widgets/add_to_playlist_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Acciones sobre una lista de reproduccion (requerimiento seccion 4.4):
/// renombrar, cambiar portada, duplicar, exportar e importar M3U, compartir el
/// listado y eliminar sin borrar las canciones.
Future<void> showPlaylistActions(
  BuildContext context, {
  required int playlistId,
  required String playlistName,
}) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _PlaylistActionsSheet(
        playlistId: playlistId,
        playlistName: playlistName,
      ),
    );

class _PlaylistActionsSheet extends ConsumerWidget {
  const _PlaylistActionsSheet({
    required this.playlistId,
    required this.playlistName,
  });

  final int playlistId;
  final String playlistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final playlist = playlists.where((item) => item.id == playlistId).firstOrNull;
    final isGift = playlist?.giftMode ?? false;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(playlistName),
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline_rounded),
            title: const Text(AppStrings.rename),
            onTap: () async {
              final navigator = Navigator.of(context);
              final name = await promptForPlaylistName(
                context,
                initialValue: playlistName,
                title: AppStrings.rename,
              );
              if (name == null) return;
              await ref
                  .read(playlistRepositoryProvider)
                  .rename(playlistId, name);
              navigator.pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text(AppStrings.changeCover),
            onTap: () => _changeCover(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.copy_all_rounded),
            title: const Text(AppStrings.duplicate),
            onTap: () async {
              final navigator = Navigator.of(context);
              await ref.read(playlistRepositoryProvider).duplicate(playlistId);
              navigator.pop();
            },
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.card_giftcard_rounded),
            title: Text(isGift ? 'Editar regalo…' : 'Convertir en regalo…'),
            onTap: playlist == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    showGiftEditor(context, playlist: playlist);
                  },
          ),
          if (isGift)
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Compartir regalo'),
              onTap: () => _shareGift(context, ref, playlist!),
            ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text(AppStrings.exportM3u),
            onTap: () => _exportM3u(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text(AppStrings.importM3u),
            onTap: () => _importM3u(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text(AppStrings.shareListing),
            onTap: () => _shareListing(context, ref),
          ),
          const Divider(height: 8),
          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              AppStrings.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(AppStrings.deletePlaylistNote),
            onTap: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _changeCover(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = Uint8List.fromList(await picked.readAsBytes());
    final path = await ref
        .read(coverRepositoryProvider)
        .savePlaylistCover(playlistId, bytes);
    await ref.read(playlistRepositoryProvider).setCover(playlistId, path);
    navigator.pop();
  }

  Future<void> _exportM3u(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final songIds = await ref.read(playlistRepositoryProvider).songIds(playlistId);
    final songs = ref.read(libraryRepositoryProvider).songsByIds(songIds);
    final content = M3u.write(playlistName, songs);

    final uri = await ref.read(engineProvider).api.createTextDocument(
          '$playlistName.m3u',
          'audio/x-mpegurl',
          content,
        );

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          uri == null
              ? 'No se exporto ningun archivo'
              : 'Lista exportada con ${songs.length} canciones',
        ),
      ),
    );
  }

  Future<void> _importM3u(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(engineProvider);

    final document = await engine.api.pickDocument(
      const ['audio/x-mpegurl', 'audio/mpegurl', 'text/plain', '*/*'],
    );
    if (document == null) return;

    final content = await engine.api.readDocumentText(document.uri);
    final imported = M3u.parse(content, ref.read(libraryRepositoryProvider).songs);

    await ref.read(playlistRepositoryProvider).addSongs(
          playlistId,
          imported.songs.map((song) => song.id).toList(),
        );

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          imported.missingEntries.isEmpty
              ? 'Se agregaron ${imported.songs.length} canciones'
              : 'Se agregaron ${imported.songs.length} canciones. '
                  '${imported.missingEntries.length} entradas no se encontraron '
                  'en el dispositivo.',
        ),
      ),
    );
  }

  Future<void> _shareListing(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final songIds = await ref.read(playlistRepositoryProvider).songIds(playlistId);
    final songs = ref.read(libraryRepositoryProvider).songsByIds(songIds);
    await ref
        .read(engineProvider)
        .api
        .shareText(playlistName, M3u.plainListing(playlistName, songs));
    navigator.pop();
  }

  /// Exporta la lista como `.nuvtune-gift`: un JSON con metadatos y canciones
  /// por (título, artista, álbum) en vez de ids de MediaStore, para que el
  /// receptor pueda matchearlas contra su propia biblioteca al importar.
  Future<void> _shareGift(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final navigator = Navigator.of(context);
    final songIds = await ref.read(playlistRepositoryProvider).songIds(playlistId);
    final songs = ref.read(libraryRepositoryProvider).songsByIds(songIds);

    final payload = <String, dynamic>{
      'name': playlist.name,
      'dedication': playlist.dedication,
      'from': playlist.giftFrom,
      'to': playlist.giftTo,
      'accentId': playlist.giftAccentId,
      'songs': [
        for (final song in songs)
          {'title': song.title, 'artist': song.artist, 'album': song.album},
      ],
    };

    final directory = await getTemporaryDirectory();
    final safeName = playlist.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final file = File('${directory.path}/${safeName.isEmpty ? 'regalo' : safeName}.nuvtune-gift');
    await file.writeAsString(jsonEncode(payload));

    navigator.pop();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: playlist.name,
        text: 'Te regalo esta playlist: ${playlist.name}',
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final sheetNavigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: Text(
          'Se eliminara la lista "$playlistName".\n\n'
          '${AppStrings.deletePlaylistNote}',
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
              await ref.read(playlistRepositoryProvider).delete(playlistId);
              sheetNavigator.pop();
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
