import 'dart:convert';

import 'package:http/http.dart' as http;

/// Un resultado de busqueda de Piped (feature "video de fondo en Wi-Fi" y
/// "buscar y descargar canciones").
class PipedSearchResult {
  const PipedSearchResult({
    required this.videoId,
    required this.title,
    required this.uploaderName,
    required this.durationSeconds,
    this.description = '',
    this.uploaderVerified = false,
    this.isMusicCategory = false,
    this.views = 0,
    this.searchRank = 0,
  });

  final String videoId;
  final String title;
  final String uploaderName;
  final int durationSeconds;
  final String description;
  final bool uploaderVerified;
  final bool isMusicCategory;
  final int views;
  final int searchRank;
}

class PipedAudioStream {
  const PipedAudioStream({
    required this.url,
    required this.mimeType,
    required this.bitrate,
    required this.codec,
  });

  final String url;
  final String mimeType;
  final int bitrate;
  final String? codec;
}

class PipedStreams {
  const PipedStreams({required this.audioStreams, required this.thumbnailUrl});

  final List<PipedAudioStream> audioStreams;
  final String? thumbnailUrl;

  /// El de mayor bitrate, que es el que conviene descargar.
  PipedAudioStream? get bestAudio {
    if (audioStreams.isEmpty) return null;
    final sorted = [...audioStreams]
      ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return sorted.first;
  }
}

/// Cliente de la API publica de Piped (https://github.com/TeamPiped/Piped),
/// que no exige contrato ni API key. No lanza excepciones: las instancias de
/// Piped caen seguido (429/500), asi que cada metodo devuelve `null` o una
/// lista vacia en vez de propagar el error, y prueba varias instancias antes
/// de rendirse.
class PipedClient {
  PipedClient({http.Client? httpClient, List<String>? instances})
    : _http = httpClient ?? http.Client(),
      _instances = instances ?? _defaultInstances;

  final http.Client _http;
  final List<String> _instances;

  static const _defaultInstances = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.yt',
    'https://piped-api.lunar.icu',
  ];

  static const _timeout = Duration(seconds: 8);
  static const _youtubeTimeout = Duration(seconds: 10);
  static const _youtubeResultsUrl = 'https://www.youtube.com/results';

  static final _youtubeVideoIdPattern = RegExp(
    r'"videoId"\s*:\s*"([A-Za-z0-9_-]{11})"',
  );

  /// Resuelve el video que se usa como fondo del reproductor.
  ///
  /// Esta busqueda es deliberadamente independiente de Piped: sus instancias
  /// publicas suelen estar saturadas o fuera de linea y esperar sus tres
  /// timeouts haria que el fondo aparezca demasiado tarde. La pagina publica
  /// de resultados de YouTube no requiere una API key; si tampoco responde,
  /// Piped queda como ultimo respaldo. [searchMany] y [streamsOf] siguen
  /// usando exclusivamente Piped para el buscador y las descargas.
  Future<String?> searchMusicVideo(String query) async {
    final candidates = await searchMusicVideoCandidates(query, limit: 1);
    return candidates.isEmpty ? null : candidates.first.videoId;
  }

  /// Devuelve varios candidatos ordenados para poder recuperarse cuando el
  /// primer resultado no permite reproducción embebida o ya no está disponible.
  Future<List<String>> searchMusicVideos(String query, {int limit = 5}) async {
    final candidates = await searchMusicVideoCandidates(query, limit: limit);
    return candidates
        .map((candidate) => candidate.videoId)
        .toList(growable: false);
  }

  /// Candidatos completos para `MusicVideoMatcher`. La consulta se mantiene
  /// como `artista cancion`: anadir "official" sesgaria los resultados sin
  /// demostrar que el canal o el contenido sean oficiales.
  Future<List<PipedSearchResult>> searchMusicVideoCandidates(
    String query, {
    int limit = 12,
  }) async {
    if (limit <= 0) return const [];
    final directResults = await _searchYouTube(query);
    if (directResults.isNotEmpty) {
      return directResults.take(limit).toList(growable: false);
    }

    final fallback = await searchMany(query);
    return fallback.take(limit).toList(growable: false);
  }

  /// Primer resultado de musica para `artista titulo`, o `null` si ninguna
  /// instancia respondio o no hubo resultados.
  Future<String?> search(String query) async {
    final results = await searchMany(query);
    return results.isEmpty ? null : results.first.videoId;
  }

  /// Todos los resultados de musica para `query` (buscador de descargas).
  Future<List<PipedSearchResult>> searchMany(String query) async {
    return _searchMany(query, filter: 'music_songs', isMusicCategory: true);
  }

  Future<List<PipedSearchResult>> _searchMany(
    String query, {
    required String filter,
    required bool isMusicCategory,
  }) async {
    for (final instance in _instances) {
      final uri = Uri.parse(
        '$instance/search',
      ).replace(queryParameters: {'q': query, 'filter': filter});
      try {
        final response = await _http.get(uri).timeout(_timeout);
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(response.body);
        final items = decoded is Map ? decoded['items'] : null;
        if (items is! List) continue;
        final results = <PipedSearchResult>[];
        for (final item in items.whereType<Map>()) {
          final parsed = _parseSearchResult(
            item,
            searchRank: results.length,
            isMusicCategory: isMusicCategory,
          );
          if (parsed != null) results.add(parsed);
        }
        return results;
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  Future<List<PipedSearchResult>> _searchYouTube(String query) async {
    final uri = Uri.parse(_youtubeResultsUrl).replace(
      queryParameters: {'search_query': query, 'hl': 'en', 'persist_hl': '1'},
    );

    try {
      final response = await _http
          .get(
            uri,
            headers: const {
              'Accept-Language': 'en-US,en;q=0.9',
              'Cookie': 'CONSENT=YES+cb.20210328-17-p0.en+FX+410',
              'Referer': 'https://www.youtube.com/',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36',
            },
          )
          .timeout(_youtubeTimeout);
      if (response.statusCode != 200) return const [];

      final parsed = _parseYouTubeInitialData(response.body);
      if (parsed.isNotEmpty) return parsed;

      // Respaldo de compatibilidad si YouTube cambia la envoltura del JSON.
      // Conserva IDs para recuperacion de embeds, pero al no inventar titulo,
      // canal ni duracion estos candidatos no superan por si solos el matcher.
      final seen = <String>{};
      final results = <PipedSearchResult>[];
      for (final match in _youtubeVideoIdPattern.allMatches(response.body)) {
        final videoId = match.group(1);
        if (videoId == null || !seen.add(videoId)) continue;
        results.add(
          PipedSearchResult(
            videoId: videoId,
            title: '',
            uploaderName: '',
            durationSeconds: 0,
            searchRank: results.length,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// Flujos de audio disponibles para un video, usado por la descarga
  /// (feature "buscar y descargar canciones").
  Future<PipedStreams?> streamsOf(String videoId) async {
    for (final instance in _instances) {
      final uri = Uri.parse('$instance/streams/$videoId');
      try {
        final response = await _http.get(uri).timeout(_timeout);
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) continue;
        final audioStreams = (decoded['audioStreams'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (stream) => PipedAudioStream(
                url: stream['url'] as String? ?? '',
                mimeType: stream['mimeType'] as String? ?? 'audio/mp4',
                bitrate: (stream['bitrate'] as num?)?.toInt() ?? 0,
                codec: stream['codec'] as String?,
              ),
            )
            .where((stream) => stream.url.isNotEmpty)
            .toList();
        return PipedStreams(
          audioStreams: audioStreams,
          thumbnailUrl: decoded['thumbnailUrl'] as String?,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  PipedSearchResult? _parseSearchResult(
    Map item, {
    int searchRank = 0,
    bool isMusicCategory = false,
  }) {
    final url = item['url'] as String?;
    final videoId = _videoIdFromUrl(url);
    if (videoId == null) return null;
    return PipedSearchResult(
      videoId: videoId,
      title: item['title'] as String? ?? '',
      uploaderName: item['uploaderName'] as String? ?? '',
      durationSeconds: (item['duration'] as num?)?.toInt() ?? 0,
      description:
          item['shortDescription'] as String? ??
          item['description'] as String? ??
          '',
      uploaderVerified: item['uploaderVerified'] as bool? ?? false,
      isMusicCategory: isMusicCategory,
      views: (item['views'] as num?)?.toInt() ?? 0,
      searchRank: searchRank,
    );
  }

  List<PipedSearchResult> _parseYouTubeInitialData(String body) {
    Object? initialData;
    for (final marker in const ['var ytInitialData =', 'ytInitialData =']) {
      final rawJson = _jsonObjectAfter(body, marker);
      if (rawJson == null) continue;
      try {
        initialData = jsonDecode(rawJson);
        break;
      } catch (_) {
        continue;
      }
    }
    if (initialData == null) return const [];

    final renderers = <Map>[];
    _collectVideoRenderers(initialData, renderers);
    final seen = <String>{};
    final results = <PipedSearchResult>[];
    for (final renderer in renderers) {
      final videoId = renderer['videoId'] as String?;
      if (videoId == null ||
          !_validVideoId.hasMatch(videoId) ||
          !seen.add(videoId)) {
        continue;
      }
      final uploader = _textOf(renderer['ownerText']).isNotEmpty
          ? _textOf(renderer['ownerText'])
          : _textOf(renderer['shortBylineText']);
      results.add(
        PipedSearchResult(
          videoId: videoId,
          title: _textOf(renderer['title']),
          uploaderName: uploader,
          durationSeconds: _durationFromRenderer(renderer),
          description: _descriptionOf(renderer),
          uploaderVerified: _isVerifiedRenderer(renderer),
          views: _viewsFromRenderer(renderer),
          searchRank: results.length,
        ),
      );
    }
    return results;
  }

  static String? _jsonObjectAfter(String source, String marker) {
    final markerIndex = source.indexOf(marker);
    if (markerIndex < 0) return null;
    final start = source.indexOf('{', markerIndex + marker.length);
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < source.length; index++) {
      final codeUnit = source.codeUnitAt(index);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == 0x5C) {
          escaped = true;
        } else if (codeUnit == 0x22) {
          inString = false;
        }
        continue;
      }
      if (codeUnit == 0x22) {
        inString = true;
      } else if (codeUnit == 0x7B) {
        depth++;
      } else if (codeUnit == 0x7D) {
        depth--;
        if (depth == 0) return source.substring(start, index + 1);
      }
    }
    return null;
  }

  static void _collectVideoRenderers(Object? node, List<Map> output) {
    if (node is Map) {
      final renderer = node['videoRenderer'];
      if (renderer is Map) output.add(renderer);
      for (final value in node.values) {
        _collectVideoRenderers(value, output);
      }
    } else if (node is List) {
      for (final value in node) {
        _collectVideoRenderers(value, output);
      }
    }
  }

  static String _textOf(Object? node) {
    if (node is! Map) return '';
    final simple = node['simpleText'];
    if (simple is String) return simple;
    final runs = node['runs'];
    if (runs is! List) return '';
    return runs
        .whereType<Map>()
        .map((run) => run['text'])
        .whereType<String>()
        .join();
  }

  static int _durationFromRenderer(Map renderer) {
    final raw = _textOf(renderer['lengthText']);
    if (raw.isEmpty) return 0;
    final parts = raw.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null) || parts.length > 3) return 0;
    var seconds = 0;
    for (final part in parts) {
      seconds = seconds * 60 + part!;
    }
    return seconds;
  }

  static String _descriptionOf(Map renderer) {
    final snippets = renderer['detailedMetadataSnippets'];
    if (snippets is! List) return '';
    return snippets
        .whereType<Map>()
        .map((snippet) => _textOf(snippet['snippetText']))
        .where((text) => text.isNotEmpty)
        .join(' ');
  }

  static bool _isVerifiedRenderer(Map renderer) {
    final badges = <Object?>[renderer['ownerBadges'], renderer['badges']];
    for (final collection in badges.whereType<List>()) {
      for (final badge in collection.whereType<Map>()) {
        final metadata = badge['metadataBadgeRenderer'];
        if (metadata is! Map) continue;
        final style = '${metadata['style']}'.toLowerCase();
        final label = '${metadata['label']}'.toLowerCase();
        if (style.contains('verified') || label.contains('verified')) {
          return true;
        }
      }
    }
    return false;
  }

  static int _viewsFromRenderer(Map renderer) {
    final raw = _textOf(renderer['viewCountText']).isNotEmpty
        ? _textOf(renderer['viewCountText'])
        : _textOf(renderer['shortViewCountText']);
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Piped devuelve `url` como `/watch?v=<id>`.
  String? _videoIdFromUrl(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    return uri?.queryParameters['v'];
  }

  void dispose() => _http.close();

  static final _validVideoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
}
