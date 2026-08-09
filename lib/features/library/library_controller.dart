import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/repositories/library_repository.dart';

class LibraryState {
  const LibraryState({required this.songs, required this.isScanning});

  final List<Song> songs;
  final bool isScanning;

  bool get isEmpty => songs.isEmpty;

  LibraryState copyWith({List<Song>? songs, bool? isScanning}) => LibraryState(
    songs: songs ?? this.songs,
    isScanning: isScanning ?? this.isScanning,
  );

  static const empty = LibraryState(songs: [], isScanning: false);
}

final libraryProvider = NotifierProvider<LibraryController, LibraryState>(
  LibraryController.new,
);

/// Mantiene la biblioteca visible y coordina los escaneos.
class LibraryController extends Notifier<LibraryState> {
  StreamSubscription<int>? _libraryChanges;
  Timer? _rescanDebounce;
  bool _rescanPending = false;
  bool _forcePending = false;

  @override
  LibraryState build() {
    // El motor avisa cuando MediaStore cambia por algo externo a la aplicacion,
    // por ejemplo al copiar musica nueva por USB. Hay que volver a consultar
    // MediaStore, no solo releer el cache del motor.
    //
    // El aviso llega tambien por los cambios que provoca la propia aplicacion
    // al reescribir etiquetas, y puede repetirse varias veces por operacion, de
    // modo que se agrupa antes de lanzar un escaneo.
    _libraryChanges = ref.watch(engineProvider).libraryChanges.listen((_) {
      _rescanDebounce?.cancel();
      _rescanDebounce = Timer(_rescanDelay, () => unawaited(scan()));
    });

    ref.onDispose(() {
      _rescanDebounce?.cancel();
      _libraryChanges?.cancel();
    });
    return LibraryState.empty;
  }

  LibraryRepository get _repository => ref.read(libraryRepositoryProvider);

  /// Escaneo completo. [force] descarta la deteccion de portadas ya resuelta.
  Future<void> scan({bool force = false}) async {
    // MediaStore puede emitir varios avisos por una sola operacion. Nunca se
    // ejecutan dos consultas en paralelo: si llega otro cambio durante un
    // escaneo, se conserva como maximo una repeticion para cuando este acabe.
    if (state.isScanning) {
      _rescanPending = true;
      _forcePending = _forcePending || force;
      return;
    }

    state = state.copyWith(isScanning: true);
    try {
      final excluded = await ref
          .read(settingsRepositoryProvider)
          .excludedFolders();
      await _repository.scan(excludedFolders: excluded, forceFullRescan: force);
      state = LibraryState(songs: _repository.songs, isScanning: false);
      await _pruneOrphans();
      await ref.read(settingsRepositoryProvider).markScanned();
    } finally {
      if (state.isScanning) {
        state = state.copyWith(isScanning: false);
      }
      if (_rescanPending) {
        final pendingForce = _forcePending;
        _rescanPending = false;
        _forcePending = false;
        unawaited(scan(force: pendingForce));
      }
    }
  }

  /// Relee la lista del motor sin volver a recorrer MediaStore.
  Future<void> refresh() async {
    await _repository.refresh();
    state = state.copyWith(songs: _repository.songs);
    await _pruneOrphans();
  }

  /// Excluye una carpeta y vuelve a escanear (requerimiento 4.1).
  Future<void> excludeFolder(String path) async {
    await ref.read(settingsRepositoryProvider).excludeFolder(path);
    await scan();
  }

  Future<void> includeFolder(String path) async {
    await ref.read(settingsRepositoryProvider).includeFolder(path);
    await scan();
  }

  /// Las listas, los favoritos y el historial pueden apuntar a canciones que ya
  /// no existen; se limpian tras cada escaneo para que no aparezcan huecos.
  Future<void> _pruneOrphans() async {
    final existing = state.songs.map((song) => song.id).toSet();
    await ref.read(playlistRepositoryProvider).pruneMissingSongs(existing);
    await ref.read(historyRepositoryProvider).pruneMissingSongs(existing);
  }

  /// Margen para agrupar los avisos seguidos de MediaStore.
  static const _rescanDelay = Duration(seconds: 3);
}
