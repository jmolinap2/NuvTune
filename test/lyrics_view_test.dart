import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/lyrics/lrc_parser.dart';
import 'package:nuvtune/features/lyrics/lyrics_view.dart';
import 'package:nuvtune/features/lyrics/lyrics_animation_style.dart';

void main() {
  group('lyricLinePlaybackPositionMs', () {
    test('invierte los desfases usados por activeLineIndex', () {
      final parsed = LrcParser.parse('''
[offset:750]
[00:10.00]Primera linea
''');

      final positionMs = lyricLinePlaybackPositionMs(
        lineTimeMs: parsed.lines.single.timeMs!,
        lrcOffsetMs: parsed.offsetMs,
        userOffsetMs: 1250,
      );

      expect(positionMs, 12000);
      expect(
        LrcParser.activeLineIndex(parsed, positionMs, extraOffsetMs: 1250),
        0,
      );
    });

    test('no solicita posiciones negativas al motor', () {
      expect(
        lyricLinePlaybackPositionMs(
          lineTimeMs: 1000,
          lrcOffsetMs: -1500,
          userOffsetMs: -500,
        ),
        0,
      );
    });
  });

  group('animación sincronizada', () {
    test('los identificadores son estables y el fallback es Suave', () {
      expect(
        LyricsAnimationStyle.byId('karaoke'),
        LyricsAnimationStyle.karaoke,
      );
      expect(LyricsAnimationStyle.byId('pulse'), LyricsAnimationStyle.pulse);
      expect(LyricsAnimationStyle.byId('rise'), LyricsAnimationStyle.rise);
      expect(
        LyricsAnimationStyle.byId('desconocida'),
        LyricsAnimationStyle.soft,
      );
    });

    test(
      'el progreso karaoke se limita entre la línea actual y la siguiente',
      () {
        expect(
          synchronizedLyricProgress(
            positionMs: 9000,
            lineStartMs: 10000,
            nextLineStartMs: 14000,
          ),
          0,
        );
        expect(
          synchronizedLyricProgress(
            positionMs: 12000,
            lineStartMs: 10000,
            nextLineStartMs: 14000,
          ),
          0.5,
        );
        expect(
          synchronizedLyricProgress(
            positionMs: 16000,
            lineStartMs: 10000,
            nextLineStartMs: 14000,
          ),
          1,
        );
      },
    );
  });
}
