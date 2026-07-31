import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';

/// Estado del ecualizador y presets guardados (requerimiento seccion 14).
class EqualizerRepository {
  EqualizerRepository(this._database);

  final NuvTuneDatabase _database;

  Stream<EqualizerStateData> watchState() =>
      _database.select(_database.equalizerState).watchSingleOrNull().asyncMap(
            (row) async => row ?? await _ensureRow(),
          );

  Future<EqualizerStateData> state() async {
    final row = await (_database.select(_database.equalizerState)
          ..where((table) => table.id.equals(0)))
        .getSingleOrNull();
    return row ?? await _ensureRow();
  }

  /// Convierte la fila guardada en los ajustes que espera el motor.
  Future<EqualizerSettings> engineSettings() async {
    final row = await state();
    return EqualizerSettings(
      enabled: row.enabled,
      bandGainsDb: decodeGains(row.gainsJson, row.bandCount),
      preampDb: row.preampDb,
      autoPreventClipping: row.autoPreventClipping,
      balance: row.balance,
      monoOutput: row.monoOutput,
    );
  }

  Future<void> save({
    bool? enabled,
    int? bandCount,
    List<double>? gains,
    double? preampDb,
    bool? autoPreventClipping,
    double? balance,
    bool? monoOutput,
    String? presetName,
  }) async {
    await _ensureRow();
    await (_database.update(_database.equalizerState)
          ..where((table) => table.id.equals(0)))
        .write(
      EqualizerStateCompanion(
        enabled: enabled == null ? const Value.absent() : Value(enabled),
        bandCount: bandCount == null ? const Value.absent() : Value(bandCount),
        gainsJson: gains == null ? const Value.absent() : Value(jsonEncode(gains)),
        preampDb: preampDb == null ? const Value.absent() : Value(preampDb),
        autoPreventClipping: autoPreventClipping == null
            ? const Value.absent()
            : Value(autoPreventClipping),
        balance: balance == null ? const Value.absent() : Value(balance),
        monoOutput:
            monoOutput == null ? const Value.absent() : Value(monoOutput),
        presetName:
            presetName == null ? const Value.absent() : Value(presetName),
      ),
    );
  }

  Future<EqualizerStateData> _ensureRow() async {
    final existing = await (_database.select(_database.equalizerState)
          ..where((table) => table.id.equals(0)))
        .getSingleOrNull();
    if (existing != null) return existing;
    await _database
        .into(_database.equalizerState)
        .insert(const EqualizerStateCompanion(id: Value(0)));
    return (_database.select(_database.equalizerState)
          ..where((table) => table.id.equals(0)))
        .getSingle();
  }

  // -- Presets guardados por el usuario ------------------------------------

  Stream<List<EqualizerPreset>> watchUserPresets() =>
      (_database.select(_database.equalizerPresetsTable)
            ..orderBy([(table) => OrderingTerm(expression: table.name.lower())]))
          .watch();

  Future<void> saveUserPreset({
    required String name,
    required int bandCount,
    required List<double> gains,
    required double preampDb,
  }) =>
      _database.into(_database.equalizerPresetsTable).insertOnConflictUpdate(
            EqualizerPresetsTableCompanion.insert(
              name: name,
              bandCount: bandCount,
              gainsJson: jsonEncode(gains),
              preampDb: Value(preampDb),
            ),
          );

  Future<void> deleteUserPreset(String name) =>
      (_database.delete(_database.equalizerPresetsTable)
            ..where((table) => table.name.equals(name)))
          .go();

  /// Decodifica las ganancias guardadas. Si el numero de bandas guardado no
  /// coincide con el pedido, se rellena o se recorta: pasa al cambiar entre el
  /// modo de 10 bandas y el avanzado.
  static List<double> decodeGains(String json, int bandCount) {
    final decoded = jsonDecode(json);
    if (decoded is! List) return List<double>.filled(bandCount, 0);
    final values = decoded
        .map((value) => value is num ? value.toDouble() : 0.0)
        .toList(growable: true);
    if (values.length == bandCount) return values;
    if (values.length > bandCount) return values.sublist(0, bandCount);
    return [...values, ...List<double>.filled(bandCount - values.length, 0)];
  }
}
