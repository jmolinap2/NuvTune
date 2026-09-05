import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lo que MusicBrainz devuelve para una cancion: solo los campos que NuvTune
/// puede rellenar (requerimiento "completar metadata con internet"). El
/// artista viene siempre que hay coincidencia; genero y compositor son mas
/// escasos en la base de datos y pueden faltar aunque haya coincidencia.
class MusicBrainzMatch {
  const MusicBrainzMatch({
    required this.matchedTitle,
    required this.matchedArtist,
    required this.score,
    this.genre,
    this.composer,
    this.releaseId,
  });

  final String matchedTitle;
  final String matchedArtist;

  /// 0-100, tal como lo reporta el buscador de MusicBrainz para esta
  /// coincidencia. Sirve para que la pantalla marque como dudosas las
  /// coincidencias bajas en vez de aplicarlas a ciegas.
  final int score;
  final String? genre;
  final String? composer;

  /// MBID del primer lanzamiento (release) asociado a la grabacion, si
  /// alguno. Es lo que Cover Art Archive necesita para buscar la portada; no
  /// implica que ese lanzamiento tenga una portada subida.
  final String? releaseId;
}

/// Cliente minimo de la API publica de MusicBrainz
/// (https://musicbrainz.org/doc/MusicBrainz_API). No requiere API key, pero
/// exige como maximo una peticion por segundo por IP anonima; esta instancia
/// respeta ese limite para toda la sesion de busqueda, sea cual sea la
/// cancion que la origino.
///
/// No reintenta ante fallos ni cae a un valor por defecto: una peticion que
/// falla o no encuentra nada devuelve `null`, y quien la use debe mostrarlo
/// como "sin coincidencia" para esa cancion, no ocultarlo.
class MusicBrainzClient {
  MusicBrainzClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _base = 'https://musicbrainz.org/ws/2';
  static const _timeout = Duration(seconds: 10);

  /// MusicBrainz pide un identificador de aplicacion descriptivo en vez del
  /// user-agent generico del cliente HTTP, para poder distinguir clientes
  /// que abusan del servicio.
  static const _userAgent = 'NuvTune/1.0 (reproductor de musica personal)';

  /// MusicBrainz limita a ~1 peticion por segundo a los clientes anonimos.
  static const _minInterval = Duration(milliseconds: 1100);

  DateTime? _lastRequestAt;

  /// Busca la cancion por titulo (y artista, si ya se conoce) y devuelve la
  /// mejor coincidencia con los datos que se pudieron completar. `null` si no
  /// hubo ninguna coincidencia o la peticion fallo.
  Future<MusicBrainzMatch?> lookup({required String title, String? artist}) async {
    final candidate = await _searchRecording(title: title, artist: artist);
    if (candidate == null) return null;
    return _detailsOf(candidate);
  }

  Future<({String id, String title, String artist, int score, String? releaseId})?>
  _searchRecording({required String title, String? artist}) async {
    final query = artist == null || artist.isEmpty
        ? 'recording:"${_escape(title)}"'
        : 'recording:"${_escape(title)}" AND artist:"${_escape(artist)}"';
    final uri = Uri.parse('$_base/recording').replace(
      queryParameters: {'query': query, 'fmt': 'json', 'limit': '3'},
    );

    final body = await _get(uri);
    if (body == null) return null;
    final recordings = body['recordings'];
    if (recordings is! List || recordings.isEmpty) return null;
    final best = recordings.first;
    if (best is! Map) return null;
    final id = best['id'];
    if (id is! String) return null;

    return (
      id: id,
      title: best['title'] as String? ?? title,
      artist: _artistNameOf(best),
      score: (best['score'] as num?)?.toInt() ?? 0,
      releaseId: _releaseIdOf(best),
    );
  }

  String? _releaseIdOf(Map recording) {
    final releases = recording['releases'];
    if (releases is! List || releases.isEmpty) return null;
    final first = releases.first;
    return first is Map ? first['id'] as String? : null;
  }

  Future<MusicBrainzMatch> _detailsOf(
    ({String id, String title, String artist, int score, String? releaseId})
    candidate,
  ) async {
    final uri = Uri.parse('$_base/recording/${candidate.id}').replace(
      queryParameters: {
        'fmt': 'json',
        'inc': 'genres+tags+artist-rels+work-rels+artist-credits',
      },
    );
    final body = await _get(uri);
    if (body == null) {
      return MusicBrainzMatch(
        matchedTitle: candidate.title,
        matchedArtist: candidate.artist,
        score: candidate.score,
        releaseId: candidate.releaseId,
      );
    }

    return MusicBrainzMatch(
      matchedTitle: candidate.title,
      matchedArtist: candidate.artist,
      score: candidate.score,
      genre: _bestGenre(body),
      composer: await _composerOf(body),
      releaseId: candidate.releaseId,
    );
  }

  String? _bestGenre(Map<String, dynamic> recordingBody) {
    final genres = _sortedByCount(recordingBody['genres']);
    if (genres.isNotEmpty) return genres.first['name'] as String?;

    final tags = _sortedByCount(recordingBody['tags']);
    if (tags.isNotEmpty) return tags.first['name'] as String?;
    return null;
  }

  List<Map> _sortedByCount(Object? raw) {
    final items = (raw is List ? raw : const []).whereType<Map>().toList();
    items.sort(
      (a, b) =>
          ((b['count'] as num?) ?? 0).compareTo((a['count'] as num?) ?? 0),
    );
    return items;
  }

  /// El compositor es una relacion de artista, casi siempre sobre la "obra"
  /// (work) de la grabacion en vez de sobre la grabacion misma: por eso, si no
  /// hay una relacion directa, hace falta una segunda consulta a la obra
  /// enlazada. Es habitual que no exista ninguna de las dos (la mayoria de la
  /// musica no clasica no modela compositor en MusicBrainz), y en ese caso el
  /// campo queda sin dato en vez de inventarse algo.
  Future<String?> _composerOf(Map<String, dynamic> recordingBody) async {
    final relations = (recordingBody['relations'] as List? ?? const [])
        .whereType<Map>();

    for (final relation in relations) {
      if (relation['type'] == 'composer' && relation['artist'] is Map) {
        return (relation['artist'] as Map)['name'] as String?;
      }
    }

    Map? work;
    for (final relation in relations) {
      if (relation['target-type'] == 'work' && relation['work'] is Map) {
        work = relation['work'] as Map;
        break;
      }
    }
    final workId = work?['id'];
    if (workId is! String) return null;

    final uri = Uri.parse('$_base/work/$workId').replace(
      queryParameters: {'fmt': 'json', 'inc': 'artist-rels'},
    );
    final workBody = await _get(uri);
    if (workBody == null) return null;

    final workRelations = (workBody['relations'] as List? ?? const [])
        .whereType<Map>();
    for (final relation in workRelations) {
      if (relation['type'] == 'composer' && relation['artist'] is Map) {
        return (relation['artist'] as Map)['name'] as String?;
      }
    }
    return null;
  }

  String _artistNameOf(Map recording) {
    final credits = recording['artist-credit'];
    if (credits is! List || credits.isEmpty) return '';
    return credits
        .whereType<Map>()
        .map((credit) => credit['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  Future<Map<String, dynamic>?> _get(Uri uri) async {
    await _waitForRateLimit();
    try {
      final response = await _http
          .get(uri, headers: const {
            'User-Agent': _userAgent,
            'Accept': 'application/json',
          })
          .timeout(_timeout);
      final decoded = response.statusCode == 200
          ? jsonDecode(response.body)
          : null;
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    } finally {
      _lastRequestAt = DateTime.now();
    }
  }

  Future<void> _waitForRateLimit() async {
    final last = _lastRequestAt;
    if (last == null) return;
    final remaining = _minInterval - DateTime.now().difference(last);
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  static String _escape(String value) =>
      value.replaceAll('\\', r'\\').replaceAll('"', r'\"');

  void dispose() => _http.close();
}
