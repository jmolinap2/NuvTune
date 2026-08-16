import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/app_theme_identity.dart';
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
    required this.identity,
    required this.surface,
    required this.typography,
    required this.density,
  });

  final AccentIdentity accent;
  final BackgroundDepth depth;
  final GlassIntensity glass;

  /// Identidad visual elegida y los tres ejes que la componen, ya resueltos:
  /// si el usuario no ha desviado un eje, aquí llega el valor de la identidad.
  final AppThemeIdentity identity;
  final SurfaceStyle surface;
  final TypographyStyle typography;
  final LayoutDensity density;

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
    identity: identity,
    surface: surface,
    typography: typography,
    density: density,
  );

  /// Aplica los tres ejes de la identidad sobre un tema ya construido.
  ///
  /// El color sigue viniendo de [AppTheme]; aquí se decide lo que distingue a
  /// una identidad de otra más allá de la paleta: cuánto pesa el texto, cuánto
  /// aire hay entre elementos y si las tarjetas son de vidrio, planas o de
  /// papel con sombra.
  ThemeData applyIdentity(ThemeData base) {
    final text = base.textTheme;
    TextStyle? title(TextStyle? style) => style?.copyWith(
      fontSize: style.fontSize == null
          ? null
          : style.fontSize! * typography.scale,
      letterSpacing: typography.titleSpacing,
      fontWeight: typography.titleWeight,
    );
    TextStyle? body(TextStyle? style) => style?.copyWith(
      fontSize: style.fontSize == null
          ? null
          : style.fontSize! * typography.scale,
    );

    return base.copyWith(
      visualDensity: density.visualDensity,
      textTheme: text.copyWith(
        displayLarge: title(text.displayLarge),
        displayMedium: title(text.displayMedium),
        displaySmall: title(text.displaySmall),
        headlineLarge: title(text.headlineLarge),
        headlineMedium: title(text.headlineMedium),
        headlineSmall: title(text.headlineSmall),
        titleLarge: title(text.titleLarge),
        titleMedium: title(text.titleMedium),
        titleSmall: title(text.titleSmall),
        bodyLarge: body(text.bodyLarge),
        bodyMedium: body(text.bodyMedium),
        bodySmall: body(text.bodySmall),
        labelLarge: body(text.labelLarge),
        labelMedium: body(text.labelMedium),
        labelSmall: body(text.labelSmall),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: surface.cardElevation,
        shadowColor: surface == SurfaceStyle.paper
            ? base.colorScheme.shadow.withValues(alpha: 0.28)
            : Colors.transparent,
      ),
    );
  }

  static const fallback = Appearance(
    accent: AccentIdentity.nebula,
    depth: BackgroundDepth.night,
    glass: GlassIntensity.medium,
    dynamicFromCover: true,
    themePreference: AppThemePreference.dark,
    motion: MotionPreferences.fallback,
    identity: AppThemeIdentity.nebulaGlass,
    surface: SurfaceStyle.glass,
    typography: TypographyStyle.expressive,
    density: LayoutDensity.balanced,
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
      oldWidget.appearance.motion != appearance.motion ||
      oldWidget.appearance.identity != appearance.identity ||
      oldWidget.appearance.surface != appearance.surface ||
      oldWidget.appearance.typography != appearance.typography ||
      oldWidget.appearance.density != appearance.density;
}
