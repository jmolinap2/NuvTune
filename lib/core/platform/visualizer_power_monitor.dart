import 'dart:async';

import 'package:flutter/services.dart';

/// Estado energetico relevante para decidir cuanto trabajo visual realizar.
///
/// [batteryLevel] usa el intervalo 0..1 y puede ser nulo cuando Android no
/// puede leer una bateria (por ejemplo, ciertos emuladores). Una bateria baja
/// no reduce efectos mientras se esta cargando; el ahorro de energia siempre
/// lo hace porque expresa una decision explicita del usuario o del sistema.
class VisualizerPowerState {
  const VisualizerPowerState({
    required this.batteryLevel,
    required this.isCharging,
    required this.isBatteryLow,
    required this.isPowerSaveMode,
  });

  const VisualizerPowerState.normal()
    : batteryLevel = null,
      isCharging = false,
      isBatteryLow = false,
      isPowerSaveMode = false;

  final double? batteryLevel;
  final bool isCharging;
  final bool isBatteryLow;
  final bool isPowerSaveMode;

  bool get shouldReduceEffects =>
      isPowerSaveMode || (isBatteryLow && !isCharging);

  factory VisualizerPowerState.fromPlatformEvent(Object? event) {
    if (event is! Map<Object?, Object?>) {
      return const VisualizerPowerState.normal();
    }

    final rawLevel = event['batteryLevel'];
    final level = rawLevel is num ? rawLevel.toDouble().clamp(0.0, 1.0) : null;
    return VisualizerPowerState(
      batteryLevel: level,
      isCharging: event['isCharging'] == true,
      isBatteryLow: event['isBatteryLow'] == true,
      isPowerSaveMode: event['isPowerSaveMode'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualizerPowerState &&
          batteryLevel == other.batteryLevel &&
          isCharging == other.isCharging &&
          isBatteryLow == other.isBatteryLow &&
          isPowerSaveMode == other.isPowerSaveMode;

  @override
  int get hashCode =>
      Object.hash(batteryLevel, isCharging, isBatteryLow, isPowerSaveMode);
}

/// Fuente ligera del estado energetico de Android para el visualizador.
///
/// El lado nativo solo registra receptores del sistema cuando existe un
/// oyente. Al suscribirse emite inmediatamente el estado actual y despues
/// unicamente cuando cambia la bateria o el modo de ahorro.
class VisualizerPowerMonitor {
  VisualizerPowerMonitor({EventChannel? channel})
    : _channel =
          channel ??
          const EventChannel('com.nuvtune.app/visualizer_power_state');

  final EventChannel _channel;
  Stream<VisualizerPowerState>? _states;

  Stream<VisualizerPowerState> get states => _states ??= _channel
      .receiveBroadcastStream()
      .transform<VisualizerPowerState>(
        StreamTransformer<Object?, VisualizerPowerState>.fromHandlers(
          handleData: (event, sink) {
            sink.add(VisualizerPowerState.fromPlatformEvent(event));
          },
          handleError: (error, stackTrace, sink) {
            if (error is MissingPluginException) {
              // Los tests de widgets y las plataformas no Android no tienen
              // lado nativo. Calidad normal es el fallback determinista.
              sink.add(const VisualizerPowerState.normal());
            } else {
              sink.addError(error, stackTrace);
            }
          },
        ),
      )
      .distinct();
}
