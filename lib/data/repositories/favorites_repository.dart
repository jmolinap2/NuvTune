import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Favoritos (requerimiento seccion 4.4).
class FavoritesRepository {
  FavoritesRepository(this._database);

  final NuvTuneDatabase _database;

  Stream<Set<int>> watchFavoriteIds() => _database
      .select(_database.favorites)
      .watch()
      .map((rows) => rows.map((row) => row.songId).toSet());

  Future<Set<int>> favoriteIds() async {
    final rows = await _database.select(_database.favorites).get();
    return rows.map((row) => row.songId).toSet();
  }

  Future<bool> isFavorite(int songId) async {
    final row = await (_database.select(
      _database.favorites,
    )..where((table) => table.songId.equals(songId))).getSingleOrNull();
    return row != null;
  }

  /// Devuelve el estado nuevo, para que quien la llame pueda informarlo al
  /// motor y la notificacion dibuje el icono correcto.
  Future<bool> toggle(int songId) async {
    final current = await isFavorite(songId);
    if (current) {
      await remove(songId);
      return false;
    }
    await add(songId);
    return true;
  }

  Future<void> add(int songId) => _database
      .into(_database.favorites)
      .insertOnConflictUpdate(FavoritesCompanion.insert(songId: Value(songId)));

  Future<void> remove(int songId) => (_database.delete(
    _database.favorites,
  )..where((table) => table.songId.equals(songId))).go();

  Future<void> addAll(Iterable<int> songIds) => _database.batch((batch) {
    batch.insertAllOnConflictUpdate(
      _database.favorites,
      songIds
          .map((id) => FavoritesCompanion.insert(songId: Value(id)))
          .toList(),
    );
  });

  /// Los favoritos se guardan en orden de agregado, el mas reciente primero.
  Future<List<int>> orderedFavoriteIds() async {
    final rows =
        await (_database.select(_database.favorites)..orderBy([
              (table) => OrderingTerm(
                expression: table.addedAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    return rows.map((row) => row.songId).toList();
  }
}
