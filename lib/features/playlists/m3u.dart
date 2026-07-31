import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Lectura y escritura de listas M3U extendidas (requerimiento seccion 4.4).
abstract final class M3u {
  static const header = '#EXTM3U';

  /// Genera un M3U extendido. Se escriben rutas absolutas porque es lo que
  /// entienden el resto de reproductores del dispositivo.
  static String write(String playlistName, List<Song> songs) {
    final lines = <String>[header, '#PLAYLIST:$playlistName'];
    for (final song in songs) {
      final seconds = (song.durationMs / 1000).round();
      lines.add('#EXTINF:$seconds,${song.artist} - ${song.title}');
      lines.add(song.filePath);
    }
    return '${lines.join('\n')}\n';
  }

  /// Listado legible para compartir como texto (requerimiento 4.4).
  static String plainListing(String playlistName, List<Song> songs) {
    final lines = <String>[playlistName, ''];
    for (var index = 0; index < songs.length; index++) {
      final song = songs[index];
      lines.add('${index + 1}. ${song.artist} - ${song.title}');
    }
    return lines.join('\n');
  }

  /// Resultado de importar un M3U: canciones que se pudieron emparejar con la
  /// biblioteca y rutas que no existen en el dispositivo.
  static M3uImport parse(String content, List<Song> library) {
    final byPath = <String, Song>{
      for (final song in library) _normalize(song.filePath): song,
    };
    final byFileName = <String, Song>{
      for (final song in library) _fileNameOf(song.filePath): song,
    };

    final matched = <Song>[];
    final missing = <String>[];
    String? name;

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#')) {
        if (line.startsWith('#PLAYLIST:')) {
          name = line.substring('#PLAYLIST:'.length).trim();
        }
        continue;
      }

      // Las rutas remotas quedan fuera del alcance: las fuentes de red son de
      // una fase posterior y no deben mezclarse con la biblioteca local
      // (requerimiento seccion 10).
      if (line.startsWith('http://') ||
          line.startsWith('https://') ||
          line.startsWith('smb://')) {
        missing.add(line);
        continue;
      }

      final song = byPath[_normalize(line)] ?? byFileName[_fileNameOf(line)];
      if (song != null) {
        matched.add(song);
      } else {
        missing.add(line);
      }
    }

    return M3uImport(name: name, songs: matched, missingEntries: missing);
  }

  static String _normalize(String path) =>
      path.replaceAll(r'\', '/').toLowerCase();

  static String _fileNameOf(String path) =>
      _normalize(path).split('/').last;
}

class M3uImport {
  const M3uImport({
    required this.name,
    required this.songs,
    required this.missingEntries,
  });

  final String? name;
  final List<Song> songs;
  final List<String> missingEntries;

  bool get isEmpty => songs.isEmpty;
}
