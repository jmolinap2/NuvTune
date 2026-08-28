import 'package:collection/collection.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Criterios de ordenacion disponibles en la biblioteca (requerimiento 4.1).
enum SongSort {
  title('Título'),
  artist('Artista'),
  album('Álbum'),
  dateAdded('Fecha de agregado'),
  dateModified('Fecha de modificacion'),
  duration('Duración'),
  trackNumber('Número de pista'),
  fileName('Nombre de archivo'),
  folder('Carpeta');

  const SongSort(this.label);

  final String label;
}

enum SortDirection { ascending, descending }

/// Filtros que se pueden combinar con la busqueda.
enum SongFilter {
  all('Todas'),
  favorites('Favoritos'),
  lossless('Sin pérdida'),
  unplayed('Nunca reproducidas'),
  withoutCover('Sin portada'),
  unsupported('Formato no compatible');

  const SongFilter(this.label);

  final String label;
}

/// Agrupacion de canciones por album, artista, carpeta, genero o compositor.
class SongGroup {
  const SongGroup({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.songs,
  });

  /// Identificador estable para la navegacion: id de MediaStore o ruta.
  final String key;
  final String title;
  final String subtitle;
  final List<Song> songs;

  int get totalDurationMs =>
      songs.fold(0, (total, song) => total + song.durationMs);

  /// Cancion de la que se toma la portada del grupo.
  Song? get coverSong =>
      songs.firstWhereOrNull((song) => song.hasCover) ?? songs.firstOrNull;
}

/// Biblioteca musical en memoria y todas sus vistas derivadas.
///
/// El motor es la fuente de verdad de las canciones; este repositorio solo
/// agrupa, ordena y filtra. Guarda la lista para no repetir el cruce del canal
/// en cada reconstruccion de la interfaz (requerimiento seccion 17).
class LibraryRepository {
  LibraryRepository(this._engine);

  final EngineBridge _engine;

  List<Song> _songs = const [];
  Map<int, Song> _byId = const {};

  List<Song> get songs => _songs;

  Song? songById(int id) => _byId[id];

  List<Song> songsByIds(Iterable<int> ids) =>
      ids.map((id) => _byId[id]).whereType<Song>().toList();

  /// Escanea y guarda el resultado. Devuelve el numero de canciones visibles.
  Future<int> scan({
    required List<String> excludedFolders,
    bool forceFullRescan = false,
  }) async {
    await _engine.api.scanLibrary(excludedFolders, forceFullRescan);
    return refresh();
  }

  /// Relee la lista que ya tiene el motor, sin volver a escanear MediaStore.
  Future<int> refresh() async {
    final songs = await _engine.api.getSongs();
    _songs = songs;
    _byId = {for (final song in songs) song.id: song};
    return songs.length;
  }

  /// Sustituye una cancion tras editar sus etiquetas.
  void applyUpdatedSong(Song song) {
    _songs = [
      for (final existing in _songs)
        if (existing.id == song.id) song else existing,
    ];
    _byId = {..._byId, song.id: song};
  }

  // -- Ordenacion, filtro y busqueda ---------------------------------------

  List<Song> query({
    String search = '',
    SongSort sort = SongSort.title,
    SortDirection direction = SortDirection.ascending,
    SongFilter filter = SongFilter.all,
    Set<int> favoriteIds = const {},
    Map<int, int> playCounts = const {},
    List<Song>? source,
  }) {
    var result = source ?? _songs;

    if (search.trim().isNotEmpty) {
      final needle = search.trim().toLowerCase();
      result = result.where((song) {
        return song.title.toLowerCase().contains(needle) ||
            song.artist.toLowerCase().contains(needle) ||
            song.album.toLowerCase().contains(needle) ||
            (song.genre?.toLowerCase().contains(needle) ?? false) ||
            (song.composer?.toLowerCase().contains(needle) ?? false) ||
            song.folderName.toLowerCase().contains(needle);
      }).toList();
    }

    result = switch (filter) {
      SongFilter.all => result,
      SongFilter.favorites =>
        result.where((song) => favoriteIds.contains(song.id)).toList(),
      SongFilter.lossless => result.where((song) => song.isLossless).toList(),
      SongFilter.unplayed =>
        result.where((song) => (playCounts[song.id] ?? 0) == 0).toList(),
      SongFilter.withoutCover =>
        result.where((song) => !song.hasCover).toList(),
      SongFilter.unsupported =>
        result.where((song) => !song.isSupported).toList(),
    };

    return sortSongs(result, sort, direction);
  }

  List<Song> sortSongs(
    List<Song> songs,
    SongSort sort,
    SortDirection direction,
  ) {
    final sorted = [...songs];
    final comparator = switch (sort) {
      SongSort.title => (Song a, Song b) => _text(
        a.title,
      ).compareTo(_text(b.title)),
      SongSort.artist => (Song a, Song b) {
        final byArtist = _text(a.artist).compareTo(_text(b.artist));
        return byArtist != 0
            ? byArtist
            : _text(a.title).compareTo(_text(b.title));
      },
      SongSort.album => (Song a, Song b) {
        final byAlbum = _text(a.album).compareTo(_text(b.album));
        if (byAlbum != 0) return byAlbum;
        return _trackOrder(a).compareTo(_trackOrder(b));
      },
      SongSort.dateAdded => (Song a, Song b) => a.dateAdded.compareTo(
        b.dateAdded,
      ),
      SongSort.dateModified => (Song a, Song b) => a.dateModified.compareTo(
        b.dateModified,
      ),
      SongSort.duration => (Song a, Song b) => a.durationMs.compareTo(
        b.durationMs,
      ),
      SongSort.trackNumber => (Song a, Song b) => _trackOrder(
        a,
      ).compareTo(_trackOrder(b)),
      SongSort.fileName => (Song a, Song b) => _text(
        a.filePath.split('/').last,
      ).compareTo(_text(b.filePath.split('/').last)),
      SongSort.folder => (Song a, Song b) {
        final byFolder = _text(a.folderPath).compareTo(_text(b.folderPath));
        return byFolder != 0
            ? byFolder
            : _text(a.title).compareTo(_text(b.title));
      },
    };

    sorted.sort(comparator);
    if (direction == SortDirection.descending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  /// Numero de disco y pista combinados, para ordenar albumes de varios discos.
  static int _trackOrder(Song song) =>
      (song.discNumber ?? 1) * 1000 + (song.trackNumber ?? 0);

  static String _text(String value) => value.toLowerCase();

  // -- Agrupaciones --------------------------------------------------------

  List<SongGroup> albums({String search = ''}) {
    final grouped = groupBy(_songs, (Song song) => song.albumId);
    final groups = grouped.entries.map((entry) {
      final tracks = sortSongs(
        entry.value,
        SongSort.trackNumber,
        SortDirection.ascending,
      );
      final first = tracks.first;
      return SongGroup(
        key: entry.key.toString(),
        title: first.displayAlbum,
        subtitle: first.displayAlbumArtist,
        songs: tracks,
      );
    }).toList();
    return _filterGroups(groups, search);
  }

  List<SongGroup> artists({String search = ''}) {
    final grouped = groupBy(_songs, (Song song) => song.artistId);
    final groups = grouped.entries.map((entry) {
      final tracks = sortSongs(
        entry.value,
        SongSort.album,
        SortDirection.ascending,
      );
      final albumCount = tracks.map((song) => song.albumId).toSet().length;
      return SongGroup(
        key: entry.key.toString(),
        title: tracks.first.displayArtist,
        subtitle: '${_albumLabel(albumCount)} · ${_songLabel(tracks.length)}',
        songs: tracks,
      );
    }).toList();
    return _filterGroups(groups, search);
  }

  List<SongGroup> folders({String search = ''}) {
    final grouped = groupBy(_songs, (Song song) => song.folderPath);
    final groups = grouped.entries.map((entry) {
      final tracks = sortSongs(
        entry.value,
        SongSort.title,
        SortDirection.ascending,
      );
      return SongGroup(
        key: entry.key,
        title: tracks.first.folderName,
        subtitle: entry.key,
        songs: tracks,
      );
    }).toList();
    return _filterGroups(groups, search);
  }

  /// Generos y compositores se resuelven como agrupacion sobre las canciones,
  /// no como pestanas propias: la pantalla Biblioteca del requerimiento seccion
  /// 11 define cinco pestanas y estas dos entran por el menu de agrupacion.
  List<SongGroup> genres({String search = ''}) {
    final grouped = groupBy(
      _songs,
      (Song song) => song.displayGenre?.trim() ?? 'Sin género',
    );
    final groups = grouped.entries.map((entry) {
      final tracks = sortSongs(
        entry.value,
        SongSort.artist,
        SortDirection.ascending,
      );
      return SongGroup(
        key: entry.key,
        title: entry.key,
        subtitle: _songLabel(tracks.length),
        songs: tracks,
      );
    }).toList();
    return _filterGroups(groups, search);
  }

  List<SongGroup> composers({String search = ''}) {
    final grouped = groupBy(
      _songs,
      (Song song) => song.displayComposer?.trim() ?? 'Sin compositor',
    );
    final groups = grouped.entries.map((entry) {
      final tracks = sortSongs(
        entry.value,
        SongSort.album,
        SortDirection.ascending,
      );
      return SongGroup(
        key: entry.key,
        title: entry.key,
        subtitle: _songLabel(tracks.length),
        songs: tracks,
      );
    }).toList();
    return _filterGroups(groups, search);
  }

  SongGroup? albumById(int albumId) =>
      albums().firstWhereOrNull((group) => group.key == albumId.toString());

  SongGroup? artistById(int artistId) =>
      artists().firstWhereOrNull((group) => group.key == artistId.toString());

  SongGroup? folderByPath(String path) =>
      folders().firstWhereOrNull((group) => group.key == path);

  /// Albumes ordenados por la fecha de agregado de su cancion mas reciente.
  List<SongGroup> recentAlbums({int limit = 20}) {
    final groups = albums();
    groups.sort((a, b) {
      final newestA = a.songs.map((song) => song.dateAdded).reduce(max);
      final newestB = b.songs.map((song) => song.dateAdded).reduce(max);
      return newestB.compareTo(newestA);
    });
    return groups.take(limit).toList();
  }

  /// Canciones agregadas mas recientemente (requerimiento 4.1).
  List<Song> recentlyAdded({int limit = 50}) => sortSongs(
    _songs,
    SongSort.dateAdded,
    SortDirection.descending,
  ).take(limit).toList();

  static int max(int a, int b) => a > b ? a : b;

  List<SongGroup> _filterGroups(List<SongGroup> groups, String search) {
    var result = groups;
    if (search.trim().isNotEmpty) {
      final needle = search.trim().toLowerCase();
      result = result
          .where(
            (group) =>
                group.title.toLowerCase().contains(needle) ||
                group.subtitle.toLowerCase().contains(needle),
          )
          .toList();
    }
    result.sort((a, b) => _text(a.title).compareTo(_text(b.title)));
    return result;
  }

  static String _songLabel(int count) =>
      count == 1 ? '1 canción' : '$count canciones';

  static String _albumLabel(int count) =>
      count == 1 ? '1 álbum' : '$count álbumes';
}
