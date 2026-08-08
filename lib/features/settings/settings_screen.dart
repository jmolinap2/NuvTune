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
import 'package:nuvtune/features/player/player_controller.dart';

/// Pantalla de ajustes con las secciones del requerimiento seccion 11.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final library = ref.watch(libraryProvider);
    final excluded = ref.watch(excludedFoldersProvider).valueOrNull ?? const [];
    final sourceFolders = ref.watch(sourceFoldersProvider).valueOrNull ?? const [];
    final output = ref.watch(audioOutputProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navSettings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (settings) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // -- Biblioteca ---------------------------------------------------
            _Section(title: AppStrings.settingsLibrary),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: const Text(AppStrings.rescanLibrary),
              subtitle: Text(
                library.isScanning
                    ? AppStrings.scanning
                    : settings.lastScanAt == null
                        ? '${Formatters.trackCount(library.songs.length)} en la biblioteca'
                        : '${Formatters.trackCount(library.songs.length)} · '
                            'último escaneo ${Formatters.dateTime(settings.lastScanAt!)}',
              ),
              trailing: library.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: library.isScanning
                  ? null
                  : () => ref.read(libraryProvider.notifier).scan(force: true),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.autorenew_rounded),
              title: const Text('Escanear al abrir la aplicación'),
              value: settings.scanOnStart,
              onChanged: (value) => _update(
                ref,
                AppSettingsCompanion(scanOnStart: Value(value)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text(AppStrings.settingsExcludedFolders),
              subtitle: Text(
                excluded.isEmpty
                    ? 'Ninguna carpeta excluida'
                    : '${excluded.length} excluidas',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/excluded-folders'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text(AppStrings.settingsSourceFolders),
              subtitle: Text(
                sourceFolders.isEmpty
                    ? 'Solo almacenamiento interno y tarjeta SD'
                    : '${sourceFolders.length} carpetas concedidas',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/source-folders'),
            ),

            // -- Apariencia ---------------------------------------------------
            _Section(title: AppStrings.settingsAppearance),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Color y apariencia'),
              subtitle: Text(
                '${AccentIdentity.byId(settings.accentId).name} · '
                '${BackgroundDepth.byId(settings.backgroundDepth).label}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/appearance'),
            ),

            // -- Reproduccion -------------------------------------------------
            _Section(title: AppStrings.settingsPlayback),
            SwitchListTile(
              secondary: const Icon(Icons.restore_rounded),
              title: const Text(AppStrings.restoreQueue),
              value: settings.restoreQueueOnStart,
              onChanged: (value) => _update(
                ref,
                AppSettingsCompanion(restoreQueueOnStart: Value(value)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.link_rounded),
              title: const Text(AppStrings.gapless),
              subtitle: const Text(
                'Salta el silencio entre pistas compatibles.',
              ),
              value: settings.gaplessEnabled,
              onChanged: (value) => _updateAndPush(
                ref,
                AppSettingsCompanion(gaplessEnabled: Value(value)),
              ),
            ),
            _CrossfadeTile(seconds: settings.crossfadeSeconds),
            SwitchListTile(
              secondary: const Icon(Icons.blur_on_rounded),
              title: const Text(AppStrings.fadeOnPause),
              value: settings.fadeOnPause,
              onChanged: (value) => _updateAndPush(
                ref,
                AppSettingsCompanion(fadeOnPause: Value(value)),
              ),
            ),

            // -- Calidad ------------------------------------------------------
            _Section(title: AppStrings.settingsQuality),
            ListTile(
              leading: const Icon(Icons.graphic_eq_rounded),
              title: const Text(AppStrings.equalizer),
              subtitle: const Text(
                'Bandas, ganancia previa, balance, velocidad y tono.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/equalizer'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.straighten_rounded),
              title: const Text(AppStrings.directMode),
              subtitle: const Text(AppStrings.directModeNote),
              value: settings.directMode,
              onChanged: (value) => _updateAndPush(
                ref,
                AppSettingsCompanion(directMode: Value(value)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.battery_saver_rounded),
              title: const Text(AppStrings.allowOffload),
              subtitle: const Text(
                'Ahorra batería cuando no hay procesamiento activo.',
              ),
              value: settings.allowOffload,
              onChanged: (value) => _updateAndPush(
                ref,
                AppSettingsCompanion(allowOffload: Value(value)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.speaker_rounded),
              title: const Text(AppStrings.outputDevice),
              subtitle: Text(output?.deviceName ?? 'Altavoz del teléfono'),
            ),

            // -- Fuentes remotas ----------------------------------------------
            _Section(title: AppStrings.remoteSources),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text(AppStrings.remoteSources),
              subtitle: const Text(
                'Servidores SMB y WebDAV, enlaces directos y emisoras de radio.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/remote-sources'),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Descargas de internet'),
              subtitle: const Text(
                'Busca y descarga canciones para escucharlas sin conexión.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/downloads'),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Registro de reproducción'),
              subtitle: const Text(
                'Qué canciones fallaron al escanear o reproducir, y por qué.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/playback-failure-log'),
            ),

            // -- Bluetooth y Android Auto -------------------------------------
            _Section(title: AppStrings.settingsBluetooth),
            const ListTile(
              leading: Icon(Icons.bluetooth_rounded),
              title: Text('Controles de Bluetooth y auriculares'),
              subtitle: Text(
                'Reproducir, pausar, anterior, siguiente, avanzar, retroceder y '
                'favorito funcionan desde la notificacion, la pantalla de '
                'bloqueo, los botones del cable y los mandos Bluetooth.',
              ),
            ),
            _Section(title: AppStrings.settingsWidgets),
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: const Text('Widget de la pantalla de inicio'),
              subtitle: Text(
                settings.widgetEnabled
                    ? 'Estilo, tamaño, colores e información que muestra.'
                    : 'Desactivado',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/widgets'),
            ),

            _Section(title: AppStrings.settingsAndroidAuto),
            const ListTile(
              leading: Icon(Icons.directions_car_rounded),
              title: Text('Android Auto'),
              subtitle: Text(AppStrings.androidAutoNote),
            ),

            // -- Metadatos ----------------------------------------------------
            _Section(title: AppStrings.settingsMetadata),
            SwitchListTile(
              secondary: const Icon(Icons.image_outlined),
              title: const Text(AppStrings.coverEmbedInFile),
              subtitle: const Text(
                'Si se desactiva, la portada nueva se guarda solo dentro de '
                'NuvTune y el archivo no se modifica.',
              ),
              value: settings.embedCoverInFile,
              onChanged: (value) => _update(
                ref,
                AppSettingsCompanion(embedCoverInFile: Value(value)),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Escritura segura'),
              subtitle: Text(
                'Los cambios de etiquetas se escriben sobre una copia temporal, '
                'se verifica que el archivo siga siendo válido y solo entonces '
                'se sustituye el original. Si algo falla, se restaura.',
              ),
            ),

            // -- Copias de seguridad ------------------------------------------
            _Section(title: AppStrings.settingsBackup),
            const ListTile(
              leading: Icon(Icons.file_download_outlined),
              title: Text('Exportar listas como M3U'),
              subtitle: Text(
                'Cada lista se exporta desde su propio menú, con el selector de '
                'archivos del sistema.',
              ),
            ),

            // -- Privacidad y acerca de ---------------------------------------
            _Section(title: AppStrings.settingsPrivacy),
            const ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Funcionamiento local'),
              subtitle: Text(AppStrings.privacyNote),
            ),
            _Section(title: AppStrings.settingsAbout),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text(AppStrings.appName),
              subtitle: Text(
                'Reproductor de música local con motor nativo Media3, '
                'ecualizador propio de 10, 15 o 20 bandas y edición real de '
                'etiquetas con TagLib.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update(WidgetRef ref, AppSettingsCompanion companion) =>
      ref.read(settingsRepositoryProvider).update(companion);

  /// Ajustes que el motor necesita conocer de inmediato.
  Future<void> _updateAndPush(
    WidgetRef ref,
    AppSettingsCompanion companion,
  ) async {
    await _update(ref, companion);
    await ref.read(playbackProvider.notifier).pushAudioSettings();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CrossfadeTile extends ConsumerStatefulWidget {
  const _CrossfadeTile({required this.seconds});

  final int seconds;

  @override
  ConsumerState<_CrossfadeTile> createState() => _CrossfadeTileState();
}

class _CrossfadeTileState extends ConsumerState<_CrossfadeTile> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.seconds.toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.multitrack_audio_rounded),
              const SizedBox(width: 16),
              const Expanded(child: Text(AppStrings.crossfade)),
              Text(
                value < 1 ? 'Desactivado' : '${value.round()} s',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Slider(
            // El requerimiento seccion 5.5 fija el rango entre 0 y 12 segundos.
            value: value.clamp(0, 12),
            max: 12,
            divisions: 12,
            onChanged: (next) => setState(() => _dragValue = next),
            onChangeEnd: (next) async {
              setState(() => _dragValue = null);
              await ref.read(settingsRepositoryProvider).update(
                    AppSettingsCompanion(crossfadeSeconds: Value(next.round())),
                  );
              await ref.read(playbackProvider.notifier).pushAudioSettings();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 8),
            child: Text(
              'En cero, la reproducción usa un solo motor y mantiene el modo '
              'sin espacios nativo.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
