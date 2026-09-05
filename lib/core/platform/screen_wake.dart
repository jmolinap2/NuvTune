import 'package:flutter/material.dart';
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

  /// El usuario eligio [ScreenWakeMode.always]: la pantalla no se apaga
  /// mientras el reproductor completo este abierto, sin importar que se este
  /// viendo en ese momento.
  always,
}

/// Cuando el usuario quiere que la pantalla no se apague sola.
///
/// No es una razon mas de [ScreenWakeReason]: decide si [videoBackground] y
/// [trainingMode] llegan a pedir la pantalla encendida o no, ademas de poder
/// activar [ScreenWakeReason.always] por si mismo.
enum ScreenWakeMode {
  automatic(
    'Automático',
    'Solo mientras se ve un video de fondo o el modo entrenamiento está '
        'activo',
    Icons.auto_awesome_rounded,
  ),
  always(
    'Siempre',
    'La pantalla no se apaga mientras el reproductor está abierto',
    Icons.brightness_high_rounded,
  ),
  never(
    'Nunca',
    'La pantalla se apaga según el ajuste del sistema, incluso con video de '
        'fondo o modo entrenamiento',
    Icons.brightness_low_rounded,
  );

  const ScreenWakeMode(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  static ScreenWakeMode fromIndex(int index) {
    if (index < 0 || index >= values.length) return automatic;
    return values[index];
  }
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
