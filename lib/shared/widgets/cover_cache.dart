import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:palette_generator/palette_generator.dart';

/// Miniaturas de portada en memoria (requerimiento seccion 17: miniaturas en
/// cache y sin decodificar la portada en resolucion completa).
///
/// El motor entrega la miniatura ya reducida por el sistema. Aqui solo se evita
/// pedir dos veces la misma y se limita cuantas se conservan, porque una
/// biblioteca grande podria llenar la memoria con imagenes.
class CoverCache {
  CoverCache(this._engine);

  final EngineBridge _engine;

  final _thumbnails = <String, Uint8List?>{};
  final _pending = <String, Future<Uint8List?>>{};
  final _insertionOrder = <String>[];

  /// Tamanos que usa la interfaz, para que el cache no se fragmente en decenas
  /// de variantes por cancion.
  static const listSize = 128;
  static const gridSize = 320;
  static const playerSize = 720;

  Future<Uint8List?> thumbnail(int songId, int size) {
    final key = '$songId@$size';

    if (_thumbnails.containsKey(key)) {
      return Future.value(_thumbnails[key]);
    }
    final inFlight = _pending[key];
    if (inFlight != null) return inFlight;

    final request = _load(songId, size, key);
    _pending[key] = request;
    return request;
  }

  Future<Uint8List?> _load(int songId, int size, String key) async {
    try {
      final cover = await _engine.api.getCover(songId, size);
      final bytes = cover?.bytes;
      _store(key, bytes);
      return bytes;
    } finally {
      _pending.remove(key);
    }
  }

  void _store(String key, Uint8List? bytes) {
    _thumbnails[key] = bytes;
    _insertionOrder.add(key);
    while (_insertionOrder.length > _maxEntries) {
      final oldest = _insertionOrder.removeAt(0);
      _thumbnails.remove(oldest);
    }
  }

  /// Se invalida tras incrustar una portada nueva en el archivo.
  void invalidate(int songId) {
    final keys = _thumbnails.keys.where((key) => key.startsWith('$songId@')).toList();
    for (final key in keys) {
      _thumbnails.remove(key);
      _insertionOrder.remove(key);
    }
  }

  void clear() {
    _thumbnails.clear();
    _insertionOrder.clear();
  }

  static const _maxEntries = 400;
}

final coverCacheProvider = Provider<CoverCache>((ref) {
  final cache = CoverCache(ref.watch(engineProvider));
  ref.onDispose(cache.clear);
  return cache;
});

/// Color dominante de la portada de una cancion, para los colores dinamicos
/// (requerimiento seccion 12).
final coverAccentProvider = FutureProvider.family<Color?, int>((ref, songId) async {
  final bytes = await ref
      .watch(coverCacheProvider)
      .thumbnail(songId, CoverCache.listSize);
  if (bytes == null) return null;

  final palette = await PaletteGenerator.fromImageProvider(
    MemoryImage(bytes),
    size: const Size(96, 96),
    maximumColorCount: 8,
  );

  // Se prefiere un color vivo; el dominante puede ser un gris de fondo que no
  // sirve como acento.
  return palette.vibrantColor?.color ??
      palette.lightVibrantColor?.color ??
      palette.darkVibrantColor?.color ??
      palette.dominantColor?.color;
});
