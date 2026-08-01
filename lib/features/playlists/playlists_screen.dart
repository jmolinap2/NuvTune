import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/playlists/playlists_list.dart';
import 'package:nuvtune/shared/widgets/add_to_playlist_sheet.dart';

/// Seccion Listas de la navegacion inferior (requerimiento seccion 12).
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navPlaylists),
        actions: [
          IconButton(
            tooltip: 'Importar regalo',
            icon: const Icon(Icons.card_giftcard_rounded),
            onPressed: () => _importGift(context, ref),
          ),
          IconButton(
            tooltip: AppStrings.newPlaylist,
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final name = await promptForPlaylistName(context);
              if (name == null) return;
              await ref.read(playlistRepositoryProvider).create(name);
            },
          ),
        ],
      ),
      body: const PlaylistsList(),
    );
  }

  /// Importa un archivo `.nuvtune-gift` exportado desde `playlist_actions.dart`:
  /// las canciones no viajan por id de MediaStore, se matchean por
  /// (título, artista) contra la biblioteca del receptor.
  Future<void> _importGift(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(engineProvider);

    final document = await engine.api.pickDocument(
      const ['application/json', 'text/plain', '*/*'],
    );
    if (document == null) return;

    final Map<String, dynamic> payload;
    try {
      final content = await engine.api.readDocumentText(document.uri);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      payload = decoded;
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('El archivo no es un regalo válido')),
      );
      return;
    }

    final library = ref.read(libraryRepositoryProvider);
    final byKey = <String, int>{};
    for (final song in library.songs) {
      byKey.putIfAbsent(_giftKey(song.title, song.artist), () => song.id);
    }

    final songEntries = (payload['songs'] as List?) ?? const [];
    final matchedIds = <int>[];
    var missing = 0;
    for (final entry in songEntries) {
      if (entry is! Map) {
        missing++;
        continue;
      }
      final key = _giftKey(
        (entry['title'] as String?) ?? '',
        (entry['artist'] as String?) ?? '',
      );
      final id = byKey[key];
      if (id == null) {
        missing++;
      } else {
        matchedIds.add(id);
      }
    }

    final name = (payload['name'] as String?)?.trim();
    final playlistId = await ref.read(playlistRepositoryProvider).create(
          (name == null || name.isEmpty) ? 'Regalo' : name,
          songIds: matchedIds,
        );
    await ref.read(playlistRepositoryProvider).setGift(
          playlistId,
          giftMode: true,
          dedication: payload['dedication'] as String?,
          giftFrom: payload['from'] as String?,
          giftTo: payload['to'] as String?,
          giftAccentId: payload['accentId'] as String?,
        );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          missing == 0
              ? 'Regalo importado con ${matchedIds.length} canciones'
              : 'Regalo importado con ${matchedIds.length} canciones. '
                  '$missing no se encontraron en tu biblioteca.',
        ),
      ),
    );
  }

  static String _giftKey(String title, String artist) =>
      '${title.trim().toLowerCase()}||${artist.trim().toLowerCase()}';
}
