import 'package:drift/drift.dart';
import 'package:nuvtune/core/network/piped_client.dart';
import 'package:nuvtune/core/platform/download_engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/video_background/music_video_matcher.dart';

/// Resuelve el video musical de una cancion para el fondo del reproductor
/// (feature "video de fondo en Wi-Fi"), con cache en `SongVideoIds` y cache
/// negativo breve para no repetir solicitudes mientras se cambia de pestana,
/// sin dejar bloqueado durante un dia un resultado fallido por problemas de
/// red temporales.
class VideoRepository {
  VideoRepository(
    this._database,
    this._piped,
    this._downloadEngine, {
    this._matcher = const MusicVideoMatcher(),
  });

  final NuvTuneDatabase _database;
  final PipedClient _piped;
  final DownloadEngineBridge _downloadEngine;
  final MusicVideoMatcher _matcher;

  static const _negativeCacheTtl = Duration(minutes: 2);
  static const _cacheSourcePrefix = 'music_match_v2';
  final Map<String, Set<String>> _rejectedIds = {};

  /// Incluye album y duracion para no mezclar, por ejemplo, la version de
  /// estudio con una edicion en vivo que conserve artista y titulo.
  String songKeyOf(Song song) =>
      '${song.artist}||${song.title}||${song.album}||${song.durationMs}'
          .trim()
          .toLowerCase();

  /// Solo lo que ya esta en cache, sin tocar la red.
  ///
  /// Lo usa el envio de un regalo: adjuntar la fuente exacta de cada cancion
  /// hace que el receptor descargue la misma version y no "lo primero que
  /// aparezca". Preguntarle a Piped por cada cancion de la lista en ese
  /// momento dejaria el envio esperando por decenas de solicitudes, de modo
  /// que se aprovecha lo que ya se resolvio antes (por el video de fondo) y
  /// el resto lo confirma el receptor.
  Future<String?> cachedVideoIdFor(Song song) async {
    final cached =
        await (_database.select(_database.songVideoIds)
              ..where((table) => table.songKey.equals(songKeyOf(song))))
            .getSingleOrNull();
    final videoId = cached?.videoId;
    return (videoId == null || videoId.isEmpty) ? null : videoId;
  }

  Future<String?> videoIdFor(Song song) async {
    final key = songKeyOf(song);
    final rejected = _rejectedIds[key] ?? const <String>{};
    final cached = await (_database.select(
      _database.songVideoIds,
    )..where((table) => table.songKey.equals(key))).getSingleOrNull();

    if (cached != null) {
      final currentMatcherCache = cached.source.startsWith(_cacheSourcePrefix);
      if (currentMatcherCache &&
          cached.videoId.isNotEmpty &&
          !rejected.contains(cached.videoId)) {
        return cached.videoId;
      }
      final expired =
          DateTime.now().difference(cached.fetchedAt) > _negativeCacheTtl;
      if (currentMatcherCache && cached.videoId.isEmpty && !expired) {
        return null;
      }
    }

    final query = _initialQuery(song);
    final initial = await _piped.searchMusicVideoCandidates(query, limit: 15);
    var candidates = _mergeCandidates(initial);
    var match = _select(song, candidates, rejected);

    // Si la pagina directa de YouTube solo trajo resultados ambiguos, se
    // amplia con la busqueda musical de Piped y el album cuando este existe.
    // El matcher vuelve a decidir sobre el conjunto completo: tampoco aqui se
    // toma simplemente el primer resultado.
    if (match == null) {
      final expanded = await _piped.searchMany(_expandedQuery(song));
      candidates = _mergeCandidates([...candidates, ...expanded]);
      match = _select(song, candidates, rejected);
    }

    // Las instancias publicas de Piped y la pagina web de YouTube pueden no
    // devolver resultados, aunque la cancion si exista. El extractor nativo
    // ya incluido para las descargas ofrece una tercera fuente y una lista mas
    // amplia. Sus resultados pasan por exactamente el mismo matcher: nunca se
    // elige de forma arbitraria el primero.
    if (match == null) {
      final extracted = await _extractorCandidates(_expandedQuery(song));
      candidates = _mergeCandidates([...candidates, ...extracted]);
      match = _select(song, candidates, rejected);
    }

    final found = match?.videoId;
    final source = match == null
        ? '$_cacheSourcePrefix:no_match'
        : '$_cacheSourcePrefix:${match.sourceType.name}:'
              '${match.confidence.name}:${match.score}';
    await _database
        .into(_database.songVideoIds)
        .insertOnConflictUpdate(
          SongVideoIdsCompanion.insert(
            songKey: key,
            videoId: found ?? '',
            source: Value(source),
            fetchedAt: Value(DateTime.now()),
          ),
        );
    return found;
  }

  Future<List<PipedSearchResult>> _extractorCandidates(String query) async {
    try {
      await _downloadEngine.initialize();
      final results = await _downloadEngine.api.search(query, 25);
      return [
        for (var index = 0; index < results.length; index++)
          if (_youtubeVideoId(results[index].sourceUrl) case final id?)
            PipedSearchResult(
              videoId: id,
              title: results[index].title,
              uploaderName: results[index].author ?? '',
              durationSeconds: results[index].durationSeconds,
              searchRank: index,
            ),
      ];
    } on Object {
      // Es un respaldo: una falla del extractor no debe romper el reproductor.
      return const [];
    }
  }

  static String? _youtubeVideoId(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return null;
    final queryId = uri.queryParameters['v'];
    if (queryId != null && _isVideoId(queryId)) return queryId;
    if (uri.host.toLowerCase() == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      if (_isVideoId(id)) return id;
    }
    final segments = uri.pathSegments;
    if (segments.length >= 2 &&
        const {'embed', 'shorts', 'live'}.contains(segments.first)) {
      final id = segments[1];
      if (_isVideoId(id)) return id;
    }
    return null;
  }

  static bool _isVideoId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);

  MusicVideoMatch? _select(
    Song song,
    List<PipedSearchResult> candidates,
    Set<String> rejected,
  ) {
    final available = candidates
        .where((candidate) => !rejected.contains(candidate.videoId))
        .toList(growable: false);
    return _matcher.selectBestMatch(
      MusicVideoSongMetadata(
        title: song.title,
        artist: _knownValue(song.artist) ?? '',
        album: _knownValue(song.album),
        durationSeconds: song.durationMs > 0 ? song.durationMs ~/ 1000 : null,
      ),
      [
        for (var index = 0; index < available.length; index++)
          YouTubeCandidate(
            videoId: available[index].videoId,
            title: available[index].title,
            uploaderName: available[index].uploaderName,
            durationSeconds: available[index].durationSeconds,
            description: available[index].description,
            uploaderVerified: available[index].uploaderVerified,
            isMusicCategory: available[index].isMusicCategory,
            views: available[index].views,
            searchRank: index,
          ),
      ],
    );
  }

  static List<PipedSearchResult> _mergeCandidates(
    Iterable<PipedSearchResult> candidates,
  ) {
    final byId = <String, PipedSearchResult>{};
    for (final candidate in candidates) {
      final existing = byId[candidate.videoId];
      if (existing == null ||
          _metadataQuality(candidate) > _metadataQuality(existing)) {
        byId[candidate.videoId] = candidate;
      }
    }
    return byId.values.toList(growable: false);
  }

  static int _metadataQuality(PipedSearchResult candidate) =>
      (candidate.title.isNotEmpty ? 2 : 0) +
      (candidate.uploaderName.isNotEmpty ? 2 : 0) +
      (candidate.durationSeconds > 0 ? 1 : 0) +
      (candidate.description.isNotEmpty ? 1 : 0) +
      (candidate.uploaderVerified ? 1 : 0) +
      (candidate.isMusicCategory ? 1 : 0);

  static String _initialQuery(Song song) {
    final artist = _knownValue(song.artist);
    return [
      ?artist,
      song.title.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  static String _expandedQuery(Song song) {
    final artist = _knownValue(song.artist);
    final album = _knownValue(song.album);
    return [
      song.title.trim(),
      ?artist,
      ?album,
    ].where((part) => part.isNotEmpty).join(' ');
  }

  static String? _knownValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == '<unknown>') return null;
    return trimmed;
  }

  /// Descarta un candidato que el IFrame de YouTube rechazó. La exclusión se
  /// mantiene durante esta ejecución y el siguiente intento usa otro ID.
  Future<void> rejectVideo(Song song, String videoId) async {
    final key = songKeyOf(song);
    _rejectedIds.putIfAbsent(key, () => <String>{}).add(videoId);
    await (_database.delete(_database.songVideoIds)..where(
          (table) => table.songKey.equals(key) & table.videoId.equals(videoId),
        ))
        .go();
  }
}
