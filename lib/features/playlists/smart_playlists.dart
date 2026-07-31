import 'package:flutter/material.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';

/// Listas inteligentes (requerimiento seccion 4.4).
///
/// Cada una es una consulta sobre la biblioteca y el contador de
/// reproducciones; no se guarda ninguna en la base de datos, se recalculan al
/// abrirlas para que siempre reflejen el estado actual.
///
/// "Musica de una carpeta especifica" no aparece en este enum porque no es una
/// consulta cerrada: necesita que el usuario diga cual es la carpeta. Se ofrece
/// junto a las demas en la lista de listas inteligentes, con un selector previo.
enum SmartPlaylist {
  addedThisWeek(
    key: 'added-this-week',
    label: 'Agregadas está semana',
    icon: Icons.new_releases_outlined,
  ),
  losslessQuality(
    key: 'lossless',
    label: 'Música con calidad FLAC',
    icon: Icons.high_quality_outlined,
  ),
  neverPlayed(
    key: 'never-played',
    label: 'Nunca reproducidas',
    icon: Icons.hourglass_empty_rounded,
  ),
  playedMoreThanFive(
    key: 'played-5',
    label: 'Con más de cinco reproducciones',
    icon: Icons.repeat_on_rounded,
  ),
  withoutCover(
    key: 'without-cover',
    label: 'Sin portada',
    icon: Icons.hide_image_outlined,
  ),
  withoutArtist(
    key: 'without-artist',
    label: 'Sin artista identificado',
    icon: Icons.person_off_outlined,
  );

  const SmartPlaylist({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;

  static SmartPlaylist? fromKey(String key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }

  List<Song> resolve(List<Song> songs, Map<int, int> playCounts) {
    switch (this) {
      case SmartPlaylist.addedThisWeek:
        final threshold = DateTime.now().subtract(const Duration(days: 7));
        return songs.where((song) => song.addedAt.isAfter(threshold)).toList()
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      case SmartPlaylist.losslessQuality:
        return songs.where((song) => song.isLossless).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      case SmartPlaylist.neverPlayed:
        return songs.where((song) => (playCounts[song.id] ?? 0) == 0).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      case SmartPlaylist.playedMoreThanFive:
        final matching =
            songs.where((song) => (playCounts[song.id] ?? 0) > 5).toList();
        matching.sort(
          (a, b) => (playCounts[b.id] ?? 0).compareTo(playCounts[a.id] ?? 0),
        );
        return matching;

      case SmartPlaylist.withoutCover:
        return songs.where((song) => !song.hasCover).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      case SmartPlaylist.withoutArtist:
        return songs.where((song) => !song.hasIdentifiedArtist).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
  }

  /// Explicacion que se muestra bajo el titulo, para que la regla sea evidente.
  String get description => switch (this) {
        SmartPlaylist.addedThisWeek =>
          'Canciones cuya fecha de agregado está dentro de los últimos siete días',
        SmartPlaylist.losslessQuality =>
          'Archivos FLAC, ALAC, WAV y AIFF, sin pérdida de información',
        SmartPlaylist.neverPlayed =>
          'Canciones que NuvTune nunca ha registrado como reproducidas',
        SmartPlaylist.playedMoreThanFive =>
          'Canciones con seis reproducciones o más',
        SmartPlaylist.withoutCover =>
          'Canciones cuyo álbum no tiene portada. La detección es por álbum, '
              'así que un álbum con portada parcial aparece completo o no aparece.',
        SmartPlaylist.withoutArtist =>
          'Canciones cuyo campo de artista está vacío o sin identificar',
      };
}
