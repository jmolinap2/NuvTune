import 'package:flutter/services.dart';

/// Por que se pide mantener la pantalla encendida.
///
/// La bandera de ventana es una sola, asi que si cada pantalla la encendiera y
/// apagara por su cuenta, la ultima en apagarla ganaria: salir del modo
/// entrenamiento apagaria la pantalla aunque el video de fondo siga
/// necesitandola. Nombrar la razon permite que el estado real sea "hay al
/// menos una razon activa".
enum ScreenWakeReason {
  /// Hay un video reproduciendose como fondo: el usuario lo esta mirando, y
  /// mirar no cuenta como interaccion para el sistema.
  videoBackground,

  /// Modo entrenamiento: la pantalla se mira de reojo mientras se trota, sin
  /// manos libres para tocarla.
  trainingMode,
}

/// Mantiene la pantalla encendida mientras haya alguna razon activa.
///
/// Unico escritor de `FLAG_KEEP_SCREEN_ON` (resuelto en `MainActivity.kt`).
/// La bandera vive en la ventana de la actividad, de modo que el sistema la
/// retira solo al pasar a segundo plano: no hay un WakeLock que pueda quedarse
/// encendido si la aplicacion muere.
class ScreenWake {
  const ScreenWake._();

  static const _channel = MethodChannel('com.nuvtune.app/screen_wake');

  static final Set<ScreenWakeReason> _reasons = {};
  static bool _applied = false;

  /// Declara si [reason] necesita la pantalla encendida ahora mismo.
  static Future<void> setReason(
    ScreenWakeReason reason, {
    required bool active,
  }) async {
    final changed = active ? _reasons.add(reason) : _reasons.remove(reason);
    if (!changed) return;
    await _apply();
  }

  static Future<void> _apply() async {
    final shouldKeepOn = _reasons.isNotEmpty;
    if (shouldKeepOn == _applied) return;
    _applied = shouldKeepOn;
    await _channel.invokeMethod<void>('setKeepScreenOn', {
      'enabled': shouldKeepOn,
    });
  }
}
