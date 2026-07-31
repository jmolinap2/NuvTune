import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';

/// Estado de la cadena de mejora de audio, perfiles por salida y analisis de
/// sonoridad (requerimiento secciones 5.1, 5.2, 5.4 y 14).
class EnhancementRepository {
  EnhancementRepository(this._database);

  final NuvTuneDatabase _database;

  // -- Estado global -------------------------------------------------------

  Stream<EnhancementStateData> watchState() =>
      _database.select(_database.enhancementState).watchSingleOrNull().asyncMap(
            (row) async => row ?? await _ensureRow(),
          );

  Future<EnhancementStateData> state() async {
    final row = await (_database.select(_database.enhancementState)
          ..where((table) => table.id.equals(0)))
        .getSingleOrNull();
    return row ?? await _ensureRow();
  }

  /// Traduce la fila a los ajustes del motor. [trackGainDb] llega del analisis
  /// de la pista actual y solo lo usa el modo de normalizacion por analisis.
  Future<EnhancementSettings> engineSettings({double trackGainDb = 0}) async {
    final row = await state();
    return EnhancementSettings(
      enabled: row.enabled,
      profile: EnhancementProfile.values[row.profileIndex],
      detail: DetailLevel.values[row.detailIndex],
      multibandStrength: row.multibandStrength,
      normalization: NormalizationMode.values[row.normalizationIndex],
      targetLevelDb: row.targetLevelDb,
      stereoExpansionEnabled: row.stereoExpansionEnabled,
      stereoWidth: row.stereoWidth,
      trackGainDb: trackGainDb,
    );
  }

  Future<void> save({
    bool? enabled,
    EnhancementProfile? profile,
    DetailLevel? detail,
    double? multibandStrength,
    NormalizationMode? normalization,
    double? targetLevelDb,
    bool? stereoExpansionEnabled,
    double? stereoWidth,
  }) async {
    await _ensureRow();
    await (_database.update(_database.enhancementState)
          ..where((table) => table.id.equals(0)))
        .write(
      EnhancementStateCompanion(
        enabled: enabled == null ? const Value.absent() : Value(enabled),
        profileIndex:
            profile == null ? const Value.absent() : Value(profile.index),
        detailIndex: detail == null ? const Value.absent() : Value(detail.index),
        multibandStrength: multibandStrength == null
            ? const Value.absent()
            : Value(multibandStrength),
        normalizationIndex: normalization == null
            ? const Value.absent()
            : Value(normalization.index),
        targetLevelDb:
            targetLevelDb == null ? const Value.absent() : Value(targetLevelDb),
        stereoExpansionEnabled: stereoExpansionEnabled == null
            ? const Value.absent()
            : Value(stereoExpansionEnabled),
        stereoWidth:
            stereoWidth == null ? const Value.absent() : Value(stereoWidth),
      ),
    );
  }

  Future<EnhancementStateData> _ensureRow() async {
    final existing = await (_database.select(_database.enhancementState)
          ..where((table) => table.id.equals(0)))
        .getSingleOrNull();
    if (existing != null) return existing;
    await _database
        .into(_database.enhancementState)
        .insert(const EnhancementStateCompanion(id: Value(0)));
    return (_database.select(_database.enhancementState)
          ..where((table) => table.id.equals(0)))
        .getSingle();
  }

  // -- Perfiles por salida (requerimiento 5.4) -----------------------------

  Stream<Map<int, OutputProfile>> watchOutputProfiles() =>
      _database.select(_database.outputProfiles).watch().map(
            (rows) => {for (final row in rows) row.outputIndex: row},
          );

  Future<OutputProfile?> profileFor(AudioOutput output) =>
      (_database.select(_database.outputProfiles)
            ..where((table) => table.outputIndex.equals(output.index)))
          .getSingleOrNull();

  /// Guarda la configuracion actual como perfil de una salida concreta.
  Future<void> saveOutputProfile({
    required AudioOutput output,
    required int bandCount,
    required List<double> gains,
    required String presetName,
    required double preampDb,
    required EnhancementProfile profile,
    required bool enhancementEnabled,
  }) =>
      _database.into(_database.outputProfiles).insertOnConflictUpdate(
            OutputProfilesCompanion.insert(
              outputIndex: Value(output.index),
              bandCount: Value(bandCount),
              gainsJson: Value(jsonEncode(gains)),
              presetName: Value(presetName),
              preampDb: Value(preampDb),
              profileIndex: Value(profile.index),
              enhancementEnabled: Value(enhancementEnabled),
            ),
          );

  Future<void> deleteOutputProfile(AudioOutput output) =>
      (_database.delete(_database.outputProfiles)
            ..where((table) => table.outputIndex.equals(output.index)))
          .go();

  // -- Analisis de sonoridad (requerimiento 5.2) ---------------------------

  Future<LoudnessAnalyse?> analysisFor(int songId) =>
      (_database.select(_database.loudnessAnalyses)
            ..where((table) => table.songId.equals(songId)))
          .getSingleOrNull();

  Future<void> saveAnalysis(LoudnessAnalysis analysis) =>
      _database.into(_database.loudnessAnalyses).insertOnConflictUpdate(
            LoudnessAnalysesCompanion.insert(
              songId: Value(analysis.songId),
              gainDb: analysis.gainDb,
              peak: analysis.peak,
            ),
          );

  Future<int> analyzedCount() async {
    final rows = await _database.select(_database.loudnessAnalyses).get();
    return rows.length;
  }

  Future<void> clearAnalyses() =>
      _database.delete(_database.loudnessAnalyses).go();

  /// Identificadores ya analizados, para no repetir trabajo caro.
  Future<Set<int>> analyzedIds() async {
    final rows = await _database.select(_database.loudnessAnalyses).get();
    return rows.map((row) => row.songId).toSet();
  }
}
