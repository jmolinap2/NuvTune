import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/video_background/music_video_background.dart';

void main() {
  group('MusicVideoBackgroundState.youtubeError', () {
    const expectedFailures = <int, MusicVideoBackgroundFailure>{
      2: MusicVideoBackgroundFailure.youtubeInvalidParameter,
      5: MusicVideoBackgroundFailure.youtubeHtml5Player,
      100: MusicVideoBackgroundFailure.youtubeVideoNotFound,
      101: MusicVideoBackgroundFailure.youtubeEmbeddingDisabled,
      150: MusicVideoBackgroundFailure.youtubeEmbeddingDisabled,
      153: MusicVideoBackgroundFailure.youtubeMissingClientIdentity,
    };

    for (final entry in expectedFailures.entries) {
      test('clasifica el codigo ${entry.key}', () {
        final state = MusicVideoBackgroundState.youtubeError(entry.key);

        expect(state.phase, MusicVideoBackgroundPhase.error);
        expect(state.failure, entry.value);
        expect(state.youtubeErrorCode, entry.key);
      });
    }

    test('conserva un codigo desconocido sin exponer otros datos', () {
      final state = MusicVideoBackgroundState.youtubeError(999);

      expect(state.failure, MusicVideoBackgroundFailure.youtubeUnknown);
      expect(state.youtubeErrorCode, 999);
    });
  });

  test('los estados de carga y listo son valores comparables', () {
    expect(
      const MusicVideoBackgroundState.loading(),
      const MusicVideoBackgroundState.loading(),
    );
    expect(
      const MusicVideoBackgroundState.ready(),
      const MusicVideoBackgroundState.ready(),
    );
    expect(
      const MusicVideoBackgroundState.loading(),
      isNot(const MusicVideoBackgroundState.ready()),
    );
  });

  group('MusicVideoTimeline', () {
    test('salta una intro cinematográfica detectada por duración', () {
      expect(
        MusicVideoTimeline.positionMs(
          audioPositionMs: 0,
          audioDurationMs: 180000,
          videoDurationMs: 192000,
        ),
        12000,
      );
      expect(
        MusicVideoTimeline.positionMs(
          audioPositionMs: 90000,
          audioDurationMs: 180000,
          videoDurationMs: 192000,
        ),
        102000,
      );
    });

    test(
      'mantiene el tiempo directo cuando la diferencia no es significativa',
      () {
        expect(
          MusicVideoTimeline.positionMs(
            audioPositionMs: 60000,
            audioDurationMs: 180000,
            videoDurationMs: 182000,
          ),
          60667,
        );
      },
    );

    test('no intenta buscar fuera de la duración disponible', () {
      expect(
        MusicVideoTimeline.positionMs(
          audioPositionMs: 240000,
          audioDurationMs: 180000,
          videoDurationMs: 180000,
        ),
        179750,
      );
    });
  });

  group('MusicVideoSyncClock', () {
    test('extrapola el tiempo entre muestras mientras se reproduce', () {
      expect(
        MusicVideoSyncClock.extrapolatedPositionMs(
          anchorPositionMs: 30000,
          anchorElapsedMs: 1000,
          nowElapsedMs: 1500,
          isPlaying: true,
          durationMs: 180000,
        ),
        30500,
      );
    });

    test('no avanza durante la pausa ni supera la duración', () {
      expect(
        MusicVideoSyncClock.extrapolatedPositionMs(
          anchorPositionMs: 30000,
          anchorElapsedMs: 1000,
          nowElapsedMs: 9000,
          isPlaying: false,
          durationMs: 180000,
        ),
        30000,
      );
      expect(
        MusicVideoSyncClock.extrapolatedPositionMs(
          anchorPositionMs: 179800,
          anchorElapsedMs: 1000,
          nowElapsedMs: 1500,
          isPlaying: true,
          durationMs: 180000,
        ),
        180000,
      );
    });

    test('distingue un salto manual del avance normal', () {
      expect(
        MusicVideoSyncClock.isDiscontinuity(
          expectedPositionMs: 30500,
          reportedPositionMs: 30600,
        ),
        isFalse,
      );
      expect(
        MusicVideoSyncClock.isDiscontinuity(
          expectedPositionMs: 30500,
          reportedPositionMs: 60000,
        ),
        isTrue,
      );
    });
  });

  test('cover llena el viewport sin el zoom fijo histórico', () {
    final css = musicVideoPlayerCss(MusicVideoFit.cover);

    expect(css, contains('177.77777778vh'));
    expect(css, contains('min-width: 100vw'));
    expect(css, isNot(contains('scale(1.6)')));
  });
}
