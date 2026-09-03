import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Registro de como se eligio el video musical de cada cancion.
///
/// Sirve para afinar el algoritmo de seleccion con datos del telefono real:
/// que candidatos devolvio la busqueda, con que señales llegaron y cual gano.
/// Es el equivalente en Dart de lo que `PlaybackFailureLog` hace en el motor.
class VideoMatchLogRepository {
  VideoMatchLogRepository(this._database);

  final NuvTuneDatabase _database;

  /// Entradas que se conservan. El registro es una herramienta de ajuste, no
  /// un historial: pasado este limite las mas viejas ya no aportan y solo
  /// harian crecer la base de datos sin fin.
  static const _maxEntries = 200;

  Stream<List<VideoMatchLogData>> watchEntries() =>
      (_database.select(_database.videoMatchLog)
            ..orderBy([
              (table) => OrderingTerm(
                expression: table.resolvedAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .watch();

  Future<void> record({
    required String songTitle,
    required String songArtist,
    required int songDurationSeconds,
    required String query,
    required String? chosenVideoId,
    required int? chosenScore,
    required String? chosenSourceType,
    required String? chosenConfidence,
    required List<Map<String, Object?>> candidates,
  }) async {
    await _database
        .into(_database.videoMatchLog)
        .insert(
          VideoMatchLogCompanion.insert(
            songTitle: songTitle,
            songArtist: songArtist,
            songDurationSeconds: songDurationSeconds,
            query: query,
            chosenVideoId: Value(chosenVideoId ?? ''),
            chosenScore: Value(chosenScore),
            chosenSourceType: Value(chosenSourceType),
            chosenConfidence: Value(chosenConfidence),
            candidatesJson: Value(jsonEncode(candidates)),
          ),
        );
    await _trim();
  }

  Future<void> clear() => _database.delete(_database.videoMatchLog).go();

  /// Deja solo las [_maxEntries] mas recientes.
  Future<void> _trim() async {
    final ids =
        await (_database.select(_database.videoMatchLog)
              ..orderBy([
                (table) => OrderingTerm(
                  expression: table.resolvedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1, offset: _maxEntries - 1))
            .get();
    if (ids.isEmpty) return;
    final oldest = ids.first.resolvedAt;
    await (_database.delete(
      _database.videoMatchLog,
    )..where((table) => table.resolvedAt.isSmallerThanValue(oldest))).go();
  }
}
