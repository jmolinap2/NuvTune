import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/navigation/page_transitions.dart';
import 'package:nuvtune/app/navigation/root_shell.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/downloads/song_search_screen.dart';
import 'package:nuvtune/features/downloads/youtube_login_screen.dart';
import 'package:nuvtune/features/equalizer/equalizer_screen.dart';
import 'package:nuvtune/features/home/home_screen.dart';
import 'package:nuvtune/features/library/library_screen.dart';
import 'package:nuvtune/features/library/song_collection_screen.dart';
import 'package:nuvtune/features/metadata_editor/batch_editor_screen.dart';
import 'package:nuvtune/features/metadata_editor/metadata_lookup_screen.dart';
import 'package:nuvtune/features/metadata_editor/song_editor_screen.dart';
import 'package:nuvtune/features/player/player_screen.dart';
import 'package:nuvtune/features/playlists/gift_intro_screen.dart';
import 'package:nuvtune/features/playlists/gift_receive_wizard.dart';
import 'package:nuvtune/features/playlists/playlist_detail_screen.dart';
import 'package:nuvtune/features/playlists/playlists_screen.dart';
import 'package:nuvtune/features/queue/queue_screen.dart';
import 'package:nuvtune/features/remote_sources/remote_sources_screen.dart';
import 'package:nuvtune/features/settings/app_theme_screen.dart';
import 'package:nuvtune/features/settings/appearance_screen.dart';
import 'package:nuvtune/features/settings/control_screen.dart';
import 'package:nuvtune/features/settings/controls_settings_screen.dart';
import 'package:nuvtune/features/settings/playback_settings_screen.dart';
import 'package:nuvtune/features/settings/system_settings_screen.dart';
import 'package:nuvtune/features/settings/visualizer_color_map_screen.dart';
import 'package:nuvtune/features/settings/folders_screen.dart';
import 'package:nuvtune/features/settings/playback_failure_log_screen.dart';
import 'package:nuvtune/features/settings/video_match_log_screen.dart';
import 'package:nuvtune/features/settings/settings_category_screens.dart';
import 'package:nuvtune/features/settings/settings_screen.dart';

/// Rutas de la aplicacion.
///
/// Las cuatro secciones de la navegacion inferior son ramas de un
/// StatefulShellRoute, de modo que cada una conserva su propia pila y su
/// posicion de desplazamiento al cambiar de pestana (requerimiento seccion 4.1).
/// Las pantallas que se abren encima, como el reproductor completo o el editor,
/// van fuera del shell para que ocupen toda la altura y usan
/// [buildFadeSlidePage] para una transicion consistente entre si.
GoRouter createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                builder: (context, state) => const PlaylistsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/player',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final motion = ThemeScope.of(context).motion;
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: motion.scale(
              const Duration(milliseconds: 420),
              systemReduceMotion: reduceMotion,
            ),
            reverseTransitionDuration: motion.scale(
              const Duration(milliseconds: 320),
              systemReduceMotion: reduceMotion,
            ),
            child: const PlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/queue',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const QueueScreen()),
      ),
      GoRoute(
        path: '/equalizer',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const EqualizerScreen()),
      ),

      GoRoute(
        path: '/album/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.album(
              int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/artist/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.artist(
              int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/folder',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.folder(
              state.uri.queryParameters['path'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/genre/:name',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.genre(state.pathParameters['name']!),
          ),
        ),
      ),
      GoRoute(
        path: '/composer/:name',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.composer(state.pathParameters['name']!),
          ),
        ),
      ),
      GoRoute(
        path: '/collection/:kind',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.named(state.pathParameters['kind']!),
          ),
        ),
      ),
      GoRoute(
        path: '/smart/:kind',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongCollectionScreen(
            source: CollectionSource.smart(state.pathParameters['kind']!),
          ),
        ),
      ),

      // Fuentes remotas (requerimiento seccion 10), fuera de la biblioteca
      // local a proposito.
      GoRoute(
        path: '/remote-sources',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const RemoteSourcesScreen()),
      ),
      GoRoute(
        path: '/remote/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          RemoteBrowserScreen(
            sourceId: int.parse(state.pathParameters['id']!),
            title: state.uri.queryParameters['name'] ?? 'Fuente remota',
          ),
        ),
      ),

      GoRoute(
        path: '/playlist/:id',
        parentNavigatorKey: rootNavigatorKey,
        // Las listas regalo (requerimiento "playlist regalo") se presentan
        // primero con su dedicatoria; `?from=gift-intro` evita el loop una
        // vez que el usuario ya vio esa pantalla y pulsa "Reproducir".
        redirect: (context, state) {
          if (state.uri.queryParameters['from'] == 'gift-intro') return null;
          final id = int.parse(state.pathParameters['id']!);
          final container = ProviderScope.containerOf(context);
          final playlists = container.read(playlistsProvider).valueOrNull;
          final playlist = playlists
              ?.where((item) => item.id == id)
              .firstOrNull;
          if (playlist != null && playlist.giftMode) {
            return '/playlist/$id/gift';
          }
          return null;
        },
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          PlaylistDetailScreen(
            playlistId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      // Asistente de recepcion de un regalo. `uri` llega cuando el archivo se
      // abre desde otra aplicacion; sin el, el asistente pide elegirlo.
      GoRoute(
        path: '/gift/receive',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          GiftReceiveWizard(initialUri: state.uri.queryParameters['uri']),
        ),
      ),
      GoRoute(
        path: '/playlist/:id/gift',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          GiftIntroScreen(playlistId: int.parse(state.pathParameters['id']!)),
        ),
      ),

      GoRoute(
        path: '/song/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          SongEditorScreen(songId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/batch-edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          BatchEditorScreen(songIds: (state.extra as List<int>?) ?? const []),
        ),
      ),

      // Descargas desde internet (feature "Buscar y descargar canciones").
      // Las descargas terminadas aparecen solas en la biblioteca (escritas
      // directamente en MediaStore.Audio), asi que no hace falta una lista
      // aparte: esta es la unica pantalla.
      GoRoute(
        path: '/downloads',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const SongSearchScreen()),
      ),
      GoRoute(
        path: '/downloads/youtube-login',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const YouTubeLoginScreen()),
      ),

      // Personalización
      GoRoute(
        path: '/settings/appearance',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          // `?tab=` sigue existiendo solo para los accesos antiguos a
          // Movimiento y Widget, que ya no cuelgan de Apariencia.
          final tab = state.uri.queryParameters['tab'];
          final screen = tab == null
              ? const AppThemeScreen()
              : AppearanceScreen(initialTab: AppearanceTab.byId(tab));
          return buildFadeSlidePage(context, state, screen);
        },
      ),
      GoRoute(
        path: '/settings/player',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const AppearanceScreen(initialTab: AppearanceTab.player),
        ),
      ),
      GoRoute(
        path: '/settings/player/visualizer',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const AppearanceScreen(initialTab: AppearanceTab.player),
        ),
      ),
      GoRoute(
        path: '/settings/player/visualizer/colors',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const VisualizerColorMapScreen(),
        ),
      ),

      // Configuración
      GoRoute(
        path: '/settings/controls',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const ControlsAndGesturesScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/controls/layout',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const ControlLayoutScreen()),
      ),
      GoRoute(
        path: '/settings/playback',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const PlaybackAudioSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/library',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const LibrarySettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/library/metadata-lookup',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const MetadataLookupScreen()),
      ),
      GoRoute(
        path: '/settings/sources',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const SourcesSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/widget',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const AppearanceScreen(initialTab: AppearanceTab.widget),
        ),
      ),
      GoRoute(
        path: '/settings/system',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const SystemSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/system/devices',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const DevicesSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/system/data',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const DataFilesSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/system/diagnostics',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const DiagnosticsSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/system/about',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const AboutSettingsScreen()),
      ),

      // Rutas antiguas: se conservan como redirección para no romper accesos
      // directos ya existentes.
      GoRoute(
        path: '/settings/theme',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/settings/appearance',
      ),
      GoRoute(
        path: '/settings/widgets',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/settings/widget',
      ),
      GoRoute(
        path: '/settings/control',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/settings/controls',
      ),
      GoRoute(
        path: '/settings/control/layout',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/settings/controls/layout',
      ),
      GoRoute(
        path: '/settings/audio',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/settings/playback',
      ),
      GoRoute(
        path: '/settings/data',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/settings/system/data',
      ),
      GoRoute(
        path: '/settings/excluded-folders',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const ExcludedFoldersScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/source-folders',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const SourceFoldersScreen()),
      ),
      GoRoute(
        path: '/settings/playback-failure-log',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeSlidePage(
          context,
          state,
          const PlaybackFailureLogScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/video-match-log',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(context, state, const VideoMatchLogScreen()),
      ),
    ],
  );
}
