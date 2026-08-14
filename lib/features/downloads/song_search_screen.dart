import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/download_engine.g.dart';
import 'package:nuvtune/core/platform/download_engine_bridge.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/downloads/download_details_sheet.dart';
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

  /// URL cuya vista previa está sonando y otra separada mientras se prepara.
  String? _previewUrl;
  String? _preparingPreviewUrl;

  StreamSubscription<DownloadCompletedEvent>? _completedSub;
  StreamSubscription<DownloadFailedEvent>? _failedSub;

  // Se lee una sola vez y se guarda: `dispose()` lo necesita para parar la
  // vista previa, y para entonces `ref` ya no es utilizable (el widget esta
  // desmontandose). El motor vive fuera del widget, asi que sigue siendo
  // valido en ese momento.
  late final DownloadEngineBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(downloadEngineProvider);
    final bridge = _bridge;
    _completedSub = bridge.completed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Descargada: ${event.fileName}'),
          action: SnackBarAction(label: 'Ver', onPressed: _openDownloadsFolder),
        ),
      );
    });
    _failedSub = bridge.failed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(event.errorCode.userMessage)));
    });
  }

  @override
  void dispose() {
    // La vista previa vive en un reproductor nativo aparte: si no se para
    // aqui, seguiria sonando despues de salir de esta pantalla.
    _bridge.api.stopPreview();
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
        const SnackBar(
          content: Text(
            'No se pudo buscar. Revisa tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePreview(SearchResultItem result) async {
    final api = ref.read(downloadEngineProvider).api;

    if (_preparingPreviewUrl == result.sourceUrl) return;
    if (_previewUrl == result.sourceUrl) {
      await api.stopPreview();
      if (mounted) setState(() => _previewUrl = null);
      return;
    }

    if (_previewUrl != null) await api.stopPreview();
    setState(() {
      _previewUrl = null;
      _preparingPreviewUrl = result.sourceUrl;
    });
    try {
      // Resolver la URL del stream tarda unos segundos; el estado de carga
      // evita que parezca que el boton no hizo nada. El método nativo ahora
      // retorna solo cuando Media3 confirma que el audio está listo.
      await api.startPreview(result.sourceUrl);
      if (mounted) setState(() => _previewUrl = result.sourceUrl);
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reproducir la vista previa.')),
      );
    } finally {
      if (mounted) setState(() => _preparingPreviewUrl = null);
    }
  }

  Future<void> _openDetails(SearchResultItem result) async {
    await ref.read(downloadEngineProvider).api.stopPreview();
    if (mounted) {
      setState(() {
        _previewUrl = null;
        _preparingPreviewUrl = null;
      });
    }
    if (!mounted) return;
    final choice = await showDownloadDetails(context, result);
    if (choice == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await ref
        .read(downloadsControllerProvider.notifier)
        .download(
          result,
          analysis: choice.analysis,
          selectedFormat: choice.format,
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Descarga iniciada. Puedes seguir usando NuvTune.',
        ),
      ),
    );
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

  Future<void> _openYoutubeLogin() async {
    final result = await context.push<bool>('/downloads/youtube-login');
    if (result == true) {
      ref.invalidate(youtubeLoginProvider);
    }
  }

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión de YouTube'),
        content: const Text(
          'Las próximas búsquedas de YouTube volverán a comportarse como '
          'si no hubieras iniciado sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(downloadEngineProvider).api.clearYouTubeLogin();
    if (!mounted) return;
    navigator.maybePop();
    ref.invalidate(youtubeLoginProvider);
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadsControllerProvider);
    final loggedIntoYoutube = ref.watch(youtubeLoginProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descargar música'),
        actions: [
          IconButton(
            tooltip: loggedIntoYoutube
                ? 'Sesión de YouTube activa'
                : 'Iniciar sesión de YouTube',
            icon: Icon(
              loggedIntoYoutube
                  ? Icons.account_circle_rounded
                  : Icons.account_circle_outlined,
              color: loggedIntoYoutube
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: loggedIntoYoutube ? _confirmLogout : _openYoutubeLogin,
          ),
          IconButton(
            tooltip: 'Ver mis descargas',
            icon: const Icon(Icons.library_music_rounded),
            onPressed: _openDownloadsFolder,
          ),
        ],
      ),
      body: Column(
        children: [
          const _DownloadHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space2,
              Tokens.gutter,
              Tokens.space2,
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Artista o canción',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: _loading ? null : _search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Tokens.radiusPill),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (downloads.isNotEmpty)
            _ActiveDownloads(
              tasks: downloads.values.toList(growable: false),
              onCancel: (sourceUrl) => ref
                  .read(downloadsControllerProvider.notifier)
                  .cancel(sourceUrl),
            ),
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
                    padding: const EdgeInsets.fromLTRB(
                      Tokens.gutter,
                      Tokens.space2,
                      Tokens.gutter,
                      Tokens.space5,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return _SearchResultTile(
                        result: result,
                        downloadTask: downloads[result.sourceUrl],
                        isPreviewing: _previewUrl == result.sourceUrl,
                        isPreparingPreview:
                            _preparingPreviewUrl == result.sourceUrl,
                        onPreview: () => _togglePreview(result),
                        onDetails: () => _openDetails(result),
                        onDownload: () => _openDetails(result),
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
    required this.downloadTask,
    required this.isPreviewing,
    required this.isPreparingPreview,
    required this.onPreview,
    required this.onDetails,
    required this.onDownload,
  });

  final SearchResultItem result;
  final DownloadTask? downloadTask;
  final bool isPreviewing;
  final bool isPreparingPreview;
  final VoidCallback onPreview;
  final VoidCallback onDetails;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = result.durationSeconds > 0
        ? Formatters.duration(result.durationSeconds * 1000)
        : null;
    final author = result.author ?? 'Autor desconocido';

    return Card(
      margin: const EdgeInsets.only(bottom: Tokens.space3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space3),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(url: result.thumbnailUrl, size: 72),
                  const SizedBox(width: Tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _PlatformBadge(platform: result.platform),
                            const SizedBox(width: Tokens.space2),
                            Expanded(
                              child: Text(
                                result.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Tokens.space1),
                        Text(
                          duration == null ? author : '$author · $duration',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.space2),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Ver formato, portada y calidad',
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: isPreviewing
                        ? 'Detener vista previa'
                        : 'Escuchar antes de descargar',
                    onPressed: onPreview,
                    icon: isPreparingPreview
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isPreviewing
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                          ),
                  ),
                  const SizedBox(width: Tokens.space2),
                  if (downloadTask == null)
                    FilledButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded, size: 19),
                      label: const Text('Descargar'),
                    )
                  else
                    SizedBox.square(
                      dimension: 42,
                      child: CircularProgressIndicator(
                        value: downloadTask!.percent / 100,
                        strokeWidth: 4,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Insignia de origen: YouTube tiene mejor catálogo pero puede pedir sesión
/// iniciada; SoundCloud nunca la pide, a cambio de un catálogo más volcado a
/// subidas de usuarios y covers que a la pista oficial.
class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.platform});

  final SourcePlatform platform;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (platform) {
      SourcePlatform.youtube => ('YouTube', Colors.red),
      SourcePlatform.soundcloud => ('SoundCloud', Colors.deepOrange),
      SourcePlatform.tiktok => ('TikTok', Colors.black),
      SourcePlatform.instagram => ('Instagram', Colors.purple),
      SourcePlatform.facebook => ('Facebook', Colors.blue),
      SourcePlatform.unknown => ('Desconocido', scheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusPill),
        color: color.withValues(alpha: 0.16),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DownloadHero extends StatelessWidget {
  const _DownloadHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space2,
        Tokens.gutter,
        Tokens.space2,
      ),
      padding: const EdgeInsets.fromLTRB(
        Tokens.space4,
        Tokens.space3,
        Tokens.space2,
        Tokens.space3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.72),
            scheme.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escucha antes de guardar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Tokens.space1),
                Text(
                  'Auris te muestra portada, formato, calidad y tamaño antes de descargar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Tokens.space2),
          Image.asset(
            'assets/images/auris.png',
            width: 76,
            height: 76,
            fit: BoxFit.contain,
            semanticLabel: 'Auris, mascota de NuvTune',
          ),
        ],
      ),
    );
  }
}

class _ActiveDownloads extends StatelessWidget {
  const _ActiveDownloads({required this.tasks, required this.onCancel});

  final List<DownloadTask> tasks;
  final ValueChanged<String> onCancel;

  @override
  Widget build(BuildContext context) {
    final task = tasks.first;
    final scheme = Theme.of(context).colorScheme;
    final downloaded = task.downloadedBytes > 0
        ? Formatters.fileSize(task.downloadedBytes)
        : null;
    final total = task.totalBytes == null
        ? null
        : Formatters.fileSize(task.totalBytes!);
    final detail = [
      '${task.percent}%',
      if (downloaded != null && total != null) '$downloaded de $total',
      if (task.etaSeconds case final eta?) 'faltan ${_etaLabel(eta)}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space2,
        Tokens.gutter,
        Tokens.space1,
      ),
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.downloading_rounded, color: scheme.primary),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: Text(
                  tasks.length == 1
                      ? 'Descargando ahora'
                      : 'Descargando ahora · ${tasks.length} en cola',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cancelar descarga',
                onPressed: () => onCancel(task.sourceUrl),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Tokens.space2),
          LinearProgressIndicator(value: task.percent / 100),
          const SizedBox(height: Tokens.space1),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _etaLabel(int seconds) {
    if (seconds < 60) return '$seconds s';
    return '${(seconds / 60).ceil()} min';
  }
}

/// Miniatura del resultado. Es la unica imagen de red de la aplicacion, de
/// modo que el fallo se resuelve aqui mismo: sin conexion (o si YouTube
/// cambia la URL) se cae al icono generico en vez de dejar un hueco.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, this.size = 56});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: const Icon(Icons.music_note_rounded),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.radiusSmall),
      child: SizedBox(
        width: size,
        height: size,
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
