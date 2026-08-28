import 'package:connectivity_plus/connectivity_plus.dart';

/// Envoltura de `connectivity_plus` para saber si hay Wi-Fi (requerimiento
/// "video de fondo en Wi-Fi": nunca debe usar datos moviles).
class ConnectivityService {
  const ConnectivityService();

  /// Empieza con el estado actual y sigue con los cambios: `onConnectivityChanged`
  /// por si sola solo avisa de cambios futuros, y sin el estado inicial el
  /// fondo de video tardaria en aparecer hasta el primer cambio de red.
  Stream<bool> get isOnWifi async* {
    yield await checkIsOnWifi();
    yield* Connectivity().onConnectivityChanged.map(
      (results) => results.contains(ConnectivityResult.wifi),
    );
  }

  Future<bool> checkIsOnWifi() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }
}
