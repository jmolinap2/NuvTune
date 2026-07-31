import 'dart:async';

import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Puente entre Flutter y el motor Android.
///
/// Envuelve el contrato generado por Pigeon en dos direcciones: expone el
/// HostApi tal cual para las ordenes, y convierte los eventos que llegan del
/// motor en flujos que la capa de estado puede escuchar sin acoplarse al
/// contrato generado.
class EngineBridge implements MusicEngineFlutterApi {
  EngineBridge({MusicEngineHostApi? hostApi})
      : api = hostApi ?? MusicEngineHostApi();

  final MusicEngineHostApi api;

  final _playbackState = StreamController<PlaybackSnapshot>.broadcast();
  final _currentTrack = StreamController<TrackChange>.broadcast();
  final _position = StreamController<PositionUpdate>.broadcast();
  final _queue = StreamController<QueueUpdate>.broadcast();
  final _audioOutput = StreamController<AudioOutputChange>.broadcast();
  final _library = StreamController<int>.broadcast();
  final _metadata = StreamController<Song>.broadcast();
  final _sleepTimerFinished = StreamController<void>.broadcast();
  final _favoriteToggleRequested = StreamController<int>.broadcast();
  final _errors = StreamController<EngineError>.broadcast();

  Stream<PlaybackSnapshot> get playbackState => _playbackState.stream;
  Stream<TrackChange> get currentTrack => _currentTrack.stream;
  Stream<PositionUpdate> get position => _position.stream;
  Stream<QueueUpdate> get queue => _queue.stream;
  Stream<AudioOutputChange> get audioOutput => _audioOutput.stream;
  Stream<int> get libraryChanges => _library.stream;
  Stream<Song> get metadataUpdates => _metadata.stream;
  Stream<void> get sleepTimerFinishedEvents => _sleepTimerFinished.stream;
  Stream<int> get favoriteToggleRequests => _favoriteToggleRequested.stream;
  Stream<EngineError> get errors => _errors.stream;

  bool _initialized = false;

  /// Conecta con el servicio de reproduccion y empieza a recibir eventos.
  Future<void> initialize() async {
    if (_initialized) return;
    MusicEngineFlutterApi.setUp(this);
    await api.initialize();
    _initialized = true;
  }

  Future<void> dispose() async {
    MusicEngineFlutterApi.setUp(null);
    await _playbackState.close();
    await _currentTrack.close();
    await _position.close();
    await _queue.close();
    await _audioOutput.close();
    await _library.close();
    await _metadata.close();
    await _sleepTimerFinished.close();
    await _favoriteToggleRequested.close();
    await _errors.close();
  }

  // -- Eventos del motor ---------------------------------------------------

  @override
  void playbackStateChanged(PlaybackSnapshot snapshot) =>
      _playbackState.add(snapshot);

  @override
  void currentTrackChanged(int index, int? songId) =>
      _currentTrack.add(TrackChange(index: index, songId: songId));

  @override
  void positionChanged(int positionMs, int durationMs, int bufferedMs) =>
      _position.add(
        PositionUpdate(
          positionMs: positionMs,
          durationMs: durationMs,
          bufferedMs: bufferedMs,
        ),
      );

  @override
  void queueChanged(List<Song> queue, int currentIndex) =>
      _queue.add(QueueUpdate(songs: queue, currentIndex: currentIndex));

  @override
  void audioDeviceChanged(AudioOutput output, String deviceName) =>
      _audioOutput.add(
        AudioOutputChange(output: output, deviceName: deviceName),
      );

  @override
  void libraryChanged(int songCount) => _library.add(songCount);

  @override
  void metadataUpdated(Song song) => _metadata.add(song);

  @override
  void sleepTimerFinished() => _sleepTimerFinished.add(null);

  @override
  void favoriteToggleRequested(int songId) =>
      _favoriteToggleRequested.add(songId);

  @override
  void errorOccurred(String code, String message) =>
      _errors.add(EngineError(code: code, message: message));
}

class TrackChange {
  const TrackChange({required this.index, required this.songId});

  final int index;
  final int? songId;
}

class PositionUpdate {
  const PositionUpdate({
    required this.positionMs,
    required this.durationMs,
    required this.bufferedMs,
  });

  final int positionMs;
  final int durationMs;
  final int bufferedMs;
}

class QueueUpdate {
  const QueueUpdate({required this.songs, required this.currentIndex});

  final List<Song> songs;
  final int currentIndex;
}

class AudioOutputChange {
  const AudioOutputChange({required this.output, required this.deviceName});

  final AudioOutput output;
  final String deviceName;
}

class EngineError {
  const EngineError({required this.code, required this.message});

  final String code;
  final String message;
}

/// Datos derivados de [Song] que la interfaz necesita a menudo.
extension SongPresentation on Song {
  /// MediaStore no deja vacios los campos que faltan: escribe la cadena
  /// literal `<unknown>`. Mostrarla tal cual delata la fuente de los datos, de
  /// modo que se trata igual que un campo vacio.
  static const _unknownFromMediaStore = '<unknown>';

  static bool _isMissing(String? value) =>
      value == null || value.isEmpty || value == _unknownFromMediaStore;

  String get displayArtist =>
      _isMissing(artist) ? 'Artista desconocido' : artist;

  String get displayAlbum => _isMissing(album) ? 'Álbum desconocido' : album;

  String get displayAlbumArtist =>
      _isMissing(albumArtist) ? displayArtist : albumArtist!;

  /// Genero y compositor se listan como agrupaciones: sin valor real no deben
  /// generar un grupo propio llamado `<unknown>`.
  String? get displayGenre => _isMissing(genre) ? null : genre;

  String? get displayComposer => _isMissing(composer) ? null : composer;

  DateTime get addedAt => DateTime.fromMillisecondsSinceEpoch(dateAdded * 1000);

  DateTime get modifiedAt =>
      DateTime.fromMillisecondsSinceEpoch(dateModified * 1000);

  /// Formatos sin perdida, usados por la lista inteligente de calidad FLAC y
  /// por la recomendacion del modo directo (requerimiento 5.5).
  bool get isLossless {
    final mime = mimeType.toLowerCase();
    return mime.contains('flac') ||
        mime.contains('wav') ||
        mime.contains('aiff') ||
        mime.contains('alac');
  }

  bool get hasIdentifiedArtist =>
      !_isMissing(artist) && artist != 'Artista desconocido';
}
