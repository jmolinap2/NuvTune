import 'package:flutter/material.dart';

/// Estilos disponibles para el lienzo reactivo del reproductor.
enum VisualizerStyle {
  automatic(
    'Automático',
    'Un estilo propio para cada canción',
    Icons.auto_awesome_rounded,
  ),
  ribbons(
    'Frecuencias 360°',
    'Barras circulares que suben y bajan con el beat',
    Icons.blur_circular_rounded,
  ),
  prism(
    'Partículas fluidas',
    'Una malla de puntos que fluye con la música',
    Icons.grain_rounded,
  ),
  dynamicSpectrum(
    'Espectro dinámico',
    'Columnas de gran altura que responden a cada frecuencia',
    Icons.graphic_eq_rounded,
  ),
  electricWaves(
    'Ondas eléctricas',
    'Cintas luminosas que giran, vibran y estallan con la música',
    Icons.electric_bolt_rounded,
  ),
  cosmicOrbs(
    'Viaje psicodélico',
    'Cintas psicodélicas que atraviesan un túnel de color',
    Icons.public_rounded,
  ),
  aurisDance(
    'Auris bailando',
    'La mascota cobra vida con pasos y poses al ritmo de la música',
    Icons.emoji_emotions_rounded,
  );

  const VisualizerStyle(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  static VisualizerStyle fromIndex(int index) {
    if (index < 0 || index >= values.length) return automatic;
    return values[index];
  }

  VisualizerStyle resolveFor(int seed) {
    if (this != automatic) return this;
    final concreteCount = values.length - 1;
    return values[1 + seed.abs() % concreteCount];
  }
}
