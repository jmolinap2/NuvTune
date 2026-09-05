import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/confirm_dialog.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Fuentes remotas (requerimiento seccion 10).
///
/// Es una seccion aparte a proposito: el requerimiento exige que lo remoto
/// nunca se mezcle en silencio con la biblioteca local, de modo que estas
/// canciones no entran en el escaneo, no aparecen en Biblioteca y llevan
/// identificadores propios.
class RemoteSourcesScreen extends ConsumerWidget {
  const RemoteSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(remoteSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.remoteSources)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSource(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addRemoteSource),
      ),
      body: sourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (sources) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                AppStrings.remoteSourcesNote,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (sources.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Sin fuentes remotas',
                  message:
                      'Agrega un servidor SMB, WebDAV, un enlace directo '
                      'o una emisora de radio.',
                ),
              )
            else
              for (final source in sources)
                ListTile(
                  leading: Icon(_iconFor(source.kind)),
                  title: Text(source.name),
                  subtitle: Text(
                    source.uri,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _remove(context, ref, source),
                  ),
                  onTap: () => _open(context, ref, source),
                ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, RemoteSource source) {
    // Una emisora o un enlace directo no tienen arbol: se reproducen ya.
    if (source.kind == RemoteSourceKind.radio ||
        source.kind == RemoteSourceKind.http) {
      _playDirect(context, ref, source);
      return;
    }
    context.push(
      '/remote/${source.id}?name=${Uri.encodeComponent(source.name)}',
    );
  }

  Future<void> _playDirect(
    BuildContext context,
    WidgetRef ref,
    RemoteSource source,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final songs = await ref.read(engineProvider).api.resolveRemoteSongs(
      source.id,
      [source.uri],
    );
    if (songs.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la fuente')),
      );
      return;
    }
    await ref.read(playbackProvider.notifier).playSongs(songs);
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    RemoteSource source,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Quitar fuente remota',
      message: 'Se quitará "${source.name}" de las fuentes remotas.',
    );
    if (!confirmed) return;
    await ref.read(engineProvider).api.removeRemoteSource(source.id);
    ref.invalidate(remoteSourcesProvider);
  }

  Future<void> _addSource(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_NewSource>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddSourceSheet(),
    );
    if (result == null) return;

    await ref
        .read(engineProvider)
        .api
        .addRemoteSource(
          result.kind,
          result.name,
          result.uri,
          result.username,
          result.password,
        );
    ref.invalidate(remoteSourcesProvider);
  }

  static IconData _iconFor(RemoteSourceKind kind) => switch (kind) {
    RemoteSourceKind.smb => Icons.dns_rounded,
    RemoteSourceKind.webdav => Icons.cloud_outlined,
    RemoteSourceKind.http => Icons.link_rounded,
    RemoteSourceKind.radio => Icons.radio_rounded,
  };
}

class _NewSource {
  const _NewSource({
    required this.kind,
    required this.name,
    required this.uri,
    this.username,
    this.password,
  });

  final RemoteSourceKind kind;
  final String name;
  final String uri;
  final String? username;
  final String? password;
}

class _AddSourceSheet extends StatefulWidget {
  const _AddSourceSheet();

  @override
  State<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends State<_AddSourceSheet> {
  RemoteSourceKind _kind = RemoteSourceKind.smb;
  final _name = TextEditingController();
  final _uri = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _uri.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _needsCredentials =>
      _kind == RemoteSourceKind.smb || _kind == RemoteSourceKind.webdav;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.addRemoteSource,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<RemoteSourceKind>(
              segments: const [
                ButtonSegment(value: RemoteSourceKind.smb, label: Text('SMB')),
                ButtonSegment(
                  value: RemoteSourceKind.webdav,
                  label: Text('WebDAV'),
                ),
                ButtonSegment(
                  value: RemoteSourceKind.http,
                  label: Text('HTTP'),
                ),
                ButtonSegment(
                  value: RemoteSourceKind.radio,
                  label: Text('Radio'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uri,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Direccion',
                hintText: _hintFor(_kind),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_needsCredentials) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _username,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Usuario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Se guarda cifrada con la Keystore de Android.',
                  helperMaxLines: 2,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('Agregar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final uri = _uri.text.trim();
    if (uri.isEmpty) return;
    Navigator.of(context).pop(
      _NewSource(
        kind: _kind,
        name: _name.text.trim().isEmpty ? uri : _name.text.trim(),
        uri: uri,
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
      ),
    );
  }

  static String _hintFor(RemoteSourceKind kind) => switch (kind) {
    RemoteSourceKind.smb => 'smb://192.168.1.10/musica',
    RemoteSourceKind.webdav => 'https://servidor/remote.php/dav/musica',
    RemoteSourceKind.http => 'https://servidor/cancion.flac',
    RemoteSourceKind.radio => 'https://emisora/stream.mp3',
  };
}

/// Explorador de una fuente remota con arbol de carpetas.
class RemoteBrowserScreen extends ConsumerStatefulWidget {
  const RemoteBrowserScreen({
    super.key,
    required this.sourceId,
    required this.title,
  });

  final int sourceId;
  final String title;

  @override
  ConsumerState<RemoteBrowserScreen> createState() =>
      _RemoteBrowserScreenState();
}

class _RemoteBrowserScreenState extends ConsumerState<RemoteBrowserScreen> {
  /// Pila de rutas visitadas, para que el boton atras suba un nivel.
  final List<String> _path = [''];

  late Future<List<RemoteEntry>> _entries = _load();

  Future<List<RemoteEntry>> _load() => ref
      .read(engineProvider)
      .api
      .browseRemoteSource(widget.sourceId, _path.last);

  void _enter(String uri) {
    setState(() {
      _path.add(uri);
      _entries = _load();
    });
  }

  bool _goBack() {
    if (_path.length <= 1) return false;
    setState(() {
      _path.removeLast();
      _entries = _load();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _path.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: FutureBuilder<List<RemoteEntry>>(
          future: _entries,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'No se pudo conectar',
                  message: '${snapshot.error}',
                  actionLabel: 'Reintentar',
                  onAction: () => setState(() => _entries = _load()),
                ),
              );
            }

            final entries = snapshot.data ?? const <RemoteEntry>[];
            if (entries.isEmpty) {
              return const EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'Carpeta vacía',
                message: 'No hay archivos ni carpetas aquí.',
              );
            }

            final playable = entries
                .where((entry) => !entry.isDirectory)
                .toList();

            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: Icon(
                    entry.isDirectory
                        ? Icons.folder_rounded
                        : Icons.music_note_rounded,
                  ),
                  title: Text(entry.name),
                  subtitle: entry.isDirectory || entry.sizeBytes == 0
                      ? null
                      : Text(
                          '${(entry.sizeBytes / 1048576).toStringAsFixed(1)} MB',
                        ),
                  onTap: () => entry.isDirectory
                      ? _enter(entry.uri)
                      : _play(entry, playable),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _play(RemoteEntry entry, List<RemoteEntry> siblings) async {
    final songs = await ref
        .read(engineProvider)
        .api
        .resolveRemoteSongs(
          widget.sourceId,
          siblings.map((item) => item.uri).toList(),
        );
    final index = siblings.indexWhere((item) => item.uri == entry.uri);
    await ref
        .read(playbackProvider.notifier)
        .playSongs(songs, startIndex: index < 0 ? 0 : index);
  }
}
