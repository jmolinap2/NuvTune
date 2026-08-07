import 'package:drift/drift.dart';
import 'package:nuvtune/core/network/piped_client.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';

/// Resuelve el video musical de una cancion para el fondo del reproductor
/// (feature "video de fondo en Wi-Fi"), con cache en `SongVideoIds` y cache
/// negativo breve para no repetir solicitudes mientras se cambia de pestana,
/// sin dejar bloqueado durante un dia un resultado fallido por problemas de
/// red temporales.
class VideoRepository {
  VideoRepository(this._database, this._piped);

  final NuvTuneDatabase _database;
  final PipedClient _piped;

  static const _negativeCacheTtl = Duration(minutes: 2);
  final Map<String, Set<String>> _rejectedIds = {};

  String songKeyOf(Song song) =>
      '${song.artist}||${song.title}'.trim().toLowerCase();

  Future<String?> videoIdFor(Song song) async {
    final key = songKeyOf(song);
    final rejected = _rejectedIds[key] ?? const <String>{};
    final cached = await (_database.select(
      _database.songVideoIds,
    )..where((table) => table.songKey.equals(key))).getSingleOrNull();

    if (cached != null) {
      if (cached.videoId.isNotEmpty && !rejected.contains(cached.videoId)) {
        return cached.videoId;
      }
      final expired =
          DateTime.now().difference(cached.fetchedAt) > _negativeCacheTtl;
      if (cached.videoId.isEmpty && !expired) return null;
    }

    final candidates = await _piped.searchMusicVideos(
      '${song.artist} ${song.title}',
    );
    final found = candidates.where((id) => !rejected.contains(id)).firstOrNull;
    await _database
        .into(_database.songVideoIds)
        .insertOnConflictUpdate(
          SongVideoIdsCompanion.insert(
            songKey: key,
            videoId: found ?? '',
            fetchedAt: Value(DateTime.now()),
          ),
        );
    return found;
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
