import 'package:intl/intl.dart';

/// Formatos de duracion, tamano y fecha que usan varias pantallas.
abstract final class Formatters {
  static String duration(int milliseconds) {
    if (milliseconds <= 0) return '0:00';
    final totalSeconds = milliseconds ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
    }
    return '$minutes:$paddedSeconds';
  }

  /// Duracion larga en palabras, para totales de listas.
  static String durationVerbose(int milliseconds) {
    final totalMinutes = milliseconds ~/ 60000;
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB'];
    var value = bytes / 1024;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}';
  }

  static String bitrate(int? bitsPerSecond) {
    if (bitsPerSecond == null || bitsPerSecond <= 0) return 'No disponible';
    return '${(bitsPerSecond / 1000).round()} kbps';
  }

  static String sampleRate(int? hertz) {
    if (hertz == null || hertz <= 0) return 'No disponible';
    final kilohertz = hertz / 1000;
    final text = kilohertz == kilohertz.roundToDouble()
        ? kilohertz.round().toString()
        : kilohertz.toStringAsFixed(1);
    return '$text kHz';
  }

  static String bitDepth(int? bits) =>
      bits == null || bits <= 0 ? 'No disponible' : '$bits bits';

  static String channels(int? count) => switch (count) {
    1 => 'Mono',
    2 => 'Estéreo',
    null => 'No disponible',
    _ => '$count canales',
  };

  /// Segundos epoch de MediaStore a fecha legible.
  static String epochDate(int epochSeconds) {
    if (epochSeconds <= 0) return 'Desconocida';
    final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return DateFormat('d MMM y', 'es').format(date);
  }

  static String dateTime(DateTime value) =>
      DateFormat('d MMM y, HH:mm', 'es').format(value);

  static String trackCount(int count) =>
      count == 1 ? '1 canción' : '$count canciones';

  static String albumCount(int count) =>
      count == 1 ? '1 álbum' : '$count álbumes';

  static String gainDb(double value) {
    final rounded = (value * 10).round() / 10;
    final sign = rounded > 0 ? '+' : '';
    return '$sign${rounded.toStringAsFixed(1)} dB';
  }

  static String frequency(double hertz) {
    if (hertz >= 1000) {
      final kilohertz = hertz / 1000;
      final text = kilohertz == kilohertz.roundToDouble()
          ? kilohertz.round().toString()
          : kilohertz.toStringAsFixed(1);
      return '${text}k';
    }
    return hertz == hertz.roundToDouble()
        ? hertz.round().toString()
        : hertz.toStringAsFixed(1);
  }

  static String speed(double value) => '${value.toStringAsFixed(2)}x';

  /// Marca de tiempo de un archivo LRC.
  static String lrcTimestamp(int milliseconds) {
    final minutes = milliseconds ~/ 60000;
    final seconds = (milliseconds % 60000) / 1000;
    return '[${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toStringAsFixed(2).padLeft(5, '0')}]';
  }
}
