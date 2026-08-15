/// Perfil de coste y fidelidad del visualizador musical.
///
/// Los identificadores se persisten en Drift; no deben depender de la posición
/// del enum. Los valores concretos son el contrato que consume el renderizador
/// para construir su configuración sin duplicar decisiones por toda la UI.
enum VisualizerQuality {
  eco(
    'eco',
    'Eco',
    description: '30 FPS · pocas partículas · glow reducido',
    bandCount: 48,
    targetFps: 30,
    particleScale: 0.45,
    glowScale: 0.55,
  ),
  normal(
    'normal',
    'Normal',
    description: '60 FPS · equilibrio visual y consumo',
    bandCount: 64,
    targetFps: 60,
    particleScale: 1,
    glowScale: 1,
  ),
  ultra(
    'ultra',
    'Ultra',
    description: '60 FPS · máximo detalle y partículas',
    bandCount: 96,
    targetFps: 60,
    particleScale: 1.35,
    glowScale: 1.2,
  );

  const VisualizerQuality(
    this.id,
    this.label, {
    required this.description,
    required this.bandCount,
    required this.targetFps,
    required this.particleScale,
    required this.glowScale,
  });

  final String id;
  final String label;
  final String description;
  final int bandCount;
  final int targetFps;
  final double particleScale;
  final double glowScale;

  static VisualizerQuality byId(String? id) => values.firstWhere(
    (quality) => quality.id == id,
    orElse: () => VisualizerQuality.normal,
  );
}
