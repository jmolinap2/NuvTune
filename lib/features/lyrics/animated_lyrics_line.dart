import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/lyrics/lyrics_animation_style.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';

/// Línea sincronizada compartida por la vista completa de letras y la escena
/// del reproductor. El contenido y los tiempos los decide el llamador; aquí
/// solo vive la presentación elegida por el usuario.
class AnimatedLyricsLine extends ConsumerWidget {
  const AnimatedLyricsLine({
    required this.text,
    required this.active,
    required this.progress,
    required this.style,
    required this.baseStyle,
    required this.activeColor,
    required this.inactiveColor,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final bool active;
  final double progress;
  final LyricsAnimationStyle style;
  final TextStyle baseStyle;
  final Color activeColor;
  final Color inactiveColor;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final motion = settings == null
        ? MotionPreferences.fallback
        : MotionPreferences(
            profile: MotionProfile.byId(settings.motionProfile),
            intensity: settings.motionIntensity,
            smoothness: settings.motionSmoothness,
            beatResponse: settings.motionBeatResponse,
            particles: settings.motionParticles,
            colorSource: VisualizerColorSource.byId(
              settings.visualizerColorSource,
            ),
          );
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        motion.effectiveIntensity == 0;
    final effectiveStyle = reduced ? LyricsAnimationStyle.soft : style;
    final duration = reduced
        ? Duration.zero
        : motion.scale(Tokens.durationFast);
    final activeTextStyle = baseStyle.copyWith(
      color: activeColor,
      fontWeight: FontWeight.w700,
    );
    final inactiveTextStyle = baseStyle.copyWith(
      color: inactiveColor,
      fontWeight: FontWeight.w500,
    );

    Widget textWith(TextStyle value) => Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: value,
    );

    final child = switch (effectiveStyle) {
      LyricsAnimationStyle.soft => AnimatedDefaultTextStyle(
        duration: duration,
        curve: motion.curve,
        textAlign: textAlign,
        style: active ? activeTextStyle : inactiveTextStyle,
        child: Text(text, maxLines: maxLines, overflow: overflow),
      ),
      LyricsAnimationStyle.karaoke when active => Stack(
        alignment: textAlign == TextAlign.start
            ? Alignment.centerLeft
            : Alignment.center,
        children: [
          textWith(inactiveTextStyle),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: textWith(activeTextStyle),
            ),
          ),
        ],
      ),
      LyricsAnimationStyle.karaoke => textWith(inactiveTextStyle),
      LyricsAnimationStyle.pulse => _pulse(
        ref,
        settings?.directMode ?? false,
        active,
        textWith(active ? activeTextStyle : inactiveTextStyle),
        activeColor,
      ),
      LyricsAnimationStyle.rise => TweenAnimationBuilder<double>(
        tween: Tween(begin: active ? 1.0 : 0.0, end: active ? 1.0 : 0.0),
        duration: duration,
        curve: motion.curve,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, (1 - value) * 12 - (active ? 0 : 3)),
          child: Opacity(
            opacity: active ? 0.72 + value * 0.28 : 1,
            child: child,
          ),
        ),
        child: textWith(active ? activeTextStyle : inactiveTextStyle),
      ),
    };

    return AnimatedScale(
      duration: duration,
      curve: motion.curve,
      scale: active && effectiveStyle == LyricsAnimationStyle.soft ? 1.035 : 1,
      child: child,
    );
  }

  Widget _pulse(
    WidgetRef ref,
    bool directMode,
    bool isActive,
    Widget child,
    Color color,
  ) {
    if (!isActive || directMode) return child;
    final analysis = ref.watch(audioAnalysisProvider).valueOrNull;
    final impulse = analysis == null
        ? 0.0
        : (analysis.beat * 0.72 + analysis.level * 0.28)
              .clamp(0.0, 1.0)
              .toDouble();
    return Transform.scale(
      scale: 1 + impulse * 0.075,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: impulse * 0.28),
              blurRadius: 18 + impulse * 12,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
