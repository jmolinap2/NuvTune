/// Una linea de letra con su marca de tiempo, si la tiene.
class LyricLine {
  const LyricLine({required this.timeMs, required this.text, this.translation});

  /// null cuando la letra no esta sincronizada.
  final int? timeMs;
  final String text;

  /// Segunda linea de traduccion, cuando el archivo la trae
  /// (requerimiento seccion 8).
  final String? translation;
}

class ParsedLyrics {
  const ParsedLyrics({
    required this.lines,
    required this.synchronized,
    this.offsetMs = 0,
  });

  final List<LyricLine> lines;
  final bool synchronized;

  /// Desfase declarado en el propio archivo con la etiqueta `[offset:]`.
  final int offsetMs;

  bool get isEmpty => lines.isEmpty;

  static const empty = ParsedLyrics(lines: [], synchronized: false);
}

/// Lector de archivos LRC (requerimiento seccion 8).
///
/// Admite varias marcas de tiempo en una misma linea, la etiqueta `[offset:]` y
/// lineas de traduccion, que en los LRC bilingues aparecen como una segunda
/// entrada con la misma marca de tiempo.
abstract final class LrcParser {
  static final _timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
  static final _metaTag = RegExp(r'^\[([a-zA-Z]+):(.*)\]$');

  static ParsedLyrics parse(String content) {
    if (content.trim().isEmpty) return ParsedLyrics.empty;

    var offsetMs = 0;
    final timed = <int, List<String>>{};
    final plain = <String>[];

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final meta = _metaTag.firstMatch(line);
      if (meta != null && _timeTag.firstMatch(line) == null) {
        if (meta.group(1)!.toLowerCase() == 'offset') {
          offsetMs = int.tryParse(meta.group(2)!.trim()) ?? 0;
        }
        continue;
      }

      final matches = _timeTag.allMatches(line).toList();
      if (matches.isEmpty) {
        plain.add(line);
        continue;
      }

      final text = line.replaceAll(_timeTag, '').trim();
      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final fraction = match.group(3);
        final fractionMs = fraction == null
            ? 0
            : int.parse(fraction.padRight(3, '0').substring(0, 3));
        final timeMs = minutes * 60000 + seconds * 1000 + fractionMs;
        timed.putIfAbsent(timeMs, () => <String>[]).add(text);
      }
    }

    if (timed.isEmpty) {
      return ParsedLyrics(
        lines: plain.map((text) => LyricLine(timeMs: null, text: text)).toList(),
        synchronized: false,
      );
    }

    final timestamps = timed.keys.toList()..sort();
    final lines = <LyricLine>[];
    for (final timeMs in timestamps) {
      final texts = timed[timeMs]!.where((text) => text.isNotEmpty).toList();
      if (texts.isEmpty) {
        // Una marca sin texto es una pausa instrumental; se conserva para que
        // el desplazamiento automatico no salte hacia adelante.
        lines.add(LyricLine(timeMs: timeMs, text: ''));
        continue;
      }
      lines.add(
        LyricLine(
          timeMs: timeMs,
          text: texts.first,
          translation: texts.length > 1 ? texts[1] : null,
        ),
      );
    }

    return ParsedLyrics(
      lines: lines,
      synchronized: true,
      offsetMs: offsetMs,
    );
  }

  /// Indice de la linea que corresponde a [positionMs], o -1 si aun no empieza.
  static int activeLineIndex(
    ParsedLyrics lyrics,
    int positionMs, {
    int extraOffsetMs = 0,
  }) {
    if (!lyrics.synchronized) return -1;
    final target = positionMs - lyrics.offsetMs - extraOffsetMs;
    var result = -1;
    for (var index = 0; index < lyrics.lines.length; index++) {
      final timeMs = lyrics.lines[index].timeMs;
      if (timeMs == null || timeMs > target) break;
      result = index;
    }
    return result;
  }

  /// Convierte lineas sincronizadas de vuelta a formato LRC, para guardarlas.
  static String write(ParsedLyrics lyrics) {
    final buffer = StringBuffer();
    if (lyrics.offsetMs != 0) {
      buffer.writeln('[offset:${lyrics.offsetMs}]');
    }
    for (final line in lyrics.lines) {
      final timeMs = line.timeMs;
      if (timeMs == null) {
        buffer.writeln(line.text);
        continue;
      }
      final minutes = timeMs ~/ 60000;
      final seconds = (timeMs % 60000) / 1000;
      final stamp = '[${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toStringAsFixed(2).padLeft(5, '0')}]';
      buffer.writeln('$stamp${line.text}');
      if (line.translation != null) {
        buffer.writeln('$stamp${line.translation}');
      }
    }
    return buffer.toString();
  }
}
