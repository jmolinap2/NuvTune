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
      expect(layout.footer, isEmpty);
      expect({
        ...layout.primary,
        ...layout.secondary,
      }, containsAll(PlayerControlId.values));
    });

    test('normaliza desconocidos, duplicados y play/pause oculto', () {
      final layout = PlayerControlLayout.fromJsonString(
        '{"primary":["next","next","unknown"],"secondary":["queue","next"]}',
      );

      expect(layout.primary, [PlayerControlId.playPause, PlayerControlId.next]);
      expect(layout.secondary, [PlayerControlId.queue]);
    });

    test('mueve play/pause desde secundarios a principales', () {
      final layout = PlayerControlLayout(
        primary: const [PlayerControlId.previous],
        secondary: const [PlayerControlId.queue, PlayerControlId.playPause],
      );

      expect(layout.primary, [
        PlayerControlId.playPause,
        PlayerControlId.previous,
      ]);
      expect(layout.secondary, [PlayerControlId.queue]);
    });

    test('serialización personalizada es estable', () {
      final original = PlayerControlLayout(
        top: const [PlayerControlId.queue],
        primary: const [
          PlayerControlId.previous,
          PlayerControlId.playPause,
          PlayerControlId.next,
        ],
        secondary: const [PlayerControlId.shuffle],
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
          PlayerControlId.shuffle,
          PlayerControlId.queue,
          PlayerControlId.sleepTimer,
        ],
        primary: const [PlayerControlId.playPause],
        secondary: const [],
      );

      expect(layout.top, [PlayerControlId.shuffle, PlayerControlId.queue]);
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

    group('favorito fuera del sistema de controles', () {
      test('ningún preajuste lo incluye', () {
        for (final preset in PlayerControlPreset.values) {
          final layout = PlayerControlLayout.forPreset(preset);
          final all = [
            ...layout.top,
            ...layout.metadata,
            ...layout.primary,
            ...layout.secondary,
            ...layout.footer,
          ];
          expect(
            all.map((control) => control.id),
            isNot(contains('favorite')),
            reason: preset.label,
          );
        }
      });

      test('un diseño guardado que aún lo nombre se lee sin él', () {
        // Favorito pasó a ser fijo junto al título; los diseños antiguos no
        // deben resucitarlo ni dejar la zona a medio migrar.
        final layout = PlayerControlLayout.fromJsonString(
          '{"top":["favorite"],"primary":["previous","playPause","next"],'
          '"secondary":["favorite","queue"],"footer":["favorite"]}',
        );

        expect(layout.top, isEmpty);
        expect(layout.footer, isEmpty);
        expect(layout.secondary, [PlayerControlId.queue]);
      });

      test('ya no existe como identificador conocido', () {
        expect(PlayerControlId.tryById('favorite'), isNull);
      });
    });

    group('zona junto al título', () {
      test('admite dos acciones y desborda a secundarios', () {
        final layout = PlayerControlLayout(
          metadata: const [
            PlayerControlId.shuffle,
            PlayerControlId.queue,
            PlayerControlId.sleepTimer,
          ],
          primary: const [PlayerControlId.playPause],
          secondary: const [],
        );

        expect(layout.metadata, [
          PlayerControlId.shuffle,
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
          top: const [PlayerControlId.queue],
          metadata: const [PlayerControlId.queue],
          primary: const [PlayerControlId.playPause],
          secondary: const [],
        );

        expect(layout.top, [PlayerControlId.queue]);
        expect(layout.metadata, isEmpty);
      });

      test('sobrevive a una ida y vuelta por JSON', () {
        final original = PlayerControlLayout(
          metadata: const [PlayerControlId.queue],
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [PlayerControlId.shuffle],
          footer: const [],
        );

        expect(
          PlayerControlLayout.fromJsonString(original.toJsonString()),
          original,
        );
      });

      test('una preferencia guardada sin esta zona sigue siendo válida', () {
        final layout = PlayerControlLayout.fromJsonString(
          '{"top":[],"primary":["previous","playPause","next"],'
          '"secondary":["queue"],"footer":[]}',
        );

        expect(layout.metadata, isEmpty);
        expect(layout.secondary, [PlayerControlId.queue]);
      });
    });
  });
}
