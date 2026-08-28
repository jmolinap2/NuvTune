import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';

/// Agrega canciones a una lista existente o a una nueva
/// (requerimiento seccion 4.1).
Future<void> showAddToPlaylistSheet(
  BuildContext context, {
  required List<int> songIds,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _AddToPlaylistSheet(songIds: songIds),
);

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.songIds});

  final List<int> songIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final counts =
        ref.watch(playlistSongCountsProvider).valueOrNull ?? const {};

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.addToPlaylist,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  songIds.length == 1
                      ? '1 canción'
                      : '${songIds.length} canciones',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text(AppStrings.newPlaylist),
            onTap: () => _createAndAdd(context, ref),
          ),
          const Divider(height: 8),
          Flexible(
            child: playlists.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text('Todavía no hay listas creadas'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final count = counts[playlist.id] ?? 0;
                      return ListTile(
                        leading: const Icon(Icons.queue_music_rounded),
                        title: Text(playlist.name),
                        subtitle: Text(
                          count == 1 ? '1 canción' : '$count canciones',
                        ),
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          await ref
                              .read(playlistRepositoryProvider)
                              .addSongs(playlist.id, songIds);
                          navigator.pop();
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context, WidgetRef ref) async {
    final name = await promptForPlaylistName(context);
    if (name == null) return;
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(playlistRepositoryProvider).create(name, songIds: songIds);
    navigator.pop();
  }
}

/// Dialogo de nombre de lista, compartido por la creacion y el renombrado.
Future<String?> promptForPlaylistName(
  BuildContext context, {
  String initialValue = '',
  String title = AppStrings.newPlaylist,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: AppStrings.playlistName),
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = controller.text.trim();
            if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
          },
          child: const Text(AppStrings.save),
        ),
      ],
    ),
  );
}
