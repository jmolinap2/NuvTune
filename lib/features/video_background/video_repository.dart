import 'package:drift/drift.dart';
import 'package:nuvtune/core/network/piped_client.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';

/// Resuelve el video musical de una cancion para el fondo del reproductor
/// (feature "video de fondo en Wi-Fi"), con cache en `SongVideoIds` y cache
/// negativo de 24h para no reintentar canciones sin resultado en cada
/// reproduccion (Piped responde 429/500 seguido).
class VideoRepository {
  VideoRepository(this._database, this._piped);

  final NuvTuneDatabase _database;
  final PipedClient _piped;

  static const _negativeCacheTtl = Duration(hours: 24);

  String songKeyOf(Song song) =>
      '${song.artist}||${song.title}'.trim().toLowerCase();

  Future<String?> videoIdFor(Song song) async {
    final key = songKeyOf(song);
    final cached = await (_database.select(_database.songVideoIds)
          ..where((table) => table.songKey.equals(key)))
        .getSingleOrNull();

    if (cached != null) {
      if (cached.videoId.isNotEmpty) return cached.videoId;
      final expired =
          DateTime.now().difference(cached.fetchedAt) > _negativeCacheTtl;
      if (!expired) return null;
    }

    final found = await _piped.search('${song.artist} ${song.title}');
    await _database.into(_database.songVideoIds).insertOnConflictUpdate(
          SongVideoIdsCompanion.insert(
            songKey: key,
            videoId: found ?? '',
            fetchedAt: Value(DateTime.now()),
          ),
        );
    return found;
  }
}
