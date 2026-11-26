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
              // Dos grupos: lo que cambia cómo se ve, y todo lo demás. Cada
              // destino responde a una intención distinta del usuario, para
              // que sepa dónde buscar sin conocer la estructura interna.
              const SettingsSectionLabel('Personalización'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SettingsFeatureCard(
                        icon: Icons.palette_outlined,
                        title: 'Apariencia',
                        subtitle: '${identity.name} · ${accent.name}',
                        warm: true,
                        onTap: () => context.push('/settings/appearance'),
                      ),
                    ),
                    const SizedBox(width: Tokens.space3),
                    Expanded(
                      child: SettingsFeatureCard(
                        icon: Icons.smart_display_outlined,
                        title: 'Reproductor',
                        subtitle: 'Escena, carátula, fondo y visualizador',
                        onTap: () => context.push('/settings/player'),
                      ),
                    ),
                  ],
                ),
              ),
              const SettingsSectionLabel('Configuración'),
              SettingsGroup(
                children: [
                  SettingsNavigationRow(
                    icon: Icons.tune_rounded,
                    title: 'Controles y gestos',
                    subtitle:
                        '${preset.label} · gestos ${_gestureSummary(settings)}',
                    onTap: () => context.push('/settings/controls'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.multitrack_audio_rounded,
                    title: 'Reproducción y audio',
                    subtitle:
                        'Reproducción, ecualizador, procesamiento y salida.',
                    onTap: () => context.push('/settings/playback'),
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
                    subtitle: 'Red, radio, enlaces y contenido descargado.',
                    onTap: () => context.push('/settings/sources'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.groups_rounded,
                    title: 'Comunidad',
                    subtitle: 'Tu usuario y tus amigos.',
                    onTap: () => context.push('/community'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.widgets_outlined,
                    title: 'Widget de inicio',
                    subtitle: settings.widgetEnabled
                        ? 'Activo · diseño, contenido y comportamiento'
                        : 'Desactivado',
                    onTap: () => context.push('/settings/widget'),
                  ),
                  SettingsNavigationRow(
                    icon: Icons.settings_outlined,
                    title: 'Sistema',
                    subtitle: 'Dispositivos, datos, diagnóstico y acerca de.',
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

/// Índice del buscador. Incluye subopciones, no solo destinos: el usuario
/// busca «crossfade» o «auriculares», no el nombre de la pantalla que los
/// contiene.
const _settingsDestinations = <_SettingsDestination>[
  _SettingsDestination(
    title: 'Apariencia',
    subtitle: 'Tema, superficies, tipografía, densidad y énfasis',
    route: '/settings/appearance',
    icon: Icons.palette_outlined,
    keywords: [
      'tema',
      'acento',
      'color',
      'nebula',
      'amoled',
      'paper',
      'claro',
      'oscuro',
      'tipografía',
      'densidad',
      'superficies',
      'glass',
    ],
  ),
  _SettingsDestination(
    title: 'Reproductor',
    subtitle: 'Escena, carátula, fondo, densidad y visualizador',
    route: '/settings/player',
    icon: Icons.smart_display_outlined,
    keywords: [
      'portada',
      'letras',
      'fondo',
      'video',
      'escenario',
      'relación de aspecto',
      'densidad',
    ],
  ),
  _SettingsDestination(
    title: 'Visualizador',
    subtitle: 'Estilo, color reactivo y rendimiento',
    route: '/settings/player/visualizer',
    icon: Icons.graphic_eq_rounded,
    keywords: ['visualizador', 'espectro', 'barras', 'eco', 'ultra', 'calidad'],
  ),
  _SettingsDestination(
    title: 'Color reactivo del visualizador',
    subtitle: 'Mapa de colores por intensidad y modo de aplicación',
    route: '/settings/player/visualizer/colors',
    icon: Icons.gradient_rounded,
    keywords: ['color', 'mapa', 'paleta', 'por fila', 'por columna', 'pico'],
  ),
  _SettingsDestination(
    title: 'Movimiento y efectos',
    subtitle: 'Animaciones, intensidad, ritmo y partículas',
    route: '/settings/appearance?tab=motion',
    icon: Icons.animation_rounded,
    keywords: ['calmada', 'enérgica', 'reducir movimiento', 'partículas'],
  ),
  _SettingsDestination(
    title: 'Controles y gestos',
    subtitle: 'Botones, distribución, mano dominante e interacción',
    route: '/settings/controls',
    icon: Icons.tune_rounded,
    keywords: ['botones', 'gestos', 'deslizar', 'doble toque', 'una mano'],
  ),
  _SettingsDestination(
    title: 'Favorito',
    subtitle: 'Se muestra fijo junto a la información de la canción',
    route: '/settings/controls',
    icon: Icons.favorite_border_rounded,
    keywords: ['favorito', 'corazón', 'me gusta'],
  ),
  _SettingsDestination(
    title: 'Reproducción y audio',
    subtitle: 'Crossfade, gapless, ecualizador, modo directo y offload',
    route: '/settings/playback',
    icon: Icons.multitrack_audio_rounded,
    keywords: [
      'crossfade',
      'gapless',
      'fade',
      'restaurar cola',
      'ecualizador',
      'offload',
      'modo directo',
      'velocidad',
      'tono',
    ],
  ),
  _SettingsDestination(
    title: 'Biblioteca',
    subtitle: 'Escaneo, carpetas incluidas y excluidas',
    route: '/settings/library',
    icon: Icons.library_music_outlined,
    keywords: ['escanear', 'carpetas', 'excluir'],
  ),
  _SettingsDestination(
    title: 'Completar con internet',
    subtitle: 'Busca género, artista y compositor en MusicBrainz',
    route: '/settings/library/metadata-lookup',
    icon: Icons.travel_explore_rounded,
    keywords: ['metadata', 'género', 'compositor', 'musicbrainz', 'etiquetas'],
  ),
  _SettingsDestination(
    title: 'Fuentes y descargas',
    subtitle: 'SMB, WebDAV, radio y búsqueda en internet',
    route: '/settings/sources',
    icon: Icons.cloud_outlined,
    keywords: ['smb', 'webdav', 'radio', 'descargar'],
  ),
  _SettingsDestination(
    title: 'Widget de inicio',
    subtitle: 'Diseño, contenido y comportamiento',
    route: '/settings/widget',
    icon: Icons.widgets_outlined,
    keywords: ['widget', 'pantalla de inicio', 'tamaño', 'opacidad'],
  ),
  _SettingsDestination(
    title: 'Dispositivos e integración',
    subtitle: 'Auriculares, Bluetooth, bloqueo y Android Auto',
    route: '/settings/system/devices',
    icon: Icons.devices_other_rounded,
    keywords: [
      'auriculares',
      'audífonos',
      'bluetooth',
      'android auto',
      'pantalla de bloqueo',
    ],
  ),
  _SettingsDestination(
    title: 'Datos y archivos',
    subtitle: 'Metadatos, portadas, escritura segura y privacidad',
    route: '/settings/system/data',
    icon: Icons.folder_shared_outlined,
    keywords: ['metadatos', 'portada', 'privacidad', 'm3u', 'exportar'],
  ),
  _SettingsDestination(
    title: 'Registro de reproducción',
    subtitle: 'Diagnóstico de canciones que fallaron',
    route: '/settings/playback-failure-log',
    icon: Icons.bug_report_outlined,
    keywords: ['diagnóstico', 'errores', 'fallos'],
  ),
  _SettingsDestination(
    title: 'Acerca de',
    subtitle: 'Versión e información técnica de NuvTune',
    route: '/settings/system/about',
    icon: Icons.info_outline_rounded,
    keywords: ['versión', 'acerca'],
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
