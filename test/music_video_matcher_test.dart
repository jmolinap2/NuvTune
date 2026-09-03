import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/video_background/music_video_matcher.dart';

void main() {
  const matcher = MusicVideoMatcher();
  const numb = MusicVideoSongMetadata(
    title: 'Numb',
    artist: 'Linkin Park',
    album: 'Meteora',
    durationSeconds: 185,
  );

  group('MusicVideoMatcher', () {
    test('prioriza el canal oficial sobre un cover mucho mas popular', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Cover000001',
          title: 'Numb - Linkin Park Cover',
          uploaderName: 'Popular Covers',
          durationSeconds: 185,
          isMusicCategory: true,
          views: 500000000,
          searchRank: 0,
        ),
        YouTubeCandidate(
          videoId: 'Official001',
          title: 'Linkin Park - Numb [Official Music Video]',
          uploaderName: 'Linkin Park',
          durationSeconds: 187,
          uploaderVerified: true,
          isMusicCategory: true,
          views: 1000,
          searchRank: 1,
        ),
      ]);

      expect(result?.videoId, 'Official001');
      expect(result?.sourceType, MusicVideoSourceType.officialArtistChannel);
      expect(result?.confidence, MusicVideoConfidence.high);
    });

    // La busqueda movil de YouTube no incluye `ownerBadges` en ningun
    // resultado, de modo que exigir la insignia dejaba a todo canal de sello
    // como origen desconocido. El titulo declarando el video como oficial es
    // la evidencia que la sustituye.
    test('reconoce un sello sin insignia cuando el titulo declara oficial', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'FanAnim0001',
          title: 'Numb - Linkin Park (animacion)',
          uploaderName: 'Fan Channel',
          durationSeconds: 185,
          searchRank: 0,
        ),
        YouTubeCandidate(
          videoId: 'LabelOff001',
          title: 'Linkin Park - Numb (Official Video)',
          uploaderName: 'Some Records and Linkin Park',
          durationSeconds: 185,
          views: 23000000,
          searchRank: 1,
        ),
      ]);

      expect(result?.videoId, 'LabelOff001');
      expect(result?.sourceType, MusicVideoSourceType.officialLabel);
    });

    test('acepta «Video Oficial» en espanol como declaracion oficial', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'LabelEs0001',
          title: 'Linkin Park - Numb (Video Oficial)',
          uploaderName: 'Some Records',
          durationSeconds: 185,
          searchRank: 0,
        ),
      ]);

      expect(result?.sourceType, MusicVideoSourceType.officialLabel);
    });

    test('reconoce Artist - Topic como fuente oficial', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Topic000001',
          title: 'Numb',
          uploaderName: 'Linkin Park - Topic',
          durationSeconds: 185,
          uploaderVerified: true,
          isMusicCategory: true,
        ),
      ]);

      expect(result?.sourceType, MusicVideoSourceType.artistTopic);
      expect(result?.confidence, MusicVideoConfidence.high);
    });

    test('reconoce un canal VEVO corroborado por artista', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Vevo0000001',
          title: 'Linkin Park - Numb (Official Video)',
          uploaderName: 'LinkinParkVEVO',
          durationSeconds: 190,
          uploaderVerified: true,
        ),
      ]);

      expect(result?.sourceType, MusicVideoSourceType.artistVevo);
      expect(result?.confidence, MusicVideoConfidence.high);
    });

    test('descarta resultados fuertes no solicitados', () {
      const forbiddenTitles = [
        'Linkin Park - Numb cover',
        'Linkin Park - Numb reaction',
        'Linkin Park - Numb karaoke',
        'Linkin Park - Numb tutorial',
        'Linkin Park - Numb nightcore',
        'Linkin Park - Numb slowed',
        'Linkin Park - Numb sped up',
        'Linkin Park - Numb instrumental',
        'Linkin Park - Numb fan made',
        'Linkin Park - Numb AMV',
      ];

      for (var index = 0; index < forbiddenTitles.length; index++) {
        final result = matcher.selectBestMatch(numb, [
          YouTubeCandidate(
            videoId: 'Bad${index.toString().padLeft(8, '0')}',
            title: forbiddenTitles[index],
            uploaderName: 'Unknown channel',
            durationSeconds: 185,
            isMusicCategory: true,
          ),
        ]);
        expect(result, isNull, reason: forbiddenTitles[index]);
      }
    });

    test('permite una version live cuando forma parte de lo solicitado', () {
      const liveSong = MusicVideoSongMetadata(
        title: 'Numb (Live)',
        artist: 'Linkin Park',
        album: 'Live in Texas',
        durationSeconds: 190,
      );
      final result = matcher.selectBestMatch(liveSong, const [
        YouTubeCandidate(
          videoId: 'Live0000001',
          title: 'Linkin Park - Numb (Live)',
          uploaderName: 'Linkin Park',
          durationSeconds: 190,
          uploaderVerified: true,
          isMusicCategory: true,
        ),
      ]);

      expect(result?.videoId, 'Live0000001');
      expect(result?.confidence, MusicVideoConfidence.high);
    });

    test('no confunde una palabra del titulo con una variante', () {
      const song = MusicVideoSongMetadata(
        title: 'Piano Man',
        artist: 'Billy Joel',
        durationSeconds: 336,
      );
      final result = matcher.selectBestMatch(song, const [
        YouTubeCandidate(
          videoId: 'PianoMan001',
          title: 'Billy Joel - Piano Man (Official Video)',
          uploaderName: 'Billy Joel',
          durationSeconds: 340,
          uploaderVerified: true,
          isMusicCategory: true,
        ),
      ]);

      expect(result?.videoId, 'PianoMan001');
    });

    test('usa duracion antes que popularidad al desempatar', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Popular0001',
          title: 'Linkin Park - Numb',
          uploaderName: 'Music Channel',
          durationSeconds: 215,
          isMusicCategory: true,
          views: 900000000,
        ),
        YouTubeCandidate(
          videoId: 'Duration001',
          title: 'Linkin Park - Numb',
          uploaderName: 'Music Channel',
          durationSeconds: 187,
          isMusicCategory: true,
          views: 10,
        ),
      ]);

      expect(result?.videoId, 'Duration001');
    });

    test('popularidad solo desempata candidatos equivalentes', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'LessViews01',
          title: 'Linkin Park - Numb',
          uploaderName: 'Music Channel',
          durationSeconds: 185,
          isMusicCategory: true,
          views: 100,
          searchRank: 0,
        ),
        YouTubeCandidate(
          videoId: 'MoreViews01',
          title: 'Linkin Park - Numb',
          uploaderName: 'Music Channel',
          durationSeconds: 185,
          isMusicCategory: true,
          views: 200,
          searchRank: 1,
        ),
      ]);

      expect(result?.videoId, 'MoreViews01');
    });

    test('devuelve niveles Medium y Low de forma explicita', () {
      final medium = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Medium00001',
          title: 'Linkin Park - Numb',
          uploaderName: 'Independent Music Channel',
          durationSeconds: 185,
          isMusicCategory: true,
        ),
      ]);
      final low = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Low00000001',
          title: 'Linkin Park - Numb',
          uploaderName: 'Unknown Channel',
          durationSeconds: 185,
        ),
      ]);

      expect(medium?.confidence, MusicVideoConfidence.medium);
      expect(low?.confidence, MusicVideoConfidence.low);
    });

    test('acepta introduccion larga de un videoclip oficial confirmado', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'LongIntro01',
          title: 'Linkin Park - Numb [Official Music Video]',
          uploaderName: 'Linkin Park',
          durationSeconds: 240,
          uploaderVerified: true,
        ),
      ]);

      expect(result?.videoId, 'LongIntro01');
      expect(result?.confidence, MusicVideoConfidence.high);
    });

    test('devuelve NoOfficialMatchFound ante coincidencia parcial', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'WrongSong01',
          title: 'Linkin Park - Somewhere I Belong',
          uploaderName: 'Linkin Park',
          durationSeconds: 185,
          uploaderVerified: true,
          isMusicCategory: true,
          views: 1000000000,
        ),
      ]);

      expect(result, isNull);
    });

    test('mantiene seleccion determinista con empate completo', () {
      final result = matcher.selectBestMatch(numb, const [
        YouTubeCandidate(
          videoId: 'Zzzzzzzzzzz',
          title: 'Linkin Park - Numb',
          uploaderName: 'Music Channel',
          durationSeconds: 185,
          isMusicCategory: true,
          searchRank: 0,
        ),
        YouTubeCandidate(
          videoId: 'Aaaaaaaaaaa',
          title: 'Linkin Park - Numb',
          uploaderName: 'Music Channel',
          durationSeconds: 185,
          isMusicCategory: true,
          searchRank: 0,
        ),
      ]);

      expect(result?.videoId, 'Aaaaaaaaaaa');
    });
  });
}
