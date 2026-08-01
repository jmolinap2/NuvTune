// Contrato tipado entre Flutter y el motor Android (requerimiento seccion 15).
// Regenerar con:
//   pigeon --input pigeons/music_engine.dart
//
// Cubre Fase 1 y Fase 2 del plan de fases. Los metodos de mejora perceptual
// avanzada (setAudioProfile / setAudioEnhancement) pertenecen a Fase 3 y no
// forman parte de este contrato todavia.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/platform/music_engine.g.dart',
    kotlinOut:
        'android/music_engine/src/main/kotlin/com/nuvtune/engine/MusicEngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.nuvtune.engine'),
    dartPackageName: 'nuvtune',
  ),
)
// ---------------------------------------------------------------------------
// Enumeraciones
// ---------------------------------------------------------------------------

enum RepeatMode { off, one, all }

enum ProcessingState { idle, buffering, ready, ended }

/// Salidas de audio reconocidas (requerimiento 5.4).
enum AudioOutput { speaker, wiredHeadphones, bluetooth, androidAuto, usbDac }

/// Resultado de una operacion de escritura sobre un archivo de audio.
enum WriteOutcome {
  /// Los cambios se escribieron y el original fue sustituido de forma atomica.
  success,

  /// El sistema requiere confirmacion del usuario; ya se le mostro el dialogo
  /// y hay que reintentar la operacion cuando `permissionGranted` sea true.
  needsUserConsent,

  /// El usuario rechazo la confirmacion del sistema.
  deniedByUser,

  /// El formato del archivo no admite escritura de etiquetas.
  unsupportedFormat,

  /// La verificacion de integridad posterior a la escritura fallo y se
  /// restauro el archivo original.
  integrityCheckFailed,
}

// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------

/// Cancion tal como la expone MediaStore, enriquecida por el motor.
class Song {
  late int id;
  late String uri;
  late String filePath;
  late String title;
  late String artist;
  late int artistId;
  late String album;
  late int albumId;
  String? albumArtist;
  String? genre;
  String? composer;
  int? year;
  int? trackNumber;
  int? discNumber;
  late int durationMs;
  late String mimeType;
  late int sizeBytes;

  /// Segundos epoch (MediaStore.DATE_ADDED).
  late int dateAdded;

  /// Segundos epoch (MediaStore.DATE_MODIFIED).
  late int dateModified;
  late String folderPath;
  late String folderName;

  /// El motor pudo resolver una miniatura para esta cancion.
  late bool hasCover;

  /// El dispositivo puede decodificar este formato.
  late bool isSupported;
}

/// Informacion tecnica del archivo (requerimiento 4.2).
class TechnicalInfo {
  late int songId;
  late String filePath;
  late String mimeType;
  late String container;
  late String codec;
  late int durationMs;
  late int sizeBytes;
  int? bitrateBps;
  int? sampleRateHz;
  int? bitsPerSample;
  int? channels;
  late bool isSupported;
  String? unsupportedReason;
}

/// Estado completo de reproduccion. Se envia en `playbackStateChanged`.
class PlaybackSnapshot {
  late bool isPlaying;
  late ProcessingState processingState;
  late int positionMs;
  late int durationMs;
  late int bufferedMs;

  /// Indice dentro de la cola; -1 si no hay nada cargado.
  late int currentIndex;
  int? currentSongId;
  late bool shuffleEnabled;
  late RepeatMode repeatMode;
  late double speed;
  late double pitch;

  /// Milisegundos restantes del temporizador de apagado; null si esta apagado.
  int? sleepTimerRemainingMs;
}

/// Resumen ligero de la senal PCM para animar la interfaz sin enviar audio
/// crudo fuera del motor. Todos los valores estan normalizados entre 0 y 1.
class AudioAnalysisFrame {
  late double level;
  late double bass;
  late double mid;
  late double treble;

  /// Pulso corto detectado principalmente a partir de transitorios graves.
  late double beat;
}

/// Etiquetas a escribir. Un campo null significa "no modificar"; una cadena
/// vacia significa "borrar el valor" (requerimiento 7.1).
class MetadataEdit {
  late int songId;
  String? title;
  String? artist;
  String? albumArtist;
  String? album;
  String? genre;
  String? year;
  String? trackNumber;
  String? discNumber;
  String? composer;
  String? comment;
  String? lyrics;
}

class WriteResult {
  late WriteOutcome outcome;
  late int songId;
  String? message;

  /// Solo relevante cuando `outcome` es `needsUserConsent`: indica si el
  /// usuario ya concedio el permiso y la operacion puede reintentarse.
  late bool permissionGranted;
}

/// Ajustes del ecualizador (requerimiento 5.3). En Fase 2 se usan 10 bandas;
/// el motor acepta 10, 15 o 20 para el modo avanzado.
class EqualizerSettings {
  late bool enabled;

  /// Ganancia por banda en dB, en el rango -12..+12. La longitud define el
  /// numero de bandas (10, 15 o 20).
  late List<double> bandGainsDb;

  /// Ganancia previa en dB aplicada antes del ecualizador.
  late double preampDb;

  /// Reduce la ganancia previa automaticamente cuando varias bandas suben,
  /// para evitar clipping (requerimiento 5.3).
  late bool autoPreventClipping;

  /// -1.0 = solo izquierda, 0.0 = centrado, 1.0 = solo derecha.
  late double balance;

  /// Mezcla ambos canales a mono (requerimiento 5.5).
  late bool monoOutput;
}

/// Opciones de calidad de reproduccion (requerimiento 5.5).
class PlaybackOptions {
  late bool gaplessEnabled;

  /// 0..12 segundos. 0 desactiva el crossfade y habilita el modo gapless
  /// nativo de un solo reproductor.
  late int crossfadeSeconds;
  late bool fadeOnPause;
  late int fadeOnPauseMs;

  /// Reproduce con el menor procesamiento posible: ignora ecualizador,
  /// balance y mono, y permite audio offload (requerimiento 5.5 modo directo).
  late bool directMode;

  /// Permite audio offload cuando no hay procesamiento activo.
  late bool allowOffload;
}

/// Perfiles de mejora perceptual (requerimiento 5.2).
enum EnhancementProfile {
  balanced,
  clarity,
  tightBass,
  smooth,
  headphones,
  phoneSpeaker,
  custom,
}

/// Intensidad del realce de detalle. En [high] la interfaz debe advertir que
/// puede sonar artificial en archivos de baja calidad (requerimiento 5.2).
enum DetailLevel { off, low, medium, high }

/// [live] sigue la senal en tiempo real; [analyzed] aplica la ganancia medida
/// previamente para la pista, al estilo de ReplayGain.
enum NormalizationMode { off, live, analyzed }

/// Cadena de mejora de audio (requerimiento 5.1 y 5.2).
///
/// El limitador no aparece como interruptor: esta siempre activo al final de la
/// cadena mientras [enabled] sea verdadero, que es justo lo que exige el
/// requerimiento.
class EnhancementSettings {
  late bool enabled;
  late EnhancementProfile profile;
  late DetailLevel detail;

  /// Intensidad del procesamiento dinamico multibanda, 0.0 a 1.0.
  late double multibandStrength;

  late NormalizationMode normalization;

  /// Nivel objetivo en dB para la normalizacion en vivo.
  late double targetLevelDb;

  /// Desactivada por omision (requerimiento 5.2).
  late bool stereoExpansionEnabled;

  /// 0.0 a 1.0; el motor la limita para preservar la compatibilidad mono.
  late double stereoWidth;

  /// Ganancia medida para la pista actual, en dB. Solo se usa cuando
  /// [normalization] es [NormalizationMode.analyzed].
  late double trackGainDb;
}

/// Resultado del analisis de sonoridad de una pista (requerimiento 5.2).
class LoudnessAnalysis {
  late int songId;

  /// Ganancia recomendada en dB para alcanzar el nivel objetivo.
  late double gainDb;

  /// Pico maximo de la pista, 0.0 a 1.0, para no rebasar el limitador.
  late double peak;
}

/// Estilo visual del widget de inicio.
enum WidgetStyle {
  /// Tarjeta clara, redondeada y minimalista.
  ios,

  /// Fondo oscuro, acento saturado y mas informacion a la vista.
  vlc,
}

/// Tamano de rejilla del widget: 4x1, 4x2 y 4x3.
enum WidgetSize { compact, normal, large }

enum WidgetTheme { light, dark, system }

/// Configuracion del widget de inicio.
///
/// Vive en el motor y no en la base de datos de Flutter: el widget se dibuja
/// con la interfaz cerrada, y en ese momento la base de datos de Drift no esta
/// abierta.
class WidgetConfig {
  late bool enabled;
  late WidgetStyle style;
  late WidgetTheme theme;
  late WidgetSize preferredSize;

  /// Color de acento en formato ARGB.
  late int accentColor;

  /// 0.0 completamente transparente, 1.0 opaco.
  late double backgroundOpacity;

  // Informacion a mostrar
  late bool showCover;
  late bool showTitle;
  late bool showArtist;
  late bool showControls;
  late bool showProgress;
  late bool showDuration;
  late bool showNextInQueue;

  // Comportamiento
  late bool openPlayerOnTap;
  late bool pauseOnHeadphonesDisconnect;
  late bool resumeOnHeadphonesConnect;
}

/// Tipos de fuente remota (requerimiento 10, "fase posterior").
enum RemoteSourceKind { smb, webdav, http, radio }

/// Servidor o emisora dada de alta por el usuario.
///
/// La contrasena nunca viaja de vuelta a Flutter ni se guarda en la base de
/// datos: el motor la cifra con la Keystore de Android y solo devuelve si
/// existe (requerimiento 16).
class RemoteSource {
  late int id;
  late RemoteSourceKind kind;
  late String name;
  late String uri;
  String? username;
  late bool hasPassword;
}

/// Entrada de un listado remoto: carpeta o archivo.
class RemoteEntry {
  late String uri;
  late String name;
  late bool isDirectory;
  String? mimeType;
  late int sizeBytes;
}

/// Frecuencias centrales de las bandas del ecualizador para dibujar la UI.
class EqualizerBands {
  late List<double> centerFrequenciesHz;
  late double minGainDb;
  late double maxGainDb;
}

class PickedDocument {
  late String uri;
  late String name;
  String? mimeType;
}

class GrantedFolder {
  late String uri;
  late String displayPath;
}

/// Miniatura de portada resuelta por el motor.
class CoverImage {
  late int songId;
  late Uint8List bytes;
  late int width;
  late int height;
}

/// Letra encontrada para una cancion (requerimiento 8).
class LyricsPayload {
  /// Letra sin sincronizar, incrustada en las etiquetas del archivo.
  String? embedded;

  /// Contenido crudo de un archivo .lrc asociado o adyacente.
  String? lrcContent;

  /// Ruta o URI del archivo .lrc utilizado.
  String? lrcSource;
}

// ---------------------------------------------------------------------------
// API que Flutter invoca en Android
// ---------------------------------------------------------------------------

@HostApi()
abstract class MusicEngineHostApi {
  /// Conecta con MusicPlayerService y comienza a emitir eventos.
  @async
  void initialize();

  // --- Biblioteca (requerimiento 4.1) -------------------------------------

  /// Escanea MediaStore ignorando MIME de video y las carpetas excluidas.
  /// Devuelve el numero de canciones visibles tras el escaneo.
  @async
  int scanLibrary(List<String> excludedFolderPaths, bool forceFullRescan);

  @async
  List<Song> getSongs();

  /// Pide a MediaStore volver a leer un archivo concreto (requerimiento 7.1).
  @async
  void rescanFile(String filePath);

  @async
  TechnicalInfo getTechnicalInfo(int songId);

  /// Miniatura cuadrada de `size` px. Devuelve null si no hay portada.
  @async
  CoverImage? getCover(int songId, int size);

  // --- Cola y reproduccion (requerimiento 4.2, 4.3) ------------------------

  /// Reemplaza la cola completa. `startIndex` y `positionMs` permiten
  /// restaurar la ultima cola al abrir la aplicacion.
  void setQueue(
    List<Song> songs,
    int startIndex,
    int positionMs,
    bool startPlaying,
  );

  void addToQueueNext(List<Song> songs);
  void addToQueueEnd(List<Song> songs);
  void removeQueueItem(int index);
  void moveQueueItem(int fromIndex, int toIndex);
  void clearQueue();
  void playQueueIndex(int index);

  void play();
  void pause();
  void stop();
  void seek(int positionMs);

  /// Desplazamiento relativo en milisegundos; negativo retrocede.
  void seekRelative(int deltaMs);
  void skipNext();
  void skipPrevious();
  void setShuffle(bool enabled);
  void setRepeatMode(RepeatMode mode);
  void setPlaybackSpeed(double speed);
  void setPitch(double pitch);

  /// Activa el analisis PCM solo mientras una interfaz visible lo necesita.
  /// En modo directo/offload no se intercepta la senal y no se emiten cuadros.
  void setAudioAnalysisEnabled(bool enabled);

  /// Devuelve el estado actual sin esperar un evento.
  @async
  PlaybackSnapshot getPlaybackSnapshot();

  /// Informa al motor si la cancion en curso es favorita, para que la
  /// notificacion y Android Auto dibujen el icono correcto (requerimiento 9.2).
  void setFavoriteState(int songId, bool isFavorite);

  // --- Temporizador de apagado (requerimiento 4.2) -------------------------

  /// `finishCurrentTrack` deja terminar la cancion en curso antes de pausar.
  void setSleepTimer(int durationMs, bool finishCurrentTrack);
  void cancelSleepTimer();

  // --- Calidad y efectos (requerimiento 5.3, 5.5) --------------------------

  void setEqualizer(EqualizerSettings settings);
  void setPlaybackOptions(PlaybackOptions options);

  @async
  EqualizerBands getEqualizerBands(int bandCount);

  @async
  AudioOutput getCurrentAudioOutput();

  // --- Mejora de audio (requerimiento 5.1, 5.2) ----------------------------

  /// Publica la cadena de mejora completa. Aplicar el mismo objeto con
  /// `enabled` en falso es lo que hace la comparacion A/B instantanea.
  void setEnhancement(EnhancementSettings settings);

  /// Mide la sonoridad de una pista para la normalizacion por analisis. Decodifica
  /// el archivo completo, de modo que la interfaz debe llamarlo en segundo plano
  /// y respetando el estado de la bateria (requerimiento 17).
  @async
  LoudnessAnalysis analyzeLoudness(int songId);

  // --- Widget de inicio (requerimiento 9.2) --------------------------------

  /// Publica la configuracion del widget y repinta los que ya esten colocados.
  void setWidgetConfig(WidgetConfig config);

  /// Numero de widgets colocados en la pantalla de inicio, para poder decirlo
  /// en la pantalla de ajustes en vez de dar por hecho que hay alguno.
  @async
  int countPlacedWidgets();

  // --- Fuentes remotas (requerimiento 10) ----------------------------------

  @async
  List<RemoteSource> listRemoteSources();

  @async
  RemoteSource addRemoteSource(
    RemoteSourceKind kind,
    String name,
    String uri,
    String? username,
    String? password,
  );

  @async
  void removeRemoteSource(int sourceId);

  /// Lista una carpeta del servidor. `path` vacio significa la raiz declarada
  /// al dar de alta la fuente.
  @async
  List<RemoteEntry> browseRemoteSource(int sourceId, String path);

  /// Convierte entradas remotas en canciones reproducibles. Los identificadores
  /// son negativos para no colisionar nunca con los de MediaStore, que es lo
  /// que mantiene separadas la biblioteca local y las fuentes remotas.
  @async
  List<Song> resolveRemoteSongs(int sourceId, List<String> uris);

  /// Descarga y resuelve una lista M3U alojada en un servidor.
  @async
  List<Song> loadRemotePlaylist(String url);

  // --- Letras por internet (requerimiento 8) -------------------------------

  /// Consulta un proveedor abierto de letras. Devuelve el contenido `.lrc`
  /// sincronizado si existe, o la letra plana, o nulo si no hay coincidencia.
  @async
  String? fetchLyricsOnline(
    String title,
    String artist,
    String album,
    int durationMs,
  );

  // --- Metadatos y portada (requerimiento 7) -------------------------------

  @async
  WriteResult editMetadata(MetadataEdit edit);

  /// Escribe varias canciones en lote y devuelve un resultado por cancion.
  @async
  List<WriteResult> editMetadataBatch(List<MetadataEdit> edits);

  /// Incrusta `imageBytes` como portada del archivo.
  @async
  WriteResult setCoverArt(int songId, Uint8List imageBytes, String mimeType);

  @async
  List<WriteResult> setCoverArtBatch(
    List<int> songIds,
    Uint8List imageBytes,
    String mimeType,
  );

  @async
  WriteResult removeCoverArt(int songId);

  /// Portada incrustada en tamano original, para el editor.
  @async
  Uint8List? getEmbeddedCover(int songId);

  // --- Letras (requerimiento 8) -------------------------------------------

  @async
  LyricsPayload getLyrics(int songId);

  /// Guarda un .lrc junto al archivo de audio o en el almacenamiento de la
  /// aplicacion si la carpeta de origen no es escribible.
  @async
  String saveLrcFile(int songId, String lrcContent);

  // --- Almacenamiento y compartir (requerimiento 10, 16) -------------------

  /// Abre ACTION_OPEN_DOCUMENT_TREE y persiste el permiso concedido.
  @async
  GrantedFolder? pickFolder();

  @async
  List<GrantedFolder> getGrantedFolders();

  @async
  void releaseFolder(String uri);

  @async
  PickedDocument? pickDocument(List<String> mimeTypes);

  @async
  String readDocumentText(String uri);

  /// Contenido binario de un documento elegido con el selector del sistema. Se
  /// usa para las imagenes de portada que no estan indexadas en la galeria.
  @async
  Uint8List readDocumentBytes(String uri);

  /// Abre ACTION_CREATE_DOCUMENT y escribe `content`. Devuelve el URI creado.
  @async
  String? createTextDocument(
    String suggestedName,
    String mimeType,
    String content,
  );

  /// Imagen presente en el portapapeles, si hay alguna.
  @async
  Uint8List? getClipboardImage();

  @async
  void shareSongs(List<int> songIds);

  @async
  void shareText(String subject, String text);

  /// Abre la ubicacion del archivo en un explorador del sistema.
  @async
  void revealFile(int songId);

  /// Elimina el archivo del dispositivo. Distinto de quitar de la biblioteca
  /// (requerimiento 16).
  @async
  WriteResult deleteSongFile(int songId);
}

// ---------------------------------------------------------------------------
// Eventos que Android envia a Flutter
// ---------------------------------------------------------------------------

@FlutterApi()
abstract class MusicEngineFlutterApi {
  void playbackStateChanged(PlaybackSnapshot snapshot);
  void currentTrackChanged(int index, int? songId);
  void positionChanged(int positionMs, int durationMs, int bufferedMs);
  void queueChanged(List<Song> queue, int currentIndex);
  void audioDeviceChanged(AudioOutput output, String deviceName);
  void audioAnalysisChanged(AudioAnalysisFrame frame);

  /// El motor detecto cambios en MediaStore y la biblioteca fue reconstruida.
  void libraryChanged(int songCount);

  /// Las etiquetas de una cancion fueron reescritas por el motor.
  void metadataUpdated(Song song);

  /// El temporizador de apagado detuvo la reproduccion.
  void sleepTimerFinished();

  /// El usuario pulso el boton de favorito en la notificacion, la pantalla de
  /// bloqueo o Android Auto. Los favoritos viven en la base de datos de Flutter,
  /// asi que el motor solo traslada la intencion (requerimiento 9.2).
  void favoriteToggleRequested(int songId);
  void errorOccurred(String code, String message);
}
