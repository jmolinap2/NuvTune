import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/settings/control_screen.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

/// Controles y gestos: solo cómo se interactúa con el reproductor.
///
/// La densidad se fue a «Reproductor > Diseño» (es composición visual, no
/// interacción), las reglas del motor a «Reproducción y audio» y los
/// auriculares a «Sistema > Dispositivos». Aquí queda únicamente lo que el
/// usuario toca.
class ControlsAndGesturesScreen extends ConsumerWidget {
  const ControlsAndGesturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final preset = PlayerControlPreset.byId(settings.playerControlPreset);
    final layout = preset == PlayerControlPreset.custom
        ? PlayerControlLayout.fromJsonString(settings.playerControlLayoutJson)
        : PlayerControlLayout.forPreset(preset);
    final mutation = ref.read(settingsMutationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Controles y gestos')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: ControlPreview(
              layout: layout,
              preset: preset,
              handedness: ControlHandedness.byId(
                settings.playerControlHandedness,
              ),
            ),
          ),
          const SettingsSectionLabel('Distribución'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Wrap(
              spacing: Tokens.space2,
              runSpacing: Tokens.space2,
              children: [
                for (final option in PlayerControlPreset.values.where(
                  (value) => value != PlayerControlPreset.custom,
                ))
                  ChoiceChip(
                    label: Text(option.label),
                    selected: preset == option,
                    onSelected: (_) => mutation.save(
                      AppSettingsCompanion(
                        playerControlPreset: Value(option.id),
                        playerControlLayoutJson: Value(
                          PlayerControlLayout.forPreset(option).toJsonString(),
                        ),
                      ),
                    ),
                  ),
                if (preset == PlayerControlPreset.custom)
                  const Chip(
                    avatar: Icon(Icons.tune_rounded, size: 17),
                    label: Text('Personalizado'),
                  ),
              ],
            ),
          ),
          if (preset == PlayerControlPreset.oneHanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.gutter,
                Tokens.space3,
                Tokens.gutter,
                0,
              ),
              child: SegmentedButton<ControlHandedness>(
                segments: const [
                  ButtonSegment(
                    value: ControlHandedness.left,
                    icon: Icon(Icons.align_horizontal_left_rounded),
                    label: Text('Izquierda'),
                  ),
                  ButtonSegment(
                    value: ControlHandedness.right,
                    icon: Icon(Icons.align_horizontal_right_rounded),
                    label: Text('Derecha'),
                  ),
                ],
                selected: {
                  ControlHandedness.byId(settings.playerControlHandedness),
                },
                onSelectionChanged: (selection) => mutation.save(
                  AppSettingsCompanion(
                    playerControlHandedness: Value(selection.first.id),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space3,
              Tokens.gutter,
              0,
            ),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/settings/controls/layout'),
              icon: const Icon(Icons.drag_indicator_rounded),
              label: const Text('Editar controles visibles y orden'),
            ),
          ),
          const SettingsSectionLabel('Gestos'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.touch_app_rounded),
                title: const Text('Doble toque para reproducir o pausar'),
                value: settings.playerGestureDoubleTap,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureDoubleTap: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe_rounded),
                title: const Text('Deslizar para cambiar de canción'),
                subtitle: const Text(
                  'Izquierda: siguiente · derecha: anterior',
                ),
                value: settings.playerGestureSwipeTrack,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureSwipeTrack: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Deslizar para ajustar volumen'),
                subtitle: const Text(
                  'Vertical sobre la portada; en pantalla completa, sobre el '
                  'lado derecho.',
                ),
                value: settings.playerGestureSwipeVolume,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureSwipeVolume: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.keyboard_arrow_down_rounded),
                title: const Text('Deslizar abajo para cerrar'),
                value: settings.playerGestureSwipeDismiss,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureSwipeDismiss: Value(value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.space4),
          const SettingsInfoPanel(
            icon: Icons.favorite_border_rounded,
            title: 'Favorito va junto al título',
            message:
                'Es una propiedad de la canción, así que se muestra fijo a la '
                'derecha de su información y no como un control movible.',
          ),
        ],
      ),
    );
  }
}
