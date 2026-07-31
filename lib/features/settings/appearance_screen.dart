import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

/// Apariencia de la aplicación.
///
/// El sistema visual de NuvTune no se apoya en un color de acento sino en un
/// degradado de tres paradas, así que lo que se elige aquí es una identidad
/// completa y no un color suelto. La vista previa de arriba usa los mismos
/// componentes que el resto de la aplicación, de modo que muestra el resultado
/// real y no una aproximación.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final appearance = ThemeScope.of(context);

    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsAppearance)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          const _Preview(),

          SectionLabel(AppStrings.appearanceAccent),
          _Note(AppStrings.appearanceAccentNote),
          const SizedBox(height: Tokens.space3),
          _AccentGrid(selected: settings.accentId),

          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text(AppStrings.dynamicColor),
            subtitle: const Text(
              'En el reproductor, el acento se toma de la portada de la '
              'canción que suena. El resto de la aplicación mantiene el color '
              'elegido arriba.',
            ),
            value: settings.useDynamicColor,
            onChanged: (value) => _save(
              ref,
              AppSettingsCompanion(useDynamicColor: Value(value)),
            ),
          ),

          SectionLabel(AppStrings.appearanceDepth),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Row(
              children: [
                for (final depth in BackgroundDepth.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Tokens.space2),
                      child: _DepthOption(
                        depth: depth,
                        selected: appearance.depth == depth,
                        onTap: () => _selectDepth(ref, depth),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SectionLabel(AppStrings.appearanceGlass),
          _Note(AppStrings.appearanceGlassNote),
          const SizedBox(height: Tokens.space3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: SegmentedButton<GlassIntensity>(
              segments: [
                for (final intensity in GlassIntensity.values)
                  ButtonSegment(
                    value: intensity,
                    label: Text(intensity.label),
                  ),
              ],
              selected: {appearance.glass},
              onSelectionChanged: (selection) => _save(
                ref,
                AppSettingsCompanion(
                  glassIntensity: Value(selection.first.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(WidgetRef ref, AppSettingsCompanion companion) =>
      ref.read(settingsRepositoryProvider).update(companion);

  /// `pureBlackBackground` es el ajuste de Fase 1 y sigue mandando sobre la
  /// profundidad, de modo que hay que mantener los dos coherentes en lugar de
  /// dejar que se contradigan.
  Future<void> _selectDepth(WidgetRef ref, BackgroundDepth depth) => _save(
        ref,
        AppSettingsCompanion(
          backgroundDepth: Value(depth.id),
          pureBlackBackground: Value(depth == BackgroundDepth.pureBlack),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

/// Vista previa con los componentes reales del sistema visual.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space4,
        Tokens.gutter,
        0,
      ),
      padding: const EdgeInsets.all(Tokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusXLarge),
        gradient: accent.headerGradient(scheme.surfaceContainerLow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.appearancePreview.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: Tokens.space3),
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                    gradient: accent.compactGradient,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eclipse Interior',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aurora Vector',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                GradientPlayButton(
                  isPlaying: true,
                  onPressed: () {},
                  size: 44,
                ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.space3),
          // Barras del ecualizador, que es donde el degradado se ve entero.
          SizedBox(
            height: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final height in _previewBars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: 46 * height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [accent.end, accent.start],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _previewBars = <double>[
    0.35, 0.6, 0.85, 0.5, 0.7, 1, 0.65, 0.4, 0.75, 0.55, 0.9, 0.45,
  ];
}

class _AccentGrid extends ConsumerWidget {
  const _AccentGrid({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Wrap(
        spacing: Tokens.space3,
        runSpacing: Tokens.space3,
        children: [
          for (final identity in AccentIdentity.all)
            _AccentSwatch(
              identity: identity,
              selected: identity.id == selected,
              onTap: () => ref.read(settingsRepositoryProvider).update(
                    AppSettingsCompanion(accentId: Value(identity.id)),
                  ),
            ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.identity,
    required this.selected,
    required this.onTap,
  });

  final AccentIdentity identity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Tokens.durationFast,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.radiusMedium),
                gradient: identity.gradient,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: identity.middle.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: Tokens.space2),
            Text(
              identity.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepthOption extends StatelessWidget {
  const _DepthOption({
    required this.depth,
    required this.selected,
    required this.onTap,
  });

  final BackgroundDepth depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Tokens.durationFast,
        padding: const EdgeInsets.all(Tokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusMedium),
          color: depth.background,
          border: Border.all(
            color: selected
                ? accent.middle
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Muestra de las tres superficies de esta profundidad.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in [
                  depth.surface,
                  depth.surfaceHigh,
                  depth.surfaceHighest,
                ])
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Tokens.space2),
            Text(
              depth.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
