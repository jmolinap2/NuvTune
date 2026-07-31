import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/permissions/permission_service.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/settings/widgets_screen.dart';

enum BootstrapStage {
  starting,
  requestingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  scanning,
  ready,
}

class BootstrapState {
  const BootstrapState({required this.stage, this.songCount = 0});

  final BootstrapStage stage;
  final int songCount;

  bool get isReady => stage == BootstrapStage.ready;

  bool get needsPermission =>
      stage == BootstrapStage.permissionDenied ||
      stage == BootstrapStage.permissionPermanentlyDenied;
}

final bootstrapProvider =
    NotifierProvider<BootstrapController, BootstrapState>(BootstrapController.new);

/// Arranque de la aplicacion, en el orden en que las cosas dependen unas de
/// otras: permiso, motor, ajustes de audio, biblioteca y por ultimo la cola
/// guardada, que necesita la biblioteca ya cargada para resolver las canciones.
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

    state = const BootstrapState(stage: BootstrapStage.scanning);

    final settings = await ref.read(settingsRepositoryProvider).settings();

    // El motor guarda su propia copia de la configuracion del widget para poder
    // dibujarlo con la aplicacion cerrada. Se resincroniza en cada arranque por
    // si la base de datos se restauro desde una copia de seguridad.
    ref.read(engineProvider).api.setWidgetConfig(widgetConfigOf(settings));

    final library = ref.read(libraryProvider.notifier);
    if (settings.scanOnStart || settings.lastScanAt == null) {
      await library.scan();
    } else {
      await library.refresh();
    }

    if (settings.restoreQueueOnStart) {
      await ref.read(playbackProvider.notifier).restoreSavedQueue();
    }

    state = BootstrapState(
      stage: BootstrapStage.ready,
      songCount: ref.read(libraryProvider).songs.length,
    );
  }

  /// Reintento tras conceder el permiso desde los ajustes del sistema.
  Future<void> retry() => start();

  Future<void> openSystemSettings() =>
      ref.read(permissionServiceProvider).openSettings();
}
