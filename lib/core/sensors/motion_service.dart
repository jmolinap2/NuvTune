import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Detecta cadencia de trote o caminata a partir del acelerómetro, para el
/// modo entrenamiento del reproductor.
///
/// No usa el reconocedor de actividad del sistema (`ACTIVITY_RECOGNITION`):
/// el acelerómetro crudo no pide permiso en Android y alcanza para esta
/// señal binaria. La detección cuenta picos de aceleración por encima de un
/// umbral dentro de una ventana deslizante; una cadencia sostenida en el
/// rango de paso humano (1.5-3 Hz) es lo que se reporta como "trotando".
class MotionService {
  MotionService({
    this.window = const Duration(seconds: 3),
    this.minPeaksToStart = 4,
    this.maxPeaksToStop = 1,
    this.peakThreshold = 1.6,
  });

  /// Ventana sobre la que se cuentan picos. Cadencia de paso humano cabe
  /// varias veces en 3 segundos, lo que evita que un solo tropezón dispare
  /// el modo entrenamiento.
  final Duration window;

  /// Picos mínimos en la ventana para considerar que hay cadencia sostenida.
  final int minPeaksToStart;

  /// Por debajo de este conteo se considera quietud, incluso ya activado:
  /// distinto del umbral de entrada para dar histéresis y que la señal no
  /// parpadee en el borde.
  final int maxPeaksToStop;

  /// Aceleración por encima de la gravedad (m/s², descontando ~9.8) que
  /// cuenta como un paso.
  final double peakThreshold;

  /// Cadencia sostenida de trote o caminata: `true`/`false` sin estados
  /// intermedios, con la histéresis ya aplicada. Es la única señal que
  /// expone el servicio; la decisión de qué hacer con ella vive en quien la
  /// consume.
  Stream<bool> get isJogging async* {
    var jogging = false;
    final peakTimes = <DateTime>[];
    var lastMagnitude = 0.0;
    var risingEdge = false;

    yield jogging;

    await for (final event in accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    )) {
      final magnitude =
          math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          ) -
          9.80665;

      // Cuenta el cruce ascendente sobre el umbral, no cada muestra por
      // encima de él: un solo paso puede mantenerse arriba del umbral
      // durante varias muestras seguidas, y contar cada una infla el
      // conteo sin relación con la cadencia real.
      final aboveThreshold = magnitude > peakThreshold;
      if (aboveThreshold && !risingEdge && lastMagnitude <= peakThreshold) {
        peakTimes.add(DateTime.now());
      }
      risingEdge = aboveThreshold;
      lastMagnitude = magnitude;

      final cutoff = DateTime.now().subtract(window);
      peakTimes.removeWhere((time) => time.isBefore(cutoff));

      final shouldJog = jogging
          ? peakTimes.length > maxPeaksToStop
          : peakTimes.length >= minPeaksToStart;

      if (shouldJog != jogging) {
        jogging = shouldJog;
        yield jogging;
      }
    }
  }
}
