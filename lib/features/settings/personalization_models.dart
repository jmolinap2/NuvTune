import 'package:flutter/material.dart';

enum AppThemePreference {
  system('system', 'Sistema'),
  light('light', 'Claro'),
  dark('dark', 'Oscuro'),
  amoled('amoled', 'AMOLED');

  const AppThemePreference(this.id, this.label);

  final String id;
  final String label;

  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark || AppThemePreference.amoled => ThemeMode.dark,
  };

  static AppThemePreference byId(String? id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => AppThemePreference.dark,
  );
}

enum MotionProfile {
  none('none', 'Sin animación'),
  calm('calm', 'Calmada'),
  balanced('balanced', 'Equilibrada'),
  energetic('energetic', 'Enérgica'),
  custom('custom', 'Personalizada');

  const MotionProfile(this.id, this.label);

  final String id;
  final String label;

  static MotionProfile byId(String? id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => MotionProfile.balanced,
  );
}

enum VisualizerColorSource {
  cover('cover', 'Portada'),
  accent('accent', 'Énfasis'),
  neutral('neutral', 'Neutro'),
  off('off', 'Sin color');

  const VisualizerColorSource(this.id, this.label);

  final String id;
  final String label;

  static VisualizerColorSource byId(String? id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => VisualizerColorSource.cover,
  );
}

class MotionPreferences {
  const MotionPreferences({
    required this.profile,
    required this.intensity,
    required this.smoothness,
    required this.beatResponse,
    required this.particles,
    required this.colorSource,
  });

  final MotionProfile profile;
  final int intensity;
  final int smoothness;
  final int beatResponse;
  final int particles;
  final VisualizerColorSource colorSource;

  static const fallback = MotionPreferences(
    profile: MotionProfile.balanced,
    intensity: 2,
    smoothness: 2,
    beatResponse: 2,
    particles: 2,
    colorSource: VisualizerColorSource.cover,
  );

  int get effectiveIntensity => switch (profile) {
    MotionProfile.none => 0,
    MotionProfile.calm => 1,
    MotionProfile.balanced => 2,
    MotionProfile.energetic => 3,
    MotionProfile.custom => intensity.clamp(0, 3),
  };

  int get effectiveSmoothness => switch (profile) {
    MotionProfile.none => 0,
    MotionProfile.calm => 3,
    MotionProfile.balanced => 2,
    MotionProfile.energetic => 1,
    MotionProfile.custom => smoothness.clamp(0, 3),
  };

  int get effectiveBeatResponse => switch (profile) {
    MotionProfile.none => 0,
    MotionProfile.calm => 1,
    MotionProfile.balanced => 2,
    MotionProfile.energetic => 3,
    MotionProfile.custom => beatResponse.clamp(0, 3),
  };

  int get effectiveParticles => switch (profile) {
    MotionProfile.none => 0,
    MotionProfile.calm => 1,
    MotionProfile.balanced => 2,
    MotionProfile.energetic => 3,
    MotionProfile.custom => particles.clamp(0, 3),
  };

  Duration scale(Duration base, {bool systemReduceMotion = false}) {
    if (systemReduceMotion || effectiveIntensity == 0) return Duration.zero;
    final multiplier = switch (effectiveSmoothness) {
      0 => 0.68,
      1 => 0.82,
      2 => 1.0,
      _ => 1.28,
    };
    return Duration(microseconds: (base.inMicroseconds * multiplier).round());
  }

  Curve get curve => switch (effectiveSmoothness) {
    0 => Curves.linear,
    1 => Curves.easeOut,
    2 => Curves.easeOutCubic,
    _ => Curves.easeInOutCubic,
  };

  @override
  bool operator ==(Object other) =>
      other is MotionPreferences &&
      other.profile == profile &&
      other.intensity == intensity &&
      other.smoothness == smoothness &&
      other.beatResponse == beatResponse &&
      other.particles == particles &&
      other.colorSource == colorSource;

  @override
  int get hashCode => Object.hash(
    profile,
    intensity,
    smoothness,
    beatResponse,
    particles,
    colorSource,
  );
}
