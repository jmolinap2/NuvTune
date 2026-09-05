import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/network/musicbrainz_client.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/metadata_editor/cover_picker.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/cover_cache.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Completa género, artista, compositor y portada buscando en MusicBrainz y
/// Cover Art Archive.
///
/// Solo propone valores para los campos que ya estén vacíos: nunca pisa un
/// dato que el archivo ya trae. El título de una canción no basta para
/// garantizar que la coincidencia sea la correcta, así que el usuario revisa
/// y marca cada propuesta antes de escribir nada; solo se preseleccionan las
/// coincidencias de puntaje alto, y siguen pudiendo desmarcarse.
class MetadataLookupScreen extends ConsumerStatefulWidget {
  const MetadataLookupScreen({super.key});

  @override
  ConsumerState<MetadataLookupScreen> createState() =>
      _MetadataLookupScreenState();
}

class _MetadataLookupScreenState extends ConsumerState<MetadataLookupScreen> {
  late final List<_LookupItem> _items;
  final _selected = <int>{};
  bool _scanning = false;
  bool _stopRequested = false;
  bool _applying = false;
  int _scanned = 0;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final song in ref.read(libraryRepositoryProvider).songs)
        if (!song.hasIdentifiedArtist ||
            song.displayGenre == null ||
            song.displayComposer == null ||
            !song.hasCover)
          _LookupItem(
            song: song,
            needsArtist: !song.hasIdentifiedArtist,
            needsGenre: song.displayGenre == null,
            needsComposer: song.displayComposer == null,
            needsCover: !song.hasCover,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.metadataLookupTitle)),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: AppStrings.metadataLookupNoPending,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _scanning
                        ? 'Buscando $_scanned de ${_items.length}...'
                        : AppStrings.metadataLookupSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_scanning)
                  LinearProgressIndicator(value: _scanned / _items.length),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) => _itemTile(_items[index]),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _items.isEmpty ? null : _bottomBar(),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _applying ? null : (_scanning ? _stop : _startScan),
                icon: Icon(
                  _scanning
                      ? Icons.stop_circle_outlined
                      : Icons.travel_explore_rounded,
                ),
                label: Text(
                  _scanning
                      ? AppStrings.metadataLookupStop
                      : (_scanned > 0
                            ? 'Continuar búsqueda'
                            : AppStrings.metadataLookupStart),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _applying || _selected.isEmpty
                    ? null
                    : _applySelected,
                icon: _applying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _selected.isEmpty
                      ? AppStrings.metadataLookupApplySelected
                      : '${AppStrings.metadataLookupApplySelected} '
                            '(${_selected.length})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(_LookupItem item) {
    final checked = _selected.contains(item.song.id);
    return CheckboxListTile(
      value: item.hasProposal ? checked : false,
      onChanged: item.hasProposal
          ? (value) => setState(() {
              if (value ?? false) {
                _selected.add(item.song.id);
              } else {
                _selected.remove(item.song.id);
              }
            })
          : null,
      secondary: item.proposedCover != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                item.proposedCover!.bytes,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          : CoverArt(song: item.song, size: 44, borderRadius: 8),
      title: Text(
        item.song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _subtitleFor(item),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _subtitleFor(_LookupItem item) {
    if (!item.searched) {
      final missing = [
        if (item.needsArtist) AppStrings.fieldArtist,
        if (item.needsGenre) AppStrings.fieldGenre,
        if (item.needsComposer) AppStrings.fieldComposer,
        if (item.needsCover) AppStrings.cover,
      ];
      return 'Falta: ${missing.join(', ')}';
    }
    if (!item.hasProposal) {
      return AppStrings.metadataLookupNoMatch;
    }
    return [
      if (item.proposedArtist != null)
        '${AppStrings.fieldArtist}: ${item.proposedArtist}',
      if (item.proposedGenre != null)
        '${AppStrings.fieldGenre}: ${item.proposedGenre}',
      if (item.proposedComposer != null)
        '${AppStrings.fieldComposer}: ${item.proposedComposer}',
      if (item.proposedCover != null) '${AppStrings.cover} encontrada',
    ].join(' · ');
  }

  Future<void> _startScan() async {
    final musicBrainz = ref.read(musicBrainzClientProvider);
    final coverArchive = ref.read(coverArtArchiveClientProvider);
    setState(() {
      _scanning = true;
      _stopRequested = false;
    });

    for (final item in _items) {
      if (_stopRequested || !mounted) break;
      if (item.searched) continue;

      final match = await musicBrainz.lookup(
        title: item.song.title,
        artist: item.needsArtist ? null : item.song.displayArtist,
      );
      if (!mounted) return;

      final releaseId = match?.releaseId;
      final cover = item.needsCover && releaseId != null
          ? await coverArchive.frontCoverOf(releaseId)
          : null;
      if (!mounted) return;

      setState(() {
        item.searched = true;
        item.match = match;
        item.proposedCover = cover;
        _scanned++;
        if (item.hasProposal && (match?.score ?? 0) >= 90) {
          _selected.add(item.song.id);
        }
      });
    }

    if (mounted) setState(() => _scanning = false);
  }

  void _stop() => setState(() => _stopRequested = true);

  Future<void> _applySelected() async {
    final toApply = _items
        .where((item) => _selected.contains(item.song.id) && item.hasProposal)
        .toList();
    if (toApply.isEmpty) return;

    setState(() => _applying = true);
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(engineProvider);

    // 1. Etiquetas en lote.
    final tagItems = toApply.where((item) => item.hasTagProposal).toList();
    final tagOutcomes = <int, WriteOutcome>{};
    if (tagItems.isNotEmpty) {
      final edits = [
        for (final item in tagItems)
          MetadataEdit(
            songId: item.song.id,
            artist: item.proposedArtist,
            genre: item.proposedGenre,
            composer: item.proposedComposer,
          ),
      ];
      final results = await engine.api.editMetadataBatch(edits);
      for (var i = 0; i < tagItems.length; i++) {
        tagOutcomes[tagItems[i].song.id] = results[i].outcome;
      }
    }

    // 2. Portada: cada cancion trae la suya propia, asi que se escribe una
    //    por una (a diferencia del editor por lote, que aplica una sola
    //    imagen elegida a mano a varias canciones).
    final coverOutcomes = <int, WriteOutcome>{};
    for (final item in toApply) {
      final cover = item.proposedCover;
      if (cover == null) continue;
      final result = await engine.api.setCoverArt(
        item.song.id,
        cover.bytes,
        cover.mimeType,
      );
      coverOutcomes[item.song.id] = result.outcome;
      if (result.outcome == WriteOutcome.success) {
        ref.read(coverCacheProvider).invalidate(item.song.id);
      }
    }

    final succeededIds = <int>{
      for (final item in toApply)
        if (_fullyApplied(item, tagOutcomes, coverOutcomes)) item.song.id,
    };
    final failures = toApply.length - succeededIds.length;

    if (!mounted) return;
    setState(() {
      _applying = false;
      _items.removeWhere((item) => succeededIds.contains(item.song.id));
      _selected.removeAll(succeededIds);
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failures == 0
              ? 'Se actualizaron ${succeededIds.length} canciones'
              : 'Se actualizaron ${succeededIds.length} de ${toApply.length} '
                    'canciones. $failures no se pudieron modificar.',
        ),
      ),
    );
  }

  /// Una cancion cuenta como aplicada solo si todo lo que se le propuso se
  /// escribio: si tenia etiquetas y portada pero solo una de las dos escrituras
  /// tuvo exito, se queda en la lista para que el fallo sea visible en vez de
  /// darse por hecha a medias.
  static bool _fullyApplied(
    _LookupItem item,
    Map<int, WriteOutcome> tagOutcomes,
    Map<int, WriteOutcome> coverOutcomes,
  ) {
    if (item.hasTagProposal &&
        tagOutcomes[item.song.id] != WriteOutcome.success) {
      return false;
    }
    if (item.proposedCover != null &&
        coverOutcomes[item.song.id] != WriteOutcome.success) {
      return false;
    }
    return true;
  }
}

class _LookupItem {
  _LookupItem({
    required this.song,
    required this.needsArtist,
    required this.needsGenre,
    required this.needsComposer,
    required this.needsCover,
  });

  final Song song;
  final bool needsArtist;
  final bool needsGenre;
  final bool needsComposer;
  final bool needsCover;

  bool searched = false;
  MusicBrainzMatch? match;
  PickedCover? proposedCover;

  String? get proposedArtist =>
      needsArtist && (match?.matchedArtist.isNotEmpty ?? false)
      ? match!.matchedArtist
      : null;

  String? get proposedGenre =>
      needsGenre && (match?.genre?.isNotEmpty ?? false) ? match!.genre : null;

  String? get proposedComposer =>
      needsComposer && (match?.composer?.isNotEmpty ?? false)
      ? match!.composer
      : null;

  bool get hasTagProposal =>
      proposedArtist != null || proposedGenre != null || proposedComposer != null;

  bool get hasProposal => hasTagProposal || proposedCover != null;
}
