import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/lyrics/lrc_parser.dart';
import 'package:nuvtune/features/lyrics/animated_lyrics_line.dart';
import 'package:nuvtune/features/lyrics/lyrics_animation_style.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

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

  /// Una llave por linea, para centrar la activa con `Scrollable.ensureVisible`
  /// en vez de calcular un offset a mano: con tipografia grande una linea larga
  /// ocupa mas de un renglon, asi que ninguna altura fija por linea es correcta.
  List<GlobalKey> _lineKeys = [];

  void _ensureLineKeys(int count) {
    if (_lineKeys.length == count) return;
    _lineKeys = List.generate(count, (_) => GlobalKey());
  }

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

        _ensureLineKeys(resolved.parsed.lines.length);
        final scheme = Theme.of(context).colorScheme;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 2),
              child: Text(
                resolved.source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _FadeEdges(
                      child: resolved.parsed.synchronized
                          ? _SyncedLyrics(
                              resolved: resolved,
                              scrollController: _scrollController,
                              autoScroll: _autoScroll,
                              lineKeys: _lineKeys,
                              onScrolledTo: (index) =>
                                  _lastScrolledIndex = index,
                              lastScrolledIndex: _lastScrolledIndex,
                              onSeek: (timeMs) => ref
                                  .read(playbackProvider.notifier)
                                  .seek(timeMs),
                            )
                          : _PlainLyrics(
                              resolved: resolved,
                              scrollController: _scrollController,
                            ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _LyricsFloatingControls(
                      synchronized: resolved.parsed.synchronized,
                      autoScroll: _autoScroll,
                      onAutoScrollChanged: (value) =>
                          setState(() => _autoScroll = value),
                      onEdit: () => _editLyrics(resolved),
                      onAdjustOffset: resolved.parsed.synchronized
                          ? () => _adjustOffset(resolved)
                          : null,
                    ),
                  ),
                ],
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

/// Controles flotantes minimos sobre la letra, en vez de una barra fija que le
/// quita espacio a la pantalla: solo el icono, translucidos, en una esquina.
class _LyricsFloatingControls extends StatelessWidget {
  const _LyricsFloatingControls({
    required this.synchronized,
    required this.autoScroll,
    required this.onAutoScrollChanged,
    required this.onEdit,
    this.onAdjustOffset,
  });

  final bool synchronized;
  final bool autoScroll;
  final ValueChanged<bool> onAutoScrollChanged;
  final VoidCallback onEdit;
  final VoidCallback? onAdjustOffset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      radius: Tokens.radiusPill,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (synchronized)
            _button(
              icon: autoScroll
                  ? Icons.vertical_align_center_rounded
                  : Icons.swipe_vertical_rounded,
              tooltip: AppStrings.lyricsAutoScroll,
              color: autoScroll ? scheme.primary : null,
              onPressed: () => onAutoScrollChanged(!autoScroll),
            ),
          if (onAdjustOffset != null)
            _button(
              icon: Icons.timer_outlined,
              tooltip: AppStrings.lyricsOffset,
              onPressed: onAdjustOffset!,
            ),
          _button(
            icon: Icons.edit_outlined,
            tooltip: AppStrings.lyricsEdit,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _button({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon, size: 19, color: color),
    onPressed: onPressed,
  );
}

/// Difumina los bordes superior e inferior de la letra en vez de cortarla en
/// seco, para que una linea entrando o saliendo del area visible se sienta
/// continua.
class _FadeEdges extends StatelessWidget {
  const _FadeEdges({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.07, 0.92, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

/// Sombra que mantiene el texto legible sin importar cuan clara sea la
/// portada difuminada detras: el fondo del reproductor lo elige la cancion,
/// no la pantalla de letras.
const _lyricTextShadows = [
  Shadow(color: Color(0x8A000000), blurRadius: 12, offset: Offset(0, 1)),
];

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.resolved, required this.scrollController});

  final ResolvedLyrics resolved;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      itemCount: resolved.parsed.lines.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Text(
          resolved.parsed.lines[index].text,
          style: TextStyle(
            fontSize: 19,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            shadows: _lyricTextShadows,
          ),
        ),
      ),
    );
  }
}

class _SyncedLyrics extends ConsumerWidget {
  const _SyncedLyrics({
    required this.resolved,
    required this.scrollController,
    required this.autoScroll,
    required this.lineKeys,
    required this.onScrolledTo,
    required this.lastScrolledIndex,
    required this.onSeek,
  });

  final ResolvedLyrics resolved;
  final ScrollController scrollController;
  final bool autoScroll;

  /// Una llave por linea (mismo orden e indice que `resolved.parsed.lines`),
  /// para poder centrar la activa sin asumir una altura fija por linea.
  final List<GlobalKey> lineKeys;
  final ValueChanged<int> onScrolledTo;
  final int lastScrolledIndex;
  final ValueChanged<int> onSeek;

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
        final lineContext = lineKeys[activeIndex].currentContext;
        if (lineContext == null) return;
        Scrollable.ensureVisible(
          lineContext,
          alignment: 0.42,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    }

    final scheme = Theme.of(context).colorScheme;
    final animationStyle = LyricsAnimationStyle.byId(
      ref.watch(settingsProvider).valueOrNull?.lyricsAnimationStyle,
    );
    final baseStyle =
        (Theme.of(context).textTheme.headlineSmall ??
                const TextStyle(fontSize: 24))
            .copyWith(height: 1.3, shadows: _lyricTextShadows);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      itemCount: resolved.parsed.lines.length,
      itemBuilder: (context, index) {
        final line = resolved.parsed.lines[index];
        final isActive = index == activeIndex;

        if (line.text.isEmpty) {
          return SizedBox(key: lineKeys[index], height: 24);
        }

        return InkWell(
          key: lineKeys[index],
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedLyricsLine(
                  text: line.text,
                  active: isActive,
                  progress: isActive && line.timeMs != null
                      ? synchronizedLyricProgress(
                          positionMs: position?.positionMs ?? 0,
                          lineStartMs: lyricLinePlaybackPositionMs(
                            lineTimeMs: line.timeMs!,
                            lrcOffsetMs: resolved.parsed.offsetMs,
                            userOffsetMs: resolved.userOffsetMs,
                          ),
                          nextLineStartMs:
                              index + 1 < resolved.parsed.lines.length &&
                                  resolved.parsed.lines[index + 1].timeMs !=
                                      null
                              ? lyricLinePlaybackPositionMs(
                                  lineTimeMs:
                                      resolved.parsed.lines[index + 1].timeMs!,
                                  lrcOffsetMs: resolved.parsed.offsetMs,
                                  userOffsetMs: resolved.userOffsetMs,
                                )
                              : null,
                        )
                      : 0,
                  style: animationStyle,
                  baseStyle: baseStyle,
                  activeColor: scheme.primary,
                  inactiveColor: scheme.onSurface.withValues(alpha: 0.4),
                  textAlign: TextAlign.start,
                ),
                if (line.translation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      line.translation!,
                      style: TextStyle(
                        fontSize: isActive ? 16 : 14.5,
                        shadows: _lyricTextShadows,
                        color: isActive
                            ? scheme.primary.withValues(alpha: 0.8)
                            : scheme.onSurface.withValues(alpha: 0.35),
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
