import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nuvtune/features/community/nostr/nostr_keys.dart';

/// Evento de Nostr (NIP-01): un mensaje firmado por su autor.
class NostrEvent {
  const NostrEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  factory NostrEvent.fromJson(Map<String, Object?> json) => NostrEvent(
    id: json['id']! as String,
    pubkey: json['pubkey']! as String,
    createdAt: json['created_at']! as int,
    kind: json['kind']! as int,
    tags: [
      for (final tag in json['tags']! as List) List<String>.from(tag as List),
    ],
    content: json['content']! as String,
    sig: json['sig']! as String,
  );

  /// Crea y firma un evento con [keys].
  factory NostrEvent.create(
    NostrKeys keys, {
    required int kind,
    required String content,
    List<List<String>> tags = const [],
  }) {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = computeId(keys.publicHex, createdAt, kind, tags, content);
    return NostrEvent(
      id: id,
      pubkey: keys.publicHex,
      createdAt: createdAt,
      kind: kind,
      tags: tags,
      content: content,
      sig: keys.sign(id),
    );
  }

  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String sig;

  /// Primer valor de la etiqueta [name], o `null` si no esta.
  String? tag(String name) {
    for (final tag in tags) {
      if (tag.length > 1 && tag.first == name) return tag[1];
    }
    return null;
  }

  /// El id es el SHA-256 de la serializacion canonica del NIP-01.
  static String computeId(
    String pubkey,
    int createdAt,
    int kind,
    List<List<String>> tags,
    String content,
  ) => sha256
      .convert(
        utf8.encode(jsonEncode([0, pubkey, createdAt, kind, tags, content])),
      )
      .toString();

  /// Un evento ajeno solo se acepta si su id y su firma son correctos.
  bool get isValid =>
      id == computeId(pubkey, createdAt, kind, tags, content) &&
      NostrKeys.verify(pubkey, id, sig);

  Map<String, Object?> toJson() => {
    'id': id,
    'pubkey': pubkey,
    'created_at': createdAt,
    'kind': kind,
    'tags': tags,
    'content': content,
    'sig': sig,
  };
}
