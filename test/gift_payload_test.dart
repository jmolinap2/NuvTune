import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/playlists/gift_payload.dart';

Song _song({required int id, required String title, required String artist}) =>
    Song(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      filePath: '/music/$id.mp3',
      title: title,
      artist: artist,
      artistId: id,
      album: 'Album',
      albumId: id,
      durationMs: 1000,
      mimeType: 'audio/mpeg',
      sizeBytes: 1,
      dateAdded: 0,
      dateModified: 0,
      folderPath: '/music',
      folderName: 'music',
      hasCover: false,
      isSupported: true,
    );

void main() {
  group('GiftPayload', () {
    test('codificar y decodificar conserva dedicatoria y canciones', () {
      const original = GiftPayload(
        name: 'Pa mailov',
        dedication: 'Para ti',
        from: 'Ale',
        to: 'Mai',
        accentId: 'nebula',
        songs: [
          GiftSong(title: 'Aquí', artist: 'Allison', album: 'Memoria'),
          GiftSong(title: 'Amor Quédate', artist: 'Jencarlos'),
        ],
      );

      final restored = GiftPayload.decode(original.encode());

      expect(restored.name, 'Pa mailov');
      expect(restored.dedication, 'Para ti');
      expect(restored.from, 'Ale');
      expect(restored.to, 'Mai');
      expect(restored.accentId, 'nebula');
      expect(restored.songs, hasLength(2));
      expect(restored.songs.first.title, 'Aquí');
      expect(restored.songs.first.album, 'Memoria');
    });

    test('un archivo que no es JSON se rechaza como regalo invalido', () {
      expect(
        () => GiftPayload.decode('esto no es un regalo'),
        throwsA(isA<FormatException>()),
      );
    });

    test('un JSON que no es un objeto se rechaza', () {
      expect(
        () => GiftPayload.decode('[1, 2, 3]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('las entradas sin titulo se descartan en vez de romper el regalo', () {
      final payload = GiftPayload.decode(
        '{"name":"R","songs":[{"artist":"X"},{"title":"Vale","artist":"Y"}]}',
      );

      expect(payload.songs, hasLength(1));
      expect(payload.songs.single.title, 'Vale');
    });

    test('un regalo sin nombre recibe uno por defecto', () {
      final payload = GiftPayload.decode('{"songs":[]}');
      expect(payload.name, 'Regalo');
    });
  });

  group('matchGiftSongs', () {
    final library = [
      _song(id: 10, title: 'Aquí', artist: 'Allison'),
      _song(id: 20, title: 'Otra', artist: 'Alguien'),
    ];

    test('empareja ignorando mayusculas y espacios sobrantes', () {
      final match = matchGiftSongs(
        const [GiftSong(title: '  aquí ', artist: 'ALLISON')],
        library,
      );

      expect(match.resolved[0], 10);
      expect(match.missing, isEmpty);
      expect(match.isComplete, isTrue);
    });

    test('lo que no esta en la biblioteca se reporta como faltante', () {
      final match = matchGiftSongs(
        const [
          GiftSong(title: 'Aquí', artist: 'Allison'),
          GiftSong(title: 'Desconocida', artist: 'Nadie'),
        ],
        library,
      );

      expect(match.foundCount, 1);
      expect(match.missing, [1]);
      expect(match.isComplete, isFalse);
    });

    test('mismo titulo con otro artista no se empareja', () {
      // Preferimos descargar de mas antes que meter en el regalo una cancion
      // que el emisor no eligio.
      final match = matchGiftSongs(
        const [GiftSong(title: 'Aquí', artist: 'Otro Artista')],
        library,
      );

      expect(match.missing, [0]);
    });

    test('la consulta de busqueda combina titulo y artista', () {
      const song = GiftSong(title: 'Aquí', artist: 'Allison');
      expect(song.searchQuery, 'Aquí Allison');
    });
  });
}
