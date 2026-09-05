import 'package:http/http.dart' as http;
import 'package:nuvtune/features/metadata_editor/cover_picker.dart';

/// Cliente minimo de Cover Art Archive (https://coverartarchive.org), que
/// aloja las portadas asociadas a un lanzamiento (release) de MusicBrainz. Sin
/// API key.
///
/// Que un lanzamiento no tenga portada subida es normal, no una falla: un 404
/// se traduce en `null` para que la pantalla lo muestre como "sin portada"
/// para esa cancion, igual que una busqueda sin coincidencia.
class CoverArtArchiveClient {
  CoverArtArchiveClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _timeout = Duration(seconds: 10);
  static const _userAgent = 'NuvTune/1.0 (reproductor de musica personal)';

  /// Portada frontal del lanzamiento. `front-1200` iguala en resolucion al
  /// recorte manual de 1000px del editor de portadas.
  Future<PickedCover?> frontCoverOf(String releaseId) async {
    final uri = Uri.parse(
      'https://coverartarchive.org/release/$releaseId/front-1200',
    );
    try {
      final response = await _http
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      final mimeType = response.headers['content-type']
          ?.split(';')
          .first
          .trim();
      return PickedCover(
        bytes: response.bodyBytes,
        mimeType: (mimeType == null || mimeType.isEmpty)
            ? 'image/jpeg'
            : mimeType,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() => _http.close();
}
