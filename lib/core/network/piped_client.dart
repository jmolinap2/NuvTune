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
  });

  final String videoId;
  final String title;
  final String uploaderName;
  final int durationSeconds;
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
    final candidates = await searchMusicVideos(query, limit: 1);
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Devuelve varios candidatos ordenados para poder recuperarse cuando el
  /// primer resultado no permite reproducción embebida o ya no está disponible.
  Future<List<String>> searchMusicVideos(String query, {int limit = 5}) async {
    if (limit <= 0) return const [];
    final directResults = await _searchYouTube('$query official music video');
    if (directResults.isNotEmpty) {
      return directResults.take(limit).toList(growable: false);
    }

    final fallback = await searchMany(query);
    return fallback
        .map((result) => result.videoId)
        .toSet()
        .take(limit)
        .toList(growable: false);
  }

  /// Primer resultado de musica para `artista titulo`, o `null` si ninguna
  /// instancia respondio o no hubo resultados.
  Future<String?> search(String query) async {
    final results = await searchMany(query);
    return results.isEmpty ? null : results.first.videoId;
  }

  /// Todos los resultados de musica para `query` (buscador de descargas).
  Future<List<PipedSearchResult>> searchMany(String query) async {
    for (final instance in _instances) {
      final uri = Uri.parse(
        '$instance/search',
      ).replace(queryParameters: {'q': query, 'filter': 'music_songs'});
      try {
        final response = await _http.get(uri).timeout(_timeout);
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(response.body);
        final items = decoded is Map ? decoded['items'] : null;
        if (items is! List) continue;
        return items
            .whereType<Map>()
            .map((item) => _parseSearchResult(item))
            .whereType<PipedSearchResult>()
            .toList();
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  Future<List<String>> _searchYouTube(String query) async {
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

      // El mismo video aparece en varios nodos del JSON incrustado. Un
      // LinkedHashSet implicito (lista + set) conserva el orden real de los
      // resultados y evita devolver IDs repetidos.
      final seen = <String>{};
      final videoIds = <String>[];
      for (final match in _youtubeVideoIdPattern.allMatches(response.body)) {
        final videoId = match.group(1);
        if (videoId != null && seen.add(videoId)) videoIds.add(videoId);
      }
      return videoIds;
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

  PipedSearchResult? _parseSearchResult(Map item) {
    final url = item['url'] as String?;
    final videoId = _videoIdFromUrl(url);
    if (videoId == null) return null;
    return PipedSearchResult(
      videoId: videoId,
      title: item['title'] as String? ?? '',
      uploaderName: item['uploaderName'] as String? ?? '',
      durationSeconds: (item['duration'] as num?)?.toInt() ?? 0,
    );
  }

  /// Piped devuelve `url` como `/watch?v=<id>`.
  String? _videoIdFromUrl(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    return uri?.queryParameters['v'];
  }

  void dispose() => _http.close();
}
