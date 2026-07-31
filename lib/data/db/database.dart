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
  BoolColumn get synchronized =>
      boolean().withDefault(const Constant(false))();
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
  IntColumn get normalizationIndex => integer().withDefault(const Constant(0))();
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

  /// Profundidad del fondo (`BackgroundDepth.id`).
  TextColumn get backgroundDepth => text().withDefault(const Constant('night'))();

  /// Intensidad del efecto de vidrio (`GlassIntensity.id`).
  TextColumn get glassIntensity => text().withDefault(const Constant('medium'))();

  // Reproduccion
  BoolColumn get restoreQueueOnStart =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get gaplessEnabled => boolean().withDefault(const Constant(true))();
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
  BoolColumn get widgetShowCover => boolean().withDefault(const Constant(true))();
  BoolColumn get widgetShowTitle => boolean().withDefault(const Constant(true))();
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
  IntColumn get sleepTimerMinutes => integer().withDefault(const Constant(30))();
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
  ],
)
class NuvTuneDatabase extends _$NuvTuneDatabase {
  NuvTuneDatabase() : super(_openConnection());

  NuvTuneDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  /// Las migraciones solo agregan; nunca reescriben lo existente, de modo que
  /// una instalacion previa conserva favoritos, listas, historial y cola.
  ///
  /// - Version 2: tablas de Fase 3 (mejora, perfiles por salida, sonoridad).
  /// - Version 3: columnas de apariencia personalizable.
  /// - Version 4: configuracion del widget de inicio.
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
        },
      );

  /// La musica nunca se copia a la base de datos: solo se guardan
  /// identificadores de MediaStore y datos derivados (requerimiento 14).
  static QueryExecutor _openConnection() => driftDatabase(name: 'nuvtune');
}
