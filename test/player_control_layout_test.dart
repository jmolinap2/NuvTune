import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';

void main() {
  group('PlayerControlLayout', () {
    test('el preajuste completo conserva los controles actuales', () {
      final layout = PlayerControlLayout.forPreset(
        PlayerControlPreset.complete,
      );

      expect(layout.primary, [
        PlayerControlId.shuffle,
        PlayerControlId.previous,
        PlayerControlId.playPause,
        PlayerControlId.next,
        PlayerControlId.repeat,
      ]);
      expect(layout.top, isEmpty);
      expect(layout.footer, [PlayerControlId.favorite]);
      expect({
        ...layout.primary,
        ...layout.secondary,
        ...layout.footer,
      }, containsAll(PlayerControlId.values));
    });

    test('normaliza desconocidos, duplicados y play/pause oculto', () {
      final layout = PlayerControlLayout.fromJsonString(
        '{"primary":["next","next","unknown"],'
        '"secondary":["favorite","next"]}',
      );

      expect(layout.primary, [PlayerControlId.playPause, PlayerControlId.next]);
      expect(layout.secondary, isEmpty);
      expect(layout.footer, [PlayerControlId.favorite]);
    });

    test('mueve play/pause desde secundarios a principales', () {
      final layout = PlayerControlLayout(
        primary: const [PlayerControlId.previous],
        secondary: const [PlayerControlId.favorite, PlayerControlId.playPause],
      );

      expect(layout.primary, [
        PlayerControlId.playPause,
        PlayerControlId.previous,
      ]);
      expect(layout.secondary, [PlayerControlId.favorite]);
    });

    test('serialización personalizada es estable', () {
      final original = PlayerControlLayout(
        top: const [PlayerControlId.favorite],
        primary: const [
          PlayerControlId.previous,
          PlayerControlId.playPause,
          PlayerControlId.next,
        ],
        secondary: const [PlayerControlId.queue],
        footer: const [PlayerControlId.sleepTimer],
      );

      expect(
        PlayerControlLayout.fromJsonString(original.toJsonString()),
        original,
      );
    });

    test('la barra superior admite dos y desborda de forma segura', () {
      final layout = PlayerControlLayout(
        top: const [
          PlayerControlId.favorite,
          PlayerControlId.queue,
          PlayerControlId.sleepTimer,
        ],
        primary: const [PlayerControlId.playPause],
        secondary: const [],
      );

      expect(layout.top, [PlayerControlId.favorite, PlayerControlId.queue]);
      expect(layout.secondary, [PlayerControlId.sleepTimer]);
    });

    test('reproducir o pausar nunca puede quedar arriba ni oculto', () {
      final layout = PlayerControlLayout(
        top: const [PlayerControlId.playPause],
        primary: const [],
        secondary: const [],
      );

      expect(layout.top, isEmpty);
      expect(layout.primary, [PlayerControlId.playPause]);
    });

    test('JSON dañado vuelve al diseño completo', () {
      expect(
        PlayerControlLayout.fromJsonString('{bad json'),
        PlayerControlLayout.complete,
      );
    });

    group('zona junto al título', () {
      test('acepta Favorito, que es su caso de uso principal', () {
        final layout = PlayerControlLayout(
          metadata: const [PlayerControlId.favorite],
          primary: const [PlayerControlId.playPause],
          secondary: const [],
        );

        expect(layout.metadata, [PlayerControlId.favorite]);
        expect(layout.footer, isEmpty);
      });

      test('admite dos acciones y desborda a secundarios', () {
        final layout = PlayerControlLayout(
          metadata: const [
            PlayerControlId.favorite,
            PlayerControlId.queue,
            PlayerControlId.sleepTimer,
          ],
          primary: const [PlayerControlId.playPause],
          secondary: const [],
        );

        expect(layout.metadata, [
          PlayerControlId.favorite,
          PlayerControlId.queue,
        ]);
        expect(layout.secondary, [PlayerControlId.sleepTimer]);
      });

      test('reproducir o pausar nunca puede quedar junto al título', () {
        final layout = PlayerControlLayout(
          metadata: const [PlayerControlId.playPause],
          primary: const [],
          secondary: const [],
        );

        expect(layout.metadata, isEmpty);
        expect(layout.primary, [PlayerControlId.playPause]);
      });

      test('un control no puede estar en dos zonas a la vez', () {
        final layout = PlayerControlLayout(
          top: const [PlayerControlId.favorite],
          metadata: const [PlayerControlId.favorite],
          primary: const [PlayerControlId.playPause],
          secondary: const [],
        );

        expect(layout.top, [PlayerControlId.favorite]);
        expect(layout.metadata, isEmpty);
      });

      test('sobrevive a una ida y vuelta por JSON', () {
        final original = PlayerControlLayout(
          metadata: const [PlayerControlId.favorite],
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [PlayerControlId.queue],
          footer: const [],
        );

        expect(
          PlayerControlLayout.fromJsonString(original.toJsonString()),
          original,
        );
      });

      test('una preferencia guardada sin esta zona sigue siendo válida', () {
        // Los diseños existentes no traen la clave `metadata`: deben leerse
        // con la zona vacía y sin alterar el resto del reparto.
        final layout = PlayerControlLayout.fromJsonString(
          '{"top":[],"primary":["previous","playPause","next"],'
          '"secondary":["queue"],"footer":["favorite"]}',
        );

        expect(layout.metadata, isEmpty);
        expect(layout.footer, [PlayerControlId.favorite]);
        expect(layout.secondary, [PlayerControlId.queue]);
      });
    });
  });
}
