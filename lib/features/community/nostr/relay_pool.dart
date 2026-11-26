import 'dart:async';
import 'dart:convert';

import 'package:nuvtune/features/community/community_exception.dart';
import 'package:nuvtune/features/community/nostr/nostr_event.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Relays publicos de Nostr. Solo reenvian mensajes firmados; no hay cuenta ni
/// servidor propio. Se usan varios porque los publicos caen de vez en cuando.
const defaultRelays = [
  'wss://nos.lol',
  'wss://relay.primal.net',
  'wss://relay.damus.io',
  'wss://offchain.pub',
];

/// Habla con varios relays a la vez. Cada operacion abre sus conexiones y las
/// cierra al terminar: la fase actual solo consulta y publica de vez en cuando.
class RelayPool {
  RelayPool({this.relays = defaultRelays});

  final List<String> relays;

  static const _timeout = Duration(seconds: 8);

  /// Eventos que cumplen alguno de [filters], sin repetidos y con firma valida.
  ///
  /// Un relay caido no es un error mientras otro responda; si ninguno lo hace,
  /// se avisa en vez de devolver una lista vacia que parezca "no hay nada".
  Future<List<NostrEvent>> query(List<Map<String, Object?>> filters) async {
    final results = await Future.wait(
      relays.map((url) => _queryRelay(url, filters)),
    );
    final answered = results.whereType<List<NostrEvent>>().toList();
    if (answered.isEmpty) {
      throw const CommunityException(
        'No se pudo conectar con ningún relay de Nostr.',
      );
    }
    final byId = <String, NostrEvent>{};
    for (final event in answered.expand((events) => events)) {
      if (event.isValid) byId[event.id] = event;
    }
    return byId.values.toList();
  }

  /// Publica [event] en todos los relays; basta con que uno lo acepte.
  Future<void> publish(NostrEvent event) async {
    final accepted = await Future.wait(
      relays.map((url) => _publishRelay(url, event)),
    );
    if (!accepted.contains(true)) {
      throw const CommunityException(
        'Ningún relay aceptó el mensaje. Revisa tu conexión.',
      );
    }
  }

  /// `null` si el relay no respondio (caido o sin conexion).
  Future<List<NostrEvent>?> _queryRelay(
    String url,
    List<Map<String, Object?>> filters,
  ) async {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    const subscription = 'nuvtune';
    final events = <NostrEvent>[];
    try {
      await channel.ready.timeout(_timeout);
      channel.sink.add(jsonEncode(['REQ', subscription, ...filters]));
      await for (final raw in channel.stream.timeout(_timeout)) {
        final message = jsonDecode(raw as String) as List;
        if (message.first == 'EVENT' && message[1] == subscription) {
          events.add(NostrEvent.fromJson(message[2] as Map<String, Object?>));
        } else if (message.first == 'EOSE') {
          break;
        }
      }
      return events;
    } on Exception {
      // Relay inalcanzable o lento: lo decide query() con el resto.
      return null;
    } finally {
      unawaited(channel.sink.close());
    }
  }

  Future<bool> _publishRelay(String url, NostrEvent event) async {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    try {
      await channel.ready.timeout(_timeout);
      channel.sink.add(jsonEncode(['EVENT', event.toJson()]));
      await for (final raw in channel.stream.timeout(_timeout)) {
        final message = jsonDecode(raw as String) as List;
        if (message.first == 'OK' && message[1] == event.id) {
          return message[2] as bool;
        }
      }
      return false;
    } on Exception {
      return false;
    } finally {
      unawaited(channel.sink.close());
    }
  }
}
