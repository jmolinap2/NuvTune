import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _darkSystemBars = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFF0B0F17),
  systemNavigationBarDividerColor: Color(0xFF0B0F17),
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

const _portraitOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
];

/// Interfaz normal: contenido de borde a borde y navegacion del sistema oscura.
Future<void> useDefaultSystemUi() async {
  await SystemChrome.setPreferredOrientations(_portraitOrientations);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_darkSystemBars);
}

/// Reproductor completo: conserva la barra de estado y oculta solo la barra de
/// navegacion inferior de NuvTune. Las barras del sistema permanecen visibles
/// y el contenido acepta tanto orientación vertical como horizontal.
Future<void> usePlayerSystemUi() async {
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  SystemChrome.setSystemUIOverlayStyle(_darkSystemBars);
}

/// Visualizador expandido: el lienzo usa toda la pantalla y las barras vuelven
/// temporalmente con un gesto desde el borde.
Future<void> useVisualizerFullscreenSystemUi() async {
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(_darkSystemBars);
}
