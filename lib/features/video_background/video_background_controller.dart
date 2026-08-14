import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/player/player_controller.dart';

/// Pista que se está reproduciendo. Se selecciona por identidad, no por título
/// y artista: dos archivos distintos pueden compartir esos metadatos.
final _currentSongProvider = Provider((ref) {
  return ref.watch(playbackProvider.select((state) => state.currentSong));
});

/// Resultado ligado explícitamente a la pista que lo solicitó.
///
/// Un [FutureProvider] puede conservar su valor anterior mientras resuelve el
/// siguiente. Conservar el identificador evita que la interfaz llegue a montar
/// el video de la canción anterior durante esa pequeña ventana.
class VideoBackgroundCandidate {
  const VideoBackgroundCandidate({required this.songId, required this.videoId});

  final int songId;
  final String? videoId;
}

/// Video de fondo para la cancion actual (feature "video de fondo en
/// Wi-Fi"): sólo se resuelve si el ajuste esta activo, hay Wi-Fi (nunca datos
/// moviles) y hay una cancion sonando.
final videoBackgroundIdProvider = FutureProvider<VideoBackgroundCandidate?>((
  ref,
) async {
  final settings = await ref.watch(settingsProvider.future);
  if (!settings.videoBackgroundEnabled) {
    debugPrint('NuvTuneVideo: desactivado en ajustes');
    return null;
  }

  final isOnWifi = await ref.watch(connectivityIsOnWifiProvider.future);
  if (!isOnWifi) {
    debugPrint('NuvTuneVideo: sin Wi-Fi');
    return null;
  }

  final song = ref.watch(_currentSongProvider);
  if (song == null) {
    debugPrint('NuvTuneVideo: sin canción activa');
    return null;
  }

  final videoId = await ref.watch(videoRepositoryProvider).videoIdFor(song);
  debugPrint(
    videoId == null
        ? 'NuvTuneVideo: no se encontró candidato'
        : 'NuvTuneVideo: candidato resuelto',
  );
  return VideoBackgroundCandidate(songId: song.id, videoId: videoId);
});
