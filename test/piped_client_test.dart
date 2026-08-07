import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuvtune/core/network/piped_client.dart';

void main() {
  group('PipedClient.searchMusicVideo', () {
    test('busca el video oficial en YouTube y deduplica IDs', () async {
      late Uri requestedUri;
      final httpClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response('''
          {"videoRenderer":{"videoId":"AbCdEf123_-"}}
          {"watchEndpoint":{"videoId":"AbCdEf123_-"}}
          {"videoRenderer":{"videoId":"ZyXwVu987_-"}}
          ''', 200);
      });
      final client = PipedClient(httpClient: httpClient, instances: const []);

      final result = await client.searchMusicVideo('Artista Cancion');

      expect(result, 'AbCdEf123_-');
      expect(requestedUri.host, 'www.youtube.com');
      expect(
        requestedUri.queryParameters['search_query'],
        'Artista Cancion official music video',
      );
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
  });
}
