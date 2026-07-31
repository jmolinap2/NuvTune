import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Lista con sus canciones resueltas en orden.
class PlaylistWithSongIds {
  const PlaylistWithSongIds({required this.playlist, required this.songIds});

  final Playlist playlist;
  final List<int> songIds;

  int get length => songIds.length;
}

/// Listas de reproduccion creadas por el usuario (requerimiento seccion 4.4).
class PlaylistRepository {
  PlaylistRepository(this._database);

  final NuvTuneDatabase _database;

  Stream<List<Playlist>> watchPlaylists() => (_database.select(_database.playlists)
        ..orderBy([
          (table) => OrderingTerm(expression: table.name.lower()),
        ]))
      .watch();

  Future<List<Playlist>> playlists() => (_database.select(_database.playlists)
        ..orderBy([(table) => OrderingTerm(expression: table.name.lower())]))
      .get();

  Future<Playlist?> playlistById(int id) =>
      (_database.select(_database.playlists)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<List<int>> watchSongIds(int playlistId) =>
      (_database.select(_database.playlistEntries)
            ..where((table) => table.playlistId.equals(playlistId))
            ..orderBy([(table) => OrderingTerm(expression: table.position)]))
          .watch()
          .map((rows) => rows.map((row) => row.songId).toList());

  Future<List<int>> songIds(int playlistId) async {
    final rows = await (_database.select(_database.playlistEntries)
          ..where((table) => table.playlistId.equals(playlistId))
          ..orderBy([(table) => OrderingTerm(expression: table.position)]))
        .get();
    return rows.map((row) => row.songId).toList();
  }

  /// Cuenta de canciones por lista, para pintar los subtitulos sin cargar todas
  /// las entradas.
  Stream<Map<int, int>> watchSongCounts() {
    final query = _database.selectOnly(_database.playlistEntries)
      ..addColumns([
        _database.playlistEntries.playlistId,
        _database.playlistEntries.songId.count(),
      ])
      ..groupBy([_database.playlistEntries.playlistId]);

    return query.watch().map((rows) {
      final result = <int, int>{};
      for (final row in rows) {
        final id = row.read(_database.playlistEntries.playlistId);
        final count = row.read(_database.playlistEntries.songId.count());
        if (id != null && count != null) {
          result[id] = count;
        }
      }
      return result;
    });
  }

  Future<int> create(String name, {List<int> songIds = const []}) async {
    final id = await _database.into(_database.playlists).insert(
          PlaylistsCompanion.insert(name: name),
        );
    if (songIds.isNotEmpty) {
      await addSongs(id, songIds);
    }
    return id;
  }

  Future<void> rename(int playlistId, String name) =>
      (_database.update(_database.playlists)
            ..where((table) => table.id.equals(playlistId)))
          .write(
        PlaylistsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  Future<void> setCover(int playlistId, String? coverPath) =>
      (_database.update(_database.playlists)
            ..where((table) => table.id.equals(playlistId)))
          .write(
        PlaylistsCompanion(
          coverPath: Value(coverPath),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Elimina la lista sin borrar las canciones (requerimiento 4.4).
  Future<void> delete(int playlistId) =>
      (_database.delete(_database.playlists)
            ..where((table) => table.id.equals(playlistId)))
          .go();

  Future<int> duplicate(int playlistId) async {
    final source = await playlistById(playlistId);
    if (source == null) {
      throw StateError('La lista $playlistId no existe');
    }
    final ids = await songIds(playlistId);
    return create('${source.name} (copia)', songIds: ids);
  }

  Future<void> addSongs(int playlistId, List<int> songIds) async {
    if (songIds.isEmpty) return;
    final existing = await this.songIds(playlistId);
    var position = existing.length;
    await _database.batch((batch) {
      for (final songId in songIds) {
        batch.insert(
          _database.playlistEntries,
          PlaylistEntriesCompanion.insert(
            playlistId: playlistId,
            songId: songId,
            position: position++,
          ),
        );
      }
    });
    await _touch(playlistId);
  }

  Future<void> removeAt(int playlistId, int position) async {
    final ids = await songIds(playlistId);
    if (position < 0 || position >= ids.length) return;
    ids.removeAt(position);
    await replaceSongs(playlistId, ids);
  }

  Future<void> removeSong(int playlistId, int songId) async {
    final ids = await songIds(playlistId);
    ids.remove(songId);
    await replaceSongs(playlistId, ids);
  }

  /// Reordenamiento manual (requerimiento 4.4).
  Future<void> move(int playlistId, int fromIndex, int toIndex) async {
    final ids = await songIds(playlistId);
    if (fromIndex < 0 || fromIndex >= ids.length) return;
    final songId = ids.removeAt(fromIndex);
    ids.insert(toIndex.clamp(0, ids.length), songId);
    await replaceSongs(playlistId, ids);
  }

  /// Reescribe todas las posiciones. Las posiciones son parte de la clave
  /// primaria, asi que se borra y se vuelve a insertar dentro de una
  /// transaccion.
  Future<void> replaceSongs(int playlistId, List<int> songIds) async {
    await _database.transaction(() async {
      await (_database.delete(_database.playlistEntries)
            ..where((table) => table.playlistId.equals(playlistId)))
          .go();
      await _database.batch((batch) {
        for (var index = 0; index < songIds.length; index++) {
          batch.insert(
            _database.playlistEntries,
            PlaylistEntriesCompanion.insert(
              playlistId: playlistId,
              songId: songIds[index],
              position: index,
            ),
          );
        }
      });
    });
    await _touch(playlistId);
  }

  /// Descarta de todas las listas las canciones que ya no existen.
  Future<void> pruneMissingSongs(Set<int> existingSongIds) async {
    final all = await playlists();
    for (final playlist in all) {
      final ids = await songIds(playlist.id);
      final kept = ids.where(existingSongIds.contains).toList();
      if (kept.length != ids.length) {
        await replaceSongs(playlist.id, kept);
      }
    }
  }

  Future<void> _touch(int playlistId) =>
      (_database.update(_database.playlists)
            ..where((table) => table.id.equals(playlistId)))
          .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
}
