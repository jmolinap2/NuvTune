import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Fondo de video musical del reproductor (feature "video de fondo en
/// Wi-Fi"): reproduce el video oficial de YouTube igual que su web publica,
/// via el IFrame Player API embebido — no descarga ni reempaqueta contenido.
class MusicVideoBackground extends StatefulWidget {
  const MusicVideoBackground({required this.videoId, super.key});

  final String videoId;

  @override
  State<MusicVideoBackground> createState() => _MusicVideoBackgroundState();
}

class _MusicVideoBackgroundState extends State<MusicVideoBackground> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant MusicVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller = _buildController(widget.videoId);
    }
  }

  WebViewController _buildController(String videoId) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_html(videoId));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: WebViewWidget(controller: _controller));
  }

  static String _html(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    html, body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
    #player { position: absolute; top: 50%; left: 50%; width: 100%; height: 100%; transform: translate(-50%, -50%) scale(1.6); }
  </style>
</head>
<body>
  <div id="player"></div>
  <script src="https://www.youtube.com/iframe_api"></script>
  <script>
    var player;
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          autoplay: 1,
          mute: 1,
          loop: 1,
          playlist: '$videoId',
          controls: 0,
          disablekb: 1,
          playsinline: 1,
          modestbranding: 1,
          rel: 0,
          fs: 0
        },
        events: {
          onReady: function (event) { event.target.mute(); event.target.playVideo(); },
          onStateChange: function (event) {
            if (event.data === YT.PlayerState.ENDED) {
              player.seekTo(0);
              player.playVideo();
            }
          }
        }
      });
    }
  </script>
</body>
</html>
''';
}
