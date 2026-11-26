import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/community/community_exception.dart';
import 'package:nuvtune/features/community/community_service.dart';
import 'package:nuvtune/features/community/nostr/nostr_event.dart';
import 'package:nuvtune/features/community/nostr/nostr_keys.dart';
import 'package:nuvtune/features/community/nostr/relay_pool.dart';

/// Relay en memoria: guarda lo publicado y lo devuelve segun el filtro.
class _FakePool extends RelayPool {
  final List<NostrEvent> stored;
  _FakePool(this.stored) : super(relays: const []);

  @override
  Future<void> publish(NostrEvent event) async => stored.add(event);

  @override
  Future<List<NostrEvent>> query(List<Map<String, Object?>> filters) async => [
    for (final event in stored)
      if (filters.any((filter) => _matches(filter, event))) event,
  ];

  static bool _matches(Map<String, Object?> filter, NostrEvent event) {
    final kinds = filter['kinds'] as List?;
    final authors = filter['authors'] as List?;
    final p = filter['#p'] as List?;
    final t = filter['#t'] as List?;
    return (kinds == null || kinds.contains(event.kind)) &&
        (authors == null || authors.contains(event.pubkey)) &&
        (p == null || p.contains(event.tag('p'))) &&
        (t == null || t.contains(event.tag('t')));
  }
}

void main() {
  group('NIP-19', () {
    // Vector del NIP-19.
    const hex =
        '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e';
    const npub =
        'npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg';

    test('npub <-> hex coincide con el vector oficial', () {
      expect(encodeBech32('npub', hex), npub);
      expect(parsePublicKey(npub), hex);
    });

    test('un codigo con un caracter cambiado se rechaza', () {
      final broken = '${npub.substring(0, npub.length - 1)}q';
      expect(() => parsePublicKey(broken), throwsA(isA<CommunityException>()));
    });

    test('nsec ida y vuelta conserva la clave', () {
      final keys = NostrKeys.generate();
      expect(NostrKeys.parseSecret(keys.nsec).publicHex, keys.publicHex);
    });
  });

  group('eventos', () {
    test('un evento firmado es valido y uno alterado no', () {
      final keys = NostrKeys.generate();
      final event = NostrEvent.create(keys, kind: 1, content: 'hola');
      expect(event.isValid, isTrue);

      final forged = NostrEvent(
        id: event.id,
        pubkey: event.pubkey,
        createdAt: event.createdAt,
        kind: event.kind,
        tags: event.tags,
        content: 'otra cosa',
        sig: event.sig,
      );
      expect(forged.isValid, isFalse);
    });
  });

  group('amistades', () {
    test('solo hay amistad cuando ambas personas se agregaron', () async {
      final store = <NostrEvent>[];
      final ana = NostrKeys.generate();
      final beto = NostrKeys.generate();
      final anaService = CommunityService(ana, pool: _FakePool(store));
      final betoService = CommunityService(beto, pool: _FakePool(store));
      await anaService.publishName('Ana');

      await anaService.addFriend(beto.npub);
      var anaView = await anaService.friends();
      expect(anaView.outgoing.map((f) => f.pubkey), [beto.publicHex]);
      expect(anaView.friends, isEmpty);
      var betoView = await betoService.friends();
      expect(betoView.incoming.single.name, 'Ana');

      await betoService.addFriend(ana.npub);
      anaView = await anaService.friends();
      expect(anaView.friends.single.pubkey, beto.publicHex);
      expect(anaView.outgoing, isEmpty);

      // Quitar a alguien (el registro mas reciente manda).
      await Future<void>.delayed(const Duration(seconds: 1));
      await anaService.removeFriend(beto.publicHex);
      anaView = await anaService.friends();
      expect(anaView.friends, isEmpty);
      betoView = await betoService.friends();
      expect(betoView.outgoing.single.pubkey, ana.publicHex);
    });

    test('no puedes agregarte a ti mismo', () {
      final keys = NostrKeys.generate();
      final service = CommunityService(keys, pool: _FakePool([]));
      expect(
        () => service.addFriend(keys.npub),
        throwsA(isA<CommunityException>()),
      );
    });
  });
}
