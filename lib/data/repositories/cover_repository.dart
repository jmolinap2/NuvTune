import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Portadas que la aplicacion guarda por su cuenta, sin tocar el archivo de
/// audio (requerimiento seccion 7.2).
///
/// La aplicacion distingue tres origenes de portada:
///  - Incrustada en la cancion, que resuelve el motor.
///  - Personalizada solo de la aplicacion, que gestiona este repositorio.
///  - General del album, tambien aqui, aplicada a todas sus canciones.
class CoverRepository {
  CoverRepository(this._database);

  final NuvTuneDatabase _database;

  Directory? _directory;

  Future<Directory> _coversDirectory() async {
    final cached = _directory;
    if (cached != null) return cached;
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'covers'));
    await directory.create(recursive: true);
    _directory = directory;
    return directory;
  }

  static String songTarget(int songId) => 'song:$songId';

  static String albumTarget(int albumId) => 'álbum:$albumId';

  Stream<Map<String, String>> watchCustomCovers() =>
      _database.select(_database.customCovers).watch().map(
            (rows) => {for (final row in rows) row.target: row.imagePath},
          );

  Future<Map<String, String>> customCovers() async {
    final rows = await _database.select(_database.customCovers).get();
    return {for (final row in rows) row.target: row.imagePath};
  }

  /// Ruta de la portada personalizada aplicable a una cancion. La portada
  /// propia de la cancion tiene prioridad sobre la del album.
  Future<String?> resolvePath({required int songId, required int albumId}) async {
    final rows = await (_database.select(_database.customCovers)
          ..where(
            (table) => table.target.isIn([songTarget(songId), albumTarget(albumId)]),
          ))
        .get();
    if (rows.isEmpty) return null;
    final bySong = rows.firstWhereOrNullTarget(songTarget(songId));
    return bySong ?? rows.first.imagePath;
  }

  Future<String> saveCover(String target, Uint8List bytes) async {
    final directory = await _coversDirectory();
    final safeName = target.replaceAll(':', '_');
    // Se escribe con un nombre nuevo en cada guardado para que Flutter no sirva
    // la imagen anterior desde su cache de imagenes.
    final file = File(
      p.join(directory.path, '$safeName-${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );
    await file.writeAsBytes(bytes, flush: true);

    final previous = await (_database.select(_database.customCovers)
          ..where((table) => table.target.equals(target)))
        .getSingleOrNull();

    await _database.into(_database.customCovers).insertOnConflictUpdate(
          CustomCoversCompanion.insert(target: target, imagePath: file.path),
        );

    if (previous != null && previous.imagePath != file.path) {
      final oldFile = File(previous.imagePath);
      if (oldFile.existsSync()) {
        await oldFile.delete();
      }
    }

    return file.path;
  }

  Future<void> removeCover(String target) async {
    final row = await (_database.select(_database.customCovers)
          ..where((table) => table.target.equals(target)))
        .getSingleOrNull();
    if (row == null) return;
    final file = File(row.imagePath);
    if (file.existsSync()) {
      await file.delete();
    }
    await (_database.delete(_database.customCovers)
          ..where((table) => table.target.equals(target)))
        .go();
  }

  /// Portada elegida para una lista de reproduccion.
  Future<String> savePlaylistCover(int playlistId, Uint8List bytes) =>
      saveCover('playlist:$playlistId', bytes);
}

extension on List<CustomCover> {
  String? firstWhereOrNullTarget(String target) {
    for (final row in this) {
      if (row.target == target) return row.imagePath;
    }
    return null;
  }
}
