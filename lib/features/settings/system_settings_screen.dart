import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

/// Sistema: todo lo que toca el sistema operativo, los archivos o el
/// diagnóstico. Sustituye a «Sistema y ayuda» y a «Datos y privacidad», que
/// eran sobre todo texto explicativo y dejaban las preferencias reales
/// repartidas en otras pantallas.
class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sistema')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: Icons.devices_other_rounded,
              title: 'Dispositivos e integración',
              subtitle: 'Auriculares, Bluetooth, bloqueo y Android Auto.',
              onTap: () => context.push('/settings/system/devices'),
            ),
            SettingsNavigationRow(
              icon: Icons.folder_shared_outlined,
              title: 'Datos y archivos',
              subtitle: 'Metadatos, escritura segura y privacidad.',
              onTap: () => context.push('/settings/system/data'),
            ),
            SettingsNavigationRow(
              icon: Icons.bug_report_outlined,
              title: 'Diagnóstico',
              subtitle: 'Registro de reproducción y fallos detectados.',
              onTap: () => context.push('/settings/system/diagnostics'),
            ),
            SettingsNavigationRow(
              icon: Icons.info_outline_rounded,
              title: 'Acerca de',
              subtitle: 'Versión e información técnica de NuvTune.',
              onTap: () => context.push('/settings/system/about'),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Comportamiento con auriculares e integraciones del sistema.
///
/// Las dos preferencias siguen guardándose en `widgetPauseOnDisconnect` y
/// `widgetResumeOnConnect`: el nombre viene de cuando vivían en el widget y no
/// se renombra aquí para no tocar persistencia en esta fase.
class DevicesSettingsScreen extends ConsumerWidget {
  const DevicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mutation = ref.read(settingsMutationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivos e integración')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          const SettingsSectionLabel('Auriculares'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.headset_off_outlined),
                title: const Text('Pausar al desconectar los audífonos'),
                value: settings.widgetPauseOnDisconnect,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(widgetPauseOnDisconnect: Value(value)),
                  sync: const {SettingsSyncTarget.deviceControls},
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.headset_rounded),
                title: const Text('Reanudar al volver a conectarlos'),
                subtitle: const Text(
                  'Solo si la desconexión provocó la pausa.',
                ),
                value: settings.widgetResumeOnConnect,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(widgetResumeOnConnect: Value(value)),
                  sync: const {SettingsSyncTarget.deviceControls},
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Integraciones'),
          const SettingsInfoPanel(
            icon: Icons.bluetooth_rounded,
            title: 'Bluetooth, cable y pantalla de bloqueo',
            message:
                'Los controles estándar funcionan desde la notificación, los '
                'botones físicos y los mandos Bluetooth.',
          ),
          const SizedBox(height: Tokens.space3),
          const SettingsInfoPanel(
            icon: Icons.directions_car_rounded,
            title: 'Android Auto',
            message: AppStrings.androidAutoNote,
          ),
        ],
      ),
    );
  }
}

class DataFilesSettingsScreen extends ConsumerWidget {
  const DataFilesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Datos y archivos')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          const SettingsSectionLabel('Metadatos'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.image_outlined),
                title: const Text(AppStrings.coverEmbedInFile),
                subtitle: const Text(
                  'Desactivado guarda la portada solo dentro de NuvTune.',
                ),
                value: settings.embedCoverInFile,
                onChanged: (value) => ref
                    .read(settingsMutationProvider.notifier)
                    .save(AppSettingsCompanion(embedCoverInFile: Value(value))),
              ),
            ],
          ),
          const SettingsSectionLabel('Protección'),
          const SettingsInfoPanel(
            icon: Icons.shield_outlined,
            title: 'Escritura segura',
            message:
                'Las etiquetas se escriben en una copia temporal, se verifica '
                'el archivo y solo entonces se sustituye el original.',
          ),
          const SizedBox(height: Tokens.space3),
          const SettingsInfoPanel(
            icon: Icons.file_download_outlined,
            title: 'Exportar listas como M3U',
            message:
                'Cada lista se exporta desde su propio menú mediante el '
                'selector de archivos del sistema.',
          ),
          const SizedBox(height: Tokens.space3),
          const SettingsInfoPanel(
            icon: Icons.lock_outline_rounded,
            title: 'Funcionamiento local',
            message: AppStrings.privacyNote,
          ),
        ],
      ),
    );
  }
}

class DiagnosticsSettingsScreen extends StatelessWidget {
  const DiagnosticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnóstico')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: Icons.bug_report_outlined,
              title: 'Registro de reproducción',
              subtitle: 'Canciones que fallaron y la causa detectada.',
              onTap: () => context.push('/settings/playback-failure-log'),
            ),
            SettingsNavigationRow(
              icon: Icons.smart_display_outlined,
              title: 'Selección de video',
              subtitle: 'Qué candidatos hubo y por qué ganó el elegido.',
              onTap: () => context.push('/settings/video-match-log'),
            ),
          ],
        ),
      ],
    ),
  );
}

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Acerca de')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: const [
        SettingsInfoPanel(
          icon: Icons.info_outline_rounded,
          title: AppStrings.appName,
          message:
              'Reproductor local con Media3, ecualizador propio y edición real '
              'de etiquetas con TagLib.',
        ),
      ],
    ),
  );
}
