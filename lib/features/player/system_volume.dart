import 'package:flutter/services.dart';

/// Volumen de musica del sistema (`AudioManager.STREAM_MUSIC`, resuelto en
/// `MainActivity.kt`).
///
/// El volumen del usuario NO se toca sobre `ExoPlayer.volume`: ese campo ya
/// tiene un escritor, [FadeController] en el motor nativo, que lo rampa para
/// el fundido y el relevo entre pistas. Dos escritores sobre el mismo campo
/// darian un volumen que depende del orden de llegada -exactamente el defecto
/// que prohibe la regla 1-: bajar el volumen a la mitad y que el siguiente
/// fundido lo devolviera a 1.0 sin que nadie lo pidiera. El volumen de flujo
/// del sistema es un dato distinto, con su propio unico escritor, y ademas es
/// el que el usuario espera que compartan las teclas fisicas.
class SystemVolume {
  const SystemVolume._();

  static const _channel = MethodChannel('com.nuvtune.app/system_volume');

  static Future<double> read() async {
    final value = await _channel.invokeMethod<double>('getMusicVolume');
    return (value ?? 0).clamp(0.0, 1.0).toDouble();
  }

  static Future<void> write(double value) => _channel.invokeMethod<void>(
    'setMusicVolume',
    {'volume': value.clamp(0.0, 1.0)},
  );
}
