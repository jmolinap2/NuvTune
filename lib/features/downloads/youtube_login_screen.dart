import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Inicio de sesion de YouTube (feature "buscar y descargar canciones").
///
/// Sin sesion, YouTube exige "confirma que no eres un robot" y bloquea el
/// audio real de casi cualquier video a un cliente anonimo: medido en el
/// dispositivo, con el yt-dlp mas reciente disponible, sin distinguir por
/// video. Esta pantalla es la pagina real de Google en un WebView, igual que
/// cualquier navegador — NuvTune nunca ve ni guarda la contraseña. Al pulsar
/// "Ya inicié sesión", el lado nativo (`YouTubeCookieJar`) lee las cookies
/// del mismo `CookieManager` que comparte cualquier WebView de la app y las
/// guarda para que yt-dlp las use con `--cookies`.
class YouTubeLoginScreen extends ConsumerStatefulWidget {
  const YouTubeLoginScreen({super.key});

  @override
  ConsumerState<YouTubeLoginScreen> createState() =>
      _YouTubeLoginScreenState();
}

class _YouTubeLoginScreenState extends ConsumerState<YouTubeLoginScreen> {
  late final WebViewController _controller;
  bool _loadingPage = true;
  bool _checkingLogin = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loadingPage = true);
          },
          onPageFinished: (url) {
            // Traza minima (solo la URL, nunca el contenido de la pagina)
            // para poder confirmar por logcat en que paso del login de
            // Google se queda atascado, sin depender de una captura.
            debugPrint('YouTubeLoginScreen: pagina cargada -> $url');
            if (mounted) setState(() => _loadingPage = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://accounts.google.com/ServiceLogin'
          '?continue=https%3A%2F%2Fwww.youtube.com%2F',
        ),
      );

    // Algunos pasos del inicio de sesion de Google (verificacion en dos
    // pasos, reCAPTCHA) corren en un origen distinto dentro de la misma
    // pagina; sin esto, Android WebView descarta esas cookies por defecto.
    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      unawaited(
        AndroidWebViewCookieManager(
          const PlatformWebViewCookieManagerCreationParams(),
        ).setAcceptThirdPartyCookies(platformController, true),
      );
    }
  }

  Future<void> _confirmLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _checkingLogin = true);
    try {
      final saved = await ref
          .read(downloadEngineProvider)
          .api
          .saveYouTubeCookies();
      if (!mounted) return;
      if (saved) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Sesión de YouTube guardada.')),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Todavía no detectamos tu sesión. Termina de iniciar sesión '
              'arriba y vuelve a intentarlo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingLogin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión de YouTube')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space3,
              Tokens.gutter,
              Tokens.space2,
            ),
            child: Text(
              'Inicia sesión con tu cuenta de Google igual que en cualquier '
              'navegador. NuvTune solo lee las cookies de la sesión para '
              'poder descargar el audio real de YouTube; nunca ve ni guarda '
              'tu contraseña.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_loadingPage) const LinearProgressIndicator(),
          Expanded(child: WebViewWidget(controller: _controller)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.gutter),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checkingLogin ? null : _confirmLogin,
                  icon: _checkingLogin
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Ya inicié sesión'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
