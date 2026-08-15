import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/player/visualizer_dynamics.dart';

void main() {
  const frameMicros = 33333;

  AudioAnalysisFrame frame({
    double level = 0,
    double bass = 0,
    double mid = 0,
    double treble = 0,
    double beat = 0,
    List<double> spectrum = const <double>[],
  }) {
    return AudioAnalysisFrame(
      level: level,
      bass: bass,
      mid: mid,
      treble: treble,
      beat: beat,
      spectrum: spectrum,
    );
  }

  group('VisualizerDynamicsEngine', () {
    test('exposes the documented configurable defaults', () {
      const config = VisualizerDynamicsConfig();

      expect(config.bandCount, 64);
      expect(config.attack, 0.55);
      expect(config.release, 0.12);
      expect(config.referenceFrameRate, 30);
      expect(config.levelEnergyWeight, 0.38);
      expect(config.bassEnergyWeight, 0.30);
      expect(config.midEnergyWeight, 0.20);
      expect(config.trebleEnergyWeight, 0.12);
      expect(config.peakHold, const Duration(milliseconds: 100));
      expect(config.peakDecay, 0.94);
      expect(config.beatImpulseDuration, const Duration(milliseconds: 160));
    });

    test('uses the documented weighted energy and 30 Hz attack', () {
      final engine = VisualizerDynamicsEngine();
      engine.update(frame(), 0);

      final state = engine.update(
        frame(level: 1, bass: 0.5, mid: 0.25, treble: 0.75),
        frameMicros,
      );
      const target = 1 * 0.38 + 0.5 * 0.30 + 0.25 * 0.20 + 0.75 * 0.12;

      expect(state.energy, closeTo(target * 0.55, 0.00001));
      expect(state.level, closeTo(0.55, 0.00001));
      expect(state.bass, closeTo(0.275, 0.00001));
      expect(state.mid, closeTo(0.1375, 0.00001));
      expect(state.treble, closeTo(0.4125, 0.00001));
    });

    test('normalizes input and applies optional band boosts', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(
          attack: 1,
          release: 1,
          bassBoost: 2,
          midBoost: 0.5,
          trebleBoost: 3,
        ),
      );

      final state = engine.update(
        frame(level: -2, bass: 0.7, mid: 0.8, treble: 0.4, beat: 5),
        0,
      );

      expect(state.level, 0);
      expect(state.bass, 1);
      expect(state.mid, 0.4);
      expect(state.treble, 1);
      expect(state.beat, 1);
      expect(state.energy, closeTo(0.5, 0.000001));
      expect(state.particleIntensity, inInclusiveRange(0, 1));
    });

    test('allows one centralized energy weighting calibration', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(
          attack: 1,
          release: 1,
          levelEnergyWeight: 0,
          bassEnergyWeight: 0,
          midEnergyWeight: 0,
          trebleEnergyWeight: 2,
        ),
      );

      final state = engine.update(
        frame(level: 1, bass: 1, mid: 1, treble: 0.25),
        0,
      );

      expect(state.energy, 0.25);
    });

    test('derives color, glow, and particle intensity centrally', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(attack: 1, release: 1),
      );

      final quiet = engine.update(frame(), 0);
      expect(quiet.brightness, 0.62);
      expect(quiet.saturation, 0.60);
      expect(quiet.glow, 0);
      expect(quiet.hue, 0);
      expect(quiet.particleIntensity, 0);

      final loud = engine.update(
        frame(level: 1, bass: 1, mid: 1, treble: 1, beat: 1),
        frameMicros,
      );
      expect(loud.energy, closeTo(1, 0.000001));
      expect(loud.brightness, closeTo(0.94, 0.000001));
      expect(loud.saturation, closeTo(1, 0.000001));
      expect(loud.glow, closeTo(1, 0.000001));
      expect(loud.hue, closeTo(1, 0.000001));
      expect(loud.particleIntensity, closeTo(1, 0.000001));
    });

    test('attack is quicker than release and independent of frame rate', () {
      VisualizerDynamicsEngine engine() => VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(bandCount: 1),
      );

      final oneStep = engine()..update(frame(), 0);
      final oneStepState = oneStep.update(frame(level: 1), frameMicros);

      final twoSteps = engine()..update(frame(), 0);
      twoSteps.update(frame(level: 1), frameMicros ~/ 2);
      final twoStepState = twoSteps.update(frame(level: 1), frameMicros);

      expect(oneStepState.level, closeTo(twoStepState.level, 0.00002));
      expect(oneStepState.level, closeTo(0.55, 0.00001));

      final falling = engine();
      falling.update(frame(level: 1), 0);
      falling.update(frame(level: 1), frameMicros);
      final beforeFall = falling.update(frame(level: 1), frameMicros * 2).level;
      final afterFall = falling.update(frame(), frameMicros * 3).level;
      final releaseChange = beforeFall - afterFall;

      final rising = engine()..update(frame(), 0);
      final beforeRise = rising.update(frame(), frameMicros).level;
      final afterRise = rising.update(frame(level: 1), frameMicros * 2).level;
      final attackChange = afterRise - beforeRise;

      expect(attackChange, greaterThan(releaseChange));
      expect(afterFall, closeTo(beforeFall * 0.88, 0.00002));
    });

    test('holds a peak for 100 ms then decays slowly', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(
          bandCount: 1,
          attack: 1,
          release: 1,
        ),
      );

      expect(
        engine.update(frame(spectrum: const <double>[1]), 0).peaks,
        <double>[1],
      );
      expect(
        engine.update(frame(spectrum: const <double>[0]), 99999).peaks.single,
        1,
      );
      expect(
        engine.update(frame(spectrum: const <double>[0]), 100000).peaks.single,
        1,
      );
      final afterDecay = engine
          .update(frame(spectrum: const <double>[0]), 133333)
          .peaks
          .single;

      expect(afterDecay, closeTo(0.94, 0.00001));
      expect(afterDecay, greaterThan(0));
    });

    test('peak decay accounts only for time after the hold', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(
          bandCount: 1,
          attack: 1,
          release: 1,
          peakDecay: 0.5,
        ),
      );

      engine.update(frame(spectrum: const <double>[1]), 0);
      final state = engine.update(frame(spectrum: const <double>[0]), 116667);

      // Solo 16.667 ms (medio frame de referencia) corresponden a decay.
      expect(state.peaks.single, closeTo(0.70710678, 0.0001));
    });

    test(
      'beat impulse is bounded, lasts 80-180 ms, and ambient stays quiet',
      () {
        final engine = VisualizerDynamicsEngine(
          config: const VisualizerDynamicsConfig(bandCount: 1),
        );

        final ambient = engine.update(frame(level: 0.3, beat: 0), 0);
        expect(ambient.beat, 0);
        expect(ambient.beatImpulse, 0);

        final pulse = engine.update(frame(beat: 2), 1000);
        expect(pulse.beat, 1);
        expect(pulse.beatImpulse, 1);

        final during = engine.update(frame(beat: 0), 81000);
        expect(during.beatImpulse, closeTo(0.5, 0.000001));

        final ended = engine.update(frame(beat: 0), 161000);
        expect(ended.beatImpulse, 0);
        expect(ended.beat, 0);

        for (var tick = 2; tick < 12; tick++) {
          final state = engine.update(
            frame(level: 0.2, beat: 0),
            tick * 100000,
          );
          expect(state.beatImpulse, 0);
        }
      },
    );

    test('resamples every spectrum to 64 immutable bands', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(attack: 1, release: 1),
      );
      final state = engine.update(
        frame(spectrum: const <double>[0, 0.5, 1]),
        0,
      );

      expect(state.spectrum, hasLength(64));
      expect(state.peaks, hasLength(64));
      expect(state.spectrum.first, 0);
      expect(state.spectrum.last, 1);
      expect(state.spectrum[32], closeTo(32 / 63, 0.000001));
      expect(() => state.spectrum[0] = 1, throwsUnsupportedError);
      expect(() => state.peaks[0] = 1, throwsUnsupportedError);

      // El estado conserva su snapshot aunque el motor siga avanzando.
      engine.update(frame(spectrum: const <double>[1]), frameMicros);
      expect(state.spectrum.first, 0);
      expect(state.peaks.first, 0);
    });

    test('reset clears smoothing, peaks, beat, and clock history', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(bandCount: 2),
      );
      engine.update(
        frame(
          level: 1,
          bass: 1,
          mid: 1,
          treble: 1,
          beat: 1,
          spectrum: const <double>[1, 0.5],
        ),
        0,
      );

      engine.reset();
      final state = engine.update(frame(), 9000000);

      expect(state.energy, 0);
      expect(state.level, 0);
      expect(state.bass, 0);
      expect(state.mid, 0);
      expect(state.treble, 0);
      expect(state.beat, 0);
      expect(state.beatImpulse, 0);
      expect(state.particleIntensity, 0);
      expect(state.spectrum, <double>[0, 0]);
      expect(state.peaks, <double>[0, 0]);
    });

    test('NaN, infinities, and out-of-range values never escape', () {
      final engine = VisualizerDynamicsEngine(
        config: const VisualizerDynamicsConfig(attack: 1, release: 1),
      );
      final state = engine.update(
        frame(
          level: double.nan,
          bass: double.infinity,
          mid: double.negativeInfinity,
          treble: 4,
          beat: double.nan,
          spectrum: const <double>[
            double.nan,
            double.infinity,
            double.negativeInfinity,
            -2,
            3,
          ],
        ),
        0,
      );

      final scalars = <double>[
        state.energy,
        state.level,
        state.bass,
        state.mid,
        state.treble,
        state.beat,
        state.beatImpulse,
        state.brightness,
        state.saturation,
        state.glow,
        state.hue,
        state.particleIntensity,
        ...state.spectrum,
        ...state.peaks,
      ];
      expect(scalars, everyElement(inInclusiveRange(0, 1)));
      expect(scalars.every((value) => value.isFinite), isTrue);
      expect(state.level, 0);
      expect(state.bass, 0);
      expect(state.mid, 0);
      expect(state.treble, 1);
      expect(state.beatImpulse, 0);
    });
  });
}
