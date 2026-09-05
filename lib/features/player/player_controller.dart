import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/data/repositories/equalizer_repository.dart';

/// Estado de reproduccion que consume la interfaz.
///
/// La posicion no va aqui: llega cada medio segundo y reconstruir la pantalla
/// completa a ese ritmo seria gastar trabajo para nada (requerimiento seccion
/// 17). Se expone aparte en [playbackPositionProvider].
class PlaybackState {
  const PlaybackState({
    required this.snapshot,
    required this.queue,
    required this.outputName,
    required this.output,
  });

  final PlaybackSnapshot snapshot;
  final List<Song> queue;
  final AudioOutput output;
  final String outputName;

  /// `-1` es el centinela de "sin pista", tanto en el motor como en la tabla
  /// `QueueState`. `elementAtOrNull` solo cubre el limite superior: con un
  /// indice negativo delega en `List.[]` y lanza `RangeError`.
  Song? get currentSong {
    final index = snapshot.currentIndex;
    return index < 0 ? null : queue.elementAtOrNull(index);
  }

  bool get hasQueue => queue.isNotEmpty;

  bool get isPlaying => snapshot.isPlaying;

  int get durationMs {
    final fromEngine = snapshot.durationMs;
    if (fromEngine > 0) return fromEngine;
    return currentSong?.durationMs ?? 0;
  }

  PlaybackState copyWith({
    PlaybackSnapshot? snapshot,
    List<Song>? queue,
    AudioOutput? output,
    String? outputName,
  }) => PlaybackState(
    snapshot: snapshot ?? this.snapshot,
    queue: queue ?? this.queue,
    output: output ?? this.output,
    outputName: outputName ?? this.outputName,
  );

  static PlaybackState initial() => PlaybackState(
    snapshot: PlaybackSnapshot(
      isPlaying: false,
      processingState: ProcessingState.idle,
      positionMs: 0,
      durationMs: 0,
      bufferedMs: 0,
      currentIndex: -1,
      shuffleEnabled: false,
      repeatMode: RepeatMode.off,
      speed: 1,
      pitch: 1,
    ),
    queue: const [],
    output: AudioOutput.speaker,
    outputName: 'Altavoz del teléfono',
  );
}

/// Posicion actual, emitida por separado para no reconstruir toda la pantalla.
final playbackPositionProvider = StreamProvider<PositionUpdate>(
  (ref) => ref.watch(engineProvider).position,
);

/// Energia y distribucion tonal de la senal actual. Solo recibe cuadros cuando
/// el reproductor completo solicita el analisis al motor.
final audioAnalysisProvider = StreamProvider<AudioAnalysisFrame>(
  (ref) => ref.watch(engineProvider).audioAnalysis,
);

final playbackProvider = NotifierProvider<PlaybackController, PlaybackState>(
  PlaybackController.new,
);

/// Orquesta la reproduccion: traduce las acciones de la interfaz en ordenes al
/// motor y guarda en la base de datos lo que debe sobrevivir al cierre.
class PlaybackController extends Notifier<PlaybackState> {
  final _subscriptions = <StreamSubscription<void>>[];

  /// Cancion cuya reproduccion ya se conto, para no inflar el historial cuando
  /// el usuario vuelve atras dentro de la misma pista.
  int? _countedSongId;

  /// Ultima posicion conocida. El estado general solo se actualiza cuando
  /// cambia algo, asi que la posicion en curso hay que seguirla aparte.
  int _lastPositionMs = 0;

  Timer? _positionPersistTimer;

  @override
  PlaybackState build() {
    final engine = ref.watch(engineProvider);
    _subscriptions.clear();

    _subscriptions.add(
      engine.position.listen((update) {
        _lastPositionMs = update.positionMs;
        _registerPlayIfNeeded(state.snapshot.currentSongId);
      }),
    );

    _subscriptions.add(
      engine.playbackState.listen((snapshot) {
        state = state.copyWith(snapshot: snapshot);
        _onSnapshot(snapshot);
      }),
    );

    _subscriptions.add(
      engine.queue.listen((update) {
        // Solo la lista. El indice es propiedad exclusiva del snapshot, y el
        // motor emite uno junto a cada cambio de cola precisamente para que
        // aqui no haga falta tocarlo.
        state = state.copyWith(queue: update.songs);
        unawaited(
          ref
              .read(queueRepositoryProvider)
              .saveQueue(
                update.songs.map((song) => song.id).toList(),
                state.snapshot.currentIndex,
              ),
        );
      }),
    );

    _subscriptions.add(
      engine.currentTrack.listen((change) {
        // El indice no se escribe aqui: su unica fuente es el snapshot. Este
        // flujo solo dispara los efectos que dependen de QUE cancion empezo, y
        // usa el id que trae el propio evento en vez de leerlo de `state`, que
        // depende de otro evento y podria no haber llegado todavia.
        _registerPlayIfNeeded(change.songId);
        _pushFavoriteStateToEngine(change.songId);
        // La ganancia de normalizacion es distinta en cada pista, de modo que
        // hay que republicarla en cada cambio (requerimiento 5.2).
        unawaited(pushEnhancement(songId: change.songId));
      }),
    );

    _subscriptions.add(
      engine.audioOutput.listen((change) {
        final changed = state.output != change.output;
        state = state.copyWith(
          output: change.output,
          outputName: change.deviceName,
        );
        // Cambiar de salida carga el perfil guardado para ella
        // (requerimiento 5.4). Solo al cambiar de tipo: reconectar los mismos
        // auriculares no debe reescribir nada.
        if (changed) {
          unawaited(_applyOutputProfile(change.output));
        }
      }),
    );

    _subscriptions.add(
      engine.metadataUpdates.listen((song) {
        ref.read(libraryRepositoryProvider).applyUpdatedSong(song);
        state = state.copyWith(
          queue: [
            for (final existing in state.queue)
              if (existing.id == song.id) song else existing,
          ],
        );
      }),
    );

    // El boton de favorito de la notificacion, la pantalla de bloqueo y Android
    // Auto llegan por aqui: el motor no conoce los favoritos.
    _subscriptions.add(
      engine.favoriteToggleRequests.listen((songId) async {
        final isFavorite = await ref
            .read(favoritesRepositoryProvider)
            .toggle(songId);
        engine.api.setFavoriteState(songId, isFavorite);
      }),
    );

    // La posicion se guarda cada pocos segundos, no en cada emision, para no
    // castigar la base de datos (requerimiento seccion 17).
    _positionPersistTimer = Timer.periodic(_positionPersistInterval, (_) {
      final index = state.snapshot.currentIndex;
      if (index < 0) return;
      unawaited(
        ref.read(queueRepositoryProvider).savePosition(index, _lastPositionMs),
      );
    });

    ref.onDispose(() {
      _positionPersistTimer?.cancel();
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });

    return PlaybackState.initial();
  }

  void _onSnapshot(PlaybackSnapshot snapshot) {
    unawaited(
      ref
          .read(queueRepositoryProvider)
          .saveModes(
            repeatModeIndex: snapshot.repeatMode.index,
            shuffleEnabled: snapshot.shuffleEnabled,
          ),
    );
    _registerPlayIfNeeded(snapshot.currentSongId);
  }

  /// Una cancion cuenta como reproducida cuando ha sonado la mitad, o un minuto
  /// en las pistas largas. Ese umbral evita contar los saltos rapidos.
  void _registerPlayIfNeeded(int? songId) {
    if (songId == null) {
      _countedSongId = null;
      return;
    }
    if (_countedSongId == songId) return;

    final duration = state.durationMs;
    if (duration <= 0) return;

    final half = duration ~/ 2;
    final threshold = half < _minimumPlayMs ? half : _minimumPlayMs;
    if (_lastPositionMs < threshold) return;

    _countedSongId = songId;
    unawaited(ref.read(historyRepositoryProvider).registerPlay(songId));
  }

  void _pushFavoriteStateToEngine(int? songId) {
    if (songId == null) return;
    unawaited(() async {
      final isFavorite = await ref
          .read(favoritesRepositoryProvider)
          .isFavorite(songId);
      ref.read(engineProvider).api.setFavoriteState(songId, isFavorite);
    }());
  }

  // -- Acciones -----------------------------------------------------------

  MusicEngineHostApi get _api => ref.read(engineProvider).api;

  /// Carga una lista de canciones como cola nueva y empieza a reproducir.
  Future<void> playSongs(
    List<Song> songs, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    if (songs.isEmpty) return;
    final playable = songs.where((song) => song.isSupported).toList();
    if (playable.isEmpty) return;

    // El aleatorio solo reordena los "siguiente"/"anterior" a partir de la
    // pista con la que arranca; `setQueue` la fija con una orden directa de
    // busqueda, ajena al orden aleatorio. Si aqui siempre se pidiera el
    // indice 0 (el valor por omision cuando quien llama no elige una
    // cancion concreta), "reproducir aleatoriamente" empezaria siempre por
    // la primera de la lista ordenada, cancion tras cancion.
    final index = shuffle
        ? Random().nextInt(playable.length)
        : startIndex.clamp(0, playable.length - 1);
    _countedSongId = null;
    _api.setShuffle(shuffle);
    _api.setQueue(playable, index, 0, true);
  }

  Future<void> playSong(Song song, {List<Song>? within}) async {
    final source = within ?? [song];
    final index = source.indexWhere((item) => item.id == song.id);
    await playSongs(source, startIndex: index < 0 ? 0 : index);
  }

  /// Restaura la cola guardada sin empezar a reproducir (requerimiento 4.3).
  Future<void> restoreSavedQueue() async {
    final saved = await ref.read(queueRepositoryProvider).load();
    if (saved.isEmpty) return;

    final songs = ref.read(libraryRepositoryProvider).songsByIds(saved.songIds);
    if (songs.isEmpty) return;

    final index = saved.currentIndex.clamp(0, songs.length - 1);
    _api.setShuffle(saved.shuffleEnabled);
    _api.setRepeatMode(
      RepeatMode.values.elementAtOrNull(saved.repeatModeIndex) ??
          RepeatMode.off,
    );
    _api.setQueue(songs, index, saved.positionMs, false);
  }

  void play() => _api.play();

  void pause() => _api.pause();

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seek(int positionMs) => _api.seek(positionMs);

  void seekRelative(int deltaMs) => _api.seekRelative(deltaMs);

  void skipNext() => _api.skipNext();

  void skipPrevious() => _api.skipPrevious();

  void toggleShuffle() => _api.setShuffle(!state.snapshot.shuffleEnabled);

  /// Recorre los tres modos: sin repetir, repetir lista, repetir cancion.
  void cycleRepeatMode() {
    final next = switch (state.snapshot.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    _api.setRepeatMode(next);
  }

  void setSpeed(double speed) => _api.setPlaybackSpeed(speed);

  void setPitch(double pitch) => _api.setPitch(pitch);

  void setAudioAnalysisEnabled(bool enabled) =>
      _api.setAudioAnalysisEnabled(enabled);

  // -- Cola ---------------------------------------------------------------

  void playNext(List<Song> songs) =>
      _api.addToQueueNext(songs.where((song) => song.isSupported).toList());

  void addToQueue(List<Song> songs) =>
      _api.addToQueueEnd(songs.where((song) => song.isSupported).toList());

  void removeFromQueue(int index) => _api.removeQueueItem(index);

  /// Quita todas las apariciones de una cancion de la cola. Se recorre desde
  /// el final para que cada eliminacion conserve validos los indices que aun
  /// faltan. Si es la pista activa, Media3 libera el elemento y avanza a la
  /// siguiente (o se detiene cuando era la unica).
  Future<void> removeSongById(int songId) async {
    final indices = <int>[
      for (var index = 0; index < state.queue.length; index++)
        if (state.queue[index].id == songId) index,
    ];
    for (final index in indices.reversed) {
      await _api.removeQueueItem(index);
    }
  }

  void moveInQueue(int fromIndex, int toIndex) =>
      _api.moveQueueItem(fromIndex, toIndex);

  Future<void> clearQueue() async {
    _api.clearQueue();
    await ref.read(queueRepositoryProvider).clear();
  }

  void playQueueIndex(int index) => _api.playQueueIndex(index);

  // -- Temporizador -------------------------------------------------------

  void startSleepTimer(Duration duration, {required bool finishCurrentTrack}) =>
      _api.setSleepTimer(duration.inMilliseconds, finishCurrentTrack);

  void cancelSleepTimer() => _api.cancelSleepTimer();

  // -- Favoritos ----------------------------------------------------------

  Future<void> toggleFavorite(int songId) async {
    final isFavorite = await ref
        .read(favoritesRepositoryProvider)
        .toggle(songId);
    _api.setFavoriteState(songId, isFavorite);
  }

  // -- Ajustes de audio ---------------------------------------------------

  /// Vuelca al motor el ecualizador y las opciones de calidad guardadas. Se
  /// llama al arrancar y cada vez que el usuario cambia algo.
  Future<void> pushAudioSettings() async {
    final equalizer = await ref
        .read(equalizerRepositoryProvider)
        .engineSettings();
    _api.setEqualizer(equalizer);

    final settings = await ref.read(settingsRepositoryProvider).settings();
    _api.setPlaybackOptions(
      PlaybackOptions(
        gaplessEnabled: settings.gaplessEnabled,
        crossfadeSeconds: settings.crossfadeSeconds,
        fadeOnPause: settings.fadeOnPause,
        fadeOnPauseMs: settings.fadeOnPauseMs,
        directMode: settings.directMode,
        allowOffload: settings.allowOffload,
      ),
    );
    _api.setPlaybackSpeed(settings.playbackSpeed);
    _api.setPitch(settings.playbackPitch);

    await pushEnhancement();
  }

  /// Publica la cadena de mejora, incluyendo la ganancia analizada de la pista
  /// actual (requerimiento 5.2).
  ///
  /// [songId] permite pasar el id ya conocido por el evento que dispara la
  /// llamada en vez de releerlo de [state]: el motor manda el cambio de pista
  /// y el snapshot de reproduccion por dos canales Pigeon separados, sin
  /// garantia de orden de llegada entre ellos, asi que `state.snapshot` puede
  /// no estar actualizado todavia cuando esta funcion se dispara desde el
  /// cambio de pista.
  Future<void> pushEnhancement({int? songId}) async {
    final repository = ref.read(enhancementRepositoryProvider);
    final resolvedSongId = songId ?? state.snapshot.currentSongId;
    final analysis = resolvedSongId == null
        ? null
        : await repository.analysisFor(resolvedSongId);
    _api.setEnhancement(
      await repository.engineSettings(trackGainDb: analysis?.gainDb ?? 0),
    );
  }

  /// Carga el perfil guardado para la salida activa (requerimiento 5.4).
  ///
  /// Si esa salida no tiene perfil guardado no se toca nada: cambiar de
  /// auriculares a altavoz no puede borrar la curva que el usuario acaba de
  /// ajustar.
  Future<void> _applyOutputProfile(AudioOutput output) async {
    final repository = ref.read(enhancementRepositoryProvider);
    final profile = await repository.profileFor(output);
    if (profile == null) return;

    await ref
        .read(equalizerRepositoryProvider)
        .save(
          bandCount: profile.bandCount,
          gains: EqualizerRepository.decodeGains(
            profile.gainsJson,
            profile.bandCount,
          ),
          presetName: profile.presetName,
          preampDb: profile.preampDb,
        );
    await repository.save(
      enabled: profile.enhancementEnabled,
      profile: EnhancementProfile.values[profile.profileIndex],
    );
    await pushAudioSettings();
  }

  static const _minimumPlayMs = 60000;
  static const _positionPersistInterval = Duration(seconds: 5);
}

/// Ganancias del ecualizador tal como las espera el motor, para las pantallas
/// que necesitan leerlas sin pasar por el repositorio.
List<double> equalizerGainsOf(EqualizerStateData state) =>
    EqualizerRepository.decodeGains(state.gainsJson, state.bandCount);
