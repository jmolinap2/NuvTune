import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

// Flutter expone su propio RepeatMode para animaciones; aqui RepeatMode es
// siempre el modo de repeticion del contrato con el motor.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/system_ui.dart';
import 'package:nuvtune/app/theme/app_theme.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/data/repositories/cover_repository.dart';
import 'package:nuvtune/features/equalizer/equalizer_screen.dart';
import 'package:nuvtune/features/lyrics/lrc_parser.dart';
import 'package:nuvtune/features/lyrics/lyrics_view.dart';
import 'package:nuvtune/features/player/audio_visualizer.dart';
import 'package:nuvtune/features/player/customizable_player_controls.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/player_scene_aspect_ratio.dart';
import 'package:nuvtune/features/player/player_visual_scene.dart';
import 'package:nuvtune/features/queue/queue_list.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
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
bool _songHasArtwork(Song song, Map<String, String> customCovers) {
  final customPath =
      customCovers[CoverRepository.songTarget(song.id)] ??
      customCovers[CoverRepository.albumTarget(song.albumId)];
  return song.hasCover || (customPath != null && File(customPath).existsSync());
}

/// Sustituto estático para el modo Portada cuando el archivo no trae imagen.
/// No usa iniciales ni movimiento: respeta literalmente la elección de no ver
/// vídeo, letras o visualizaciones reactivas.
class _StaticCoverFallback extends StatelessWidget {
  const _StaticCoverFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = math.max(constraints.maxWidth, constraints.maxHeight);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer,
                scheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -extent * 0.14,
                top: -extent * 0.18,
                child: Container(
                  width: extent * 0.72,
                  height: extent * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.1),
                      width: math.max(2, extent * 0.018),
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.album_rounded,
                  size: extent * 0.34,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _systemVolumeChannel = MethodChannel('com.nuvtune.app/system_volume');

// Dos escenas pueden sucederse mientras una consulta de letras sigue en vuelo
// (por ejemplo al abrir pantalla completa). Compartir el Future por canción
// evita repetir la petición y permite que la escena que siga montada guarde el
// resultado. Los fallos y respuestas vacías se retiran para permitir reintento.
final Map<int, Future<String?>> _lyricsSceneRequests = {};

Future<String?> _requestLyricsForScene({
  required MusicEngineHostApi engineApi,
  required Song song,
}) {
  final existing = _lyricsSceneRequests[song.id];
  if (existing != null) return existing;

  final artist = _onlineLyricsArtist(song.artist);
  final request = () async {
    var content = await engineApi.fetchLyricsOnline(
      song.title,
      artist,
      song.album,
      song.durationMs,
    );
    if ((content == null || content.trim().isEmpty) &&
        song.album.trim().isNotEmpty) {
      content = await engineApi.fetchLyricsOnline(
        song.title,
        artist,
        '',
        song.durationMs,
      );
    }
    return content;
  }();
  _lyricsSceneRequests[song.id] = request;
  unawaited(
    request.then<void>(
      (content) {
        if ((content == null || content.trim().isEmpty) &&
            identical(_lyricsSceneRequests[song.id], request)) {
          _lyricsSceneRequests.remove(song.id);
        } else if (content != null && content.trim().isNotEmpty) {
          // La base de datos es el caché duradero. Este margen solo cubre la
          // transición entre escenas; luego se libera también el texto.
          Timer(const Duration(seconds: 30), () {
            if (identical(_lyricsSceneRequests[song.id], request)) {
              _lyricsSceneRequests.remove(song.id);
            }
          });
        }
      },
      onError: (Object _, StackTrace _) {
        if (identical(_lyricsSceneRequests[song.id], request)) {
          _lyricsSceneRequests.remove(song.id);
        }
      },
    ),
  );
  return request;
}

String _onlineLyricsArtist(String value) {
  final artist = value.trim();
  if (artist.isEmpty ||
      artist == '<unknown>' ||
      artist.toLowerCase() == 'artista desconocido') {
    return '';
  }
  return artist;
}

enum _VisualizationAction { fullscreen, scene, style }

Future<void> _openFullscreenPlayer(
  BuildContext context,
  Song song,
  PlayerVisualScene initialScene,
) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _FullscreenPlayerPage(initialSong: song, initialScene: initialScene),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: child,
        ),
  ),
);

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
  late final MusicEngineHostApi _engineApi;
  bool _appIsVisible = true;
  bool _visualizerVisible = false;
  bool _fullscreenOpen = false;
  bool? _audioAnalysisEnabled;
  String? _videoReadinessId;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _engineApi = ref.read(engineProvider).api;
    usePlayerSystemUi();
    WidgetsBinding.instance.addObserver(this);
    _tabController.addListener(_syncAudioAnalysis);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAudioAnalysis());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (_appIsVisible != visible && mounted) {
      setState(() => _appIsVisible = visible);
    }
    if (_appIsVisible) usePlayerSystemUi();
    _syncAudioAnalysis();
  }

  void _syncAudioAnalysis() {
    if (!mounted) return;
    final enabled =
        _appIsVisible &&
        !_fullscreenOpen &&
        _tabController.index == 0 &&
        _visualizerVisible;
    if (_audioAnalysisEnabled == enabled) return;
    _audioAnalysisEnabled = enabled;
    ref.read(playbackProvider.notifier).setAudioAnalysisEnabled(enabled);
  }

  void _setVisualizerVisible(bool visible) {
    if (_visualizerVisible == visible) return;
    _visualizerVisible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAudioAnalysis());
  }

  void _restoreAudioAnalysisAfterFullscreen() {
    // La ruta de pantalla completa habilita el FFT por su cuenta. Al volver se
    // fuerza la escritura aunque el valor lógico del padre no haya cambiado.
    _audioAnalysisEnabled = null;
    _syncAudioAnalysis();
  }

  Future<void> _showFullscreenPlayer(Song song, PlayerVisualScene scene) async {
    if (_fullscreenOpen) return;
    setState(() => _fullscreenOpen = true);
    _syncAudioAnalysis();
    // El WebView de la pantalla normal sale del arbol antes de crear el de la
    // vista inmersiva. Asi no quedan dos videos ni dos superficies Android.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      await _openFullscreenPlayer(context, song, scene);
    } finally {
      if (mounted) {
        setState(() => _fullscreenOpen = false);
        _restoreAudioAnalysisAfterFullscreen();
      }
    }
  }

  void _handleVideoReadiness(String videoId, bool ready) {
    if (!mounted || _videoReadinessId != videoId || _videoReady == ready) {
      return;
    }
    setState(() => _videoReady = ready);
  }

  @override
  void dispose() {
    useDefaultSystemUi();
    // Riverpod invalida `ref` durante el desmontaje. Se conserva el API que ya
    // estaba vivo para cerrar el analisis sin leer providers desde dispose.
    unawaited(_engineApi.setAudioAnalysisEnabled(false));
    _tabController.removeListener(_syncAudioAnalysis);
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));

    if (song == null) {
      _setVisualizerVisible(false);
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.nowPlaying)),
        body: const EmptyState(
          icon: Icons.music_note_rounded,
          title: AppStrings.emptyQueue,
          message: 'Elige una canción en la biblioteca para empezar.',
        ),
      );
    }

    // La ruta fullscreen es opaca y monta su propia escena. Mientras está
    // abierta se retira todo el árbol visual normal (incluidas pestañas y
    // consultas) para no conservar trabajo invisible detrás de ella.
    if (_fullscreenOpen) {
      _setVisualizerVisible(false);
      return const Scaffold(
        backgroundColor: Color(0xFF02050D),
        body: SizedBox.expand(),
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
    final settings = ref.watch(settingsProvider).valueOrNull;
    final visualScene = PlayerVisualScene.fromIndex(
      settings?.playerVisualScene ?? 0,
    );
    // No se observa ni se ejecuta el proveedor de YouTube en Visualizador,
    // Letras o Portada. La pantalla normal tambien lo desmonta mientras la
    // experiencia inmersiva esta abierta.
    final videoBackgroundId = visualScene.requestsVideo && _appIsVisible
        ? ref.watch(videoBackgroundIdProvider).valueOrNull
        : null;
    if (_videoReadinessId != videoBackgroundId) {
      _videoReadinessId = videoBackgroundId;
      _videoReady = false;
    }
    final videoReady = videoBackgroundId != null && _videoReady;
    final visualizerVisible = visualScene.showsVisualizer;
    _setVisualizerVisible(visualizerVisible);
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
                  _ImmersivePlayerBackground(
                    key: ValueKey('background-${song.id}'),
                    song: song,
                    isPlaying: isPlaying,
                    videoId: videoBackgroundId,
                    // El visualizador principal ya ocupa el escenario. Mantener
                    // otro painter reactivo desenfocado detrás duplicaba el
                    // trabajo de GPU sin aportar detalle visible.
                    animateFallback: false,
                    onVideoReadinessChanged: _handleVideoReadiness,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: !videoReady
                          ? accent.headerGradient(
                              scheme.surface.withValues(alpha: 0.92),
                            )
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.12),
                                scheme.surface.withValues(alpha: 0.34),
                                scheme.surface.withValues(alpha: 0.9),
                              ],
                              stops: const [0, 0.56, 1],
                            ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        _PlayerAppBar(
                          song: song,
                          onOpenFullscreen: (scene) =>
                              _showFullscreenPlayer(song, scene),
                        ),
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
                              // TickerMode apaga el Ticker del visualizador de
                              // respaldo (para canciones sin portada) en
                              // cuanto esta pestana deja de ser la activa;
                              // TabBarView mantiene el widget montado para el
                              // swipe, pero sin esto seguia animando fuera de
                              // pantalla.
                              AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, child) => TickerMode(
                                  enabled: _tabController.index == 0,
                                  child: child!,
                                ),
                                child: _NowPlayingTab(
                                  song: song,
                                  visualScene: visualScene,
                                  videoAvailable: videoReady,
                                  onOpenLyrics: () =>
                                      _tabController.animateTo(1),
                                  onOpenFullscreen: _showFullscreenPlayer,
                                ),
                              ),
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

class _FullscreenPlayerPage extends ConsumerStatefulWidget {
  const _FullscreenPlayerPage({
    required this.initialSong,
    required this.initialScene,
  });

  final Song initialSong;
  final PlayerVisualScene initialScene;

  @override
  ConsumerState<_FullscreenPlayerPage> createState() =>
      _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends ConsumerState<_FullscreenPlayerPage>
    with WidgetsBindingObserver {
  static const _swipeDistanceThreshold = 72.0;
  static const _swipeVelocityThreshold = 560.0;

  Timer? _chromeTimer;
  Timer? _gestureFeedbackTimer;
  late final MusicEngineHostApi _engineApi;
  late PlayerVisualScene _scene;
  late PlayerSceneAspectRatio _aspectRatio;
  bool _appIsVisible = true;
  bool? _audioAnalysisEnabled;
  bool _chromeVisible = true;
  bool _lyricsContentScrollable = false;
  int? _lyricsScrollSongId;
  double _horizontalDragDistance = 0;
  double _verticalDragDistance = 0;
  double? _systemVolume;
  bool _verticalControlsVolume = false;
  IconData? _gestureFeedbackIcon;
  String? _gestureFeedbackLabel;

  @override
  void initState() {
    super.initState();
    _engineApi = ref.read(engineProvider).api;
    _scene = widget.initialScene;
    _aspectRatio = PlayerSceneAspectRatio.fromIndex(
      ref.read(settingsProvider).valueOrNull?.playerSceneAspectRatio ?? 0,
    );
    WidgetsBinding.instance.addObserver(this);
    useVisualizerFullscreenSystemUi();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAudioAnalysis();
      unawaited(_readSystemVolume());
      _scheduleChromeHide();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (_appIsVisible != visible && mounted) {
      setState(() => _appIsVisible = visible);
    }
    if (_appIsVisible) {
      useVisualizerFullscreenSystemUi();
    }
    _syncAudioAnalysis();
  }

  void _syncAudioAnalysis() {
    if (!mounted) return;
    final enabled = _appIsVisible && _scene == PlayerVisualScene.visualizer;
    if (_audioAnalysisEnabled == enabled) return;
    _audioAnalysisEnabled = enabled;
    ref.read(playbackProvider.notifier).setAudioAnalysisEnabled(enabled);
  }

  Future<void> _chooseScene() async {
    final choice = await showPlayerVisualScenePicker(context, selected: _scene);
    if (!mounted || choice == null || choice == _scene) {
      _scheduleChromeHide();
      return;
    }
    setState(() {
      _scene = choice;
      _lyricsContentScrollable = false;
    });
    _audioAnalysisEnabled = null;
    _syncAudioAnalysis();
    await ref
        .read(settingsRepositoryProvider)
        .update(AppSettingsCompanion(playerVisualScene: Value(choice.index)));
    if (!mounted) return;
    _scheduleChromeHide();
  }

  Future<void> _chooseAspectRatio() async {
    final choice = await showPlayerSceneAspectRatioPicker(
      context,
      selected: _aspectRatio,
    );
    if (!mounted || choice == null || choice == _aspectRatio) {
      _scheduleChromeHide();
      return;
    }
    setState(() => _aspectRatio = choice);
    await ref
        .read(settingsRepositoryProvider)
        .update(
          AppSettingsCompanion(playerSceneAspectRatio: Value(choice.index)),
        );
    if (!mounted) return;
    _scheduleChromeHide();
  }

  void _scheduleChromeHide() {
    _chromeTimer?.cancel();
    _chromeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _scheduleChromeHide();
  }

  void _togglePlayback() {
    final willPlay = !ref.read(playbackProvider).isPlaying;
    ref.read(playbackProvider.notifier).togglePlayPause();
    unawaited(HapticFeedback.lightImpact());
    _showGestureFeedback(
      willPlay ? Icons.play_arrow_rounded : Icons.pause_rounded,
      willPlay ? 'Reproduciendo' : 'Pausa',
    );
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_horizontalDragDistance.abs() < _swipeDistanceThreshold &&
        velocity.abs() < _swipeVelocityThreshold) {
      return;
    }

    final direction = _horizontalDragDistance.abs() >= _swipeDistanceThreshold
        ? _horizontalDragDistance
        : velocity;
    _skipSong(next: direction < 0);
  }

  void _skipSong({required bool next}) {
    final controller = ref.read(playbackProvider.notifier);
    if (next) {
      controller.skipNext();
      _showGestureFeedback(Icons.skip_next_rounded, 'Siguiente');
    } else {
      controller.skipPrevious();
      _showGestureFeedback(Icons.skip_previous_rounded, 'Anterior');
    }
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _readSystemVolume() async {
    try {
      final value = await _systemVolumeChannel.invokeMethod<double>(
        'getMusicVolume',
      );
      if (mounted && value != null) {
        _systemVolume = value.clamp(0.0, 1.0);
      }
    } on PlatformException {
      // El resto de gestos sigue disponible si la plataforma no expone volumen.
    }
  }

  Future<void> _setSystemVolume(double value) async {
    try {
      await _systemVolumeChannel.invokeMethod<double>('setMusicVolume', {
        'volume': value,
      });
    } on PlatformException {
      // El gesto no debe interrumpir la visualización si Android lo rechaza.
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    final settings = ref.read(settingsProvider).valueOrNull;
    _verticalDragDistance = 0;
    _verticalControlsVolume =
        (settings?.playerGestureSwipeVolume ?? true) &&
        details.localPosition.dx >= MediaQuery.sizeOf(context).width * 0.62;
    if (_verticalControlsVolume && _systemVolume == null) {
      unawaited(_readSystemVolume());
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    _verticalDragDistance += delta;
    if (!_verticalControlsVolume || _systemVolume == null) return;

    final next =
        (_systemVolume! - delta / MediaQuery.sizeOf(context).height * 1.65)
            .clamp(0.0, 1.0)
            .toDouble();
    _systemVolume = next;
    unawaited(_setSystemVolume(next));
    _showGestureFeedback(
      next == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
      'Volumen ${(next * 100).round()} %',
    );
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_verticalControlsVolume) {
      _verticalControlsVolume = false;
      unawaited(HapticFeedback.selectionClick());
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final draggedDown = _verticalDragDistance > _swipeDistanceThreshold;
    final flickedDown = velocity > _swipeVelocityThreshold;
    final dismissEnabled =
        ref.read(settingsProvider).valueOrNull?.playerGestureSwipeDismiss ??
        true;
    if (dismissEnabled && (draggedDown || flickedDown)) {
      Navigator.of(context).maybePop();
    }
  }

  void _showGestureFeedback(IconData icon, String label) {
    _gestureFeedbackTimer?.cancel();
    setState(() {
      _gestureFeedbackIcon = icon;
      _gestureFeedbackLabel = label;
    });
    _gestureFeedbackTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        _gestureFeedbackIcon = null;
        _gestureFeedbackLabel = null;
      });
    });
  }

  void _setLyricsContentScrollable(bool value) {
    if (!mounted || !_scene.showsLyrics || _lyricsContentScrollable == value) {
      return;
    }
    setState(() => _lyricsContentScrollable = value);
  }

  @override
  void dispose() {
    _chromeTimer?.cancel();
    _gestureFeedbackTimer?.cancel();
    unawaited(_engineApi.setAudioAnalysisEnabled(false));
    WidgetsBinding.instance.removeObserver(this);
    usePlayerSystemUi();
    super.dispose();
  }

  Widget _buildFullscreenScene({
    required BuildContext context,
    required Song song,
    required bool isPlaying,
    required BoxConstraints constraints,
    required String? videoId,
  }) {
    Widget coverBackdrop({String? activeVideoId}) => _ImmersivePlayerBackground(
      key: ValueKey(
        'fullscreen-background-${song.id}-${activeVideoId ?? 'cover'}',
      ),
      song: song,
      isPlaying: isPlaying,
      videoId: activeVideoId,
      animateFallback: false,
      onVideoReadinessChanged: (_, _) {},
      letterbox: true,
    );

    return switch (_scene) {
      PlayerVisualScene.visualizer => Stack(
        fit: StackFit.expand,
        children: [
          // Fondo solido, no un degradado: cualquier tinte (incluso muy
          // oscuro) se nota detras de estilos con trazos dispersos como
          // ribbons o minimalSpectrum.
          const ColoredBox(color: Colors.black),
          ReactiveAudioVisualizer(
            key: ValueKey('fullscreen-visualizer-${song.id}'),
            song: song,
            size: constraints.maxWidth,
            height: constraints.maxHeight,
            borderRadius: 0,
            isPlaying: isPlaying,
            immersive: true,
          ),
        ],
      ),
      PlayerVisualScene.video => coverBackdrop(activeVideoId: videoId),
      PlayerVisualScene.both => Stack(
        fit: StackFit.expand,
        children: [
          coverBackdrop(activeVideoId: videoId),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(28, 92, 28, 118),
            child: _PlayerLyricsSceneStage(
              key: ValueKey('fullscreen-video-lyrics-${song.id}'),
              song: song,
              onOpenLyrics: () {},
              immersive: true,
              videoOverlay: true,
              showOpenAction: false,
              onScrollabilityChanged: _setLyricsContentScrollable,
            ),
          ),
        ],
      ),
      PlayerVisualScene.lyrics => Stack(
        fit: StackFit.expand,
        children: [
          coverBackdrop(),
          const ColoredBox(color: Color(0x66000000)),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(28, 92, 28, 118),
            child: _PlayerLyricsSceneStage(
              key: ValueKey('fullscreen-lyrics-${song.id}'),
              song: song,
              onOpenLyrics: () {},
              immersive: true,
              showOpenAction: false,
              onScrollabilityChanged: _setLyricsContentScrollable,
            ),
          ),
        ],
      ),
      PlayerVisualScene.cover => Stack(
        fit: StackFit.expand,
        children: [
          coverBackdrop(),
          const ColoredBox(color: Color(0x55000000)),
          Center(
            child: Builder(
              builder: (context) {
                final size = math
                    .min(
                      constraints.maxWidth * 0.88,
                      constraints.maxHeight * 0.68,
                    )
                    .clamp(240.0, 760.0)
                    .toDouble();
                return CoverArt(
                  song: song,
                  size: size,
                  borderRadius: 28,
                  fallback: const _StaticCoverFallback(),
                );
              },
            ),
          ),
        ],
      ),
    };
  }

  Widget _buildSceneStack({
    required BuildContext context,
    required Song song,
    required bool isPlaying,
    required String? videoId,
  }) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      fit: StackFit.expand,
      children: [
        _buildFullscreenScene(
          context: context,
          song: song,
          isPlaying: isPlaying,
          constraints: constraints,
          videoId: videoId,
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x99000000),
                ],
                stops: [0, 0.2, 0.68, 1],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTopControlsRow(BuildContext context) => Row(
    children: [
      _VisualizerChromeButton(
        tooltip: AppStrings.close,
        icon: Icons.close_rounded,
        onPressed: () => Navigator.of(context).pop(),
      ),
      const Spacer(),
      _VisualizerChromeButton(
        tooltip: 'Cambiar relación de aspecto',
        icon: Icons.aspect_ratio_rounded,
        onPressed: _chooseAspectRatio,
      ),
      const SizedBox(width: Tokens.space2),
      _VisualizerChromeButton(
        tooltip: 'Cambiar escena',
        icon: _scene.icon,
        onPressed: _chooseScene,
      ),
      if (_scene == PlayerVisualScene.visualizer) ...[
        const SizedBox(width: Tokens.space2),
        _VisualizerChromeButton(
          tooltip: 'Cambiar visualizador',
          icon: Icons.auto_awesome_rounded,
          onPressed: () async {
            await showVisualizerStylePicker(context, ref);
            _scheduleChromeHide();
          },
        ),
      ],
    ],
  );

  /// Título, artista y pista de gestos. Se superponen al escenario cuando
  /// este ocupa la pantalla entera; cuando hay una relación de aspecto
  /// acotada se renderizan fuera de la caja para no tapar el video.
  Widget _buildChromeFooter(
    BuildContext context,
    Song song,
    String gestureHint,
  ) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Tokens.space1),
        Text(
          song.displayArtist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Tokens.space2),
        Text(
          gestureHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(
      playbackProvider.select((s) => s.currentSong),
    );
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final controlSettings = ref.watch(settingsProvider).valueOrNull;
    final doubleTapEnabled = controlSettings?.playerGestureDoubleTap ?? true;
    final swipeTrackEnabled = controlSettings?.playerGestureSwipeTrack ?? true;
    final verticalGestureEnabled =
        (controlSettings?.playerGestureSwipeVolume ?? true) ||
        (controlSettings?.playerGestureSwipeDismiss ?? true);
    final song = currentSong ?? widget.initialSong;
    if (_lyricsScrollSongId != song.id) {
      _lyricsScrollSongId = song.id;
      _lyricsContentScrollable = false;
    }
    final videoId = _scene.requestsVideo && _appIsVisible
        ? ref.watch(videoBackgroundIdProvider).valueOrNull
        : null;
    final lyricsAreScrollable = _scene.showsLyrics && _lyricsContentScrollable;
    final gestureHint = lyricsAreScrollable
        ? '${_scene.label} · Toca: controles · '
              'Doble toque: reproducir/pausar · '
              '←/→: canción · Desliza para recorrer la letra'
        : '${_scene.label} · Toca: controles · '
              'Doble toque: reproducir/pausar · '
              '←/→: canción · ↑/↓ a la derecha: volumen · '
              '↓ en el centro: salir';
    // Con una relación de aspecto acotada, el escenario vive dentro de una
    // caja centrada y el pie de título/artista sale fuera de ella; a
    // pantalla completa el layout no cambia respecto al comportamiento previo.
    final boxed = _aspectRatio.ratio != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Semantics(
        container: true,
        explicitChildNodes: true,
        label: '${_scene.label} en pantalla completa. ${song.title}',
        hint:
            'Activa para mostrar u ocultar controles. '
            'Usa las acciones de accesibilidad para reproducir o cambiar de canción.',
        onTap: _toggleChrome,
        onIncrease: () => _skipSong(next: true),
        onDecrease: () => _skipSong(next: false),
        customSemanticsActions: {
          CustomSemanticsAction(label: isPlaying ? 'Pausar' : 'Reproducir'):
              _togglePlayback,
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleChrome,
          onDoubleTap: doubleTapEnabled ? _togglePlayback : null,
          onHorizontalDragStart: swipeTrackEnabled
              ? (_) => _horizontalDragDistance = 0
              : null,
          onHorizontalDragUpdate: swipeTrackEnabled
              ? (details) =>
                    _horizontalDragDistance += details.primaryDelta ?? 0
              : null,
          onHorizontalDragEnd: swipeTrackEnabled
              ? _handleHorizontalDragEnd
              : null,
          // Solo una letra no sincronizada necesita el eje vertical. Las
          // sincronizadas cambian de línea solas y conservan volumen/salir.
          onVerticalDragStart: lyricsAreScrollable || !verticalGestureEnabled
              ? null
              : _handleVerticalDragStart,
          onVerticalDragUpdate: lyricsAreScrollable || !verticalGestureEnabled
              ? null
              : _handleVerticalDragUpdate,
          onVerticalDragEnd: lyricsAreScrollable || !verticalGestureEnabled
              ? null
              : _handleVerticalDragEnd,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    boxed
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: _aspectRatio.ratio!,
                              child: Container(
                                // Fondo negro puro alrededor: sin este borde y
                                // esta sombra, un recuadro oscuro sobre fondo
                                // negro es casi imperceptible y la relación de
                                // aspecto parece no tener efecto.
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    Tokens.radiusLarge,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 32,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildSceneStack(
                                  context: context,
                                  song: song,
                                  isPlaying: isPlaying,
                                  videoId: videoId,
                                ),
                              ),
                            ),
                          )
                        : _buildSceneStack(
                            context: context,
                            song: song,
                            isPlaying: isPlaying,
                            videoId: videoId,
                          ),
                    IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: Tokens.durationFast,
                        reverseDuration: Tokens.durationFast,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.88, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                        child: _gestureFeedbackIcon == null
                            ? const SizedBox(
                                key: ValueKey('gesture-feedback-empty'),
                              )
                            : Center(
                                key: ValueKey(_gestureFeedbackLabel),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.54),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Tokens.space4,
                                      vertical: Tokens.space3,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _gestureFeedbackIcon,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(width: Tokens.space2),
                                        Text(
                                          _gestureFeedbackLabel!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    IgnorePointer(
                      ignoring: !_chromeVisible,
                      child: AnimatedOpacity(
                        opacity: _chromeVisible ? 1 : 0,
                        duration: Tokens.durationMedium,
                        child: SafeArea(
                          minimum: const EdgeInsets.all(Tokens.space3),
                          child: boxed
                              ? _buildTopControlsRow(context)
                              : Column(
                                  children: [
                                    _buildTopControlsRow(context),
                                    const Spacer(),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: _buildChromeFooter(
                                        context,
                                        song,
                                        gestureHint,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (boxed)
                IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    opacity: _chromeVisible ? 1 : 0,
                    duration: Tokens.durationMedium,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Tokens.gutter,
                        Tokens.space3,
                        Tokens.gutter,
                        Tokens.space4,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildChromeFooter(context, song, gestureHint),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualizerChromeButton extends StatelessWidget {
  const _VisualizerChromeButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.34),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      color: Colors.white,
      onPressed: onPressed,
    ),
  );
}

class _ImmersivePlayerBackground extends ConsumerStatefulWidget {
  const _ImmersivePlayerBackground({
    required this.song,
    required this.isPlaying,
    required this.videoId,
    required this.animateFallback,
    required this.onVideoReadinessChanged,
    this.letterbox = false,
    super.key,
  });

  final Song song;
  final bool isPlaying;
  final String? videoId;
  final bool animateFallback;
  final void Function(String videoId, bool ready) onVideoReadinessChanged;

  /// Cuando es `true` (solo pantalla completa), el video 16:9 se muestra
  /// completo y centrado en vez de recortado, y la portada ampliada y
  /// desenfocada se usa como relleno del espacio sobrante. Cuando es `false`
  /// (fondo ambiental detrás de la interfaz normal), el video llena el
  /// contenedor por completo, igual que antes de esta opción.
  final bool letterbox;

  @override
  ConsumerState<_ImmersivePlayerBackground> createState() =>
      _ImmersivePlayerBackgroundState();
}

class _ImmersivePlayerBackgroundState
    extends ConsumerState<_ImmersivePlayerBackground> {
  String? _failedVideoId;
  bool _discardingVideo = false;
  final Set<String> _transientRetries = <String>{};

  @override
  void didUpdateWidget(covariant _ImmersivePlayerBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id ||
        oldWidget.videoId != widget.videoId) {
      _failedVideoId = null;
      _transientRetries.clear();
    }
  }

  void _handleVideoState(MusicVideoBackgroundState state) {
    final videoId = widget.videoId;
    if (videoId != null) {
      widget.onVideoReadinessChanged(
        videoId,
        state.phase == MusicVideoBackgroundPhase.ready,
      );
    }
    if (state.phase == MusicVideoBackgroundPhase.ready) {
      debugPrint('NuvTuneVideo: reproduciendo');
      return;
    }

    if (state.phase != MusicVideoBackgroundPhase.error ||
        videoId == null ||
        videoId == _failedVideoId ||
        _discardingVideo) {
      return;
    }

    debugPrint(
      'NuvTuneVideo: ${state.failure?.name ?? state.phase.name}'
      '${state.youtubeErrorCode == null ? '' : ' (${state.youtubeErrorCode})'}',
    );

    setState(() {
      _failedVideoId = videoId;
    });

    final rejectCandidate = switch (state.failure) {
      MusicVideoBackgroundFailure.invalidVideoId ||
      MusicVideoBackgroundFailure.youtubeInvalidParameter ||
      MusicVideoBackgroundFailure.youtubeHtml5Player ||
      MusicVideoBackgroundFailure.youtubeVideoNotFound ||
      MusicVideoBackgroundFailure.youtubeEmbeddingDisabled ||
      MusicVideoBackgroundFailure.youtubeUnknown => true,
      _ => false,
    };

    if (!rejectCandidate) {
      // Los fallos de red, inicialización o autoplay no pertenecen al ID. Se
      // reintenta una sola vez sin consumir todos los candidatos de la canción.
      if (state.failure !=
              MusicVideoBackgroundFailure.youtubeMissingClientIdentity &&
          _transientRetries.add(videoId)) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted && widget.videoId == videoId) {
            setState(() => _failedVideoId = null);
          }
        });
      }
      return;
    }

    setState(() => _discardingVideo = true);

    final repository = ref.read(videoRepositoryProvider);
    unawaited(() async {
      try {
        await repository.rejectVideo(widget.song, videoId);
        if (!mounted) return;
        // El siguiente cálculo excluye el ID que el IFrame rechazó y prueba
        // otro resultado de YouTube para esta misma canción.
        ref.invalidate(videoBackgroundIdProvider);
      } finally {
        if (mounted) setState(() => _discardingVideo = false);
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final activeVideoId = widget.videoId == _failedVideoId
        ? null
        : widget.videoId;
    final showVideo = activeVideoId != null;
    // En letterbox la portada difuminada es la capa base siempre, porque
    // ademas de fallback rellena el espacio sobrante del video 16:9 contenido;
    // fuera de letterbox solo aparece cuando no hay video que mostrar.
    final showFallback = widget.letterbox || !showVideo;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              math.max(constraints.maxWidth, constraints.maxHeight) * 1.15;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (showFallback)
                Center(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
                    child: Opacity(
                      opacity: 0.3,
                      child: SizedBox.square(
                        dimension: size,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: CoverArt(
                            song: widget.song,
                            size: 480,
                            borderRadius: 0,
                            fallback: widget.animateFallback
                                ? ReactiveAudioVisualizer(
                                    song: widget.song,
                                    size: 480,
                                    borderRadius: 0,
                                    isPlaying: widget.isPlaying,
                                  )
                                : const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          Color(0xFF17213A),
                                          Color(0xFF05070E),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (showVideo)
                if (widget.letterbox)
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: MusicVideoBackground(
                        key: ValueKey(activeVideoId),
                        videoId: activeVideoId,
                        isPlaying: widget.isPlaying,
                        fit: MusicVideoFit.contain,
                        onStateChanged: _handleVideoState,
                      ),
                    ),
                  )
                else
                  // WebView es una vista de plataforma en Android. Mantenerla
                  // fuera de filtros y opacidad evita cuadros negros en GPU.
                  Positioned.fill(
                    child: MusicVideoBackground(
                      key: ValueKey(activeVideoId),
                      videoId: activeVideoId,
                      isPlaying: widget.isPlaying,
                      onStateChanged: _handleVideoState,
                    ),
                  ),
              ColoredBox(
                color: Colors.black.withValues(alpha: showVideo ? 0.24 : 0.38),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerAppBar extends ConsumerWidget {
  const _PlayerAppBar({required this.song, required this.onOpenFullscreen});

  final Song song;
  final Future<void> Function(PlayerVisualScene scene) onOpenFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outputName = ref.watch(playbackProvider.select((s) => s.outputName));
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final settings = ref.watch(settingsProvider).valueOrNull;
    final visualScene = PlayerVisualScene.fromIndex(
      settings?.playerVisualScene ?? 0,
    );

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
                  outputName,
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
          PopupMenuButton<_VisualizationAction>(
            tooltip: 'Visualización',
            icon: const Icon(Icons.graphic_eq_rounded),
            onSelected: (action) async {
              switch (action) {
                case _VisualizationAction.fullscreen:
                  await onOpenFullscreen(visualScene);
                  break;
                case _VisualizationAction.scene:
                  final choice = await showPlayerVisualScenePicker(
                    context,
                    selected: visualScene,
                  );
                  if (choice != null) {
                    await ref
                        .read(settingsRepositoryProvider)
                        .update(
                          AppSettingsCompanion(
                            playerVisualScene: Value(choice.index),
                          ),
                        );
                  }
                  break;
                case _VisualizationAction.style:
                  if (context.mounted) {
                    await showVisualizerStylePicker(context, ref);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _VisualizationAction.fullscreen,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fullscreen_rounded),
                  title: const Text('Pantalla completa'),
                  subtitle: Text(visualScene.label),
                ),
              ),
              const PopupMenuItem(
                value: _VisualizationAction.style,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.auto_awesome_rounded),
                  title: Text('Cambiar estilo'),
                ),
              ),
              PopupMenuItem(
                value: _VisualizationAction.scene,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(visualScene.icon),
                  title: const Text('Escenario'),
                  subtitle: Text(visualScene.label),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () =>
                showSongActions(context, song: song, contextSongs: queue),
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
  const _NowPlayingTab({
    required this.song,
    required this.visualScene,
    required this.videoAvailable,
    required this.onOpenLyrics,
    required this.onOpenFullscreen,
  });

  final Song song;
  final PlayerVisualScene visualScene;
  final bool videoAvailable;
  final VoidCallback onOpenLyrics;
  final Future<void> Function(Song song, PlayerVisualScene scene)
  onOpenFullscreen;

  @override
  ConsumerState<_NowPlayingTab> createState() => _NowPlayingTabState();
}

/// Quien decide, en este instante, que portada muestra el carrusel.
///
/// El indice visible tenia antes dos escritores independientes -el indice que
/// reporta el motor y las notificaciones de scroll del propio carrusel- y se
/// pisaban entre si. Al pasar de la pista 146 a la 147, el indice se ponia en
/// 147 y acto seguido `animateToPage` arrancaba desde la pagina 146.0; las
/// notificaciones de esa animacion devolvian `round() == 146` durante su
/// primera mitad y reescribian el indice a 146, hasta que la pagina cruzaba
/// 146.5 y volvia a 147. Eso era el parpadeo: siguiente, anterior, siguiente.
///
/// Con la autoridad explicita el dato tiene un unico origen en cada estado, y
/// las transiciones entre estados son las de la propia interaccion: no hay
/// banderas defensivas ni temporizadores.
enum _CarouselAuthority {
  /// Manda el motor: la portada visible es la que suena. Las notificaciones de
  /// scroll se ignoran porque son el eco de una animacion que pedimos nosotros.
  engine,

  /// Manda el dedo: la portada visible sale de la posicion del carrusel.
  drag,

  /// El usuario ya eligio y la orden viaja al motor; manda lo elegido hasta
  /// que el motor conteste. Sin este estado la portada volveria a la anterior
  /// durante los milisegundos que tarda la respuesta.
  pendingEngine,
}

class _NowPlayingTabState extends ConsumerState<_NowPlayingTab> {
  /// Margen para comparar la posicion continua del carrusel contra un indice
  /// entero: `PageController.page` no aterriza nunca en un valor exacto.
  static const double _pageEpsilon = 0.01;

  late final PageController _pageController;

  /// Ultimo indice reportado por el motor. Unica fuente cuando la autoridad es
  /// [_CarouselAuthority.engine].
  late int _engineIndex;

  /// Indice bajo el dedo. Unica fuente mientras la autoridad es
  /// [_CarouselAuthority.drag].
  late int _dragIndex;

  /// Indice que el usuario acaba de elegir. Unica fuente mientras la autoridad
  /// es [_CarouselAuthority.pendingEngine].
  late int _pendingIndex;

  _CarouselAuthority _authority = _CarouselAuthority.engine;

  /// Impide encolar mas de una sincronizacion por fotograma.
  bool _syncScheduled = false;

  double _visualizerDragDx = 0;

  @override
  void initState() {
    super.initState();
    final state = ref.read(playbackProvider);
    final initial = state.snapshot.currentIndex < 0
        ? 0
        : state.snapshot.currentIndex
              .clamp(0, math.max(0, state.queue.length - 1))
              .toInt();
    _engineIndex = initial;
    _dragIndex = initial;
    _pendingIndex = initial;
    _pageController = PageController(
      initialPage: initial,
      viewportFraction: 0.9,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Portada que se muestra. Sale de un unico campo, elegido por la autoridad
  /// vigente: nunca de dos a la vez.
  int get _visibleIndex => switch (_authority) {
    _CarouselAuthority.engine => _engineIndex,
    _CarouselAuthority.drag => _dragIndex,
    _CarouselAuthority.pendingEngine => _pendingIndex,
  };

  bool _handleCarouselScroll(ScrollNotification notification) {
    final queueLength = ref.read(playbackProvider).queue.length;
    if (queueLength == 0) return false;

    // `dragDetails` solo llega cuando hay un dedo empujando; una animacion
    // nuestra no lo trae. Es lo que separa "el usuario esta eligiendo" de "el
    // carrusel se mueve porque se lo pedimos", y es exactamente la distincion
    // que faltaba.
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _authority = _CarouselAuthority.drag;
    }

    if (_authority != _CarouselAuthority.drag) return false;

    final page = _pageController.hasClients ? _pageController.page : null;
    if (page != null) {
      final target = page.round().clamp(0, queueLength - 1).toInt();
      if (target != _dragIndex) setState(() => _dragIndex = target);
    }

    // El scroll termina cuando el carrusel ya se asento, con el dedo fuera:
    // ese es el momento de fijar la eleccion.
    if (notification is ScrollEndNotification) _commitDrag();
    return false;
  }

  /// El usuario solto el carrusel: se ordena la portada elegida.
  void _commitDrag() {
    final state = ref.read(playbackProvider);
    final chosen = _dragIndex;
    if (state.queue.isEmpty || chosen == state.snapshot.currentIndex) {
      setState(() => _authority = _CarouselAuthority.engine);
      return;
    }
    _requestIndex(chosen);
  }

  /// Intencion explicita de reproducir una portada concreta: tocarla, o el
  /// boton de "a continuacion".
  ///
  /// Se le ordena al motor directamente en vez de animar el carrusel y deducir
  /// la intencion del final del scroll. Deducirla del scroll obligaba a que
  /// una animacion nuestra fuera indistinguible de un gesto del usuario, que
  /// es la raiz del problema que este rediseño elimina.
  void _requestIndex(int index) {
    final state = ref.read(playbackProvider);
    if (state.queue.isEmpty) return;
    final target = index.clamp(0, state.queue.length - 1).toInt();
    if (target == state.snapshot.currentIndex) return;

    HapticFeedback.selectionClick();
    setState(() {
      _pendingIndex = target;
      _authority = _CarouselAuthority.pendingEngine;
    });
    ref.read(playbackProvider.notifier).playQueueIndex(target);
    _scheduleCarouselSync();
  }

  /// Incorpora el indice del motor al estado local. Se llama desde `build`, de
  /// modo que el propio fotograma que lo recibe ya pinta con el valor nuevo.
  void _syncWithEngine(int engineIndex) {
    if (engineIndex < 0) return;

    final changed = engineIndex != _engineIndex;
    _engineIndex = engineIndex;

    // Cualquier indice que reporte el motor cierra la espera, coincida o no
    // con lo pedido: el motor es la verdad. Asi la espera no depende de que
    // llegue un valor concreto y no hace falta un tiempo maximo.
    if (changed && _authority == _CarouselAuthority.pendingEngine) {
      _authority = _CarouselAuthority.engine;
    }

    // Mientras el dedo manda, el carrusel no se toca.
    if (_authority == _CarouselAuthority.drag) return;
    _scheduleCarouselSync();
  }

  void _scheduleCarouselSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _applyCarouselSync();
    });
  }

  /// Invariante del carrusel: terminado cada fotograma en que el dedo no
  /// manda, la pagina visible coincide con [_visibleIndex].
  ///
  /// Se aplica siempre, no solo cuando cambia el indice, y por eso no hace
  /// falta recordar sincronizaciones pendientes cuando el carrusel esta
  /// desmontado (ocurre al mostrar el visualizador): al volver a montarse, el
  /// primer fotograma lo recoloca.
  void _applyCarouselSync() {
    if (_authority == _CarouselAuthority.drag) return;
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;

    final target = _visibleIndex;
    final distance = (page - target).abs();
    if (distance < _pageEpsilon) return;

    // Solo se anima el paso entre portadas contiguas, que es el unico caso en
    // que el movimiento comunica algo. Con el modo aleatorio dos pistas
    // consecutivas pueden estar a cientos de posiciones de distancia en la
    // cola (146 -> 753 en la traza real), y animar esa distancia hace desfilar
    // cientos de caratulas en un tercio de segundo: eso es lo que se percibia
    // como "salto varias canciones de golpe" cuando el motor solo habia
    // avanzado una.
    if (distance > 1 + _pageEpsilon) {
      _pageController.jumpToPage(target);
    } else {
      _pageController.animateToPage(
        target,
        duration: Tokens.durationMedium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _skipFromVisualizer({required bool next}) {
    final state = ref.read(playbackProvider);
    final index = state.snapshot.currentIndex;
    final hasSeveralSongs = state.queue.length > 1 && index >= 0;
    if (!hasSeveralSongs) return false;

    final canWrap =
        state.snapshot.shuffleEnabled ||
        state.snapshot.repeatMode == RepeatMode.all;
    final canSkip = next
        ? index < state.queue.length - 1 || canWrap
        : index > 0 || canWrap;
    if (!canSkip) return false;

    HapticFeedback.selectionClick();
    final controller = ref.read(playbackProvider.notifier);
    if (next) {
      controller.skipNext();
    } else {
      controller.skipPrevious();
    }
    return true;
  }

  void _finishVisualizerDrag(DragEndDetails details) {
    final distance = _visualizerDragDx.abs();
    final velocity = (details.primaryVelocity ?? 0).abs();
    final direction = _visualizerDragDx == 0
        ? details.primaryVelocity ?? 0
        : _visualizerDragDx;
    _visualizerDragDx = 0;

    // Un arrastre pausado y deliberado también cuenta. Para los flicks se
    // exige una distancia mínima, evitando cambios por roces diminutos.
    final deliberateDrag = distance >= 72;
    final deliberateFlick = distance >= 24 && velocity >= 650;
    if ((!deliberateDrag && !deliberateFlick) || direction == 0) return;
    _skipFromVisualizer(next: direction < 0);
  }

  Widget _buildCarouselArtwork({
    required Song song,
    required double size,
    required bool hasArtwork,
    required bool isCurrent,
    required bool isPlaying,
    required ColorScheme scheme,
    bool staticFallback = false,
  }) {
    Widget artwork;
    if (hasArtwork || staticFallback) {
      artwork = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isCurrent && isPlaying
                ? scheme.primary.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
            width: isCurrent && isPlaying ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(
                alpha: isCurrent && isPlaying ? 0.24 : 0.08,
              ),
              blurRadius: isCurrent ? 26 : 12,
              spreadRadius: isCurrent ? 1 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: CoverArt(
            song: song,
            size: size,
            borderRadius: 24,
            fallback: hasArtwork ? null : const _StaticCoverFallback(),
          ),
        ),
      );
    } else {
      artwork = ReactiveAudioVisualizer(
        key: ValueKey('visualizer-${song.id}'),
        song: song,
        size: size,
        borderRadius: 0,
        isPlaying: isPlaying && isCurrent,
      );
    }

    return isCurrent
        ? Hero(tag: 'now-playing-cover-${song.id}', child: artwork)
        : artwork;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackProvider);
    final engineIndex = state.snapshot.currentIndex;
    _syncWithEngine(engineIndex);
    final safePreviewIndex = state.queue.isEmpty
        ? 0
        : _visibleIndex.clamp(0, state.queue.length - 1).toInt();
    final displaySong = state.queue.isEmpty
        ? widget.song
        : state.queue[safePreviewIndex];
    final controller = ref.read(playbackProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final favorites = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favorites.contains(displaySong.id);
    final appSettings = ref.watch(settingsProvider).valueOrNull;
    final controlPreset = PlayerControlPreset.byId(
      appSettings?.playerControlPreset ?? PlayerControlPreset.complete.id,
    );
    final controlLayout = controlPreset == PlayerControlPreset.custom
        ? PlayerControlLayout.fromJsonString(
            appSettings?.playerControlLayoutJson ??
                PlayerControlLayout.complete.toJsonString(),
          )
        : PlayerControlLayout.forPreset(controlPreset);
    final controlHandedness = ControlHandedness.byId(
      appSettings?.playerControlHandedness ?? ControlHandedness.right.id,
    );
    final customCovers =
        ref.watch(customCoversProvider).valueOrNull ?? const <String, String>{};
    final showCleanVideo =
        widget.visualScene == PlayerVisualScene.video && widget.videoAvailable;
    final showLyrics = widget.visualScene.showsLyrics;
    final forceVisualizer = widget.visualScene.showsVisualizer;
    final activeSong = state.currentSong ?? displaySong;
    final showSingleVisualizer =
        !showCleanVideo && !showLyrics && forceVisualizer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final coverSize = math
            .min(stageWidth * 0.82, constraints.maxHeight * 0.46)
            .clamp(156.0, 440.0)
            .toDouble();
        // Los painters reservan margen interno para el resplandor. Un lienzo
        // mayor que la pantalla hace que la forma generativa, sin marco, sea el
        // escenario visual y no una portada cuadrada diminuta.
        final visualizerSize = math
            .max(stageWidth * 1.42, coverSize * 1.5)
            .clamp(280.0, 620.0)
            .toDouble();
        final stageHeight = math
            .max(
              coverSize + 16,
              math.min(stageWidth * 0.98, constraints.maxHeight * 0.52),
            )
            .clamp(172.0, 520.0)
            .toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              SizedBox(
                height: stageHeight,
                child: AnimatedSwitcher(
                  duration: Tokens.durationMedium,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: showCleanVideo
                      ? const SizedBox.expand(
                          key: ValueKey('clean-video-stage'),
                        )
                      : showLyrics
                      ? _PlayerLyricsSceneStage(
                          key: ValueKey('lyrics-stage-${displaySong.id}'),
                          song: displaySong,
                          onOpenLyrics: widget.onOpenLyrics,
                          videoOverlay:
                              widget.visualScene == PlayerVisualScene.both,
                        )
                      : showSingleVisualizer
                      ? OverflowBox(
                          key: ValueKey('single-visualizer-${activeSong.id}'),
                          alignment: Alignment.center,
                          minWidth: stageWidth,
                          maxWidth: stageWidth,
                          child: SizedBox(
                            width: stageWidth,
                            height: stageHeight,
                            child: Semantics(
                              label: 'Visualización de ${activeSong.title}',
                              hint:
                                  'Toca para abrir en pantalla completa. '
                                  'Desliza para cambiar de canción.',
                              button: true,
                              onTap: () async {
                                await widget.onOpenFullscreen(
                                  activeSong,
                                  widget.visualScene,
                                );
                              },
                              onIncrease: () => _skipFromVisualizer(next: true),
                              onDecrease: () =>
                                  _skipFromVisualizer(next: false),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  await widget.onOpenFullscreen(
                                    activeSong,
                                    widget.visualScene,
                                  );
                                },
                                onHorizontalDragStart: (_) {
                                  _visualizerDragDx = 0;
                                },
                                onHorizontalDragUpdate: (details) {
                                  _visualizerDragDx +=
                                      details.primaryDelta ?? 0;
                                },
                                onHorizontalDragCancel: () {
                                  _visualizerDragDx = 0;
                                },
                                onHorizontalDragEnd: _finishVisualizerDrag,
                                child: Center(
                                  child: OverflowBox(
                                    alignment: Alignment.center,
                                    minWidth: visualizerSize,
                                    maxWidth: visualizerSize,
                                    minHeight: visualizerSize,
                                    maxHeight: visualizerSize,
                                    child: _buildCarouselArtwork(
                                      song: activeSong,
                                      size: visualizerSize,
                                      hasArtwork: false,
                                      isCurrent: true,
                                      isPlaying: state.isPlaying,
                                      scheme: scheme,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : OverflowBox(
                          key: const ValueKey('cover-carousel-stage'),
                          alignment: Alignment.center,
                          minWidth: stageWidth,
                          maxWidth: stageWidth,
                          child: SizedBox(
                            width: stageWidth,
                            height: stageHeight,
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
                                  final hasArtwork = _songHasArtwork(
                                    item,
                                    customCovers,
                                  );
                                  final itemSize = coverSize;
                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (context, child) {
                                      final page = _pageController.hasClients
                                          ? (_pageController.page ??
                                                engineIndex.toDouble())
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
                                      onTap: () async {
                                        if (index != engineIndex) {
                                          _requestIndex(index);
                                          return;
                                        }
                                        await widget.onOpenFullscreen(
                                          item,
                                          widget.visualScene,
                                        );
                                      },
                                      child: Center(
                                        child: OverflowBox(
                                          alignment: Alignment.center,
                                          minWidth: itemSize,
                                          maxWidth: itemSize,
                                          minHeight: itemSize,
                                          maxHeight: itemSize,
                                          child: _buildCarouselArtwork(
                                            song: item,
                                            size: itemSize,
                                            hasArtwork: hasArtwork,
                                            isCurrent: index == engineIndex,
                                            isPlaying: state.isPlaying,
                                            scheme: scheme,
                                            staticFallback: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
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
                ],
              ),

              const SizedBox(height: 8),
              const _ProgressBar(),
              const SizedBox(height: 16),

              CustomizablePlayerControls(
                layout: controlLayout,
                preset: controlPreset,
                handedness: controlHandedness,
                state: state,
                controller: controller,
                song: displaySong,
                isFavorite: isFavorite,
                onOpenQueue: () => context.push('/queue'),
              ),

              if ((controlLayout.primary.contains(PlayerControlId.queue) ||
                      controlLayout.secondary.contains(
                        PlayerControlId.queue,
                      )) &&
                  engineIndex >= 0 &&
                  engineIndex + 1 < state.queue.length)
                Padding(
                  padding: const EdgeInsets.only(top: Tokens.space2),
                  child: TextButton.icon(
                    onPressed: () => _requestIndex(engineIndex + 1),
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

enum _LyricsSceneLookup { unknown, checking, available, unavailable }

class _PlayerLyricsSceneStage extends ConsumerStatefulWidget {
  const _PlayerLyricsSceneStage({
    required this.song,
    required this.onOpenLyrics,
    this.immersive = false,
    this.videoOverlay = false,
    this.showOpenAction = true,
    this.onScrollabilityChanged,
    super.key,
  });

  final Song song;
  final VoidCallback onOpenLyrics;
  final bool immersive;
  final bool videoOverlay;
  final bool showOpenAction;
  final ValueChanged<bool>? onScrollabilityChanged;

  @override
  ConsumerState<_PlayerLyricsSceneStage> createState() =>
      _PlayerLyricsSceneStageState();
}

class _PlayerLyricsSceneStageState
    extends ConsumerState<_PlayerLyricsSceneStage> {
  _LyricsSceneLookup _lookup = _LyricsSceneLookup.unknown;
  bool? _wasOnWifi;
  bool? _reportedScrollable;

  @override
  void didUpdateWidget(covariant _PlayerLyricsSceneStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _lookup = _LyricsSceneLookup.unknown;
      _reportedScrollable = null;
    }
  }

  void _reportScrollability(bool value) {
    final callback = widget.onScrollabilityChanged;
    if (callback == null || _reportedScrollable == value) return;
    _reportedScrollable = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(value);
    });
  }

  void _scheduleOnlineLookup(bool isOnWifi) {
    if (!isOnWifi || _lookup != _LyricsSceneLookup.unknown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lookup != _LyricsSceneLookup.unknown) return;
      unawaited(_fetchOnlineOnce());
    });
  }

  Future<void> _fetchOnlineOnce() async {
    if (_lookup != _LyricsSceneLookup.unknown) return;
    setState(() => _lookup = _LyricsSceneLookup.checking);

    final song = widget.song;
    final engineApi = ref.read(engineProvider).api;
    final repository = ref.read(lyricsRepositoryProvider);
    try {
      final content = await _requestLyricsForScene(
        engineApi: engineApi,
        song: song,
      );
      if (content == null || content.trim().isEmpty) {
        if (mounted && widget.song.id == song.id) {
          setState(() => _lookup = _LyricsSceneLookup.unavailable);
        }
        return;
      }

      if (!mounted || widget.song.id != song.id) return;
      final parsed = LrcParser.parse(content);
      await repository.save(
        songId: song.id,
        content: content,
        synchronized: parsed.synchronized,
      );
      _lyricsSceneRequests.remove(song.id);
      if (!mounted || widget.song.id != song.id) return;
      setState(() => _lookup = _LyricsSceneLookup.available);
      ref.invalidate(lyricsProvider(song.id));
    } catch (_) {
      if (mounted && widget.song.id == song.id) {
        setState(() => _lookup = _LyricsSceneLookup.unavailable);
      }
    }
  }

  void _retryOnlineLookup() {
    if (_lookup != _LyricsSceneLookup.unavailable) return;
    setState(() => _lookup = _LyricsSceneLookup.unknown);
    unawaited(_fetchOnlineOnce());
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsProvider(widget.song.id));
    final resolvedForScroll = lyricsAsync.valueOrNull;
    _reportScrollability(
      resolvedForScroll != null &&
          !resolvedForScroll.parsed.isEmpty &&
          !resolvedForScroll.parsed.synchronized,
    );
    final isOnWifi =
        ref.watch(connectivityIsOnWifiProvider).valueOrNull ?? false;
    final reconnected = _wasOnWifi == false && isOnWifi;
    _wasOnWifi = isOnWifi;
    if (reconnected && _lookup == _LyricsSceneLookup.unavailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lookup == _LyricsSceneLookup.unavailable) {
          _retryOnlineLookup();
        }
      });
    }
    final body = lyricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildFallback(
        context,
        message: 'No se pudo leer la letra de esta canción.',
        icon: Icons.error_outline_rounded,
      ),
      data: (resolved) {
        if (resolved.parsed.isEmpty) {
          _scheduleOnlineLookup(isOnWifi);
          final message = switch (_lookup) {
            _LyricsSceneLookup.checking ||
            _LyricsSceneLookup.available => 'Buscando letra en Wi-Fi…',
            _LyricsSceneLookup.unavailable =>
              'No encontramos una letra para esta canción.',
            _LyricsSceneLookup.unknown when !isOnWifi =>
              'No hay letra local. Conéctate a Wi-Fi o abre Letras para '
                  'añadirla.',
            _ => 'Preparando búsqueda de letra…',
          };
          return _buildFallback(
            context,
            message: message,
            showProgress:
                _lookup == _LyricsSceneLookup.checking ||
                _lookup == _LyricsSceneLookup.available,
            onRetry: isOnWifi && _lookup == _LyricsSceneLookup.unavailable
                ? _retryOnlineLookup
                : null,
          );
        }
        return _buildLyrics(context, resolved);
      },
    );

    if (!widget.immersive && !widget.videoOverlay) {
      return SizedBox.expand(
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(
            Tokens.space4,
            Tokens.space3,
            Tokens.space4,
            Tokens.space2,
          ),
          child: body,
        ),
      );
    }

    final overlay = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.immersive
            ? null
            : BorderRadius.circular(Tokens.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.videoOverlay
              ? const [Color(0x99000000), Color(0x28000000), Color(0xB0000000)]
              : const [Color(0x66000000), Color(0x33000000), Color(0x88000000)],
          stops: const [0, 0.48, 1],
        ),
        border: widget.immersive
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.immersive ? Tokens.space5 : Tokens.space4,
          widget.immersive ? Tokens.space4 : Tokens.space3,
          widget.immersive ? Tokens.space5 : Tokens.space4,
          widget.immersive ? Tokens.space4 : Tokens.space2,
        ),
        child: body,
      ),
    );
    return SizedBox.expand(
      child: widget.immersive
          ? overlay
          : ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radiusLarge),
              child: overlay,
            ),
    );
  }

  Widget _buildLyrics(BuildContext context, ResolvedLyrics resolved) {
    final scheme = Theme.of(context).colorScheme;
    final parsed = resolved.parsed;
    final positionMs =
        ref.watch(playbackPositionProvider).valueOrNull?.positionMs ?? 0;

    Widget content;
    if (parsed.synchronized) {
      final activeIndex = LrcParser.activeLineIndex(
        parsed,
        positionMs,
        extraOffsetMs: resolved.userOffsetMs,
      );
      final centerIndex = activeIndex < 0 ? 0 : activeIndex;
      final visibleBefore = widget.immersive ? 2 : 1;
      final visibleCount = widget.immersive ? 5 : 4;
      var firstIndex = math.max(0, centerIndex - visibleBefore);
      final lastIndex = math.min(
        parsed.lines.length - 1,
        firstIndex + visibleCount - 1,
      );
      firstIndex = math.max(0, lastIndex - visibleCount + 1);
      final baseStyle =
          (widget.immersive
              ? Theme.of(context).textTheme.headlineSmall
              : Theme.of(context).textTheme.titleMedium) ??
          const TextStyle(fontSize: 18);
      content = Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = firstIndex; index <= lastIndex; index++)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: widget.immersive ? 10 : 4,
                ),
                child: InkWell(
                  onTap: parsed.lines[index].timeMs == null
                      ? null
                      : () => ref
                            .read(playbackProvider.notifier)
                            .seek(
                              lyricLinePlaybackPositionMs(
                                lineTimeMs: parsed.lines[index].timeMs!,
                                lrcOffsetMs: parsed.offsetMs,
                                userOffsetMs: resolved.userOffsetMs,
                              ),
                            ),
                  borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.space2,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: Tokens.durationFast,
                      textAlign: TextAlign.center,
                      style: baseStyle.copyWith(
                        color: index == activeIndex
                            ? Colors.white
                            : (widget.videoOverlay || widget.immersive
                                  ? Colors.white.withValues(alpha: 0.46)
                                  : scheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    )),
                        fontWeight: index == activeIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.25,
                        shadows: widget.videoOverlay
                            ? const [
                                Shadow(color: Colors.black, blurRadius: 14),
                                Shadow(color: Colors.black, blurRadius: 4),
                              ]
                            : null,
                      ),
                      child: Text(
                        parsed.lines[index].text.isEmpty
                            ? '♪'
                            : parsed.lines[index].text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      content = Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
          itemCount: parsed.lines.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: Tokens.space2),
          itemBuilder: (context, index) => Text(
            parsed.lines[index].text,
            textAlign: TextAlign.center,
            style:
                (widget.immersive
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      color: index == 0
                          ? Colors.white
                          : (widget.videoOverlay || widget.immersive
                                ? Colors.white.withValues(alpha: 0.68)
                                : scheme.onSurfaceVariant.withValues(
                                    alpha: 0.72,
                                  )),
                      height: 1.35,
                      shadows: widget.videoOverlay
                          ? const [Shadow(color: Colors.black, blurRadius: 10)]
                          : null,
                    ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(
              parsed.synchronized ? Icons.sync_rounded : Icons.lyrics_outlined,
              size: 18,
              color: scheme.primary,
            ),
            const SizedBox(width: Tokens.space2),
            Expanded(
              child: Text(
                parsed.synchronized
                    ? 'Letra sincronizada'
                    : (resolved.source.isEmpty ? 'Letra' : resolved.source),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (widget.showOpenAction)
              TextButton(
                onPressed: widget.onOpenLyrics,
                child: const Text('Abrir'),
              ),
          ],
        ),
        content,
      ],
    );
  }

  Widget _buildFallback(
    BuildContext context, {
    required String message,
    IconData icon = Icons.lyrics_outlined,
    bool showProgress = false,
    VoidCallback? onRetry,
  }) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showProgress)
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        else
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        const SizedBox(height: Tokens.space3),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (onRetry != null || widget.showOpenAction) ...[
          const SizedBox(height: Tokens.space2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Tokens.space2,
            children: [
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                ),
              if (widget.showOpenAction)
                TextButton.icon(
                  onPressed: widget.onOpenLyrics,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Abrir Letras'),
                ),
            ],
          ),
        ],
      ],
    ),
  );
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
