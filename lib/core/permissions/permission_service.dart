import 'package:permission_handler/permission_handler.dart';

/// Estado del permiso de lectura de audio.
enum MusicPermissionStatus { granted, denied, permanentlyDenied }

/// Permisos que necesita la aplicacion.
///
/// Solo se pide lectura de audio; nunca acceso total al almacenamiento
/// (requerimiento seccion 16). Las carpetas fuera de MediaStore se abren con el
/// selector del sistema, que no requiere permiso previo.
class PermissionService {
  const PermissionService();

  Future<MusicPermissionStatus> currentStatus() async {
    final status = await Permission.audio.status;
    return _map(status);
  }

  Future<MusicPermissionStatus> requestMusicAccess() async {
    final status = await Permission.audio.request();
    return _map(status);
  }

  /// La notificacion multimedia es la que mantiene vivo el servicio en primer
  /// plano; sin ella el sistema puede detener la reproduccion.
  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> openSettings() => openAppSettings();

  MusicPermissionStatus _map(PermissionStatus status) => switch (status) {
        PermissionStatus.granted => MusicPermissionStatus.granted,
        PermissionStatus.limited => MusicPermissionStatus.granted,
        PermissionStatus.provisional => MusicPermissionStatus.granted,
        PermissionStatus.permanentlyDenied =>
          MusicPermissionStatus.permanentlyDenied,
        PermissionStatus.restricted => MusicPermissionStatus.permanentlyDenied,
        PermissionStatus.denied => MusicPermissionStatus.denied,
      };
}
