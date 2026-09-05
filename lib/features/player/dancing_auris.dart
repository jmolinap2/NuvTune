import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/visualizer_dynamics.dart';

/// Cameo de Auris bailando al ritmo, para el escenario del visualizador.
///
/// Reusa el mismo lenguaje de movimiento que `AurisGuide`/`GiftAuris`
/// (reposo en bucle + `Transform.translate`/`Transform.scale`), sumando un
/// "salto" corto disparado en cada pulso de beat. No tiene provider propio de
/// dinámica visual: como ya hace `animated_lyrics_line.dart`, deriva su
/// propio valor suavizado del único stream compartido [audioAnalysisProvider]
/// en vez de depender del visualizador principal.
class DancingAuris extends ConsumerStatefulWidget {
  const DancingAuris({required this.song, this.size = 64, super.key});

  final Song song;
  final double size;

  @override
  ConsumerState<DancingAuris> createState() => _DancingAurisState();
}

class _DancingAurisState extends ConsumerState<DancingAuris>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  final _dynamicsEngine = VisualizerDynamicsEngine(
    config: const VisualizerDynamicsConfig(bandCount: 1),
  );
  final _clock = Stopwatch()..start();

  /// Decidido una sola vez al montar (el widget se reconstruye con una key
  /// por canción): recalcularlo en cada build haría que Auris parpadeara
  /// entrando y saliendo con cada fotograma. Aparece en aprox. 1 de cada 3
  /// canciones dentro del visualizador: frecuente para descubrirse, poco
  /// frecuente para seguir siendo una sorpresa.
  late final bool _revealed;
  double _lastBeatImpulse = 0;
  bool _motionEnabled = false;

  static const _energeticGenres = [
    'electro',
    'dance',
    'house',
    'edm',
    'techno',
  ];

  @override
  void initState() {
    super.initState();
    _revealed = math.Random().nextInt(3) == 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled == _motionEnabled) return;
    _motionEnabled = enabled;
    if (enabled) {
      _idle.repeat(reverse: true);
    } else {
      _idle.stop();
      _idle.value = 0;
      _hop.stop();
      _hop.value = 0;
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _hop.dispose();
    super.dispose();
  }

  /// Casi siempre vacío/`<unknown>` en archivos locales: nunca decide si
  /// Auris aparece, solo matiza la intensidad del salto cuando el dato existe.
  double _genreEnergyBoost() {
    final genre = widget.song.genre?.toLowerCase() ?? '';
    return _energeticGenres.any(genre.contains) ? 1.15 : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_revealed || !_motionEnabled) return const SizedBox.shrink();

    final frame = ref.watch(audioAnalysisProvider).valueOrNull;
    if (frame == null) return const SizedBox.shrink();

    final dynamics = _dynamicsEngine.update(frame, _clock.elapsedMicroseconds);
    if (dynamics.beatImpulse >= 0.5 && _lastBeatImpulse < 0.5) {
      // Un AnimationController no se puede reiniciar en medio de este mismo
      // build (el propio `AnimatedBuilder` de abajo lo está escuchando).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hop.forward(from: 0);
      });
    }
    _lastBeatImpulse = dynamics.beatImpulse;
    final energy = (dynamics.energy * _genreEnergyBoost()).clamp(0.0, 1.0);

    return ExcludeSemantics(
      // Puramente decorativo: no debe ensuciar el árbol de accesibilidad que
      // ya describe el visualizador debajo.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _hop]),
          child: Image.asset(
            'assets/images/auris.png',
            width: widget.size,
            height: widget.size,
            filterQuality: FilterQuality.medium,
          ),
          builder: (context, child) {
            final hop = Curves.easeOutBack.transform(_hop.value);
            final bob = 4 + energy * 6;
            return Transform.translate(
              offset: Offset(0, -bob * _idle.value - 6 * hop),
              child: Transform.scale(
                scale: 1 + 0.02 * _idle.value + (0.05 + energy * 0.05) * hop,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
