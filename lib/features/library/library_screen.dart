import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/repositories/library_repository.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/playlists/playlists_list.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/song_actions_sheet.dart';
import 'package:nuvtune/shared/widgets/song_tile.dart';
import 'package:nuvtune/shared/widgets/sort_filter_bar.dart';

/// Pantalla Biblioteca con las cinco pestanas del requerimiento seccion 11.
///
/// Generos y compositores se abren desde el menu de la barra superior: la
/// pantalla Biblioteca del requerimiento define cinco pestanas, asi que estas
/// dos agrupaciones entran como vistas derivadas y no como pestanas propias.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navLibrary),
        actions: [
          IconButton(
            tooltip: AppStrings.rescanLibrary,
            icon: library.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: library.isScanning
                ? null
                : () => ref.read(libraryProvider.notifier).scan(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'genres' => _showGroups(context, GroupKind.genre),
              'composers' => _showGroups(context, GroupKind.composer),
              'recently-added' => context.push('/collection/recently-added'),
              _ => null,
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'genres', child: Text(AppStrings.genres)),
              PopupMenuItem(
                value: 'composers',
                child: Text(AppStrings.composers),
              ),
              PopupMenuItem(
                value: 'recently-added',
                child: Text(AppStrings.recentlyAdded),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: AppStrings.tabSongs),
            Tab(text: AppStrings.tabAlbums),
            Tab(text: AppStrings.tabArtists),
            Tab(text: AppStrings.tabFolders),
            Tab(text: AppStrings.tabPlaylists),
          ],
        ),
      ),
      body: library.isEmpty
          ? _emptyBody(library.isScanning)
          : TabBarView(
              controller: _tabController,
              children: const [
                _SongsTab(),
                _AlbumsTab(),
                _GroupsTab(kind: GroupKind.artist),
                _GroupsTab(kind: GroupKind.folder),
                PlaylistsList(),
              ],
            ),
    );
  }

  Widget _emptyBody(bool isScanning) {
    if (isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(AppStrings.scanning),
          ],
        ),
      );
    }
    return EmptyState(
      icon: Icons.library_music_outlined,
      title: AppStrings.emptyLibrary,
      message: AppStrings.emptyLibraryHint,
      actionLabel: AppStrings.rescanLibrary,
      onAction: () => ref.read(libraryProvider.notifier).scan(force: true),
    );
  }

  void _showGroups(BuildContext context, GroupKind kind) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GroupPickerSheet(kind: kind),
    );
  }
}

enum GroupKind { artist, folder, genre, composer }

// ---------------------------------------------------------------------------
// Pestana Canciones
// ---------------------------------------------------------------------------

class _SongsTab extends ConsumerStatefulWidget {
  const _SongsTab();

  @override
  ConsumerState<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<_SongsTab>
    with AutomaticKeepAliveClientMixin {
  String _search = '';
  SongSort _sort = SongSort.title;
  SortDirection _direction = SortDirection.ascending;
  SongFilter _filter = SongFilter.all;
  bool _restored = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // El orden y el filtro se recuerdan entre sesiones (requerimiento 4.1).
    _restoreState();
  }

  Future<void> _restoreState() async {
    final saved = await ref.read(settingsRepositoryProvider).librarySortState();
    final songs = saved['songs'];
    if (songs is Map && mounted) {
      setState(() {
        _sort = SongSort.values.firstWhere(
          (value) => value.name == songs['sort'],
          orElse: () => SongSort.title,
        );
        _direction = songs['descending'] == true
            ? SortDirection.descending
            : SortDirection.ascending;
        _filter = SongFilter.values.firstWhere(
          (value) => value.name == songs['filter'],
          orElse: () => SongFilter.all,
        );
        _restored = true;
      });
    } else if (mounted) {
      setState(() => _restored = true);
    }
  }

  Future<void> _persistState() async {
    if (!_restored) return;
    final repository = ref.read(settingsRepositoryProvider);
    final state = await repository.librarySortState();
    state['songs'] = {
      'sort': _sort.name,
      'descending': _direction == SortDirection.descending,
      'filter': _filter.name,
    };
    await repository.saveLibrarySortState(state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final library = ref.watch(libraryProvider);
    final favorites = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final playCounts = ref.watch(playCountsProvider).valueOrNull ?? const {};

    final songs = ref.read(libraryRepositoryProvider).query(
          source: library.songs,
          search: _search,
          sort: _sort,
          direction: _direction,
          filter: _filter,
          favoriteIds: favorites,
          playCounts: playCounts,
        );

    return Column(
      children: [
        SortFilterBar(
          search: _search,
          onSearchChanged: (value) => setState(() => _search = value),
          sort: _sort,
          direction: _direction,
          onSortChanged: (sort, direction) {
            setState(() {
              _sort = sort;
              _direction = direction;
            });
            _persistState();
          },
          filter: _filter,
          onFilterChanged: (filter) {
            setState(() => _filter = filter);
            _persistState();
          },
        ),
        PlayAllHeader(
          count: songs.length,
          onPlayAll: () => ref.read(playbackProvider.notifier).playSongs(songs),
          onShuffleAll: () => ref
              .read(playbackProvider.notifier)
              .playSongs(songs, shuffle: true),
        ),
        Expanded(
          child: songs.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: AppStrings.noResults,
                )
              : ListView.builder(
                  // Carga paginada por construccion: ListView.builder solo crea
                  // las filas visibles (requerimiento seccion 17).
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return SongTile(
                      song: song,
                      onTap: () => ref
                          .read(playbackProvider.notifier)
                          .playSong(song, within: songs),
                      onMore: () => showSongActions(
                        context,
                        song: song,
                        contextSongs: songs,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pestana Albumes
// ---------------------------------------------------------------------------

class _AlbumsTab extends ConsumerStatefulWidget {
  const _AlbumsTab();

  @override
  ConsumerState<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends ConsumerState<_AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  String _search = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.watch(libraryProvider);
    final albums = ref.read(libraryRepositoryProvider).albums(search: _search);

    return Column(
      children: [
        SortFilterBar(
          search: _search,
          onSearchChanged: (value) => setState(() => _search = value),
        ),
        Expanded(
          child: albums.isEmpty
              ? const EmptyState(
                  icon: Icons.album_outlined,
                  title: AppStrings.noResults,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return _AlbumCard(album: album);
                  },
                ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final SongGroup album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/album/${album.key}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) => GroupCover(
                song: album.coverSong,
                size: constraints.maxWidth,
                borderRadius: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 2),
          Text(
            album.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestanas Artistas y Carpetas
// ---------------------------------------------------------------------------

class _GroupsTab extends ConsumerStatefulWidget {
  const _GroupsTab({required this.kind});

  final GroupKind kind;

  @override
  ConsumerState<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<_GroupsTab>
    with AutomaticKeepAliveClientMixin {
  String _search = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.watch(libraryProvider);
    final groups = resolveGroups(
      ref.read(libraryRepositoryProvider),
      widget.kind,
      _search,
    );

    return Column(
      children: [
        SortFilterBar(
          search: _search,
          onSearchChanged: (value) => setState(() => _search = value),
        ),
        Expanded(
          child: groups.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: AppStrings.noResults,
                )
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return GroupTile(
                      title: group.title,
                      subtitle: widget.kind == GroupKind.folder
                          ? '${Formatters.trackCount(group.songs.length)} · ${group.subtitle}'
                          : group.subtitle,
                      coverSong: group.coverSong,
                      icon: widget.kind == GroupKind.folder
                          ? Icons.folder_rounded
                          : Icons.person_rounded,
                      onTap: () => context.push(routeForGroup(widget.kind, group)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

List<SongGroup> resolveGroups(
  LibraryRepository repository,
  GroupKind kind,
  String search,
) =>
    switch (kind) {
      GroupKind.artist => repository.artists(search: search),
      GroupKind.folder => repository.folders(search: search),
      GroupKind.genre => repository.genres(search: search),
      GroupKind.composer => repository.composers(search: search),
    };

String routeForGroup(GroupKind kind, SongGroup group) => switch (kind) {
      GroupKind.artist => '/artist/${group.key}',
      GroupKind.folder => '/folder?path=${Uri.encodeQueryComponent(group.key)}',
      GroupKind.genre => '/genre/${Uri.encodeComponent(group.key)}',
      GroupKind.composer => '/composer/${Uri.encodeComponent(group.key)}',
    };

/// Hoja para elegir un genero o un compositor.
class _GroupPickerSheet extends ConsumerStatefulWidget {
  const _GroupPickerSheet({required this.kind});

  final GroupKind kind;

  @override
  ConsumerState<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends ConsumerState<_GroupPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final groups = resolveGroups(
      ref.read(libraryRepositoryProvider),
      widget.kind,
      _search,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              widget.kind == GroupKind.genre
                  ? AppStrings.genres
                  : AppStrings.composers,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SortFilterBar(
            search: _search,
            onSearchChanged: (value) => setState(() => _search = value),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: Icon(
                    widget.kind == GroupKind.genre
                        ? Icons.category_rounded
                        : Icons.edit_note_rounded,
                  ),
                  title: Text(group.title),
                  subtitle: Text(group.subtitle),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(routeForGroup(widget.kind, group));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
