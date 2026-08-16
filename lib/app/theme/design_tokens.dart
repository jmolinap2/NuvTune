import 'package:flutter/material.dart';

/// Tokens del sistema visual de NuvTune.
///
/// Los valores salen del sistema de diseño de `img/`: paleta, degradados,
/// tipografia Space Grotesk y el lenguaje de tarjetas de vidrio. Todo el resto
/// de la interfaz debe leer de aqui en lugar de escribir numeros sueltos, que
/// es lo que producia la mezcla de tamanos y rellenos arbitrarios.
abstract final class Tokens {
  // -- Escala de espaciado -------------------------------------------------
  //
  // Cinco valores. Si algo necesita un valor intermedio, casi siempre es senal
  // de que el elemento esta mal encajado, no de que falte un token.

  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 24.0;
  static const space6 = 32.0;

  /// Margen lateral de las pantallas.
  static const gutter = 20.0;

  // -- Radios --------------------------------------------------------------

  static const radiusSmall = 12.0;
  static const radiusMedium = 18.0;
  static const radiusLarge = 24.0;
  static const radiusXLarge = 32.0;
  static const radiusPill = 999.0;

  // -- Tipografia ----------------------------------------------------------

  static const fontFamily = 'SpaceGrotesk';

  // -- Duraciones ----------------------------------------------------------

  static const durationFast = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 260);
  static const durationSlow = Duration(milliseconds: 420);
}

/// Identidad cromatica completa: el degradado de marca y los colores que se
/// derivan de el.
///
/// El sistema de diseño no define un color de acento sino un degradado de tres
/// paradas (violeta, magenta, cian). Los botones principales, las barras del
/// ecualizador y el logotipo lo usan entero; el resto de la interfaz usa las
/// paradas por separado.
class AccentIdentity {
  const AccentIdentity({
    required this.id,
    required this.name,
    required this.start,
    required this.middle,
    required this.end,
  });

  final String id;
  final String name;
  final Color start;
  final Color middle;
  final Color end;

  /// Degradado de marca, de izquierda a derecha.
  LinearGradient get gradient => LinearGradient(
    colors: [start, middle, end],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Version de dos paradas para superficies pequenas, donde tres colores se
  /// leen como suciedad en lugar de como degradado.
  LinearGradient get compactGradient => LinearGradient(
    colors: [start, middle],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Degradado vertical para fondos de cabecera.
  LinearGradient headerGradient(Color surface) => LinearGradient(
    colors: [
      middle.withValues(alpha: 0.34),
      start.withValues(alpha: 0.16),
      surface,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0, 0.45, 1],
  );

  /// Color primario del esquema de Material.
  Color get primary => middle;

  /// Identidades disponibles en Apariencia.
  static const nebula = AccentIdentity(
    id: 'nebula',
    name: 'Nebulosa',
    start: Color(0xFF6D00FF),
    middle: Color(0xFFB14BFF),
    end: Color(0xFF00E5FF),
  );

  static const magenta = AccentIdentity(
    id: 'magenta',
    name: 'Magenta',
    start: Color(0xFF6D00FF),
    middle: Color(0xFFFF2D95),
    end: Color(0xFFFF9A6B),
  );

  static const aurora = AccentIdentity(
    id: 'aurora',
    name: 'Aurora',
    start: Color(0xFF00E5FF),
    middle: Color(0xFF2BE8A8),
    end: Color(0xFFB8FF6B),
  );

  static const solar = AccentIdentity(
    id: 'solar',
    name: 'Solar',
    start: Color(0xFFFF6B2D),
    middle: Color(0xFFFFB020),
    end: Color(0xFFFFE566),
  );

  static const ruby = AccentIdentity(
    id: 'ruby',
    name: 'Rubí',
    start: Color(0xFFFF2D55),
    middle: Color(0xFFFF4D8D),
    end: Color(0xFFFF9EC4),
  );

  static const ice = AccentIdentity(
    id: 'ice',
    name: 'Hielo',
    start: Color(0xFF2D6BFF),
    middle: Color(0xFF4FA8FF),
    end: Color(0xFF7AF0FF),
  );

  static const all = <AccentIdentity>[
    nebula,
    magenta,
    aurora,
    solar,
    ruby,
    ice,
  ];

  static AccentIdentity byId(String id) =>
      all.firstWhere((item) => item.id == id, orElse: () => nebula);

  /// Identidad construida a partir del color dominante de una portada. Las
  /// paradas se derivan girando el tono, de modo que el degradado sigue
  /// teniendo recorrido y no se convierte en un bloque plano.
  static AccentIdentity fromCover(Color dominant) {
    final hsl = HSLColor.fromColor(dominant);
    final base = hsl
        .withSaturation(hsl.saturation.clamp(0.55, 1.0))
        .withLightness(hsl.lightness.clamp(0.42, 0.68));

    return AccentIdentity(
      id: 'cover',
      name: 'Portada',
      start: base.withHue((base.hue - 28) % 360).toColor(),
      middle: base.toColor(),
      end: base.withHue((base.hue + 34) % 360).toColor(),
    );
  }
}

/// Profundidad del fondo. El sistema de diseño usa un negro azulado, pero hay
/// quien prefiere negro absoluto en pantallas OLED.
enum BackgroundDepth {
  night(
    'night',
    'Nocturno',
    Color(0xFF0B0F17),
    Color(0xFF131726),
    Color(0xFF1E1B2E),
    Color(0xFF2B1450),
  ),
  violet(
    'violet',
    'Violeta',
    Color(0xFF0A0613),
    Color(0xFF150F26),
    Color(0xFF1F1638),
    Color(0xFF2E1A55),
  ),
  warm(
    'warm',
    'Cálido',
    Color(0xFF160D0D),
    Color(0xFF241515),
    Color(0xFF342020),
    Color(0xFF4A2926),
  ),
  monochrome(
    'mono',
    'Monocromo',
    Color(0xFF101010),
    Color(0xFF1A1A1A),
    Color(0xFF252525),
    Color(0xFF303030),
  ),
  pureBlack(
    'black',
    'AMOLED',
    Color(0xFF000000),
    Color(0xFF0A0A0F),
    Color(0xFF13131A),
    Color(0xFF1C1C26),
  );

  const BackgroundDepth(
    this.id,
    this.label,
    this.background,
    this.surface,
    this.surfaceHigh,
    this.surfaceHighest,
  );

  final String id;
  final String label;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;

  static BackgroundDepth byId(String id) =>
      values.firstWhere((item) => item.id == id, orElse: () => night);
}

/// Intensidad del efecto de vidrio de las tarjetas.
enum GlassIntensity {
  subtle('subtle', 'Sutil', 0.05, 0.06, 0),
  medium('medium', 'Medio', 0.09, 0.12, 14),
  strong('strong', 'Intenso', 0.14, 0.20, 26);

  const GlassIntensity(
    this.id,
    this.label,
    this.fillOpacity,
    this.borderOpacity,
    this.blur,
  );

  final String id;
  final String label;
  final double fillOpacity;
  final double borderOpacity;

  /// Radio del desenfoque de fondo. En "Sutil" vale cero y la tarjeta se dibuja
  /// sin `BackdropFilter`, que es lo caro.
  final double blur;

  static GlassIntensity byId(String id) =>
      values.firstWhere((item) => item.id == id, orElse: () => medium);
}
