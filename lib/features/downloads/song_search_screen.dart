import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/download_engine.g.dart';
import 'package:nuvtune/core/platform/download_engine_bridge.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/downloads/downloads_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Carpeta donde `MediaStoreWriter.saveAudio` deja las descargas. Se usa para
/// llevar al usuario a verlas: quedan mezcladas con el resto de la biblioteca
/// (son canciones normales de MediaStore), y esta carpeta es lo unico que las
/// distingue.
const String kDownloadsFolderName = 'NuvTune descargas';

/// Buscador de canciones para descargar (motor heredado de
/// C:\Repos\NuvClip: yt-dlp + ffmpeg nativos).
///
/// La descarga esta en zona gris de los TOS de estas plataformas: por eso el
/// aviso fijo debajo del buscador.
class SongSearchScreen extends ConsumerStatefulWidget {
  const SongSearchScreen({super.key});

  @override
  ConsumerState<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends ConsumerState<SongSearchScreen> {
  final _controller = TextEditingController();
  List<SearchResultItem> _results = const [];
  bool _loading = false;
  bool _searched = false;

  /// URL cuya vista previa esta sonando (o cargando, ver [_preparingPreview]).
  String? _previewUrl;
  bool _preparingPreview = false;

  StreamSubscription<DownloadCompletedEvent>? _completedSub;
  StreamSubscription<DownloadFailedEvent>? _failedSub;

  @override
  void initState() {
    super.initState();
    final bridge = ref.read(downloadEngineProvider);
    _completedSub = bridge.completed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Descargada: ${event.fileName}'),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: _openDownloadsFolder,
          ),
        ),
      );
    });
    _failedSub = bridge.failed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.errorCode.userMessage)),
      );
    });
  }

  @override
  void dispose() {
    // La vista previa vive en un reproductor nativo aparte: si no se para
    // aqui, seguiria sonando despues de salir de esta pantalla.
    ref.read(downloadEngineProvider).api.stopPreview();
    _controller.dispose();
    _completedSub?.cancel();
    _failedSub?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    try {
      final engine = ref.read(downloadEngineProvider);
      // La primera vez, el motor todavia puede estar extrayendo sus
      // binarios (arranque no bloqueante desde bootstrap.dart); esperar
      // aqui evita buscar antes de que este listo.
      await engine.initialize();
      final results = await engine.api.search(query, 12);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo buscar. Revisa tu conexión e inténtalo de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePreview(SearchResultItem result) async {
    final api = ref.read(downloadEngineProvider).api;

    if (_previewUrl == result.sourceUrl) {
      await api.stopPreview();
      if (mounted) setState(() => _previewUrl = null);
      return;
    }

    setState(() {
      _previewUrl = result.sourceUrl;
      _preparingPreview = true;
    });
    try {
      // Resolver la URL del stream tarda unos segundos; el estado de carga
      // evita que parezca que el boton no hizo nada.
      await api.startPreview(result.sourceUrl);
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reproducir la vista previa.')),
      );
    } finally {
      if (mounted) setState(() => _preparingPreview = false);
    }
  }

  Future<void> _download(SearchResultItem result) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(downloadsControllerProvider.notifier).download(result);
    if (!mounted || error == null) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  /// Lleva a la carpeta donde caen las descargas. No se navega por una ruta
  /// fija porque la ruta absoluta depende del almacenamiento del dispositivo:
  /// se busca la carpeta ya escaneada por su nombre.
  void _openDownloadsFolder() {
    final folder = ref
        .read(libraryRepositoryProvider)
        .folders()
        .where((group) => group.title == kDownloadsFolderName)
        .firstOrNull;

    if (folder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todavía no hay descargas. Aparecerán en Biblioteca, '
            'en la carpeta "$kDownloadsFolderName".',
          ),
        ),
      );
      return;
    }
    context.push('/folder?path=${Uri.encodeQueryComponent(folder.key)}');
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(downloadsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar canciones'),
        actions: [
          IconButton(
            tooltip: 'Ver mis descargas',
            icon: const Icon(Icons.library_music_rounded),
            onPressed: _openDownloadsFolder,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space4,
              Tokens.gutter,
              Tokens.space2,
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Artista o canción',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Tokens.radiusPill),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Text(
              'Toca ▶ para escuchar antes de descargar. Úsalo solo para '
              'contenido de dominio público o de uso personal permitido en tu '
              'jurisdicción.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: Tokens.space2),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: !_searched
                ? const EmptyState(
                    icon: Icons.music_note_outlined,
                    title: 'Busca una canción',
                    message: 'Escribe un artista o título y pulsa buscar.',
                  )
                : _results.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        message: 'Prueba con otro término de búsqueda.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: Tokens.space5),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return _SearchResultTile(
                            result: result,
                            downloadPercent: progress[result.sourceUrl],
                            isPreviewing: _previewUrl == result.sourceUrl,
                            isPreparingPreview: _preparingPreview &&
                                _previewUrl == result.sourceUrl,
                            onPreview: () => _togglePreview(result),
                            onDownload: () => _download(result),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.downloadPercent,
    required this.isPreviewing,
    required this.isPreparingPreview,
    required this.onPreview,
    required this.onDownload,
  });

  final SearchResultItem result;
  final int? downloadPercent;
  final bool isPreviewing;
  final bool isPreparingPreview;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = result.durationSeconds > 0
        ? Formatters.duration(result.durationSeconds * 1000)
        : null;
    final author = result.author ?? 'Autor desconocido';

    return ListTile(
      leading: _Thumbnail(url: result.thumbnailUrl),
      title: Text(
        result.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        duration == null ? author : '$author · $duration',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: isPreviewing ? 'Detener vista previa' : 'Escuchar antes de descargar',
            onPressed: onPreview,
            icon: isPreparingPreview
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isPreviewing
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_outline_rounded,
                    color: isPreviewing ? scheme.primary : null,
                  ),
          ),
          if (downloadPercent != null)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: downloadPercent! / 100,
                strokeWidth: 3,
              ),
            )
          else
            IconButton(
              tooltip: 'Descargar',
              icon: const Icon(Icons.download_rounded),
              onPressed: onDownload,
            ),
        ],
      ),
    );
  }
}

/// Miniatura del resultado. Es la unica imagen de red de la aplicacion, de
/// modo que el fallo se resuelve aqui mismo: sin conexion (o si YouTube
/// cambia la URL) se cae al icono generico en vez de dejar un hueco.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: const Icon(Icons.music_note_rounded),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.radiusSmall),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => placeholder,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
              ),
      ),
    );
  }
}
