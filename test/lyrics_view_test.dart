import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/lyrics/lrc_parser.dart';
import 'package:nuvtune/features/lyrics/lyrics_view.dart';

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
}
