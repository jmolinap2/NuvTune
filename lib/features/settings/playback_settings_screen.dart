import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/settings/control_screen.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

/// Reproducción y audio: las reglas del motor y el procesamiento del sonido.
///
/// Reúne lo que antes estaba repartido entre «Control» (restaurar cola,
/// gapless, crossfade, fade) y «Audio y calidad». Ninguna de esas opciones es
/// un control: son decisiones sobre cómo suena la música.
class PlaybackAudioSettingsScreen extends ConsumerWidget {
  const PlaybackAudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final output = ref.watch(audioOutputProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mutation = ref.read(settingsMutationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reproducción y audio')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          const SettingsSectionLabel('Reproducción'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.restore_rounded),
                title: const Text(AppStrings.restoreQueue),
                value: settings.restoreQueueOnStart,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(restoreQueueOnStart: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.link_rounded),
                title: const Text(AppStrings.gapless),
                subtitle: const Text(
                  'Elimina el silencio entre pistas compatibles.',
                ),
                value: settings.gaplessEnabled,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(gaplessEnabled: Value(value)),
                  sync: const {SettingsSyncTarget.audio},
                ),
              ),
              CrossfadeSetting(seconds: settings.crossfadeSeconds),
              SwitchListTile(
                secondary: const Icon(Icons.blur_on_rounded),
                title: const Text(AppStrings.fadeOnPause),
                value: settings.fadeOnPause,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(fadeOnPause: Value(value)),
                  sync: const {SettingsSyncTarget.audio},
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Audio'),
          SettingsGroup(
            children: [
              SettingsNavigationRow(
                icon: Icons.graphic_eq_rounded,
                title: AppStrings.equalizer,
                subtitle: 'Bandas, ganancia, balance, velocidad y tono.',
                onTap: () => context.push('/equalizer'),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.straighten_rounded),
                title: const Text(AppStrings.directMode),
                subtitle: const Text(AppStrings.directModeNote),
                value: settings.directMode,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(directMode: Value(value)),
                  sync: const {SettingsSyncTarget.audio},
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.battery_saver_rounded),
                title: const Text(AppStrings.allowOffload),
                subtitle: const Text(
                  'Ahorra batería cuando no hay procesamiento activo.',
                ),
                value: settings.allowOffload,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(allowOffload: Value(value)),
                  sync: const {SettingsSyncTarget.audio},
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Salida actual'),
          SettingsInfoPanel(
            icon: Icons.speaker_rounded,
            title: output?.deviceName ?? 'Altavoz del teléfono',
            message:
                'NuvTune adapta los perfiles y la compatibilidad a la salida '
                'detectada.',
          ),
          const SizedBox(height: Tokens.space3),
          const SettingsInfoPanel(
            icon: Icons.speed_rounded,
            title: 'Velocidad y tono',
            message:
                'Se ajustan desde el ecualizador mientras suena la música y se '
                'recuerdan, pero no son una preferencia global.',
          ),
        ],
      ),
    );
  }
}
