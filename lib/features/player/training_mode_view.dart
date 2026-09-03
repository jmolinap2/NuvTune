import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/player/player_controller.dart';

/// Vista simplificada del reproductor para el modo entrenamiento: menos
/// elementos, texto grande, pensada para mirarse de reojo mientras se trota.
///
/// No reutiliza el carrusel de portadas ni `CustomizablePlayerControls`: esos
/// widgets están optimizados para mirarse de cerca y con calma, justo lo
/// contrario de lo que hace falta aquí.
class TrainingModeView extends ConsumerWidget {
  const TrainingModeView({
    required this.song,
    required this.state,
    required this.controller,
    required this.onDismiss,
    super.key,
  });

  final Song song;
  final PlaybackState state;
  final PlaybackController controller;

  /// El usuario pidió explícitamente volver a la vista normal, aunque la
  /// cadencia siga activa (botón de salida, nunca deducido de otro gesto).
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final positionMs =
        ref.watch(playbackPositionProvider).valueOrNull?.positionMs ?? 0;
    final durationMs = state.durationMs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetectionBadge(color: scheme.tertiary),
              IconButton(
                tooltip: 'Salir del modo entrenamiento',
                icon: const Icon(Icons.close_rounded),
                color: scheme.onSurfaceVariant,
                onPressed: onDismiss,
              ),
            ],
          ),
          const Spacer(),
          Text(
            song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            song.displayArtist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Text(
            Formatters.duration(positionMs),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'de ${Formatters.duration(durationMs)}',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TrainingButton(
                icon: Icons.skip_previous_rounded,
                size: 56,
                onPressed: controller.skipPrevious,
              ),
              const SizedBox(width: 28),
              _TrainingButton(
                icon: state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 92,
                filled: true,
                onPressed: controller.togglePlayPause,
              ),
              const SizedBox(width: 28),
              _TrainingButton(
                icon: Icons.skip_next_rounded,
                size: 56,
                onPressed: controller.skipNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetectionBadge extends StatelessWidget {
  const _DetectionBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          'Trote detectado',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

class _TrainingButton extends StatelessWidget {
  const _TrainingButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.primary : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: filled ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
