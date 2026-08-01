import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/repositories/cover_repository.dart';
import 'package:nuvtune/shared/widgets/cover_cache.dart';

/// Portada de una cancion.
///
/// Resuelve las tres procedencias que distingue el requerimiento seccion 7.2, en
/// este orden de prioridad:
///  1. Portada personalizada de la cancion, guardada solo por la aplicacion.
///  2. Portada personalizada del album.
///  3. Portada incrustada en el archivo, que resuelve el motor.
/// Si no hay ninguna, se dibuja un marcador con la inicial.
class CoverArt extends ConsumerWidget {
  const CoverArt({
    required this.song,
    this.size = 56,
    this.borderRadius = 12,
    this.fallback,
    super.key,
  });

  final Song? song;
  final double size;
  final double borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = song;
    final radius = BorderRadius.circular(borderRadius);

    if (current == null) {
      return _Placeholder(
        size: size,
        borderRadius: radius,
        letter: null,
        fallback: fallback,
      );
    }

    final customCovers =
        ref.watch(customCoversProvider).valueOrNull ?? const {};
    final customPath =
        customCovers[CoverRepository.songTarget(current.id)] ??
        customCovers[CoverRepository.albumTarget(current.albumId)];

    if (customPath != null && File(customPath).existsSync()) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(customPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: _cacheDimension(context),
        ),
      );
    }

    if (!current.hasCover) {
      return _Placeholder(
        size: size,
        borderRadius: radius,
        letter: _initialOf(current),
        fallback: fallback,
      );
    }

    return _EmbeddedCover(
      song: current,
      size: size,
      borderRadius: radius,
      requestSize: _requestSize(),
      fallback: fallback,
    );
  }

  int _requestSize() {
    if (size <= 72) return CoverCache.listSize;
    if (size <= 360) return CoverCache.gridSize;
    return CoverCache.playerSize;
  }

  /// Se decodifica a la resolucion en pixeles que realmente ocupa en pantalla.
  int _cacheDimension(BuildContext context) =>
      (size * MediaQuery.devicePixelRatioOf(context)).round();

  static String _initialOf(Song song) => song.title.isEmpty
      ? '?'
      : song.title.trim().characters.first.toUpperCase();
}

class _EmbeddedCover extends ConsumerWidget {
  const _EmbeddedCover({
    required this.song,
    required this.size,
    required this.borderRadius,
    required this.requestSize,
    this.fallback,
  });

  final Song song;
  final double size;
  final BorderRadius borderRadius;
  final int requestSize;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(coverCacheProvider);

    return FutureBuilder<Uint8List?>(
      future: cache.thumbnail(song.id, requestSize),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: bytes == null
              ? _Placeholder(
                  key: const ValueKey('cover-placeholder'),
                  size: size,
                  borderRadius: borderRadius,
                  letter: CoverArt._initialOf(song),
                  fallback: fallback,
                )
              : ClipRRect(
                  key: ValueKey('cover-${song.id}-$requestSize'),
                  borderRadius: borderRadius,
                  child: Image.memory(
                    bytes,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.size,
    required this.borderRadius,
    required this.letter,
    this.fallback,
    super.key,
  });

  final double size;
  final BorderRadius borderRadius;
  final String? letter;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (fallback != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox.square(dimension: size, child: fallback),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surfaceContainerHighest, scheme.surfaceContainerHigh],
        ),
      ),
      alignment: Alignment.center,
      child: letter == null
          ? Icon(
              Icons.music_note_rounded,
              size: size * 0.45,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            )
          : Text(
              letter!,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

/// Portada de un grupo (album, artista, carpeta) o de una lista.
class GroupCover extends StatelessWidget {
  const GroupCover({
    required this.song,
    this.customPath,
    this.size = 160,
    this.borderRadius = 16,
    this.icon = Icons.album_rounded,
    super.key,
  });

  final Song? song;
  final String? customPath;
  final double size;
  final double borderRadius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final path = customPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      );
    }

    if (song != null) {
      return CoverArt(song: song, size: size, borderRadius: borderRadius);
    }

    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: scheme.surfaceContainerHigh,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.4, color: scheme.onSurfaceVariant),
    );
  }
}
