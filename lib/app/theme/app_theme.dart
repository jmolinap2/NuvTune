import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

/// Tema oscuro de NuvTune (requerimiento seccion 12).
///
/// Construido sobre el sistema visual de `img/`: fondo azulado profundo,
/// degradado de marca de tres paradas, tipografia Space Grotesk y tarjetas de
/// vidrio. El usuario elige identidad cromatica, profundidad del fondo e
/// intensidad del vidrio desde Ajustes > Apariencia.
abstract final class AppTheme {
  /// Acento por omision, para el codigo que todavía no lee la configuracion.
  static const seed = Color(0xFFB14BFF);

  static ThemeData light({
    AccentIdentity accent = AccentIdentity.nebula,
    BackgroundDepth depth = BackgroundDepth.night,
  }) {
    final background = switch (depth) {
      BackgroundDepth.violet => const Color(0xFFFAF5FF),
      BackgroundDepth.warm => const Color(0xFFFFF7F3),
      BackgroundDepth.monochrome ||
      BackgroundDepth.pureBlack => const Color(0xFFF6F6F6),
      BackgroundDepth.night => const Color(0xFFF8F6FB),
    };
    final surface = switch (depth) {
      BackgroundDepth.violet => const Color(0xFFFFFBFF),
      BackgroundDepth.warm => const Color(0xFFFFFCFA),
      _ => Colors.white,
    };
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent.middle,
          brightness: Brightness.light,
          surface: background,
        ).copyWith(
          primary: accent.middle,
          onPrimary: _onColor(accent.middle),
          secondary: accent.end,
          onSecondary: _onColor(accent.end),
          tertiary: accent.start,
          surface: background,
          surfaceContainerLowest: surface,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: Color.alphaBlend(
            accent.middle.withValues(alpha: 0.045),
            surface,
          ),
          surfaceContainerHighest: Color.alphaBlend(
            accent.middle.withValues(alpha: 0.08),
            surface,
          ),
          outline: const Color(0xFF77707F),
          outlineVariant: const Color(0xFFDDD5E3),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: Tokens.fontFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme,
    );
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.middle.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent.middle,
        inactiveTrackColor: scheme.outlineVariant,
        thumbColor: accent.middle,
        overlayColor: accent.middle.withValues(alpha: 0.12),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: accent.middle.withValues(alpha: 0.20),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(accent.middle, width: 1.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Tokens.space4,
          vertical: Tokens.space4,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusXLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.radiusXLarge),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? accent.middle
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _onColor(accent.middle)
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.middle
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.space5,
            vertical: Tokens.space3,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent.middle,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: accent.middle,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent.middle,
        linearTrackColor: scheme.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: Tokens.space5,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark({
    AccentIdentity accent = AccentIdentity.nebula,
    BackgroundDepth depth = BackgroundDepth.night,
  }) {
    final scheme = ColorScheme.dark(
      primary: accent.middle,
      onPrimary: _onColor(accent.middle),
      primaryContainer: accent.start,
      onPrimaryContainer: Colors.white,
      secondary: accent.end,
      onSecondary: _onColor(accent.end),
      secondaryContainer: accent.end.withValues(alpha: 0.24),
      onSecondaryContainer: Colors.white,
      tertiary: accent.start,
      onTertiary: Colors.white,
      surface: depth.background,
      onSurface: const Color(0xFFF2F1F6),
      onSurfaceVariant: const Color(0xFFA9A6B8),
      surfaceContainerLowest: depth.background,
      surfaceContainerLow: depth.surface,
      surfaceContainer: depth.surface,
      surfaceContainerHigh: depth.surfaceHigh,
      surfaceContainerHighest: depth.surfaceHighest,
      outline: const Color(0xFF3A3648),
      outlineVariant: const Color(0xFF26232F),
      error: const Color(0xFFFF5470),
      onError: Colors.white,
      errorContainer: const Color(0xFF4A1220),
      onErrorContainer: const Color(0xFFFFD9DF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: depth.background,
      fontFamily: Tokens.fontFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Color(0xFFF2F1F6),
        ),
      ),

      cardTheme: CardThemeData(
        color: depth.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Tokens.gutter,
          vertical: Tokens.space1,
        ),
        minVerticalPadding: Tokens.space2,
        titleTextStyle: TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFFF2F1F6),
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 13,
          height: 1.35,
          color: Color(0xFFA9A6B8),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: depth.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.middle.withValues(alpha: 0.24),
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: Tokens.fontFamily,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent.middle : const Color(0xFFA9A6B8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? accent.middle : const Color(0xFFA9A6B8),
          );
        }),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: accent.middle,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        overlayColor: accent.middle.withValues(alpha: 0.16),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),

      // Chips en pastilla, como en el sistema de diseño.
      chipTheme: ChipThemeData(
        backgroundColor: depth.surfaceHigh,
        selectedColor: accent.middle,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space3,
          vertical: Tokens.space2,
        ),
        showCheckmark: false,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: depth.surfaceHigh,
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.white.withValues(alpha: 0.06)),
        focusedBorder: _inputBorder(accent.middle, width: 1.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Tokens.space4,
          vertical: Tokens.space4,
        ),
        hintStyle: const TextStyle(color: Color(0xFF6E6B7D)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: depth.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusXLarge),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF2F1F6),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: depth.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Colors.white.withValues(alpha: 0.22),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.radiusXLarge),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: depth.surfaceHighest,
        contentTextStyle: const TextStyle(
          fontFamily: Tokens.fontFamily,
          color: Color(0xFFF2F1F6),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMedium),
        ),
        insetPadding: const EdgeInsets.all(Tokens.space4),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: Tokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? accent.middle
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _onColor(accent.middle)
                : const Color(0xFFA9A6B8),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF6E6B7D),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.middle
              : Colors.white.withValues(alpha: 0.10),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.space5,
            vertical: Tokens.space3,
          ),
          textStyle: const TextStyle(
            fontFamily: Tokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.space5,
            vertical: Tokens.space3,
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accent.middle,
        unselectedLabelColor: const Color(0xFFA9A6B8),
        indicatorColor: accent.middle,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: Tokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent.middle,
        linearTrackColor: Colors.white.withValues(alpha: 0.10),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
        space: Tokens.space5,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Blanco o negro segun lo que se lea mejor sobre [background].
  static Color _onColor(Color background) =>
      background.computeLuminance() > 0.55 ? Colors.black : Colors.white;

  /// Escala tipografica. Se define entera para que ninguna pantalla tenga que
  /// escribir tamanos a mano.
  static const _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.15,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 15, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    // Etiqueta de seccion: mayusculas espaciadas, como en el sistema visual.
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}
