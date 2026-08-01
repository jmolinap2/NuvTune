import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:nuvtune/core/network/piped_client.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:path_provider/path_provider.dart';

/// Canciones descargadas desde internet (feature "buscar y descargar
/// canciones"). Piped da la URL directa del stream de audio; se guarda en
/// `getApplicationDocumentsDirectory()/downloads/`, fuera de MediaStore.
///
/// La descarga corre en el isolate normal de Dart: es trabajo de E/S, no de
/// CPU, asi que ya no bloquea la interfaz sin necesidad de un Isolate aparte
/// (que además complicaria reportar el progreso).
class DownloadRepository {
  DownloadRepository(this._database, this._piped);

  final NuvTuneDatabase _database;
  final PipedClient _piped;

  Stream<List<DownloadedSong>> watchDownloads() =>
      (_database.select(_database.downloadedSongs)
            ..orderBy([(table) => OrderingTerm.desc(table.downloadedAt)]))
          .watch();

  Future<void> downloadFromVideoId(
    String videoId, {
    required String title,
    required String artist,
    String? album,
    void Function(int percent)? onProgress,
  }) async {
    final streams = await _piped.streamsOf(videoId);
    final audio = streams?.bestAudio;
    if (audio == null) {
      throw StateError('No se encontró audio descargable para "$title"');
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/downloads');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final fileName =
        '${_slug(title)}-${DateTime.now().millisecondsSinceEpoch}.${_extensionFor(audio.mimeType)}';
    final file = File('${directory.path}/$fileName');

    final request = http.Request('GET', Uri.parse(audio.url));
    final client = http.Client();
    try {
      final response = await client.send(request);
      final total = response.contentLength ?? 0;
      var received = 0;

      final sink = file.openWrite();
      await response.stream.map((chunk) {
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(((received / total) * 100).clamp(0, 100).round());
        }
        return chunk;
      }).pipe(sink);
      await sink.close();
    } finally {
      client.close();
    }

    await _database.into(_database.downloadedSongs).insert(
          DownloadedSongsCompanion.insert(
            title: title,
            artist: artist,
            album: Value(album),
            filePath: file.path,
            mimeType: Value(audio.mimeType),
            sizeBytes: Value(await file.length()),
            sourceVideoId: Value(videoId),
          ),
        );
  }

  Future<void> delete(int id) async {
    final row = await (_database.select(_database.downloadedSongs)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    await (_database.delete(_database.downloadedSongs)
          ..where((table) => table.id.equals(id)))
        .go();

    final file = File(row.filePath);
    if (file.existsSync()) file.deleteSync();
    final coverPath = row.coverPath;
    if (coverPath != null) {
      final cover = File(coverPath);
      if (cover.existsSync()) cover.deleteSync();
    }
  }

  static String _extensionFor(String mimeType) {
    if (mimeType.contains('webm')) return 'webm';
    return 'm4a';
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'cancion' : slug;
  }
}
