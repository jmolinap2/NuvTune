import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuvtune/features/community/community_api.dart';

final communityApiProvider = Provider<CommunityApi>((ref) => CommunityApi());

/// Sesion iniciada: quien eres y con que token se firman las peticiones.
class CommunitySession {
  const CommunitySession({required this.username, required this.token});
  final String username;
  final String token;
}

const _tokenKey = 'community_token';
const _storage = FlutterSecureStorage();

/// Unico escritor de la sesion de comunidad (y de su token guardado).
///
/// `null` significa sin sesion. Al arrancar se valida el token guardado contra
/// el servidor: si ya no vale se borra, en vez de dejar una sesion fantasma.
final communitySessionProvider =
    AsyncNotifierProvider<CommunitySessionController, CommunitySession?>(
      CommunitySessionController.new,
    );

class CommunitySessionController extends AsyncNotifier<CommunitySession?> {
  CommunityApi get _api => ref.read(communityApiProvider);

  @override
  Future<CommunitySession?> build() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    try {
      return CommunitySession(username: await _api.me(token), token: token);
    } on CommunityException catch (error) {
      // Solo un 401 prueba que el token murio. Sin conexion no se sabe: el
      // error llega a la pantalla (con reintento) y el token se conserva.
      if (!error.isUnauthorized) rethrow;
      await _storage.delete(key: _tokenKey);
      return null;
    }
  }

  Future<void> login(String username, String password) =>
      _open(() => _api.login(username, password));

  Future<void> register(String username, String password) =>
      _open(() => _api.register(username, password));

  Future<void> _open(
    Future<({String token, String username})> Function() action,
  ) async {
    final result = await action();
    await _storage.write(key: _tokenKey, value: result.token);
    state = AsyncData(
      CommunitySession(username: result.username, token: result.token),
    );
  }

  Future<void> logout() async {
    final session = state.valueOrNull;
    if (session == null) return;
    await _api.logout(session.token);
    await _storage.delete(key: _tokenKey);
    state = const AsyncData(null);
  }
}

/// Amigos y solicitudes de la sesion actual. Se recarga con `invalidate`.
final friendsProvider = FutureProvider.autoDispose<Friends>((ref) async {
  final session = await ref.watch(communitySessionProvider.future);
  if (session == null) throw const CommunityException('Sin sesión.');
  return ref.read(communityApiProvider).friends(session.token);
});
