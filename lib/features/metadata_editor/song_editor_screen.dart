import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/repositories/cover_repository.dart';
import 'package:nuvtune/features/lyrics/lyrics_view.dart';
import 'package:nuvtune/features/metadata_editor/cover_picker.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/cover_cache.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/song_actions_sheet.dart';

/// Editor de una cancion (requerimiento seccion 7.1 y pantalla "Editor de
/// cancion" de la seccion 11).
class SongEditorScreen extends ConsumerStatefulWidget {
  const SongEditorScreen({required this.songId, super.key});

  final int songId;

  @override
  ConsumerState<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends ConsumerState<SongEditorScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _loaded = false;
  bool _saving = false;
  bool _dirty = false;

  /// Portada elegida en esta sesion de edicion, todavía sin guardar.
  PickedCover? _pendingCover;
  bool _removeCover = false;
  bool _applyCoverToAlbum = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Song? get _song =>
      ref.read(libraryRepositoryProvider).songById(widget.songId);

  @override
  Widget build(BuildContext context) {
    final song = _song;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editSong)),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Esta canción ya no está en la biblioteca',
        ),
      );
    }

    if (!_loaded) {
      _loadFields(song);
    }

    final embedCoverPreference =
        ref.watch(settingsProvider).valueOrNull?.embedCoverInFile ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editSong),
        actions: [
          if (_dirty)
            IconButton(
              tooltip: AppStrings.discardChanges,
              icon: const Icon(Icons.restore_rounded),
              onPressed: () => setState(() {
                _loaded = false;
                _dirty = false;
                _pendingCover = null;
                _removeCover = false;
              }),
            ),
          IconButton(
            tooltip: AppStrings.technicalInfo,
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showTechnicalInfo(context, song: song),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _CoverEditor(
              song: song,
              pendingCover: _pendingCover,
              removeCover: _removeCover,
              applyToAlbum: _applyCoverToAlbum,
              embedInFile: embedCoverPreference,
              onPicked: (cover) => setState(() {
                _pendingCover = cover;
                _removeCover = false;
                _dirty = true;
              }),
              onRemove: () => setState(() {
                _pendingCover = null;
                _removeCover = true;
                _dirty = true;
              }),
              onApplyToAlbumChanged: (value) =>
                  setState(() => _applyCoverToAlbum = value),
            ),

            const SizedBox(height: 20),

            _field(AppStrings.fieldTitle, 'title'),
            _field(AppStrings.fieldArtist, 'artist'),
            _field(AppStrings.fieldAlbumArtist, 'albumArtist'),
            _field(AppStrings.fieldAlbum, 'álbum'),
            _field(AppStrings.fieldGenre, 'genre'),
            Row(
              children: [
                Expanded(
                  child: _field(
                    AppStrings.fieldYear,
                    'year',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    AppStrings.fieldTrackNumber,
                    'track',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    AppStrings.fieldDiscNumber,
                    'disc',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            _field(AppStrings.fieldComposer, 'composer'),
            _field(AppStrings.fieldComment, 'comment', maxLines: 3),
            _field(AppStrings.fieldLyrics, 'lyrics', maxLines: 8),

            const SizedBox(height: 12),
            Text(
              'Los cambios se escriben en el archivo mediante una copia '
              'temporal. Si algo falla, el original se restaura y no se aplica '
              'nada.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving || !_dirty ? null : () => _save(song),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Guardando...' : AppStrings.save),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String key, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[key],
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: maxLines > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) {
          if (!_dirty) setState(() => _dirty = true);
        },
      ),
    );
  }

  Future<void> _loadFields(Song song) async {
    _loaded = true;

    // Los valores de MediaStore sirven de base; la letra la aporta el motor
    // leyendo las etiquetas reales del archivo.
    final values = <String, String>{
      'title': song.title,
      'artist': song.artist,
      'albumArtist': song.albumArtist ?? '',
      'álbum': song.album,
      'genre': song.genre ?? '',
      'year': song.year?.toString() ?? '',
      'track': song.trackNumber?.toString() ?? '',
      'disc': song.discNumber?.toString() ?? '',
      'composer': song.composer ?? '',
      'comment': '',
      'lyrics': '',
    };

    for (final entry in values.entries) {
      final controller = _controllers[entry.key];
      if (controller == null) {
        _controllers[entry.key] = TextEditingController(text: entry.value);
      } else {
        controller.text = entry.value;
      }
    }

    final lyrics = await ref.read(engineProvider).api.getLyrics(song.id);
    final embedded = lyrics.embedded;
    if (embedded != null && mounted) {
      _controllers['lyrics']?.text = embedded;
    }
    if (mounted) setState(() {});
  }

  Future<void> _save(Song song) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(engineProvider);

    try {
      // 1. Etiquetas. Solo se envian los campos que cambiaron; el motor
      //    interpreta null como "no modificar" y "" como "borrar".
      final edit = MetadataEdit(
        songId: song.id,
        title: _changed('title', song.title),
        artist: _changed('artist', song.artist),
        albumArtist: _changed('albumArtist', song.albumArtist ?? ''),
        album: _changed('álbum', song.album),
        genre: _changed('genre', song.genre ?? ''),
        year: _changed('year', song.year?.toString() ?? ''),
        trackNumber: _changed('track', song.trackNumber?.toString() ?? ''),
        discNumber: _changed('disc', song.discNumber?.toString() ?? ''),
        composer: _changed('composer', song.composer ?? ''),
        comment: _controllers['comment']?.text,
        lyrics: _controllers['lyrics']?.text,
      );

      final tagResult = await engine.api.editMetadata(edit);
      if (tagResult.outcome != WriteOutcome.success) {
        messenger.showSnackBar(SnackBar(content: Text(_describe(tagResult))));
        return;
      }

      // 2. Portada.
      await _saveCover(song, engine, messenger);

      ref.read(coverCacheProvider).invalidate(song.id);
      // La letra pudo cambiar dentro del archivo: se descarta la resuelta.
      ref.invalidate(lyricsProvider(song.id));
      messenger.showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
      if (mounted) {
        setState(() {
          _dirty = false;
          _pendingCover = null;
          _removeCover = false;
          _loaded = false;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveCover(
    Song song,
    EngineBridge engine,
    ScaffoldMessengerState messenger,
  ) async {
    final embedInFile =
        ref.read(settingsProvider).valueOrNull?.embedCoverInFile ?? true;

    if (_removeCover) {
      if (embedInFile) {
        final result = await engine.api.removeCoverArt(song.id);
        if (result.outcome != WriteOutcome.success) {
          messenger.showSnackBar(SnackBar(content: Text(_describe(result))));
        }
      }
      await ref
          .read(coverRepositoryProvider)
          .removeCover(CoverRepository.songTarget(song.id));
      if (_applyCoverToAlbum) {
        await ref
            .read(coverRepositoryProvider)
            .removeCover(CoverRepository.albumTarget(song.albumId));
      }
      return;
    }

    final cover = _pendingCover;
    if (cover == null) return;

    if (!embedInFile) {
      // Portada solo dentro de la aplicacion (requerimiento 7.2).
      final target = _applyCoverToAlbum
          ? CoverRepository.albumTarget(song.albumId)
          : CoverRepository.songTarget(song.id);
      await ref.read(coverRepositoryProvider).saveCover(target, cover.bytes);
      return;
    }

    if (_applyCoverToAlbum) {
      final albumSongs = ref
          .read(libraryRepositoryProvider)
          .songs
          .where((item) => item.albumId == song.albumId)
          .map((item) => item.id)
          .toList();
      final results = await engine.api.setCoverArtBatch(
        albumSongs,
        cover.bytes,
        cover.mimeType,
      );
      final failed = results.where((r) => r.outcome != WriteOutcome.success);
      if (failed.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'La portada se aplico a ${results.length - failed.length} de '
              '${results.length} canciones del álbum',
            ),
          ),
        );
      }
      for (final id in albumSongs) {
        ref.read(coverCacheProvider).invalidate(id);
      }
      return;
    }

    final result = await engine.api.setCoverArt(
      song.id,
      cover.bytes,
      cover.mimeType,
    );
    if (result.outcome != WriteOutcome.success) {
      messenger.showSnackBar(SnackBar(content: Text(_describe(result))));
    }
  }

  /// Devuelve el valor nuevo solo si difiere del original, para no reescribir
  /// etiquetas que el usuario no toco.
  String? _changed(String key, String original) {
    final value = _controllers[key]?.text ?? '';
    return value == original ? null : value;
  }

  static String _describe(WriteResult result) => switch (result.outcome) {
    WriteOutcome.success => 'Cambios guardados',
    WriteOutcome.deniedByUser =>
      'No se autorizo modificar el archivo, no se guardo nada',
    WriteOutcome.needsUserConsent =>
      'El sistema pide confirmacion para modificar este archivo',
    WriteOutcome.unsupportedFormat =>
      result.message ?? 'El formato no admite escritura de etiquetas',
    WriteOutcome.integrityCheckFailed =>
      result.message ?? 'La verificacion fallo; el archivo no se modifico',
  };
}

class _CoverEditor extends ConsumerWidget {
  const _CoverEditor({
    required this.song,
    required this.pendingCover,
    required this.removeCover,
    required this.applyToAlbum,
    required this.embedInFile,
    required this.onPicked,
    required this.onRemove,
    required this.onApplyToAlbumChanged,
  });

  final Song song;
  final PickedCover? pendingCover;
  final bool removeCover;
  final bool applyToAlbum;
  final bool embedInFile;
  final ValueChanged<PickedCover> onPicked;
  final VoidCallback onRemove;
  final ValueChanged<bool> onApplyToAlbumChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              _preview(context),
              Positioned(
                right: 4,
                bottom: 4,
                child: Material(
                  color: scheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showCoverOptions(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 20,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          embedInFile
              ? 'La portada se incrustara en el archivo'
              : 'La portada se guardara solo dentro de NuvTune',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.coverApplyToAlbum),
          value: applyToAlbum,
          onChanged: onApplyToAlbumChanged,
        ),
      ],
    );
  }

  Widget _preview(BuildContext context) {
    const size = 180.0;
    final cover = pendingCover;

    if (removeCover) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.hide_image_outlined, size: 48),
      );
    }

    if (cover != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          cover.bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return CoverArt(song: song, size: size, borderRadius: 20);
  }

  void _showCoverOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in const [
              (
                CoverSource.gallery,
                AppStrings.coverFromGallery,
                Icons.photo_library_outlined,
              ),
              (
                CoverSource.camera,
                AppStrings.coverFromCamera,
                Icons.photo_camera_outlined,
              ),
              (
                CoverSource.files,
                AppStrings.coverFromFiles,
                Icons.folder_open_outlined,
              ),
              (
                CoverSource.clipboard,
                AppStrings.coverFromClipboard,
                Icons.content_paste_rounded,
              ),
            ])
              ListTile(
                leading: Icon(option.$3),
                title: Text(option.$2),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final picked = await pickCoverImage(
                    context,
                    ref,
                    source: option.$1,
                  );
                  if (picked != null) onPicked(picked);
                },
              ),
            const Divider(height: 8),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                AppStrings.coverRemove,
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onRemove();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
