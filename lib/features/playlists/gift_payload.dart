import 'dart:convert';
import 'dart:math';

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
    if (title.length > GiftPayload.maxSongFieldLength) return null;
    final artist = (raw['artist'] as String?)?.trim() ?? '';
    final album = (raw['album'] as String?)?.trim();
    if (artist.length > GiftPayload.maxSongFieldLength ||
        (album?.length ?? 0) > GiftPayload.maxSongFieldLength) {
      return null;
    }
    final videoId = (raw['sourceVideoId'] as String?)?.trim();
    if (videoId != null &&
        videoId.isNotEmpty &&
        !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId)) {
      return null;
    }
    return GiftSong(
      title: title,
      artist: artist,
      album: album,
      sourceVideoId: (videoId == null || videoId.isEmpty) ? null : videoId,
    );
  }
}

enum GiftSignatureStatus {
  signedNew('signed_new'),
  signedKnown('signed_known'),
  signedChanged('signed_changed'),
  legacyUnsigned('legacy_unsigned');

  const GiftSignatureStatus(this.id);

  final String id;

  static GiftSignatureStatus byId(Object? id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => GiftSignatureStatus.legacyUnsigned,
  );
}

class GiftSecurityInfo {
  const GiftSecurityInfo({
    required this.signatureStatus,
    this.fingerprint,
    this.formatVersion = 1,
  });

  final GiftSignatureStatus signatureStatus;
  final String? fingerprint;
  final int formatVersion;

  bool get isSigned => signatureStatus != GiftSignatureStatus.legacyUnsigned;
  bool get isKnown => signatureStatus == GiftSignatureStatus.signedKnown;

  static const legacy = GiftSecurityInfo(
    signatureStatus: GiftSignatureStatus.legacyUnsigned,
  );

  static GiftSecurityInfo fromJson(Object? raw) {
    if (raw is! Map) return legacy;
    final fingerprint = raw['fingerprint'];
    return GiftSecurityInfo(
      signatureStatus: GiftSignatureStatus.byId(raw['status']),
      fingerprint: fingerprint is String && fingerprint.length <= 40
          ? fingerprint
          : null,
      formatVersion: raw['formatVersion'] is int
          ? (raw['formatVersion'] as int).clamp(1, 100).toInt()
          : 1,
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
    this.giftId,
    this.createdAt,
    this.dedication,
    this.from,
    this.to,
    this.accentId,
    this.security = GiftSecurityInfo.legacy,
  });

  factory GiftPayload.create({
    required String name,
    required List<GiftSong> songs,
    String? dedication,
    String? from,
    String? to,
    String? accentId,
  }) {
    final random = Random.secure();
    final identifier = base64Url
        .encode(List<int>.generate(16, (_) => random.nextInt(256)))
        .replaceAll('=', '');
    return GiftPayload(
      name: name,
      songs: songs,
      giftId: identifier,
      createdAt: DateTime.now().toUtc(),
      dedication: dedication,
      from: from,
      to: to,
      accentId: accentId,
    );
  }

  final String name;
  final List<GiftSong> songs;
  final String? giftId;
  final DateTime? createdAt;
  final String? dedication;
  final String? from;
  final String? to;
  final String? accentId;
  final GiftSecurityInfo security;

  static const maxSongs = 500;
  static const maxMetadataLength = 256 * 1024;
  static const maxSongFieldLength = 300;

  String encode() => jsonEncode({
    'formatVersion': 2,
    if (giftId != null) 'giftId': giftId,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
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
    if (content.length > maxMetadataLength) {
      throw const FormatException('El regalo contiene demasiados metadatos');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const FormatException('El archivo no es un regalo válido');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo no es un regalo válido');
    }

    final rawSongs = decoded['songs'];
    if (rawSongs is! List || rawSongs.isEmpty || rawSongs.length > maxSongs) {
      throw const FormatException(
        'El regalo debe contener una lista válida de canciones',
      );
    }
    final songs = <GiftSong>[];
    for (final entry in rawSongs) {
      final song = GiftSong.fromJson(entry);
      if (song == null) {
        throw const FormatException(
          'El regalo contiene una canción con datos inválidos',
        );
      }
      songs.add(song);
    }

    final name = _boundedString(decoded, 'name', 120);
    final giftId = _boundedString(decoded, 'giftId', 64);
    if (giftId != null && !RegExp(r'^[A-Za-z0-9_-]{16,64}$').hasMatch(giftId)) {
      throw const FormatException('El identificador del regalo no es válido');
    }
    final createdAtText = _boundedString(decoded, 'createdAt', 64);
    final createdAt = createdAtText == null
        ? null
        : DateTime.tryParse(createdAtText)?.toUtc();
    if (createdAtText != null && createdAt == null) {
      throw const FormatException('La fecha del regalo no es válida');
    }
    return GiftPayload(
      name: (name == null || name.isEmpty) ? 'Regalo' : name,
      songs: songs,
      giftId: giftId,
      createdAt: createdAt,
      dedication: _boundedString(decoded, 'dedication', 2000),
      from: _boundedString(decoded, 'from', 80),
      to: _boundedString(decoded, 'to', 80),
      accentId: _boundedString(decoded, 'accentId', 40),
      security: GiftSecurityInfo.fromJson(decoded['_nuvtuneSecurity']),
    );
  }

  static String? _boundedString(
    Map<String, dynamic> source,
    String key,
    int maximumLength,
  ) {
    final raw = source[key];
    if (raw == null) return null;
    if (raw is! String) {
      throw FormatException('El campo $key del regalo no es válido');
    }
    final value = raw.trim();
    if (value.length > maximumLength) {
      throw FormatException('El campo $key del regalo es demasiado largo');
    }
    return value.isEmpty ? null : value;
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
