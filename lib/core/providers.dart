import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/permissions/permission_service.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/data/repositories/cover_repository.dart';
import 'package:nuvtune/data/repositories/enhancement_repository.dart';
import 'package:nuvtune/data/repositories/equalizer_repository.dart';
import 'package:nuvtune/data/repositories/favorites_repository.dart';
import 'package:nuvtune/data/repositories/history_repository.dart';
import 'package:nuvtune/data/repositories/library_repository.dart';
import 'package:nuvtune/data/repositories/lyrics_repository.dart';
import 'package:nuvtune/data/repositories/playlist_repository.dart';
import 'package:nuvtune/data/repositories/queue_repository.dart';
import 'package:nuvtune/data/repositories/settings_repository.dart';

/// Base de datos local. Vive mientras vive la aplicacion.
final databaseProvider = Provider<NuvTuneDatabase>((ref) {
  final database = NuvTuneDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Puente con el motor Android.
final engineProvider = Provider<EngineBridge>((ref) {
  final engine = EngineBridge();
  ref.onDispose(engine.dispose);
  return engine;
});

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(engineProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(databaseProvider)),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepository(ref.watch(databaseProvider)),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(databaseProvider)),
);

final queueRepositoryProvider = Provider<QueueRepository>(
  (ref) => QueueRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final equalizerRepositoryProvider = Provider<EqualizerRepository>(
  (ref) => EqualizerRepository(ref.watch(databaseProvider)),
);

final enhancementRepositoryProvider = Provider<EnhancementRepository>(
  (ref) => EnhancementRepository(ref.watch(databaseProvider)),
);

final coverRepositoryProvider = Provider<CoverRepository>(
  (ref) => CoverRepository(ref.watch(databaseProvider)),
);

final lyricsRepositoryProvider = Provider<LyricsRepository>(
  (ref) => LyricsRepository(ref.watch(databaseProvider)),
);

// -- Flujos derivados de la base de datos ------------------------------------

final settingsProvider = StreamProvider<AppSetting>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);

final favoriteIdsProvider = StreamProvider<Set<int>>(
  (ref) => ref.watch(favoritesRepositoryProvider).watchFavoriteIds(),
);

final playlistsProvider = StreamProvider<List<Playlist>>(
  (ref) => ref.watch(playlistRepositoryProvider).watchPlaylists(),
);

final playlistSongCountsProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(playlistRepositoryProvider).watchSongCounts(),
);

final playCountsProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(historyRepositoryProvider).watchPlayCounts(),
);

final recentlyPlayedIdsProvider = StreamProvider<List<int>>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecentlyPlayedIds(),
);

final mostPlayedIdsProvider = StreamProvider<List<int>>(
  (ref) => ref.watch(historyRepositoryProvider).watchMostPlayedIds(),
);

final excludedFoldersProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchExcludedFolders(),
);

final sourceFoldersProvider = StreamProvider<List<SourceFolder>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSourceFolders(),
);

final customCoversProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(coverRepositoryProvider).watchCustomCovers(),
);

final equalizerStateProvider = StreamProvider<EqualizerStateData>(
  (ref) => ref.watch(equalizerRepositoryProvider).watchState(),
);

final enhancementStateProvider = StreamProvider<EnhancementStateData>(
  (ref) => ref.watch(enhancementRepositoryProvider).watchState(),
);

/// Perfiles guardados por tipo de salida (requerimiento 5.4).
final outputProfilesProvider = StreamProvider<Map<int, OutputProfile>>(
  (ref) => ref.watch(enhancementRepositoryProvider).watchOutputProfiles(),
);

/// Servidores y emisoras dados de alta en el motor (requerimiento 10).
final remoteSourcesProvider = FutureProvider<List<RemoteSource>>(
  (ref) => ref.watch(engineProvider).api.listRemoteSources(),
);

final userEqualizerPresetsProvider = StreamProvider<List<EqualizerPreset>>(
  (ref) => ref.watch(equalizerRepositoryProvider).watchUserPresets(),
);

/// Errores que emite el motor, para mostrarlos como aviso sin bloquear.
final engineErrorsProvider = StreamProvider<EngineError>(
  (ref) => ref.watch(engineProvider).errors,
);

/// Salida de audio activa (requerimiento 5.4).
final audioOutputProvider = StreamProvider<AudioOutputChange>(
  (ref) => ref.watch(engineProvider).audioOutput,
);
