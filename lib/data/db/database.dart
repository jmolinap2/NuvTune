import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Favoritos (requerimiento seccion 14).
class Favorites extends Table {
  IntColumn get songId => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

/// Listas creadas por el usuario.
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Portada elegida para la lista, guardada dentro de la aplicacion.
  TextColumn get coverPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Modo regalo: presenta la lista con dedicatoria antes de reproducir.
  BoolColumn get giftMode => boolean().withDefault(const Constant(false))();

  /// Dedicatoria mostrada en la portada del modo regalo.
  TextColumn get dedication => text().nullable()();

  /// "De" y "Para" del regalo (opcional; si estan vacios no se muestran).
  TextColumn get giftFrom => text().nullable()();
  TextColumn get giftTo => text().nullable()();

  /// Identidad cromatica elegida para el regalo (uno de AccentIdentity.id).
  TextColumn get giftAccentId => text().nullable()();

  /// Identificador estable del paquete recibido. Evita importar dos veces el
  /// mismo regalo aunque Android entregue otra URI o el archivo cambie de
  /// nombre al compartirlo.
  TextColumn get giftId => text().nullable()();
}

/// Orden de las canciones dentro de cada lista (requerimiento 4.4).
class PlaylistEntries extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get songId => integer()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {playlistId, position};
}

/// Historial de reproduccion, base de "reproducidas recientemente".
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Contador de reproducciones, base de "mas reproducidas" y de varias listas
/// inteligentes.
class PlayCounts extends Table {
  IntColumn get songId => integer()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

/// Cola guardada para restaurarla al abrir la aplicacion (requerimiento 4.3).
class QueueEntries extends Table {
  IntColumn get position => integer()();
  IntColumn get songId => integer()();

  @override
  Set<Column<Object>> get primaryKey => {position};
}

/// Estado de la cola: cancion actual, posicion, repeticion y aleatorio. Una
/// sola fila, con [id] fijo en 0.
class QueueState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get currentIndex => integer().withDefault(const Constant(-1))();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();

  /// Indice de [RepeatMode] del contrato con el motor.
  IntColumn get repeatMode => integer().withDefault(const Constant(0))();
  BoolColumn get shuffleEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Carpetas excluidas del escaneo (requerimiento 4.1).
class ExcludedFolders extends Table {
  TextColumn get path => text()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

/// Carpetas concedidas por Storage Access Framework como fuente de musica.
///
/// No se llama GrantedFolders para que la clase de fila generada por Drift no
/// choque con la clase GrantedFolder del contrato de Pigeon.
class SourceFolders extends Table {
  TextColumn get uri => text()();
  TextColumn get displayPath => text()();

  @override
  Set<Column<Object>> get primaryKey => {uri};
}

/// Portadas que solo existen dentro de la aplicacion, sin tocar el archivo
/// (requerimiento 7.2: la aplicacion distingue entre portada incrustada,
/// portada personalizada solo de la aplicacion y portada general del album).
class CustomCovers extends Table {
  /// `song:<id>` o `album:<id>`.
  TextColumn get target => text()();
  TextColumn get imagePath => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {target};
}

/// Presets del ecualizador guardados por el usuario (requerimiento 14).
@DataClassName('EqualizerPreset')
class EqualizerPresetsTable extends Table {
  @override
  String get tableName => 'equalizer_presets';

  TextColumn get name => text()();
  IntColumn get bandCount => integer()();

  /// Ganancias en dB codificadas como JSON.
  TextColumn get gainsJson => text()();
  RealColumn get preampDb => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

/// Estado actual del ecualizador. Una sola fila con [id] fijo en 0.
class EqualizerState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  IntColumn get bandCount => integer().withDefault(const Constant(10))();
  TextColumn get gainsJson =>
      text().withDefault(const Constant('[0,0,0,0,0,0,0,0,0,0]'))();
  RealColumn get preampDb => real().withDefault(const Constant(0))();
  BoolColumn get autoPreventClipping =>
      boolean().withDefault(const Constant(true))();
  RealColumn get balance => real().withDefault(const Constant(0))();
  BoolColumn get monoOutput => boolean().withDefault(const Constant(false))();
  TextColumn get presetName => text().withDefault(const Constant('Plano'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Letras editadas o asociadas a mano, con su desfase (requerimiento 8).
class LyricsOverrides extends Table {
  IntColumn get songId => integer()();
  TextColumn get content => text()();
  IntColumn get offsetMs => integer().withDefault(const Constant(0))();
  BoolColumn get synchronized => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

/// Estado de la cadena de mejora de audio. Una sola fila con [id] fijo en 0
/// (requerimiento 5.1 y 5.2).
class EnhancementState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  /// Indice de `EnhancementProfile` del contrato con el motor.
  IntColumn get profileIndex => integer().withDefault(const Constant(0))();

  /// Indice de `DetailLevel`.
  IntColumn get detailIndex => integer().withDefault(const Constant(0))();
  RealColumn get multibandStrength => real().withDefault(const Constant(0))();

  /// Indice de `NormalizationMode`.
  IntColumn get normalizationIndex =>
      integer().withDefault(const Constant(0))();
  RealColumn get targetLevelDb => real().withDefault(const Constant(-14))();
  BoolColumn get stereoExpansionEnabled =>
      boolean().withDefault(const Constant(false))();
  RealColumn get stereoWidth => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Perfil guardado por tipo de salida de audio (requerimiento 5.4).
///
/// La clave es el indice de `AudioOutput`: altavoz, auriculares con cable,
/// Bluetooth, Android Auto y DAC USB.
class OutputProfiles extends Table {
  IntColumn get outputIndex => integer()();

  /// Curva del ecualizador guardada para esta salida.
  IntColumn get bandCount => integer().withDefault(const Constant(10))();
  TextColumn get gainsJson =>
      text().withDefault(const Constant('[0,0,0,0,0,0,0,0,0,0]'))();
  TextColumn get presetName => text().withDefault(const Constant('Plano'))();
  RealColumn get preampDb => real().withDefault(const Constant(0))();

  /// Perfil de mejora asociado a esta salida.
  IntColumn get profileIndex => integer().withDefault(const Constant(0))();
  BoolColumn get enhancementEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {outputIndex};
}

/// Analisis de sonoridad por pista, al estilo de ReplayGain (requerimiento 5.2).
class LoudnessAnalyses extends Table {
  IntColumn get songId => integer()();
  RealColumn get gainDb => real()();
  RealColumn get peak => real()();
  DateTimeColumn get analyzedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

/// Emisoras de radio y enlaces remotos guardados por el usuario
/// (requerimiento 10).
///
/// Los servidores con credenciales no viven aqui: los guarda el motor, que
/// cifra la contrasena con la Keystore de Android (requerimiento 16).
class SavedRadios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Videos musicales asociados a una cancion, para el fondo del reproductor.
///
/// La clave `songKey` combina artista, titulo, album y duracion en minusculas.
/// No usa el ID de MediaStore, de modo que un re-escaneo o reinstalacion no
/// invalida el cache, pero dos versiones distintas de una cancion no se pisan.
class SongVideoIds extends Table {
  TextColumn get songKey => text()();
  TextColumn get videoId => text()();

  /// Origen ("piped", "manual", "youtube_api"), por si algun dia hay mas de
  /// una fuente y hay que priorizar.
  TextColumn get source => text().withDefault(const Constant('piped'))();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {songKey};
}

/// Preferencias de la aplicacion. Una sola fila con [id] fijo en 0; columnas
/// tipadas en lugar de pares clave/valor para que el compilador valide cada
/// ajuste.
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  // Biblioteca
  BoolColumn get scanOnStart => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastScanAt => dateTime().nullable()();

  // Apariencia
  BoolColumn get useDynamicColor =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get pureBlackBackground =>
      boolean().withDefault(const Constant(false))();

  /// Identidad cromatica elegida (`AccentIdentity.id`).
  TextColumn get accentId => text().withDefault(const Constant('nebula'))();

  /// Modo global de tema (`AppThemePreference.id`). Las instalaciones previas
  /// migran a oscuro para conservar exactamente su apariencia.
  TextColumn get themeMode => text().withDefault(const Constant('dark'))();

  /// Profundidad del fondo (`BackgroundDepth.id`).
  TextColumn get backgroundDepth =>
      text().withDefault(const Constant('night'))();

  /// Intensidad del efecto de vidrio (`GlassIntensity.id`).
  TextColumn get glassIntensity =>
      text().withDefault(const Constant('medium'))();

  /// Identidad visual completa (`AppThemeIdentity.id`). Agrupa brillo, fondo,
  /// superficie, tipografía, densidad y acento en una sola elección.
  TextColumn get themeIdentity =>
      text().withDefault(const Constant('nebulaGlass'))();

  /// Desvíos por eje sobre la identidad. Vacío significa «lo que diga la
  /// identidad», de modo que cambiar de identidad no arrastra ajustes viejos.
  TextColumn get surfaceStyle => text().withDefault(const Constant(''))();
  TextColumn get typographyStyle => text().withDefault(const Constant(''))();
  TextColumn get layoutDensity => text().withDefault(const Constant(''))();

  // Reproduccion
  BoolColumn get restoreQueueOnStart =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get gaplessEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get crossfadeSeconds => integer().withDefault(const Constant(0))();
  BoolColumn get fadeOnPause => boolean().withDefault(const Constant(true))();
  IntColumn get fadeOnPauseMs => integer().withDefault(const Constant(250))();

  // Calidad
  BoolColumn get directMode => boolean().withDefault(const Constant(false))();
  BoolColumn get allowOffload => boolean().withDefault(const Constant(true))();
  RealColumn get playbackSpeed => real().withDefault(const Constant(1))();
  RealColumn get playbackPitch => real().withDefault(const Constant(1))();

  // Metadatos
  BoolColumn get embedCoverInFile =>
      boolean().withDefault(const Constant(true))();

  // Widget de inicio (requerimiento 9.2). El motor guarda su propia copia en
  // SharedPreferences para poder dibujar con la aplicacion cerrada; esta es la
  // que alimenta la pantalla de ajustes.
  BoolColumn get widgetEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get widgetStyle => integer().withDefault(const Constant(0))();
  IntColumn get widgetTheme => integer().withDefault(const Constant(1))();
  IntColumn get widgetSize => integer().withDefault(const Constant(1))();
  IntColumn get widgetAccentColor =>
      integer().withDefault(const Constant(0xFFB14BFF))();
  RealColumn get widgetOpacity => real().withDefault(const Constant(0.92))();
  BoolColumn get widgetShowCover =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetShowTitle =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetShowArtist =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetShowControls =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetShowProgress =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetShowDuration =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get widgetShowNextInQueue =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get widgetOpenOnTap =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetPauseOnDisconnect =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get widgetResumeOnConnect =>
      boolean().withDefault(const Constant(false))();

  // Temporizador
  IntColumn get sleepTimerMinutes =>
      integer().withDefault(const Constant(30))();
  BoolColumn get sleepTimerFinishTrack =>
      boolean().withDefault(const Constant(true))();

  /// Secciones activas de la pantalla Inicio, en orden, codificadas como JSON.
  TextColumn get homeSectionsJson => text().withDefault(
    const Constant(
      '["continue","favorites","recentlyPlayed","recentAlbums","mostPlayed","featuredPlaylists"]',
    ),
  )();

  /// Orden y filtro recordados por seccion de la biblioteca
  /// (requerimiento 4.1), codificados como JSON.
  TextColumn get librarySortJson => text().withDefault(const Constant('{}'))();

  /// Fondo de video musical en la pantalla del reproductor.
  /// Requiere Wi-Fi (nunca datos moviles) para no gastar el plan del usuario.
  BoolColumn get videoBackgroundEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Estilo del visualizador reactivo del reproductor.
  /// Cero es automatico; los demas valores siguen VisualizerStyle.values.
  IntColumn get playerVisualizerStyle =>
      integer().withDefault(const Constant(0))();

  /// Perfil de rendimiento del visualizador (`VisualizerQuality.id`). Se
  /// guarda como identificador estable para que reordenar el enum no cambie
  /// silenciosamente la preferencia elegida.
  TextColumn get playerVisualizerQuality =>
      text().withDefault(const Constant('normal'))();

  /// Reduce partículas, destellos y variaciones visuales rápidas sin depender
  /// del ajuste de accesibilidad global de Android.
  BoolColumn get reduceVisualizerEffects =>
      boolean().withDefault(const Constant(false))();

  /// Personalidad global del movimiento y ajustes avanzados (niveles 0..3).
  TextColumn get motionProfile =>
      text().withDefault(const Constant('balanced'))();
  IntColumn get motionIntensity => integer().withDefault(const Constant(2))();
  IntColumn get motionSmoothness => integer().withDefault(const Constant(2))();
  IntColumn get motionBeatResponse =>
      integer().withDefault(const Constant(2))();
  IntColumn get motionParticles => integer().withDefault(const Constant(2))();
  TextColumn get visualizerColorSource =>
      text().withDefault(const Constant('cover'))();

  /// Mapa de colores del visualizador: paradas `{p, c}` ordenadas por
  /// intensidad, no por posición en pantalla. Es JSON porque representa una
  /// lista de longitud variable que el usuario edita.
  /// Cadena vacía significa "usar el reparto por defecto".
  TextColumn get visualizerColorMapJson =>
      text().withDefault(const Constant(''))();

  /// Cómo se reparte ese mapa sobre cada elemento (`VisualizerColorMode.id`):
  /// `row` pinta cada nivel de altura con su color, `column` da a la barra
  /// entera el color de la intensidad que alcanza.
  TextColumn get visualizerColorMode =>
      text().withDefault(const Constant('row'))();

  /// Escenario principal del reproductor. Los índices corresponden a
  /// PlayerVisualScene; cero es Video y usa Portada si no hay un video
  /// disponible mediante Wi-Fi.
  IntColumn get playerVisualScene => integer().withDefault(const Constant(0))();

  /// Relación de aspecto del contenedor de la escena visual en pantalla
  /// completa. Los índices corresponden a PlayerSceneAspectRatio; cero es
  /// pantalla completa (9:16, comportamiento previo a esta columna).
  IntColumn get playerSceneAspectRatio =>
      integer().withDefault(const Constant(0))();

  // Controles y gestos del reproductor. El orden usa JSON porque representa
  // dos listas ordenadas; los interruptores siguen siendo columnas tipadas.
  TextColumn get playerControlPreset =>
      text().withDefault(const Constant('complete'))();
  TextColumn get playerControlLayoutJson => text().withDefault(
    const Constant(
      '{"top":[],"primary":["shuffle","previous","playPause","next","repeat"],'
      '"secondary":["seekBackward","seekForward","queue","sleepTimer"],'
      '"footer":["favorite"]}',
    ),
  )();
  TextColumn get playerControlHandedness =>
      text().withDefault(const Constant('right'))();

  /// Cuanto aire deja el reproductor: 'compact', 'normal' o 'spacious'. Ver
  /// [PlayerDensity]. No guarda medidas en pixeles a proposito: el reparto de
  /// altura lo recalcula el reproductor con la pantalla real, asi que una
  /// preferencia hecha en un telefono no puede dejar los controles fuera de
  /// pantalla en otro.
  TextColumn get playerDensity =>
      text().withDefault(const Constant('normal'))();
  BoolColumn get playerGestureDoubleTap =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get playerGestureSwipeTrack =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get playerGestureSwipeVolume =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get playerGestureSwipeDismiss =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Favorites,
    Playlists,
    PlaylistEntries,
    PlayHistory,
    PlayCounts,
    QueueEntries,
    QueueState,
    ExcludedFolders,
    SourceFolders,
    CustomCovers,
    EqualizerPresetsTable,
    EqualizerState,
    EnhancementState,
    OutputProfiles,
    LoudnessAnalyses,
    SavedRadios,
    LyricsOverrides,
    AppSettings,
    SongVideoIds,
  ],
)
class NuvTuneDatabase extends _$NuvTuneDatabase {
  NuvTuneDatabase() : super(_openConnection());

  NuvTuneDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 18;

  /// Las migraciones solo agregan; nunca reescriben lo existente, de modo que
  /// una instalacion previa conserva favoritos, listas, historial y cola.
  ///
  /// - Version 2: tablas de Fase 3 (mejora, perfiles por salida, sonoridad).
  /// - Version 3: columnas de apariencia personalizable.
  /// - Version 4: configuracion del widget de inicio.
  /// - Version 5: video de fondo, descargas online y modo regalo de listas.
  /// - Version 6: estilo preferido del visualizador del reproductor.
  /// - Version 8: escenario persistente (video, visualizador, video + letras,
  ///   letras o portada).
  /// - Version 9: relacion de aspecto del contenedor de la escena en pantalla
  ///   completa.
  /// - Version 10: se retira `downloaded_songs` (tabla propia fuera de
  ///   MediaStore). El motor de descarga heredado de NuvClip escribe
  ///   directamente en MediaStore.Audio, asi que una descarga se vuelve una
  ///   cancion normal de la biblioteca sin necesitar esta tabla aparte.
  /// - Version 11: diseño y gestos personalizables del reproductor.
  /// - Version 12: identificador estable de regalos para importacion idempotente.
  /// - Version 13: densidad del reproductor.
  /// - Version 14: perfil de calidad y reducción de efectos del visualizador.
  /// - Version 15: tema real, perfiles de movimiento y color del visualizador.
  /// - Version 16: mapa de colores editable del visualizador, indexado por la
  ///   intensidad que alcanza cada elemento.
  /// - Version 17: reparto del mapa por fila o por columna.
  /// - Version 18: identidades visuales completas y sus desvíos por eje.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(enhancementState);
        await migrator.createTable(outputProfiles);
        await migrator.createTable(loudnessAnalyses);
        await migrator.createTable(savedRadios);
      }
      if (from < 3) {
        await migrator.addColumn(appSettings, appSettings.accentId);
        await migrator.addColumn(appSettings, appSettings.backgroundDepth);
        await migrator.addColumn(appSettings, appSettings.glassIntensity);
      }
      if (from < 4) {
        // Una llamada por columna: `addColumn` exige el tipo concreto y una
        // lista mixta de booleanas, enteras y reales lo perderia.
        await migrator.addColumn(appSettings, appSettings.widgetEnabled);
        await migrator.addColumn(appSettings, appSettings.widgetStyle);
        await migrator.addColumn(appSettings, appSettings.widgetTheme);
        await migrator.addColumn(appSettings, appSettings.widgetSize);
        await migrator.addColumn(appSettings, appSettings.widgetAccentColor);
        await migrator.addColumn(appSettings, appSettings.widgetOpacity);
        await migrator.addColumn(appSettings, appSettings.widgetShowCover);
        await migrator.addColumn(appSettings, appSettings.widgetShowTitle);
        await migrator.addColumn(appSettings, appSettings.widgetShowArtist);
        await migrator.addColumn(appSettings, appSettings.widgetShowControls);
        await migrator.addColumn(appSettings, appSettings.widgetShowProgress);
        await migrator.addColumn(appSettings, appSettings.widgetShowDuration);
        await migrator.addColumn(
          appSettings,
          appSettings.widgetShowNextInQueue,
        );
        await migrator.addColumn(appSettings, appSettings.widgetOpenOnTap);
        await migrator.addColumn(
          appSettings,
          appSettings.widgetPauseOnDisconnect,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.widgetResumeOnConnect,
        );
      }
      if (from < 5) {
        await migrator.createTable(songVideoIds);
        // `downloaded_songs` se creaba aqui; se retiro en la version 10 (mas
        // abajo, `deleteTable` con `DROP TABLE IF EXISTS` cubre tanto a quien
        // la llegue a tener como a quien salte directo de una version previa
        // a la 5 hasta la actual sin haberla tenido nunca).
        await migrator.addColumn(playlists, playlists.giftMode);
        await migrator.addColumn(playlists, playlists.dedication);
        await migrator.addColumn(playlists, playlists.giftFrom);
        await migrator.addColumn(playlists, playlists.giftTo);
        await migrator.addColumn(playlists, playlists.giftAccentId);
        await migrator.addColumn(
          appSettings,
          appSettings.videoBackgroundEnabled,
        );
      }
      if (from < 6) {
        await migrator.addColumn(
          appSettings,
          appSettings.playerVisualizerStyle,
        );
      }
      if (from < 8) {
        await migrator.addColumn(appSettings, appSettings.playerVisualScene);
      }
      if (from < 9) {
        await migrator.addColumn(
          appSettings,
          appSettings.playerSceneAspectRatio,
        );
      }
      if (from < 10) {
        await migrator.deleteTable('downloaded_songs');
      }
      if (from < 11) {
        await migrator.addColumn(appSettings, appSettings.playerControlPreset);
        await migrator.addColumn(
          appSettings,
          appSettings.playerControlLayoutJson,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.playerControlHandedness,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.playerGestureDoubleTap,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.playerGestureSwipeTrack,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.playerGestureSwipeVolume,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.playerGestureSwipeDismiss,
        );
      }
      if (from < 12) {
        await migrator.addColumn(playlists, playlists.giftId);
      }
      if (from < 13) {
        await migrator.addColumn(appSettings, appSettings.playerDensity);
      }
      if (from < 14) {
        await migrator.addColumn(
          appSettings,
          appSettings.playerVisualizerQuality,
        );
        await migrator.addColumn(
          appSettings,
          appSettings.reduceVisualizerEffects,
        );
      }
      if (from < 15) {
        await migrator.addColumn(appSettings, appSettings.themeMode);
        await migrator.addColumn(appSettings, appSettings.motionProfile);
        await migrator.addColumn(appSettings, appSettings.motionIntensity);
        await migrator.addColumn(appSettings, appSettings.motionSmoothness);
        await migrator.addColumn(appSettings, appSettings.motionBeatResponse);
        await migrator.addColumn(appSettings, appSettings.motionParticles);
        await migrator.addColumn(
          appSettings,
          appSettings.visualizerColorSource,
        );
        await customStatement('''
          UPDATE app_settings
          SET motion_profile = 'calm', reduce_visualizer_effects = 0
          WHERE reduce_visualizer_effects = 1
        ''');
        await customStatement('''
          UPDATE app_settings
          SET theme_mode = 'amoled',
              pure_black_background = 0,
              background_depth = 'night'
          WHERE pure_black_background = 1 OR background_depth = 'black'
        ''');
      }
      if (from < 16) {
        await migrator.addColumn(
          appSettings,
          appSettings.visualizerColorMapJson,
        );
      }
      if (from < 17) {
        await migrator.addColumn(appSettings, appSettings.visualizerColorMode);
      }
      if (from < 18) {
        await migrator.addColumn(appSettings, appSettings.themeIdentity);
        await migrator.addColumn(appSettings, appSettings.surfaceStyle);
        await migrator.addColumn(appSettings, appSettings.typographyStyle);
        await migrator.addColumn(appSettings, appSettings.layoutDensity);
        // Una instalación previa conserva su apariencia: se le asigna la
        // identidad más cercana a lo que ya tenía en vez de imponer la nueva
        // por defecto.
        await customStatement('''
          UPDATE app_settings
          SET theme_identity = CASE
            WHEN theme_mode = 'light' THEN 'paperLoft'
            WHEN theme_mode = 'amoled' THEN 'amoledMono'
            ELSE 'nebulaGlass'
          END
        ''');
      }
    },
  );

  /// La musica nunca se copia a la base de datos: solo se guardan
  /// identificadores de MediaStore y datos derivados (requerimiento 14).
  static QueryExecutor _openConnection() => driftDatabase(name: 'nuvtune');
}
