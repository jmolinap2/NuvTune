import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/lyrics/lrc_parser.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Letras resueltas para una cancion, con la fuente de la que salieron.
class ResolvedLyrics {
  const ResolvedLyrics({
    required this.parsed,
    required this.source,
    required this.userOffsetMs,
  });

  final ParsedLyrics parsed;
  final String source;
  final int userOffsetMs;
}

/// Posicion de reproduccion correspondiente a una marca de tiempo de la letra.
///
/// Es la operacion inversa de [LrcParser.activeLineIndex]: tanto el desfase del
/// propio LRC como el configurado por el usuario retrasan la marca respecto al
/// audio. El motor de reproduccion no admite posiciones negativas.
int lyricLinePlaybackPositionMs({
  required int lineTimeMs,
  required int lrcOffsetMs,
  required int userOffsetMs,
}) {
  final positionMs = lineTimeMs + lrcOffsetMs + userOffsetMs;
  return positionMs < 0 ? 0 : positionMs;
}

/// Resuelve la letra de una cancion en el orden de prioridad del requerimiento
/// seccion 8: primero la correccion del usuario, luego el archivo `.lrc` y por
/// ultimo la letra incrustada en las etiquetas.
final lyricsProvider = FutureProvider.family<ResolvedLyrics, int>((
  ref,
  songId,
) async {
  final override = await ref
      .watch(lyricsRepositoryProvider)
      .overrideFor(songId);
  if (override != null) {
    return ResolvedLyrics(
      parsed: LrcParser.parse(override.content),
      source: 'Guardada en NuvTune',
      userOffsetMs: override.offsetMs,
    );
  }

  final payload = await ref.watch(engineProvider).api.getLyrics(songId);

  final lrc = payload.lrcContent;
  if (lrc != null && lrc.trim().isNotEmpty) {
    return ResolvedLyrics(
      parsed: LrcParser.parse(lrc),
      source: payload.lrcSource ?? 'Archivo LRC',
      userOffsetMs: 0,
    );
  }

  final embedded = payload.embedded;
  if (embedded != null && embedded.trim().isNotEmpty) {
    return ResolvedLyrics(
      parsed: LrcParser.parse(embedded),
      source: 'Incrustada en el archivo',
      userOffsetMs: 0,
    );
  }

  return const ResolvedLyrics(
    parsed: ParsedLyrics.empty,
    source: '',
    userOffsetMs: 0,
  );
});

/// Vista de letras con desplazamiento automatico (requerimiento seccion 8).
class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({required this.song, super.key});

  final Song song;

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;
  int _lastScrolledIndex = -1;
  bool _searching = false;
  int _onlineSearchSerial = 0;

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      // Invalida cualquier respuesta pendiente de la cancion anterior. El
      // nuevo widget ya provoca un build, por lo que no hace falta setState.
      _onlineSearchSerial++;
      _searching = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Busca la letra en un proveedor abierto (requerimiento seccion 8). El
  /// resultado se guarda como letra propia de la cancion, de modo que la
  /// consulta ocurre una sola vez.
  Future<void> _fetchOnline() async {
    if (_searching) return;

    // Song es mutable en el contrato Pigeon. Se capturan tambien sus campos
    // para que un cambio de cola durante la consulta no altere los argumentos
    // ni el destino donde se guarda la respuesta.
    final songId = widget.song.id;
    final title = widget.song.title;
    final artist = _onlineArtist(widget.song.artist);
    final album = _onlineAlbum(widget.song.album);
    final durationMs = widget.song.durationMs;
    final searchSerial = ++_onlineSearchSerial;

    setState(() => _searching = true);

    String? content;
    try {
      final api = ref.read(engineProvider).api;
      content = await api.fetchLyricsOnline(title, artist, album, durationMs);

      if (!mounted || !_isCurrentSearch(searchSerial, songId)) return;

      // Algunos proveedores penalizan un album impreciso. Si la busqueda mas
      // especifica falla, se hace un unico segundo intento sin ese dato.
      if (!_hasLyrics(content) && album.isNotEmpty) {
        content = await api.fetchLyricsOnline(title, artist, '', durationMs);
      }
    } catch (_) {
      if (!mounted || !_isCurrentSearch(searchSerial, songId)) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo buscar la letra en este momento'),
        ),
      );
      return;
    }

    if (!mounted || !_isCurrentSearch(searchSerial, songId)) return;

    if (!_hasLyrics(content)) {
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró letra para esta canción')),
      );
      return;
    }

    // Esta comprobacion ocurre inmediatamente antes de iniciar la escritura:
    // una respuesta tardia nunca se asocia a la cancion que ahora esta activa.
    if (!_isCurrentSearch(searchSerial, songId)) return;
    await ref
        .read(lyricsRepositoryProvider)
        .save(
          songId: songId,
          content: content!,
          synchronized: content.contains(RegExp(r'\[\d{2}:\d{2}')),
        );
    ref.invalidate(lyricsProvider(songId));

    if (!mounted || !_isCurrentSearch(searchSerial, songId)) return;
    setState(() => _searching = false);
  }

  bool _isCurrentSearch(int searchSerial, int songId) =>
      searchSerial == _onlineSearchSerial && widget.song.id == songId;

  static bool _hasLyrics(String? content) =>
      content != null && content.trim().isNotEmpty;

  static String _onlineArtist(String value) {
    final artist = value.trim();
    if (artist.isEmpty ||
        artist == '<unknown>' ||
        artist.toLowerCase() == 'artista desconocido') {
      return '';
    }
    return artist;
  }

  static String _onlineAlbum(String value) {
    final album = value.trim();
    if (album.isEmpty ||
        album == '<unknown>' ||
        album.toLowerCase() == 'álbum desconocido') {
      return '';
    }
    return album;
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsProvider(widget.song.id));

    return lyricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => EmptyState(
        icon: Icons.lyrics_outlined,
        title: AppStrings.noLyrics,
        message: '$error',
      ),
      data: (resolved) {
        if (resolved.parsed.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyState(
                icon: Icons.lyrics_outlined,
                title: AppStrings.noLyrics,
                message:
                    'Puedes escribirla, asociar un archivo LRC desde el editor '
                    'de la canción, o buscarla en internet.',
                actionLabel: AppStrings.lyricsEdit,
                onAction: () => _editLyrics(resolved),
              ),
              const SizedBox(height: 8),
              // Es la unica parte de la aplicacion que sale a la red por una
              // cancion local, de modo que se pide siempre a mano.
              TextButton.icon(
                onPressed: _searching ? null : _fetchOnline,
                icon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore_rounded, size: 18),
                label: const Text(AppStrings.fetchLyricsOnline),
              ),
            ],
          );
        }

        return Column(
          children: [
            _LyricsToolbar(
              source: resolved.source,
              synchronized: resolved.parsed.synchronized,
              autoScroll: _autoScroll,
              onAutoScrollChanged: (value) =>
                  setState(() => _autoScroll = value),
              onEdit: () => _editLyrics(resolved),
              onAdjustOffset: resolved.parsed.synchronized
                  ? () => _adjustOffset(resolved)
                  : null,
            ),
            Expanded(
              child: resolved.parsed.synchronized
                  ? _SyncedLyrics(
                      resolved: resolved,
                      scrollController: _scrollController,
                      autoScroll: _autoScroll,
                      onScrolledTo: (index) => _lastScrolledIndex = index,
                      lastScrolledIndex: _lastScrolledIndex,
                      onSeek: (timeMs) =>
                          ref.read(playbackProvider.notifier).seek(timeMs),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      itemCount: resolved.parsed.lines.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          resolved.parsed.lines[index].text,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editLyrics(ResolvedLyrics resolved) async {
    final controller = TextEditingController(
      text: resolved.parsed.isEmpty ? '' : LrcParser.write(resolved.parsed),
    );

    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.lyricsEdit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes pegar un LRC con marcas de tiempo como [01:23.45].',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 12,
                  minLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Letra de la canción',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        child: const Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == null) return;

    final parsed = LrcParser.parse(saved);
    await ref
        .read(lyricsRepositoryProvider)
        .save(
          songId: widget.song.id,
          content: saved,
          synchronized: parsed.synchronized,
        );
    ref.invalidate(lyricsProvider(widget.song.id));
  }

  Future<void> _adjustOffset(ResolvedLyrics resolved) async {
    var offset = resolved.userOffsetMs;

    final applied = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.lyricsOffset,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Un valor positivo retrasa la letra respecto al audio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${offset > 0 ? '+' : ''}${(offset / 1000).toStringAsFixed(1)} s',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Slider(
                  value: offset.toDouble().clamp(-5000, 5000),
                  min: -5000,
                  max: 5000,
                  divisions: 100,
                  onChanged: (value) =>
                      setSheetState(() => offset = value.round()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(offset),
                        child: const Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (applied == null) return;

    // El desfase se guarda junto con la letra; si venia de un archivo LRC o de
    // las etiquetas, se materializa primero como correccion del usuario.
    final repository = ref.read(lyricsRepositoryProvider);
    final existing = await repository.overrideFor(widget.song.id);
    if (existing == null) {
      await repository.save(
        songId: widget.song.id,
        content: LrcParser.write(resolved.parsed),
        synchronized: resolved.parsed.synchronized,
        offsetMs: applied,
      );
    } else {
      await repository.saveOffset(widget.song.id, applied);
    }
    ref.invalidate(lyricsProvider(widget.song.id));
  }
}

class _LyricsToolbar extends StatelessWidget {
  const _LyricsToolbar({
    required this.source,
    required this.synchronized,
    required this.autoScroll,
    required this.onAutoScrollChanged,
    required this.onEdit,
    this.onAdjustOffset,
  });

  final String source;
  final bool synchronized;
  final bool autoScroll;
  final ValueChanged<bool> onAutoScrollChanged;
  final VoidCallback onEdit;
  final VoidCallback? onAdjustOffset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          if (synchronized)
            IconButton(
              tooltip: AppStrings.lyricsAutoScroll,
              icon: Icon(
                autoScroll
                    ? Icons.vertical_align_center_rounded
                    : Icons.swipe_vertical_rounded,
                color: autoScroll ? scheme.primary : null,
              ),
              onPressed: () => onAutoScrollChanged(!autoScroll),
            ),
          if (onAdjustOffset != null)
            IconButton(
              tooltip: AppStrings.lyricsOffset,
              icon: const Icon(Icons.timer_outlined),
              onPressed: onAdjustOffset,
            ),
          IconButton(
            tooltip: AppStrings.lyricsEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _SyncedLyrics extends ConsumerWidget {
  const _SyncedLyrics({
    required this.resolved,
    required this.scrollController,
    required this.autoScroll,
    required this.onScrolledTo,
    required this.lastScrolledIndex,
    required this.onSeek,
  });

  final ResolvedLyrics resolved;
  final ScrollController scrollController;
  final bool autoScroll;
  final ValueChanged<int> onScrolledTo;
  final int lastScrolledIndex;
  final ValueChanged<int> onSeek;

  static const _lineHeight = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playbackPositionProvider).valueOrNull;
    final activeIndex = LrcParser.activeLineIndex(
      resolved.parsed,
      position?.positionMs ?? 0,
      extraOffsetMs: resolved.userOffsetMs,
    );

    if (autoScroll && activeIndex >= 0 && activeIndex != lastScrolledIndex) {
      onScrolledTo(activeIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final target = (activeIndex * _lineHeight - 140).clamp(
          0.0,
          scrollController.position.maxScrollExtent,
        );
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    }

    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: resolved.parsed.lines.length,
      itemBuilder: (context, index) {
        final line = resolved.parsed.lines[index];
        final isActive = index == activeIndex;

        if (line.text.isEmpty) {
          return const SizedBox(height: 20);
        }

        return InkWell(
          onTap: line.timeMs == null
              ? null
              : () => onSeek(
                  lyricLinePlaybackPositionMs(
                    lineTimeMs: line.timeMs!,
                    lrcOffsetMs: resolved.parsed.offsetMs,
                    userOffsetMs: resolved.userOffsetMs,
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: isActive ? 20 : 16.5,
                    height: 1.35,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.55),
                  ),
                  child: Text(line.text),
                ),
                if (line.translation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line.translation!,
                      style: TextStyle(
                        fontSize: isActive ? 15 : 13.5,
                        color: isActive
                            ? scheme.primary.withValues(alpha: 0.8)
                            : scheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
