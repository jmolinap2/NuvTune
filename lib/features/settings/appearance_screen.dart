import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/app_theme_identity.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_scene_aspect_ratio.dart';
import 'package:nuvtune/features/player/player_visual_scene.dart';
import 'package:nuvtune/features/player/visualizer_color_map.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';
import 'package:nuvtune/features/lyrics/lyrics_animation_style.dart';
import 'package:nuvtune/features/player/visualizer_quality.dart';
import 'package:nuvtune/features/settings/visualizer_color_map_screen.dart';
import 'package:nuvtune/features/player/audio_visualizer.dart';
import 'package:nuvtune/features/player/visualization_picker.dart';
import 'package:nuvtune/features/settings/player_density.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';
import 'package:nuvtune/features/settings/personalization_models.dart';
import 'package:nuvtune/features/settings/widgets_screen.dart';
import 'package:nuvtune/shared/widgets/accent_picker.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

/// Pestañas de «Personalización del reproductor».
///
/// El tema global ya no está aquí: vive en su propia pantalla
/// (`/settings/theme`) porque afecta a toda la aplicación, mientras que estas
/// pestañas solo tocan el reproductor y su widget.
enum AppearanceTab {
  player('player'),
  motion('motion'),
  widget('widget');

  const AppearanceTab(this.id);
  final String id;

  static AppearanceTab byId(String? id) => values.firstWhere(
    (tab) => tab.id == id,
    orElse: () => AppearanceTab.player,
  );
}

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({this.initialTab = AppearanceTab.player, super.key});

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
      title: const Text('Personalización del reproductor'),
      bottom: TabBar(
        controller: _controller,
        tabs: const [
          Tab(icon: Icon(Icons.smart_display_outlined), text: 'Reproductor'),
          Tab(icon: Icon(Icons.animation_rounded), text: 'Movimiento'),
          Tab(icon: Icon(Icons.widgets_outlined), text: 'Widget'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _controller,
      children: const [
        _PlayerAppearancePanel(),
        _MotionAppearancePanel(),
        WidgetSettingsContent(),
      ],
    ),
  );
}

/// Contenido de «Apariencia de la app». Se expone para que
/// [AppThemeScreen] lo aloje en su propia pantalla.
class AppThemePanel extends ConsumerWidget {
  const AppThemePanel({super.key});

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
        // Tres bloques, de lo general a lo concreto: qué identidad quieres,
        // qué define esa identidad y, por último, el color de énfasis. Antes
        // eran cuatro listas sueltas (modo, tema base, énfasis, superficies)
        // cuya relación entre sí no se podía deducir mirándolas.
        const SettingsSectionLabel('Tema activo'),
        const _Note('Elige la identidad visual general de NuvTune.'),
        const SizedBox(height: Tokens.space3),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            itemCount: AppThemeIdentity.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: Tokens.space3),
            itemBuilder: (context, index) {
              final identity = AppThemeIdentity.values[index];
              return _IdentityCard(
                identity: identity,
                selected: appearance.identity == identity,
                // Cambiar de identidad limpia los desvíos por eje: si no, un
                // ajuste heredado del tema anterior haría que la identidad
                // recién elegida no se viera como se anuncia.
                onTap: () => mutation.save(
                  AppSettingsCompanion(
                    themeIdentity: Value(identity.id),
                    accentId: Value(identity.accentId),
                    backgroundDepth: Value(identity.depth.id),
                    glassIntensity: Value(identity.surface.glassIntensity.id),
                    surfaceStyle: const Value(''),
                    typographyStyle: const Value(''),
                    layoutDensity: const Value(''),
                  ),
                ),
              );
            },
          ),
        ),
        const SettingsSectionLabel('Qué cambia'),
        const _Note('Define la estructura visual de la app.'),
        const SizedBox(height: Tokens.space3),
        _AxisSelector<SurfaceStyle>(
          icon: Icons.layers_outlined,
          title: 'Superficies y profundidad',
          values: SurfaceStyle.values,
          selected: appearance.surface,
          labelOf: (value) => value.label,
          descriptionOf: (value) => value.description,
          onSelected: (value) => mutation.save(
            AppSettingsCompanion(
              surfaceStyle: Value(value.id),
              glassIntensity: Value(value.glassIntensity.id),
            ),
          ),
        ),
        _AxisSelector<TypographyStyle>(
          icon: Icons.text_fields_rounded,
          title: 'Tipografía e iconos',
          values: TypographyStyle.values,
          selected: appearance.typography,
          labelOf: (value) => value.label,
          descriptionOf: (value) => value.description,
          onSelected: (value) => mutation.save(
            AppSettingsCompanion(typographyStyle: Value(value.id)),
          ),
        ),
        _AxisSelector<LayoutDensity>(
          icon: Icons.density_medium_rounded,
          title: 'Densidad y espaciado',
          values: LayoutDensity.values,
          selected: appearance.density,
          labelOf: (value) => value.label,
          descriptionOf: (value) => value.description,
          onSelected: (value) => mutation.save(
            AppSettingsCompanion(layoutDensity: Value(value.id)),
          ),
        ),
        const SettingsSectionLabel('Color de énfasis'),
        const _Note(AppStrings.appearanceAccentNote),
        const SizedBox(height: Tokens.space3),
        _AccentGrid(selected: settings.accentId),
        const SettingsSectionLabel('Vista previa'),
        const _AppearancePreview(),
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
    final lyricsAnimation = LyricsAnimationStyle.byId(
      settings.lyricsAnimationStyle,
    );

    // Estructura del documento de reorganización: Diseño, Fondo y ambiente,
    // Visualizador. La densidad vive aquí porque es composición visual del
    // reproductor, no interacción, y por eso salió de «Control».
    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        const _PlayerPreview(),
        const SettingsSectionLabel('Diseño'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: scene.icon,
              title: 'Escenario',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space3,
            Tokens.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Densidad', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Tokens.space2),
              SegmentedButton<PlayerDensity>(
                segments: [
                  for (final option in PlayerDensity.values)
                    ButtonSegment(value: option, label: Text(option.label)),
                ],
                selected: {PlayerDensity.byId(settings.playerDensity)},
                onSelectionChanged: (selection) => mutation.save(
                  AppSettingsCompanion(
                    playerDensity: Value(selection.first.id),
                  ),
                ),
              ),
              const SizedBox(height: Tokens.space2),
              Text(
                'Cuánto aire deja el reproductor alrededor de sus elementos.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SettingsSectionLabel('Fondo y ambiente'),
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
        const SettingsSectionLabel('Visualizador'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: visualizer.icon,
              title: 'Estilo',
              subtitle: visualizer.label,
              onTap: () => showVisualizerStylePicker(context, ref),
            ),
            SettingsNavigationRow(
              icon: Icons.gradient_rounded,
              title: 'Color reactivo',
              subtitle: 'Mapa de colores por intensidad y modo de aplicación',
              onTap: () => context.push('/settings/player/visualizer/colors'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.casino_outlined),
              title: const Text('Colores aleatorios'),
              subtitle: const Text(
                'La paleta evoluciona suavemente con la canción y el ritmo.',
              ),
              value: settings.visualizerRandomColors,
              onChanged: (value) => mutation.save(
                AppSettingsCompanion(visualizerRandomColors: Value(value)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Cameo de Auris'),
              subtitle: const Text(
                'Auris aparece de vez en cuando bailando al ritmo, dentro del visualizador.',
              ),
              value: settings.aurisCameoEnabled,
              onChanged: (value) => mutation.save(
                AppSettingsCompanion(aurisCameoEnabled: Value(value)),
              ),
            ),
          ],
        ),
        const SettingsSectionLabel('Letras'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: lyricsAnimation.icon,
              title: 'Animación sincronizada',
              subtitle:
                  '${lyricsAnimation.label} · ${lyricsAnimation.description}',
              onTap: () => showLyricsAnimationStylePicker(context, ref),
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
          icon: Icons.speed_rounded,
          title: 'La calidad no cambia el color',
          message:
              'Eco, Normal y Ultra solo ajustan rendimiento: bandas, FPS y '
              'partículas. El mapa de colores elegido se respeta siempre.',
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
        // El mapa gobierna los estilos del visualizador y no depende de la
        // fuente de color: son dos ajustes de cosas distintas.
        const SettingsSectionLabel('Color del visualizador'),
        _ColorMapTile(
          map: VisualizerColorMap.fromJsonString(
            settings.visualizerColorMapJson,
          ),
          mode: VisualizerColorMode.byId(settings.visualizerColorMode),
        ),
        const SettingsSectionLabel('Color de la carátula'),
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

/// Acceso al mapa de colores con su degradado a la vista, para que el ajuste
/// se reconozca sin abrirlo.
class _ColorMapTile extends StatelessWidget {
  const _ColorMapTile({required this.map, required this.mode});

  final VisualizerColorMap map;
  final VisualizerColorMode mode;

  @override
  Widget build(BuildContext context) {
    final gradient = map.toGradient();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Mapa de colores'),
        subtitle: Text(
          '${map.stops.length} colores · ${mode.label.toLowerCase()}',
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radiusSmall),
            gradient: LinearGradient(
              colors: gradient.colors,
              stops: gradient.positions,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const VisualizerColorMapScreen(),
          ),
        ),
      ),
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
    const labels = ['Nula', 'Suave', 'Media', 'Alta', 'Extrema'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label)),
              Text(labels[value.round().clamp(0, 4)]),
            ],
          ),
          Slider(
            value: value.clamp(0, 4),
            max: 4,
            divisions: 4,
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
      3 => const Duration(milliseconds: 380),
      _ => const Duration(milliseconds: 280),
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

/// Tarjeta de una identidad completa: se ve con sus propios colores, no con
/// los del tema activo, para poder compararlas de un vistazo.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.identity,
    required this.selected,
    required this.onTap,
  });

  final AppThemeIdentity identity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = identity.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: '${identity.name}. ${identity.tags.join(", ")}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        child: AnimatedContainer(
          duration: ThemeScope.of(context).motion.scale(
            Tokens.durationFast,
            systemReduceMotion: MediaQuery.disableAnimationsOf(context),
          ),
          curve: ThemeScope.of(context).motion.curve,
          width: 208,
          padding: const EdgeInsets.all(Tokens.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radiusLarge),
            color: identity.previewBackground,
            border: Border.all(
              color: selected
                  ? accent.middle
                  : identity.previewText.withValues(alpha: 0.14),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      identity.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent.middle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: accent.middle,
                    ),
                ],
              ),
              const SizedBox(height: Tokens.space2),
              // Miniatura del reproductor: es donde más se nota la identidad.
              Container(
                padding: const EdgeInsets.all(Tokens.space2),
                decoration: BoxDecoration(
                  color: identity.previewSurface,
                  borderRadius: BorderRadius.circular(Tokens.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: accent.compactGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: Tokens.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: identity.previewText.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 5,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: identity.previewText.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Tokens.space2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.skip_previous_rounded,
                          size: 14,
                          color: identity.previewText.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: accent.middle,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.pause_rounded,
                            size: 13,
                            color: identity.previewBackground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.skip_next_rounded,
                          size: 14,
                          color: identity.previewText.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Tokens.space2),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final tag in identity.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Tokens.radiusPill),
                        border: Border.all(
                          color: identity.previewText.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: identity.previewText.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uno de los tres ejes que componen una identidad. Se muestran juntos y con
/// el mismo formato porque juntos responden a «qué cambia» al elegir un tema.
class _AxisSelector<T> extends StatelessWidget {
  const _AxisSelector({
    required this.icon,
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.descriptionOf,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final String Function(T) descriptionOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        0,
        Tokens.gutter,
        Tokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.space2),
          Wrap(
            spacing: Tokens.space2,
            runSpacing: Tokens.space2,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descriptionOf(selected),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
