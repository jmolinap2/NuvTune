import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';

/// Portada generativa que reacciona a la dinamica real de la pista.
///
/// Cuando el motor esta en modo directo no llegan cuadros PCM; en ese caso el
/// movimiento procedural sigue dando vida a la portada sin desactivar offload.
class ReactiveAudioVisualizer extends ConsumerStatefulWidget {
  const ReactiveAudioVisualizer({
    required this.song,
    required this.size,
    required this.borderRadius,
    required this.isPlaying,
    this.allowStyleSelection = false,
    super.key,
  });

  final Song song;
  final double size;
  final double borderRadius;
  final bool isPlaying;
  final bool allowStyleSelection;

  @override
  ConsumerState<ReactiveAudioVisualizer> createState() =>
      _ReactiveAudioVisualizerState();
}

class _ReactiveAudioVisualizerState
    extends ConsumerState<ReactiveAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _motion.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant ReactiveAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _syncMotion();
  }

  void _syncMotion() {
    if (widget.isPlaying && !_reduceMotion) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(audioAnalysisProvider).valueOrNull;
    final settingIndex = ref.watch(
      settingsProvider.select(
        (value) => value.valueOrNull?.playerVisualizerStyle ?? 0,
      ),
    );
    final requested = VisualizerStyle.fromIndex(settingIndex);
    final seed = _stableSongSeed(widget.song);
    final style = requested.resolveFor(seed);
    final colors = _palette(seed, Theme.of(context).colorScheme.primary);

    return Semantics(
      image: true,
      label: 'Visualizador ${style.label} para ${widget.song.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox.square(
          dimension: widget.size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => CustomPaint(
                    painter: _VisualizerPainter(
                      style: style,
                      time: _motion.value,
                      frame: _effectiveFrame(analysis),
                      colors: colors,
                      seed: seed,
                      isPlaying: widget.isPlaying,
                    ),
                  ),
                ),
              ),
              _VisualizerMonogram(song: widget.song, style: style),
              if (widget.allowStyleSelection)
                Positioned(
                  right: Tokens.space3,
                  top: Tokens.space3,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.34),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Cambiar visualizador',
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      color: Colors.white,
                      onPressed: () => showVisualizerStylePicker(context, ref),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  AudioAnalysisFrame _effectiveFrame(AudioAnalysisFrame? value) {
    if (!widget.isPlaying) {
      return AudioAnalysisFrame(level: 0, bass: 0, mid: 0, treble: 0, beat: 0);
    }
    if (value != null) return value;

    // Movimiento organico para modo directo/offload o durante el primer cuadro.
    final phase = _motion.value * math.pi * 2;
    return AudioAnalysisFrame(
      level: 0.24 + math.sin(phase * 2.0) * 0.05,
      bass: 0.27 + math.sin(phase * 1.5) * 0.08,
      mid: 0.22 + math.sin(phase * 2.3 + 1.2) * 0.06,
      treble: 0.18 + math.sin(phase * 3.1 + 2.1) * 0.05,
      beat: 0,
    );
  }

  static List<Color> _palette(int seed, Color accent) {
    final hue = (seed.abs() % 360).toDouble();
    final base = HSLColor.fromAHSL(1, hue, 0.78, 0.56).toColor();
    final second = HSLColor.fromAHSL(1, (hue + 62) % 360, 0.84, 0.58).toColor();
    final third = HSLColor.fromAHSL(1, (hue + 188) % 360, 0.72, 0.52).toColor();
    return [Color.lerp(base, accent, 0.28)!, second, third];
  }

  static int _stableSongSeed(Song song) {
    // FNV-1a de 32 bits: no depende del hash aleatorio de la ejecucion, de modo
    // que una cancion conserva estilo y colores despues de cerrar la app.
    var hash = 0x811C9DC5;
    for (final unit in '${song.id}|${song.title}|${song.artist}'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}

class _VisualizerMonogram extends StatelessWidget {
  const _VisualizerMonogram({required this.song, required this.style});

  final Song song;
  final VisualizerStyle style;

  @override
  Widget build(BuildContext context) {
    final characters = song.displayArtist.trim().characters;
    final initial = characters.isEmpty ? '♪' : characters.first;
    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          duration: Tokens.durationMedium,
          opacity: style == VisualizerStyle.orbit ? 0.72 : 0.14,
          child: Text(
            initial.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: style == VisualizerStyle.orbit ? 54 : 92,
              height: 1,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 22)],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showVisualizerStylePicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected = VisualizerStyle.fromIndex(
    ref.read(settingsProvider).valueOrNull?.playerVisualizerStyle ?? 0,
  );
  final choice = await showModalBottomSheet<VisualizerStyle>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Tokens.gutter,
          0,
          Tokens.gutter,
          Tokens.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visualizador sin portada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Tokens.space2),
            Text(
              'Todos reaccionan a la dinámica, graves, medios y agudos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Tokens.space4),
            Flexible(
              child: RadioGroup<VisualizerStyle>(
                groupValue: selected,
                onChanged: (value) => Navigator.of(context).pop(value),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final style in VisualizerStyle.values)
                      RadioListTile<VisualizerStyle>(
                        value: style,
                        secondary: Icon(style.icon),
                        title: Text(style.label),
                        subtitle: Text(style.description),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null) return;
  await ref
      .read(settingsRepositoryProvider)
      .update(AppSettingsCompanion(playerVisualizerStyle: Value(choice.index)));
}

class _VisualizerPainter extends CustomPainter {
  const _VisualizerPainter({
    required this.style,
    required this.time,
    required this.frame,
    required this.colors,
    required this.seed,
    required this.isPlaying,
  });

  final VisualizerStyle style;
  final double time;
  final AudioAnalysisFrame frame;
  final List<Color> colors;
  final int seed;
  final bool isPlaying;

  double get phase => time * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors[0], Colors.black, 0.64)!,
            Color.lerp(colors[2], Colors.black, 0.78)!,
          ],
        ).createShader(rect),
    );

    switch (style) {
      case VisualizerStyle.automatic:
        break;
      case VisualizerStyle.aurora:
        _paintAurora(canvas, size);
        break;
      case VisualizerStyle.ribbons:
        _paintRibbons(canvas, size);
        break;
      case VisualizerStyle.prism:
        _paintPrism(canvas, size);
        break;
      case VisualizerStyle.spectrum:
        _paintSpectrum(canvas, size);
        break;
      case VisualizerStyle.orbit:
        _paintOrbit(canvas, size);
        break;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x52000000)],
        ).createShader(rect),
    );
  }

  void _paintAurora(Canvas canvas, Size size) {
    final random = math.Random(seed);
    for (var index = 0; index < 6; index++) {
      final tone = switch (index % 3) {
        0 => frame.bass,
        1 => frame.mid,
        _ => frame.treble,
      };
      final angle = phase * (0.18 + index * 0.035) + random.nextDouble() * 6;
      final center = Offset(
        size.width * (0.5 + math.cos(angle) * (0.2 + index * 0.018)),
        size.height * (0.5 + math.sin(angle * 1.3) * (0.19 + index * 0.014)),
      );
      final radius = size.shortestSide * (0.19 + tone * 0.23 + index * 0.012);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = colors[index % colors.length].withValues(
            alpha: 0.24 + tone * 0.32,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.48),
      );
    }
  }

  void _paintRibbons(Canvas canvas, Size size) {
    final energies = [frame.bass, frame.mid, frame.treble, frame.level];
    for (var ribbon = 0; ribbon < 4; ribbon++) {
      final energy = energies[ribbon];
      final path = Path();
      final centerY = size.height * (0.27 + ribbon * 0.15);
      final amplitude = size.height * (0.035 + energy * 0.12);
      const segments = 72;
      for (var index = 0; index <= segments; index++) {
        final x = size.width * index / segments;
        final normalized = index / segments;
        final y =
            centerY +
            math.sin(
                  normalized * math.pi * (3.5 + ribbon) +
                      phase * (0.8 + ribbon * 0.16),
                ) *
                amplitude +
            math.sin(normalized * math.pi * 9 - phase) * amplitude * 0.22;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + energy * 7
          ..strokeCap = StrokeCap.round
          ..color = colors[ribbon % colors.length].withValues(
            alpha: 0.55 + energy * 0.4,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + energy * 8),
      );
    }
  }

  void _paintPrism(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var layer = 5; layer >= 0; layer--) {
      final energy = layer.isEven ? frame.bass : frame.mid;
      final radius =
          size.shortestSide *
          (0.12 + layer * 0.055 + energy * 0.075 + frame.beat * 0.035);
      final sides = 3 + layer % 4;
      final path = Path();
      for (var point = 0; point < sides; point++) {
        final angle =
            phase * (layer.isEven ? 0.34 : -0.26) + point * math.pi * 2 / sides;
        final position =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (point == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 + energy * 4
          ..color = colors[layer % colors.length].withValues(
            alpha: 0.3 + energy * 0.58,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, energy * 5),
      );
    }
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    const count = 28;
    final gap = size.width * 0.008;
    final barWidth = (size.width - gap * (count + 1)) / count;
    final baseline = size.height * 0.69;
    final random = math.Random(seed);
    for (var index = 0; index < count; index++) {
      final x = index / (count - 1);
      final tone = x < 0.33
          ? frame.bass
          : x < 0.68
          ? frame.mid
          : frame.treble;
      final variation = 0.7 + random.nextDouble() * 0.3;
      final flutter = 0.82 + math.sin(phase * 3 + index * 1.7) * 0.18;
      final height = size.height * (0.035 + tone * 0.42 * variation * flutter);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          gap + index * (barWidth + gap),
          baseline - height,
          barWidth,
          height,
        ),
        Radius.circular(barWidth),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [colors[0], colors[1], colors[2]],
          ).createShader(rect.outerRect),
      );
      final reflection = Rect.fromLTWH(
        rect.left,
        baseline + 5,
        barWidth,
        height * 0.3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(reflection, Radius.circular(barWidth)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors[0].withValues(alpha: 0.28), Colors.transparent],
          ).createShader(reflection),
      );
    }
  }

  void _paintOrbit(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final random = math.Random(seed);
    for (var ring = 0; ring < 3; ring++) {
      final tone = [frame.bass, frame.mid, frame.treble][ring];
      final radius =
          size.shortestSide *
          (0.17 + ring * 0.105 + tone * 0.035 + frame.beat * 0.025);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.08 + tone * 0.17),
      );
      final particles = 8 + ring * 4;
      for (var index = 0; index < particles; index++) {
        final angle =
            index * math.pi * 2 / particles +
            phase * (0.22 + ring * 0.14) * (ring.isEven ? 1 : -1);
        final wobble = math.sin(phase * 2 + index) * size.width * 0.008;
        final position =
            center +
            Offset(math.cos(angle), math.sin(angle)) * (radius + wobble);
        final particleSize = 1.8 + random.nextDouble() * 2.5 + tone * 5;
        canvas.drawCircle(
          position,
          particleSize,
          Paint()
            ..color = colors[(index + ring) % colors.length].withValues(
              alpha: 0.55 + tone * 0.4,
            )
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tone * 4),
        );
      }
    }

    canvas.drawCircle(
      center,
      size.shortestSide * (0.11 + frame.level * 0.035 + frame.beat * 0.025),
      Paint()
        ..shader =
            RadialGradient(
              colors: [colors[1].withValues(alpha: 0.68), Colors.transparent],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.2),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.time != time ||
      oldDelegate.frame != frame ||
      oldDelegate.seed != seed ||
      oldDelegate.isPlaying != isPlaying;
}
