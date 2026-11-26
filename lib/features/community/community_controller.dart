import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuvtune/features/community/community_service.dart';
import 'package:nuvtune/features/community/nostr/nostr_keys.dart';

const _secretKey = 'community_secret_key';
const _storage = FlutterSecureStorage();

/// Tu identidad de comunidad: un par de claves guardado en el almacen seguro
/// del telefono. `null` significa que aun no tienes usuario.
///
/// Es el unico escritor de la clave guardada. No hay contraseña ni servidor:
/// quien tiene la clave secreta es esa persona.
final identityProvider = AsyncNotifierProvider<IdentityController, NostrKeys?>(
  IdentityController.new,
);

class IdentityController extends AsyncNotifier<NostrKeys?> {
  @override
  Future<NostrKeys?> build() async {
    final secret = await _storage.read(key: _secretKey);
    return secret == null ? null : NostrKeys.fromSecretHex(secret);
  }

  /// Crea una identidad nueva. Primero se publica el nombre y solo si llega a
  /// algun relay se guarda la clave: asi un fallo de red no deja un usuario a
  /// medias.
  Future<void> create(String name) async {
    final keys = NostrKeys.generate();
    await CommunityService(keys).publishName(name);
    await _save(keys);
  }

  /// Recupera una identidad existente (por ejemplo, en un telefono nuevo).
  Future<void> restore(String secret) => _save(NostrKeys.parseSecret(secret));

  Future<void> _save(NostrKeys keys) async {
    await _storage.write(key: _secretKey, value: keys.secretHex);
    state = AsyncData(keys);
  }

  /// Borra la clave de este telefono. Sin copia de la clave secreta, esa
  /// identidad y sus amistades no se pueden recuperar.
  Future<void> signOut() async {
    await _storage.delete(key: _secretKey);
    state = const AsyncData(null);
  }
}

/// Servicio de la identidad actual; `null` sin identidad.
final communityServiceProvider = Provider<CommunityService?>((ref) {
  final keys = ref.watch(identityProvider).valueOrNull;
  return keys == null ? null : CommunityService(keys);
});

/// Tu nombre publicado.
final myNameProvider = FutureProvider.autoDispose<String?>((ref) {
  final service = ref.watch(communityServiceProvider);
  return service?.myName() ?? Future.value();
});

/// Amigos y solicitudes. Se recarga con `ref.invalidate(friendsProvider)`.
final friendsProvider = FutureProvider.autoDispose<Friends>((ref) {
  final service = ref.watch(communityServiceProvider)!;
  return service.friends();
});
