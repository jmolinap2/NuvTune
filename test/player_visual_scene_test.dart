import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/player/player_visual_scene.dart';

void main() {
  test('los índices siguen el orden actual de los escenarios', () {
    expect(PlayerVisualScene.fromIndex(0), PlayerVisualScene.video);
    expect(PlayerVisualScene.fromIndex(1), PlayerVisualScene.visualizer);
    expect(PlayerVisualScene.fromIndex(2), PlayerVisualScene.both);
    expect(PlayerVisualScene.fromIndex(3), PlayerVisualScene.lyrics);
    expect(PlayerVisualScene.fromIndex(4), PlayerVisualScene.cover);
    expect(PlayerVisualScene.fromIndex(-1), PlayerVisualScene.video);
    expect(PlayerVisualScene.fromIndex(999), PlayerVisualScene.video);
  });

  test('solo Video y Ambos solicitan un fondo de YouTube', () {
    expect(PlayerVisualScene.video.requestsVideo, isTrue);
    expect(PlayerVisualScene.both.requestsVideo, isTrue);
    expect(PlayerVisualScene.visualizer.requestsVideo, isFalse);
    expect(PlayerVisualScene.lyrics.requestsVideo, isFalse);
    expect(PlayerVisualScene.cover.requestsVideo, isFalse);
  });

  test('Ambos representa video con letras, no video con visualizador', () {
    expect(PlayerVisualScene.both.label, 'Video + letras');
    expect(PlayerVisualScene.both.description, contains('letra sincronizada'));
    expect(PlayerVisualScene.both.showsLyrics, isTrue);
    expect(PlayerVisualScene.both.showsVisualizer, isFalse);
    expect(PlayerVisualScene.visualizer.showsVisualizer, isTrue);
    expect(PlayerVisualScene.cover.showsCover, isTrue);
  });
}
