import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';

/// Apariencia efectiva de la aplicacion en un punto del arbol.
///
/// El `ColorScheme` de Material no puede transportar un degradado de tres
/// paradas ni la intensidad del vidrio, que son dos piezas centrales del
/// sistema visual. [ThemeScope] las lleva en paralelo al tema, de modo que
/// cualquier componente puede pedirlas sin tener que recibirlas por parametro.
class Appearance {
  const Appearance({
    required this.accent,
    required this.depth,
    required this.glass,
    required this.dynamicFromCover,
    required this.themePreference,
    required this.motion,
  });

  final AccentIdentity accent;
  final BackgroundDepth depth;
  final GlassIntensity glass;

  /// Si el acento se toma de la portada de la cancion en reproduccion.
  final bool dynamicFromCover;
  final AppThemePreference themePreference;
  final MotionPreferences motion;

  Appearance withAccent(AccentIdentity value) => Appearance(
    accent: value,
    depth: depth,
    glass: glass,
    dynamicFromCover: dynamicFromCover,
    themePreference: themePreference,
    motion: motion,
  );

  static const fallback = Appearance(
    accent: AccentIdentity.nebula,
    depth: BackgroundDepth.night,
    glass: GlassIntensity.medium,
    dynamicFromCover: true,
    themePreference: AppThemePreference.dark,
    motion: MotionPreferences.fallback,
  );
}

class ThemeScope extends InheritedWidget {
  const ThemeScope({super.key, required this.appearance, required super.child});

  final Appearance appearance;

  /// Devuelve la apariencia vigente. Fuera de un [ThemeScope] cae en la
  /// identidad por omision en lugar de fallar: asi una pantalla suelta en una
  /// prueba de widget sigue construyendose.
  static Appearance of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.appearance ??
      Appearance.fallback;

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.appearance.accent.id != appearance.accent.id ||
      oldWidget.appearance.accent.middle != appearance.accent.middle ||
      oldWidget.appearance.depth != appearance.depth ||
      oldWidget.appearance.glass != appearance.glass ||
      oldWidget.appearance.dynamicFromCover != appearance.dynamicFromCover ||
      oldWidget.appearance.themePreference != appearance.themePreference ||
      oldWidget.appearance.motion != appearance.motion;
}
