import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/download_engine.g.dart';
import 'package:nuvtune/core/platform/download_engine_bridge.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/library/library_controller.dart';

/// Progreso (0-100) de las descargas en curso, por `sourceUrl` del resultado
/// de busqueda. La descarga en si corre en el servicio nativo en primer
/// plano (motor heredado de C:\Repos\NuvClip): esto solo refleja los eventos
/// de progreso que llegan por [DownloadEngineBridge].
///
/// No hay una lista propia de "canciones descargadas": el motor las escribe
/// directamente en MediaStore.Audio, asi que aparecen solas en la biblioteca
/// normal en cuanto el escaneo incremental (ya disparado por el observador de
/// MediaStore) las recoge.
final downloadsControllerProvider =
    NotifierProvider<DownloadsController, Map<String, DownloadTask>>(
      DownloadsController.new,
    );

class DownloadTask {
  const DownloadTask({
    required this.downloadId,
    required this.sourceUrl,
    required this.title,
    required this.author,
    this.percent = 0,
    this.downloadedBytes = 0,
    this.totalBytes,
    this.etaSeconds,
  });

  final String downloadId;
  final String sourceUrl;
  final String title;
  final String? author;
  final int percent;
  final int downloadedBytes;
  final int? totalBytes;
  final int? etaSeconds;

  DownloadTask copyWith({
    int? percent,
    int? downloadedBytes,
    int? totalBytes,
    int? etaSeconds,
  }) => DownloadTask(
    downloadId: downloadId,
    sourceUrl: sourceUrl,
    title: title,
    author: author,
    percent: percent ?? this.percent,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    etaSeconds: etaSeconds ?? this.etaSeconds,
  );
}

class DownloadsController extends Notifier<Map<String, DownloadTask>> {
  final _urlByDownloadId = <String, String>{};

  @override
  Map<String, DownloadTask> build() {
    final bridge = ref.watch(downloadEngineProvider);
    final progressSub = bridge.progress.listen((event) {
      final url = _urlByDownloadId[event.downloadId];
      if (url == null || !state.containsKey(url)) return;
      final current = state[url]!;
      state = {
        ...state,
        url: current.copyWith(
          percent: event.percent.round().clamp(0, 100),
          downloadedBytes: event.downloadedBytes,
          totalBytes: event.totalBytes,
          etaSeconds: event.etaSeconds,
        ),
      };
    });
    final completedSub = bridge.completed.listen((event) {
      _clear(event.downloadId);
      // No se depende solo del observador de MediaStore: al terminar, la
      // canción debe aparecer enseguida aunque el fabricante retrase ese
      // evento o la pantalla de descargas ya no esté visible.
      unawaited(ref.read(libraryProvider.notifier).scan());
    });
    final failedSub = bridge.failed.listen((event) => _clear(event.downloadId));
    ref.onDispose(() {
      progressSub.cancel();
      completedSub.cancel();
      failedSub.cancel();
    });
    return const {};
  }

  bool isDownloading(String sourceUrl) => state.containsKey(sourceUrl);

  /// Busca el resultado elegido, analiza su enlace real y encola la
  /// descarga de audio. Devuelve un mensaje de error si algo no dejo
  /// encolar la descarga; `null` significa que quedo en curso (el resultado
  /// final llega por los streams de [DownloadEngineBridge]).
  Future<String?> download(
    SearchResultItem result, {
    VideoAnalysis? analysis,
    VideoFormatOption? selectedFormat,
  }) async {
    if (isDownloading(result.sourceUrl)) return null;

    try {
      final engine = ref.read(downloadEngineProvider);
      await engine.initialize();
      final resolved = analysis == null
          ? await engine.api.analyzeUrl(result.sourceUrl)
          : null;
      final video = analysis ?? resolved?.video;
      if (video == null) {
        return resolved?.errorCode?.userMessage ??
            'No se pudo analizar la canción.';
      }
      if (video.audioFormats.isEmpty) {
        return 'No hay audio disponible para descargar.';
      }

      // Primera opcion = mejor bitrate (YtDlpEngine.toAudioFormatOptions las
      // entrega ordenadas 192/128/64 kbps).
      final format = selectedFormat ?? video.audioFormats.first;
      if (!video.audioFormats.any((item) => item.formatId == format.formatId)) {
        return 'La calidad seleccionada ya no está disponible.';
      }
      final downloadId = DateTime.now().microsecondsSinceEpoch.toString();
      _urlByDownloadId[downloadId] = result.sourceUrl;
      state = {
        ...state,
        result.sourceUrl: DownloadTask(
          downloadId: downloadId,
          sourceUrl: result.sourceUrl,
          title: result.title,
          author: result.author,
          totalBytes: format.approxSizeBytes,
        ),
      };

      await engine.api.startDownload(
        DownloadRequest(
          downloadId: downloadId,
          sourceUrl: result.sourceUrl,
          platform: video.platform,
          formatId: format.formatId,
          suggestedFileName: _fileNameFor(result.title),
          wifiOnly: false,
          audioOnly: true,
          approxTotalBytes: format.approxSizeBytes,
          songTitle: result.title,
          songArtist: result.author,
        ),
      );
      return null;
    } catch (_) {
      return 'No se pudo iniciar la descarga.';
    } finally {
      // El caso exitoso lo limpia _onCompleted/_onFailed via el downloadId;
      // esto solo cubre las salidas tempranas (arriba) que nunca llegaron a
      // registrar uno.
      if (!_urlByDownloadId.containsValue(result.sourceUrl)) {
        _clearByUrl(result.sourceUrl);
      }
    }
  }

  Future<void> cancel(String sourceUrl) async {
    final task = state[sourceUrl];
    if (task == null) return;
    await ref.read(downloadEngineProvider).api.cancelDownload(task.downloadId);
    _urlByDownloadId.remove(task.downloadId);
    _clearByUrl(sourceUrl);
  }

  void _clear(String downloadId) {
    final url = _urlByDownloadId.remove(downloadId);
    if (url != null) _clearByUrl(url);
  }

  void _clearByUrl(String sourceUrl) {
    if (!state.containsKey(sourceUrl)) return;
    final next = {...state}..remove(sourceUrl);
    state = next;
  }

  static String _fileNameFor(String title) {
    final safe = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return '${safe.isEmpty ? 'cancion' : safe}.mp3';
  }
}
