import 'dart:convert';

import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Una cancion dentro de un regalo. Viaja por (titulo, artista, album) y no
/// por id de MediaStore: los ids son locales a cada telefono, de modo que un
/// id del emisor no significaria nada en la biblioteca del receptor.
class GiftSong {
  const GiftSong({
    required this.title,
    required this.artist,
    this.album,
    this.sourceVideoId,
  });

  final String title;
  final String artist;
  final String? album;

  /// Fuente exacta que tenia el emisor, cuando se conoce.
  ///
  /// Es lo que evita que el receptor termine con un cover o una version en
  /// vivo: si viaja este id, se descarga ese video y no el primer resultado
  /// de una busqueda por texto. Cuando es nulo, el receptor elige entre
  /// candidatos en vez de que la aplicacion adivine por el.
  final String? sourceVideoId;

  /// Consulta con la que se buscan candidatos cuando no viajo [sourceVideoId].
  String get searchQuery => '$title $artist'.trim();

  /// Enlace directo a la fuente exacta, si el regalo la trae.
  String? get sourceUrl => sourceVideoId == null
      ? null
      : 'https://www.youtube.com/watch?v=$sourceVideoId';

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        if (album != null) 'album': album,
        if (sourceVideoId != null) 'sourceVideoId': sourceVideoId,
      };

  static GiftSong? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = (raw['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return null;
    final videoId = (raw['sourceVideoId'] as String?)?.trim();
    return GiftSong(
      title: title,
      artist: (raw['artist'] as String?)?.trim() ?? '',
      album: (raw['album'] as String?)?.trim(),
      sourceVideoId: (videoId == null || videoId.isEmpty) ? null : videoId,
    );
  }
}

/// Contenido de un archivo `.nuvtune-gift`.
///
/// El formato se mantiene igual al que ya generaba `playlist_actions.dart`
/// para no romper los regalos que el usuario ya haya compartido.
class GiftPayload {
  const GiftPayload({
    required this.name,
    required this.songs,
    this.dedication,
    this.from,
    this.to,
    this.accentId,
  });

  final String name;
  final List<GiftSong> songs;
  final String? dedication;
  final String? from;
  final String? to;
  final String? accentId;

  String encode() => jsonEncode({
        'name': name,
        'dedication': dedication,
        'from': from,
        'to': to,
        'accentId': accentId,
        'songs': [for (final song in songs) song.toJson()],
      });

  /// Lanza [FormatException] si el archivo no es un regalo valido. La
  /// validacion es deliberadamente defensiva: el archivo llega de otra
  /// aplicacion (WhatsApp, Drive, un gestor de archivos) y no hay ninguna
  /// garantia de que sea lo que dice ser.
  static GiftPayload decode(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const FormatException('El archivo no es un regalo válido');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo no es un regalo válido');
    }

    final songs = <GiftSong>[];
    for (final entry in (decoded['songs'] as List?) ?? const []) {
      final song = GiftSong.fromJson(entry);
      if (song != null) songs.add(song);
    }

    final name = (decoded['name'] as String?)?.trim();
    return GiftPayload(
      name: (name == null || name.isEmpty) ? 'Regalo' : name,
      songs: songs,
      dedication: (decoded['dedication'] as String?)?.trim(),
      from: (decoded['from'] as String?)?.trim(),
      to: (decoded['to'] as String?)?.trim(),
      accentId: decoded['accentId'] as String?,
    );
  }
}

/// Resultado de cruzar un regalo contra la biblioteca local.
class GiftMatch {
  const GiftMatch({required this.resolved, required this.missing});

  /// Id de MediaStore por cada cancion del regalo que ya existe localmente,
  /// en el orden original del regalo.
  final Map<int, int> resolved;

  /// Indices (dentro de `GiftPayload.songs`) de lo que hay que descargar.
  final List<int> missing;

  int get foundCount => resolved.length;
  bool get isComplete => missing.isEmpty;
}

/// Cruza las canciones de un regalo contra una biblioteca local.
///
/// El emparejamiento es por (titulo, artista) normalizados. Es
/// deliberadamente laxo con mayusculas y espacios, y deliberadamente estricto
/// en lo demas: preferimos descargar de mas a meter en la lista una cancion
/// que no era la que el emisor eligio.
GiftMatch matchGiftSongs(List<GiftSong> songs, List<Song> library) {
  final byKey = <String, int>{};
  for (final song in library) {
    byKey.putIfAbsent(_giftKey(song.title, song.artist), () => song.id);
  }

  final resolved = <int, int>{};
  final missing = <int>[];
  for (var index = 0; index < songs.length; index++) {
    final id = byKey[_giftKey(songs[index].title, songs[index].artist)];
    if (id == null) {
      missing.add(index);
    } else {
      resolved[index] = id;
    }
  }
  return GiftMatch(resolved: resolved, missing: missing);
}

String _giftKey(String title, String artist) =>
    '${title.trim().toLowerCase()}||${artist.trim().toLowerCase()}';
