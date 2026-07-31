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
}
