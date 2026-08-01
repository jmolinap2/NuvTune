import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/player/player_controller.dart';

/// Solo (artista, titulo): sirve para que el provider de mas abajo no vuelva
/// a pedir el video cuando cambia otra parte del estado de reproduccion (por
/// ejemplo la cola), ya que los records de Dart comparan por valor.
final _currentSongKeyProvider = Provider<(String, String)?>((ref) {
  return ref.watch(playbackProvider.select((state) {
    final song = state.currentSong;
    return song == null ? null : (song.artist, song.title);
  }));
});

/// Video de fondo para la cancion actual (feature "video de fondo en
/// Wi-Fi"): sólo se resuelve si el ajuste esta activo, hay Wi-Fi (nunca datos
/// moviles) y hay una cancion sonando.
final videoBackgroundIdProvider = FutureProvider<String?>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  if (!settings.videoBackgroundEnabled) return null;

  final isOnWifi = await ref.watch(connectivityIsOnWifiProvider.future);
  if (!isOnWifi) return null;

  final key = ref.watch(_currentSongKeyProvider);
  if (key == null) return null;

  final song = ref.read(playbackProvider).currentSong;
  if (song == null) return null;

  return ref.watch(videoRepositoryProvider).videoIdFor(song);
});
