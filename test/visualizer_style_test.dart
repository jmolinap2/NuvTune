import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';

void main() {
  test('los estilos conservan sus índices públicos y consecutivos', () {
    expect(VisualizerStyle.fromIndex(0), VisualizerStyle.automatic);
    expect(VisualizerStyle.fromIndex(1), VisualizerStyle.ribbons);
    expect(VisualizerStyle.fromIndex(2), VisualizerStyle.prism);
    expect(VisualizerStyle.fromIndex(3), VisualizerStyle.dynamicSpectrum);
    expect(VisualizerStyle.dynamicSpectrum.label, 'Espectro dinámico');
    expect(VisualizerStyle.fromIndex(4), VisualizerStyle.electricWaves);
    expect(VisualizerStyle.fromIndex(5), VisualizerStyle.cosmicOrbs);
    expect(
      VisualizerStyle.values.map((style) => style.index),
      orderedEquals(<int>[0, 1, 2, 3, 4, 5]),
    );
  });

  test('un índice inválido vuelve a Automático', () {
    expect(VisualizerStyle.fromIndex(-1), VisualizerStyle.automatic);
    expect(VisualizerStyle.fromIndex(6), VisualizerStyle.automatic);
    expect(VisualizerStyle.fromIndex(99), VisualizerStyle.automatic);
  });

  test('Automático también puede elegir Viaje psicodélico', () {
    final seedForCosmic = VisualizerStyle.cosmicOrbs.index - 1;

    expect(
      VisualizerStyle.automatic.resolveFor(seedForCosmic),
      VisualizerStyle.cosmicOrbs,
    );
  });
}
