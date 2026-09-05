import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';

/// Transicion estandar para las rutas empujadas sobre el shell principal.
///
/// Antes solo `/player` tenia una `CustomTransitionPage` propia y el resto
/// caia al cambio de pantalla por defecto del sistema; esto le da al resto de
/// la navegacion el mismo lenguaje (desvanecido + deslizamiento sutil), con
/// una duracion mas ligera que la del reproductor completo. Respeta tanto el
/// perfil de movimiento de Apariencia como "Reducir movimiento" del sistema
/// via [MotionPreferences.scale].
CustomTransitionPage<void> buildFadeSlidePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final motion = ThemeScope.of(context).motion;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: motion.scale(
      Tokens.durationMedium,
      systemReduceMotion: reduceMotion,
    ),
    reverseTransitionDuration: motion.scale(
      Tokens.durationFast,
      systemReduceMotion: reduceMotion,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
