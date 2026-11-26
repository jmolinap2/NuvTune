import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Lo que publica el CI en `version.json` junto a cada APK.
class UpdateInfo {
  const UpdateInfo({
    required this.build,
    required this.name,
    required this.message,
    required this.apkUrl,
    required this.bytes,
  });

  factory UpdateInfo.fromJson(Map<String, Object?> json, Uri base) =>
      UpdateInfo(
        build: json['build']! as int,
        name: json['name']! as String,
        message: json['message']! as String,
        apkUrl: base.resolve(json['apk']! as String),
        bytes: json['bytes']! as int,
      );

  /// Numero de compilacion (`versionCode`): unico criterio para decidir si hay
  /// algo nuevo. Solo crece, porque sale del numero de commits.
  final int build;
  final String name;

  /// Asunto del commit publicado.
  final String message;
  final Uri apkUrl;
  final int bytes;
}

sealed class UpdateCheck {
  const UpdateCheck();
}

class UpToDate extends UpdateCheck {
  const UpToDate();
}

class UpdateAvailable extends UpdateCheck {
  const UpdateAvailable(this.info);
  final UpdateInfo info;
}

/// No se pudo consultar el servidor (sin internet, sitio caido...). Es un
/// resultado normal, no un estado imposible: la comprobacion automatica lo
/// ignora a proposito y la manual lo muestra.
class CheckFailed extends UpdateCheck {
  const CheckFailed(this.reason);
  final String reason;
}

/// Actualizacion por internet: consulta `version.json` del sitio donde el CI
/// publica cada commit, descarga la APK y delega la instalacion en Android.
class AppUpdater {
  AppUpdater({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  /// Sitio de Netlify donde el CI publica `version.json` y `NuvTune.apk`.
  static final Uri baseUrl = Uri.parse('https://nuvtune.netlify.app/');

  static const _channel = MethodChannel('com.nuvtune.app/updater');
  static const _timeout = Duration(seconds: 15);

  final http.Client _http;

  Future<int> installedBuild() async =>
      (await _channel.invokeMethod<int>('installedBuild'))!;

  Future<bool> canInstall() async =>
      (await _channel.invokeMethod<bool>('canInstall'))!;

  Future<void> openInstallSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');

  Future<void> install(File apk) =>
      _channel.invokeMethod<void>('install', {'path': apk.path});

  Future<UpdateCheck> check() async {
    final http.Response response;
    try {
      // El parametro evita que un cache intermedio sirva un manifiesto viejo.
      final uri = baseUrl.resolve(
        'version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      response = await _http.get(uri).timeout(_timeout);
    } on Exception {
      return const CheckFailed(
        'Sin conexión con el servidor de actualizaciones',
      );
    }
    if (response.statusCode != 200) {
      return CheckFailed('El servidor respondió ${response.statusCode}');
    }
    final info = UpdateInfo.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
      baseUrl,
    );
    return info.build > await installedBuild()
        ? UpdateAvailable(info)
        : const UpToDate();
  }

  /// Descarga la APK y avisa el avance (0..1). Falla si el tamano no coincide
  /// con el publicado: una descarga truncada nunca llega al instalador.
  Future<File> download(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
  }) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/NuvTune-${info.build}.apk');

    final response = await _http.send(http.Request('GET', info.apkUrl));
    if (response.statusCode != 200) {
      throw HttpException('La descarga respondió ${response.statusCode}');
    }
    final sink = file.openWrite();
    var received = 0;
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received / info.bytes);
    }
    await sink.close();

    if (received != info.bytes) {
      throw HttpException(
        'Descarga incompleta: $received de ${info.bytes} bytes',
      );
    }
    return file;
  }
}
