import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';
import 'package:nuvtune/shared/widgets/option_picker.dart';

final Stopwatch _sharedVisualizerClock = Stopwatch()..start();

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
    this.height,
    this.immersive = false,
    this.styleOverride,
    super.key,
  });

  final Song song;
  final double size;
  final double? height;
  final double borderRadius;
  final bool isPlaying;
  final bool immersive;
  final VisualizerStyle? styleOverride;

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
    // Las páginas vecinas del carrusel permanecen montadas. Solo la pista que
    // realmente está sonando debe escuchar los cuadros FFT de alta frecuencia.
    final analysis = widget.isPlaying
        ? ref.watch(audioAnalysisProvider).valueOrNull
        : null;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final settingIndex = settings?.playerVisualizerStyle ?? 0;
    final hasLiveAnalysis =
        analysis != null && !(settings?.directMode ?? false);
    final requested =
        widget.styleOverride ?? VisualizerStyle.fromIndex(settingIndex);
    final seed = _stableSongSeed(widget.song);
    final style = requested.resolveFor(seed);
    final colors = _palette(seed, Theme.of(context).colorScheme.primary);

    return Semantics(
      image: true,
      label:
          'Visualizador ${style.label} para ${widget.song.title}, '
          '${hasLiveAnalysis ? 'reactivo a la música' : 'movimiento ambiental'}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: widget.size,
          height: widget.height ?? widget.size,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _motion,
              builder: (context, child) => CustomPaint(
                painter: _VisualizerPainter(
                  style: style,
                  time:
                      (_sharedVisualizerClock.elapsedMicroseconds % 14000000) /
                      14000000,
                  frame: _effectiveFrame(hasLiveAnalysis ? analysis : null),
                  colors: colors,
                  seed: seed,
                  isPlaying: widget.isPlaying,
                  immersive: widget.immersive,
                  hasLiveAnalysis: hasLiveAnalysis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AudioAnalysisFrame _effectiveFrame(AudioAnalysisFrame? value) {
    if (!widget.isPlaying) {
      return AudioAnalysisFrame(
        level: 0,
        bass: 0,
        mid: 0,
        treble: 0,
        beat: 0,
        spectrum: List<double>.filled(24, 0, growable: false),
      );
    }
    if (value != null) return value;

    // En modo directo/offload no hay PCM disponible. Se conserva una escena
    // ambiental reconocible, pero sin falsos golpes ni un espectro que aparente
    // medir la canción.
    final time =
        (_sharedVisualizerClock.elapsedMicroseconds % 14000000) / 14000000;
    final phase = time * math.pi * 2;
    final ambientSpectrum = List<double>.generate(24, (index) {
      final normalized = index / 23;
      final envelope = 0.72 - normalized * 0.28;
      final drift = math.sin(
        phase * (0.72 + normalized * 0.46) + normalized * math.pi * 3.4,
      );
      return (0.16 + drift * 0.035) * envelope;
    }, growable: false);
    return AudioAnalysisFrame(
      level: 0.2 + math.sin(phase * 0.76) * 0.025,
      bass: 0.22 + math.sin(phase * 0.64) * 0.035,
      mid: 0.18 + math.sin(phase * 0.91 + 1.2) * 0.028,
      treble: 0.14 + math.sin(phase * 1.13 + 2.1) * 0.02,
      beat: 0,
      spectrum: ambientSpectrum,
    );
  }

  static List<Color> _palette(int seed, Color accent) {
    final shift = ((seed.abs() % 41) - 20).toDouble();
    final cyan = HSLColor.fromAHSL(1, 184 + shift * 0.22, 0.92, 0.57).toColor();
    final blue = HSLColor.fromAHSL(1, 225 + shift * 0.14, 0.88, 0.6).toColor();
    final magenta = HSLColor.fromAHSL(
      1,
      294 + shift * 0.18,
      0.86,
      0.59,
    ).toColor();
    return [Color.lerp(cyan, accent, 0.12)!, blue, magenta];
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

Future<void> showVisualizerStylePicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected = VisualizerStyle.fromIndex(
    ref.read(settingsProvider).valueOrNull?.playerVisualizerStyle ?? 0,
  );
  final choice = await showOptionPicker<VisualizerStyle>(
    context,
    title: 'Visualizador',
    selected: selected,
    helperText: 'Todos reaccionan a la dinámica, graves, medios y agudos.',
    options: [
      for (final style in VisualizerStyle.values)
        OptionPickerItem(
          value: style,
          icon: style.icon,
          label: style.label,
          description: style.description,
        ),
    ],
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
    required this.immersive,
    required this.hasLiveAnalysis,
  });

  final VisualizerStyle style;
  final double time;
  final AudioAnalysisFrame frame;
  final List<Color> colors;
  final int seed;
  final bool isPlaying;
  final bool immersive;
  final bool hasLiveAnalysis;

  double get phase => time * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (immersive) _paintImmersiveAtmosphere(canvas, size);
    switch (style) {
      case VisualizerStyle.automatic:
        // Inalcanzable en la práctica: `resolveFor(seed)` en
        // _ReactiveAudioVisualizerState.build() siempre resuelve `automatic` a
        // un estilo concreto antes de construir este painter. Se mantiene como
        // fallback defensivo porque Dart exige exhaustividad del switch.
        assert(
          false,
          'VisualizerStyle.automatic debe resolverse antes de pintar',
        );
        _paintSpectrum(canvas, size);
        break;
      case VisualizerStyle.ribbons:
        _paintRibbons(canvas, size);
        break;
      case VisualizerStyle.prism:
        _paintPrism(canvas, size);
        break;
      case VisualizerStyle.minimalSpectrum:
        _paintSpectrum(canvas, size);
        break;
      case VisualizerStyle.electricWaves:
        _paintElectricWaves(canvas, size);
        break;
      case VisualizerStyle.cosmicOrbs:
        _paintCosmicOrbs(canvas, size);
        break;
    }
  }

  void _paintImmersiveAtmosphere(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final drift = Offset(
      math.sin(phase * 0.34) * size.width * 0.2,
      math.cos(phase * 0.27) * size.height * 0.12,
    );
    final glowRadius = size.shortestSide * (0.42 + frame.bass * 0.18);
    canvas.drawCircle(
      center + drift,
      glowRadius,
      Paint()
        ..color = colors[0].withValues(alpha: 0.08 + frame.level * 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.58),
    );
    canvas.drawCircle(
      center - drift * 0.8,
      glowRadius * 0.88,
      Paint()
        ..color = colors[2].withValues(alpha: 0.07 + frame.mid * 0.07)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.52),
    );

    final random = math.Random(seed ^ 0x6A09E667);
    for (var index = 0; index < 96; index++) {
      final x = random.nextDouble();
      final baseY = random.nextDouble();
      final speed = 0.012 + random.nextDouble() * 0.026;
      final y = (baseY - time * speed) % 1.0;
      final tone = _spectrumAt(x);
      final point = Offset(
        size.width * x + math.sin(phase * 0.3 + index) * 7,
        size.height * y,
      );
      canvas.drawCircle(
        point,
        0.45 + random.nextDouble() * 1.2 + tone * 1.1,
        Paint()..color = _colorAt(x).withValues(alpha: 0.1 + tone * 0.28),
      );
    }
  }

  void _paintRibbons(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * (fullCanvas ? 0.34 : 0.235);
    final innerRadius = baseRadius + size.shortestSide * frame.beat * 0.014;
    final count = fullCanvas ? 96 : 64;
    // En pantalla completa se suman anillos concéntricos para que el motivo
    // ocupe el lienzo entero en vez de quedar como un círculo pequeño y
    // centrado; en modo compacto se conserva el único anillo original.
    final ringCount = fullCanvas ? 3 : 1;

    canvas.drawCircle(
      center,
      innerRadius * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = colors[0].withValues(alpha: 0.22),
    );

    for (var ring = 0; ring < ringCount; ring++) {
      final ringRadius = innerRadius * (1.0 + ring * 0.62);
      final ringAlpha = ring == 0 ? 1.0 : 0.55 - ring * 0.12;
      final ringDirection = ring.isOdd ? -1.0 : 1.0;
      final lengthScale = ring == 0 ? 1.0 : 0.72;

      for (var index = 0; index < count; index++) {
        final normalized = index / count;
        final angle = normalized * math.pi * 2 * ringDirection - math.pi / 2;
        final tone = _mirroredSpectrumAt(normalized);
        final flutter =
            0.9 +
            math.sin(phase * 3.2 + index * 1.71 + ring * 1.3) *
                (hasLiveAnalysis ? 0.1 : 0.22);
        final length =
            size.shortestSide *
            (0.038 + tone * 0.16 * flutter + frame.beat * 0.038) *
            lengthScale;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final start = center + direction * ringRadius;
        final end = center + direction * (ringRadius + length);
        final color = _colorAt(normalized);
        canvas.drawLine(
          start,
          end,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = size.shortestSide * 0.011
            ..color = color.withValues(alpha: (0.28 + tone * 0.72) * ringAlpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tone * 4),
        );
      }
    }
  }

  void _paintPrism(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final shortest = size.shortestSide;
    final direction = seed.isEven ? 1.0 : -1.0;
    final center =
        size.center(Offset.zero) +
        Offset(
          math.sin(phase * 2) * size.width * (0.018 + frame.mid * 0.042),
          math.cos(phase * 3) * size.height * (0.012 + frame.bass * 0.028),
        );
    final orbitalTurn =
        phase * direction +
        math.sin(phase * 2) * (0.1 + frame.mid * 0.42) +
        math.sin(phase * 6) * frame.beat * 0.1;
    final strands = fullCanvas ? 9 : 8;
    final points = fullCanvas ? 72 : 60;
    final particlePaint = Paint()..blendMode = BlendMode.plus;
    final streamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;

    // Un halo barato (sin blur) da profundidad al vórtice sin multiplicar el
    // coste de cada partícula.
    final glowRadius = shortest * (0.25 + frame.bass * 0.14);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _fluidParticleColor(0.08, 0.2, frame.bass, alpha: 0.13),
            _fluidParticleColor(0.64, 0.8, frame.mid, alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
        ..blendMode = BlendMode.plus,
    );

    for (var strand = 0; strand < strands; strand++) {
      final band = strand / (strands - 1);
      final stream = Path();
      final radiusX =
          size.width * (fullCanvas ? 0.13 + band * 0.36 : 0.17 + band * 0.27);
      final radiusY =
          size.height * (fullCanvas ? 0.1 + band * 0.31 : 0.16 + band * 0.25);
      for (var index = 0; index < points; index++) {
        final normalized = index / points;
        final tone = _spectrumAt((normalized + band * 0.17) % 1);
        final baseAngle = normalized * math.pi * 2;
        // Los medios retuercen el flujo; los graves ensanchan la órbita y el
        // beat la impulsa. Los agudos solo añaden el detalle de alta frecuencia.
        final vortex =
            math.sin(baseAngle * (2 + band * 2.4) - phase * direction * 3) *
            (0.035 + frame.mid * 0.2 + tone * 0.08);
        final angularJitter =
            math.sin(baseAngle * (13 + strand) + phase * 7) *
            frame.treble *
            0.045;
        final angle =
            baseAngle +
            orbitalTurn * (0.52 + band * 0.48) +
            (band - 0.5) * frame.mid * 1.15 +
            vortex +
            angularJitter;
        final radialPulse =
            1 +
            frame.bass * (0.07 + 0.13 * math.sin(baseAngle - phase * 2)) +
            frame.beat * (0.04 + tone * 0.1);
        final trebleRipple =
            math.sin(baseAngle * (17 + strand % 4) - phase * 8) *
            shortest *
            frame.treble *
            0.012;
        final local = Offset(
          math.cos(angle) * radiusX * radialPulse + trebleRipple,
          math.sin(angle) * radiusY * radialPulse +
              math.cos(baseAngle * 4 - phase * 2) *
                  shortest *
                  frame.mid *
                  0.035,
        );
        final point = center + local;
        if (index == 0) {
          stream.moveTo(point.dx, point.dy);
        } else {
          stream.lineTo(point.dx, point.dy);
        }
        particlePaint.color = _fluidParticleColor(
          normalized,
          band,
          tone,
          alpha: 0.2 + tone * 0.65,
        );
        canvas.drawCircle(
          point,
          0.55 + tone * 1.25 + frame.treble * 0.85 + frame.beat * tone * 0.55,
          particlePaint,
        );
      }
      stream.close();
      streamPaint
        ..strokeWidth = shortest * (0.0007 + frame.mid * 0.0012)
        ..color = _fluidParticleColor(
          band,
          1 - band,
          frame.mid,
          alpha: 0.08 + frame.level * 0.13,
        );
      canvas.drawPath(stream, streamPaint);
    }
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final count = fullCanvas ? 64 : 42;
    final gap = size.width * 0.0045;
    final barWidth = (size.width - gap * (count + 1)) / count;
    final baseline = size.height * 0.67;
    final heightScale = fullCanvas ? 0.58 : 0.36;
    final random = math.Random(seed);
    for (var index = 0; index < count; index++) {
      final x = index / (count - 1);
      final tone = _spectrumAt(x);
      final variation = 0.7 + random.nextDouble() * 0.3;
      final flutter =
          0.94 +
          math.sin(phase * 3 + index * 1.7) * (hasLiveAnalysis ? 0.06 : 0.16);
      final height =
          size.height * (0.022 + tone * heightScale * variation * flutter);
      final left = gap + index * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - height, barWidth, height),
        Radius.circular(barWidth),
      );
      final color = _colorAt(x);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.5 + tone * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, tone * 2.5),
      );

      // Reflejo especular corto y translúcido: solo en pantalla completa, donde
      // hay espacio bajo la línea base para que el motivo "barras minimalistas"
      // ocupe más lienzo sin perder su identidad limpia.
      if (fullCanvas) {
        final reflectionHeight = height * 0.42;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, baseline, barWidth, reflectionHeight),
            Radius.circular(barWidth),
          ),
          Paint()..color = color.withValues(alpha: 0.14 + tone * 0.18),
        );
      }
    }

    final particleCount = fullCanvas ? 48 : 28;
    final randomParticles = math.Random(seed ^ 0x5F3759DF);
    for (var index = 0; index < particleCount; index++) {
      final point = Offset(
        size.width * (0.08 + randomParticles.nextDouble() * 0.84),
        size.height * (0.16 + randomParticles.nextDouble() * 0.34),
      );
      canvas.drawCircle(
        point,
        0.6 + frame.treble * 1.6,
        Paint()
          ..color = _colorAt(
            randomParticles.nextDouble(),
          ).withValues(alpha: 0.18 + frame.treble * 0.4),
      );
    }
  }

  void _paintElectricWaves(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final strandCount = fullCanvas ? 8 : 6;
    final bounds = Offset.zero & size;
    final energy =
        (frame.level * 0.38 +
                frame.bass * 0.3 +
                frame.mid * 0.2 +
                frame.treble * 0.12)
            .clamp(0.0, 1.0);
    final direction = seed.isEven ? 1.0 : -1.0;
    // Una vuelta completa mantiene continuidad al reiniciar el reloj. Graves y
    // medios desvían la trayectoria; el beat imprime pequeños golpes de giro.
    final orbitAngle =
        phase * direction +
        math.sin(phase * 2) * (0.12 + frame.mid * 0.44) +
        math.sin(phase * 3) * frame.bass * 0.22 +
        math.sin(phase * 7) * frame.beat * 0.1;

    canvas.save();

    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _electricColor(0, frame.bass).withValues(alpha: 0.72),
        _electricColor(0.32, frame.mid),
        _electricColor(0.68, frame.treble),
        _electricColor(1, frame.beat).withValues(alpha: 0.9),
      ],
      stops: const [0, 0.36, 0.7, 1],
    ).createShader(bounds.inflate(size.width * 0.12));

    // Varias capas dibujadas de atrás hacia delante crean el aspecto de
    // cintas de plasma de los visualizadores clásicos, sin encerrar la forma
    // en una portada cuadrada.
    for (var strand = 0; strand < strandCount; strand++) {
      final normalized = strandCount == 1 ? 0.5 : strand / (strandCount - 1);
      final path = _electricWavePath(
        size: size,
        strand: strand,
        strandCount: strandCount,
        fullCanvas: fullCanvas,
        orbitAngle: orbitAngle,
      );
      final tone = _spectrumAt((normalized + time * 0.11) % 1.0);
      final depth = 1 - (normalized - 0.5).abs() * 1.35;
      final pulse = 1 + frame.beat * (0.42 + depth * 0.5);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth =
              size.shortestSide *
              (0.034 + tone * 0.028 + energy * 0.018) *
              pulse
          ..shader = shader
          ..color = Colors.white.withValues(alpha: 0.12 + tone * 0.1)
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.shortestSide * (0.025 + frame.bass * 0.022),
          ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth =
              size.shortestSide * (0.0036 + tone * 0.004 + frame.beat * 0.002)
          ..shader = shader
          ..blendMode = BlendMode.plus,
      );
    }

    // Una onda fina y nerviosa aporta la vibración de agudos que caracterizaba
    // a los modos de pantalla completa de Windows Media Player.
    for (var echo = 0; echo < 3; echo++) {
      final path = _electricTracePath(
        size: size,
        echo: echo,
        fullCanvas: fullCanvas,
        orbitAngle: orbitAngle,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.shortestSide * (0.0024 + frame.treble * 0.003)
          ..shader = shader
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            1.4 + frame.treble * 4.5,
          ),
      );
    }

    _paintElectricSparks(canvas, size, shader, fullCanvas, orbitAngle);
    canvas.restore();
  }

  Path _electricWavePath({
    required Size size,
    required int strand,
    required int strandCount,
    required bool fullCanvas,
    required double orbitAngle,
  }) {
    final path = Path();
    final steps = fullCanvas ? 144 : 104;
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final span = fullCanvas ? diagonal * 1.22 : size.width * 1.24;
    final center = size.center(Offset.zero);
    final strandPosition = strand / (strandCount - 1);
    final signedPosition = strandPosition * 2 - 1;
    final strandPhase = signedPosition * 1.72 + strand * 0.29;
    final baseAmplitude =
        size.height *
        (fullCanvas ? 0.22 : 0.18) *
        (0.72 + frame.bass * 0.76 + frame.beat * 0.28);
    final laneOffset =
        signedPosition * size.height * (fullCanvas ? 0.12 : 0.105);

    for (var index = 0; index <= steps; index++) {
      final normalized = index / steps;
      final x = center.dx - span * 0.5 + normalized * span;
      final envelope =
          0.55 +
          math.pow(math.sin(normalized * math.pi), 1.25).toDouble() * 0.45;
      final broad = math.sin(
        normalized * math.pi * (2.15 + strandPosition * 0.72) +
            phase * (0.66 + strandPosition * 0.16) +
            strandPhase,
      );
      final fold = math.sin(
        normalized * math.pi * (5.2 + frame.mid * 2.6) -
            phase * (0.94 + strandPosition * 0.11) -
            strandPhase * 0.6,
      );
      final shimmer = math.sin(
        normalized * math.pi * (18 + strand * 0.55) +
            phase * (3.1 + frame.treble * 2.7) +
            strand,
      );
      final localSpectrum = _spectrumAt(normalized);
      final spectralRipple =
          math.sin(
            normalized * math.pi * (9.5 + strandPosition * 3.2) -
                phase * (1.42 + strandPosition * 0.17) +
                strandPhase,
          ) *
          baseAmplitude *
          (0.04 + localSpectrum * 0.25);
      final y =
          center.dy +
          laneOffset * math.cos(normalized * math.pi * 2 + phase * 0.28) +
          broad * baseAmplitude * envelope +
          fold * baseAmplitude * (0.12 + frame.mid * 0.15) +
          spectralRipple * envelope +
          shimmer * size.height * frame.treble * 0.012;
      final circularBend =
          (normalized - 0.5) * (0.42 + frame.mid * 1.05) +
          math.sin(normalized * math.pi * 2 - phase * 2) *
              (0.035 + frame.beat * 0.11) +
          signedPosition * frame.bass * 0.09;
      final point = _rotateAround(
        Offset(x, y),
        center,
        orbitAngle + circularBend,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  Path _electricTracePath({
    required Size size,
    required int echo,
    required bool fullCanvas,
    required double orbitAngle,
  }) {
    final path = Path();
    final steps = fullCanvas ? 160 : 120;
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final span = fullCanvas ? diagonal * 1.2 : size.width * 1.2;
    final center = size.center(Offset.zero);
    final mirror = echo.isEven ? 1.0 : -1.0;
    for (var index = 0; index <= steps; index++) {
      final normalized = index / steps;
      final x = center.dx - span * 0.5 + normalized * span;
      final envelope = math.sin(normalized * math.pi);
      final sweep = math.sin(
        normalized * math.pi * (3.2 + echo * 0.42) +
            phase * (1.14 + echo * 0.13),
      );
      final vibration = math.sin(
        normalized * math.pi * (31 + echo * 5) - phase * 6.2 + echo,
      );
      final localSpectrum = _spectrumAt(normalized);
      final y =
          center.dy +
          mirror * sweep * size.height * (0.15 + frame.mid * 0.16) +
          vibration *
              size.height *
              (0.005 + frame.treble * 0.014 + localSpectrum * 0.025) *
              envelope +
          (echo - 1) * size.height * 0.026;
      final circularBend =
          (normalized - 0.5) * (0.35 + frame.mid * 0.8) +
          math.sin(normalized * math.pi * 2 + phase * 3 + echo) *
              frame.beat *
              0.09;
      final point = _rotateAround(
        Offset(x, y),
        center,
        orbitAngle + circularBend,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  void _paintElectricSparks(
    Canvas canvas,
    Size size,
    Shader shader,
    bool fullCanvas,
    double orbitAngle,
  ) {
    final random = math.Random(seed ^ 0x00C0FFEE);
    final count = fullCanvas ? 72 : 42;
    final sparkPaint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus;
    for (var index = 0; index < count; index++) {
      final normalized = random.nextDouble();
      final sweep = math.sin(normalized * math.pi * 3.2 + phase * 1.14);
      final spectralEnergy = _spectrumAt(normalized);
      final activity =
          (0.12 +
              spectralEnergy * 0.72 +
              frame.treble * 0.34 +
              frame.beat * 0.72) *
          (0.55 + random.nextDouble() * 0.45);
      final drift = math.sin(phase * (1.2 + random.nextDouble()) + index) * 8;
      final rawPoint = Offset(
        normalized * size.width + drift,
        size.height * 0.5 +
            sweep * size.height * (0.15 + frame.mid * 0.16) +
            (random.nextDouble() - 0.5) * size.height * 0.24 * activity,
      );
      final point = _rotateAround(
        rawPoint,
        size.center(Offset.zero),
        orbitAngle +
            (normalized - 0.5) * (0.38 + frame.mid * 0.9) +
            math.sin(normalized * math.pi * 2 - phase * 2) * frame.beat * 0.08,
      );
      final radius =
          0.55 + random.nextDouble() * 1.25 + frame.treble * 1.9 + frame.beat;
      canvas.drawCircle(point, radius, sparkPaint);
      if (frame.beat > 0.48 && index % 11 == 0) {
        final flare = size.shortestSide * (0.014 + frame.beat * 0.018);
        canvas.drawLine(
          point - Offset(flare, 0),
          point + Offset(flare, 0),
          sparkPaint..strokeWidth = 0.8 + frame.beat,
        );
        canvas.drawLine(
          point - Offset(0, flare),
          point + Offset(0, flare),
          sparkPaint,
        );
      }
    }
  }

  void _paintCosmicOrbs(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final camera = Offset(
      size.width * (0.49 + math.sin(phase) * (0.07 + frame.beat * 0.025)),
      size.height * (0.5 + math.cos(phase * 2) * (0.055 + frame.mid * 0.035)),
    );
    final seededRoll = ((seed.abs() % 997) / 997 - 0.5) * 0.24;
    final cameraRoll =
        seededRoll +
        math.sin(phase * (1 + seed.abs() % 2)) * (0.08 + frame.mid * 0.1) +
        math.sin(phase * 4) * frame.beat * 0.035;

    canvas.save();
    canvas.translate(camera.dx, camera.dy);
    canvas.rotate(cameraRoll);
    canvas.translate(-camera.dx, -camera.dy);

    _paintCosmicNebula(canvas, size, camera);
    _paintCosmicStars(canvas, size, camera, fullCanvas);
    _paintCosmicTunnel(canvas, size, camera, fullCanvas);
    _paintTravellingOrbs(canvas, size, camera, fullCanvas);
    canvas.restore();
  }

  void _paintCosmicNebula(Canvas canvas, Size size, Offset camera) {
    final shortest = size.shortestSide;
    for (var cloud = 0; cloud < 5; cloud++) {
      final angle = phase * (cloud.isEven ? 1 : -1) + cloud * 1.37;
      final reach = Offset(
        math.cos(angle) * size.width * (0.2 + cloud * 0.035),
        math.sin(angle * 1.17) * size.height * (0.17 + cloud * 0.025),
      );
      final radius =
          shortest *
          (0.25 + cloud * 0.055 + frame.bass * 0.09 + frame.level * 0.04);
      canvas.drawCircle(
        camera + reach,
        radius,
        Paint()
          ..color = _cosmicColor(
            cloud / 5 + 0.11,
            alpha: 0.045 + frame.mid * 0.055,
          )
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.72),
      );
    }
  }

  void _paintCosmicTunnel(
    Canvas canvas,
    Size size,
    Offset camera,
    bool fullCanvas,
  ) {
    // Mantiene densidad visual sin recalcular decenas de miles de vértices por
    // cuadro en un teléfono: 8/6 cintas y tres filamentos siguen cubriendo todo
    // el lienzo, mientras el glow completa el volumen aparente.
    final ribbonCount = fullCanvas ? 8 : 6;
    final bounds = (Offset.zero & size).inflate(size.shortestSide * 0.18);
    for (var ribbon = 0; ribbon < ribbonCount; ribbon++) {
      final normalized = ribbon / math.max(1, ribbonCount - 1);
      final spectrum = _spectrumAt(normalized);
      final random = math.Random(seed ^ (ribbon * 0x45D9F3B));
      final directionAngle = random.nextDouble() * math.pi * 2;
      final shader = LinearGradient(
        begin: Alignment(-math.cos(directionAngle), -math.sin(directionAngle)),
        end: Alignment(math.cos(directionAngle), math.sin(directionAngle)),
        colors: [
          _cosmicColor(normalized, alpha: 0.22),
          _cosmicColor(normalized + 0.24, alpha: 0.92),
          _cosmicColor(normalized + 0.52, alpha: 1),
          _cosmicColor(normalized + 0.78, alpha: 0.9),
          _cosmicColor(normalized + 1, alpha: 0.2),
        ],
        stops: const [0, 0.22, 0.5, 0.78, 1],
      ).createShader(bounds);
      final centerPath = _cosmicRibbonPath(
        size: size,
        camera: camera,
        ribbon: ribbon,
        filament: 0,
        fullCanvas: fullCanvas,
      );

      canvas.drawPath(
        centerPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth =
              size.shortestSide *
              (0.032 +
                  frame.bass * 0.045 +
                  spectrum * 0.025 +
                  frame.beat * 0.03)
          ..shader = shader
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.shortestSide * (0.022 + frame.bass * 0.026),
          ),
      );

      // Los filamentos separados hacen visible la torsión pseudo-3D de cada
      // cinta y evitan que el resultado se lea como una única forma central.
      for (var filament = -1; filament <= 1; filament++) {
        final filamentPath = filament == 0
            ? centerPath
            : _cosmicRibbonPath(
                size: size,
                camera: camera,
                ribbon: ribbon,
                filament: filament.toDouble(),
                fullCanvas: fullCanvas,
              );
        canvas.drawPath(
          filamentPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth =
                size.shortestSide *
                (0.0014 +
                    frame.treble * 0.0028 +
                    spectrum * 0.0018 +
                    (filament == 0 ? frame.beat * 0.002 : 0))
            ..shader = shader
            ..blendMode = BlendMode.plus
            ..maskFilter = filament == 0
                ? MaskFilter.blur(BlurStyle.normal, 1.2 + frame.treble * 3.2)
                : null,
        );
      }
    }
  }

  Path _cosmicRibbonPath({
    required Size size,
    required Offset camera,
    required int ribbon,
    required double filament,
    required bool fullCanvas,
  }) {
    final random = math.Random(seed ^ (ribbon * 0x27D4EB2D));
    final baseAngle = random.nextDouble() * math.pi * 2;
    final lane = (random.nextDouble() - 0.5) * size.shortestSide * 0.62;
    final depthPhase = random.nextDouble() * math.pi * 2;
    final wavePhase = random.nextDouble() * math.pi * 2;
    final waveCount = 1.45 + random.nextDouble() * 2.3;
    final depthTurns = 1.25 + random.nextDouble() * 2.15;
    final direction = random.nextBool() ? 1.0 : -1.0;
    final speed = 1 + ribbon % 3;
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final steps = fullCanvas ? 140 : 104;
    final path = Path();

    for (var step = 0; step <= steps; step++) {
      final normalized = step / steps;
      final localSpectrum = _spectrumAt(normalized);
      final travellingPhase =
          phase * direction * (speed + frame.bass * 0.34 + frame.beat * 0.5);
      final depthAngle =
          normalized * math.pi * 2 * depthTurns + travellingPhase + depthPhase;
      final depth = math.sin(depthAngle);
      final perspective = 0.68 + (depth + 1) * 0.25;
      final along = (normalized - 0.5) * diagonal * 2.3;
      final bend =
          math.sin(
            normalized * math.pi * 2 * waveCount +
                travellingPhase * (0.72 + frame.mid * 0.48) +
                wavePhase,
          ) *
          size.shortestSide *
          (0.11 + frame.bass * 0.17 + localSpectrum * 0.12);
      final changeOfDirection =
          math.sin(
            normalized * math.pi * (5 + ribbon % 4) -
                phase * direction * (2 + frame.mid * 2.5) +
                depthPhase,
          ) *
          size.shortestSide *
          (0.025 + frame.mid * 0.105 + frame.beat * 0.035);
      final vibration =
          math.sin(
            normalized * math.pi * (28 + ribbon % 7) +
                phase * direction * (5 + frame.treble * 5) +
                wavePhase,
          ) *
          size.shortestSide *
          (0.002 + frame.treble * 0.023 + localSpectrum * 0.009);
      final ribbonWidth =
          filament *
          size.shortestSide *
          (0.01 + frame.bass * 0.025 + frame.beat * 0.008) *
          (0.28 + (math.cos(depthAngle) + 1) * 0.5);
      final roll =
          baseAngle +
          math.sin(phase * (1 + ribbon % 2) + depthPhase) *
              (0.12 + frame.mid * 0.25) +
          math.sin(phase * 4 + ribbon) * frame.beat * 0.055;
      final local = Offset(
        along * perspective,
        (lane + bend + changeOfDirection + vibration + ribbonWidth) *
            perspective,
      );
      final point =
          camera +
          Offset(
            local.dx * math.cos(roll) - local.dy * math.sin(roll),
            local.dx * math.sin(roll) + local.dy * math.cos(roll),
          );
      if (step == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  void _paintCosmicStars(
    Canvas canvas,
    Size size,
    Offset camera,
    bool fullCanvas,
  ) {
    final random = math.Random(seed ^ 0x51A7F1E1);
    final starCount = fullCanvas ? 92 : 56;
    for (var star = 0; star < starCount; star++) {
      final angle = random.nextDouble() * math.pi * 2;
      final baseDepth = random.nextDouble();
      final speed = 1 + star % 3;
      final reactiveSpeed = speed + frame.bass * 0.7 + frame.beat * 1.25;
      final depth = (baseDepth + time * reactiveSpeed) % 1.0;
      final previousDepth = math.max(
        0.0,
        depth - 0.018 - frame.treble * 0.045 - frame.beat * 0.025,
      );
      final perspective = math.pow(depth, 1.72).toDouble();
      final previousPerspective = math.pow(previousDepth, 1.72).toDouble();
      final radialWobble =
          math.sin(phase * (1 + star % 2) + star * 0.41) * frame.mid * 0.12;
      final direction = Offset(
        math.cos(angle + radialWobble),
        math.sin(angle + radialWobble),
      );
      final ellipse = Offset(
        direction.dx * size.width * 0.78,
        direction.dy * size.height * 0.78,
      );
      final point = camera + ellipse * perspective;
      final previous = camera + ellipse * previousPerspective;
      final brightness = 0.16 + depth * 0.56 + frame.treble * 0.28;
      final color = _cosmicColor(
        star / starCount + depth * 0.18,
        alpha: brightness.clamp(0.0, 0.95).toDouble(),
      );
      canvas.drawLine(
        previous,
        point,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth =
              0.45 + depth * 1.8 + frame.treble * 1.35 + frame.beat * 0.4
          ..color = color
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _paintTravellingOrbs(
    Canvas canvas,
    Size size,
    Offset camera,
    bool fullCanvas,
  ) {
    final random = math.Random(seed ^ 0x0B17C05A);
    final orbCount = fullCanvas ? 4 : 3;
    for (var orb = 0; orb < orbCount; orb++) {
      final baseTravel = random.nextDouble();
      final lane = random.nextDouble();
      final baseRadius = random.nextDouble();
      final cycles = 1 + orb % 2;
      final travel =
          (baseTravel +
              time * (cycles + frame.bass * 0.24 + frame.beat * 0.5)) %
          1.0;
      final orbSpectrum = _spectrumAt(orb / math.max(1, orbCount - 1));
      final position = _cosmicOrbPosition(size, camera, travel, lane, orb);
      final radius =
          size.shortestSide *
          (0.005 + baseRadius * 0.012 + frame.bass * 0.007) *
          (0.68 + math.sin(travel * math.pi) * 0.46 + frame.beat * 0.18);
      final color = _cosmicColor(orb / orbCount + travel * 0.28, alpha: 0.68);

      final trail = Path();
      const trailSteps = 10;
      for (var step = 0; step <= trailSteps; step++) {
        final trailTravel =
            (travel - step * (0.008 + frame.treble * 0.003)) % 1.0;
        final trailPoint = _cosmicOrbPosition(
          size,
          camera,
          trailTravel,
          lane,
          orb,
        );
        if (step == 0) {
          trail.moveTo(trailPoint.dx, trailPoint.dy);
        } else {
          trail.lineTo(trailPoint.dx, trailPoint.dy);
        }
      }
      canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = radius * (0.22 + frame.mid * 0.3)
          ..color = color.withValues(alpha: 0.14 + orbSpectrum * 0.24)
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            radius * (0.3 + frame.treble * 0.26),
          ),
      );

      final glowBounds = Rect.fromCircle(
        center: position,
        radius: radius * 2.8,
      );
      canvas.drawCircle(
        position,
        radius * 2.3,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.56),
              color.withValues(alpha: 0.42),
              _cosmicColor(orb / orbCount + 0.32, alpha: 0.12),
              Colors.transparent,
            ],
            stops: const [0, 0.12, 0.5, 1],
          ).createShader(glowBounds)
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            radius * (0.14 + frame.bass * 0.24),
          ),
      );
      canvas.drawCircle(
        position,
        radius * (0.22 + frame.beat * 0.12),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.58 + frame.treble * 0.3)
          ..blendMode = BlendMode.plus,
      );

      if (frame.beat > 0.68) {
        final flare = radius * (1.2 + frame.beat * 1.8);
        final flarePaint = Paint()
          ..color = color.withValues(alpha: frame.beat * 0.7)
          ..strokeWidth = 0.8 + frame.beat * 1.3
          ..blendMode = BlendMode.plus;
        canvas.drawLine(
          position - Offset(flare, 0),
          position + Offset(flare, 0),
          flarePaint,
        );
        canvas.drawLine(
          position - Offset(0, flare),
          position + Offset(0, flare),
          flarePaint,
        );
      }
    }
  }

  Offset _cosmicOrbPosition(
    Size size,
    Offset camera,
    double travel,
    double lane,
    int orb,
  ) {
    final x = -size.width * 0.16 + travel * size.width * 1.32;
    final arc = math.sin(travel * math.pi * 2 + lane * math.pi * 2 + orb);
    final curl = math.cos(travel * math.pi * 4 - phase * 2 + orb * 0.7);
    final targetY =
        size.height * (0.12 + lane * 0.76) +
        arc * size.height * (0.09 + frame.mid * 0.14) +
        curl * size.height * frame.treble * 0.025;
    final cameraPull = math.sin(travel * math.pi) * frame.bass * 0.08;
    return Offset(
      _lerp(x, camera.dx, cameraPull),
      _lerp(targetY, camera.dy, cameraPull * 0.72),
    );
  }

  Color _cosmicColor(double offset, {double alpha = 1}) {
    final seedHue = (seed.abs() % 360).toDouble();
    // El abanico no ocupa siempre los 360°: así el giro de la base cromática
    // es perceptible en vez de parecer el mismo arcoíris desplazado. Dos vueltas
    // por ciclo mantienen continuidad y hacen visible el cambio en pocos s.
    final audioShift =
        frame.bass * 44 +
        frame.mid * 118 +
        frame.treble * 214 +
        frame.beat * 76;
    final hueSpan = 190 + frame.mid * 88 + frame.treble * 58;
    final hue =
        (seedHue +
            time * 720 +
            audioShift +
            offset * hueSpan +
            math.sin((offset + time) * math.pi * 2) * frame.beat * 24) %
        360;
    return HSVColor.fromAHSV(
      alpha.clamp(0.0, 1.0).toDouble(),
      hue,
      (0.72 + frame.treble * 0.2 + frame.beat * 0.08)
          .clamp(0.0, 1.0)
          .toDouble(),
      (0.74 + frame.level * 0.22 + frame.beat * 0.04)
          .clamp(0.0, 1.0)
          .toDouble(),
    ).toColor();
  }

  Color _electricColor(double position, double tone) {
    final seedHue = (seed.abs() % 360).toDouble();
    // La oscilación sembrada evita una secuencia idéntica entre canciones,
    // pero usa un número entero de vueltas para cerrar el ciclo sin saltos.
    final harmonic = 1 + seed.abs() % 4;
    final wandering =
        math.sin((time * harmonic + position) * math.pi * 2) *
        (22 + frame.mid * 42);
    final audioShift =
        frame.bass * 48 +
        frame.mid * 104 +
        frame.treble * 188 +
        frame.beat * 82;
    final hue =
        (seedHue +
            time * 720 +
            wandering +
            audioShift +
            position * (210 + frame.treble * 110)) %
        360;
    return HSVColor.fromAHSV(
      1,
      hue,
      (0.76 + frame.treble * 0.18 + frame.beat * 0.06)
          .clamp(0.0, 1.0)
          .toDouble(),
      (0.76 + frame.level * 0.18 + tone * 0.1).clamp(0.0, 1.0).toDouble(),
    ).toColor();
  }

  Color _fluidParticleColor(
    double position,
    double band,
    double tone, {
    double alpha = 1,
  }) {
    final seedHue = (seed.abs() % 360).toDouble();
    final audioShift =
        frame.bass * 38 +
        frame.mid * 112 +
        frame.treble * 196 +
        frame.beat * 68;
    final hue =
        (seedHue +
            time * 720 +
            audioShift +
            position * (145 + frame.treble * 105) +
            band * (82 + frame.mid * 118)) %
        360;
    return HSVColor.fromAHSV(
      alpha.clamp(0.0, 1.0).toDouble(),
      hue,
      (0.7 + frame.treble * 0.2 + tone * 0.08).clamp(0.0, 1.0).toDouble(),
      (0.68 + frame.level * 0.18 + tone * 0.14).clamp(0.0, 1.0).toDouble(),
    ).toColor();
  }

  Offset _rotateAround(Offset point, Offset center, double angle) {
    final local = point - center;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    return center +
        Offset(
          local.dx * cosine - local.dy * sine,
          local.dx * sine + local.dy * cosine,
        );
  }

  double _toneAt(double normalized) {
    final value = normalized % 1.0;
    if (value < 1 / 3) {
      return _lerp(frame.bass, frame.mid, value * 3);
    }
    if (value < 2 / 3) {
      return _lerp(frame.mid, frame.treble, (value - 1 / 3) * 3);
    }
    return _lerp(frame.treble, frame.bass, (value - 2 / 3) * 3);
  }

  double _spectrumAt(double normalized) {
    final spectrum = frame.spectrum;
    if (spectrum.isEmpty) return _toneAt(normalized);
    final value = normalized.clamp(0.0, 1.0).toDouble();
    final position = value * (spectrum.length - 1);
    final lower = position.floor();
    final upper = math.min(lower + 1, spectrum.length - 1);
    return _lerp(
      spectrum[lower],
      spectrum[upper],
      position - lower,
    ).clamp(0.0, 1.0).toDouble();
  }

  double _mirroredSpectrumAt(double normalized) {
    final value = normalized % 1.0;
    final mirrored = value <= 0.5 ? value * 2 : (1 - value) * 2;
    return _spectrumAt(mirrored);
  }

  Color _colorAt(double normalized) {
    final value = normalized.clamp(0.0, 1.0).toDouble();
    if (value < 0.5) return Color.lerp(colors[0], colors[1], value * 2)!;
    return Color.lerp(colors[1], colors[2], (value - 0.5) * 2)!;
  }

  double _lerp(double a, double b, double amount) => a + (b - a) * amount;

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.time != time ||
      oldDelegate.frame != frame ||
      oldDelegate.seed != seed ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.immersive != immersive ||
      oldDelegate.hasLiveAnalysis != hasLiveAnalysis;
}
