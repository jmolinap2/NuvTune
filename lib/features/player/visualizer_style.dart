import 'package:flutter/material.dart';

/// Estilos del lienzo reactivo usado cuando una pista no tiene portada.
/// [automatic] elige uno de los otros estilos de forma determinista por cancion.
enum VisualizerStyle {
  automatic(
    'Automático',
    'Un estilo propio para cada canción',
    Icons.auto_awesome_rounded,
  ),
  aurora('Aurora', 'Nebulosas fluidas y luminosas', Icons.blur_on_rounded),
  ribbons(
    'Cintas',
    'Ondas continuas que siguen los tonos',
    Icons.waves_rounded,
  ),
  prism(
    'Prisma',
    'Geometría que pulsa con el ritmo',
    Icons.change_history_rounded,
  ),
  spectrum(
    'Espectro',
    'Barras reflejadas por frecuencias',
    Icons.graphic_eq_rounded,
  ),
  orbit(
    'Órbita',
    'Partículas alrededor del artista',
    Icons.blur_circular_rounded,
  );

  const VisualizerStyle(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  static VisualizerStyle fromIndex(int index) =>
      index >= 0 && index < values.length ? values[index] : automatic;

  VisualizerStyle resolveFor(int seed) {
    if (this != automatic) return this;
    final concrete = values.skip(1).toList(growable: false);
    return concrete[seed.abs() % concrete.length];
  }
}
