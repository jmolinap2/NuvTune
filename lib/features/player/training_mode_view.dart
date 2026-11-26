import 'dart:async';
import 'dart:math' as math;

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
class TrainingModeView extends ConsumerStatefulWidget {
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
  ConsumerState<TrainingModeView> createState() => _TrainingModeViewState();
}

class _TrainingModeViewState extends ConsumerState<TrainingModeView> {
  static const _sessionGoal = Duration(minutes: 30);
  late DateTime _startedAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(_startedAt);
    final elapsedText = Formatters.duration(elapsed.inMilliseconds);
    final progress = (elapsed.inMilliseconds / _sessionGoal.inMilliseconds)
        .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetectionBadge(color: scheme.primary),
              IconButton(
                tooltip: 'Salir del modo entrenamiento',
                icon: const Icon(Icons.close_rounded),
                color: scheme.onSurfaceVariant,
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const Spacer(),
          _ExerciseRing(
            progress: progress,
            color: scheme.primary,
            isPlaying: widget.state.isPlaying,
          ),
          const SizedBox(height: 24),
          Text(
            widget.song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.song.displayArtist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Text(
            elapsedText,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'tiempo de ejercicio',
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
                onPressed: widget.controller.skipPrevious,
              ),
              const SizedBox(width: 28),
              _TrainingButton(
                icon: widget.state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 92,
                filled: true,
                onPressed: widget.controller.togglePlayPause,
              ),
              const SizedBox(width: 28),
              _TrainingButton(
                icon: Icons.skip_next_rounded,
                size: 56,
                onPressed: widget.controller.skipNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseRing extends StatelessWidget {
  const _ExerciseRing({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  final double progress;
  final Color color;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 270,
      child: CustomPaint(
        painter: _ExerciseRingPainter(progress: progress, color: color),
        child: Center(
          child: AnimatedScale(
            scale: isPlaying ? 1 : 0.94,
            duration: const Duration(milliseconds: 250),
            child: Icon(Icons.directions_run_rounded, size: 92, color: color),
          ),
        ),
      ),
    );
  }
}

class _ExerciseRingPainter extends CustomPainter {
  const _ExerciseRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ExerciseRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Ritmo visible a distancia: el corredor y las barras avanzan con la música
/// para que el modo entrenamiento no parezca una pantalla estática.
class _TrainingRhythm extends StatefulWidget {
  const _TrainingRhythm({required this.isPlaying, required this.color});

  final bool isPlaying;
  final Color color;

  @override
  State<_TrainingRhythm> createState() => _TrainingRhythmState();
}

class _TrainingRhythmState extends State<_TrainingRhythm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rhythm = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _TrainingRhythm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _sync();
  }

  void _sync() {
    final enabled =
        widget.isPlaying &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled) {
      if (!_rhythm.isAnimating) _rhythm.repeat();
    } else {
      _rhythm.stop();
      if (!widget.isPlaying) _rhythm.value = 0;
    }
  }

  @override
  void dispose() {
    _rhythm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: AnimatedBuilder(
      animation: _rhythm,
      builder: (context, _) {
        final phase = _rhythm.value;
        final step = (phase * 2).floor();
        return Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(9, (index) {
                final wave = (phase * 6 + index * 0.72) % 1;
                final height = 18 + (1 - (wave * 2 - 1).abs()) * 42;
                return Container(
                  width: 5,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.18 + height / 86),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            Transform.translate(
              offset: Offset((phase - 0.5) * 120, 0),
              child: Transform.scale(
                scaleX: step.isEven ? 1 : -1,
                child: Icon(
                  Icons.directions_run_rounded,
                  size: 54,
                  color: widget.color,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
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
        Icon(Icons.directions_run_rounded, size: 19, color: color),
        const SizedBox(width: 8),
        Text(
          'Modo ejercicio',
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
