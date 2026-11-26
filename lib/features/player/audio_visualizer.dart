import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/platform/visualizer_power_monitor.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/dancing_auris.dart';
import 'package:nuvtune/features/player/visualizer_color_map.dart';
import 'package:nuvtune/features/player/visualizer_dynamics.dart';
import 'package:nuvtune/features/player/visualizer_quality.dart';
import 'package:nuvtune/features/player/visualizer_motion_tuning.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';
import 'package:nuvtune/shared/widgets/option_picker.dart';

final Stopwatch _sharedVisualizerClock = Stopwatch()..start();
final _visualizerPowerMonitorProvider =
    Provider.autoDispose<VisualizerPowerMonitor>(
      (ref) => VisualizerPowerMonitor(),
    );
final _visualizerPowerStateProvider =
    StreamProvider.autoDispose<VisualizerPowerState>(
      (ref) => ref.watch(_visualizerPowerMonitorProvider).states,
    );

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
  bool _systemReduceMotion = false;
  bool _userReduceEffects = false;

  // Única fuente de "qué está haciendo la música" (energía, beatImpulse,
  // peak-hold): antes cada painter calculaba su propia versión de estos
  // valores con umbrales distintos. Ver visualizer_dynamics.dart.
  VisualizerDynamicsEngine _dynamicsEngine = VisualizerDynamicsEngine();
  int _engineBandCount = const VisualizerDynamicsConfig().bandCount;
  String _engineMotionKey = '';
  VisualizerDynamicsState? _lastDynamics;
  int _lastFrameBucket = -1;
  bool? _lastHadLiveAnalysis;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _motion.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    _reduceMotion = _systemReduceMotion || _userReduceEffects;
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant ReactiveAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id ||
        (oldWidget.isPlaying && !widget.isPlaying)) {
      _dynamicsEngine.reset();
      _lastDynamics = null;
      _lastFrameBucket = -1;
    }
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
    final powerState =
        ref.watch(_visualizerPowerStateProvider).valueOrNull ??
        const VisualizerPowerState.normal();
    final requestedQuality = VisualizerQuality.byId(
      settings?.playerVisualizerQuality,
    );
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
    _userReduceEffects = motion.effectiveIntensity == 0;
    final reduceMotion = _systemReduceMotion || _userReduceEffects;
    final forceEco = reduceMotion || powerState.shouldReduceEffects;
    final quality = forceEco ? VisualizerQuality.eco : requestedQuality;
    _configureDynamics(quality.bandCount, motion);
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMotion();
      });
    }
    final renderFrameMicros =
        Duration.microsecondsPerSecond ~/ quality.targetFps;
    final settingIndex = settings?.playerVisualizerStyle ?? 0;
    final hasLiveAnalysis =
        analysis != null && !(settings?.directMode ?? false);
    final requested =
        widget.styleOverride ?? VisualizerStyle.fromIndex(settingIndex);
    final seed = _stableSongSeed(widget.song);
    final style = requested.resolveFor(seed);
    final colorMap = VisualizerColorMap.fromJsonString(
      settings?.visualizerColorMapJson,
    );
    final colorMode = VisualizerColorMode.byId(settings?.visualizerColorMode);
    final tuning = VisualizerMotionTuning.from(motion);
    final particleScale = switch (motion.effectiveParticles) {
      0 => 0.0,
      1 => 0.5,
      2 => 1.0,
      3 => 1.5,
      _ => 2.0,
    };

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
              builder: (context, child) {
                final nowMicros = _sharedVisualizerClock.elapsedMicroseconds;
                final frameBucket = nowMicros ~/ renderFrameMicros;
                if (_lastHadLiveAnalysis != hasLiveAnalysis) {
                  _dynamicsEngine.reset();
                  _lastDynamics = null;
                  _lastFrameBucket = -1;
                  _lastHadLiveAnalysis = hasLiveAnalysis;
                }
                if (_lastDynamics == null || frameBucket != _lastFrameBucket) {
                  _lastFrameBucket = frameBucket;
                  final effectiveFrame = _effectiveFrame(
                    hasLiveAnalysis ? analysis : null,
                  );
                  _lastDynamics = _dynamicsEngine.update(
                    effectiveFrame,
                    frameBucket * renderFrameMicros,
                  );
                }
                final renderMicros = frameBucket * renderFrameMicros;
                final dynamics = _lastDynamics!;
                final visualizer = style == VisualizerStyle.aurisDance
                    ? AurisDanceVisualizer(
                        song: widget.song,
                        isPlaying: widget.isPlaying,
                        reduceMotion: _reduceMotion,
                        energy: dynamics.energy,
                        beatImpulse: dynamics.beatImpulse,
                      )
                    : CustomPaint(
                        painter: _VisualizerPainter(
                          style: style,
                          time: (renderMicros % 14000000) / 14000000,
                          elapsedSeconds:
                              renderMicros / Duration.microsecondsPerSecond,
                          dynamics: dynamics,
                          colorMap: colorMap,
                          colorMode: colorMode,
                          randomColors:
                              settings?.visualizerRandomColors ?? false,
                          seed: seed,
                          isPlaying: widget.isPlaying,
                          immersive: widget.immersive,
                          hasLiveAnalysis: hasLiveAnalysis,
                          reduceMotion: _reduceMotion,
                          quality: quality,
                          tuning: tuning,
                          motionParticleScale: particleScale,
                        ),
                      );
                final showCompanion =
                    widget.immersive &&
                    style != VisualizerStyle.aurisDance &&
                    (settings?.aurisCameoEnabled ?? false);
                if (!showCompanion) return visualizer;
                final companionSize = math
                    .min(
                      widget.size * 0.26,
                      (widget.height ?? widget.size) * 0.3,
                    )
                    .clamp(72.0, 150.0)
                    .toDouble();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    visualizer,
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: DancingAuris(
                        key: ValueKey('dancing-auris-${widget.song.id}'),
                        song: widget.song,
                        size: companionSize,
                        isPlaying: widget.isPlaying,
                        energy: dynamics.energy,
                        beatImpulse: dynamics.beatImpulse,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _configureDynamics(int bandCount, MotionPreferences motion) {
    final key =
        '${motion.effectiveSmoothness}:'
        '${motion.effectiveBeatResponse}:${motion.effectiveIntensity}';
    if (_engineBandCount == bandCount && _engineMotionKey == key) return;
    _engineBandCount = bandCount;
    _engineMotionKey = key;
    final responsiveness = switch (motion.effectiveBeatResponse) {
      0 => 0.65,
      1 => 0.82,
      2 => 1.0,
      3 => 1.25,
      _ => 1.55,
    };
    final smoothness = switch (motion.effectiveSmoothness) {
      0 => 1.22,
      1 => 1.08,
      2 => 1.0,
      3 => 0.82,
      _ => 0.68,
    };
    _dynamicsEngine = VisualizerDynamicsEngine(
      config: VisualizerDynamicsConfig(
        bandCount: bandCount,
        attack: (0.55 * responsiveness).clamp(0.0, 1.0).toDouble(),
        release: (0.12 / smoothness).clamp(0.01, 1.0).toDouble(),
        levelBoost: responsiveness,
        bassBoost: responsiveness,
        midBoost: 0.92 + (responsiveness - 0.82) * 0.45,
        trebleBoost: 0.9 + (responsiveness - 0.82) * 0.35,
        beatImpulseDuration: Duration(milliseconds: (160 * smoothness).round()),
      ),
    );
    _lastDynamics = null;
    _lastFrameBucket = -1;
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

  // El mapa de colores gobierna siempre los estilos del visualizador. No se
  // cruza con «Color de los efectos»: esa preferencia tiñe la animación de la
  // carátula y su vista previa, no el visualizador. Dos ajustes decidiendo el
  // mismo color eran dos escritores del mismo dato.

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
      .read(settingsMutationProvider.notifier)
      .save(AppSettingsCompanion(playerVisualizerStyle: Value(choice.index)));
}

class _VisualizerPainter extends CustomPainter {
  const _VisualizerPainter({
    required this.style,
    required this.time,
    required this.elapsedSeconds,
    required this.dynamics,
    required this.colorMap,
    required this.colorMode,
    required this.randomColors,
    required this.seed,
    required this.isPlaying,
    required this.immersive,
    required this.hasLiveAnalysis,
    required this.reduceMotion,
    required this.quality,
    required this.tuning,
    required this.motionParticleScale,
  });

  final VisualizerStyle style;
  final double time;
  final double elapsedSeconds;
  final VisualizerDynamicsState dynamics;
  final VisualizerColorMap colorMap;
  final VisualizerColorMode colorMode;
  final bool randomColors;
  final int seed;
  final bool isPlaying;
  final bool immersive;
  final bool hasLiveAnalysis;
  final bool reduceMotion;
  final VisualizerQuality quality;
  final VisualizerMotionTuning tuning;
  final double motionParticleScale;

  double get phase => time * math.pi * 2;

  /// Presencia común de los painters: el silencio FFT puede descansar de
  /// verdad, mientras Ambient conserva una silueta tenue sin fingir beats.
  double get visualActivity {
    final raw = math
        .max(
          dynamics.energy,
          math.max(dynamics.treble * 0.9, renderBeatImpulse),
        )
        .clamp(0.0, 1.0)
        .toDouble();
    final curved = raw * raw * (3 - 2 * raw);
    return hasLiveAnalysis ? curved : math.max(0.22, curved);
  }

  double get visualPresence => 0.06 + visualActivity * 0.94;

  double get visualMotion => reduceMotion
      ? 0
      : ((0.05 + visualActivity * 0.95) * tuning.motionScale)
            .clamp(0.0, 1.8)
            .toDouble();

  double get renderGlow =>
      (dynamics.glow *
              quality.glowScale *
              (reduceMotion ? 0.42 : tuning.motionScale))
          .clamp(0.0, 1.0)
          .toDouble();

  // El glow se compone con gradientes y pasadas de stroke translúcidas. No
  // reintroducir MaskFilter.blur por primitiva: en el POCO/Mali provocó dos
  // fallos nativos de RenderThread y era el mayor coste de rasterización.

  double get renderParticleIntensity =>
      (dynamics.particleIntensity * (reduceMotion ? 0 : motionParticleScale))
          .clamp(0.0, 1.0)
          .toDouble();

  int particleBudget(int normalBudget) => math.max(
    0,
    (normalBudget * quality.particleScale * motionParticleScale).round(),
  );

  double get renderBeatImpulse =>
      dynamics.beatImpulse * (reduceMotion ? 0.28 : tuning.motionScale);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    _paintBackdrop(canvas, size);
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
      case VisualizerStyle.dynamicSpectrum:
        _paintSpectrum(canvas, size);
        break;
      case VisualizerStyle.electricWaves:
        _paintElectricWaves(canvas, size);
        break;
      case VisualizerStyle.cosmicOrbs:
        _paintCosmicOrbs(canvas, size);
        break;
      case VisualizerStyle.aurisDance:
        // La rama de widgets sustituye este painter antes de llegar aquí.
        _paintSpectrum(canvas, size);
        break;
    }
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final focalPoint = Alignment(
      math.sin(phase * 0.18) * 0.16,
      -0.08 + math.cos(phase * 0.14) * 0.08,
    );
    final activeCenter = Color.lerp(
      const Color(0xFF061127),
      const Color(0xFF130729),
      dynamics.hue * 0.72,
    )!;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: focalPoint,
          radius: 1.18,
          colors: [
            Color.lerp(
              const Color(0xFF050D20),
              activeCenter,
              0.18 + dynamics.energy * 0.36,
            )!,
            const Color(0xFF010613),
            const Color(0xFF01030A),
          ],
          stops: const [0, 0.58, 1],
        ).createShader(bounds),
    );
  }

  void _paintImmersiveAtmosphere(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final drift = Offset(
      math.sin(phase * 0.34) * size.width * 0.16,
      math.cos(phase * 0.27) * size.height * 0.09,
    );
    final glowRadius = size.shortestSide * (0.26 + dynamics.energy * 0.2);
    final glowBounds = Rect.fromCircle(
      center: center + drift,
      radius: glowRadius,
    );
    canvas.drawCircle(
      center + drift,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _reactiveColor(
              0.16,
              dynamics.bass,
              alpha: 0.025 + renderGlow * 0.14,
            ),
            _reactiveColor(
              0.72,
              dynamics.mid,
              alpha: 0.012 + renderGlow * 0.055,
            ),
            Colors.transparent,
          ],
          stops: const [0, 0.44, 1],
        ).createShader(glowBounds),
    );

    final random = math.Random(seed ^ 0x6A09E667);
    final normalParticleBudget = switch (style) {
      VisualizerStyle.ribbons => 48,
      VisualizerStyle.dynamicSpectrum => 20,
      VisualizerStyle.prism => 10,
      VisualizerStyle.electricWaves => 14,
      VisualizerStyle.cosmicOrbs => 10,
      VisualizerStyle.aurisDance => 0,
      VisualizerStyle.automatic => 20,
    };
    final scaledParticleBudget = particleBudget(normalParticleBudget);
    final ambientParticles = hasLiveAnalysis ? 0 : 4;
    final particleCount = reduceMotion
        ? ambientParticles
        : (ambientParticles + renderParticleIntensity * scaledParticleBudget)
              .round();
    final particlePaint = Paint();
    for (var index = 0; index < particleCount; index++) {
      final x = random.nextDouble();
      final baseY = random.nextDouble();
      final speed = 0.012 + random.nextDouble() * 0.026;
      final y = reduceMotion ? baseY : (baseY - time * speed) % 1.0;
      final tone = _spectrumAt(x);
      final point = Offset(
        size.width * x + (reduceMotion ? 0 : math.sin(phase * 0.3 + index) * 7),
        size.height * y,
      );
      canvas.drawCircle(
        point,
        0.35 + random.nextDouble() * 0.8 + tone * 1.25,
        particlePaint
          ..color = _reactiveColor(
            x,
            tone,
            alpha:
                (0.035 + tone * 0.34) * (0.28 + renderParticleIntensity * 0.72),
          ),
      );
    }
  }

  void _paintRibbons(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final shortest = size.shortestSide;
    final center = Offset(
      size.width * 0.5,
      size.height * (fullCanvas ? 0.46 : 0.5),
    );
    // El aro deja espacio real a las columnas. Antes nacía al 26 % del lado
    // corto y una barra solo podía crecer otro 19 %, por eso parecía un tambor
    // que resonaba en su sitio en vez de un espectro radial vivo.
    final baseRadius = shortest * (fullCanvas ? 0.18 : 0.175);
    final innerRadius = baseRadius + shortest * renderBeatImpulse * 0.035;
    final direction = seed.isEven ? 1.0 : -1.0;
    final rotationAngle = reduceMotion
        ? 0.0
        : elapsedSeconds *
                  math.pi *
                  2 *
                  tuning.rotationTurnsPerSecond *
                  direction +
              renderBeatImpulse * 0.16 * direction;
    // El aro de referencia necesita más trazos que bandas analíticas para
    // conservar su densidad. Se interpola el estado común; el perfil solo
    // reduce el muestreo donde realmente aporta ahorro.
    final count = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 64,
      (VisualizerQuality.eco, false) => 48,
      (VisualizerQuality.normal, true) => 96,
      (VisualizerQuality.normal, false) => 64,
      (VisualizerQuality.ultra, true) => 112,
      (VisualizerQuality.ultra, false) => 80,
    };
    final ringCount = fullCanvas
        ? switch (quality) {
            VisualizerQuality.eco => 2,
            VisualizerQuality.normal || VisualizerQuality.ultra => 3,
          }
        : 1;
    final ringBounds = Rect.fromCircle(center: center, radius: innerRadius);
    final ringShader = SweepGradient(
      transform: const GradientRotation(-math.pi / 2),
      colors: _gradientColors(alpha: 1).reversed.toList(growable: false),
    ).createShader(ringBounds);
    final haloRingShader = SweepGradient(
      transform: const GradientRotation(-math.pi / 2),
      colors: _gradientColors(
        alpha: 0.08 + renderGlow * 0.22,
      ).reversed.toList(growable: false),
    ).createShader(ringBounds);

    // El interior oscuro y el aro nítido evitan que el halo convierta el
    // motivo radial en una mancha. Es la misma jerarquía de las referencias:
    // halo amplio, cuerpo saturado y un núcleo luminoso localizado.
    canvas.drawCircle(
      center,
      innerRadius * 0.98,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF01040D),
            const Color(0xFF02091B),
            _reactiveColor(
              0.54,
              dynamics.energy,
              alpha: 0.035 + renderGlow * 0.055,
            ),
          ],
          stops: const [0, 0.72, 1],
        ).createShader(ringBounds),
    );
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * (0.006 + renderGlow * 0.006)
        ..shader = haloRingShader
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.0023
        ..shader = ringShader
        ..blendMode = BlendMode.plus,
    );

    for (var ring = 0; ring < ringCount; ring++) {
      final primary = ring == ringCount - 1;
      final ringRadius = ringCount == 1
          ? innerRadius
          : innerRadius * (0.72 + ring * 0.14);
      final ringAlpha = primary ? 1.0 : 0.12 + ring * 0.11;
      final ringDirection = ring.isOdd ? -1.0 : 1.0;
      final lengthScale = primary ? 1.0 : 0.24 + ring * 0.14;
      final bars = Path();
      final peakMarkers = Path();
      // El modo «por columna» necesita cada trazo por separado con su propia
      // intensidad; el modo «por fila» se conforma con la silueta común.
      final segments = <({Offset start, Offset end, double tone})>[];

      for (var index = 0; index < count; index++) {
        final normalized = index / count;
        final angle =
            normalized * math.pi * 2 * ringDirection -
            math.pi / 2 +
            rotationAngle;
        final tone = _mirroredSpectrumAt(normalized);
        final flutter = hasLiveAnalysis
            ? 1.0
            : 0.9 + math.sin(phase * 3.2 + index * 1.71 + ring * 1.3) * 0.1;
        final shapedTone = math.pow(tone, tuning.ribbonExponent).toDouble();
        final length =
            shortest *
            (0.016 +
                shapedTone * 0.25 * tuning.ribbonLengthScale * flutter +
                renderBeatImpulse * 0.045) *
            lengthScale;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final start = center + direction * ringRadius;
        final end = center + direction * (ringRadius + length);
        bars
          ..moveTo(start.dx, start.dy)
          ..lineTo(end.dx, end.dy);
        if (colorMode == VisualizerColorMode.column) {
          segments.add((start: start, end: end, tone: tone));
        }

        if (primary) {
          final peak = _mirroredPeakAt(normalized);
          if (peak > tone + 0.035) {
            final peakEnd =
                center +
                direction *
                    (ringRadius +
                        shortest *
                            (0.012 +
                                math
                                        .pow(peak, tuning.ribbonExponent)
                                        .toDouble() *
                                    0.25 *
                                    tuning.ribbonLengthScale +
                                renderBeatImpulse * 0.045));
            peakMarkers.addOval(
              Rect.fromCircle(center: peakEnd, radius: shortest * 0.0032),
            );
          }
        }
      }

      // Aquí «fila» es la distancia al aro: el degradado radial reparte el
      // mapa a lo largo de cada trazo, de modo que uno corto solo alcanza los
      // colores bajos. En «por columna» cada trazo se pinta con el color de su
      // propia intensidad. Antes ambos casos usaban un barrido por ángulo, así
      // que el color dependía de la posición en el aro y no de la fuerza.
      final maxLength =
          shortest *
          (0.016 + 0.25 * tuning.ribbonLengthScale + renderBeatImpulse * 0.045);
      Shader? radialRamp(double alpha) => _radialGradient(
        center: center,
        innerRadius: ringRadius,
        maxLength: maxLength * lengthScale,
        alpha: alpha,
      );

      if (primary && renderGlow > 0.08) {
        final glowAlpha = (0.08 + renderGlow * 0.22).clamp(0.0, 1.0).toDouble();
        canvas.drawPath(
          bars,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = shortest * (0.014 + renderGlow * 0.01)
            ..shader = radialRamp(glowAlpha)
            ..color = colorMap
                .colorAt(dynamics.energy)
                .withValues(alpha: glowAlpha)
            ..blendMode = BlendMode.plus,
        );
      }

      if (colorMode == VisualizerColorMode.row) {
        canvas.drawPath(
          bars,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = shortest * (primary ? 0.0095 : 0.0034)
            ..shader = radialRamp((0.9 * ringAlpha).clamp(0.0, 1.0).toDouble())
            ..blendMode = BlendMode.plus,
        );
      } else {
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = shortest * (primary ? 0.0095 : 0.0034)
          ..blendMode = BlendMode.plus;
        for (final segment in segments) {
          canvas.drawLine(
            segment.start,
            segment.end,
            strokePaint
              ..color = colorMap
                  .colorAt(segment.tone)
                  .withValues(alpha: (0.9 * ringAlpha).clamp(0.0, 1.0)),
          );
        }
      }

      if (primary) {
        canvas.drawPath(
          peakMarkers,
          Paint()
            ..shader = radialRamp(1)
            ..color = colorMap.colorAt(1)
            ..blendMode = BlendMode.plus,
        );
      }
    }

    final coreRadius = shortest * (0.018 + renderBeatImpulse * 0.007);
    final coreGlowRadius = coreRadius * 3.4;
    canvas.drawCircle(
      center,
      coreGlowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _reactiveColor(
              0.7,
              dynamics.energy,
              alpha: 0.08 + renderGlow * 0.18,
            ),
            Colors.transparent,
          ],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: coreGlowRadius))
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.003
        ..color = _peakColor(0.68, dynamics.energy)
        ..blendMode = BlendMode.plus,
    );
  }

  void _paintPrism(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final shortest = size.shortestSide;
    final direction = seed.isEven ? 1.0 : -1.0;
    final activity = visualActivity;
    final presence = visualPresence;
    final motion = visualMotion;
    final center =
        size.center(Offset.zero) +
        Offset(
          math.sin(phase * 2) *
              size.width *
              (0.004 + activity * 0.014 + dynamics.mid * 0.042) *
              motion,
          math.cos(phase * 3) *
              size.height *
              (0.003 + activity * 0.009 + dynamics.bass * 0.028) *
              motion,
        );
    final orbitalTurn =
        (phase * direction +
            math.sin(phase * 2) * (0.1 + dynamics.mid * 0.42) +
            math.sin(phase * 6) * renderBeatImpulse * 0.1) *
        motion;
    final strands = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 6,
      (VisualizerQuality.eco, false) => 5,
      (VisualizerQuality.normal, true) => 8,
      (VisualizerQuality.normal, false) => 7,
      (VisualizerQuality.ultra, true) => 9,
      (VisualizerQuality.ultra, false) => 8,
    };
    final points = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 42,
      (VisualizerQuality.eco, false) => 36,
      (VisualizerQuality.normal, true) => 56,
      (VisualizerQuality.normal, false) => 48,
      (VisualizerQuality.ultra, true) => 72,
      (VisualizerQuality.ultra, false) => 60,
    };
    final maxParticles = particleBudget(fullCanvas ? 60 : 42);
    final targetParticles = reduceMotion
        ? 0
        : (maxParticles * renderParticleIntensity).round();
    final totalPoints = strands * points;
    final particleStride = targetParticles == 0
        ? totalPoints + 1
        : math.max(1, (totalPoints / targetParticles).floor());
    var particlesDrawn = 0;
    final particlePaint = Paint()..blendMode = BlendMode.plus;
    final streamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;

    // Un halo barato (sin blur) da profundidad al vórtice sin multiplicar el
    // coste de cada partícula.
    final glowRadius =
        shortest * (0.23 + dynamics.bass * 0.16) * (0.74 + activity * 0.26);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _fluidParticleColor(
              0.08,
              0.2,
              dynamics.bass,
              alpha: (0.035 + renderGlow * 0.13) * presence,
            ),
            _fluidParticleColor(
              0.64,
              0.8,
              dynamics.mid,
              alpha: (0.012 + renderGlow * 0.05) * presence,
            ),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
        ..blendMode = BlendMode.plus,
    );

    for (var strand = 0; strand < strands; strand++) {
      final band = strand / (strands - 1);
      final stream = Path();
      Offset? strongestPeakPoint;
      var strongestPeakLift = 0.0;
      var strongestPeakPosition = band;
      final radiusX =
          size.width *
          (fullCanvas ? 0.13 + band * 0.36 : 0.17 + band * 0.27) *
          (0.74 + activity * 0.26);
      final radiusY =
          size.height *
          (fullCanvas ? 0.1 + band * 0.31 : 0.16 + band * 0.25) *
          (0.74 + activity * 0.26);
      for (var index = 0; index < points; index++) {
        final normalized = index / points;
        final spectrumPosition = (normalized + band * 0.17) % 1;
        final tone = _spectrumAt(spectrumPosition);
        final peak = _peakAt(spectrumPosition);
        final baseAngle = normalized * math.pi * 2;
        // Los medios retuercen el flujo; los graves ensanchan la órbita y el
        // beat la impulsa. Los agudos solo añaden el detalle de alta frecuencia.
        final vortex =
            math.sin(baseAngle * (2 + band * 2.4) - phase * direction * 3) *
            (0.006 + activity * 0.029 + dynamics.mid * 0.2 + tone * 0.08);
        final angularJitter =
            math.sin(baseAngle * (13 + strand) + phase * 7) *
            dynamics.treble *
            0.045;
        final angle =
            baseAngle +
            orbitalTurn * (0.52 + band * 0.48) +
            (band - 0.5) * dynamics.mid * 1.15 +
            vortex +
            angularJitter;
        final radialPulse =
            1 +
            dynamics.bass * (0.07 + 0.13 * math.sin(baseAngle - phase * 2)) +
            renderBeatImpulse * (0.04 + tone * 0.1);
        final trebleRipple =
            math.sin(baseAngle * (17 + strand % 4) - phase * 8) *
            shortest *
            dynamics.treble *
            0.012;
        final local = Offset(
          math.cos(angle) * radiusX * radialPulse + trebleRipple,
          math.sin(angle) * radiusY * radialPulse +
              math.cos(baseAngle * 4 - phase * 2) *
                  shortest *
                  dynamics.mid *
                  0.035,
        );
        final point = center + local;
        if (index == 0) {
          stream.moveTo(point.dx, point.dy);
        } else {
          stream.lineTo(point.dx, point.dy);
        }
        final peakLift = math.max(0.0, peak - tone);
        if (peakLift > strongestPeakLift) {
          strongestPeakLift = peakLift;
          strongestPeakPoint = point;
          strongestPeakPosition = spectrumPosition;
        }
        final visibleParticle =
            particlesDrawn < targetParticles &&
            (strand * points + index) % particleStride == 0;
        if (visibleParticle) {
          particlesDrawn++;
          particlePaint.color = _fluidParticleColor(
            normalized,
            band,
            tone,
            alpha: (0.2 + tone * 0.65) * presence,
          );
          canvas.drawCircle(
            point,
            0.45 +
                tone * 1.35 +
                dynamics.treble * 0.8 +
                renderBeatImpulse * tone * 0.65,
            particlePaint,
          );
        }
      }
      stream.close();
      streamPaint
        ..strokeWidth = shortest * (0.0007 + dynamics.mid * 0.0012)
        ..color = _fluidParticleColor(
          band,
          1 - band,
          dynamics.mid,
          alpha: (0.035 + renderGlow * 0.16) * presence,
        );
      canvas.drawPath(stream, streamPaint);
      if (!reduceMotion &&
          strongestPeakPoint != null &&
          strongestPeakLift > 0.025) {
        final point = strongestPeakPoint;
        final peakRadius = shortest * (0.003 + strongestPeakLift * 0.009);
        final peakColor = _peakColor(
          strongestPeakPosition,
          math.min(1.0, strongestPeakLift + dynamics.energy),
        );
        canvas.drawCircle(
          point,
          peakRadius * 2.6,
          Paint()
            ..color = peakColor.withValues(alpha: 0.2 + renderGlow * 0.25)
            ..blendMode = BlendMode.plus,
        );
        canvas.drawCircle(
          point,
          peakRadius,
          Paint()
            ..color = peakColor.withValues(alpha: 0.88)
            ..blendMode = BlendMode.plus,
        );
      }
    }
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final count = fullCanvas
        ? quality.bandCount
        : math.min(48, quality.bandCount);
    final gap = size.width * (fullCanvas ? 0.0038 : 0.0052);
    final barWidth = (size.width - gap * (count + 1)) / count;
    final baseline = size.height * (fullCanvas ? 0.68 : 0.72);
    final heightScale = fullCanvas
        ? tuning.spectrumHeightScale
        : tuning.spectrumHeightScale * 0.82;
    final segmentHeight = math.max(
      2.0,
      size.shortestSide * (fullCanvas ? 0.0085 : 0.011),
    );
    final segmentGap = math.max(1.3, segmentHeight * 0.42);
    final segmentStep = segmentHeight + segmentGap;
    final bars = Path();
    final highlights = Path();
    final reflections = Path();
    final peaks = Path();
    var highestBar = baseline;
    var reflectionBottom = baseline;

    for (var index = 0; index < count; index++) {
      final x = index / (count - 1);
      final tone = _spectrumAt(x);
      final shapedTone = math
          .pow(tone, (tuning.ribbonExponent + 0.10).clamp(0.62, 1.0))
          .toDouble();
      final ambientFlutter = hasLiveAnalysis
          ? 1.0
          : 0.94 + math.sin(phase * 2.1 + index * 0.37) * 0.06;
      final height =
          size.height *
          (0.022 + shapedTone * heightScale * ambientFlutter).clamp(0.0, 0.72);
      final left = gap + index * (barWidth + gap);
      final top = baseline - height;
      highestBar = math.min(highestBar, top);
      bars.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, height),
          Radius.circular(barWidth * 0.48),
        ),
      );
      if (tone > 0.52) {
        final highlightHeight = math.min(segmentHeight, height);
        highlights.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barWidth, highlightHeight),
            Radius.circular(math.min(barWidth, highlightHeight) * 0.48),
          ),
        );
      }

      if (fullCanvas && tone > 0.08) {
        final reflectedHeight = math.min(height * 0.27, size.height * 0.095);
        final reflectionTop = baseline + segmentGap;
        reflectionBottom = math.max(
          reflectionBottom,
          reflectionTop + reflectedHeight,
        );
        reflections.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, reflectionTop, barWidth, reflectedHeight),
            Radius.circular(barWidth * 0.45),
          ),
        );
      }

      final peakTone = _peakAt(x);
      if (peakTone > tone + 0.02) {
        final peakHeight =
            size.height *
            (0.022 +
                math.pow(
                      peakTone,
                      (tuning.ribbonExponent + 0.10).clamp(0.62, 1.0),
                    ) *
                    heightScale);
        final markerHeight = math.max(1.8, segmentHeight * 0.36);
        peaks.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              left,
              baseline - peakHeight - segmentGap * 1.25,
              barWidth,
              markerHeight,
            ),
            Radius.circular(markerHeight * 0.5),
          ),
        );
      }
    }

    final bounds = Offset.zero & size;
    // Altura que alcanzaría una barra al 100 %: define el tramo del lienzo
    // sobre el que se proyecta el mapa en modo «por fila».
    final fullHeight = size.height * (0.022 + heightScale);
    if (renderGlow > 0.025) {
      final glowAlpha = (0.08 + renderGlow * 0.28).clamp(0.0, 1.0).toDouble();
      final glowShader = _barGradient(
        baseline: baseline,
        fullHeight: fullHeight,
        alpha: glowAlpha,
      );
      canvas.drawPath(
        bars,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + renderGlow * 4
          // Sin degradado (modo «por columna») el halo toma el color del nivel
          // general: un `shader` nulo dejaría el trazo en negro e invisible
          // bajo BlendMode.plus.
          ..shader = glowShader
          ..color = colorMap
              .colorAt(dynamics.energy)
              .withValues(alpha: glowAlpha)
          ..blendMode = BlendMode.plus,
      );
    }
    // Cada capa se recorta a su silueta y se rellena con el reparto elegido:
    // un degradado vertical común («por fila») o una banda de color plano por
    // columna («por columna»). Antes se rellenaba con un degradado horizontal
    // derivado de graves/medios/agudos, y por eso todas las columnas cambiaban
    // de color a la vez sin importar la altura de cada una.
    void fillThrough(Path silhouette, double alpha, {bool highlight = false}) {
      canvas.save();
      canvas.clipPath(silhouette);
      final gradient = _barGradient(
        baseline: baseline,
        fullHeight: fullHeight,
        alpha: alpha,
      );
      if (gradient != null) {
        canvas.drawRect(
          bounds,
          Paint()
            ..shader = gradient
            ..blendMode = BlendMode.plus,
        );
      } else {
        for (var index = 0; index < count; index++) {
          final x = index / (count - 1);
          final tone = highlight ? _peakAt(x) : _spectrumAt(x);
          final left = gap + index * (barWidth + gap);
          canvas.drawRect(
            Rect.fromLTWH(left - gap * 0.5, 0, barWidth + gap, size.height),
            Paint()
              ..color = colorMap.colorAt(tone).withValues(alpha: alpha)
              ..blendMode = BlendMode.plus,
          );
        }
      }
      canvas.restore();
    }

    fillThrough(bars, (0.82 + dynamics.energy * 0.18).clamp(0.0, 1.0));
    fillThrough(highlights, 0.9, highlight: true);
    canvas.save();
    canvas.clipPath(bars);
    final separatorPaint = Paint()..color = const Color(0xFF010613);
    for (var y = baseline - segmentStep; y > highestBar; y -= segmentStep) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, segmentGap),
        separatorPaint,
      );
    }
    canvas.restore();
    if (fullCanvas) {
      fillThrough(
        reflections,
        (0.14 + renderGlow * 0.12).clamp(0.0, 1.0).toDouble(),
      );
      canvas.save();
      canvas.clipPath(reflections);
      final reflectionSeparatorPaint = Paint()..color = const Color(0xB8010613);
      final reflectionStep = segmentStep * 0.72;
      for (
        var y = baseline + segmentGap + segmentHeight * 0.62;
        y < reflectionBottom;
        y += reflectionStep
      ) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, segmentGap * 0.72),
          reflectionSeparatorPaint,
        );
      }
      canvas.restore();
    }
    // El marcador de pico vive por encima de la barra, así que en «por fila»
    // le toca el color de esa altura y en «por columna» el de su propio pico.
    fillThrough(peaks, 0.98, highlight: true);

    final maxParticles = particleBudget(fullCanvas ? 34 : 22);
    final ambientParticles = hasLiveAnalysis ? 0 : 3;
    final particleCount = reduceMotion
        ? ambientParticles
        : (ambientParticles + renderParticleIntensity * maxParticles).round();
    final randomParticles = math.Random(seed ^ 0x5F3759DF);
    final particlePaint = Paint()..blendMode = BlendMode.plus;
    for (var index = 0; index < particleCount; index++) {
      final x = 0.03 + randomParticles.nextDouble() * 0.94;
      final baseY = randomParticles.nextDouble();
      final drift = reduceMotion
          ? 0.0
          : (time * (0.025 + randomParticles.nextDouble() * 0.035)) % 1;
      final y = (baseY - drift) % 1.0;
      final tone = _spectrumAt(x);
      final point = Offset(
        size.width * x,
        size.height * (0.14 + y * (baseline / size.height - 0.2)),
      );
      canvas.drawCircle(
        point,
        0.4 + tone * 1.45 + renderBeatImpulse * 0.7,
        particlePaint
          ..color = _reactiveColor(
            x,
            tone,
            alpha:
                (0.04 + tone * 0.48) * (0.32 + renderParticleIntensity * 0.68),
          ),
      );
    }
  }

  void _paintElectricWaves(Canvas canvas, Size size) {
    final fullCanvas = immersive || size.width > size.height * 1.18;
    final strandCount = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 4,
      (VisualizerQuality.eco, false) => 4,
      (VisualizerQuality.normal, true) => 6,
      (VisualizerQuality.normal, false) => 5,
      (VisualizerQuality.ultra, true) => 8,
      (VisualizerQuality.ultra, false) => 6,
    };
    final bounds = Offset.zero & size;
    // dynamics.energy es la misma composición (level/bass/mid/treble
    // ponderados) que antes se recalculaba aquí de forma local.
    final energy = dynamics.energy;
    final presence = visualPresence;
    final direction = seed.isEven ? 1.0 : -1.0;
    // Una vuelta completa mantiene continuidad al reiniciar el reloj. Graves y
    // medios desvían la trayectoria; el beat imprime pequeños golpes de giro.
    final orbitAngle =
        (phase * direction +
            math.sin(phase * 2) * (0.12 + dynamics.mid * 0.44) +
            math.sin(phase * 3) * dynamics.bass * 0.22 +
            math.sin(phase * 7) * renderBeatImpulse * 0.1) *
        visualMotion;

    canvas.save();

    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: _gradientColors(alpha: 0.12 + presence * 0.84),
      stops: const [0, 0.36, 0.7, 1],
    ).createShader(bounds.inflate(size.width * 0.12));
    final glowShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: _gradientColors(alpha: 0.06 + renderGlow * 0.22),
      stops: const [0, 0.36, 0.7, 1],
    ).createShader(bounds.inflate(size.width * 0.12));

    // Se construyen primero las cintas para compartir una sola pasada de blur.
    // Antes cada una creaba una superficie difuminada de pantalla completa;
    // en GPU móviles eso multiplicaba memoria y podía bloquear el rasterizador.
    final glowPaths = Path();
    final strandLayers =
        <
          ({
            Path path,
            double normalized,
            double tone,
            double peak,
            double peakLift,
            Offset peakPoint,
          })
        >[];
    for (var strand = 0; strand < strandCount; strand++) {
      final normalized = strandCount == 1 ? 0.5 : strand / (strandCount - 1);
      final wave = _electricWaveGeometry(
        size: size,
        strand: strand,
        strandCount: strandCount,
        fullCanvas: fullCanvas,
        orbitAngle: orbitAngle,
      );
      final path = wave.path;
      final tone = _spectrumAt(normalized);
      final peak = _peakAt(normalized);
      final peakLift = math.max(0.0, peak - tone);
      glowPaths.addPath(path, Offset.zero);
      strandLayers.add((
        path: path,
        normalized: normalized,
        tone: tone,
        peak: peak,
        peakLift: peakLift,
        peakPoint: wave.peakPoint,
      ));
    }

    if (renderGlow > 0.025) {
      canvas.drawPath(
        glowPaths,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth =
              size.shortestSide *
              (0.018 + energy * 0.038 + renderBeatImpulse * 0.012)
          ..shader = glowShader
          ..blendMode = BlendMode.plus,
      );
    }

    // Varias capas nítidas conservan el plasma y la profundidad, mientras el
    // halo agregado de arriba evita ocho blurs independientes por fotograma.
    for (final layer in strandLayers) {
      final path = layer.path;
      final normalized = layer.normalized;
      final tone = layer.tone;
      final peak = layer.peak;
      final peakLift = layer.peakLift;
      final peakPoint = layer.peakPoint;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth =
              size.shortestSide *
              (0.0012 +
                  presence *
                      (0.0024 + tone * 0.004 + renderBeatImpulse * 0.002))
          ..shader = shader
          ..blendMode = BlendMode.plus,
      );
      if (!reduceMotion && peakLift > 0.025) {
        final flare = size.shortestSide * (0.006 + peakLift * 0.018);
        final peakPaint = Paint()
          ..color = _peakColor(
            normalized,
            peak,
          ).withValues(alpha: 0.64 + peakLift * 0.34)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.8 + peakLift * 1.8
          ..blendMode = BlendMode.plus;
        canvas.drawLine(
          peakPoint - Offset(flare, 0),
          peakPoint + Offset(flare, 0),
          peakPaint,
        );
        canvas.drawLine(
          peakPoint - Offset(0, flare),
          peakPoint + Offset(0, flare),
          peakPaint,
        );
      }
    }

    // Una onda fina y nerviosa aporta la vibración de agudos que caracterizaba
    // a los modos de pantalla completa de Windows Media Player.
    final tracePaths = Path();
    final traceCount = switch (quality) {
      VisualizerQuality.eco => 1,
      VisualizerQuality.normal => 2,
      VisualizerQuality.ultra => 3,
    };
    for (var echo = 0; echo < traceCount; echo++) {
      final path = _electricTracePath(
        size: size,
        echo: echo,
        traceCount: traceCount,
        fullCanvas: fullCanvas,
        orbitAngle: orbitAngle,
      );
      tracePaths.addPath(path, Offset.zero);
    }
    canvas.drawPath(
      tracePaths,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth =
            size.shortestSide *
            (0.0008 + presence * 0.0016 + dynamics.treble * 0.003)
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );

    _paintElectricSparks(canvas, size, shader, fullCanvas, orbitAngle);
    canvas.restore();
  }

  ({Path path, Offset peakPoint}) _electricWaveGeometry({
    required Size size,
    required int strand,
    required int strandCount,
    required bool fullCanvas,
    required double orbitAngle,
  }) {
    final path = Path();
    final steps = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 72,
      (VisualizerQuality.eco, false) => 56,
      (VisualizerQuality.normal, true) => 104,
      (VisualizerQuality.normal, false) => 80,
      (VisualizerQuality.ultra, true) => 144,
      (VisualizerQuality.ultra, false) => 104,
    };
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final span = fullCanvas ? diagonal * 1.22 : size.width * 1.24;
    final center = size.center(Offset.zero);
    final strandPosition = strand / (strandCount - 1);
    final signedPosition = strandPosition * 2 - 1;
    final strandPhase = signedPosition * 1.72 + strand * 0.29;
    final peakStep = ((0.34 + strandPosition * 0.32) * steps).round();
    var peakPoint = center;
    final baseAmplitude =
        size.height *
        (fullCanvas ? 0.22 : 0.18) *
        (0.18 +
            visualActivity * 0.54 +
            dynamics.bass * 0.72 +
            renderBeatImpulse * 0.28);
    final laneOffset =
        signedPosition *
        size.height *
        (fullCanvas ? 0.12 : 0.105) *
        (0.35 + visualActivity * 0.65);

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
        normalized * math.pi * (5.2 + dynamics.mid * 2.6) -
            phase * (0.94 + strandPosition * 0.11) -
            strandPhase * 0.6,
      );
      final shimmer = math.sin(
        normalized * math.pi * (18 + strand * 0.55) +
            phase * (3.1 + dynamics.treble * 2.7) +
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
          fold * baseAmplitude * (0.12 + dynamics.mid * 0.15) +
          spectralRipple * envelope +
          shimmer * size.height * dynamics.treble * 0.012;
      final circularBend =
          (normalized - 0.5) * (0.42 + dynamics.mid * 1.05) +
          math.sin(normalized * math.pi * 2 - phase * 2) *
              (0.035 + renderBeatImpulse * 0.11) +
          signedPosition * dynamics.bass * 0.09;
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
      if (index == peakStep) peakPoint = point;
    }
    return (path: path, peakPoint: peakPoint);
  }

  Path _electricTracePath({
    required Size size,
    required int echo,
    required int traceCount,
    required bool fullCanvas,
    required double orbitAngle,
  }) {
    final path = Path();
    final steps = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 64,
      (VisualizerQuality.eco, false) => 48,
      (VisualizerQuality.normal, true) => 104,
      (VisualizerQuality.normal, false) => 80,
      (VisualizerQuality.ultra, true) => 160,
      (VisualizerQuality.ultra, false) => 120,
    };
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
          mirror *
              sweep *
              size.height *
              (0.035 + visualActivity * 0.115 + dynamics.mid * 0.16) +
          vibration *
              size.height *
              (0.005 + dynamics.treble * 0.014 + localSpectrum * 0.025) *
              envelope +
          (echo - (traceCount - 1) / 2) * size.height * 0.026;
      final circularBend =
          (normalized - 0.5) * (0.35 + dynamics.mid * 0.8) +
          math.sin(normalized * math.pi * 2 + phase * 3 + echo) *
              renderBeatImpulse *
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
    final maxCount = particleBudget(fullCanvas ? 68 : 40);
    final count = reduceMotion
        ? 0
        : (renderParticleIntensity * maxCount).round();
    final sparkPaint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus;
    for (var index = 0; index < count; index++) {
      final normalized = random.nextDouble();
      final sweep = math.sin(normalized * math.pi * 3.2 + phase * 1.14);
      final spectralEnergy = _spectrumAt(normalized);
      final activity =
          (spectralEnergy * 0.72 +
              dynamics.treble * 0.34 +
              renderBeatImpulse * 0.72) *
          (0.55 + random.nextDouble() * 0.45);
      final drift = math.sin(phase * (1.2 + random.nextDouble()) + index) * 8;
      final rawPoint = Offset(
        normalized * size.width + drift,
        size.height * 0.5 +
            sweep * size.height * (0.15 + dynamics.mid * 0.16) +
            (random.nextDouble() - 0.5) * size.height * 0.24 * activity,
      );
      final point = _rotateAround(
        rawPoint,
        size.center(Offset.zero),
        orbitAngle +
            (normalized - 0.5) * (0.38 + dynamics.mid * 0.9) +
            math.sin(normalized * math.pi * 2 - phase * 2) *
                renderBeatImpulse *
                0.08,
      );
      final radius =
          0.55 +
          random.nextDouble() * 1.25 +
          dynamics.treble * 1.9 +
          renderBeatImpulse;
      canvas.drawCircle(point, radius, sparkPaint);
      // beatImpulse normalizado (no dynamics.beat crudo) da un destello
      // consistente con el resto de estilos: mismo umbral y misma forma de
      // pulso en vez de que cada painter invente su propio disparador.
      if (!reduceMotion && renderBeatImpulse > 0.48 && index % 11 == 0) {
        final flare = size.shortestSide * (0.014 + renderBeatImpulse * 0.018);
        canvas.drawLine(
          point - Offset(flare, 0),
          point + Offset(flare, 0),
          sparkPaint..strokeWidth = 0.8 + renderBeatImpulse,
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
    final motionActivity = visualMotion;
    final camera = Offset(
      size.width *
          (0.49 +
              math.sin(phase) *
                  (0.07 + renderBeatImpulse * 0.025) *
                  motionActivity),
      size.height *
          (0.5 +
              math.cos(phase * 2) *
                  (0.055 + dynamics.mid * 0.035) *
                  motionActivity),
    );
    final seededRoll = ((seed.abs() % 997) / 997 - 0.5) * 0.24;
    final cameraRoll =
        seededRoll +
        math.sin(phase * (1 + seed.abs() % 2)) *
            (0.08 + dynamics.mid * 0.1) *
            motionActivity +
        math.sin(phase * 4) * renderBeatImpulse * 0.035;

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
    final cloudCount = quality == VisualizerQuality.eco ? 2 : 3;
    for (var cloud = 0; cloud < cloudCount; cloud++) {
      final angle = phase * (cloud.isEven ? 1 : -1) + cloud * 1.37;
      final reach = Offset(
        math.cos(angle) * size.width * (0.2 + cloud * 0.035),
        math.sin(angle * 1.17) * size.height * (0.17 + cloud * 0.025),
      );
      final radius = shortest * (0.2 + cloud * 0.045 + dynamics.bass * 0.075);
      final center = camera + reach;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _cosmicColor(
                cloud / 5 + 0.11,
                alpha: 0.012 + renderGlow * (0.035 + cloud * 0.009),
              ),
              _cosmicColor(cloud / 5 + 0.23, alpha: 0.004 + renderGlow * 0.012),
              Colors.transparent,
            ],
            stops: const [0, 0.42, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..blendMode = BlendMode.plus,
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
    final ribbonCount = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 4,
      (VisualizerQuality.eco, false) => 3,
      (VisualizerQuality.normal, true) => 6,
      (VisualizerQuality.normal, false) => 5,
      (VisualizerQuality.ultra, true) => 8,
      (VisualizerQuality.ultra, false) => 6,
    };
    final bounds = (Offset.zero & size).inflate(size.shortestSide * 0.18);
    final presence = visualPresence;
    final tunnelGlow = Path();
    for (var ribbon = 0; ribbon < ribbonCount; ribbon++) {
      final normalized = ribbon / math.max(1, ribbonCount - 1);
      final spectrum = _spectrumAt(normalized);
      final random = math.Random(seed ^ (ribbon * 0x45D9F3B));
      final directionAngle = random.nextDouble() * math.pi * 2;
      final shader = LinearGradient(
        begin: Alignment(-math.cos(directionAngle), -math.sin(directionAngle)),
        end: Alignment(math.cos(directionAngle), math.sin(directionAngle)),
        colors: [
          _cosmicColor(normalized, alpha: 0.22 * presence),
          _cosmicColor(normalized + 0.24, alpha: 0.92 * presence),
          _cosmicColor(normalized + 0.52, alpha: presence),
          _cosmicColor(normalized + 0.78, alpha: 0.9 * presence),
          _cosmicColor(normalized + 1, alpha: 0.2 * presence),
        ],
        stops: const [0, 0.22, 0.5, 0.78, 1],
      ).createShader(bounds);
      final paths = _cosmicRibbonPaths(
        size: size,
        camera: camera,
        ribbon: ribbon,
        fullCanvas: fullCanvas,
      );
      final centerPath = paths.center;
      tunnelGlow.addPath(centerPath, Offset.zero);

      canvas.drawPath(
        centerPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth =
              size.shortestSide *
              (0.009 +
                  dynamics.energy * 0.023 +
                  dynamics.bass * 0.045 +
                  spectrum * 0.025 +
                  renderBeatImpulse * 0.03)
          ..shader = shader
          ..blendMode = BlendMode.plus,
      );

      // Los filamentos separados hacen visible la torsión pseudo-3D de cada
      // cinta y evitan que el resultado se lea como una única forma central.
      for (var filament = -1; filament <= 1; filament++) {
        final filamentPath = switch (filament) {
          -1 => paths.negative,
          0 => centerPath,
          _ => paths.positive,
        };
        canvas.drawPath(
          filamentPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth =
                size.shortestSide *
                (0.0014 +
                    dynamics.treble * 0.0028 +
                    spectrum * 0.0018 +
                    (filament == 0 ? renderBeatImpulse * 0.002 : 0))
            ..shader = shader
            ..blendMode = BlendMode.plus,
        );
      }
    }
    if (renderGlow > 0.04) {
      canvas.drawPath(
        tunnelGlow,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = size.shortestSide * (0.014 + renderGlow * 0.024)
          ..shader = LinearGradient(
            colors: _gradientColors(alpha: 0.035 + renderGlow * 0.09),
          ).createShader(bounds)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  ({Path negative, Path center, Path positive}) _cosmicRibbonPaths({
    required Size size,
    required Offset camera,
    required int ribbon,
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
    final steps = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, true) => 64,
      (VisualizerQuality.eco, false) => 52,
      (VisualizerQuality.normal, true) => 96,
      (VisualizerQuality.normal, false) => 76,
      (VisualizerQuality.ultra, true) => 140,
      (VisualizerQuality.ultra, false) => 104,
    };
    final negativePath = Path();
    final centerPath = Path();
    final positivePath = Path();
    final travellingPhase =
        phase *
        direction *
        (speed * (0.08 + visualActivity * 0.92) +
            dynamics.bass * 0.34 +
            renderBeatImpulse * 0.5);
    final roll =
        baseAngle +
        math.sin(phase * (1 + ribbon % 2) + depthPhase) *
            (0.12 + dynamics.mid * 0.25) +
        math.sin(phase * 4 + ribbon) * renderBeatImpulse * 0.055;
    final rollCosine = math.cos(roll);
    final rollSine = math.sin(roll);

    for (var step = 0; step <= steps; step++) {
      final normalized = step / steps;
      final localSpectrum = _spectrumAt(normalized);
      final depthAngle =
          normalized * math.pi * 2 * depthTurns + travellingPhase + depthPhase;
      final depth = math.sin(depthAngle);
      final perspective = 0.68 + (depth + 1) * 0.25;
      final along = (normalized - 0.5) * diagonal * 2.3;
      final bend =
          math.sin(
            normalized * math.pi * 2 * waveCount +
                travellingPhase * (0.72 + dynamics.mid * 0.48) +
                wavePhase,
          ) *
          size.shortestSide *
          (0.025 +
              visualActivity * 0.085 +
              dynamics.bass * 0.17 +
              localSpectrum * 0.12);
      final changeOfDirection =
          math.sin(
            normalized * math.pi * (5 + ribbon % 4) -
                phase * direction * (2 + dynamics.mid * 2.5) +
                depthPhase,
          ) *
          size.shortestSide *
          (0.005 +
              visualActivity * 0.02 +
              dynamics.mid * 0.105 +
              renderBeatImpulse * 0.035);
      final vibration =
          math.sin(
            normalized * math.pi * (28 + ribbon % 7) +
                phase * direction * (5 + dynamics.treble * 5) +
                wavePhase,
          ) *
          size.shortestSide *
          (0.0005 +
              visualActivity * 0.0015 +
              dynamics.treble * 0.023 +
              localSpectrum * 0.009);
      final ribbonWidth =
          size.shortestSide *
          (0.01 + dynamics.bass * 0.025 + renderBeatImpulse * 0.008) *
          (0.28 + (math.cos(depthAngle) + 1) * 0.5);
      final localX = along * perspective;
      final centerY =
          (lane + bend + changeOfDirection + vibration) * perspective;
      final widthY = ribbonWidth * perspective;
      final negativeY = centerY - widthY;
      final positiveY = centerY + widthY;
      final centerPoint =
          camera +
          Offset(
            localX * rollCosine - centerY * rollSine,
            localX * rollSine + centerY * rollCosine,
          );
      final negativePoint =
          camera +
          Offset(
            localX * rollCosine - negativeY * rollSine,
            localX * rollSine + negativeY * rollCosine,
          );
      final positivePoint =
          camera +
          Offset(
            localX * rollCosine - positiveY * rollSine,
            localX * rollSine + positiveY * rollCosine,
          );
      if (step == 0) {
        negativePath.moveTo(negativePoint.dx, negativePoint.dy);
        centerPath.moveTo(centerPoint.dx, centerPoint.dy);
        positivePath.moveTo(positivePoint.dx, positivePoint.dy);
      } else {
        negativePath.lineTo(negativePoint.dx, negativePoint.dy);
        centerPath.lineTo(centerPoint.dx, centerPoint.dy);
        positivePath.lineTo(positivePoint.dx, positivePoint.dy);
      }
    }
    return (negative: negativePath, center: centerPath, positive: positivePath);
  }

  void _paintCosmicStars(
    Canvas canvas,
    Size size,
    Offset camera,
    bool fullCanvas,
  ) {
    final random = math.Random(seed ^ 0x51A7F1E1);
    final maxStars = particleBudget(fullCanvas ? 64 : 40);
    final ambientBaseStars = hasLiveAnalysis ? 0 : 4;
    final starCount = reduceMotion
        ? ambientBaseStars
        : (ambientBaseStars +
                  visualActivity * 8 +
                  renderParticleIntensity * (maxStars - ambientBaseStars - 8))
              .round();
    final starPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    for (var star = 0; star < starCount; star++) {
      final angle = random.nextDouble() * math.pi * 2;
      final baseDepth = random.nextDouble();
      final speed = 1 + star % 3;
      final reactiveSpeed =
          speed * (0.08 + visualActivity * 0.92) +
          dynamics.bass * 0.7 +
          renderBeatImpulse * 1.25;
      final depth = (baseDepth + time * reactiveSpeed) % 1.0;
      final previousDepth = math.max(
        0.0,
        depth -
            0.004 -
            visualActivity * 0.014 -
            dynamics.treble * 0.045 -
            renderBeatImpulse * 0.025,
      );
      final perspective = math.pow(depth, 1.72).toDouble();
      final previousPerspective = math.pow(previousDepth, 1.72).toDouble();
      final radialWobble =
          math.sin(phase * (1 + star % 2) + star * 0.41) * dynamics.mid * 0.12;
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
      final brightness =
          0.035 +
          depth * (0.18 + visualActivity * 0.38) +
          dynamics.energy * 0.22 +
          dynamics.treble * 0.28;
      final color = _cosmicColor(
        star / starCount + depth * 0.18,
        alpha: brightness.clamp(0.0, 0.95).toDouble(),
      );
      canvas.drawLine(
        previous,
        point,
        starPaint
          ..strokeWidth =
              0.45 +
              depth * 1.8 +
              dynamics.treble * 1.35 +
              renderBeatImpulse * 0.4
          ..color = color,
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
    final orbCount = switch ((quality, fullCanvas)) {
      (VisualizerQuality.eco, _) => 2,
      (VisualizerQuality.normal, _) => 3,
      (VisualizerQuality.ultra, true) => 4,
      (VisualizerQuality.ultra, false) => 3,
    };
    for (var orb = 0; orb < orbCount; orb++) {
      final baseTravel = random.nextDouble();
      final lane = random.nextDouble();
      final baseRadius = random.nextDouble();
      final cycles = 1 + orb % 2;
      final travel =
          (baseTravel +
              time *
                  (cycles * (0.12 + visualActivity * 0.88) +
                      dynamics.bass * 0.24 +
                      renderBeatImpulse * 0.5)) %
          1.0;
      final orbSpectrum = _spectrumAt(orb / math.max(1, orbCount - 1));
      final orbPeak = _peakAt(orb / math.max(1, orbCount - 1));
      final peakLift = math.max(0.0, orbPeak - orbSpectrum);
      final position = _cosmicOrbPosition(size, camera, travel, lane, orb);
      final radius =
          size.shortestSide *
          (0.005 + baseRadius * 0.012 + dynamics.bass * 0.007) *
          (0.24 +
              visualActivity * 0.44 +
              math.sin(travel * math.pi) * 0.46 * visualActivity +
              renderBeatImpulse * 0.18 +
              peakLift * 0.28);
      final color = _cosmicColor(
        orb / orbCount + travel * 0.28,
        alpha: 0.12 + visualPresence * 0.56,
      );

      final trail = Path();
      const trailSteps = 10;
      for (var step = 0; step <= trailSteps; step++) {
        final trailTravel =
            (travel - step * (0.008 + dynamics.treble * 0.003)) % 1.0;
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
          ..strokeWidth = radius * (0.22 + dynamics.mid * 0.3)
          ..color = color.withValues(
            alpha: 0.03 + visualPresence * (0.11 + orbSpectrum * 0.24),
          )
          ..blendMode = BlendMode.plus,
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
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        position,
        radius * (0.22 + renderBeatImpulse * 0.12),
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.1 + visualPresence * (0.48 + dynamics.treble * 0.3),
          )
          ..blendMode = BlendMode.plus,
      );

      // El golpe expande el orb de inmediato; el peak común conserva un flare
      // más pequeño durante su hold/decay en vez de desaparecer de golpe.
      final flareStrength = math.max(renderBeatImpulse, peakLift);
      if (!reduceMotion && (renderBeatImpulse > 0.68 || peakLift > 0.025)) {
        final flare = radius * (1.2 + flareStrength * 1.8);
        final flarePaint = Paint()
          ..color = _peakColor(
            orb / orbCount,
            orbPeak,
          ).withValues(alpha: 0.28 + flareStrength * 0.48)
          ..strokeWidth = 0.8 + flareStrength * 1.3
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
        arc * size.height * (0.09 + dynamics.mid * 0.14) +
        curl * size.height * dynamics.treble * 0.025;
    final cameraPull = math.sin(travel * math.pi) * dynamics.bass * 0.08;
    return Offset(
      _lerp(x, camera.dx, cameraPull),
      _lerp(targetY, camera.dy, cameraPull * 0.72),
    );
  }

  Color _cosmicColor(double offset, {double alpha = 1}) {
    final position = offset - offset.floorToDouble();
    return _reactiveColor(position, _spectrumAt(position), alpha: alpha);
  }

  Color _fluidParticleColor(
    double position,
    double band,
    double tone, {
    double alpha = 1,
  }) {
    final palettePosition = (position * 0.68 + band * 0.32) % 1.0;
    return _reactiveColor(palettePosition, tone, alpha: alpha);
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
      return _lerp(dynamics.bass, dynamics.mid, value * 3);
    }
    if (value < 2 / 3) {
      return _lerp(dynamics.mid, dynamics.treble, (value - 1 / 3) * 3);
    }
    return _lerp(dynamics.treble, dynamics.bass, (value - 2 / 3) * 3);
  }

  double _spectrumAt(double normalized) {
    final spectrum = dynamics.spectrum;
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

  double _peakAt(double normalized) {
    if (!hasLiveAnalysis) return 0;
    final peaks = dynamics.peaks;
    if (peaks.isEmpty) return 0;
    final value = normalized.clamp(0.0, 1.0).toDouble();
    final position = value * (peaks.length - 1);
    final lower = position.floor();
    final upper = math.min(lower + 1, peaks.length - 1);
    return _lerp(
      peaks[lower],
      peaks[upper],
      position - lower,
    ).clamp(0.0, 1.0).toDouble();
  }

  double _mirroredSpectrumAt(double normalized) {
    final value = normalized % 1.0;
    final mirrored = value <= 0.5 ? value * 2 : (1 - value) * 2;
    return _spectrumAt(mirrored);
  }

  double _mirroredPeakAt(double normalized) {
    final value = normalized % 1.0;
    final mirrored = value <= 0.5 ? value * 2 : (1 - value) * 2;
    return _peakAt(mirrored);
  }

  /// Degradado vertical del mapa para las barras, o `null` en modo «por
  /// columna», donde cada barra se pinta con su propio color plano.
  ///
  /// Va de la línea base (intensidad 0) a la altura que alcanzaría una barra
  /// al 100 %, de modo que una barra corta solo llega a mostrar los colores
  /// bajos del mapa.
  Shader? _barGradient({
    required double baseline,
    required double fullHeight,
    required double alpha,
  }) {
    if (colorMode != VisualizerColorMode.row) return null;
    final ramp = colorMap.projectedOnto(0, 1);
    return ui.Gradient.linear(
      Offset(0, baseline),
      Offset(0, baseline - fullHeight),
      [
        for (final color in ramp.colors)
          _colorize(color).withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
      ],
      ramp.positions,
    );
  }

  /// Equivalente radial de [_barGradient] para los motivos circulares: el
  /// mapa se reparte desde el aro (intensidad 0) hasta donde llegaría un trazo
  /// del 100 %. Devuelve `null` en modo «por columna».
  Shader? _radialGradient({
    required Offset center,
    required double innerRadius,
    required double maxLength,
    required double alpha,
  }) {
    if (colorMode != VisualizerColorMode.row) return null;
    final outerRadius = innerRadius + maxLength;
    if (outerRadius <= 0) return null;
    final ramp = colorMap.projectedOnto(innerRadius / outerRadius, 1);
    return ui.Gradient.radial(center, outerRadius, [
      for (final color in ramp.colors)
        _colorize(color).withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
    ], ramp.positions);
  }

  /// Una sola traducción cromática para todos los estilos.
  ///
  /// El mapa se consulta con la intensidad **del propio elemento** (`tone`), no
  /// con la energía global ni con la posición en pantalla: una barra que llega
  /// al 90 % toma el color del 90 % aunque sus vecinas sigan bajas. Antes la
  /// posición en la paleta la fijaba la energía global, así que toda la fila
  /// cambiaba de color a la vez y ninguna columna podía destacar por su fuerza.
  ///
  /// La energía global sigue interviniendo, pero solo en *presencia* (cuánto
  /// emerge el elemento del fondo), nunca en qué color le toca: así un naranja
  /// elegido en el mapa se ve naranja.
  Color _reactiveColor(double normalized, double tone, {double alpha = 1}) {
    final t = tone.clamp(0.0, 1.0).toDouble();
    final base = _colorize(colorMap.colorAt(t));
    // Los elementos apagados se hunden hacia el fondo y los activos muestran el
    // color del mapa tal cual. La curva deja que la diferencia se note ya en
    // amplitudes medias en vez de solo cerca del pico.
    final emergence = math.pow(t, 0.62).toDouble();
    final presence = reduceMotion
        ? 0.45 + emergence * 0.4
        : (0.12 + emergence * 0.88) * (0.72 + dynamics.energy * 0.28) +
              renderBeatImpulse * 0.06;
    final blended = Color.lerp(
      _floorColor,
      base,
      presence.clamp(0.0, 1.0).toDouble(),
    )!;
    return blended.withValues(alpha: alpha.clamp(0.0, 1.0).toDouble());
  }

  /// Fondo hacia el que se hunden los elementos sin energía. Se deriva de la
  /// parada más baja del mapa para que un mapa cálido no descanse sobre un
  /// azul frío ajeno a la paleta elegida.
  Color get _floorColor {
    final hsl = HSLColor.fromColor(_colorize(colorMap.stops.first.color));
    return hsl
        .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
        .withLightness(0.05)
        .toColor();
  }

  Color _peakColor(double normalized, double peak) {
    // El marcador de pico mira algo más arriba en el mapa que la barra que lo
    // sostiene, de modo que el tramo reservado al pico se vea de verdad.
    final base = _colorize(colorMap.colorAt(math.min(1.0, peak + 0.06)));
    final whiteMix = (0.12 + dynamics.energy * 0.16 + renderBeatImpulse * 0.16)
        .clamp(0.0, 0.5)
        .toDouble();
    return Color.lerp(base, const Color(0xFFF6F8FF), whiteMix)!;
  }

  List<Color> _gradientColors({required double alpha, bool highlight = false}) {
    final values = <({double position, double tone})>[
      (position: 0, tone: dynamics.bass),
      (position: 0.36, tone: _lerp(dynamics.bass, dynamics.mid, 0.68)),
      (position: 0.7, tone: _lerp(dynamics.mid, dynamics.treble, 0.62)),
      (position: 1, tone: dynamics.treble),
    ];
    return [
      for (final value in values)
        (highlight
                ? _peakColor(value.position, value.tone)
                : _reactiveColor(value.position, value.tone))
            .withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
    ];
  }

  double _lerp(double a, double b, double amount) => a + (b - a) * amount;

  Color _colorize(Color color) {
    if (!randomColors) return color;
    final offset = fluidRandomHueOffset(
      seed: seed,
      elapsedSeconds: elapsedSeconds,
      energy: dynamics.energy,
      beatImpulse: dynamics.beatImpulse,
    );
    return rotateVisualizerHue(color, offset);
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.time != time ||
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.dynamics != dynamics ||
      oldDelegate.colorMap != colorMap ||
      oldDelegate.colorMode != colorMode ||
      oldDelegate.randomColors != randomColors ||
      oldDelegate.seed != seed ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.immersive != immersive ||
      oldDelegate.hasLiveAnalysis != hasLiveAnalysis ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.quality != quality ||
      oldDelegate.tuning.motionScale != tuning.motionScale ||
      oldDelegate.motionParticleScale != motionParticleScale;
}
