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
      expect(layout.secondary, containsAll(PlayerControlId.values.where(
        (control) => !layout.primary.contains(control),
      )));
    });

    test('normaliza desconocidos, duplicados y play/pause oculto', () {
      final layout = PlayerControlLayout.fromJsonString(
        '{"primary":["next","next","unknown"],'
        '"secondary":["favorite","next"]}',
      );

      expect(layout.primary, [
        PlayerControlId.playPause,
        PlayerControlId.next,
      ]);
      expect(layout.secondary, [PlayerControlId.favorite]);
    });

    test('mueve play/pause desde secundarios a principales', () {
      final layout = PlayerControlLayout(
        primary: const [PlayerControlId.previous],
        secondary: const [
          PlayerControlId.favorite,
          PlayerControlId.playPause,
        ],
      );

      expect(layout.primary, [
        PlayerControlId.playPause,
        PlayerControlId.previous,
      ]);
      expect(layout.secondary, [PlayerControlId.favorite]);
    });

    test('serialización personalizada es estable', () {
      final original = PlayerControlLayout(
        primary: const [
          PlayerControlId.previous,
          PlayerControlId.playPause,
          PlayerControlId.next,
        ],
        secondary: const [
          PlayerControlId.queue,
          PlayerControlId.favorite,
        ],
      );

      expect(
        PlayerControlLayout.fromJsonString(original.toJsonString()),
        original,
      );
    });

    test('JSON dañado vuelve al diseño completo', () {
      expect(
        PlayerControlLayout.fromJsonString('{bad json'),
        PlayerControlLayout.complete,
      );
    });
  });
}
