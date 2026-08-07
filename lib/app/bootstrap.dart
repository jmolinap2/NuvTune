import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/permissions/permission_service.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/settings/widgets_screen.dart';

enum BootstrapStage {
  starting,
  requestingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  ready,
}

class BootstrapState {
  const BootstrapState({required this.stage});

  final BootstrapStage stage;

  bool get isReady => stage == BootstrapStage.ready;

  bool get needsPermission =>
      stage == BootstrapStage.permissionDenied ||
      stage == BootstrapStage.permissionPermanentlyDenied;
}

final bootstrapProvider =
    NotifierProvider<BootstrapController, BootstrapState>(BootstrapController.new);

/// Arranque de la aplicacion, en el orden en que las cosas dependen unas de
/// otras: permiso, motor, ajustes de audio y por ultimo biblioteca y cola
/// guardada.
///
/// El escaneo de biblioteca (y la restauracion de cola, que depende de el) ya
/// no bloquean la primera pantalla: con bibliotecas grandes, esperarlos hacia
/// sentir el arranque lento aunque el motor y los permisos ya estuvieran
/// listos. En vez de eso, la app pasa a `ready` en cuanto el motor esta
/// inicializado y el resto sigue en segundo plano; Inicio y Biblioteca ya
/// muestran `libraryProvider.isScanning` de forma reactiva mientras tanto.
class BootstrapController extends Notifier<BootstrapState> {
  @override
  BootstrapState build() =>
      const BootstrapState(stage: BootstrapStage.starting);

  Future<void> start() async {
    state = const BootstrapState(stage: BootstrapStage.requestingPermission);

    final permissions = ref.read(permissionServiceProvider);
    var status = await permissions.currentStatus();
    if (status != MusicPermissionStatus.granted) {
      status = await permissions.requestMusicAccess();
    }

    if (status != MusicPermissionStatus.granted) {
      state = BootstrapState(
        stage: status == MusicPermissionStatus.permanentlyDenied
            ? BootstrapStage.permissionPermanentlyDenied
            : BootstrapStage.permissionDenied,
      );
      return;
    }

    // La notificacion multimedia es la que sostiene el servicio en primer
    // plano; si el usuario la rechaza la reproduccion sigue funcionando, pero
    // sin controles fuera de la aplicacion.
    await permissions.requestNotifications();

    await ref.read(engineProvider).initialize();
    await ref.read(playbackProvider.notifier).pushAudioSettings();

    final settings = await ref.read(settingsRepositoryProvider).settings();

    // El motor guarda su propia copia de la configuracion del widget para poder
    // dibujarlo con la aplicacion cerrada. Se resincroniza en cada arranque por
    // si la base de datos se restauro desde una copia de seguridad.
    ref.read(engineProvider).api.setWidgetConfig(widgetConfigOf(settings));

    state = const BootstrapState(stage: BootstrapStage.ready);
    unawaited(_finishLoadingLibrary(settings));
    // Extrae los binarios de yt-dlp/ffmpeg la primera vez (costoso); no debe
    // demorar el arranque, y solo hace falta antes de buscar/descargar algo.
    unawaited(ref.read(downloadEngineProvider).initialize());
  }

  Future<void> _finishLoadingLibrary(AppSetting settings) async {
    final library = ref.read(libraryProvider.notifier);
    if (settings.scanOnStart || settings.lastScanAt == null) {
      await library.scan();
    } else {
      await library.refresh();
    }

    if (settings.restoreQueueOnStart) {
      await ref.read(playbackProvider.notifier).restoreSavedQueue();
    }
  }

  /// Reintento tras conceder el permiso desde los ajustes del sistema.
  Future<void> retry() => start();

  Future<void> openSystemSettings() =>
      ref.read(permissionServiceProvider).openSettings();
}
