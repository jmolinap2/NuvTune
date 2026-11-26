import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Auris como personaje animable, no como una imagen que se desplaza.
/// Cabeza, cascos, torso, brazos y piernas se dibujan por separado.
class DancingAuris extends StatefulWidget {
  const DancingAuris({
    required this.song,
    required this.isPlaying,
    required this.energy,
    required this.beatImpulse,
    required this.size,
    super.key,
  });

  final Song song;
  final bool isPlaying;
  final double energy;
  final double beatImpulse;
  final double size;

  @override
  State<DancingAuris> createState() => _DancingAurisState();
}

class _DancingAurisState extends State<DancingAuris>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _moodFor(widget.song).loop,
  );

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant DancingAuris oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _clock.duration = _moodFor(widget.song).loop;
      _clock.value = 0;
    }
    if (oldWidget.isPlaying != widget.isPlaying) _syncMotion();
  }

  void _syncMotion() {
    final animate =
        widget.isPlaying &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodFor(widget.song);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => _AurisPoseAtlas(
            size: widget.size,
            phase: _clock.value,
            energy: widget.energy,
            beatImpulse: widget.beatImpulse,
            mood: mood,
          ),
        ),
      ),
    );
  }
}

/// Visualizador completo de Auris. El mismo rig se escala al escenario.
class AurisDanceVisualizer extends StatefulWidget {
  const AurisDanceVisualizer({
    required this.song,
    required this.isPlaying,
    required this.reduceMotion,
    required this.energy,
    required this.beatImpulse,
    super.key,
  });

  final Song song;
  final bool isPlaying;
  final bool reduceMotion;
  final double energy;
  final double beatImpulse;

  @override
  State<AurisDanceVisualizer> createState() => _AurisDanceVisualizerState();
}

class _AurisDanceVisualizerState extends State<AurisDanceVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _moodFor(widget.song).loop,
  );

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AurisDanceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _clock.duration = _moodFor(widget.song).loop;
      _clock.value = 0;
    }
    if (oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    final animate =
        widget.isPlaying &&
        !widget.reduceMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodFor(widget.song);
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(
            constraints.maxWidth * 0.72,
            constraints.maxHeight * 0.78,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFFFFA13B,
                      ).withValues(alpha: 0.12 + widget.energy * 0.22),
                      const Color(0xFF050810),
                    ],
                  ),
                ),
              ),
              Center(
                child: _AurisPoseAtlas(
                  size: size,
                  phase: _clock.value,
                  energy: widget.energy,
                  beatImpulse: widget.beatImpulse,
                  mood: mood,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Reproduce una sola celda de la hoja 4×4. Nunca se pinta la hoja completa:
/// cada tick selecciona una pose y la recorta en el canvas, por lo que no hay
/// cuadrícula, tablero de transparencia ni títulos visibles en pantalla.
class _AurisPoseAtlas extends StatefulWidget {
  const _AurisPoseAtlas({
    required this.size,
    required this.phase,
    required this.energy,
    required this.beatImpulse,
    required this.mood,
  });

  final double size;
  final double phase;
  final double energy;
  final double beatImpulse;
  final _DanceMood mood;

  @override
  State<_AurisPoseAtlas> createState() => _AurisPoseAtlasState();
}

class _AurisPoseAtlasState extends State<_AurisPoseAtlas> {
  static const _asset = AssetImage('assets/images/auris-dance-loop-v2.png');
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listener ??= ImageStreamListener((info, _) {
      if (mounted) setState(() => _image = info.image);
    });
    final stream = _asset.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    _stream?.removeListener(_listener!);
    _stream = stream..addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _image == null
        ? _AurisPuppetPainter(
            phase: widget.phase,
            energy: widget.energy,
            beatImpulse: widget.beatImpulse,
            mood: widget.mood,
          )
        : _AurisAtlasPainter(
            image: _image!,
            phase: widget.phase,
            energy: widget.energy,
            beatImpulse: widget.beatImpulse,
            mood: widget.mood,
          );
    return CustomPaint(size: Size.square(widget.size), painter: painter);
  }
}

class _AurisAtlasPainter extends CustomPainter {
  const _AurisAtlasPainter({
    required this.image,
    required this.phase,
    required this.energy,
    required this.beatImpulse,
    required this.mood,
  });

  final ui.Image image;
  final double phase;
  final double energy;
  final double beatImpulse;
  final _DanceMood mood;

  // Orden coreografiado: vuelve a las poses neutras entre pasos amplios para
  // que el ciclo cierre sin un salto brusco de una silueta a otra.
  static const _danceLoop = <int>[
    0,
    1,
    2,
    3,
    2,
    1,
    0,
    4,
    5,
    6,
    7,
    6,
    5,
    4,
    0,
    8,
    9,
    10,
    11,
    10,
    9,
    8,
    0,
    12,
    13,
    14,
    15,
    14,
    13,
    12,
    0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const columns = 4;
    const rows = 4;
    final loopIndex = (phase * _danceLoop.length).floor() % _danceLoop.length;
    final baseFrame = _danceLoop[loopIndex];
    // Un golpe destacado adelanta una pose: hace que los acentos no sean
    // únicamente un cambio de velocidad uniforme.
    final frame = beatImpulse > 0.55
        ? _danceLoop[(loopIndex + 2) % _danceLoop.length]
        : baseFrame;
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final source = Rect.fromLTWH(
      (frame % columns) * cellWidth,
      (frame ~/ columns) * cellHeight,
      cellWidth,
      cellHeight,
    );
    final pulse = 1 + beatImpulse * 0.045;
    final renderedSize = size.shortestSide * 0.98 * pulse;
    final destination = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: renderedSize,
      height: renderedSize,
    );
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _AurisAtlasPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.phase != phase ||
      oldDelegate.energy != energy ||
      oldDelegate.beatImpulse != beatImpulse ||
      oldDelegate.mood != mood;
}

enum _DanceMood {
  gentle(loop: Duration(milliseconds: 3600), amplitude: 0.55),
  balanced(loop: Duration(milliseconds: 2300), amplitude: 1),
  energetic(loop: Duration(milliseconds: 1350), amplitude: 1.45);

  const _DanceMood({required this.loop, required this.amplitude});

  final Duration loop;
  final double amplitude;
}

_DanceMood _moodFor(Song song) {
  final genre = song.genre?.toLowerCase() ?? '';
  if (const [
    'electro',
    'dance',
    'house',
    'edm',
    'techno',
    'metal',
    'rock',
  ].any(genre.contains)) {
    return _DanceMood.energetic;
  }
  if (genre.contains('ambient') ||
      genre.contains('classical') ||
      genre.contains('acoustic') ||
      genre.contains('jazz')) {
    return _DanceMood.gentle;
  }
  return _DanceMood.balanced;
}

/// Rig vectorial compacto: piernas y cabeza responden de forma independiente.
class _AurisPuppetPainter extends CustomPainter {
  const _AurisPuppetPainter({
    required this.phase,
    required this.energy,
    required this.beatImpulse,
    required this.mood,
  });

  final double phase;
  final double energy;
  final double beatImpulse;
  final _DanceMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 200;
    final time = phase * math.pi * 2;
    final activity = (0.32 + energy * 0.68) * mood.amplitude;
    final step = math.sin(time) * activity;
    final bounce =
        math.max(0.0, math.sin(time)) * 11 * activity + beatImpulse * 18;
    final headTilt = step * 0.14 + math.sin(time * 2) * 0.025;

    canvas
      ..translate(size.width / 2, size.height * 0.56 - bounce * scale)
      ..scale(scale);

    final orange = const Color(0xFFFFA12D);
    final gold = const Color(0xFFFFD15A);
    final black = const Color(0xFF0A0D13);
    final outline = Paint()
      ..color = orange.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final limb = Paint()
      ..color = black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.round;
    final limbGlow = Paint()
      ..color = orange.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 18), width: 172, height: 56),
      Paint()
        ..color = gold.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(const Offset(-78, 35), 7, Paint()..color = gold);

    void drawLeg(double side, double swing) {
      final hip = Offset(side * 20, 48);
      final knee = Offset(side * (26 + swing * 12), 71 - swing.abs() * 5);
      final foot = Offset(side * (38 + swing * 22), 90 - swing * 14);
      final path = Path()
        ..moveTo(hip.dx, hip.dy)
        ..quadraticBezierTo(knee.dx, knee.dy, foot.dx, foot.dy);
      canvas.drawPath(path, limb);
      canvas.drawPath(path, limbGlow);
    }

    drawLeg(-1, step + beatImpulse * 0.8);
    drawLeg(1, -step + beatImpulse * 0.42);

    final torso = Rect.fromCenter(
      center: const Offset(0, 35),
      width: 68,
      height: 72,
    );
    canvas.drawOval(
      torso,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFF313846), Color(0xFF080B11)],
        ).createShader(torso),
    );
    canvas.drawOval(torso, outline);

    void drawArm(double side, double swing) {
      final shoulder = Offset(side * 32, 20);
      final elbow = Offset(side * (48 + swing * 14), 35 - swing * 16);
      final hand = Offset(side * (57 + swing * 18), 48 - swing * 30);
      final path = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy);
      canvas.drawPath(path, limb);
      canvas.drawPath(path, limbGlow);
    }

    drawArm(-1, -step * 0.75 + beatImpulse * 0.3);
    drawArm(1, step * 0.75 + beatImpulse * 0.45);

    canvas.save();
    canvas
      ..translate(0, -28)
      ..rotate(headTilt);
    final head = Rect.fromCircle(center: Offset.zero, radius: 55);
    canvas.drawCircle(
      Offset.zero,
      55,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.32, -0.5),
          colors: [Color(0xFF384251), Color(0xFF090C13)],
        ).createShader(head),
    );
    canvas.drawCircle(Offset.zero, 55, outline);
    final headset = Paint()
      ..color = orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 61),
      math.pi + 0.35,
      math.pi - 0.7,
      false,
      headset,
    );
    for (final side in [-1.0, 1.0]) {
      final ear = Rect.fromCenter(
        center: Offset(side * 55, 2),
        width: 22,
        height: 34,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(ear, const Radius.circular(11)),
        Paint()..color = const Color(0xFF10141D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(ear, const Radius.circular(11)),
        outline,
      );
    }
    final wave = Path()..moveTo(-27, 0);
    for (var index = 0; index < 10; index++) {
      final x = -27 + index * 6;
      final height = 6 + ((index * 7) % 13) + energy * 9;
      wave
        ..lineTo(x + 3, -height / 2)
        ..lineTo(x + 6, height / 2);
    }
    canvas.drawPath(
      wave,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AurisPuppetPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.energy != energy ||
      oldDelegate.beatImpulse != beatImpulse ||
      oldDelegate.mood != mood;
}
