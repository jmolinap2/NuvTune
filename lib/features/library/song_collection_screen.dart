import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/repositories/library_repository.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/playlists/m3u.dart';
import 'package:nuvtune/features/playlists/smart_playlists.dart';
import 'package:nuvtune/shared/widgets/add_to_playlist_sheet.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/song_actions_sheet.dart';
import 'package:nuvtune/shared/widgets/song_tile.dart';
import 'package:nuvtune/shared/widgets/sort_filter_bar.dart';

enum CollectionKind {
  album,
  artist,
  folder,
  genre,
  composer,
  favorites,
  recentlyPlayed,
  mostPlayed,
  recentlyAdded,
  smart,
}

/// Identifica el conjunto de canciones que muestra [SongCollectionScreen].
class CollectionSource {
  const CollectionSource._(this.kind, {this.id, this.name});

  const CollectionSource.album(int albumId)
      : this._(CollectionKind.album, id: albumId);

  const CollectionSource.artist(int artistId)
      : this._(CollectionKind.artist, id: artistId);

  const CollectionSource.folder(String path)
      : this._(CollectionKind.folder, name: path);

  const CollectionSource.genre(String genre)
      : this._(CollectionKind.genre, name: genre);

  const CollectionSource.composer(String composer)
      : this._(CollectionKind.composer, name: composer);

  const CollectionSource.smart(String key)
      : this._(CollectionKind.smart, name: key);

  /// Colecciones con nombre fijo que aparecen en Inicio y en la biblioteca.
  factory CollectionSource.named(String kind) => switch (kind) {
        'favorites' => const CollectionSource._(CollectionKind.favorites),
        'recently-played' =>
          const CollectionSource._(CollectionKind.recentlyPlayed),
        'most-played' => const CollectionSource._(CollectionKind.mostPlayed),
        _ => const CollectionSource._(CollectionKind.recentlyAdded),
      };

  final CollectionKind kind;
  final int? id;
  final String? name;
}

/// Pantalla generica de lista de canciones: album, artista, carpeta, genero,
/// compositor, colección con nombre o lista inteligente.
///
/// Una sola pantalla para todas porque el requerimiento pide las mismas
/// acciones en cada vista (seccion 4.1) y duplicarla siete veces solo abriria
/// siete sitios donde arreglar cada cambio.
class SongCollectionScreen extends ConsumerStatefulWidget {
  const SongCollectionScreen({required this.source, super.key});

  final CollectionSource source;

  @override
  ConsumerState<SongCollectionScreen> createState() =>
      _SongCollectionScreenState();
}

class _SongCollectionScreenState extends ConsumerState<SongCollectionScreen> {
  String _search = '';
  SongSort _sort = SongSort.trackNumber;
  SortDirection _direction = SortDirection.ascending;
  final _selection = <int>{};

  @override
  void initState() {
    super.initState();
    // Los albumes se leen en orden de pista; el resto por titulo.
    _sort = widget.source.kind == CollectionKind.album
        ? SongSort.trackNumber
        : SongSort.title;
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final repository = ref.read(libraryRepositoryProvider);
    final playCounts = ref.watch(playCountsProvider).valueOrNull ?? const {};

    final resolved = _resolveSongs(repository, library.songs, playCounts);
    final title = _resolveTitle(resolved);

    // Las colecciónes ordenadas por relevancia conservan su propio orden; en el
    // resto manda la eleccion del usuario.
    final ordered = _keepsOwnOrder
        ? _applySearch(resolved)
        : repository.query(
            source: resolved,
            search: _search,
            sort: _sort,
            direction: _direction,
          );

    final isSelecting = _selection.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelecting ? '${_selection.length} seleccionadas' : title),
        leading: isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(_selection.clear),
              )
            : null,
        actions: isSelecting
            ? [
                IconButton(
                  tooltip: AppStrings.editSeveralSongs,
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: () => context.push(
                    '/batch-edit',
                    extra: _selection.toList(),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.addToPlaylist,
                  icon: const Icon(Icons.playlist_add_rounded),
                  onPressed: () => showAddToPlaylistSheet(
                    context,
                    songIds: _selection.toList(),
                  ),
                ),
              ]
            : [
                IconButton(
                  tooltip: AppStrings.share,
                  icon: const Icon(Icons.share_rounded),
                  onPressed: ordered.isEmpty
                      ? null
                      : () => ref.read(engineProvider).api.shareText(
                            title,
                            M3u.plainListing(title, ordered),
                          ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _onMenuSelected(value, ordered),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'queue',
                      child: Text(AppStrings.addToQueue),
                    ),
                    const PopupMenuItem(
                      value: 'playlist',
                      child: Text(AppStrings.addToPlaylist),
                    ),
                    const PopupMenuItem(
                      value: 'select',
                      child: Text(AppStrings.editSeveralSongs),
                    ),
                  ],
                ),
              ],
      ),
      body: library.isEmpty && library.isScanning
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_showsHeader)
                  SliverToBoxAdapter(
                    child: _CollectionHeader(
                      title: title,
                      subtitle: _resolveSubtitle(resolved),
                      coverSong: resolved.firstWhere(
                        (song) => song.hasCover,
                        orElse: () => resolved.first,
                      ),
                    ),
                  ),
                if (_description != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        _description!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SortFilterBar(
                    search: _search,
                    onSearchChanged: (value) => setState(() => _search = value),
                    sort: _keepsOwnOrder ? null : _sort,
                    direction: _keepsOwnOrder ? null : _direction,
                    onSortChanged: _keepsOwnOrder
                        ? null
                        : (sort, direction) => setState(() {
                              _sort = sort;
                              _direction = direction;
                            }),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PlayAllHeader(
                    count: ordered.length,
                    subtitle: ordered.isEmpty
                        ? null
                        : '${Formatters.trackCount(ordered.length)} · '
                            '${Formatters.durationVerbose(
                            ordered.fold(0, (sum, song) => sum + song.durationMs),
                          )}',
                    onPlayAll: () =>
                        ref.read(playbackProvider.notifier).playSongs(ordered),
                    onShuffleAll: () => ref
                        .read(playbackProvider.notifier)
                        .playSongs(ordered, shuffle: true),
                  ),
                ),
                if (ordered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.music_off_rounded,
                      title: _search.isEmpty
                          ? 'Esta colección está vacía'
                          : AppStrings.noResults,
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: ordered.length,
                    itemBuilder: (context, index) {
                      final song = ordered[index];
                      final selected = _selection.contains(song.id);
                      return SongTile(
                        song: song,
                        subtitleOverride: _subtitleForSong(song, playCounts),
                        onTap: isSelecting
                            ? () => _toggleSelection(song.id)
                            : () => ref
                                .read(playbackProvider.notifier)
                                .playSong(song, within: ordered),
                        onMore: isSelecting
                            ? null
                            : () => showSongActions(
                                  context,
                                  song: song,
                                  contextSongs: ordered,
                                ),
                        trailing: isSelecting
                            ? Checkbox(
                                value: selected,
                                onChanged: (_) => _toggleSelection(song.id),
                              )
                            : null,
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  void _toggleSelection(int songId) => setState(() {
        if (!_selection.remove(songId)) {
          _selection.add(songId);
        }
      });

  void _onMenuSelected(String value, List<Song> songs) {
    switch (value) {
      case 'queue':
        ref.read(playbackProvider.notifier).addToQueue(songs);
      case 'playlist':
        showAddToPlaylistSheet(
          context,
          songIds: songs.map((song) => song.id).toList(),
        );
      case 'select':
        setState(() => _selection.addAll(songs.take(1).map((song) => song.id)));
    }
  }

  /// Las colecciónes cuyo orden es el resultado de la consulta no se reordenan.
  bool get _keepsOwnOrder => switch (widget.source.kind) {
        CollectionKind.recentlyPlayed => true,
        CollectionKind.mostPlayed => true,
        CollectionKind.recentlyAdded => true,
        CollectionKind.favorites => true,
        CollectionKind.smart => true,
        _ => false,
      };

  bool get _showsHeader => switch (widget.source.kind) {
        CollectionKind.album => true,
        CollectionKind.artist => true,
        _ => false,
      };

  String? get _description => widget.source.kind == CollectionKind.smart
      ? SmartPlaylist.fromKey(widget.source.name ?? '')?.description
      : null;

  List<Song> _applySearch(List<Song> songs) {
    if (_search.trim().isEmpty) return songs;
    final needle = _search.trim().toLowerCase();
    return songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(needle) ||
              song.artist.toLowerCase().contains(needle) ||
              song.album.toLowerCase().contains(needle),
        )
        .toList();
  }

  String? _subtitleForSong(Song song, Map<int, int> playCounts) {
    if (widget.source.kind == CollectionKind.mostPlayed ||
        widget.source.name == SmartPlaylist.playedMoreThanFive.key) {
      final count = playCounts[song.id] ?? 0;
      return '${song.displayArtist} · $count reproducciones';
    }
    if (widget.source.kind == CollectionKind.album) {
      final track = song.trackNumber;
      final prefix = track == null ? '' : '$track · ';
      return '$prefix${Formatters.duration(song.durationMs)}';
    }
    if (widget.source.kind == CollectionKind.recentlyAdded ||
        widget.source.name == SmartPlaylist.addedThisWeek.key) {
      return '${song.displayArtist} · ${Formatters.epochDate(song.dateAdded)}';
    }
    return null;
  }

  List<Song> _resolveSongs(
    LibraryRepository repository,
    List<Song> allSongs,
    Map<int, int> playCounts,
  ) {
    switch (widget.source.kind) {
      case CollectionKind.album:
        return repository.albumById(widget.source.id!)?.songs ?? const [];
      case CollectionKind.artist:
        return repository.artistById(widget.source.id!)?.songs ?? const [];
      case CollectionKind.folder:
        return repository.folderByPath(widget.source.name!)?.songs ?? const [];
      case CollectionKind.genre:
        return repository
                .genres()
                .where((group) => group.key == widget.source.name)
                .firstOrNull
                ?.songs ??
            const [];
      case CollectionKind.composer:
        return repository
                .composers()
                .where((group) => group.key == widget.source.name)
                .firstOrNull
                ?.songs ??
            const [];
      case CollectionKind.favorites:
        final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
        return allSongs.where((song) => ids.contains(song.id)).toList();
      case CollectionKind.recentlyPlayed:
        final ids = ref.watch(recentlyPlayedIdsProvider).valueOrNull ?? const [];
        return repository.songsByIds(ids);
      case CollectionKind.mostPlayed:
        final ids = ref.watch(mostPlayedIdsProvider).valueOrNull ?? const [];
        return repository.songsByIds(ids);
      case CollectionKind.recentlyAdded:
        return repository.recentlyAdded(limit: 100);
      case CollectionKind.smart:
        final smart = SmartPlaylist.fromKey(widget.source.name ?? '');
        return smart?.resolve(allSongs, playCounts) ?? const [];
    }
  }

  String _resolveTitle(List<Song> songs) => switch (widget.source.kind) {
        CollectionKind.album => songs.firstOrNull?.displayAlbum ?? 'Álbum',
        CollectionKind.artist => songs.firstOrNull?.displayArtist ?? 'Artista',
        CollectionKind.folder =>
          songs.firstOrNull?.folderName ?? _lastPathSegment(widget.source.name),
        CollectionKind.genre => widget.source.name ?? 'Género',
        CollectionKind.composer => widget.source.name ?? 'Compositor',
        CollectionKind.favorites => AppStrings.homeFavorites,
        CollectionKind.recentlyPlayed => AppStrings.homeRecentlyPlayed,
        CollectionKind.mostPlayed => AppStrings.homeMostPlayed,
        CollectionKind.recentlyAdded => AppStrings.recentlyAdded,
        CollectionKind.smart =>
          SmartPlaylist.fromKey(widget.source.name ?? '')?.label ?? 'Lista',
      };

  String _resolveSubtitle(List<Song> songs) => switch (widget.source.kind) {
        CollectionKind.album => songs.firstOrNull?.displayAlbumArtist ?? '',
        CollectionKind.artist => Formatters.albumCount(
            songs.map((song) => song.albumId).toSet().length,
          ),
        _ => '',
      };

  static String _lastPathSegment(String? path) =>
      path == null || path.isEmpty ? 'Carpeta' : path.split('/').last;
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.title,
    required this.subtitle,
    required this.coverSong,
  });

  final String title;
  final String subtitle;
  final Song coverSong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CoverArt(song: coverSong, size: 128, borderRadius: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
