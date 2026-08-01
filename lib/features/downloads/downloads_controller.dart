import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';

/// Canciones descargadas, mas recientes primero.
final downloadedSongsProvider = StreamProvider<List<DownloadedSong>>(
  (ref) => ref.watch(downloadRepositoryProvider).watchDownloads(),
);

/// Progreso (0-100) de las descargas en curso, por videoId de Piped.
final downloadsControllerProvider =
    NotifierProvider<DownloadsController, Map<String, int>>(
  DownloadsController.new,
);

class DownloadsController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  bool isDownloading(String videoId) => state.containsKey(videoId);

  Future<void> startDownload(
    String videoId, {
    required String title,
    required String artist,
    String? album,
  }) async {
    if (isDownloading(videoId)) return;
    state = {...state, videoId: 0};
    try {
      await ref.read(downloadRepositoryProvider).downloadFromVideoId(
            videoId,
            title: title,
            artist: artist,
            album: album,
            onProgress: (percent) {
              if (!state.containsKey(videoId)) return;
              state = {...state, videoId: percent};
            },
          );
    } finally {
      final next = {...state}..remove(videoId);
      state = next;
    }
  }
}
