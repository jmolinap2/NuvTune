import 'dart:async';

import 'package:nuvtune/core/platform/download_engine.g.dart';

/// Puente con el motor de descarga nativo (busqueda + descarga de audio),
/// heredado de C:\Repos\NuvClip. Mismo patron que [EngineBridge]
/// (`core/platform/engine_bridge.dart`): expone el HostApi tal cual para las
/// ordenes, y convierte los eventos push de Kotlin en streams.
class DownloadEngineBridge implements DownloadEngineFlutterApi {
  DownloadEngineBridge({DownloadEngineHostApi? hostApi})
    : api = hostApi ?? DownloadEngineHostApi();

  final DownloadEngineHostApi api;

  final _progress = StreamController<DownloadProgressEvent>.broadcast();
  final _completed = StreamController<DownloadCompletedEvent>.broadcast();
  final _failed = StreamController<DownloadFailedEvent>.broadcast();

  Stream<DownloadProgressEvent> get progress => _progress.stream;
  Stream<DownloadCompletedEvent> get completed => _completed.stream;
  Stream<DownloadFailedEvent> get failed => _failed.stream;

  Future<void>? _initializing;

  /// Extrae los binarios de yt-dlp/ffmpeg la primera vez (costoso); se llama
  /// una sola vez por proceso, sin bloquear el arranque de la aplicacion.
  ///
  /// Memoiza el `Future` en curso, no solo un booleano: `bootstrap.dart` la
  /// llama sin esperar, y si `search()`/`download()` llaman a esto de nuevo
  /// mientras esa primera llamada sigue en vuelo, tienen que esperar la
  /// misma inicializacion real, no encontrar un flag ya en `true` y seguir
  /// de largo antes de que el motor este listo.
  Future<void> initialize() => _initializing ??= _doInitialize();

  Future<void> _doInitialize() async {
    DownloadEngineFlutterApi.setUp(this);
    await api.initialize();
  }

  Future<void> dispose() async {
    DownloadEngineFlutterApi.setUp(null);
    await _progress.close();
    await _completed.close();
    await _failed.close();
  }

  @override
  void onDownloadProgress(
    String downloadId,
    double percent,
    int? etaSeconds,
    int downloadedBytes,
    int? totalBytes,
  ) => _progress.add(
    DownloadProgressEvent(
      downloadId: downloadId,
      percent: percent,
      etaSeconds: etaSeconds,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
    ),
  );

  @override
  void onDownloadCompleted(
    String downloadId,
    String savedUri,
    String fileName,
    int sizeBytes,
  ) => _completed.add(
    DownloadCompletedEvent(
      downloadId: downloadId,
      savedUri: savedUri,
      fileName: fileName,
      sizeBytes: sizeBytes,
    ),
  );

  @override
  void onDownloadFailed(
    String downloadId,
    DownloadErrorCode errorCode,
    String? errorDetail,
  ) => _failed.add(
    DownloadFailedEvent(
      downloadId: downloadId,
      errorCode: errorCode,
      errorDetail: errorDetail,
    ),
  );
}

class DownloadProgressEvent {
  const DownloadProgressEvent({
    required this.downloadId,
    required this.percent,
    required this.etaSeconds,
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final String downloadId;
  final double percent;
  final int? etaSeconds;
  final int downloadedBytes;
  final int? totalBytes;
}

class DownloadCompletedEvent {
  const DownloadCompletedEvent({
    required this.downloadId,
    required this.savedUri,
    required this.fileName,
    required this.sizeBytes,
  });

  final String downloadId;
  final String savedUri;
  final String fileName;
  final int sizeBytes;
}

class DownloadFailedEvent {
  const DownloadFailedEvent({
    required this.downloadId,
    required this.errorCode,
    required this.errorDetail,
  });

  final String downloadId;
  final DownloadErrorCode errorCode;
  final String? errorDetail;
}

/// Mensajes en espanol para cada [DownloadErrorCode] (requerimiento: Kotlin
/// solo clasifica, Dart redacta el texto que ve el usuario).
extension DownloadErrorCodeMessage on DownloadErrorCode {
  String get userMessage => switch (this) {
    DownloadErrorCode.unsupportedLink =>
      'Ese enlace no es de un sitio compatible.',
    DownloadErrorCode.privateContent =>
      'El contenido es privado o requiere iniciar sesión.',
    DownloadErrorCode.contentRemoved => 'El contenido ya no está disponible.',
    DownloadErrorCode.regionRestricted =>
      'El contenido no está disponible en tu región.',
    DownloadErrorCode.fetchFailed =>
      'No se pudo obtener el contenido. Inténtalo de nuevo.',
    DownloadErrorCode.extractorOutdated =>
      'La plataforma cambió y la actualización automática no pudo resolverlo. Inténtalo más tarde.',
    DownloadErrorCode.insufficientStorage =>
      'No hay espacio suficiente en el dispositivo.',
    DownloadErrorCode.cancelled => 'Descarga cancelada.',
    DownloadErrorCode.networkLost => 'Se perdió la conexión a internet.',
    DownloadErrorCode.wifiRequired =>
      'Activa el Wi-Fi o desactiva "Solo con Wi-Fi" en Ajustes.',
    DownloadErrorCode.unknown => 'No se pudo completar la descarga.',
  };
}
