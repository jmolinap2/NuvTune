import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/player/player_scene_aspect_ratio.dart';

void main() {
  test('los índices siguen el orden actual de las relaciones de aspecto', () {
    expect(PlayerSceneAspectRatio.fromIndex(0), PlayerSceneAspectRatio.full);
    expect(
      PlayerSceneAspectRatio.fromIndex(1),
      PlayerSceneAspectRatio.portrait,
    );
    expect(
      PlayerSceneAspectRatio.fromIndex(2),
      PlayerSceneAspectRatio.balanced,
    );
    expect(PlayerSceneAspectRatio.fromIndex(3), PlayerSceneAspectRatio.square);
    expect(PlayerSceneAspectRatio.fromIndex(-1), PlayerSceneAspectRatio.full);
    expect(PlayerSceneAspectRatio.fromIndex(999), PlayerSceneAspectRatio.full);
  });

  test('pantalla completa no fuerza un valor numérico de relación', () {
    expect(PlayerSceneAspectRatio.full.ratio, isNull);
  });

  test('el resto de relaciones expone el valor numérico esperado', () {
    expect(PlayerSceneAspectRatio.portrait.ratio, 9 / 16);
    expect(PlayerSceneAspectRatio.balanced.ratio, 3 / 4);
    expect(PlayerSceneAspectRatio.square.ratio, 1 / 1);
  });
}
