import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/app_theme_identity.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/library/library_controller.dart';
import 'package:nuvtune/features/settings/auris_guide.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
import 'package:nuvtune/features/settings/settings_components.dart';

/// Panel principal de Ajustes. Las opciones editables viven en pantallas
/// temáticas para que información, acciones y preferencias no se mezclen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final library = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navSettings),
        actions: [
          IconButton(
            tooltip: 'Buscar en ajustes',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch<void>(
              context: context,
              delegate: _SettingsSearchDelegate(),
            ),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (settings) {
          final preset = PlayerControlPreset.byId(settings.playerControlPreset);
          final accent = AccentIdentity.byId(settings.accentId);
          final identity = AppThemeIdentity.byId(settings.themeIdentity);

          return ListView(
            padding: const EdgeInsets.only(bottom: Tokens.space6),
            children: [
              const AurisGuide(),
              const SettingsSectionLabel('Tu experiencia'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SettingsFeatureCard(
                        icon: Icons.tune_rounded,
                        title: 'Control',
                        subtitle:
                            '${preset.label} · gestos ${_gestureSummary(settings)}',
                        onTap: () => context.push('/settings/control'),
                      ),
                    ),
                    const SizedBox(width: Tokens.space3),
                    Expanded(
                      child: SettingsFeatureCard(
                        icon: Icons.palette_outlined,
                        title: 'Apariencia',
                        subtitle: '${identity.name} · ${accent.name}',
                        warm: true,
                        onTap: () => context.push('/settings/theme'),
                      ),
                    ),
                  ],
                ),
              ),
              const SettingsSectionLabel('Configuración'),
              SettingsGroup(
                children: [
                  SettingsNavigationRow(
                    icon: Icons.multitrack_audio_rounded,
                    title: 'Audio y calidad',
                    subtitle: 'Ecualizador, salida y procesamiento.',
                    onTap: () => context.push('/settings/audio'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.library_music_outlined,
                    title: 'Biblioteca',
                    subtitle: library.isScanning
                        ? 'Escaneando música…'
                        : '${library.songs.length} canciones · carpetas y escaneo',
                    onTap: () => context.push('/settings/library'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.cloud_outlined,
                    title: 'Fuentes y descargas',
                    subtitle: 'Local, SMB, WebDAV, radio e internet.',
                    onTap: () => context.push('/settings/sources'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Datos y privacidad',
                    subtitle: 'Metadatos, respaldo y protección de archivos.',
                    onTap: () => context.push('/settings/data'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Sistema y ayuda',
                    subtitle: 'Diagnóstico, compatibilidad y acerca de.',
                    onTap: () => context.push('/settings/system'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _gestureSummary(AppSetting settings) {
    final count = [
      settings.playerGestureDoubleTap,
      settings.playerGestureSwipeTrack,
      settings.playerGestureSwipeVolume,
      settings.playerGestureSwipeDismiss,
    ].where((enabled) => enabled).length;
    return count == 0 ? 'desactivados' : '$count activos';
  }
}

class _SettingsDestination {
  const _SettingsDestination({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.keywords = const [],
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final List<String> keywords;

  bool matches(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return true;
    return [
      title,
      subtitle,
      ...keywords,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

const _settingsDestinations = <_SettingsDestination>[
  _SettingsDestination(
    title: 'Control',
    subtitle: 'Botones, gestos, reproducción y auriculares',
    route: '/settings/control',
    icon: Icons.tune_rounded,
    keywords: ['crossfade', 'gapless', 'bluetooth', 'android auto'],
  ),
  _SettingsDestination(
    title: 'Apariencia de la app',
    subtitle: 'Tema, superficies, tipografía, densidad y énfasis',
    route: '/settings/theme',
    icon: Icons.palette_outlined,
    keywords: [
      'tema',
      'acento',
      'nebula',
      'amoled',
      'paper',
      'claro',
      'oscuro',
      'tipografía',
      'densidad',
    ],
  ),
  _SettingsDestination(
    title: 'Apariencia del reproductor',
    subtitle: 'Escenario, visualizador, video y relación de aspecto',
    route: '/settings/appearance?tab=player',
    icon: Icons.smart_display_outlined,
    keywords: ['portada', 'letras', 'fondo'],
  ),
  _SettingsDestination(
    title: 'Movimiento y efectos',
    subtitle: 'Animaciones, intensidad, ritmo, partículas y color',
    route: '/settings/appearance?tab=motion',
    icon: Icons.animation_rounded,
    keywords: ['calmada', 'enérgica', 'reducir movimiento', 'visualizador'],
  ),
  _SettingsDestination(
    title: 'Widget de inicio',
    subtitle: 'Estilo, tamaño, color y contenido',
    route: '/settings/appearance?tab=widget',
    icon: Icons.widgets_outlined,
  ),
  _SettingsDestination(
    title: 'Audio y calidad',
    subtitle: 'Ecualizador, salida, modo directo y offload',
    route: '/settings/audio',
    icon: Icons.multitrack_audio_rounded,
  ),
  _SettingsDestination(
    title: 'Biblioteca',
    subtitle: 'Escaneo, carpetas incluidas y excluidas',
    route: '/settings/library',
    icon: Icons.library_music_outlined,
  ),
  _SettingsDestination(
    title: 'Fuentes y descargas',
    subtitle: 'SMB, WebDAV, radio y búsqueda en internet',
    route: '/settings/sources',
    icon: Icons.cloud_outlined,
  ),
  _SettingsDestination(
    title: 'Datos y privacidad',
    subtitle: 'Metadatos, portadas, respaldo y escritura segura',
    route: '/settings/data',
    icon: Icons.admin_panel_settings_outlined,
  ),
  _SettingsDestination(
    title: 'Registro de reproducción',
    subtitle: 'Diagnóstico de canciones que fallaron',
    route: '/settings/playback-failure-log',
    icon: Icons.bug_report_outlined,
  ),
  _SettingsDestination(
    title: 'Sistema y ayuda',
    subtitle: 'Compatibilidad, Android Auto y acerca de',
    route: '/settings/system',
    icon: Icons.help_outline_rounded,
  ),
];

class _SettingsSearchDelegate extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'Buscar ajustes';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Limpiar',
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: 'Volver',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final results = _settingsDestinations
        .where((destination) => destination.matches(query))
        .toList();
    if (results.isEmpty) {
      return const Center(child: Text('No se encontraron ajustes.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final destination = results[index];
        return ListTile(
          leading: Icon(destination.icon),
          title: Text(destination.title),
          subtitle: Text(destination.subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            close(context, null);
            context.push(destination.route);
          },
        );
      },
    );
  }
}
