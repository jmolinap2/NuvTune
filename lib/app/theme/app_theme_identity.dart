import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

/// Estilo de las superficies: qué material aparenta la interfaz.
enum SurfaceStyle {
  glass('glass', 'Glass', 'Vidrio esmerilado con profundidad'),
  flat('flat', 'Flat', 'Geometría plana, sin desenfoque'),
  paper('paper', 'Paper', 'Tarjetas claras con sombra suave');

  const SurfaceStyle(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  /// Intensidad de vidrio equivalente. `flat` y `paper` no desenfocan: uno por
  /// geometría plana y el otro porque su profundidad viene de la sombra.
  GlassIntensity get glassIntensity => switch (this) {
    SurfaceStyle.glass => GlassIntensity.strong,
    SurfaceStyle.flat => GlassIntensity.subtle,
    SurfaceStyle.paper => GlassIntensity.subtle,
  };

  double get cardElevation => switch (this) {
    SurfaceStyle.glass => 0,
    SurfaceStyle.flat => 0,
    SurfaceStyle.paper => 2,
  };

  static SurfaceStyle byId(String? id) =>
      values.firstWhere((value) => value.id == id, orElse: () => glass);
}

/// Personalidad del texto y los iconos.
enum TypographyStyle {
  expressive('expressive', 'Expresivo', 'Títulos con carácter'),
  minimal('minimal', 'Minimal', 'Texto sobrio y compacto'),
  editorial('editorial', 'Editorial', 'Lectura amplia y serena');

  const TypographyStyle(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  /// Factor sobre el tamaño base. Se mantiene cerca de 1 a propósito: pasado
  /// ese margen la interfaz deja de caber en pantallas estrechas.
  double get scale => switch (this) {
    TypographyStyle.expressive => 1.0,
    TypographyStyle.minimal => 0.96,
    TypographyStyle.editorial => 1.05,
  };

  double get titleSpacing => switch (this) {
    TypographyStyle.expressive => -0.4,
    TypographyStyle.minimal => 0,
    TypographyStyle.editorial => 0.2,
  };

  FontWeight get titleWeight => switch (this) {
    TypographyStyle.expressive => FontWeight.w700,
    TypographyStyle.minimal => FontWeight.w600,
    TypographyStyle.editorial => FontWeight.w500,
  };

  static TypographyStyle byId(String? id) =>
      values.firstWhere((value) => value.id == id, orElse: () => expressive);
}

/// Cuánta información cabe en pantalla.
enum LayoutDensity {
  compact('compact', 'Compacto', 'Más contenido a la vista'),
  balanced('balanced', 'Equilibrado', 'El reparto por defecto'),
  airy('airy', 'Aireado', 'Más aire entre elementos');

  const LayoutDensity(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  VisualDensity get visualDensity => switch (this) {
    LayoutDensity.compact => VisualDensity.compact,
    LayoutDensity.balanced => VisualDensity.standard,
    LayoutDensity.airy => const VisualDensity(horizontal: 1, vertical: 1),
  };

  /// Factor de separación para los espacios que se calculan a mano.
  double get spacingScale => switch (this) {
    LayoutDensity.compact => 0.84,
    LayoutDensity.balanced => 1.0,
    LayoutDensity.airy => 1.2,
  };

  static LayoutDensity byId(String? id) =>
      values.firstWhere((value) => value.id == id, orElse: () => balanced);
}

/// Identidad visual completa de la aplicación.
///
/// Existe porque los ajustes sueltos (modo, profundidad, vidrio, acento) podían
/// combinarse en resultados incoherentes y, sobre todo, indistinguibles entre
/// sí: elegir «claro» u «oscuro» no cambiaba la personalidad de la interfaz.
/// Cada identidad fija de una vez brillo, fondo, superficie, tipografía,
/// densidad y acento, y el usuario puede desviarse después eje por eje.
enum AppThemeIdentity {
  nebulaGlass(
    'nebulaGlass',
    'Nebula Glass',
    ['Cósmico', 'Premium', 'Inmersivo'],
    Brightness.dark,
    BackgroundDepth.violet,
    SurfaceStyle.glass,
    TypographyStyle.expressive,
    LayoutDensity.balanced,
    'nebula',
  ),
  amoledMono(
    'amoledMono',
    'AMOLED Mono',
    ['Minimalista', 'Ultra oscuro', 'Eficiente'],
    Brightness.dark,
    BackgroundDepth.pureBlack,
    SurfaceStyle.flat,
    TypographyStyle.minimal,
    LayoutDensity.compact,
    'aurora',
  ),
  paperLoft(
    'paperLoft',
    'Paper Loft',
    ['Cálido', 'Editorial', 'Sereno'],
    Brightness.light,
    BackgroundDepth.warm,
    SurfaceStyle.paper,
    TypographyStyle.editorial,
    LayoutDensity.airy,
    'solar',
  );

  const AppThemeIdentity(
    this.id,
    this.name,
    this.tags,
    this.brightness,
    this.depth,
    this.surface,
    this.typography,
    this.density,
    this.accentId,
  );

  final String id;
  final String name;
  final List<String> tags;
  final Brightness brightness;
  final BackgroundDepth depth;
  final SurfaceStyle surface;
  final TypographyStyle typography;
  final LayoutDensity density;
  final String accentId;

  AccentIdentity get accent => AccentIdentity.byId(accentId);

  /// Color de fondo representativo, para la tarjeta de selección.
  Color get previewBackground => switch (this) {
    AppThemeIdentity.nebulaGlass => const Color(0xFF120A24),
    AppThemeIdentity.amoledMono => const Color(0xFF000000),
    AppThemeIdentity.paperLoft => const Color(0xFFF6EFE6),
  };

  Color get previewSurface => switch (this) {
    AppThemeIdentity.nebulaGlass => const Color(0xFF1E1235),
    AppThemeIdentity.amoledMono => const Color(0xFF0D0D0D),
    AppThemeIdentity.paperLoft => const Color(0xFFFFFBF5),
  };

  Color get previewText => switch (this) {
    AppThemeIdentity.paperLoft => const Color(0xFF2A2420),
    _ => const Color(0xFFF4F1FA),
  };

  static AppThemeIdentity byId(String? id) =>
      values.firstWhere((value) => value.id == id, orElse: () => nebulaGlass);
}
