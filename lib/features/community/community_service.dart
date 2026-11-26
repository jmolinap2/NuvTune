import 'dart:convert';

import 'package:nuvtune/features/community/community_exception.dart';
import 'package:nuvtune/features/community/nostr/nostr_event.dart';
import 'package:nuvtune/features/community/nostr/nostr_keys.dart';
import 'package:nuvtune/features/community/nostr/relay_pool.dart';

class Friend {
  const Friend({required this.pubkey, required this.name});

  final String pubkey;

  /// Nombre publicado por esa persona; `null` si aun no lo ha publicado.
  final String? name;

  String get npub => encodeBech32('npub', pubkey);

  /// Lo que se muestra: su nombre, o el inicio de su codigo si no tiene.
  String get label => name ?? '${npub.substring(0, 12)}…';
}

class Friends {
  const Friends({
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  final List<Friend> friends;

  /// Quienes te agregaron y esperan que respondas.
  final List<Friend> incoming;

  /// A quienes agregaste y todavia no te agregaron.
  final List<Friend> outgoing;
}

/// Identidad y amistades sobre Nostr, sin servidor propio.
///
/// Cada persona publica un registro por cada contacto (evento 30078, de tipo
/// "reemplazable"): su contenido es `add` o `remove`. Dos personas son amigas
/// cuando cada una tiene un `add` hacia la otra; ese consentimiento mutuo es
/// el que habilitara compartir musica en las fases siguientes.
class CommunityService {
  CommunityService(this._keys, {RelayPool? pool}) : _pool = pool ?? RelayPool();

  final NostrKeys _keys;
  final RelayPool _pool;

  static const _profileKind = 0;
  static const _friendKind = 30078;
  static const _friendTag = 'nuvtune-friend';

  Future<void> publishName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 30) {
      throw const CommunityException(
        'El nombre debe tener de 2 a 30 caracteres.',
      );
    }
    return _pool.publish(
      NostrEvent.create(
        _keys,
        kind: _profileKind,
        content: jsonEncode({'name': trimmed}),
      ),
    );
  }

  Future<String?> myName() async =>
      (await _names([_keys.publicHex]))[_keys.publicHex];

  Future<void> addFriend(String code) {
    final pubkey = parsePublicKey(code);
    if (pubkey == _keys.publicHex) {
      throw const CommunityException('No puedes agregarte a ti mismo.');
    }
    return _setRelation(pubkey, 'add');
  }

  Future<void> removeFriend(String pubkey) => _setRelation(pubkey, 'remove');

  Future<void> _setRelation(String pubkey, String state) => _pool.publish(
    NostrEvent.create(
      _keys,
      kind: _friendKind,
      content: state,
      tags: [
        ['d', '$_friendTag:$pubkey'],
        ['p', pubkey],
        ['t', _friendTag],
      ],
    ),
  );

  Future<Friends> friends() async {
    final events = await _pool.query([
      {
        'kinds': [_friendKind],
        '#t': [_friendTag],
        'authors': [_keys.publicHex],
      },
      {
        'kinds': [_friendKind],
        '#t': [_friendTag],
        '#p': [_keys.publicHex],
      },
    ]);

    // Un registro por (autor, destinatario): vale el mas reciente.
    final latest = <(String, String), NostrEvent>{};
    for (final event in events) {
      final target = event.tag('p');
      if (target == null) continue;
      final key = (event.pubkey, target);
      final current = latest[key];
      if (current == null || event.createdAt > current.createdAt) {
        latest[key] = event;
      }
    }
    bool added(String from, String to) => latest[(from, to)]?.content == 'add';

    final me = _keys.publicHex;
    final others = {
      for (final (from, to) in latest.keys) from == me ? to : from,
    };
    final friends = <String>[];
    final incoming = <String>[];
    final outgoing = <String>[];
    for (final other in others) {
      final mine = added(me, other);
      final theirs = added(other, me);
      if (mine && theirs) {
        friends.add(other);
      } else if (mine) {
        outgoing.add(other);
      } else if (theirs) {
        incoming.add(other);
      }
    }

    final names = await _names(others.toList());
    List<Friend> build(List<String> keys) => [
      for (final key in keys) Friend(pubkey: key, name: names[key]),
    ];
    return Friends(
      friends: build(friends),
      incoming: build(incoming),
      outgoing: build(outgoing),
    );
  }

  Future<Map<String, String>> _names(List<String> pubkeys) async {
    if (pubkeys.isEmpty) return const {};
    final events = await _pool.query([
      {
        'kinds': [_profileKind],
        'authors': pubkeys,
      },
    ]);
    final latest = <String, NostrEvent>{};
    for (final event in events) {
      final current = latest[event.pubkey];
      if (current == null || event.createdAt > current.createdAt) {
        latest[event.pubkey] = event;
      }
    }
    return {
      for (final event in latest.values)
        if (_nameOf(event) case final String name) event.pubkey: name,
    };
  }

  /// El perfil lo escribe un tercero: si no es el JSON esperado, se ignora.
  static String? _nameOf(NostrEvent event) {
    final Object? decoded;
    try {
      decoded = jsonDecode(event.content);
    } on FormatException {
      return null;
    }
    return decoded is Map && decoded['name'] is String
        ? decoded['name'] as String
        : null;
  }
}
