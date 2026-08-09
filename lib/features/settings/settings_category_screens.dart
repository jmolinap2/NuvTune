import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

class AudioQualitySettingsScreen extends ConsumerWidget {
  const AudioQualitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final output = ref.watch(audioOutputProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mutation = ref.read(settingsMutationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Audio y calidad')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          const SettingsSectionLabel('Procesamiento'),
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
                'NuvTune adapta los perfiles y la compatibilidad a la salida detectada.',
          ),
        ],
      ),
    );
  }
}

class LibrarySettingsScreen extends ConsumerWidget {
  const LibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final library = ref.watch(libraryProvider);
    final excluded = ref.watch(excludedFoldersProvider).valueOrNull ?? const [];
    final sourceFolders =
        ref.watch(sourceFoldersProvider).valueOrNull ?? const [];
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mutation = ref.read(settingsMutationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          const SettingsSectionLabel('Escaneo'),
          SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.library_music_outlined),
                title: const Text(AppStrings.rescanLibrary),
                subtitle: Text(
                  library.isScanning
                      ? AppStrings.scanning
                      : settings.lastScanAt == null
                      ? '${Formatters.trackCount(library.songs.length)} en la biblioteca'
                      : '${Formatters.trackCount(library.songs.length)} · último escaneo ${Formatters.dateTime(settings.lastScanAt!)}',
                ),
                trailing: library.isScanning
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: library.isScanning
                    ? null
                    : () =>
                          ref.read(libraryProvider.notifier).scan(force: true),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.autorenew_rounded),
                title: const Text('Escanear al abrir la aplicación'),
                value: settings.scanOnStart,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(scanOnStart: Value(value)),
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Carpetas'),
          SettingsGroup(
            children: [
              SettingsNavigationRow(
                icon: Icons.folder_off_outlined,
                title: AppStrings.settingsExcludedFolders,
                subtitle: excluded.isEmpty
                    ? 'Ninguna carpeta excluida'
                    : '${excluded.length} excluidas',
                onTap: () => context.push('/settings/excluded-folders'),
              ),
              SettingsNavigationRow(
                icon: Icons.create_new_folder_outlined,
                title: AppStrings.settingsSourceFolders,
                subtitle: sourceFolders.isEmpty
                    ? 'Almacenamiento interno y tarjeta SD'
                    : '${sourceFolders.length} carpetas concedidas',
                onTap: () => context.push('/settings/source-folders'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SourcesSettingsScreen extends StatelessWidget {
  const SourcesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fuentes y descargas')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        const SettingsSectionLabel('Contenido'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: Icons.cloud_outlined,
              title: AppStrings.remoteSources,
              subtitle: 'SMB, WebDAV, enlaces directos y radio.',
              onTap: () => context.push('/remote-sources'),
            ),
            SettingsNavigationRow(
              icon: Icons.download_outlined,
              title: 'Descargas de internet',
              subtitle: 'Busca canciones y guárdalas para oírlas sin conexión.',
              onTap: () => context.push('/downloads'),
            ),
          ],
        ),
      ],
    ),
  );
}

class DataPrivacySettingsScreen extends ConsumerWidget {
  const DataPrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Datos y privacidad')),
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
                'Las etiquetas se escriben en una copia temporal, se verifica el archivo y solo entonces se sustituye el original.',
          ),
          const SizedBox(height: Tokens.space3),
          const SettingsInfoPanel(
            icon: Icons.file_download_outlined,
            title: 'Exportar listas como M3U',
            message:
                'Cada lista se exporta desde su propio menú mediante el selector de archivos del sistema.',
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

class SystemHelpSettingsScreen extends StatelessWidget {
  const SystemHelpSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sistema y ayuda')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        const SettingsSectionLabel('Diagnóstico'),
        SettingsGroup(
          children: [
            SettingsNavigationRow(
              icon: Icons.bug_report_outlined,
              title: 'Registro de reproducción',
              subtitle: 'Canciones que fallaron y la causa detectada.',
              onTap: () => context.push('/settings/playback-failure-log'),
            ),
          ],
        ),
        const SettingsSectionLabel('Compatibilidad'),
        const SettingsInfoPanel(
          icon: Icons.bluetooth_rounded,
          title: 'Bluetooth, cable y pantalla de bloqueo',
          message:
              'Los controles estándar funcionan desde la notificación, botones físicos y mandos Bluetooth.',
        ),
        const SizedBox(height: Tokens.space3),
        const SettingsInfoPanel(
          icon: Icons.directions_car_rounded,
          title: 'Android Auto',
          message: AppStrings.androidAutoNote,
        ),
        const SettingsSectionLabel('Acerca de'),
        const SettingsInfoPanel(
          icon: Icons.info_outline_rounded,
          title: AppStrings.appName,
          message:
              'Reproductor local con Media3, ecualizador propio y edición real de etiquetas con TagLib.',
        ),
      ],
    ),
  );
}
