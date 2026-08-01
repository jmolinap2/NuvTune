import 'dart:math' as math;
import 'dart:ui';

// Flutter expone su propio RepeatMode para animaciones; aqui RepeatMode es
// siempre el modo de repeticion del contrato con el motor.
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/app_theme.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/equalizer/equalizer_screen.dart';
import 'package:nuvtune/features/lyrics/lyrics_view.dart';
import 'package:nuvtune/features/player/audio_visualizer.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/sleep_timer_sheet.dart';
import 'package:nuvtune/features/queue/queue_list.dart';
import 'package:nuvtune/features/video_background/music_video_background.dart';
import 'package:nuvtune/features/video_background/video_background_controller.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';
import 'package:nuvtune/shared/widgets/cover_cache.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/glass.dart';
import 'package:nuvtune/shared/widgets/song_actions_sheet.dart';

/// Reproductor completo (requerimiento seccion 11).
///
/// Las cuatro vistas que pide el requerimiento (portada, cola, letras y
/// efectos) son pestanas de esta misma pantalla, con la informacion tecnica
/// disponible desde el menu.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );
  bool _appIsVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController.addListener(_syncAudioAnalysis);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAudioAnalysis());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsVisible = state == AppLifecycleState.resumed;
    _syncAudioAnalysis();
  }

  void _syncAudioAnalysis() {
    if (!mounted) return;
    ref
        .read(playbackProvider.notifier)
        .setAudioAnalysisEnabled(_appIsVisible && _tabController.index == 0);
  }

  @override
  void dispose() {
    ref.read(engineProvider).api.setAudioAnalysisEnabled(false);
    _tabController.removeListener(_syncAudioAnalysis);
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackProvider);
    final song = state.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.nowPlaying)),
        body: const EmptyState(
          icon: Icons.music_note_rounded,
          title: AppStrings.emptyQueue,
          message: 'Elige una canción en la biblioteca para empezar.',
        ),
      );
    }

    // Colores tomados de la portada (requerimiento seccion 12). Si el usuario
    // los desactiva, se mantiene la identidad elegida en Apariencia.
    final appearance = ThemeScope.of(context);
    final dominant = appearance.dynamicFromCover
        ? ref.watch(coverAccentProvider(song.id)).valueOrNull
        : null;
    final accent = dominant == null
        ? appearance.accent
        : AccentIdentity.fromCover(dominant);
    final videoBackgroundId = ref.watch(videoBackgroundIdProvider).valueOrNull;

    // Se vuelve a declarar el ambito para que las tarjetas de vidrio y el boton
    // de reproduccion tomen el color de la portada, no el general.
    return ThemeScope(
      appearance: appearance.withAccent(accent),
      child: Theme(
        data: AppTheme.dark(accent: accent, depth: appearance.depth),
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 650),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _ImmersivePlayerBackground(
                      key: ValueKey('background-${song.id}-$videoBackgroundId'),
                      song: song,
                      isPlaying: state.isPlaying,
                      videoId: videoBackgroundId,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: accent.headerGradient(
                        scheme.surface.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        _PlayerAppBar(song: song),
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          tabs: const [
                            Tab(text: AppStrings.nowPlaying),
                            Tab(text: AppStrings.lyrics),
                            Tab(text: AppStrings.queue),
                            Tab(text: AppStrings.effects),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _NowPlayingTab(song: song),
                              LyricsView(song: song),
                              const QueueList(),
                              const _EffectsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImmersivePlayerBackground extends StatelessWidget {
  const _ImmersivePlayerBackground({
    required this.song,
    required this.isPlaying,
    required this.videoId,
    super.key,
  });

  final Song song;
  final bool isPlaying;
  final String? videoId;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              math.max(constraints.maxWidth, constraints.maxHeight) * 1.15;
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
                  child: Opacity(
                    opacity: videoId == null ? 0.3 : 0.24,
                    child: SizedBox.square(
                      dimension: size,
                      child: videoId == null
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: CoverArt(
                                song: song,
                                size: 480,
                                borderRadius: 0,
                                fallback: ReactiveAudioVisualizer(
                                  song: song,
                                  size: 480,
                                  borderRadius: 0,
                                  isPlaying: isPlaying,
                                ),
                              ),
                            )
                          : MusicVideoBackground(
                              key: ValueKey(videoId),
                              videoId: videoId!,
                            ),
                    ),
                  ),
                ),
              ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerAppBar extends ConsumerWidget {
  const _PlayerAppBar({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider);
    final timerRemaining = state.snapshot.sleepTimerRemainingMs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            tooltip: AppStrings.close,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  AppStrings.nowPlaying.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  state.outputName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.sleepTimer,
            icon: Icon(
              timerRemaining == null
                  ? Icons.bedtime_outlined
                  : Icons.bedtime_rounded,
              color: timerRemaining == null
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => showSleepTimerSheet(context),
          ),
          IconButton(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () =>
                showSongActions(context, song: song, contextSongs: state.queue),
          ),
        ],
      ),
    );
  }
}

/// Pestana "Efectos" del reproductor completo (requerimiento seccion 11).
///
/// Monta el mismo cuerpo que la pantalla "Ecualizador y mejora" en lugar de una
/// version reducida: los dos sitios ajustan el mismo estado y no tendria
/// sentido que ofrecieran controles distintos.
class _EffectsTab extends ConsumerWidget {
  const _EffectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(equalizerStateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('$error')),
      data: (state) => EqualizerBody(state: state, settings: settings),
    );
  }
}

class _NowPlayingTab extends ConsumerStatefulWidget {
  const _NowPlayingTab({required this.song});

  final Song song;

  @override
  ConsumerState<_NowPlayingTab> createState() => _NowPlayingTabState();
}

class _NowPlayingTabState extends ConsumerState<_NowPlayingTab> {
  late final PageController _pageController;
  late int _previewIndex;
  late int _lastEngineIndex;

  @override
  void initState() {
    super.initState();
    final state = ref.read(playbackProvider);
    final initial = state.snapshot.currentIndex < 0
        ? 0
        : state.snapshot.currentIndex
              .clamp(0, math.max(0, state.queue.length - 1))
              .toInt();
    _previewIndex = initial;
    _lastEngineIndex = initial;
    _pageController = PageController(
      initialPage: initial,
      viewportFraction: 0.84,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _handleCarouselScroll(ScrollNotification notification) {
    final page = _pageController.hasClients ? _pageController.page : null;
    if (page != null) {
      final queueLength = ref.read(playbackProvider).queue.length;
      final target = page
          .round()
          .clamp(0, math.max(0, queueLength - 1))
          .toInt();
      if (target != _previewIndex && mounted) {
        setState(() => _previewIndex = target);
      }
    }
    if (notification is ScrollEndNotification) _commitVisiblePage();
    return false;
  }

  void _commitVisiblePage() {
    if (!_pageController.hasClients) return;
    final state = ref.read(playbackProvider);
    if (state.queue.isEmpty) return;
    final target =
        (_pageController.page ?? state.snapshot.currentIndex.toDouble())
            .round()
            .clamp(0, state.queue.length - 1)
            .toInt();
    if (target == state.snapshot.currentIndex) return;
    HapticFeedback.selectionClick();
    ref.read(playbackProvider.notifier).playQueueIndex(target);
  }

  void _showPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: Tokens.durationMedium,
      curve: Curves.easeOutCubic,
    );
  }

  void _syncWithEngine(int engineIndex) {
    if (engineIndex < 0 || engineIndex == _lastEngineIndex) return;
    _lastEngineIndex = engineIndex;
    _previewIndex = engineIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page ?? engineIndex.toDouble();
      if ((page - engineIndex).abs() < 0.01) return;
      _pageController.animateToPage(
        engineIndex,
        duration: Tokens.durationMedium,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackProvider);
    final engineIndex = state.snapshot.currentIndex;
    _syncWithEngine(engineIndex);
    final safePreviewIndex = state.queue.isEmpty
        ? 0
        : _previewIndex.clamp(0, state.queue.length - 1).toInt();
    final displaySong = state.queue.isEmpty
        ? widget.song
        : state.queue[safePreviewIndex];
    final controller = ref.read(playbackProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final favorites = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favorites.contains(displaySong.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final carouselWidth = constraints.maxWidth - 48;
        final coverSize = math
            .min(carouselWidth * 0.84 - 12, constraints.maxHeight * 0.46)
            .clamp(156.0, 440.0)
            .toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              SizedBox(
                width: carouselWidth,
                height: coverSize + 16,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleCarouselScroll,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: state.queue.length,
                    physics: state.queue.length > 1
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = state.queue[index];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          final page = _pageController.hasClients
                              ? (_pageController.page ?? engineIndex.toDouble())
                              : engineIndex.toDouble();
                          final distance = (page - index)
                              .abs()
                              .clamp(0.0, 1.0)
                              .toDouble();
                          return Transform.translate(
                            offset: Offset(0, distance * 8),
                            child: Transform.scale(
                              scale: 1 - distance * 0.065,
                              child: Opacity(
                                opacity: 1 - distance * 0.28,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () => _showPage(index),
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: index == engineIndex && state.isPlaying
                                      ? scheme.primary.withValues(alpha: 0.7)
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: index == engineIndex && state.isPlaying
                                      ? 1.6
                                      : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withValues(
                                      alpha:
                                          index == engineIndex &&
                                              state.isPlaying
                                          ? 0.24
                                          : 0.08,
                                    ),
                                    blurRadius: index == engineIndex ? 26 : 12,
                                    spreadRadius: index == engineIndex ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(1),
                                child: Builder(
                                  builder: (context) {
                                    final artwork = CoverArt(
                                      song: item,
                                      size: coverSize,
                                      borderRadius: 24,
                                      fallback: ReactiveAudioVisualizer(
                                        key: ValueKey('visualizer-${item.id}'),
                                        song: item,
                                        size: coverSize,
                                        borderRadius: 24,
                                        isPlaying:
                                            state.isPlaying &&
                                            index == engineIndex,
                                        allowStyleSelection:
                                            index == engineIndex,
                                      ),
                                    );
                                    return index == engineIndex
                                        ? Hero(
                                            tag: 'now-playing-cover-${item.id}',
                                            child: artwork,
                                          )
                                        : artwork;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Se reserva la altura de dos lineas del titulo aunque
                        // la cancion actual solo necesite una: si no, cada
                        // titulo largo o corto empuja los controles arriba y
                        // abajo al cambiar de pista.
                        Builder(
                          builder: (context) {
                            final titleStyle = Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                );
                            final lineHeight =
                                (titleStyle?.fontSize ?? 22) *
                                (titleStyle?.height ?? 1.2);
                            final reserved =
                                MediaQuery.textScalerOf(
                                  context,
                                ).scale(lineHeight) *
                                2;
                            return SizedBox(
                              height: reserved,
                              child: Text(
                                displaySong.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () =>
                              context.push('/artist/${displaySong.artistId}'),
                          child: Text(
                            displaySong.displayArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () =>
                              context.push('/album/${displaySong.albumId}'),
                          child: Text(
                            displaySong.displayAlbum,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 28,
                    tooltip: AppStrings.favorite,
                    onPressed: () => controller.toggleFavorite(displaySong.id),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? scheme.primary : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const _ProgressBar(),
              const SizedBox(height: 4),

              // Formato y calidad, siempre visibles (requerimiento 4.2).
              AnimatedSwitcher(
                duration: Tokens.durationFast,
                child: _FormatChips(
                  key: ValueKey(displaySong.id),
                  song: displaySong,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 24,
                    tooltip: state.snapshot.shuffleEnabled
                        ? 'Aleatorio activado'
                        : AppStrings.shuffle,
                    onPressed: controller.toggleShuffle,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: state.snapshot.shuffleEnabled
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    iconSize: 38,
                    tooltip: 'Anterior',
                    onPressed: controller.skipPrevious,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  _PlayPauseButton(isPlaying: state.isPlaying),
                  IconButton(
                    iconSize: 38,
                    tooltip: 'Siguiente',
                    onPressed: controller.skipNext,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                  IconButton(
                    iconSize: 24,
                    tooltip: switch (state.snapshot.repeatMode) {
                      RepeatMode.off => AppStrings.repeatOff,
                      RepeatMode.all => AppStrings.repeatAll,
                      RepeatMode.one => AppStrings.repeatOne,
                    },
                    onPressed: controller.cycleRepeatMode,
                    icon: Icon(
                      state.snapshot.repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: state.snapshot.repeatMode == RepeatMode.off
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.seekRelative(-10000),
                    icon: const Icon(Icons.replay_10_rounded, size: 20),
                    label: const Text('10 s'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => controller.seekRelative(30000),
                    icon: const Icon(Icons.forward_30_rounded, size: 20),
                    label: const Text('30 s'),
                  ),
                ],
              ),

              if (engineIndex >= 0 && engineIndex + 1 < state.queue.length)
                Padding(
                  padding: const EdgeInsets.only(top: Tokens.space2),
                  child: TextButton.icon(
                    onPressed: () => _showPage(engineIndex + 1),
                    icon: const Icon(Icons.queue_music_rounded, size: 18),
                    label: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - 96,
                      ),
                      child: Text(
                        'A continuación · ${state.queue[engineIndex + 1].title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

              if (state.snapshot.sleepTimerRemainingMs != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'La música se detendrá en '
                    '${Formatters.duration(state.snapshot.sleepTimerRemainingMs!)}',
                    style: TextStyle(fontSize: 12, color: scheme.primary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayPauseButton extends ConsumerWidget {
  const _PlayPauseButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pausar' : 'Reproducir',
      child: GradientPlayButton(
        isPlaying: isPlaying,
        onPressed: () {
          // Respuesta hactica: en un reproductor muchas acciones se hacen sin
          // mirar la pantalla.
          HapticFeedback.lightImpact();
          ref.read(playbackProvider.notifier).togglePlayPause();
        },
      ),
    );
  }
}

class _ProgressBar extends ConsumerStatefulWidget {
  const _ProgressBar();

  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  /// Posicion mientras el usuario arrastra, para que la barra no vuelva atras
  /// cada vez que llega una actualizacion del motor.
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final duration = ref.watch(playbackProvider.select((s) => s.durationMs));
    final position = ref.watch(playbackPositionProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    final currentMs = _dragValue ?? (position?.positionMs.toDouble() ?? 0);
    final maxMs = duration <= 0 ? 1.0 : duration.toDouble();

    return Column(
      children: [
        Slider(
          value: currentMs.clamp(0, maxMs),
          max: maxMs,
          onChanged: (value) => setState(() => _dragValue = value),
          onChangeEnd: (value) {
            ref.read(playbackProvider.notifier).seek(value.round());
            setState(() => _dragValue = null);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.duration(currentMs.round()),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Text(
                Formatters.duration(duration),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormatChips extends StatelessWidget {
  const _FormatChips({required this.song, super.key});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip(context, song.mimeType.split('/').last.toUpperCase()),
        if (song.isLossless) _chip(context, 'Sin pérdida', highlight: true),
        _chip(context, Formatters.fileSize(song.sizeBytes)),
        InkWell(
          onTap: () => showTechnicalInfo(context, song: song),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: scheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.technicalInfo,
                  style: TextStyle(fontSize: 11.5, color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, {bool highlight = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: highlight
            ? scheme.primary.withValues(alpha: 0.18)
            : scheme.surfaceContainerHigh,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: highlight ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
