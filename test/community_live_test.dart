import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/community/community_service.dart';
import 'package:nuvtune/features/community/nostr/nostr_keys.dart';

/// Prueba contra relays publicos reales. Solo corre si se pide:
///   flutter test test/community_live_test.dart --dart-define=NUVTUNE_LIVE=true
void main() {
  const live = bool.fromEnvironment('NUVTUNE_LIVE');

  test('dos personas se hacen amigas por relays reales', () async {
    final ana = NostrKeys.generate();
    final beto = NostrKeys.generate();
    final anaService = CommunityService(ana);
    final betoService = CommunityService(beto);

    await anaService.publishName('Ana prueba');
    await betoService.publishName('Beto prueba');
    await anaService.addFriend(beto.npub);

    // Los relays tardan un instante en indexar.
    await Future<void>.delayed(const Duration(seconds: 2));
    final betoView = await betoService.friends();
    expect(betoView.incoming.single.name, 'Ana prueba');

    await betoService.addFriend(ana.npub);
    await Future<void>.delayed(const Duration(seconds: 2));
    final anaView = await anaService.friends();
    expect(anaView.friends.single.name, 'Beto prueba');
  }, skip: live ? false : 'requiere --dart-define=NUVTUNE_LIVE=true');
}
