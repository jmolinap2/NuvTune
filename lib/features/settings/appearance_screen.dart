import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/audio_visualizer.dart';
import 'package:nuvtune/features/player/player_scene_aspect_ratio.dart';
import 'package:nuvtune/features/player/player_visual_scene.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';
import 'package:nuvtune/features/player/visualizer_quality.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';
import 'package:nuvtune/features/settings/widgets_screen.dart';
import 'package:nuvtune/shared/widgets/accent_picker.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

enum AppearanceTab {
  app('app'),
  player('player'),
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
      title: const Text(AppStrings.settingsAppearance),
      bottom: TabBar(
        controller: _controller,
        tabs: const [
          Tab(text: 'Aplicación'),
          Tab(text: 'Reproductor'),
          Tab(text: 'Widget'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _controller,
      children: const [
        _AppAppearancePanel(),
        _PlayerAppearancePanel(),
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
        const SettingsSectionLabel('Color de acento'),
        const _Note(AppStrings.appearanceAccentNote),
        const SizedBox(height: Tokens.space3),
        _AccentGrid(selected: settings.accentId),
        const SettingsSectionLabel('Fondo'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Row(
            children: [
              for (
                var index = 0;
                index < BackgroundDepth.values.length;
                index++
              ) ...[
                Expanded(
                  child: _DepthOption(
                    depth: BackgroundDepth.values[index],
                    selected: appearance.depth == BackgroundDepth.values[index],
                    onTap: () {
                      final depth = BackgroundDepth.values[index];
                      mutation.save(
                        AppSettingsCompanion(
                          backgroundDepth: Value(depth.id),
                          pureBlackBackground: Value(
                            depth == BackgroundDepth.pureBlack,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (index < BackgroundDepth.values.length - 1)
                  const SizedBox(width: Tokens.space2),
              ],
            ],
          ),
        ),
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
              title: 'Escenario del reproductor',
              subtitle: '${scene.label} · ${scene.description}',
              onTap: () => _selectScene(context, ref, scene),
            ),
            SettingsNavigationRow(
              icon: ratio.icon,
              title: 'Relación de aspecto',
              subtitle: '${ratio.label} · ${ratio.description}',
              onTap: () => _selectRatio(context, ref, ratio),
            ),
            SettingsNavigationRow(
              icon: visualizer.icon,
              title: 'Estilo del visualizador',
              subtitle:
                  '${visualizer.label} · color e intensidad siguen la música',
              onTap: () => showVisualizerStylePicker(context, ref),
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
        SettingsGroup(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.motion_photos_off_outlined),
              title: const Text('Reducir efectos visuales'),
              subtitle: const Text(
                'Reduce partículas, destellos y cambios rápidos de color.',
              ),
              value: settings.reduceVisualizerEffects,
              onChanged: (value) => mutation.save(
                AppSettingsCompanion(reduceVisualizerEffects: Value(value)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectScene(
    BuildContext context,
    WidgetRef ref,
    PlayerVisualScene selected,
  ) async {
    final choice = await showPlayerVisualScenePicker(
      context,
      selected: selected,
    );
    if (choice == null) return;
    await ref
        .read(settingsMutationProvider.notifier)
        .save(AppSettingsCompanion(playerVisualScene: Value(choice.index)));
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
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Tokens.durationFast,
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
