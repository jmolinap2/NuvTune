import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/navigation/root_shell.dart';
import 'package:nuvtune/features/equalizer/equalizer_screen.dart';
import 'package:nuvtune/features/home/home_screen.dart';
import 'package:nuvtune/features/library/library_screen.dart';
import 'package:nuvtune/features/library/song_collection_screen.dart';
import 'package:nuvtune/features/metadata_editor/batch_editor_screen.dart';
import 'package:nuvtune/features/metadata_editor/song_editor_screen.dart';
import 'package:nuvtune/features/player/player_screen.dart';
import 'package:nuvtune/features/playlists/playlist_detail_screen.dart';
import 'package:nuvtune/features/playlists/playlists_screen.dart';
import 'package:nuvtune/features/queue/queue_screen.dart';
import 'package:nuvtune/features/remote_sources/remote_sources_screen.dart';
import 'package:nuvtune/features/settings/appearance_screen.dart';
import 'package:nuvtune/features/settings/folders_screen.dart';
import 'package:nuvtune/features/settings/settings_screen.dart';
import 'package:nuvtune/features/settings/widgets_screen.dart';

/// Rutas de la aplicacion.
///
/// Las cuatro secciones de la navegacion inferior son ramas de un
/// StatefulShellRoute, de modo que cada una conserva su propia pila y su
/// posicion de desplazamiento al cambiar de pestana (requerimiento seccion 4.1).
/// Las pantallas que se abren encima, como el reproductor completo o el editor,
/// van fuera del shell para que ocupen toda la altura.
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
        builder: (context, state) => const PlayerScreen(),
      ),
      GoRoute(
        path: '/queue',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const QueueScreen(),
      ),
      GoRoute(
        path: '/equalizer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EqualizerScreen(),
      ),

      GoRoute(
        path: '/album/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.album(
            int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/artist/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.artist(
            int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/folder',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.folder(
            state.uri.queryParameters['path'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/genre/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.genre(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        path: '/composer/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.composer(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        path: '/collection/:kind',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.named(state.pathParameters['kind']!),
        ),
      ),
      GoRoute(
        path: '/smart/:kind',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongCollectionScreen(
          source: CollectionSource.smart(state.pathParameters['kind']!),
        ),
      ),

      // Fuentes remotas (requerimiento seccion 10), fuera de la biblioteca
      // local a proposito.
      GoRoute(
        path: '/remote-sources',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RemoteSourcesScreen(),
      ),
      GoRoute(
        path: '/remote/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => RemoteBrowserScreen(
          sourceId: int.parse(state.pathParameters['id']!),
          title: state.uri.queryParameters['name'] ?? 'Fuente remota',
        ),
      ),

      GoRoute(
        path: '/playlist/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlaylistDetailScreen(
          playlistId: int.parse(state.pathParameters['id']!),
        ),
      ),

      GoRoute(
        path: '/song/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SongEditorScreen(
          songId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/batch-edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => BatchEditorScreen(
          songIds: (state.extra as List<int>?) ?? const [],
        ),
      ),

      GoRoute(
        path: '/settings/appearance',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/settings/widgets',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WidgetsScreen(),
      ),
      GoRoute(
        path: '/settings/excluded-folders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ExcludedFoldersScreen(),
      ),
      GoRoute(
        path: '/settings/source-folders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SourceFoldersScreen(),
      ),
    ],
  );
}
