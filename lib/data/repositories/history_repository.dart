import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Historial y contador de reproducciones (requerimiento seccion 14).
///
/// Alimenta las vistas "reproducidas recientemente" y "mas reproducidas", y
/// varias listas inteligentes.
class HistoryRepository {
  HistoryRepository(this._database);

  final NuvTuneDatabase _database;

  /// Una cancion cuenta como reproducida cuando ha sonado lo suficiente; quien
  /// llama decide el umbral. Aqui solo se registra.
  Future<void> registerPlay(int songId) async {
    await _database.transaction(() async {
      await _database
          .into(_database.playHistory)
          .insert(PlayHistoryCompanion.insert(songId: songId));

      final existing = await (_database.select(
        _database.playCounts,
      )..where((table) => table.songId.equals(songId))).getSingleOrNull();

      await _database
          .into(_database.playCounts)
          .insertOnConflictUpdate(
            PlayCountsCompanion.insert(
              songId: Value(songId),
              count: Value((existing?.count ?? 0) + 1),
              lastPlayedAt: Value(DateTime.now()),
            ),
          );

      // El historial se recorta para que no crezca sin limite
      // (requerimiento seccion 17).
      await _database.customStatement(
        'DELETE FROM play_history WHERE id NOT IN '
        '(SELECT id FROM play_history ORDER BY played_at DESC LIMIT ?)',
        [_historyLimit],
      );
    });
  }

  /// Identificadores en orden de escucha, del mas reciente al mas antiguo y sin
  /// repeticiones.
  Stream<List<int>> watchRecentlyPlayedIds({int limit = 100}) {
    final query = _database.selectOnly(_database.playHistory)
      ..addColumns([
        _database.playHistory.songId,
        _database.playHistory.playedAt.max(),
      ])
      ..groupBy([_database.playHistory.songId])
      ..orderBy([
        OrderingTerm(
          expression: _database.playHistory.playedAt.max(),
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);

    return query.watch().map(
      (rows) => rows
          .map((row) => row.read(_database.playHistory.songId))
          .whereType<int>()
          .toList(),
    );
  }

  Stream<List<int>> watchMostPlayedIds({int limit = 100}) {
    final query = _database.select(_database.playCounts)
      ..where((table) => table.count.isBiggerThanValue(0))
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.count, mode: OrderingMode.desc),
        (table) => OrderingTerm(
          expression: table.lastPlayedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.watch().map((rows) => rows.map((row) => row.songId).toList());
  }

  Stream<Map<int, int>> watchPlayCounts() => _database
      .select(_database.playCounts)
      .watch()
      .map((rows) => {for (final row in rows) row.songId: row.count});

  Future<Map<int, int>> playCounts() async {
    final rows = await _database.select(_database.playCounts).get();
    return {for (final row in rows) row.songId: row.count};
  }

  Future<int?> lastPlayedSongId() async {
    final row =
        await (_database.select(_database.playHistory)
              ..orderBy([
                (table) => OrderingTerm(
                  expression: table.playedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.songId;
  }

  Future<void> clearHistory() async {
    await _database.delete(_database.playHistory).go();
    await _database.delete(_database.playCounts).go();
  }

  /// Se descartan las entradas de canciones que ya no estan en la biblioteca.
  Future<void> pruneMissingSongs(Set<int> existingSongIds) async {
    final historyRows = await _database.select(_database.playHistory).get();
    final orphanHistory = historyRows
        .where((row) => !existingSongIds.contains(row.songId))
        .map((row) => row.id)
        .toList();
    if (orphanHistory.isNotEmpty) {
      await (_database.delete(
        _database.playHistory,
      )..where((table) => table.id.isIn(orphanHistory))).go();
    }

    final countRows = await _database.select(_database.playCounts).get();
    final orphanCounts = countRows
        .where((row) => !existingSongIds.contains(row.songId))
        .map((row) => row.songId)
        .toList();
    if (orphanCounts.isNotEmpty) {
      await (_database.delete(
        _database.playCounts,
      )..where((table) => table.songId.isIn(orphanCounts))).go();
    }
  }

  static const _historyLimit = 1000;
}
