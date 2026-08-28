import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Cola guardada, tal como debe restaurarse al abrir la aplicacion.
class SavedQueue {
  const SavedQueue({
    required this.songIds,
    required this.currentIndex,
    required this.positionMs,
    required this.repeatModeIndex,
    required this.shuffleEnabled,
  });

  final List<int> songIds;
  final int currentIndex;
  final int positionMs;
  final int repeatModeIndex;
  final bool shuffleEnabled;

  bool get isEmpty => songIds.isEmpty;

  static const empty = SavedQueue(
    songIds: [],
    currentIndex: -1,
    positionMs: 0,
    repeatModeIndex: 0,
    shuffleEnabled: false,
  );
}

/// Persistencia de la cola (requerimiento seccion 4.3).
///
/// Guarda canciones, orden, cancion actual, posicion, estado de repeticion y
/// estado aleatorio, que es exactamente la lista que exige el requerimiento.
class QueueRepository {
  QueueRepository(this._database);

  final NuvTuneDatabase _database;

  Future<SavedQueue> load() async {
    final entries = await (_database.select(
      _database.queueEntries,
    )..orderBy([(table) => OrderingTerm(expression: table.position)])).get();
    final state = await (_database.select(
      _database.queueState,
    )..where((table) => table.id.equals(0))).getSingleOrNull();

    if (entries.isEmpty) return SavedQueue.empty;

    return SavedQueue(
      songIds: entries.map((row) => row.songId).toList(),
      currentIndex: state?.currentIndex ?? 0,
      positionMs: state?.positionMs ?? 0,
      repeatModeIndex: state?.repeatMode ?? 0,
      shuffleEnabled: state?.shuffleEnabled ?? false,
    );
  }

  /// Reemplaza la cola completa. Se llama cuando el motor avisa de que la cola
  /// cambio, no en cada movimiento de la barra de progreso.
  Future<void> saveQueue(List<int> songIds, int currentIndex) async {
    await _database.transaction(() async {
      await _database.delete(_database.queueEntries).go();
      await _database.batch((batch) {
        for (var index = 0; index < songIds.length; index++) {
          batch.insert(
            _database.queueEntries,
            QueueEntriesCompanion.insert(
              position: Value(index),
              songId: songIds[index],
            ),
          );
        }
      });
      await _upsertState(
        QueueStateCompanion(currentIndex: Value(currentIndex)),
      );
    });
  }

  Future<void> savePosition(int currentIndex, int positionMs) => _upsertState(
    QueueStateCompanion(
      currentIndex: Value(currentIndex),
      positionMs: Value(positionMs),
    ),
  );

  Future<void> saveModes({
    required int repeatModeIndex,
    required bool shuffleEnabled,
  }) => _upsertState(
    QueueStateCompanion(
      repeatMode: Value(repeatModeIndex),
      shuffleEnabled: Value(shuffleEnabled),
    ),
  );

  Future<void> clear() async {
    await _database.delete(_database.queueEntries).go();
    await _upsertState(
      const QueueStateCompanion(currentIndex: Value(-1), positionMs: Value(0)),
    );
  }

  /// La fila de estado siempre tiene id 0; se hace merge para no perder los
  /// campos que no vienen en [companion].
  Future<void> _upsertState(QueueStateCompanion companion) async {
    final existing = await (_database.select(
      _database.queueState,
    )..where((table) => table.id.equals(0))).getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.queueState)
          .insert(companion.copyWith(id: const Value(0)));
      return;
    }

    await (_database.update(
      _database.queueState,
    )..where((table) => table.id.equals(0))).write(companion);
  }
}
