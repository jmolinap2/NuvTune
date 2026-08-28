import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/player/visualizer_motion_tuning.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';

void main() {
  MotionPreferences preferences(MotionProfile profile) => MotionPreferences(
    profile: profile,
    intensity: 2,
    smoothness: 2,
    beatResponse: 2,
    particles: 2,
    colorSource: VisualizerColorSource.cover,
  );

  test(
    'Extrema gira, alarga columnas y eleva el espectro más que Equilibrada',
    () {
      final balanced = VisualizerMotionTuning.from(
        preferences(MotionProfile.balanced),
      );
      final extreme = VisualizerMotionTuning.from(
        preferences(MotionProfile.extreme),
      );

      expect(
        extreme.rotationTurnsPerSecond,
        greaterThan(balanced.rotationTurnsPerSecond),
      );
      expect(
        extreme.ribbonLengthScale,
        greaterThan(balanced.ribbonLengthScale),
      );
      expect(extreme.ribbonExponent, lessThan(balanced.ribbonExponent));
      expect(
        extreme.spectrumHeightScale,
        greaterThan(balanced.spectrumHeightScale),
      );
    },
  );

  test('Sin animación elimina el giro continuo', () {
    final none = VisualizerMotionTuning.from(preferences(MotionProfile.none));
    expect(none.rotationTurnsPerSecond, 0);
    expect(none.motionScale, 0);
  });
}
