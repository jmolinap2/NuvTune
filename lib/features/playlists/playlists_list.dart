import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/playlists/playlist_actions.dart';
import 'package:nuvtune/features/playlists/smart_playlists.dart';
import 'package:nuvtune/shared/widgets/add_to_playlist_sheet.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Listado de listas de reproduccion.
///
/// Lo comparten la pestana Listas de la biblioteca y la seccion Listas de la
/// navegacion inferior, que el requerimiento pide en los dos sitios
/// (secciones 11 y 12).
class PlaylistsList extends ConsumerWidget {
  const PlaylistsList({this.showSmartPlaylists = true, super.key});

  final bool showSmartPlaylists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final counts = ref.watch(playlistSongCountsProvider).valueOrNull ?? const {};
    final customCovers = ref.watch(customCoversProvider).valueOrNull ?? const {};

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Colecciones que existen siempre (requerimiento seccion 4.4).
        _FixedCollection(
          icon: Icons.favorite_rounded,
          label: AppStrings.homeFavorites,
          route: '/collection/favorites',
        ),
        _FixedCollection(
          icon: Icons.history_rounded,
          label: AppStrings.homeRecentlyPlayed,
          route: '/collection/recently-played',
        ),
        _FixedCollection(
          icon: Icons.trending_up_rounded,
          label: AppStrings.homeMostPlayed,
          route: '/collection/most-played',
        ),
        _FixedCollection(
          icon: Icons.schedule_rounded,
          label: AppStrings.recentlyAdded,
          route: '/collection/recently-added',
        ),

        if (showSmartPlaylists) ...[
          const SectionHeader(title: AppStrings.smartPlaylists),
          for (final smart in SmartPlaylist.values)
            ListTile(
              leading: Icon(smart.icon),
              title: Text(smart.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/smart/${smart.key}'),
            ),
          // La septima lista inteligente del requerimiento 4.4 necesita que el
          // usuario diga cual es la carpeta, asi que pregunta antes de abrir.
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: const Text(AppStrings.smartFromFolder),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickFolder(context, ref),
          ),
        ],

        SectionHeader(
          title: 'Mis listas',
          actionLabel: AppStrings.newPlaylist,
          onAction: () => _createPlaylist(context, ref),
        ),

        if (playlists.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              icon: Icons.queue_music_outlined,
              title: 'Todavía no hay listas',
              message: 'Crea una lista para agrupar tus canciones.',
            ),
          )
        else
          for (final playlist in playlists)
            ListTile(
              leading: GroupCover(
                song: null,
                customPath: playlist.coverPath ??
                    customCovers['playlist:${playlist.id}'],
                size: 52,
                borderRadius: 12,
                icon: Icons.queue_music_rounded,
              ),
              title: playlist.giftMode
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            playlist.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _GiftChip(),
                      ],
                    )
                  : Text(playlist.name),
              subtitle: Text(
                (counts[playlist.id] ?? 0) == 1
                    ? '1 canción'
                    : '${counts[playlist.id] ?? 0} canciones',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => showPlaylistActions(
                  context,
                  playlistId: playlist.id,
                  playlistName: playlist.name,
                ),
              ),
              onTap: () => context.push('/playlist/${playlist.id}'),
            ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await promptForPlaylistName(context);
    if (name == null) return;
    await ref.read(playlistRepositoryProvider).create(name);
  }

  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final folders = ref.read(libraryRepositoryProvider).folders();
    final router = GoRouter.of(context);

    final path = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.smartFromFolder,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.title),
                    subtitle: Text(
                      folder.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(folder.key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (path == null) return;
    router.push('/folder?path=${Uri.encodeComponent(path)}');
  }
}

/// Insignia "🎁 Regalo" para las listas convertidas en regalo.
class _GiftChip extends StatelessWidget {
  const _GiftChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.primary.withValues(alpha: 0.16),
      ),
      child: Text(
        '🎁 Regalo',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FixedCollection extends StatelessWidget {
  const _FixedCollection({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.primary.withValues(alpha: 0.16),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: scheme.primary, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(route),
    );
  }
}
