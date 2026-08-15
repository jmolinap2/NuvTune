import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/player/visualizer_quality.dart';

void main() {
  test('los perfiles exponen el contrato de rendimiento documentado', () {
    expect(VisualizerQuality.eco.bandCount, 48);
    expect(VisualizerQuality.eco.targetFps, 30);
    expect(VisualizerQuality.normal.bandCount, 64);
    expect(VisualizerQuality.normal.targetFps, 60);
    expect(VisualizerQuality.ultra.bandCount, 96);
    expect(VisualizerQuality.ultra.targetFps, 60);
  });

  test('byId conserva normal como fallback seguro', () {
    expect(VisualizerQuality.byId('eco'), VisualizerQuality.eco);
    expect(VisualizerQuality.byId('ultra'), VisualizerQuality.ultra);
    expect(VisualizerQuality.byId(null), VisualizerQuality.normal);
    expect(VisualizerQuality.byId('desconocido'), VisualizerQuality.normal);
  });
}
