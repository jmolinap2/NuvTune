import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';

/// Tarjeta de vidrio del sistema visual: relleno translucido, borde de un pixel
/// muy tenue y esquinas amplias.
///
/// El desenfoque de fondo solo se aplica cuando la intensidad elegida lo pide.
/// `BackdropFilter` obliga a la GPU a leer lo que hay detras, y en una lista
/// larga eso se nota; en intensidad "Sutil" la tarjeta se dibuja sin el.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Tokens.space4),
    this.margin,
    this.radius = Tokens.radiusLarge,
    this.onTap,
    this.tint,
    this.borderless = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  /// Matiz opcional, para tarjetas que representan una identidad de color.
  final Color? tint;

  final bool borderless;

  @override
  Widget build(BuildContext context) {
    final appearance = ThemeScope.of(context);
    final glass = appearance.glass;
    final base = tint ?? Colors.white;
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: base.withValues(alpha: glass.fillOpacity),
        border: borderless
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: glass.borderOpacity),
              ),
        gradient: tint == null
            ? null
            : LinearGradient(
                colors: [
                  tint!.withValues(alpha: glass.fillOpacity * 2.2),
                  tint!.withValues(alpha: glass.fillOpacity * 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: child,
    );

    if (glass.blur > 0) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Icono dentro de un cuadrado redondeado con matiz de acento, tal como
/// aparece en las tarjetas del sistema visual.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
    this.gradient = false,
  });

  final IconData icon;
  final double size;
  final Color? color;

  /// Con degradado completo para los elementos destacados; con matiz plano
  /// para los secundarios.
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;
    final tone = color ?? accent.middle;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: gradient ? accent.compactGradient : null,
        color: gradient ? null : tone.withValues(alpha: 0.16),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * 0.48,
        color: gradient ? Colors.white : tone,
      ),
    );
  }
}

/// Boton principal con el degradado de marca.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusPill),
          gradient: accent.gradient,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: accent.middle.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(Tokens.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Tokens.space5,
                vertical: Tokens.space4,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: Colors.white),
                    const SizedBox(width: Tokens.space2),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boton circular de reproduccion con degradado y halo, la pieza central del
/// reproductor en el sistema visual.
class GradientPlayButton extends StatelessWidget {
  const GradientPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 74,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: accent.compactGradient,
          boxShadow: [
            BoxShadow(
              color: accent.middle.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: Tokens.durationFast,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            size: size * 0.46,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de seccion en mayusculas espaciadas.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space5,
            Tokens.gutter,
            Tokens.space2,
          ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Texto pintado con el degradado de marca. Se usa con moderacion: el
/// logotipo, los titulos de bienvenida y poco mas.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;

    return ShaderMask(
      shaderCallback: (bounds) => accent.gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? Theme.of(context).textTheme.headlineMedium)?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Chip en pastilla con degradado cuando esta activo, como los filtros del
/// sistema visual.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Tokens.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space4,
          vertical: Tokens.space2 + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusPill),
          gradient: selected ? accent.compactGradient : null,
          color: selected ? null : scheme.surfaceContainerHigh,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Tokens.space1 + 2),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
