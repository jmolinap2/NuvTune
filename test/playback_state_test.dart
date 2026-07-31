import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/player/player_controller.dart';

Song song(int id) => Song(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      filePath: '/music/$id.mp3',
      title: 'Pista $id',
      artist: 'Artista',
      artistId: 1,
      album: 'Album',
      albumId: 1,
      albumArtist: 'Artista',
      genre: 'Rock',
      year: 2024,
      trackNumber: id,
      discNumber: 1,
      durationMs: 200000,
      mimeType: 'audio/mpeg',
      sizeBytes: 1000,
      dateAdded: 0,
      dateModified: 0,
      folderPath: '/music',
      folderName: 'music',
      hasCover: false,
      isSupported: true,
    );

PlaybackState stateWith({required List<Song> queue, required int index}) {
  final initial = PlaybackState.initial();
  return initial.copyWith(
    queue: queue,
    snapshot: PlaybackSnapshot(
      isPlaying: false,
      processingState: ProcessingState.idle,
      positionMs: 0,
      durationMs: 0,
      bufferedMs: 0,
      currentIndex: index,
      shuffleEnabled: false,
      repeatMode: RepeatMode.off,
      speed: 1,
      pitch: 1,
    ),
  );
}

void main() {
  group('PlaybackState.currentSong', () {
    // Regresion: el indice -1 llegaba a List.[] y lanzaba RangeError, lo que
    // rompia el build de Inicio y dejaba la aplicacion en gris.
    test('devuelve null con el centinela -1 y la cola vacia', () {
      expect(PlaybackState.initial().currentSong, isNull);
    });

    test('devuelve null con el centinela -1 y una cola cargada', () {
      final state = stateWith(queue: [song(1), song(2)], index: -1);
      expect(state.currentSong, isNull);
    });

    // La cola y el snapshot llegan por eventos distintos, de modo que existe
    // una ventana real en la que el indice apunta fuera de la cola nueva.
    test('devuelve null si el indice quedo fuera de la cola', () {
      final state = stateWith(queue: [song(1)], index: 5);
      expect(state.currentSong, isNull);
    });

    test('devuelve la pista apuntada por el indice', () {
      final state = stateWith(queue: [song(1), song(2), song(3)], index: 1);
      expect(state.currentSong?.id, 2);
    });
  });

  group('PlaybackState.durationMs', () {
    test('cae en la duracion de la pista cuando el motor no la reporta', () {
      final state = stateWith(queue: [song(7)], index: 0);
      expect(state.durationMs, 200000);
    });

    test('vale cero sin pista actual', () {
      expect(PlaybackState.initial().durationMs, 0);
    });
  });
}
