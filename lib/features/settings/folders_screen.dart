import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Carpetas excluidas del escaneo (requerimiento seccion 4.1).
class ExcludedFoldersScreen extends ConsumerWidget {
  const ExcludedFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excluded = ref.watch(excludedFoldersProvider).valueOrNull ?? const [];
    final folders = ref.watch(libraryRepositoryProvider).folders();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsExcludedFolders),
        actions: [
          IconButton(
            tooltip: 'Excluir una carpeta',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showFolderPicker(context, ref),
          ),
        ],
      ),
      body: excluded.isEmpty
          ? EmptyState(
              icon: Icons.folder_off_outlined,
              title: 'Ninguna carpeta excluida',
              message:
                  'Las ${folders.length} carpetas con música del dispositivo '
                  'están visibles.',
              actionLabel: 'Excluir una carpeta',
              onAction: () => _showFolderPicker(context, ref),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Las canciones de estas carpetas no aparecen en la '
                    'biblioteca. Los archivos no se eliminan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final path in excluded)
                  ListTile(
                    leading: const Icon(Icons.folder_off_rounded),
                    title: Text(path.split('/').last),
                    subtitle: Text(path),
                    trailing: IconButton(
                      tooltip: 'Volver a incluir',
                      icon: const Icon(Icons.undo_rounded),
                      onPressed: () =>
                          ref.read(libraryProvider.notifier).includeFolder(path),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showFolderPicker(BuildContext context, WidgetRef ref) {
    final folders = ref.read(libraryRepositoryProvider).folders();
    final excluded = ref.read(excludedFoldersProvider).valueOrNull ?? const [];
    final available =
        folders.where((group) => !excluded.contains(group.key)).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Elegir carpeta a excluir',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final folder = available[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_rounded),
                    title: Text(folder.title),
                    subtitle: Text(
                      '${Formatters.trackCount(folder.songs.length)} · ${folder.key}',
                      maxLines: 2,
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ref
                          .read(libraryProvider.notifier)
                          .excludeFolder(folder.key);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carpetas concedidas con el selector del sistema (requerimiento seccion 10).
class SourceFoldersScreen extends ConsumerWidget {
  const SourceFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(sourceFoldersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsSourceFolders),
        actions: [
          IconButton(
            tooltip: 'Agregar carpeta',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addFolder(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'El almacenamiento interno y la tarjeta SD ya se escanean con el '
              'permiso de audio. Conceder una carpeta adicional sirve para que '
              'NuvTune pueda leer y escribir archivos que no son medios, como '
              'los .lrc de las letras y los .m3u de las listas.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (folders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: EmptyState(
                icon: Icons.create_new_folder_outlined,
                title: 'Ninguna carpeta concedida',
              ),
            )
          else
            for (final folder in folders)
              ListTile(
                leading: const Icon(Icons.folder_special_rounded),
                title: Text(folder.displayPath.split('/').last),
                subtitle: Text(folder.displayPath),
                trailing: IconButton(
                  tooltip: 'Revocar acceso',
                  icon: const Icon(Icons.link_off_rounded),
                  onPressed: () async {
                    await ref.read(engineProvider).api.releaseFolder(folder.uri);
                    await ref
                        .read(settingsRepositoryProvider)
                        .removeSourceFolder(folder.uri);
                  },
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final granted = await ref.read(engineProvider).api.pickFolder();
    if (granted == null) return;
    await ref
        .read(settingsRepositoryProvider)
        .addSourceFolder(granted.uri, granted.displayPath);
    await ref.read(libraryProvider.notifier).scan();
  }
}
