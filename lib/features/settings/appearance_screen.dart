import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_scene_aspect_ratio.dart';
import 'package:nuvtune/features/player/player_visual_scene.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';
import 'package:nuvtune/features/player/visualizer_quality.dart';
import 'package:nuvtune/features/player/visualization_picker.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';
import 'package:nuvtune/features/settings/widgets_screen.dart';
import 'package:nuvtune/shared/widgets/accent_picker.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

enum AppearanceTab {
  app('app'),
  player('player'),
  motion('motion'),
  widget('widget');

  const AppearanceTab(this.id);
  final String id;

  static AppearanceTab byId(String? id) =>
      values.firstWhere((tab) => tab.id == id, orElse: () => AppearanceTab.app);
}

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({this.initialTab = AppearanceTab.app, super.key});

  final AppearanceTab initialTab;

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: AppearanceTab.values.length,
    initialIndex: widget.initialTab.index,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Personalización'),
      bottom: TabBar(
        controller: _controller,
        tabs: const [
          Tab(icon: Icon(Icons.palette_outlined), text: 'Tema'),
          Tab(icon: Icon(Icons.smart_display_outlined), text: 'Reproductor'),
          Tab(icon: Icon(Icons.animation_rounded), text: 'Movimiento'),
          Tab(icon: Icon(Icons.widgets_outlined), text: 'Widget'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _controller,
      children: const [
        _AppAppearancePanel(),
        _PlayerAppearancePanel(),
        _MotionAppearancePanel(),
        WidgetSettingsContent(),
      ],
    ),
  );
}

class _AppAppearancePanel extends ConsumerWidget {
  const _AppAppearancePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final appearance = ThemeScope.of(context);
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final mutation = ref.read(settingsMutationProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        const _AppearancePreview(),
        const SettingsSectionLabel('Modo'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Wrap(
            spacing: Tokens.space2,
            runSpacing: Tokens.space2,
            children: [
              for (final mode in AppThemePreference.values)
                ChoiceChip(
                  label: Text(mode.label),
                  selected: AppThemePreference.byId(settings.themeMode) == mode,
                  onSelected: (_) => mutation.save(
                    AppSettingsCompanion(themeMode: Value(mode.id)),
                  ),
                ),
            ],
          ),
        ),
        const SettingsSectionLabel('Tema base'),
        const _Note(
          'Define fondos y superficies. El color de énfasis se elige aparte.',
        ),
        const SizedBox(height: Tokens.space3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - Tokens.space2) / 2;
              return Wrap(
                spacing: Tokens.space2,
                runSpacing: Tokens.space2,
                children: [
                  for (final depth in BackgroundDepth.values.where(
                    (value) => value != BackgroundDepth.pureBlack,
                  ))
                    SizedBox(
                      width: width,
                      child: _DepthOption(
                        depth: depth,
                        selected: appearance.depth == depth,
                        onTap: () => mutation.save(
                          AppSettingsCompanion(
                            backgroundDepth: Value(depth.id),
                            pureBlackBackground: Value(
                              depth == BackgroundDepth.pureBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SettingsSectionLabel('Color de énfasis'),
        const _Note(AppStrings.appearanceAccentNote),
        const SizedBox(height: Tokens.space3),
        _AccentGrid(selected: settings.accentId),
        const SettingsSectionLabel('Superficies'),
        const _Note(AppStrings.appearanceGlassNote),
        const SizedBox(height: Tokens.space3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: SegmentedButton<GlassIntensity>(
            segments: [
              for (final intensity in GlassIntensity.values)
                ButtonSegment(value: intensity, label: Text(intensity.label)),
            ],
            selected: {appearance.glass},
            onSelectionChanged: (selection) => mutation.save(
              AppSettingsCompanion(glassIntensity: Value(selection.first.id)),
            ),
          ),
        ),
        const SizedBox(height: Tokens.space4),
        const SettingsInfoPanel(
          icon: Icons.accessibility_new_rounded,
          title: 'Movimiento según Android',
          message:
              'Auris, el visualizador y las transiciones se detienen automáticamente cuando el sistema pide reducir animaciones.',
        ),
      ],
    );
  }
}

class _PlayerAppearancePanel extends ConsumerWidget {
  const _PlayerAppearancePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final mutation = ref.read(settingsMutationProvider.notifier);
    final scene = PlayerVisualScene.fromIndex(settings.playerVisualScene);
    final ratio = PlayerSceneAspectRatio.fromIndex(
      settings.playerSceneAspectRatio,
    );
    final visualizer = VisualizerStyle.fromIndex(
      settings.playerVisualizerStyle,
    );
    final visualizerQuality = VisualizerQuality.byId(
      settings.playerVisualizerQuality,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        const _PlayerPreview(),
        const SettingsSectionLabel('Diseño'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: Icons.dashboard_customize_outlined,
              title: 'Diseño y controles',
              subtitle: 'Posición, orden, visibilidad y densidad',
              onTap: () => context.push('/settings/control'),
            ),
          ],
        ),
        const SettingsSectionLabel('Color y fondo'),
        SettingsGroup(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.palette_outlined),
              title: const Text(AppStrings.dynamicColor),
              subtitle: const Text('Usa el color dominante de la portada.'),
              value: settings.useDynamicColor,
              onChanged: (value) => mutation.save(
                AppSettingsCompanion(useDynamicColor: Value(value)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.movie_filter_outlined),
              title: const Text('Fondo de video musical en Wi-Fi'),
              subtitle: const Text('Nunca utiliza datos móviles.'),
              value: settings.videoBackgroundEnabled,
              onChanged: (value) => mutation.save(
                AppSettingsCompanion(videoBackgroundEnabled: Value(value)),
              ),
            ),
          ],
        ),
        const SettingsSectionLabel('Escena visual'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: scene.icon,
              title: 'Escenario y estilo',
              subtitle: scene.showsVisualizer
                  ? '${scene.label} · ${visualizer.label}'
                  : '${scene.label} · el estilo no se aplica en esta escena',
              onTap: () => showVisualizationPicker(context, ref),
            ),
            SettingsNavigationRow(
              icon: ratio.icon,
              title: 'Relación de aspecto',
              subtitle: '${ratio.label} · ${ratio.description}',
              onTap: () => _selectRatio(context, ref, ratio),
            ),
          ],
        ),
        const SettingsSectionLabel('Rendimiento del visualizador'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<VisualizerQuality>(
                segments: [
                  for (final quality in VisualizerQuality.values)
                    ButtonSegment(value: quality, label: Text(quality.label)),
                ],
                selected: {visualizerQuality},
                onSelectionChanged: (selection) => mutation.save(
                  AppSettingsCompanion(
                    playerVisualizerQuality: Value(selection.first.id),
                  ),
                ),
              ),
              const SizedBox(height: Tokens.space2),
              Text(
                visualizerQuality.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space3),
        const SettingsInfoPanel(
          icon: Icons.animation_rounded,
          title: 'Movimiento configurable',
          message:
              'La intensidad, la respuesta al ritmo, las partículas y sus colores se ajustan en la pestaña Movimiento.',
        ),
      ],
    );
  }

  Future<void> _selectRatio(
    BuildContext context,
    WidgetRef ref,
    PlayerSceneAspectRatio selected,
  ) async {
    final choice = await showPlayerSceneAspectRatioPicker(
      context,
      selected: selected,
    );
    if (choice == null) return;
    await ref
        .read(settingsMutationProvider.notifier)
        .save(
          AppSettingsCompanion(playerSceneAspectRatio: Value(choice.index)),
        );
  }
}

class _MotionAppearancePanel extends ConsumerWidget {
  const _MotionAppearancePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final mutation = ref.read(settingsMutationProvider.notifier);
    final profile = MotionProfile.byId(settings.motionProfile);
    final colorSource = VisualizerColorSource.byId(
      settings.visualizerColorSource,
    );
    final motion = MotionPreferences(
      profile: profile,
      intensity: settings.motionIntensity,
      smoothness: settings.motionSmoothness,
      beatResponse: settings.motionBeatResponse,
      particles: settings.motionParticles,
      colorSource: colorSource,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        _MotionPreview(motion: motion),
        const SettingsSectionLabel('Personalidad'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Wrap(
            spacing: Tokens.space2,
            runSpacing: Tokens.space2,
            children: [
              for (final option in MotionProfile.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: profile == option,
                  onSelected: (_) => mutation.save(
                    AppSettingsCompanion(
                      motionProfile: Value(option.id),
                      reduceVisualizerEffects: Value(
                        option == MotionProfile.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (profile == MotionProfile.custom) ...[
          const SettingsSectionLabel('Ajuste fino'),
          _MotionSlider(
            label: 'Intensidad',
            value: settings.motionIntensity,
            onSaved: (value) => mutation.save(
              AppSettingsCompanion(motionIntensity: Value(value)),
            ),
          ),
          _MotionSlider(
            label: 'Suavidad',
            value: settings.motionSmoothness,
            onSaved: (value) => mutation.save(
              AppSettingsCompanion(motionSmoothness: Value(value)),
            ),
          ),
          _MotionSlider(
            label: 'Respuesta al ritmo',
            value: settings.motionBeatResponse,
            onSaved: (value) => mutation.save(
              AppSettingsCompanion(motionBeatResponse: Value(value)),
            ),
          ),
          _MotionSlider(
            label: 'Partículas y destellos',
            value: settings.motionParticles,
            onSaved: (value) => mutation.save(
              AppSettingsCompanion(motionParticles: Value(value)),
            ),
          ),
        ],
        const SettingsSectionLabel('Color de los efectos'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Wrap(
            spacing: Tokens.space2,
            runSpacing: Tokens.space2,
            children: [
              for (final option in VisualizerColorSource.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: colorSource == option,
                  onSelected: (_) => mutation.save(
                    AppSettingsCompanion(
                      visualizerColorSource: Value(option.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space4),
        const SettingsInfoPanel(
          icon: Icons.accessibility_new_rounded,
          title: 'Accesibilidad primero',
          message:
              'Reducir animaciones de Android y la protección térmica siempre tienen prioridad sobre este perfil.',
        ),
      ],
    );
  }
}

class _MotionSlider extends StatefulWidget {
  const _MotionSlider({
    required this.label,
    required this.value,
    required this.onSaved,
  });

  final String label;
  final int value;
  final ValueChanged<int> onSaved;

  @override
  State<_MotionSlider> createState() => _MotionSliderState();
}

class _MotionSliderState extends State<_MotionSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.value.toDouble();
    const labels = ['Nula', 'Suave', 'Media', 'Alta'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label)),
              Text(labels[value.round().clamp(0, 3)]),
            ],
          ),
          Slider(
            value: value.clamp(0, 3),
            max: 3,
            divisions: 3,
            onChanged: (next) => setState(() => _dragValue = next),
            onChangeEnd: (next) {
              setState(() => _dragValue = null);
              widget.onSaved(next.round());
            },
          ),
        ],
      ),
    );
  }
}

class _MotionPreview extends StatefulWidget {
  const _MotionPreview({required this.motion});

  final MotionPreferences motion;

  @override
  State<_MotionPreview> createState() => _MotionPreviewState();
}

class _MotionPreviewState extends State<_MotionPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    if (widget.motion.effectiveIntensity == 0 ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    final base = switch (widget.motion.effectiveIntensity) {
      1 => const Duration(milliseconds: 760),
      2 => const Duration(milliseconds: 560),
      _ => const Duration(milliseconds: 380),
    };
    _controller.duration = widget.motion.scale(base);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = ThemeScope.of(context).accent;
    final effectColor = switch (widget.motion.colorSource) {
      VisualizerColorSource.cover => accent.start,
      VisualizerColorSource.accent => scheme.primary,
      VisualizerColorSource.neutral => scheme.onSurfaceVariant,
      VisualizerColorSource.off => Colors.transparent,
    };
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
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final curve = widget.motion.curve.transform(_controller.value);
          final amplitude = widget.motion.effectiveIntensity * 0.025;
          return Column(
            children: [
              Transform.scale(
                scale: 1 + math.sin(curve * math.pi) * amplitude,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Tokens.radiusLarge),
                    gradient: LinearGradient(
                      colors: [accent.start, effectColor, accent.end],
                    ),
                    boxShadow: effectColor == Colors.transparent
                        ? const []
                        : [
                            BoxShadow(
                              color: effectColor.withValues(
                                alpha: 0.12 + curve * 0.20,
                              ),
                              blurRadius: 18 + curve * 24,
                            ),
                          ],
                  ),
                  child: const Icon(Icons.music_note_rounded, size: 40),
                ),
              ),
              const SizedBox(height: Tokens.space3),
              const Text(
                'Notes ’n’ Words',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Text('ONE OK ROCK'),
              const SizedBox(height: Tokens.space3),
              FilledButton.icon(
                onPressed: _play,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Probar movimiento'),
              ),
            ],
          );
        },
      ),
    );
  }
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

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview();

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
      child: RepaintBoundary(
        child: GlassCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                  gradient: accent.compactGradient,
                ),
                child: const Icon(Icons.graphic_eq_rounded),
              ),
              const SizedBox(width: Tokens.space3),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Eclipse Interior',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('Aurora Vector'),
                  ],
                ),
              ),
              GradientPlayButton(isPlaying: true, onPressed: () {}, size: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerPreview extends StatelessWidget {
  const _PlayerPreview();

  @override
  Widget build(BuildContext context) => Container(
    height: 176,
    margin: const EdgeInsets.fromLTRB(
      Tokens.gutter,
      Tokens.space4,
      Tokens.gutter,
      0,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Tokens.radiusXLarge),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      gradient: RadialGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.42),
          Theme.of(context).colorScheme.surface,
        ],
      ),
    ),
    child: const RepaintBoundary(
      child: Center(child: Icon(Icons.graphic_eq_rounded, size: 72)),
    ),
  );
}

class _AccentGrid extends ConsumerWidget {
  const _AccentGrid({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
    child: AccentSwatchGrid(
      selected: selected,
      onSelected: (identity) => ref
          .read(settingsMutationProvider.notifier)
          .save(AppSettingsCompanion(accentId: Value(identity.id))),
    ),
  );
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
    return Semantics(
      button: true,
      selected: selected,
      label: depth.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
        child: AnimatedContainer(
          duration: ThemeScope.of(context).motion.scale(
            Tokens.durationFast,
            systemReduceMotion: MediaQuery.disableAnimationsOf(context),
          ),
          curve: ThemeScope.of(context).motion.curve,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final color in [
                    depth.surface,
                    depth.surfaceHigh,
                    depth.surfaceHighest,
                  ])
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Tokens.space2),
              Text(
                depth.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
