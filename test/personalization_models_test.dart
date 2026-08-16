import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';

void main() {
  test('identificadores desconocidos usan valores seguros', () {
    expect(AppThemePreference.byId('desconocido'), AppThemePreference.dark);
    expect(MotionProfile.byId('desconocido'), MotionProfile.balanced);
    expect(
      VisualizerColorSource.byId('desconocido'),
      VisualizerColorSource.cover,
    );
  });

  test(
    'los perfiles fijan una personalidad sin perder valores personalizados',
    () {
      const custom = MotionPreferences(
        profile: MotionProfile.custom,
        intensity: 3,
        smoothness: 0,
        beatResponse: 1,
        particles: 2,
        colorSource: VisualizerColorSource.accent,
      );
      expect(custom.effectiveIntensity, 3);
      expect(custom.effectiveSmoothness, 0);
      expect(custom.effectiveBeatResponse, 1);
      expect(custom.effectiveParticles, 2);

      const calm = MotionPreferences(
        profile: MotionProfile.calm,
        intensity: 3,
        smoothness: 0,
        beatResponse: 3,
        particles: 3,
        colorSource: VisualizerColorSource.cover,
      );
      expect(calm.effectiveIntensity, 1);
      expect(calm.effectiveSmoothness, 3);
      expect(calm.effectiveBeatResponse, 1);
      expect(calm.effectiveParticles, 1);
    },
  );

  test('sin animación y accesibilidad producen duración cero', () {
    const none = MotionPreferences(
      profile: MotionProfile.none,
      intensity: 3,
      smoothness: 3,
      beatResponse: 3,
      particles: 3,
      colorSource: VisualizerColorSource.off,
    );
    expect(none.scale(const Duration(milliseconds: 260)), Duration.zero);

    expect(
      MotionPreferences.fallback.scale(
        const Duration(milliseconds: 260),
        systemReduceMotion: true,
      ),
      Duration.zero,
    );
  });

  test('preferencias de tema se traducen a ThemeMode', () {
    expect(AppThemePreference.system.themeMode, ThemeMode.system);
    expect(AppThemePreference.light.themeMode, ThemeMode.light);
    expect(AppThemePreference.amoled.themeMode, ThemeMode.dark);
  });
}
