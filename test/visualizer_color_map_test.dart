import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/player/visualizer_color_map.dart';

void main() {
  group('color aleatorio fluido', () {
    test('es determinista por canción y continuo entre fotogramas', () {
      final first = fluidRandomHueOffset(
        seed: 42,
        elapsedSeconds: 12,
        energy: 0.7,
        beatImpulse: 0.2,
      );
      final same = fluidRandomHueOffset(
        seed: 42,
        elapsedSeconds: 12,
        energy: 0.7,
        beatImpulse: 0.2,
      );
      final next = fluidRandomHueOffset(
        seed: 42,
        elapsedSeconds: 12.016,
        energy: 0.7,
        beatImpulse: 0.2,
      );
      final rawDistance = (next - first).abs();
      final circularDistance = rawDistance > 0.5
          ? 1 - rawDistance
          : rawDistance;

      expect(same, first);
      expect(circularDistance, lessThan(0.01));
    });
  });

  group('VisualizerColorMap.colorAt', () {
    test('devuelve el color exacto de cada parada', () {
      final map = VisualizerColorMap.defaults;
      for (final stop in map.stops) {
        expect(map.colorAt(stop.position), stop.color);
      }
    });

    test('interpola entre dos paradas sin saltos', () {
      final map = VisualizerColorMap(const [
        VisualizerColorStop(0, Color(0xFF000000)),
        VisualizerColorStop(1, Color(0xFFFFFFFF)),
      ]);
      final middle = map.colorAt(0.5);
      expect(middle.r, closeTo(0.5, 0.02));
      expect(middle.g, closeTo(0.5, 0.02));
      expect(middle.b, closeTo(0.5, 0.02));
    });

    test('una intensidad fuera de rango se sujeta a los extremos', () {
      final map = VisualizerColorMap.defaults;
      expect(map.colorAt(-3), map.stops.first.color);
      expect(map.colorAt(9), map.stops.last.color);
      expect(map.colorAt(double.nan), map.stops.first.color);
    });

    test('solo la intensidad alta alcanza el tramo de pico', () {
      final map = VisualizerColorMap.defaults;
      // El reparto pedido reserva el blanco al pico: una barra a media altura
      // no puede recibir el mismo color que una que llega al máximo.
      expect(map.colorAt(0.5), isNot(map.colorAt(1)));
      expect(map.colorAt(1), const Color(0xFFFFFFFF));
    });
  });

  group('normalización', () {
    test('las paradas quedan ordenadas por intensidad', () {
      final map = VisualizerColorMap(const [
        VisualizerColorStop(0.8, Color(0xFF00FF00)),
        VisualizerColorStop(0.1, Color(0xFFFF0000)),
        VisualizerColorStop(0.4, Color(0xFF0000FF)),
      ]);
      expect(
        map.stops.map((stop) => stop.position),
        orderedEquals(<double>[0.1, 0.4, 0.8]),
      );
    });

    test('una posición repetida conserva solo la primera', () {
      final map = VisualizerColorMap(const [
        VisualizerColorStop(0.5, Color(0xFFFF0000)),
        VisualizerColorStop(0.5, Color(0xFF00FF00)),
        VisualizerColorStop(1, Color(0xFF0000FF)),
      ]);
      expect(map.stops.length, 2);
      expect(map.colorAt(0.5), const Color(0xFFFF0000));
    });

    test('una lista vacía vuelve al reparto por defecto', () {
      expect(VisualizerColorMap(const []), VisualizerColorMap.defaults);
    });
  });

  group('edición', () {
    test('no se puede bajar del mínimo de paradas', () {
      final map = VisualizerColorMap(const [
        VisualizerColorStop(0, Color(0xFF000000)),
        VisualizerColorStop(1, Color(0xFFFFFFFF)),
      ]);
      expect(map.removeStop(0), map);
    });

    test('la posición sugerida cae en el hueco más ancho', () {
      final map = VisualizerColorMap(const [
        VisualizerColorStop(0, Color(0xFF000000)),
        VisualizerColorStop(0.1, Color(0xFF111111)),
        VisualizerColorStop(1, Color(0xFFFFFFFF)),
      ]);
      expect(map.suggestedPosition(), closeTo(0.55, 0.001));
    });

    test('el degradado cubre siempre de 0 a 1', () {
      final map = VisualizerColorMap(const [
        VisualizerColorStop(0.3, Color(0xFFFF0000)),
        VisualizerColorStop(0.6, Color(0xFF00FF00)),
      ]);
      final gradient = map.toGradient();
      expect(gradient.positions.first, 0);
      expect(gradient.positions.last, 1);
      expect(gradient.colors.length, gradient.positions.length);
    });
  });

  group('persistencia', () {
    test('sobrevive a una ida y vuelta por JSON', () {
      final original = VisualizerColorPreset.sunset.map;
      final restored = VisualizerColorMap.fromJsonString(
        original.toJsonString(),
      );
      expect(restored, original);
    });

    test('un JSON dañado vuelve al reparto por defecto', () {
      expect(
        VisualizerColorMap.fromJsonString('{no es json'),
        VisualizerColorMap.defaults,
      );
      expect(
        VisualizerColorMap.fromJsonString('{"p":0}'),
        VisualizerColorMap.defaults,
      );
      expect(
        VisualizerColorMap.fromJsonString(''),
        VisualizerColorMap.defaults,
      );
      expect(
        VisualizerColorMap.fromJsonString(null),
        VisualizerColorMap.defaults,
      );
    });

    test('una lista con una sola parada válida vuelve al defecto', () {
      expect(
        VisualizerColorMap.fromJsonString('[{"p":0.5,"c":4294901760}]'),
        VisualizerColorMap.defaults,
      );
    });
  });

  group('rampTo (modo por fila)', () {
    test('una barra baja solo llega a los colores bajos', () {
      final map = VisualizerColorMap.defaults;
      final ramp = map.rampTo(0.25);
      // Con el reparto por defecto, el 25 % es violeta: el naranja y el blanco
      // quedan fuera del alcance de una barra de esa altura.
      expect(ramp.colors, isNot(contains(const Color(0xFFFF8A00))));
      expect(ramp.colors, isNot(contains(const Color(0xFFFFFFFF))));
      expect(ramp.colors.last, const Color(0xFF7B61FF));
    });

    test('una barra al máximo atraviesa todo el mapa', () {
      final ramp = VisualizerColorMap.defaults.rampTo(1);
      expect(ramp.colors.first, const Color(0xFF00B4FF));
      expect(ramp.colors.last, const Color(0xFFFFFFFF));
      expect(ramp.colors.length, VisualizerColorMap.defaults.stops.length);
    });

    test('siempre cubre la longitud completa del elemento', () {
      for (final intensity in const [0.0, 0.03, 0.4, 0.77, 1.0]) {
        final ramp = VisualizerColorMap.defaults.rampTo(intensity);
        expect(ramp.positions.first, 0, reason: 'intensidad $intensity');
        expect(ramp.positions.last, 1, reason: 'intensidad $intensity');
        expect(ramp.colors.length, ramp.positions.length);
      }
    });

    test('las posiciones crecen de forma estricta', () {
      // Flutter lanza si un degradado recibe paradas que no crecen.
      for (final intensity in const [0.05, 0.25, 0.5, 0.9, 1.0]) {
        final ramp = VisualizerColorMap.defaults.rampTo(intensity);
        for (var index = 1; index < ramp.positions.length; index++) {
          expect(
            ramp.positions[index],
            greaterThan(ramp.positions[index - 1]),
            reason: 'intensidad $intensity, parada $index',
          );
        }
      }
    });
  });

  group('projectedOnto', () {
    test('respeta el tramo pedido y cubre de 0 a 1', () {
      final ramp = VisualizerColorMap.defaults.projectedOnto(0.4, 1);
      expect(ramp.positions.first, 0);
      expect(ramp.positions.last, 1);
      for (var index = 1; index < ramp.positions.length; index++) {
        expect(ramp.positions[index], greaterThan(ramp.positions[index - 1]));
      }
    });

    test('un tramo degenerado no rompe el degradado', () {
      final ramp = VisualizerColorMap.defaults.projectedOnto(0.8, 0.8);
      expect(ramp.positions, orderedEquals(<double>[0, 1]));
      expect(ramp.colors.length, 2);
    });
  });

  group('VisualizerColorMode', () {
    test('un identificador desconocido cae en «por fila»', () {
      expect(VisualizerColorMode.byId(null), VisualizerColorMode.row);
      expect(VisualizerColorMode.byId('otra-cosa'), VisualizerColorMode.row);
    });

    test('los identificadores guardados se conservan', () {
      for (final mode in VisualizerColorMode.values) {
        expect(VisualizerColorMode.byId(mode.id), mode);
      }
    });
  });

  test('cada prestablecido se reconoce a sí mismo', () {
    for (final preset in VisualizerColorPreset.values) {
      expect(VisualizerColorPreset.matching(preset.map), preset);
    }
  });
}
