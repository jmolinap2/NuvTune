import 'dart:math' as math;

import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Parámetros temporales y de calibración del motor visual.
///
/// [attack], [release] y [peakDecay] son coeficientes de un frame de
/// referencia. El motor los convierte usando el tiempo real transcurrido, de
/// modo que el resultado no depende de la frecuencia con la que se llame a
/// [VisualizerDynamicsEngine.update].
class VisualizerDynamicsConfig {
  const VisualizerDynamicsConfig({
    this.bandCount = 64,
    this.attack = 0.55,
    this.release = 0.12,
    this.referenceFrameRate = 30,
    this.levelBoost = 1,
    this.bassBoost = 1,
    this.midBoost = 1,
    this.trebleBoost = 1,
    this.levelEnergyWeight = 0.38,
    this.bassEnergyWeight = 0.30,
    this.midEnergyWeight = 0.20,
    this.trebleEnergyWeight = 0.12,
    this.peakHold = const Duration(milliseconds: 100),
    this.peakDecay = 0.94,
    this.beatImpulseDuration = const Duration(milliseconds: 160),
  }) : assert(bandCount > 0),
       assert(attack >= 0 && attack <= 1),
       assert(release >= 0 && release <= 1),
       assert(referenceFrameRate > 0 && referenceFrameRate < double.infinity),
       assert(levelBoost >= 0 && levelBoost < double.infinity),
       assert(bassBoost >= 0 && bassBoost < double.infinity),
       assert(midBoost >= 0 && midBoost < double.infinity),
       assert(trebleBoost >= 0 && trebleBoost < double.infinity),
       assert(levelEnergyWeight >= 0 && levelEnergyWeight < double.infinity),
       assert(bassEnergyWeight >= 0 && bassEnergyWeight < double.infinity),
       assert(midEnergyWeight >= 0 && midEnergyWeight < double.infinity),
       assert(trebleEnergyWeight >= 0 && trebleEnergyWeight < double.infinity),
       assert(
         levelEnergyWeight +
                 bassEnergyWeight +
                 midEnergyWeight +
                 trebleEnergyWeight >
             0,
       ),
       assert(peakDecay >= 0 && peakDecay < 1);

  /// Cantidad estable de bandas entregadas a todos los painters.
  final int bandCount;

  /// Fracción recorrida hacia un valor mayor en un frame de referencia.
  final double attack;

  /// Fracción recorrida hacia un valor menor en un frame de referencia.
  final double release;

  /// Frecuencia a la que se interpretan [attack], [release] y [peakDecay].
  final double referenceFrameRate;

  final double levelBoost;
  final double bassBoost;
  final double midBoost;
  final double trebleBoost;

  /// Pesos de la única definición de energía visual. Se normalizan por su
  /// suma para que una calibración alternativa conserve el rango 0–1.
  final double levelEnergyWeight;
  final double bassEnergyWeight;
  final double midEnergyWeight;
  final double trebleEnergyWeight;

  final Duration peakHold;

  /// Proporción del peak conservada por frame de referencia después del hold.
  final double peakDecay;

  /// Tiempo máximo que tarda un impulso aislado de intensidad 1 en apagarse.
  final Duration beatImpulseDuration;
}

/// Interpretación musical compartida por todos los estilos del visualizador
/// en un instante dado: "qué está haciendo la música", no "cómo se dibuja".
///
/// Las colecciones se copian como listas no modificables para que un painter
/// no pueda alterar accidentalmente el estado del motor ni el de otro painter.
class VisualizerDynamicsState {
  VisualizerDynamicsState({
    required this.energy,
    required this.level,
    required this.bass,
    required this.mid,
    required this.treble,
    required this.beat,
    required this.beatImpulse,
    required this.brightness,
    required this.saturation,
    required this.glow,
    required this.hue,
    required this.particleIntensity,
    required List<double> spectrum,
    required List<double> peaks,
  }) : spectrum = List<double>.unmodifiable(spectrum),
       peaks = List<double>.unmodifiable(peaks);

  /// Energía común, con pesos level/bass/mid/treble de 38/30/20/12 %.
  final double energy;

  final double level;
  final double bass;
  final double mid;
  final double treble;

  /// Beat nativo normalizado. Un frame ambiental con beat cero permanece cero.
  final double beat;

  /// Pulso corto derivado del beat, con caída temporal independiente del FPS.
  final double beatImpulse;

  /// Techo normalizado de luminosidad para la energía actual.
  final double brightness;

  /// Techo normalizado de saturación para la energía actual.
  final double saturation;

  /// Presupuesto normalizado de glow.
  final double glow;

  /// Posición normalizada dentro de la evolución cromática de baja a alta
  /// energía.
  final double hue;

  /// Intensidad común de partículas derivada de energía, agudos y beat.
  final double particleIntensity;

  final List<double> spectrum;
  final List<double> peaks;
}

/// Única fuente de verdad de la dinámica musical visual.
///
/// Normaliza las entradas del motor nativo, remuestrea el espectro, aplica una
/// envolvente attack/release independiente del frame rate y mantiene el estado
/// temporal de beat y peaks. Los painters reciben únicamente el resultado y
/// conservan la responsabilidad de la geometría.
class VisualizerDynamicsEngine {
  VisualizerDynamicsEngine({this.config = const VisualizerDynamicsConfig()})
    : _spectrum = List<double>.filled(config.bandCount, 0),
      _peakLevels = List<double>.filled(config.bandCount, 0),
      _peakHoldUntilMicros = List<int>.filled(config.bandCount, 0);

  final VisualizerDynamicsConfig config;
  final List<double> _spectrum;
  final List<double> _peakLevels;
  final List<int> _peakHoldUntilMicros;

  double _energy = 0;
  double _level = 0;
  double _bass = 0;
  double _mid = 0;
  double _treble = 0;
  double _beatImpulse = 0;
  int? _lastTickMicros;

  VisualizerDynamicsState update(AudioAnalysisFrame frame, int nowMicros) {
    final previousTickMicros = _lastTickMicros;
    final deltaSeconds = _elapsedSeconds(nowMicros);

    final targetLevel = _normalize(frame.level * config.levelBoost);
    final targetBass = _normalize(frame.bass * config.bassBoost);
    final targetMid = _normalize(frame.mid * config.midBoost);
    final targetTreble = _normalize(frame.treble * config.trebleBoost);
    final targetBeat = _normalize(frame.beat);
    final targetSpectrum = _resample(frame.spectrum, config.bandCount);

    _level = _smooth(_level, targetLevel, deltaSeconds);
    _bass = _smooth(_bass, targetBass, deltaSeconds);
    _mid = _smooth(_mid, targetMid, deltaSeconds);
    _treble = _smooth(_treble, targetTreble, deltaSeconds);

    final energyWeightTotal =
        config.levelEnergyWeight +
        config.bassEnergyWeight +
        config.midEnergyWeight +
        config.trebleEnergyWeight;
    final targetEnergy = energyWeightTotal <= 0
        ? 0.0
        : _normalize(
            (targetLevel * config.levelEnergyWeight +
                    targetBass * config.bassEnergyWeight +
                    targetMid * config.midEnergyWeight +
                    targetTreble * config.trebleEnergyWeight) /
                energyWeightTotal,
          );
    _energy = _smooth(_energy, targetEnergy, deltaSeconds);

    for (var index = 0; index < _spectrum.length; index++) {
      _spectrum[index] = _smooth(
        _spectrum[index],
        targetSpectrum[index],
        deltaSeconds,
      );
    }

    _beatImpulse = _nextBeatImpulse(targetBeat, _beatImpulse, deltaSeconds);
    _advancePeaks(
      targetSpectrum: targetSpectrum,
      nowMicros: nowMicros,
      previousTickMicros: previousTickMicros,
    );

    final brightness = _normalize(_lerp(0.62, 0.94, _energy * _energy));
    final saturation = _normalize(_lerp(0.60, 1, _energy));
    final glow = _normalize(
      math.pow(_energy, 0.85).toDouble() * 0.82 + _beatImpulse * 0.18,
    );
    final hue = _normalize(_energy);
    final particleIntensity = _normalize(
      _energy * 0.50 + _treble * 0.30 + _beatImpulse * 0.20,
    );

    return VisualizerDynamicsState(
      energy: _energy,
      level: _level,
      bass: _bass,
      mid: _mid,
      treble: _treble,
      beat: targetBeat,
      beatImpulse: _beatImpulse,
      brightness: brightness,
      saturation: saturation,
      glow: glow,
      hue: hue,
      particleIntensity: particleIntensity,
      spectrum: _spectrum,
      peaks: _peakLevels,
    );
  }

  /// Elimina toda la historia temporal sin cambiar la configuración.
  void reset() {
    _energy = 0;
    _level = 0;
    _bass = 0;
    _mid = 0;
    _treble = 0;
    _beatImpulse = 0;
    _lastTickMicros = null;
    for (var index = 0; index < config.bandCount; index++) {
      _spectrum[index] = 0;
      _peakLevels[index] = 0;
      _peakHoldUntilMicros[index] = 0;
    }
  }

  double _elapsedSeconds(int nowMicros) {
    final previous = _lastTickMicros;
    if (previous == null) {
      _lastTickMicros = nowMicros;
      return 1 / config.referenceFrameRate;
    }
    if (nowMicros <= previous) return 0;
    _lastTickMicros = nowMicros;
    return (nowMicros - previous) / Duration.microsecondsPerSecond;
  }

  double _smooth(double current, double target, double deltaSeconds) {
    if (deltaSeconds <= 0 || current == target) return current;
    final coefficient = target > current ? config.attack : config.release;
    if (coefficient == 0) return current;
    if (coefficient == 1) return target;
    final referenceFrames = deltaSeconds * config.referenceFrameRate;
    final retained = math.pow(1 - coefficient, referenceFrames).toDouble();
    return _normalize(target + (current - target) * retained);
  }

  double _nextBeatImpulse(double beat, double current, double deltaSeconds) {
    final durationSeconds =
        math.max(1, config.beatImpulseDuration.inMicroseconds) /
        Duration.microsecondsPerSecond;
    final decayed = math.max(0.0, current - deltaSeconds / durationSeconds);
    return _normalize(math.max(beat, decayed));
  }

  void _advancePeaks({
    required List<double> targetSpectrum,
    required int nowMicros,
    required int? previousTickMicros,
  }) {
    for (var index = 0; index < config.bandCount; index++) {
      final target = targetSpectrum[index];
      if (target >= _peakLevels[index]) {
        _peakLevels[index] = target;
        _peakHoldUntilMicros[index] =
            nowMicros + math.max(0, config.peakHold.inMicroseconds);
        continue;
      }

      final holdUntil = _peakHoldUntilMicros[index];
      if (nowMicros <= holdUntil) continue;

      final decayStart = math.max(previousTickMicros ?? nowMicros, holdUntil);
      final decayMicros = math.max(0, nowMicros - decayStart);
      if (decayMicros == 0) continue;
      final referenceFrames =
          decayMicros /
          Duration.microsecondsPerSecond *
          config.referenceFrameRate;
      final retained = math.pow(config.peakDecay, referenceFrames).toDouble();
      _peakLevels[index] = _normalize(
        math.max(
          math.max(target, _spectrum[index]),
          _peakLevels[index] * retained,
        ),
      );
    }
  }

  static List<double> _resample(List<double> source, int outputLength) {
    if (source.isEmpty) {
      return List<double>.filled(outputLength, 0, growable: false);
    }

    final normalized = List<double>.generate(
      source.length,
      (index) => _normalize(source[index]),
      growable: false,
    );
    if (normalized.length == 1) {
      return List<double>.filled(
        outputLength,
        normalized.first,
        growable: false,
      );
    }
    if (outputLength == 1) {
      return <double>[normalized.first];
    }

    return List<double>.generate(outputLength, (index) {
      final position = index * (normalized.length - 1) / (outputLength - 1);
      final lower = position.floor();
      final upper = math.min(lower + 1, normalized.length - 1);
      final fraction = position - lower;
      return _lerp(normalized[lower], normalized[upper], fraction);
    }, growable: false);
  }

  static double _normalize(double value) {
    if (!value.isFinite) return 0;
    return value.clamp(0.0, 1.0).toDouble();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
