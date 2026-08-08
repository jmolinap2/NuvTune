import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/playlists/gift_payload.dart';

/// Paso del asistente de recepcion de un regalo.
enum GiftImportStage {
  /// Todavia no se eligio ningun archivo.
  idle,

  /// Leyendo y validando el archivo.
  reading,

  /// Archivo valido: se muestra que trae antes de tocar la biblioteca.
  reviewing,

  /// Copiando a la biblioteca el audio que venia dentro del regalo.
  importing,

  /// Lista creada.
  done,

  /// El archivo no era un regalo valido.
  failed,
}

class GiftImportState {
  const GiftImportState({
    this.stage = GiftImportStage.idle,
    this.payload,
    this.match,
    this.embeddedAudioCount = 0,
    this.sizeBytes = 0,
    this.addedCount = 0,
    this.playlistId,
    this.error,
  });

  final GiftImportStage stage;
  final GiftPayload? payload;

  /// Cruce contra la biblioteca hecho al abrir el archivo.
  final GiftMatch? match;

  /// Cuantas canciones traen su audio dentro del archivo. Cero significa un
  /// regalo del formato antiguo, que solo llevaba titulos.
  final int embeddedAudioCount;
  final int sizeBytes;

  /// Cuantas canciones se copiaron a la biblioteca al importar.
  final int addedCount;

  final int? playlistId;
  final String? error;

  int get totalSongs => payload?.songs.length ?? 0;
  int get foundCount => match?.foundCount ?? 0;
  int get missingCount => match?.missing.length ?? 0;

  /// Un regalo del formato nuevo trae todo lo que hace falta; uno antiguo
  /// depende de lo que el receptor ya tenga.
  bool get hasEmbeddedAudio => embeddedAudioCount > 0;

  GiftImportState copyWith({
    GiftImportStage? stage,
    GiftPayload? payload,
    GiftMatch? match,
    int? embeddedAudioCount,
    int? sizeBytes,
    int? addedCount,
    int? playlistId,
    String? error,
  }) =>
      GiftImportState(
        stage: stage ?? this.stage,
        payload: payload ?? this.payload,
        match: match ?? this.match,
        embeddedAudioCount: embeddedAudioCount ?? this.embeddedAudioCount,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        addedCount: addedCount ?? this.addedCount,
        playlistId: playlistId ?? this.playlistId,
        error: error ?? this.error,
      );
}

final giftImportProvider =
    NotifierProvider<GiftImportController, GiftImportState>(
  GiftImportController.new,
);

/// Orquesta la recepcion de un regalo: leer el archivo, mostrar que trae,
/// copiar su audio a la biblioteca y crear la lista.
class GiftImportController extends Notifier<GiftImportState> {
  @override
  GiftImportState build() => const GiftImportState();

  void reset() => state = const GiftImportState();

  /// Lee el archivo sin importar nada todavia.
  Future<void> loadFromUri(String uri) async {
    state = const GiftImportState(stage: GiftImportStage.reading);
    try {
      final package = await ref.read(engineProvider).api.readGiftPackage(uri);
      final payload = GiftPayload.decode(package.metadataJson);
      state = GiftImportState(
        stage: GiftImportStage.reviewing,
        payload: payload,
        match: matchGiftSongs(
          payload.songs,
          ref.read(libraryRepositoryProvider).songs,
        ),
        embeddedAudioCount: package.embeddedAudioCount,
        sizeBytes: package.sizeBytes,
      );
      _pendingUri = uri;
    } on FormatException catch (error) {
      state = GiftImportState(
        stage: GiftImportStage.failed,
        error: error.message,
      );
    } catch (_) {
      state = const GiftImportState(
        stage: GiftImportStage.failed,
        error: 'No se pudo leer el archivo del regalo',
      );
    }
  }

  /// Uri del regalo en curso: el audio se copia recien cuando el usuario
  /// acepta, de modo que hay que recordar de donde salio.
  String? _pendingUri;

  /// Abre el selector del sistema y carga el archivo elegido. Devuelve false
  /// si el usuario cancelo.
  Future<bool> pickAndLoad() async {
    // `*/*` a secas y no una lista de tipos: WhatsApp guarda el regalo como
    // `application/octet-stream` y algunos selectores de archivos atenuan todo
    // lo que no este en la lista declarada. Aqui es preferible dejar elegir
    // cualquier archivo y rechazarlo despues con un mensaje claro, a que el
    // usuario vea su regalo en gris y no pueda tocarlo.
    final document =
        await ref.read(engineProvider).api.pickDocument(const ['*/*']);
    if (document == null) return false;
    await loadFromUri(document.uri);
    return true;
  }

  /// Copia el audio del regalo a la biblioteca y crea la lista.
  Future<void> completeImport() async {
    final payload = state.payload;
    final uri = _pendingUri;
    if (payload == null || uri == null) return;

    var added = 0;
    if (state.hasEmbeddedAudio) {
      state = state.copyWith(stage: GiftImportStage.importing);
      try {
        added = await ref.read(engineProvider).api.importGiftAudio(uri);
      } catch (_) {
        state = state.copyWith(
          stage: GiftImportStage.failed,
          error: 'No se pudo copiar la música del regalo',
        );
        return;
      }
      // El audio se escribio en MediaStore: recien tras releer la biblioteca
      // existen como canciones con id propio y se pueden meter en la lista.
      await ref.read(libraryProvider.notifier).scan();
    }

    final finalMatch = matchGiftSongs(
      payload.songs,
      ref.read(libraryRepositoryProvider).songs,
    );
    final songIds = [
      for (var index = 0; index < payload.songs.length; index++)
        if (finalMatch.resolved[index] != null) finalMatch.resolved[index]!,
    ];

    final playlists = ref.read(playlistRepositoryProvider);
    final playlistId = await playlists.create(payload.name, songIds: songIds);
    await playlists.setGift(
      playlistId,
      giftMode: true,
      dedication: payload.dedication,
      giftFrom: payload.from,
      giftTo: payload.to,
      giftAccentId: payload.accentId,
    );

    state = state.copyWith(
      stage: GiftImportStage.done,
      match: finalMatch,
      addedCount: added,
      playlistId: playlistId,
    );
  }
}
