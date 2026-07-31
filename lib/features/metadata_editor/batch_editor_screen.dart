import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/metadata_editor/cover_picker.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/cover_cache.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Edicion en lote (requerimiento seccion 7.1: aplicar artista, album, genero o
/// portada a varias canciones).
///
/// Solo se escriben los campos que el usuario marca; el resto de cada cancion
/// queda intacto.
class BatchEditorScreen extends ConsumerStatefulWidget {
  const BatchEditorScreen({required this.songIds, super.key});

  final List<int> songIds;

  @override
  ConsumerState<BatchEditorScreen> createState() => _BatchEditorScreenState();
}

class _BatchEditorScreenState extends ConsumerState<BatchEditorScreen> {
  final _artist = TextEditingController();
  final _albumArtist = TextEditingController();
  final _album = TextEditingController();
  final _genre = TextEditingController();
  final _year = TextEditingController();

  final _enabled = <String, bool>{
    'artist': false,
    'albumArtist': false,
    'álbum': false,
    'genre': false,
    'year': false,
  };

  PickedCover? _cover;
  bool _saving = false;
  double _progress = 0;

  @override
  void dispose() {
    _artist.dispose();
    _albumArtist.dispose();
    _album.dispose();
    _genre.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(libraryRepositoryProvider).songsByIds(widget.songIds);

    if (songs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editSeveralSongs)),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No hay canciones seleccionadas',
        ),
      );
    }

    final hasSomething = _enabled.values.any((value) => value) || _cover != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${songs.length} canciones'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: songs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    CoverArt(song: songs[index], size: 68, borderRadius: 12),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Marca los campos que quieras aplicar a todas las canciones '
              'seleccionadas. Los campos sin marcar no se tocan.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            _batchField(AppStrings.fieldArtist, 'artist', _artist),
            _batchField(AppStrings.fieldAlbumArtist, 'albumArtist', _albumArtist),
            _batchField(AppStrings.fieldAlbum, 'álbum', _album),
            _batchField(AppStrings.fieldGenre, 'genre', _genre),
            _batchField(
              AppStrings.fieldYear,
              'year',
              _year,
              keyboardType: TextInputType.number,
            ),

            const Divider(height: 32),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _cover == null
                  ? const Icon(Icons.image_outlined, size: 40)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _cover!.bytes,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
              title: const Text(AppStrings.cover),
              subtitle: Text(
                _cover == null
                    ? 'Sin cambios'
                    : 'Se aplicara a las ${songs.length} canciones',
              ),
              trailing: TextButton(
                onPressed: _pickCover,
                child: Text(_cover == null ? 'Elegir' : 'Cambiar'),
              ),
            ),

            if (_saving) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                'Escribiendo ${(_progress * songs.length).round()} de '
                '${songs.length}...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving || !hasSomething ? null : () => _apply(songs),
            icon: const Icon(Icons.save_rounded),
            label: const Text(AppStrings.batchApply),
          ),
        ),
      ),
    );
  }

  Widget _batchField(
    String label,
    String key,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: _enabled[key],
            onChanged: (value) => setState(() => _enabled[key] = value ?? false),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: _enabled[key] ?? false,
              keyboardType: keyboardType,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: label),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCover() async {
    final picked = await pickCoverImage(
      context,
      ref,
      source: CoverSource.gallery,
    );
    if (picked != null) setState(() => _cover = picked);
  }

  Future<void> _apply(List<Song> songs) async {
    setState(() {
      _saving = true;
      _progress = 0;
    });

    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(engineProvider);
    var failures = 0;

    try {
      final edits = <MetadataEdit>[
        for (final song in songs)
          MetadataEdit(
            songId: song.id,
            artist: _valueIfEnabled('artist', _artist),
            albumArtist: _valueIfEnabled('albumArtist', _albumArtist),
            album: _valueIfEnabled('álbum', _album),
            genre: _valueIfEnabled('genre', _genre),
            year: _valueIfEnabled('year', _year),
          ),
      ];

      final anyField = _enabled.values.any((value) => value);
      if (anyField) {
        final results = await engine.api.editMetadataBatch(edits);
        failures +=
            results.where((r) => r.outcome != WriteOutcome.success).length;
        setState(() => _progress = _cover == null ? 1 : 0.5);
      }

      final cover = _cover;
      if (cover != null) {
        final results = await engine.api.setCoverArtBatch(
          songs.map((song) => song.id).toList(),
          cover.bytes,
          cover.mimeType,
        );
        failures +=
            results.where((r) => r.outcome != WriteOutcome.success).length;
        for (final song in songs) {
          ref.read(coverCacheProvider).invalidate(song.id);
        }
        setState(() => _progress = 1);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failures == 0
                ? 'Se actualizaron ${songs.length} canciones'
                : 'Se actualizaron ${songs.length - failures} de '
                    '${songs.length} canciones. $failures no se pudieron '
                    'modificar.',
          ),
        ),
      );

      if (mounted && failures == 0) {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _valueIfEnabled(String key, TextEditingController controller) =>
      (_enabled[key] ?? false) ? controller.text : null;
}
