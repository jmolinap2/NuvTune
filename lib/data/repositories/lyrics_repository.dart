import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Letras editadas o asociadas a mano, con su desfase (requerimiento seccion 8).
///
/// El motor resuelve las letras incrustadas y los archivos `.lrc` del
/// almacenamiento; lo que se guarda aqui son las correcciones del usuario, que
/// tienen prioridad sobre ambas.
class LyricsRepository {
  LyricsRepository(this._database);

  final NuvTuneDatabase _database;

  Future<LyricsOverride?> overrideFor(int songId) => (_database.select(
    _database.lyricsOverrides,
  )..where((table) => table.songId.equals(songId))).getSingleOrNull();

  Stream<LyricsOverride?> watchOverride(int songId) => (_database.select(
    _database.lyricsOverrides,
  )..where((table) => table.songId.equals(songId))).watchSingleOrNull();

  Future<void> save({
    required int songId,
    required String content,
    required bool synchronized,
    int offsetMs = 0,
  }) => _database
      .into(_database.lyricsOverrides)
      .insertOnConflictUpdate(
        LyricsOverridesCompanion.insert(
          songId: Value(songId),
          content: content,
          synchronized: Value(synchronized),
          offsetMs: Value(offsetMs),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> saveOffset(int songId, int offsetMs) =>
      (_database.update(
        _database.lyricsOverrides,
      )..where((table) => table.songId.equals(songId))).write(
        LyricsOverridesCompanion(
          offsetMs: Value(offsetMs),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> remove(int songId) => (_database.delete(
    _database.lyricsOverrides,
  )..where((table) => table.songId.equals(songId))).go();
}
