import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Etapa observable de carga del video musical.
enum MusicVideoBackgroundPhase { loading, ready, error }

/// Como se encaja el video 16:9 dentro del contenedor del [MusicVideoBackground].
enum MusicVideoFit {
  /// Llena cualquier contenedor conservando 16:9 y recorta únicamente el
  /// excedente. El tamaño se calcula con CSS a partir del viewport.
  cover,

  /// Muestra el video completo y permite franjas si el contenedor no es 16:9.
  contain,
}

String musicVideoPlayerCss(MusicVideoFit fit) => switch (fit) {
  MusicVideoFit.cover =>
    '#player { position: absolute; top: 50%; left: 50%; '
        'width: 177.77777778vh; height: 100vh; min-width: 100vw; '
        'min-height: 56.25vw; transform: translate(-50%, -50%); }',
  MusicVideoFit.contain =>
    '#player { position: absolute; inset: 0; width: 100%; height: 100%; }',
};

/// Motivo estable y no sensible por el que el video no puede mostrarse.
enum MusicVideoBackgroundFailure {
  invalidVideoId,
  initialization,
  timeout,
  navigation,
  webResource,
  httpResponse,
  ssl,
  iframeApi,
  youtubeInvalidParameter,
  youtubeHtml5Player,
  youtubeVideoNotFound,
  youtubeEmbeddingDisabled,
  youtubeMissingClientIdentity,
  autoplayBlocked,
  youtubeUnknown,
}

/// Estado publico emitido por [MusicVideoBackground.onStateChanged].
@immutable
class MusicVideoBackgroundState {
  const MusicVideoBackgroundState.loading()
    : phase = MusicVideoBackgroundPhase.loading,
      failure = null,
      youtubeErrorCode = null;

  const MusicVideoBackgroundState.ready()
    : phase = MusicVideoBackgroundPhase.ready,
      failure = null,
      youtubeErrorCode = null;

  const MusicVideoBackgroundState.error(this.failure, {this.youtubeErrorCode})
    : phase = MusicVideoBackgroundPhase.error,
      assert(failure != null);

  /// Convierte los codigos documentados por YouTube en fallos accionables.
  factory MusicVideoBackgroundState.youtubeError(int code) {
    final failure = switch (code) {
      2 => MusicVideoBackgroundFailure.youtubeInvalidParameter,
      5 => MusicVideoBackgroundFailure.youtubeHtml5Player,
      100 => MusicVideoBackgroundFailure.youtubeVideoNotFound,
      101 || 150 => MusicVideoBackgroundFailure.youtubeEmbeddingDisabled,
      153 => MusicVideoBackgroundFailure.youtubeMissingClientIdentity,
      _ => MusicVideoBackgroundFailure.youtubeUnknown,
    };
    return MusicVideoBackgroundState.error(failure, youtubeErrorCode: code);
  }

  final MusicVideoBackgroundPhase phase;
  final MusicVideoBackgroundFailure? failure;

  /// Solo contiene el codigo numerico de YouTube; nunca URL, titulo ni ID.
  final int? youtubeErrorCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicVideoBackgroundState &&
          phase == other.phase &&
          failure == other.failure &&
          youtubeErrorCode == other.youtubeErrorCode;

  @override
  int get hashCode => Object.hash(phase, failure, youtubeErrorCode);
}

/// Convierte la posición del audio local en la del videoclip.
///
/// Cuando un videoclip dura apreciablemente más que el archivo de audio, la
/// diferencia suele ser una intro cinematográfica. En ese caso se salta esa
/// introducción y se reparte cualquier sobrante hasta el final del video. No
/// intenta reconocer audio ni descarga contenido: es una corrección local y
/// deliberadamente acotada para que los saltos manuales sigan siendo fluidos.
class MusicVideoTimeline {
  static const int _introDetectionThresholdMs = 2500;
  static const int _maximumAssumedIntroMs = 20000;
  static const int _endPaddingMs = 250;

  static int positionMs({
    required int audioPositionMs,
    required int audioDurationMs,
    required int videoDurationMs,
  }) {
    if (videoDurationMs <= 0) return audioPositionMs < 0 ? 0 : audioPositionMs;

    if (audioDurationMs <= 0) {
      return audioPositionMs
          .clamp(0, _maximumPosition(videoDurationMs))
          .toInt();
    }
    final audioPosition = audioPositionMs.clamp(0, audioDurationMs).toInt();

    final excessMs = videoDurationMs - audioDurationMs;
    final assumedIntroMs = excessMs >= _introDetectionThresholdMs
        ? excessMs.clamp(0, _maximumAssumedIntroMs).toInt()
        : 0;
    final playableVideoMs = videoDurationMs - assumedIntroMs;
    final progress = audioPosition / audioDurationMs;
    final target = assumedIntroMs + (playableVideoMs * progress).round();
    return target.clamp(0, _maximumPosition(videoDurationMs)).toInt();
  }

  static int _maximumPosition(int videoDurationMs) =>
      videoDurationMs > _endPaddingMs ? videoDurationMs - _endPaddingMs : 0;
}

/// Mantiene una estimación continua entre las muestras de posición del audio.
///
/// El proveedor del reproductor publica la posición dos veces por segundo. El
/// reloj evita que el video persiga muestras ya antiguas y permite distinguir
/// el avance normal de un salto manual en la barra de progreso.
class MusicVideoSyncClock {
  static const int discontinuityThresholdMs = 900;

  static int extrapolatedPositionMs({
    required int anchorPositionMs,
    required int anchorElapsedMs,
    required int nowElapsedMs,
    required bool isPlaying,
    required int durationMs,
  }) {
    final elapsedMs = (nowElapsedMs - anchorElapsedMs).clamp(0, 60000).toInt();
    final positionMs = anchorPositionMs + (isPlaying ? elapsedMs : 0);
    if (durationMs <= 0) return positionMs < 0 ? 0 : positionMs;
    return positionMs.clamp(0, durationMs).toInt();
  }

  static bool isDiscontinuity({
    required int expectedPositionMs,
    required int reportedPositionMs,
  }) =>
      (reportedPositionMs - expectedPositionMs).abs() >=
      discontinuityThresholdMs;
}

/// Fondo de video musical del reproductor (feature "video de fondo en
/// Wi-Fi"): reproduce el video oficial de YouTube igual que su web publica,
/// via el IFrame Player API embebido — no descarga ni reempaqueta contenido.
class MusicVideoBackground extends StatefulWidget {
  const MusicVideoBackground({
    required this.videoId,
    required this.isPlaying,
    required this.audioPositionMs,
    required this.audioDurationMs,
    this.fit = MusicVideoFit.cover,
    this.onStateChanged,
    this.loadTimeout = const Duration(seconds: 12),
    super.key,
  }) : assert(loadTimeout > Duration.zero);

  final String videoId;
  final bool isPlaying;
  final int audioPositionMs;
  final int audioDurationMs;

  /// Como se encaja el video 16:9 dentro de este widget. Cambia el CSS
  /// inyectado en el WebView, no el tamano del propio widget.
  final MusicVideoFit fit;

  /// Emite `loading`, `ready` o `error` una sola vez por transicion.
  ///
  /// El padre puede retirar este widget al recibir `error` y mostrar la portada
  /// o el visualizador local. El callback nunca incluye metadatos de la pista.
  final ValueChanged<MusicVideoBackgroundState>? onStateChanged;

  /// Tiempo maximo para que el IFrame confirme `onReady`.
  final Duration loadTimeout;

  @override
  State<MusicVideoBackground> createState() => _MusicVideoBackgroundState();
}

class _MusicVideoBackgroundState extends State<MusicVideoBackground> {
  static final RegExp _validVideoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static const String _javaScriptChannel = 'NuvTuneVideo';
  static const String _applicationOrigin = 'https://com.nuvtune.app';

  late WebViewController _controller;
  MusicVideoBackgroundState _loadState =
      const MusicVideoBackgroundState.loading();
  Timer? _loadTimer;
  Timer? _playbackSyncTimer;
  int _generation = 0;
  int? _videoDurationMs;
  final Stopwatch _playbackClock = Stopwatch();
  late int _audioAnchorPositionMs;
  late int _audioAnchorElapsedMs;

  @override
  void initState() {
    super.initState();
    _playbackClock.start();
    _resetAudioAnchor();
    _controller = _buildController(widget.videoId);
    _playbackSyncTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (widget.isPlaying &&
          _loadState.phase == MusicVideoBackgroundPhase.ready) {
        unawaited(_syncPlayback(_controller));
      }
    });
  }

  @override
  void didUpdateWidget(covariant MusicVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final playbackChanged = oldWidget.isPlaying != widget.isPlaying;
    final positionChanged = oldWidget.audioPositionMs != widget.audioPositionMs;
    final expectedPositionMs = _currentAudioPositionMs(
      isPlaying: oldWidget.isPlaying,
      durationMs: oldWidget.audioDurationMs,
    );
    final forceSeek =
        playbackChanged ||
        (positionChanged &&
            MusicVideoSyncClock.isDiscontinuity(
              expectedPositionMs: expectedPositionMs,
              reportedPositionMs: widget.audioPositionMs,
            ));
    if (playbackChanged || positionChanged) {
      _resetAudioAnchor();
    }

    var replacedController = false;
    if (oldWidget.videoId != widget.videoId || oldWidget.fit != widget.fit) {
      _controller = _buildController(widget.videoId);
      replacedController = true;
    } else if (oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.audioPositionMs != widget.audioPositionMs ||
        oldWidget.audioDurationMs != widget.audioDurationMs) {
      unawaited(_syncPlayback(_controller, forceSeek: forceSeek));
    } else if (oldWidget.loadTimeout != widget.loadTimeout &&
        _loadState.phase == MusicVideoBackgroundPhase.loading) {
      _startTimeout(_generation);
    }

    if (!replacedController &&
        oldWidget.onStateChanged == null &&
        widget.onStateChanged != null) {
      _notifyParent(_loadState, _generation);
    }
  }

  WebViewController _buildController(String videoId) {
    final generation = ++_generation;
    _loadTimer?.cancel();
    _videoDurationMs = null;
    _loadState = const MusicVideoBackgroundState.loading();
    _notifyParent(_loadState, generation);

    final controller = WebViewController();
    if (!_validVideoId.hasMatch(videoId)) {
      _deferFailure(
        generation,
        const MusicVideoBackgroundState.error(
          MusicVideoBackgroundFailure.invalidVideoId,
        ),
      );
      return controller;
    }

    _startTimeout(generation);
    unawaited(_configureController(controller, videoId, generation));
    return controller;
  }

  Future<void> _configureController(
    WebViewController controller,
    String videoId,
    int generation,
  ) async {
    try {
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.transparent);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.isMainFrame || _isAllowedMainFrame(request.url)) {
              return NavigationDecision.navigate;
            }
            _fail(
              generation,
              const MusicVideoBackgroundState.error(
                MusicVideoBackgroundFailure.navigation,
              ),
            );
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (!_isFatalWebResourceError(error)) return;
            _fail(
              generation,
              const MusicVideoBackgroundState.error(
                MusicVideoBackgroundFailure.webResource,
              ),
            );
          },
          onHttpError: (error) {
            final uri = error.request?.uri ?? error.response?.uri;
            if (uri == null || !_isCriticalYouTubeResource(uri.toString())) {
              return;
            }
            _fail(
              generation,
              const MusicVideoBackgroundState.error(
                MusicVideoBackgroundFailure.httpResponse,
              ),
            );
          },
          onSslAuthError: (error) {
            unawaited(error.cancel());
            _fail(
              generation,
              const MusicVideoBackgroundState.error(
                MusicVideoBackgroundFailure.ssl,
              ),
            );
          },
        ),
      );
      await controller.addJavaScriptChannel(
        _javaScriptChannel,
        onMessageReceived: (message) =>
            _handleJavaScriptMessage(generation, message.message),
      );

      // webview_flutter expone esta opcion en su controlador Android. Se usa de
      // forma dinamica para mantener este widget compatible tambien con iOS sin
      // depender directamente del paquete especifico de cada plataforma.
      try {
        await (controller.platform as dynamic)
            .setMediaPlaybackRequiresUserGesture(false);
      } catch (_) {
        // `mute=1` y `autoplay=1` siguen siendo la ruta estandar del IFrame.
      }

      if (!_isCurrent(generation)) return;
      await controller.loadHtmlString(
        _html(videoId, widget.isPlaying, widget.fit),
        // Android usa baseUrl como Referer del iframe. YouTube exige que ese
        // valor identifique a la app anfitriona, no al propio youtube.com.
        baseUrl: '$_applicationOrigin/',
      );
      if (_isCurrent(generation) && identical(controller, _controller)) {
        await _syncPlayback(controller);
      }
    } catch (_) {
      _fail(
        generation,
        const MusicVideoBackgroundState.error(
          MusicVideoBackgroundFailure.initialization,
        ),
      );
    }
  }

  void _resetAudioAnchor() {
    _audioAnchorPositionMs = widget.audioPositionMs;
    _audioAnchorElapsedMs = _playbackClock.elapsedMilliseconds;
  }

  int _currentAudioPositionMs({bool? isPlaying, int? durationMs}) =>
      MusicVideoSyncClock.extrapolatedPositionMs(
        anchorPositionMs: _audioAnchorPositionMs,
        anchorElapsedMs: _audioAnchorElapsedMs,
        nowElapsedMs: _playbackClock.elapsedMilliseconds,
        isPlaying: isPlaying ?? widget.isPlaying,
        durationMs: durationMs ?? widget.audioDurationMs,
      );

  Future<void> _syncPlayback(
    WebViewController controller, {
    bool forceSeek = false,
  }) async {
    try {
      final audioPositionMs = _currentAudioPositionMs();
      final targetMs = _videoDurationMs == null
          ? audioPositionMs
          : MusicVideoTimeline.positionMs(
              audioPositionMs: audioPositionMs,
              audioDurationMs: widget.audioDurationMs,
              videoDurationMs: _videoDurationMs!,
            );
      await controller.runJavaScript(
        'setPlayback(${widget.isPlaying}, ${targetMs / 1000}, $forceSeek);',
      );
    } catch (_) {
      // La pagina puede no estar lista. El valor actual se vuelve a aplicar
      // despues de loadHtmlString y el valor inicial se aplica en onReady.
    }
  }

  void _handleJavaScriptMessage(int generation, String rawMessage) {
    if (!_isCurrent(generation)) return;

    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) return;
      switch (decoded['type']) {
        case 'ready':
          final rawDuration = decoded['duration'];
          final durationWasUnknown = _videoDurationMs == null;
          if (rawDuration is num && rawDuration.isFinite && rawDuration > 0) {
            _videoDurationMs = (rawDuration * 1000).round();
          }
          _transition(generation, const MusicVideoBackgroundState.ready());
          unawaited(_syncPlayback(_controller, forceSeek: durationWasUnknown));
        case 'error':
          final rawCode = decoded['code'];
          if (rawCode is num) {
            _fail(
              generation,
              MusicVideoBackgroundState.youtubeError(rawCode.toInt()),
            );
          } else {
            _fail(
              generation,
              const MusicVideoBackgroundState.error(
                MusicVideoBackgroundFailure.youtubeUnknown,
              ),
            );
          }
        case 'iframe_api_error':
          _fail(
            generation,
            const MusicVideoBackgroundState.error(
              MusicVideoBackgroundFailure.iframeApi,
            ),
          );
        case 'autoplay_blocked':
          _fail(
            generation,
            const MusicVideoBackgroundState.error(
              MusicVideoBackgroundFailure.autoplayBlocked,
            ),
          );
      }
    } on FormatException {
      // Solo se aceptan mensajes JSON del documento local controlado por la app.
    }
  }

  void _startTimeout(int generation) {
    _loadTimer?.cancel();
    _loadTimer = Timer(widget.loadTimeout, () {
      if (!_isCurrent(generation) ||
          _loadState.phase != MusicVideoBackgroundPhase.loading) {
        return;
      }
      _fail(
        generation,
        const MusicVideoBackgroundState.error(
          MusicVideoBackgroundFailure.timeout,
        ),
      );
    });
  }

  void _deferFailure(int generation, MusicVideoBackgroundState failure) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fail(generation, failure);
    });
  }

  void _fail(int generation, MusicVideoBackgroundState failure) {
    if (failure.phase != MusicVideoBackgroundPhase.error) return;
    _transition(generation, failure);
  }

  void _transition(int generation, MusicVideoBackgroundState next) {
    if (!_isCurrent(generation) || _loadState == next) return;
    if (_loadState.phase == MusicVideoBackgroundPhase.error) return;

    if (next.phase != MusicVideoBackgroundPhase.loading) {
      _loadTimer?.cancel();
      _loadTimer = null;
    }
    setState(() => _loadState = next);
    _notifyParent(next, generation);
  }

  void _notifyParent(MusicVideoBackgroundState state, int generation) {
    final callback = widget.onStateChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrent(generation) || _loadState != state) return;
      widget.onStateChanged?.call(state);
    });
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  bool _isFatalWebResourceError(WebResourceError error) {
    if (error.isForMainFrame == true) return true;
    if (_loadState.phase == MusicVideoBackgroundPhase.ready) return false;
    return _isCriticalYouTubeResource(error.url);
  }

  static bool _isAllowedMainFrame(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;
    if (uri.scheme == 'about' || uri.scheme == 'data') return true;
    return uri.scheme == 'https' &&
        (_isYouTubeHost(uri.host) ||
            uri.host.toLowerCase() == 'com.nuvtune.app');
  }

  static bool _isCriticalYouTubeResource(String? rawUrl) {
    if (rawUrl == null) return false;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !_isYouTubeHost(uri.host)) return false;
    return uri.path == '/iframe_api' ||
        uri.path.startsWith('/embed/') ||
        uri.path.startsWith('/s/player/');
  }

  static bool _isYouTubeHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'youtube.com' ||
        normalized.endsWith('.youtube.com') ||
        normalized == 'youtube-nocookie.com' ||
        normalized.endsWith('.youtube-nocookie.com');
  }

  @override
  void dispose() {
    _generation++;
    _loadTimer?.cancel();
    _playbackSyncTimer?.cancel();
    _playbackClock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_loadState.phase != MusicVideoBackgroundPhase.error)
            WebViewWidget(controller: _controller),
          if (_loadState.phase == MusicVideoBackgroundPhase.loading)
            const _VideoStatusFallback(showProgress: true),
          if (_loadState.phase == MusicVideoBackgroundPhase.error)
            const _VideoStatusFallback(showProgress: false),
        ],
      ),
    );
  }

  static String _html(String videoId, bool isPlaying, MusicVideoFit fit) {
    final encodedVideoId = jsonEncode(videoId);
    final playerCss = musicVideoPlayerCss(fit);
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    html, body { width: 100%; height: 100%; margin: 0; padding: 0; background: transparent; overflow: hidden; }
    $playerCss
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    function notifyHost(type, value) {
      if (!window.$_javaScriptChannel ||
          typeof window.$_javaScriptChannel.postMessage !== 'function') return;
      var payload = {type: type};
      if (typeof value === 'number') {
        if (type === 'ready') {
          payload.duration = value;
        } else {
          payload.code = value;
        }
      }
      window.$_javaScriptChannel.postMessage(JSON.stringify(payload));
    }
  </script>
  <script src="https://www.youtube.com/iframe_api"
          onerror="notifyHost('iframe_api_error')"></script>
  <script>
    var player;
    var shouldPlay = $isPlaying;
    var pendingTargetSeconds = null;
    var lastSeekAtMs = 0;
    function setPlayback(value, targetSeconds, forceSeek) {
      shouldPlay = value;
      if (typeof targetSeconds === 'number' && isFinite(targetSeconds)) {
        pendingTargetSeconds = Math.max(0, targetSeconds);
      }
      if (!player || typeof player.playVideo !== 'function') return;
      player.mute();
      if (pendingTargetSeconds !== null) {
        var currentSeconds = player.getCurrentTime();
        var driftSeconds = typeof currentSeconds === 'number'
            ? Math.abs(currentSeconds - pendingTargetSeconds)
            : Number.POSITIVE_INFINITY;
        var nowMs = Date.now();
        // Los saltos manuales se aplican inmediatamente. Durante reproducción,
        // una tolerancia corta corrige buffering sin buscar en cada muestra.
        if (forceSeek ||
            (driftSeconds > 0.65 && nowMs - lastSeekAtMs >= 750)) {
          player.seekTo(pendingTargetSeconds, true);
          lastSeekAtMs = nowMs;
        }
      }
      if (shouldPlay) {
        if (player.getPlayerState() !== YT.PlayerState.PLAYING) {
          player.playVideo();
        }
      } else {
        player.pauseVideo();
      }
    }
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: $encodedVideoId,
        playerVars: {
          autoplay: 1,
          mute: 1,
          loop: 1,
          playlist: $encodedVideoId,
          controls: 0,
          disablekb: 1,
          playsinline: 1,
          modestbranding: 1,
          rel: 0,
          fs: 0,
          iv_load_policy: 3,
          origin: '$_applicationOrigin',
          widget_referrer: '$_applicationOrigin/'
        },
        events: {
          onReady: function () {
            notifyHost('ready', player.getDuration());
            setPlayback(shouldPlay, pendingTargetSeconds, true);
          },
          onError: function (event) {
            notifyHost('error', Number(event.data));
          },
          onStateChange: function (event) {
            if (event.data === YT.PlayerState.PLAYING) {
              notifyHost('ready', player.getDuration());
            }
            if (shouldPlay && event.data === YT.PlayerState.ENDED) {
              player.seekTo(0);
              player.playVideo();
            }
          },
          onAutoplayBlocked: function () {
            notifyHost('autoplay_blocked');
          }
        }
      });
    }
  </script>
</body>
</html>
''';
  }
}

class _VideoStatusFallback extends StatelessWidget {
  const _VideoStatusFallback({required this.showProgress});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: showProgress
          ? 'Cargando video musical'
          : 'Video musical no disponible',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.95,
            colors: [
              scheme.primary.withValues(alpha: 0.24),
              scheme.secondary.withValues(alpha: 0.1),
              const Color(0xFF02050D),
            ],
          ),
        ),
        child: showProgress
            ? Center(
                child: SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
