import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/bootstrap.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/navigation/app_router.dart';
import 'package:nuvtune/app/theme/app_theme.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

final _routerProvider = Provider<GoRouter>((ref) => createRouter());

/// Apariencia elegida por el usuario (Ajustes > Apariencia).
///
/// Se resuelve una sola vez en la raiz y viaja por [ThemeScope]: si cada
/// pantalla la leyera del repositorio, un cambio de acento produciria
/// reconstrucciones desacompasadas.
final appearanceProvider = Provider<Appearance>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (settings == null) return Appearance.fallback;

  return Appearance(
    accent: AccentIdentity.byId(settings.accentId),
    // `pureBlackBackground` es de Fase 1 y sigue mandando: quien lo tuviera
    // activado no debe perder su preferencia al aparecer el ajuste nuevo.
    depth: settings.pureBlackBackground
        ? BackgroundDepth.pureBlack
        : BackgroundDepth.byId(settings.backgroundDepth),
    glass: GlassIntensity.byId(settings.glassIntensity),
    dynamicFromCover: settings.useDynamicColor,
  );
});

/// Raiz de la aplicacion.
///
/// Mientras el arranque no termina se muestra una pantalla propia: la interfaz
/// principal necesita permiso de audio y la biblioteca ya cargada, y mostrarla
/// antes daria una aplicacion aparentemente vacia.
class NuvTuneApp extends ConsumerStatefulWidget {
  const NuvTuneApp({super.key});

  @override
  ConsumerState<NuvTuneApp> createState() => _NuvTuneAppState();
}

class _NuvTuneAppState extends ConsumerState<NuvTuneApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    final appearance = ref.watch(appearanceProvider);
    final theme = AppTheme.dark(
      accent: appearance.accent,
      depth: appearance.depth,
    );

    return ThemeScope(
      appearance: appearance,
      child: bootstrap.isReady
          ? MaterialApp.router(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: theme,
              routerConfig: ref.watch(_routerProvider),
              builder: _wrapErrors,
            )
          : MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: _BootstrapScreen(state: bootstrap),
              builder: _wrapErrors,
            ),
    );
  }

  /// Un fallo al construir una pantalla no puede costar la aplicación entera.
  ///
  /// Sin esto, Flutter en release pinta su `ErrorWidget`, que es un rectángulo
  /// gris a pantalla completa; ya ocurrió una vez con una excepción en la
  /// pantalla de Inicio. Aquí el fallo queda contenido en una tarjeta y el
  /// resto de la navegación sigue viva.
  Widget _wrapErrors(BuildContext context, Widget? child) {
    ErrorWidget.builder = (details) => _SectionErrorCard(details: details);
    return child ?? const SizedBox.shrink();
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space5),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconBadge(
                  icon: Icons.error_outline_rounded,
                  color: Color(0xFFFF5470),
                ),
                const SizedBox(height: Tokens.space3),
                Text(
                  'Esta sección no se pudo mostrar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Tokens.space2),
                Text(
                  'El resto de la aplicación sigue funcionando.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapScreen extends ConsumerWidget {
  const _BootstrapScreen({required this.state});

  final BootstrapState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(bootstrapProvider.notifier);
    final accent = ThemeScope.of(context).accent;

    if (state.needsPermission) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: AppStrings.permissionTitle,
          message: AppStrings.permissionBody,
          actionLabel:
              state.stage == BootstrapStage.permissionPermanentlyDenied
                  ? AppStrings.openSystemSettings
                  : AppStrings.grantPermission,
          onAction: state.stage == BootstrapStage.permissionPermanentlyDenied
              ? controller.openSystemSettings
              : controller.retry,
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.radiusXLarge),
                gradient: accent.compactGradient,
                boxShadow: [
                  BoxShadow(
                    color: accent.middle.withValues(alpha: 0.4),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.graphic_eq_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Tokens.space5),
            GradientText(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Tokens.space1),
            Text(
              AppStrings.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: Tokens.space6),
            SizedBox(
              width: 168,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radiusPill),
                child: const LinearProgressIndicator(minHeight: 4),
              ),
            ),
            const SizedBox(height: Tokens.space3),
            Text(
              switch (state.stage) {
                BootstrapStage.requestingPermission =>
                  AppStrings.permissionTitle,
                _ => 'Preparando el motor de audio…',
              },
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
