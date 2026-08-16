import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/navigation/app_router.dart';

/// Comprueba el árbol de Ajustes propuesto en la auditoría de reorganización:
/// que cada destino exista y que los accesos directos antiguos sigan llevando
/// a algún sitio en vez de romperse.
void main() {
  final router = createRouter();

  Iterable<String> paths() sync* {
    final pending = [...router.configuration.routes];
    while (pending.isNotEmpty) {
      final route = pending.removeLast();
      if (route is GoRoute) yield route.path;
      pending.addAll(route.routes);
    }
  }

  group('rutas de Ajustes', () {
    test('existen los siete destinos de primer nivel', () {
      const expected = [
        '/settings',
        '/settings/appearance',
        '/settings/player',
        '/settings/controls',
        '/settings/playback',
        '/settings/library',
        '/settings/sources',
        '/settings/widget',
        '/settings/system',
      ];
      final registered = paths().toSet();
      for (final route in expected) {
        expect(registered, contains(route), reason: route);
      }
    });

    test('Sistema expone sus cuatro subsecciones', () {
      const expected = [
        '/settings/system/devices',
        '/settings/system/data',
        '/settings/system/diagnostics',
        '/settings/system/about',
      ];
      final registered = paths().toSet();
      for (final route in expected) {
        expect(registered, contains(route), reason: route);
      }
    });

    test('el color reactivo tiene su propia ruta', () {
      expect(
        paths().toSet(),
        contains('/settings/player/visualizer/colors'),
      );
    });

    test('los accesos directos antiguos siguen registrados', () {
      // Se conservan como redirección: un enlace guardado no puede quedar
      // apuntando a una ruta inexistente tras la reorganización.
      const legacy = [
        '/settings/theme',
        '/settings/widgets',
        '/settings/control',
        '/settings/control/layout',
        '/settings/audio',
        '/settings/data',
      ];
      final registered = paths().toSet();
      for (final route in legacy) {
        expect(registered, contains(route), reason: route);
      }
    });

    test('no hay rutas duplicadas', () {
      final all = paths().toList();
      expect(all.length, all.toSet().length);
    });
  });
}
