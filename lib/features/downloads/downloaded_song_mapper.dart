import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';

/// Convierte una [DownloadedSong] en el [Song] del contrato pigeon para que
/// pueda entrar a la cola de reproduccion igual que cualquier otra cancion.
///
/// El id es negativo (hash de la ruta) porque los ids de MediaStore siempre
/// son positivos: así nunca chocan con una canción real de la biblioteca.
extension DownloadedSongMapping on DownloadedSong {
  Song toSong() {
    final syntheticId = -(filePath.hashCode.abs());
    final downloadedAtSeconds = downloadedAt.millisecondsSinceEpoch ~/ 1000;
    final lastSlash = filePath.lastIndexOf('/');

    return Song(
      id: syntheticId,
      uri: Uri.file(filePath).toString(),
      filePath: filePath,
      title: title,
      artist: artist,
      artistId: syntheticId,
      album: album ?? 'Descargas',
      albumId: syntheticId,
      durationMs: durationMs,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      dateAdded: downloadedAtSeconds,
      dateModified: downloadedAtSeconds,
      folderPath: lastSlash < 0 ? filePath : filePath.substring(0, lastSlash),
      folderName: 'Descargas',
      hasCover: coverPath != null,
      isSupported: true,
    );
  }
}
