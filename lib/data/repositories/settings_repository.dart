import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';

/// Preferencias de la aplicacion y carpetas configuradas
/// (requerimiento secciones 11 y 14).
class SettingsRepository {
  SettingsRepository(this._database);

  final NuvTuneDatabase _database;

  Stream<AppSetting> watchSettings() =>
      _database.select(_database.appSettings).watchSingleOrNull().asyncMap(
            (row) async => row ?? await _ensureRow(),
          );

  Future<AppSetting> settings() async {
    final row = await (_database.select(_database.appSettings)
          ..where((table) => table.id.equals(0)))
        .getSingleOrNull();
    return row ?? await _ensureRow();
  }

  /// Registra el momento del ultimo escaneo completo.
  Future<void> markScanned() =>
      update(AppSettingsCompanion(lastScanAt: Value(DateTime.now())));

  Future<void> update(AppSettingsCompanion companion) async {
    await _ensureRow();
    await (_database.update(_database.appSettings)
          ..where((table) => table.id.equals(0)))
        .write(companion);
  }

  Future<AppSetting> _ensureRow() async {
    final existing = await (_database.select(_database.appSettings)
          ..where((table) => table.id.equals(0)))
        .getSingleOrNull();
    if (existing != null) return existing;
    await _database
        .into(_database.appSettings)
        .insert(const AppSettingsCompanion(id: Value(0)));
    return (_database.select(_database.appSettings)
          ..where((table) => table.id.equals(0)))
        .getSingle();
  }

  // -- Carpetas excluidas (requerimiento 4.1) ------------------------------

  Stream<List<String>> watchExcludedFolders() =>
      (_database.select(_database.excludedFolders)
            ..orderBy([(table) => OrderingTerm(expression: table.path)]))
          .watch()
          .map((rows) => rows.map((row) => row.path).toList());

  Future<List<String>> excludedFolders() async {
    final rows = await _database.select(_database.excludedFolders).get();
    return rows.map((row) => row.path).toList();
  }

  Future<void> excludeFolder(String path) =>
      _database.into(_database.excludedFolders).insertOnConflictUpdate(
            ExcludedFoldersCompanion.insert(path: path),
          );

  Future<void> includeFolder(String path) =>
      (_database.delete(_database.excludedFolders)
            ..where((table) => table.path.equals(path)))
          .go();

  // -- Carpetas de origen concedidas por SAF (requerimiento 10) ------------

  Stream<List<SourceFolder>> watchSourceFolders() =>
      (_database.select(_database.sourceFolders)
            ..orderBy([(table) => OrderingTerm(expression: table.displayPath)]))
          .watch();

  Future<void> addSourceFolder(String uri, String displayPath) =>
      _database.into(_database.sourceFolders).insertOnConflictUpdate(
            SourceFoldersCompanion.insert(uri: uri, displayPath: displayPath),
          );

  Future<void> removeSourceFolder(String uri) =>
      (_database.delete(_database.sourceFolders)
            ..where((table) => table.uri.equals(uri)))
          .go();

  // -- Orden y filtro recordados por seccion (requerimiento 4.1) ----------

  Future<Map<String, dynamic>> librarySortState() async {
    final row = await settings();
    final decoded = jsonDecode(row.librarySortJson);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<void> saveLibrarySortState(Map<String, dynamic> state) =>
      update(AppSettingsCompanion(librarySortJson: Value(jsonEncode(state))));

  Future<List<String>> homeSections() async {
    final row = await settings();
    final decoded = jsonDecode(row.homeSectionsJson);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }

  Future<void> saveHomeSections(List<String> sections) =>
      update(AppSettingsCompanion(homeSectionsJson: Value(jsonEncode(sections))));
}
