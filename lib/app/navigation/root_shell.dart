import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/gift_intent_service.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/player/mini_player.dart';

/// Contenedor con la navegacion inferior y el mini reproductor
/// (requerimiento seccion 12: Inicio | Biblioteca | Listas | Ajustes).
class RootShell extends ConsumerStatefulWidget {
  const RootShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Los errores del motor se muestran una sola vez y sin cortar el uso de la
    // aplicacion.
    ref.listenManual(engineErrorsProvider, (previous, next) {
      final error = next.valueOrNull;
      if (error == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 5),
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingGift());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Con la aplicacion ya abierta, tocar un regalo la trae al frente por
    // `onNewIntent`: no hay un `initState` nuevo donde mirar, hay que volver
    // a preguntar al reanudar.
    if (state == AppLifecycleState.resumed) _openPendingGift();
  }

  /// Abre el asistente de recepcion si la aplicacion se lanzo (o se reanudo)
  /// con un archivo `.nuvtune-gift`.
  Future<void> _openPendingGift() async {
    final uri = await const GiftIntentService().takePendingGift();
    if (uri == null || !mounted) return;
    context.push('/gift/receive?uri=${Uri.encodeQueryComponent(uri)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: AppStrings.navHome,
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: AppStrings.navLibrary,
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music_rounded),
                label: AppStrings.navPlaylists,
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: AppStrings.navSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    // Volver a pulsar la pestana activa regresa a su raiz, para que la pila de
    // cada seccion no crezca sin salida.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
