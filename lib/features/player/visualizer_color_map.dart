import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// Desplazamiento cromático continuo y determinista para una canción.
/// Combina ondas inconmensurables: parece aleatorio, pero nunca salta entre
/// fotogramas ni cambia al reconstruir el widget.
double fluidRandomHueOffset({
  required int seed,
  required double elapsedSeconds,
  required double energy,
  required double beatImpulse,
}) {
  final seedPhase = (seed.abs() % 4096) / 4096 * math.pi * 2;
  final speed = 0.10 + energy.clamp(0.0, 1.0) * 0.12;
  final time = elapsedSeconds * speed;
  final wave =
      math.sin(time + seedPhase) * 0.31 +
      math.sin(time * 0.618 + seedPhase * 1.7) * 0.19 +
      math.sin(time * 1.414 - seedPhase * 0.73) * 0.08;
  return (0.5 + wave + beatImpulse.clamp(0.0, 1.0) * 0.025) % 1.0;
}

Color rotateVisualizerHue(Color color, double offset) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withHue((hsl.hue + offset * 360) % 360).toColor();
}

/// Cómo se reparte el mapa sobre cada elemento del visualizador.
///
/// Es una decisión de lectura, no de paleta: los mismos colores cuentan cosas
/// distintas según se apliquen a lo largo del elemento o a todo el elemento.
enum VisualizerColorMode {
  /// Cada nivel de altura tiene su color. Una barra baja solo muestra los
  /// colores bajos; una alta los atraviesa todos y remata en el del pico.
  /// Es el aspecto clásico del ecualizador de LEDs.
  row('row', 'Por fila', 'Cada nivel de altura tiene su color'),

  /// Toda la barra toma un único color, el que corresponde a la intensidad
  /// que alcanza. Así solo las columnas que llegan a cierta fuerza muestran
  /// el color de esa fuerza.
  column(
    'column',
    'Por columna',
    'Cada barra toma un solo color según su fuerza',
  );

  const VisualizerColorMode(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  static VisualizerColorMode byId(String? id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => VisualizerColorMode.row,
  );
}

/// Una parada del mapa de colores: a partir de qué intensidad manda este color.
///
/// [position] es la intensidad normalizada (0 = silencio, 1 = pico), no una
/// coordenada de pantalla. Esa distinción es la razón de existir del mapa: el
/// color de un elemento depende de la fuerza que alcanza, así que solo las
/// barras que llegan a cierta altura toman el color de esa altura.
@immutable
class VisualizerColorStop implements Comparable<VisualizerColorStop> {
  const VisualizerColorStop(this.position, this.color);

  final double position;
  final Color color;

  VisualizerColorStop copyWith({double? position, Color? color}) =>
      VisualizerColorStop(position ?? this.position, color ?? this.color);

  @override
  int compareTo(VisualizerColorStop other) =>
      position.compareTo(other.position);

  @override
  bool operator ==(Object other) =>
      other is VisualizerColorStop &&
      other.position == position &&
      other.color.toARGB32() == color.toARGB32();

  @override
  int get hashCode => Object.hash(position, color.toARGB32());
}

/// Traducción de intensidad musical a color, compartida por todos los estilos.
///
/// Es la única definición cromática del visualizador: barras, anillos, ondas,
/// partículas y picos consultan este mapa con su propia intensidad, de modo
/// que un mismo valor produce el mismo color en cualquier estilo.
@immutable
class VisualizerColorMap {
  /// Ordena y deduplica: [colorAt] recorre las paradas asumiendo orden
  /// ascendente, y dos paradas en la misma posición harían indefinido cuál
  /// gana.
  factory VisualizerColorMap(Iterable<VisualizerColorStop> stops) {
    final sorted = <VisualizerColorStop>[];
    final seen = <double>{};
    for (final stop in stops) {
      final position = stop.position.clamp(0.0, 1.0).toDouble();
      if (!position.isFinite || !seen.add(position)) continue;
      sorted.add(VisualizerColorStop(position, stop.color));
    }
    if (sorted.isEmpty) return defaults;
    sorted.sort();
    return VisualizerColorMap._(List.unmodifiable(sorted));
  }

  const VisualizerColorMap._(this.stops);

  final List<VisualizerColorStop> stops;

  /// Mínimo y máximo de paradas. El mínimo evita un mapa vacío sin color; el
  /// máximo mantiene la lista editable a mano y el degradado legible.
  static const int minStops = 2;
  static const int maxStops = 12;

  /// Reparto por defecto: los tramos que pidió el producto —azul/cian hasta
  /// 25 %, violeta hasta 50 %, magenta/rosa hasta 75 %, naranja cálido hasta
  /// 90 % y casi blanco reservado al pico.
  static final VisualizerColorMap defaults = VisualizerColorMap._(
    List.unmodifiable(const [
      VisualizerColorStop(0.00, Color(0xFF00B4FF)),
      VisualizerColorStop(0.25, Color(0xFF7B61FF)),
      VisualizerColorStop(0.50, Color(0xFFFF2DB7)),
      VisualizerColorStop(0.75, Color(0xFFFF8A00)),
      VisualizerColorStop(0.90, Color(0xFFFFC1FF)),
      VisualizerColorStop(1.00, Color(0xFFFFFFFF)),
    ]),
  );

  /// Color correspondiente a una intensidad normalizada, interpolado entre las
  /// dos paradas que la rodean para que no existan saltos bruscos.
  Color colorAt(double intensity) {
    final value = intensity.isFinite
        ? intensity.clamp(0.0, 1.0).toDouble()
        : 0.0;
    if (stops.length == 1 || value <= stops.first.position) {
      return stops.first.color;
    }
    if (value >= stops.last.position) return stops.last.color;
    for (var index = 0; index < stops.length - 1; index++) {
      final lower = stops[index];
      final upper = stops[index + 1];
      if (value > upper.position) continue;
      final span = upper.position - lower.position;
      final t = span <= 0 ? 0.0 : (value - lower.position) / span;
      return Color.lerp(lower.color, upper.color, t)!;
    }
    return stops.last.color;
  }

  /// Paradas listas para un [LinearGradient]: `stops` exige valores
  /// estrictamente crecientes que empiecen en 0 y terminen en 1.
  ({List<Color> colors, List<double> positions}) toGradient() {
    final colors = <Color>[];
    final positions = <double>[];
    if (stops.first.position > 0) {
      colors.add(stops.first.color);
      positions.add(0);
    }
    for (final stop in stops) {
      colors.add(stop.color);
      positions.add(stop.position);
    }
    if (stops.last.position < 1) {
      colors.add(stops.last.color);
      positions.add(1);
    }
    return (colors: colors, positions: positions);
  }

  /// Paradas proyectadas sobre el tramo `[start, end]` de un degradado, con
  /// los extremos prolongados hasta 0 y 1.
  ///
  /// Sirve para el modo «por fila»: el degradado no empieza en el borde del
  /// lienzo sino donde nace el elemento (la línea base de las barras, el aro
  /// del motivo radial), y termina donde llegaría una intensidad del 100 %.
  ({List<Color> colors, List<double> positions}) projectedOnto(
    double start,
    double end,
  ) {
    final from = start.clamp(0.0, 1.0).toDouble();
    final to = end.clamp(0.0, 1.0).toDouble();
    final span = to - from;
    if (span <= 0) {
      return (colors: [stops.first.color, stops.last.color], positions: [0, 1]);
    }
    final colors = <Color>[];
    final positions = <double>[];
    if (from > 0) {
      colors.add(stops.first.color);
      positions.add(0);
    }
    for (final stop in stops) {
      final projected = from + stop.position * span;
      // Una parada proyectada nunca puede retroceder: `stops` de un degradado
      // debe crecer de forma monótona o Flutter lanza.
      if (positions.isNotEmpty && projected <= positions.last) continue;
      colors.add(stop.color);
      positions.add(projected);
    }
    if (positions.last < 1) {
      colors.add(stops.last.color);
      positions.add(1);
    }
    return (colors: colors, positions: positions);
  }

  /// Colores que llega a mostrar un elemento cuya intensidad máxima es
  /// [intensity], repartidos sobre su propia longitud (0 = base, 1 = punta).
  ///
  /// Es el modo «por fila» visto desde un solo elemento: una barra baja
  /// devuelve únicamente los colores bajos del mapa, y solo una que llega al
  /// 100 % alcanza el color reservado al pico.
  ({List<Color> colors, List<double> positions}) rampTo(double intensity) {
    final top = intensity.isFinite ? intensity.clamp(0.0, 1.0).toDouble() : 0.0;
    if (top <= 0) {
      return (
        colors: [stops.first.color, stops.first.color],
        positions: [0, 1],
      );
    }
    final colors = <Color>[];
    final positions = <double>[];
    for (final stop in stops) {
      if (stop.position > top) break;
      final projected = stop.position / top;
      if (positions.isNotEmpty && projected <= positions.last) continue;
      colors.add(stop.color);
      positions.add(projected);
    }
    if (positions.isEmpty) {
      colors.add(stops.first.color);
      positions.add(0);
    }
    if (positions.last < 1) {
      colors.add(colorAt(top));
      positions.add(1);
    }
    return (colors: colors, positions: positions);
  }

  VisualizerColorMap withStop(VisualizerColorStop stop) =>
      VisualizerColorMap([...stops, stop]);

  VisualizerColorMap replaceStop(int index, VisualizerColorStop stop) {
    final next = [...stops];
    next[index] = stop;
    return VisualizerColorMap(next);
  }

  VisualizerColorMap removeStop(int index) {
    if (stops.length <= minStops) return this;
    final next = [...stops]..removeAt(index);
    return VisualizerColorMap(next);
  }

  /// Posición libre más amplia, para que "añadir color" caiga en el hueco
  /// mayor en vez de encimarse a una parada existente.
  double suggestedPosition() {
    if (stops.length < 2) return 0.5;
    var bestGap = -1.0;
    var best = 0.5;
    for (var index = 0; index < stops.length - 1; index++) {
      final gap = stops[index + 1].position - stops[index].position;
      if (gap > bestGap) {
        bestGap = gap;
        best = (stops[index].position + stops[index + 1].position) / 2;
      }
    }
    return double.parse(best.toStringAsFixed(2));
  }

  String toJsonString() => jsonEncode([
    for (final stop in stops)
      {
        'p': double.parse(stop.position.toStringAsFixed(4)),
        'c': stop.color.toARGB32(),
      },
  ]);

  /// Una preferencia dañada o de una versión anterior vuelve al reparto por
  /// defecto en vez de dejar el visualizador sin color.
  static VisualizerColorMap fromJsonString(String? source) {
    if (source == null || source.trim().isEmpty) return defaults;
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (decoded is! List) return defaults;
    final stops = <VisualizerColorStop>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final position = entry['p'];
      final color = entry['c'];
      if (position is! num || color is! num) continue;
      stops.add(VisualizerColorStop(position.toDouble(), Color(color.toInt())));
    }
    if (stops.length < minStops) return defaults;
    return VisualizerColorMap(stops.take(maxStops));
  }

  @override
  bool operator ==(Object other) =>
      other is VisualizerColorMap && listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hashAll(stops);
}

/// Repartos listos para usar. `custom` no aparece aquí: es el estado en el que
/// queda el mapa cuando el usuario edita cualquier parada.
enum VisualizerColorPreset {
  aurora('aurora', 'Aurora'),
  sunset('sunset', 'Atardecer'),
  ice('ice', 'Hielo'),
  ember('ember', 'Brasa');

  const VisualizerColorPreset(this.id, this.label);

  final String id;
  final String label;

  VisualizerColorMap get map => switch (this) {
    VisualizerColorPreset.aurora => VisualizerColorMap.defaults,
    VisualizerColorPreset.sunset => VisualizerColorMap(const [
      VisualizerColorStop(0.00, Color(0xFF2B1B5A)),
      VisualizerColorStop(0.30, Color(0xFF9B3DCA)),
      VisualizerColorStop(0.60, Color(0xFFFF5C7A)),
      VisualizerColorStop(0.85, Color(0xFFFFA23A)),
      VisualizerColorStop(1.00, Color(0xFFFFF3C4)),
    ]),
    VisualizerColorPreset.ice => VisualizerColorMap(const [
      VisualizerColorStop(0.00, Color(0xFF06254A)),
      VisualizerColorStop(0.35, Color(0xFF1E8FD5)),
      VisualizerColorStop(0.70, Color(0xFF57E0F0)),
      VisualizerColorStop(1.00, Color(0xFFF2FEFF)),
    ]),
    VisualizerColorPreset.ember => VisualizerColorMap(const [
      VisualizerColorStop(0.00, Color(0xFF2A0A0A)),
      VisualizerColorStop(0.30, Color(0xFFB02A1E)),
      VisualizerColorStop(0.65, Color(0xFFFF7A18)),
      VisualizerColorStop(0.88, Color(0xFFFFD24A)),
      VisualizerColorStop(1.00, Color(0xFFFFFDF2)),
    ]),
  };

  static VisualizerColorPreset? matching(VisualizerColorMap map) {
    for (final preset in values) {
      if (preset.map == map) return preset;
    }
    return null;
  }
}
