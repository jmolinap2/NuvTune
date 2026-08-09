import 'package:flutter/services.dart';

enum GiftShareChannel { whatsApp, email }

/// Archivo de regalo con el que se abrio la aplicacion desde fuera (WhatsApp,
/// Drive, un gestor de archivos).
///
/// Deliberadamente un MethodChannel aparte del contrato de Pigeon, igual que
/// en C:\Repos\NuvClip: es un dato que Dart consulta puntualmente al arrancar
/// o al volver a primer plano, no una operacion del motor.
class GiftIntentService {
  const GiftIntentService();

  static const _channel = MethodChannel('com.nuvtune.app/gift_intent');

  /// Devuelve la uri pendiente y la consume: dos llamadas seguidas no abren
  /// el mismo regalo dos veces.
  Future<String?> takePendingGift() async {
    try {
      return await _channel.invokeMethod<String>('takePendingGift');
    } on MissingPluginException {
      // En pruebas de widget no hay lado nativo; no tener regalo pendiente es
      // la respuesta correcta, no un error.
      return null;
    }
  }

  /// Entrega el archivo usando un URI temporal de solo lectura. En WhatsApp
  /// intenta abrir el chat directamente; si no esta instalado, Android abre
  /// el panel general. Correo siempre usa el selector para que el usuario
  /// elija su aplicacion de confianza.
  Future<void> shareGift({
    required String path,
    required GiftShareChannel channel,
    required String subject,
    required String text,
  }) async {
    await _channel.invokeMethod<void>('shareGift', {
      'path': path,
      'channel': channel.name,
      'subject': subject,
      'text': text,
    });
  }
}
