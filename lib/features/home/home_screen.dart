import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/repositories/library_repository.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/glass.dart';
import 'package:nuvtune/shared/widgets/song_actions_sheet.dart';
import 'package:nuvtune/shared/widgets/song_tile.dart';

/// Pantalla Inicio con las secciones configurables del requerimiento
/// seccion 11.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final enabledSections = _sectionsOf(settings);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Tokens.gutter,
        title: const _HomeTitle(),
        actions: [
          IconButton(
            tooltip: AppStrings.equalizer,
            icon: const Icon(Icons.graphic_eq_rounded),
            onPressed: () => context.push('/equalizer'),
          ),
          IconButton(
            tooltip: 'Configurar secciones',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSectionSettings(context, ref, enabledSections),
          ),
          const SizedBox(width: Tokens.space1),
        ],
      ),
      body: library.isEmpty
          ? EmptyState(
              icon: Icons.library_music_outlined,
              title: library.isScanning
                  ? AppStrings.scanning
                  : AppStrings.emptyLibrary,
              message: library.isScanning ? null : AppStrings.emptyLibraryHint,
              actionLabel: library.isScanning ? null : AppStrings.rescanLibrary,
              onAction: library.isScanning
                  ? null
                  : () => ref.read(libraryProvider.notifier).scan(force: true),
            )
          : _HomeBody(
              sections: enabledSections,
              songs: library.songs,
              buildSection: (section) =>
                  _buildSection(context, ref, section, library.songs),
            ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    HomeSection section,
    List<Song> allSongs,
  ) {
    final repository = ref.watch(libraryRepositoryProvider);

    switch (section) {
      case HomeSection.continueListening:
        final current = ref.watch(
          playbackProvider.select((state) => state.currentSong),
        );
        if (current == null) return const SizedBox.shrink();
        return _ContinueCard(song: current);

      case HomeSection.favorites:
        final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
        final songs = allSongs.where((song) => ids.contains(song.id)).toList();
        return _SongRow(
          title: AppStrings.homeFavorites,
          route: '/collection/favorites',
          songs: songs,
        );

      case HomeSection.recentlyPlayed:
        final ids = ref.watch(recentlyPlayedIdsProvider).valueOrNull ?? const [];
        return _SongRow(
          title: AppStrings.homeRecentlyPlayed,
          route: '/collection/recently-played',
          songs: repository.songsByIds(ids),
        );

      case HomeSection.recentAlbums:
        return _AlbumRow(
          title: AppStrings.homeRecentAlbums,
          albums: repository.recentAlbums(),
        );

      case HomeSection.mostPlayed:
        final ids = ref.watch(mostPlayedIdsProvider).valueOrNull ?? const [];
        return _SongRow(
          title: AppStrings.homeMostPlayed,
          route: '/collection/most-played',
          songs: repository.songsByIds(ids),
        );

      case HomeSection.featuredPlaylists:
        final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
        final counts =
            ref.watch(playlistSongCountsProvider).valueOrNull ?? const {};
        if (playlists.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: AppStrings.homeFeaturedPlaylists,
              actionLabel: 'Ver todas',
              onAction: () => context.go('/playlists'),
            ),
            for (final playlist in playlists.take(4))
              ListTile(
                leading: GroupCover(
                  song: null,
                  customPath: playlist.coverPath,
                  size: 48,
                  borderRadius: 12,
                  icon: Icons.queue_music_rounded,
                ),
                title: Text(playlist.name),
                subtitle: Text(
                  Formatters.trackCount(counts[playlist.id] ?? 0),
                ),
                onTap: () => context.push('/playlist/${playlist.id}'),
              ),
          ],
        );
    }
  }

  List<HomeSection> _sectionsOf(AppSetting? settings) {
    if (settings == null) return HomeSection.values;
    final decoded = _decodeSections(settings.homeSectionsJson);
    return decoded.isEmpty ? HomeSection.values : decoded;
  }

  static List<HomeSection> _decodeSections(String source) {
    // El JSON guarda las claves de las secciones activas, en orden.
    final decoded = jsonDecode(source);
    if (decoded is! List) return const [];
    return decoded
        .whereType<String>()
        .map(HomeSection.fromKey)
        .whereType<HomeSection>()
        .toList();
  }

  void _showSectionSettings(
    BuildContext context,
    WidgetRef ref,
    List<HomeSection> enabled,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _SectionSettingsSheet(enabled: enabled),
    );
  }
}

/// Marca de la aplicación en la barra superior, con el degradado de identidad.
class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GradientText(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          AppStrings.tagline,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Cuerpo de Inicio.
///
/// Las secciones sin datos se colapsan, de modo que una biblioteca recién
/// escaneada dejaba la pantalla practicamente vacía. Aquí se cuenta cuántas
/// quedan visibles y, si son muy pocas, se completa con material que existe
/// desde el primer escaneo y no necesita historial.
class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.sections,
    required this.songs,
    required this.buildSection,
  });

  final List<HomeSection> sections;
  final List<Song> songs;
  final Widget Function(HomeSection) buildSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(libraryRepositoryProvider);
    final playCounts = ref.watch(playCountsProvider).valueOrNull ?? const {};
    final favorites = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};

    // Una seccion se considera con contenido si su fuente tiene elementos.
    final populated = sections.where((section) {
      return switch (section) {
        HomeSection.continueListening => ref.watch(
          playbackProvider.select((state) => state.currentSong != null),
        ),
        HomeSection.favorites => favorites.isNotEmpty,
        HomeSection.recentlyPlayed => playCounts.isNotEmpty,
        HomeSection.recentAlbums => repository.recentAlbums().isNotEmpty,
        HomeSection.mostPlayed => playCounts.isNotEmpty,
        HomeSection.featuredPlaylists =>
          (ref.watch(playlistsProvider).valueOrNull ?? const []).isNotEmpty,
      };
    }).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        for (final section in sections) buildSection(section),

        // Relleno honesto: no inventa datos, muestra lo que ya hay.
        if (populated < _minimumSections) ...[
          _SongRow(
            title: AppStrings.recentlyAdded,
            route: '/collection/recently-added',
            songs: repository.recentlyAdded(limit: 12),
          ),
          _ArtistRow(artists: repository.artists()),
        ],
      ],
    );
  }

  /// Por debajo de esto la pantalla se ve rota, no minimalista.
  static const _minimumSections = 3;
}

/// Fila horizontal de artistas, con la inicial dentro de un circulo de acento.
class _ArtistRow extends StatelessWidget {
  const _ArtistRow({required this.artists});

  final List<SongGroup> artists;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) return const SizedBox.shrink();
    final accent = ThemeScope.of(context).accent;
    final visible = artists.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: AppStrings.homeArtists),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            itemCount: visible.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: Tokens.space3),
            itemBuilder: (context, index) {
              final artist = visible[index];
              return SizedBox(
                width: 84,
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () => context.push('/artist/${artist.key}'),
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accent.start.withValues(alpha: 0.55),
                              accent.end.withValues(alpha: 0.35),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          artist.title.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Tokens.space2),
                    Text(
                      artist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Secciones de Inicio, en el orden del requerimiento seccion 11.
enum HomeSection {
  continueListening('continue'),
  favorites('favorites'),
  recentlyPlayed('recentlyPlayed'),
  recentAlbums('recentAlbums'),
  mostPlayed('mostPlayed'),
  featuredPlaylists('featuredPlaylists');

  const HomeSection(this.key);

  final String key;

  String get label => switch (this) {
        HomeSection.continueListening => AppStrings.homeContinue,
        HomeSection.favorites => AppStrings.homeFavorites,
        HomeSection.recentlyPlayed => AppStrings.homeRecentlyPlayed,
        HomeSection.recentAlbums => AppStrings.homeRecentAlbums,
        HomeSection.mostPlayed => AppStrings.homeMostPlayed,
        HomeSection.featuredPlaylists => AppStrings.homeFeaturedPlaylists,
      };

  static HomeSection? fromKey(String key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}

class _SectionSettingsSheet extends ConsumerWidget {
  const _SectionSettingsSheet({required this.enabled});

  final List<HomeSection> enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Secciones de Inicio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          for (final section in HomeSection.values)
            SwitchListTile(
              title: Text(section.label),
              value: enabled.contains(section),
              onChanged: (value) {
                final updated = HomeSection.values
                    .where(
                      (item) => item == section
                          ? value
                          : enabled.contains(item),
                    )
                    .map((item) => item.key)
                    .toList();
                ref
                    .read(settingsRepositoryProvider)
                    .saveHomeSections(updated);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/player'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CoverArt(song: song, size: 74, borderRadius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.homeContinue,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: ref.read(playbackProvider.notifier).togglePlayPause,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SongRow extends ConsumerWidget {
  const _SongRow({
    required this.title,
    required this.route,
    required this.songs,
  });

  final String title;
  final String route;
  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) return const SizedBox.shrink();

    final visible = songs.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: songs.length > visible.length ? 'Ver todo' : null,
          onAction: songs.length > visible.length
              ? () => context.push(route)
              : null,
        ),
        for (final song in visible)
          SongTile(
            song: song,
            dense: true,
            onTap: () =>
                ref.read(playbackProvider.notifier).playSong(song, within: songs),
            onMore: () =>
                showSongActions(context, song: song, contextSongs: songs),
          ),
      ],
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.title, required this.albums});

  final String title;
  final List<SongGroup> albums;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: albums.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final album = albums[index];
              return SizedBox(
                width: 140,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/album/${album.key}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GroupCover(song: album.coverSong, size: 140),
                      const SizedBox(height: 8),
                      Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        album.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
