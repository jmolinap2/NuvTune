import 'package:nuvtune/features/settings/personalization_models.dart';

/// Calibración visual derivada de un nivel de movimiento efectivo.
///
/// Mantenerla fuera de los painters permite comprobar la progresión completa
/// (incluido Extrema) sin depender de un Canvas ni duplicar constantes.
class VisualizerMotionTuning {
  const VisualizerMotionTuning({
    required this.motionScale,
    required this.particleScale,
    required this.responsiveness,
    required this.ribbonExponent,
    required this.ribbonLengthScale,
    required this.spectrumHeightScale,
    required this.rotationTurnsPerSecond,
  });

  final double motionScale;
  final double particleScale;
  final double responsiveness;
  final double ribbonExponent;
  final double ribbonLengthScale;
  final double spectrumHeightScale;
  final double rotationTurnsPerSecond;

  factory VisualizerMotionTuning.from(MotionPreferences preferences) {
    return switch (preferences.effectiveIntensity) {
      0 => const VisualizerMotionTuning(
        motionScale: 0,
        particleScale: 0,
        responsiveness: 0.65,
        ribbonExponent: 1.05,
        ribbonLengthScale: 0.62,
        spectrumHeightScale: 0.34,
        rotationTurnsPerSecond: 0,
      ),
      1 => const VisualizerMotionTuning(
        motionScale: 0.62,
        particleScale: 0.5,
        responsiveness: 0.82,
        ribbonExponent: 0.94,
        ribbonLengthScale: 0.82,
        spectrumHeightScale: 0.44,
        rotationTurnsPerSecond: 1 / 34,
      ),
      2 => const VisualizerMotionTuning(
        motionScale: 1,
        particleScale: 1,
        responsiveness: 1,
        ribbonExponent: 0.80,
        ribbonLengthScale: 1,
        spectrumHeightScale: 0.56,
        rotationTurnsPerSecond: 1 / 24,
      ),
      3 => const VisualizerMotionTuning(
        motionScale: 1.4,
        particleScale: 1.5,
        responsiveness: 1.25,
        ribbonExponent: 0.68,
        ribbonLengthScale: 1.12,
        spectrumHeightScale: 0.63,
        rotationTurnsPerSecond: 1 / 15,
      ),
      _ => const VisualizerMotionTuning(
        motionScale: 1.8,
        particleScale: 2,
        responsiveness: 1.55,
        ribbonExponent: 0.56,
        ribbonLengthScale: 1.25,
        spectrumHeightScale: 0.70,
        rotationTurnsPerSecond: 1 / 8,
      ),
    };
  }
}
