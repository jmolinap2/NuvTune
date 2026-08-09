import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuvtune/core/network/piped_client.dart';

void main() {
  group('PipedClient.searchMusicVideo', () {
    test('extrae candidatos completos de YouTube y deduplica IDs', () async {
      late Uri requestedUri;
      final httpClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response('''
          <script>
          var ytInitialData = {
            "contents": [
              {"videoRenderer": {
                "videoId": "AbCdEf123_-",
                "title": {"runs": [{"text": "Linkin Park - Numb [Official Music Video]"}]},
                "ownerText": {"runs": [{"text": "Linkin Park"}]},
                "lengthText": {"simpleText": "3:07"},
                "viewCountText": {"simpleText": "2,000 views"},
                "ownerBadges": [{"metadataBadgeRenderer": {"style": "BADGE_STYLE_TYPE_VERIFIED", "label": "Verified"}}]
              }},
              {"videoRenderer": {
                "videoId": "ZyXwVu987_-",
                "title": {"simpleText": "Numb cover"},
                "shortBylineText": {"runs": [{"text": "Other"}]},
                "lengthText": {"simpleText": "3:05"}
              }},
              {"videoRenderer": {"videoId": "AbCdEf123_-"}}
            ]
          };
          </script>
          ''', 200);
      });
      final client = PipedClient(httpClient: httpClient, instances: const []);

      final result = await client.searchMusicVideoCandidates(
        'Linkin Park Numb',
      );

      expect(result.map((candidate) => candidate.videoId), [
        'AbCdEf123_-',
        'ZyXwVu987_-',
      ]);
      expect(result.first.title, 'Linkin Park - Numb [Official Music Video]');
      expect(result.first.uploaderName, 'Linkin Park');
      expect(result.first.durationSeconds, 187);
      expect(result.first.views, 2000);
      expect(result.first.uploaderVerified, isTrue);
      expect(requestedUri.host, 'www.youtube.com');
      expect(requestedUri.queryParameters['search_query'], 'Linkin Park Numb');
      client.dispose();
    });

    test('usa Piped como respaldo si YouTube no devuelve videos', () async {
      final requestedHosts = <String>[];
      final httpClient = MockClient((request) async {
        requestedHosts.add(request.url.host);
        if (request.url.host == 'www.youtube.com') {
          return http.Response('<html>sin resultados</html>', 200);
        }
        return http.Response('''
          {"items":[{"url":"/watch?v=Fallback1_-", "title":"Cancion", "uploaderName":"Artista", "duration":180}]}
          ''', 200);
      });
      final client = PipedClient(
        httpClient: httpClient,
        instances: const ['https://piped.test'],
      );

      final result = await client.searchMusicVideo('Artista Cancion');

      expect(result, 'Fallback1_-');
      expect(requestedHosts, ['www.youtube.com', 'piped.test']);
      client.dispose();
    });

    test(
      'expone candidatos deduplicados para recuperar un embed fallido',
      () async {
        final httpClient = MockClient((request) async {
          return http.Response('''
          {"videoRenderer":{"videoId":"FirstId123_"}}
          {"watchEndpoint":{"videoId":"FirstId123_"}}
          {"videoRenderer":{"videoId":"SecondId45_"}}
          {"videoRenderer":{"videoId":"ThirdId678_"}}
        ''', 200);
        });
        final client = PipedClient(httpClient: httpClient, instances: const []);

        final result = await client.searchMusicVideos(
          'Artista Cancion',
          limit: 2,
        );

        expect(result, ['FirstId123_', 'SecondId45_']);
        client.dispose();
      },
    );

    test(
      'conserva verificacion, vistas y categoria en el respaldo Piped',
      () async {
        final httpClient = MockClient((request) async {
          if (request.url.host == 'www.youtube.com') {
            return http.Response('<html>sin resultados</html>', 200);
          }
          return http.Response('''
          {"items":[{
            "url":"/watch?v=Metadata01_",
            "title":"Cancion",
            "uploaderName":"Artista - Topic",
            "duration":180,
            "uploaderVerified":true,
            "views":3456,
            "shortDescription":"Provided to YouTube"
          }]}
        ''', 200);
        });
        final client = PipedClient(
          httpClient: httpClient,
          instances: const ['https://piped.test'],
        );

        final result = await client.searchMusicVideoCandidates(
          'Artista Cancion',
        );

        expect(result.single.uploaderVerified, isTrue);
        expect(result.single.isMusicCategory, isTrue);
        expect(result.single.views, 3456);
        expect(result.single.description, 'Provided to YouTube');
        client.dispose();
      },
    );
  });
}
