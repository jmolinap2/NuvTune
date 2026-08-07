// Contrato tipado entre Flutter y el motor de descarga nativo.
// Regenerar con:
//   dart pub global run pigeon --input pigeons/download_engine.dart
//
// Motor heredado de C:\Repos\NuvClip (youtubedl-android + ffmpeg nativo): a
// diferencia del cliente Piped que tenia NuvTune antes, este SI descarga de
// forma confiable y es multi-plataforma. La unica adicion sobre el contrato
// original de NuvClip es `search`: NuvClip solo acepta un enlace pegado,
// pero un regalo de NuvTune solo trae texto (titulo/artista), nunca un
// enlace, asi que hace falta buscar antes de poder analizar.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/platform/download_engine.g.dart',
    kotlinOut:
        'android/music_engine/src/main/kotlin/com/nuvtune/engine/downloader/DownloadEngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.nuvtune.engine.downloader'),
    dartPackageName: 'nuvtune',
  ),
)
enum SourcePlatform { tiktok, instagram, facebook, youtube, unknown }

/// Clasificacion tecnica del fallo. El mensaje exacto que ve el usuario vive
/// en Dart, no aqui: Kotlin solo diagnostica, no redacta copy de UI.
enum DownloadErrorCode {
  unsupportedLink,
  privateContent,
  contentRemoved,
  regionRestricted,
  fetchFailed,
  extractorOutdated,
  insufficientStorage,
  cancelled,
  networkLost,

  /// El ajuste "Solo con Wi-Fi" esta activo y no hay una red Wi-Fi disponible
  /// al momento de iniciar la descarga.
  wifiRequired,
  unknown,
}

class VideoFormatOption {
  late String formatId;

  /// Ya resuelto por Kotlin a partir de la altura/codec ("1080p", "720p").
  late String qualityLabel;
  late String fileExtension;
  int? height;
  int? approxSizeBytes;
}

class VideoAnalysis {
  late String sourceUrl;
  late SourcePlatform platform;
  late String title;
  String? author;
  String? thumbnailUrl;
  late int durationSeconds;
  late List<VideoFormatOption> formats;

  /// Calidades de solo-audio (extraccion con ffmpeg), separadas de [formats]
  /// porque no tienen altura y son las unicas relevantes para NuvTune (todo
  /// lo que entra a la biblioteca de musica es audio).
  late List<VideoFormatOption> audioFormats;
}

/// Union por nulabilidad: si [errorCode] es nulo, [video] esta presente y la
/// operacion tuvo exito; si no, [video] es nulo.
class AnalysisResult {
  VideoAnalysis? video;
  DownloadErrorCode? errorCode;

  /// Texto tecnico crudo (stderr de yt-dlp) solo para diagnostico local;
  /// nunca se muestra al usuario tal cual.
  String? errorDetail;
}

/// Un resultado de busqueda por texto: mas liviano que [VideoAnalysis]
/// porque `ytsearchN:` no trae la lista de formatos de cada entrada, solo su
/// metadata. Para descargar hace falta un paso extra: `analyzeUrl(sourceUrl)`
/// sobre el resultado elegido, igual que si el usuario hubiera pegado ese
/// enlace directamente.
class SearchResultItem {
  late String sourceUrl;
  late String title;
  String? author;
  String? thumbnailUrl;
  late int durationSeconds;
}

class DownloadRequest {
  /// Generado en Dart antes de llamar a `startDownload`, no por Kotlin: la
  /// fila de historial y la notificacion en primer plano necesitan un id
  /// estable desde antes de que exista ninguna respuesta nativa.
  late String downloadId;
  late String sourceUrl;
  late SourcePlatform platform;
  late String formatId;
  late String suggestedFileName;
  late bool wifiOnly;

  /// Siempre true en NuvTune: solo se descarga audio (yt-dlp -x + ffmpeg).
  /// Se conserva el campo (en vez de eliminarlo) para no divergir del
  /// contrato de NuvClip mas de lo necesario.
  late bool audioOnly;

  /// Tamaño aproximado que ya se conocia desde el analisis, para que el
  /// progreso pueda mostrar MB descargados sin que Kotlin tenga que inferirlo.
  int? approxTotalBytes;

  /// Metadatos para la cancion resultante (titulo/artista/album del regalo o
  /// de la busqueda), usados al escribirla en MediaStore.Audio para que el
  /// escaneo de biblioteca la reconozca con la informacion correcta en vez de
  /// solo el titulo del video.
  String? songTitle;
  String? songArtist;
  String? songAlbum;
}

class ExtractorUpdateResult {
  /// true = se actualizo a una version nueva; false = ya estaba al dia.
  late bool updated;
  String? versionName;
}

@HostApi()
abstract class DownloadEngineHostApi {
  /// Inicializa yt-dlp y ffmpeg. Debe llamarse una sola vez por proceso,
  /// antes de cualquier otro metodo; es costosa (extrae binarios la primera
  /// vez) por lo que se ejecuta en el arranque de la app, sin bloquearlo.
  @async
  void initialize();

  /// Busca por texto libre (p. ej. "titulo artista"). Antepone `ytsearchN:`
  /// internamente; no pasa por el filtro de dominios permitidos porque no es
  /// un enlace. El resultado elegido se analiza despues con [analyzeUrl].
  @async
  List<SearchResultItem> search(String query, int limit);

  @async
  AnalysisResult analyzeUrl(String url);

  /// No bloquea: encola la descarga en el servicio en primer plano y
  /// retorna. El resultado llega despues por
  /// onDownloadCompleted/onDownloadFailed.
  void startDownload(DownloadRequest request);

  void cancelDownload(String downloadId);

  @async
  ExtractorUpdateResult updateExtractor();

  String? currentExtractorVersion();
}

@FlutterApi()
abstract class DownloadEngineFlutterApi {
  void onDownloadProgress(
    String downloadId,
    double percent,
    int? etaSeconds,
    int downloadedBytes,
    int? totalBytes,
  );

  void onDownloadCompleted(
    String downloadId,
    String savedUri,
    String fileName,
    int sizeBytes,
  );

  void onDownloadFailed(
    String downloadId,
    DownloadErrorCode errorCode,
    String? errorDetail,
  );
}
