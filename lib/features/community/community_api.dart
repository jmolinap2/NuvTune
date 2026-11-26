import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error legible para la persona: el servidor ya responde en español.
class CommunityException implements Exception {
  const CommunityException(this.message, {this.statusCode});
  final String message;

  /// Codigo HTTP de la respuesta; `null` si ni siquiera hubo conexion.
  final int? statusCode;

  /// El servidor rechazo el token: la sesion ya no existe.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class Friends {
  const Friends({
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  factory Friends.fromJson(Map<String, Object?> json) => Friends(
    friends: List<String>.from(json['friends']! as List),
    incoming: List<String>.from(json['incoming']! as List),
    outgoing: List<String>.from(json['outgoing']! as List),
  );

  final List<String> friends;

  /// Solicitudes recibidas, pendientes de aceptar.
  final List<String> incoming;

  /// Solicitudes enviadas, pendientes de que las acepten.
  final List<String> outgoing;
}

/// Cliente de la API de comunidad (`backend/community`).
class CommunityApi {
  CommunityApi({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  /// Direccion del Worker de Cloudflare. Se obtiene al desplegar
  /// `backend/community` (`pnpm deploy`); mientras tenga el marcador, toda
  /// llamada falla de forma visible en la pantalla de Comunidad.
  static final Uri baseUrl = Uri.parse(
    'https://nuvtune-community.REEMPLAZAR.workers.dev',
  );

  static const _timeout = Duration(seconds: 15);

  final http.Client _http;

  /// Devuelve `{token, username}`.
  Future<({String token, String username})> register(
    String username,
    String password,
  ) => _authenticate('register', username, password);

  Future<({String token, String username})> login(
    String username,
    String password,
  ) => _authenticate('login', username, password);

  Future<({String token, String username})> _authenticate(
    String path,
    String username,
    String password,
  ) async {
    final body = await _send(
      'POST',
      path,
      body: {'username': username, 'password': password},
    );
    return (
      token: body['token']! as String,
      username: body['username']! as String,
    );
  }

  Future<void> logout(String token) => _send('POST', 'logout', token: token);

  /// Falla con 401 si el token ya no vale: la sesion no es valida.
  Future<String> me(String token) async =>
      (await _send('GET', 'me', token: token))['username']! as String;

  Future<Friends> friends(String token) async =>
      Friends.fromJson(await _send('GET', 'friends', token: token));

  Future<void> requestFriend(String token, String username) => _send(
    'POST',
    'friends/request',
    token: token,
    body: {'username': username},
  );

  Future<void> acceptFriend(String token, String username) => _send(
    'POST',
    'friends/accept',
    token: token,
    body: {'username': username},
  );

  /// Quita un amigo, cancela una solicitud enviada o rechaza una recibida.
  Future<void> removeFriend(String token, String username) =>
      _send('DELETE', 'friends/${Uri.encodeComponent(username)}', token: token);

  Future<Map<String, Object?>> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, baseUrl.resolve(path));
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(_timeout),
      );
    } on Exception {
      throw const CommunityException(
        'No se pudo conectar con el servidor de comunidad.',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final json = decoded as Map<String, Object?>;
    if (response.statusCode >= 400) {
      throw CommunityException(
        json['error'] as String? ?? 'Error ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return json;
  }
}
