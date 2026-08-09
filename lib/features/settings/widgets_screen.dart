import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';
import 'package:nuvtune/shared/widgets/glass.dart';

/// Número de widgets ya colocados en la pantalla de inicio.
final placedWidgetsProvider = FutureProvider<int>(
  (ref) => ref.watch(engineProvider).api.countPlacedWidgets(),
);

/// Configuración del widget de inicio (requerimiento sección 9.2).
///
/// Cada cambio se guarda y se publica en el motor de inmediato, de modo que el
/// widget de la pantalla de inicio se repinta sin tener que salir de aquí.
class WidgetsScreen extends StatelessWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.settingsWidgets)),
    body: const WidgetSettingsContent(),
  );
}

/// Panel incrustable de apariencia y contenido del widget.
class WidgetSettingsContent extends ConsumerWidget {
  const WidgetSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final placed = ref.watch(placedWidgetsProvider).valueOrNull ?? 0;
    final style = WidgetStyle.values[settings.widgetStyle];
    final size = WidgetSize.values[settings.widgetSize];

    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.space6),
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.widgets_outlined),
          title: const Text(AppStrings.widgetsEnable),
          subtitle: Text(
            placed == 0
                ? 'Todavía no hay ningún widget en la pantalla de inicio.'
                : placed == 1
                ? 'Hay 1 widget en la pantalla de inicio.'
                : 'Hay $placed widgets en la pantalla de inicio.',
          ),
          value: settings.widgetEnabled,
          onChanged: (value) =>
              _save(ref, AppSettingsCompanion(widgetEnabled: Value(value))),
        ),

        if (settings.widgetEnabled) ...[
          SectionLabel(AppStrings.widgetsPreview),
          _WidgetPreview(settings: settings, style: style, size: size),

          SectionLabel(AppStrings.widgetsStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Row(
              children: [
                for (final option in WidgetStyle.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Tokens.space2),
                      child: _StyleCard(
                        style: option,
                        selected: style == option,
                        onTap: () => _save(
                          ref,
                          AppSettingsCompanion(
                            widgetStyle: Value(option.index),
                            // Cada estilo trae su tema natural; el usuario
                            // puede cambiarlo después.
                            widgetTheme: Value(
                              option == WidgetStyle.ios
                                  ? WidgetTheme.light.index
                                  : WidgetTheme.dark.index,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SectionLabel(AppStrings.widgetsSize),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: SegmentedButton<WidgetSize>(
              segments: const [
                ButtonSegment(value: WidgetSize.compact, label: Text('4x1')),
                ButtonSegment(value: WidgetSize.normal, label: Text('4x2')),
                ButtonSegment(value: WidgetSize.large, label: Text('4x3')),
              ],
              selected: {size},
              onSelectionChanged: (selection) => _save(
                ref,
                AppSettingsCompanion(widgetSize: Value(selection.first.index)),
              ),
            ),
          ),
          const _Note(
            'Es una preferencia: manda el tamaño que le des al widget al '
            'colocarlo, y NuvTune ajusta lo que muestra a lo que quepa.',
          ),

          SectionLabel(AppStrings.widgetsAppearance),
          ListTile(
            leading: const Icon(Icons.contrast_rounded),
            title: const Text('Tema'),
            trailing: DropdownButton<WidgetTheme>(
              value: WidgetTheme.values[settings.widgetTheme],
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: WidgetTheme.light,
                  child: Text('Claro'),
                ),
                DropdownMenuItem(
                  value: WidgetTheme.dark,
                  child: Text('Oscuro'),
                ),
                DropdownMenuItem(
                  value: WidgetTheme.system,
                  child: Text('Según el estilo'),
                ),
              ],
              onChanged: (value) => value == null
                  ? null
                  : _save(
                      ref,
                      AppSettingsCompanion(widgetTheme: Value(value.index)),
                    ),
            ),
          ),
          _AccentRow(selected: settings.widgetAccentColor),
          _OpacitySlider(value: settings.widgetOpacity),

          SectionLabel(AppStrings.widgetsContent),
          _Toggle(
            icon: Icons.image_outlined,
            label: 'Portada del álbum',
            value: settings.widgetShowCover,
            onChanged: (value) =>
                _save(ref, AppSettingsCompanion(widgetShowCover: Value(value))),
          ),
          _Toggle(
            icon: Icons.music_note_rounded,
            label: 'Título de la canción',
            value: settings.widgetShowTitle,
            onChanged: (value) =>
                _save(ref, AppSettingsCompanion(widgetShowTitle: Value(value))),
          ),
          _Toggle(
            icon: Icons.person_outline_rounded,
            label: 'Artista',
            value: settings.widgetShowArtist,
            onChanged: (value) => _save(
              ref,
              AppSettingsCompanion(widgetShowArtist: Value(value)),
            ),
          ),
          _Toggle(
            icon: Icons.skip_next_rounded,
            label: 'Controles de reproducción',
            detail: 'Anterior, reproducir o pausar, siguiente',
            value: settings.widgetShowControls,
            onChanged: (value) => _save(
              ref,
              AppSettingsCompanion(widgetShowControls: Value(value)),
            ),
          ),
          _Toggle(
            icon: Icons.linear_scale_rounded,
            label: 'Barra de progreso',
            detail: 'No cabe en el tamaño 4x1',
            value: settings.widgetShowProgress,
            onChanged: (value) => _save(
              ref,
              AppSettingsCompanion(widgetShowProgress: Value(value)),
            ),
          ),
          _Toggle(
            icon: Icons.timer_outlined,
            label: 'Duración y tiempo transcurrido',
            value: settings.widgetShowDuration,
            onChanged: (value) => _save(
              ref,
              AppSettingsCompanion(widgetShowDuration: Value(value)),
            ),
          ),
          _Toggle(
            icon: Icons.queue_music_rounded,
            label: 'Siguiente en la cola',
            value: settings.widgetShowNextInQueue,
            onChanged: (value) => _save(
              ref,
              AppSettingsCompanion(widgetShowNextInQueue: Value(value)),
            ),
          ),

          SectionLabel(AppStrings.widgetsBehaviour),
          _Toggle(
            icon: Icons.open_in_new_rounded,
            label: 'Abrir el reproductor al tocar el widget',
            value: settings.widgetOpenOnTap,
            onChanged: (value) =>
                _save(ref, AppSettingsCompanion(widgetOpenOnTap: Value(value))),
          ),
          SectionLabel(AppStrings.widgetsHowTo),
          const _Note(
            '1. Mantén pulsada la pantalla de inicio.\n'
            '2. Toca en «Widgets».\n'
            '3. Busca NuvTune.\n'
            '4. Arrastra el widget y ajústalo al tamaño que prefieras.\n\n'
            'Puedes colocar varios widgets de tamaños distintos: todos usan '
            'esta misma configuración.',
          ),
        ],
      ],
    );
  }

  /// Guarda y publica en el motor, que es quien dibuja el widget.
  Future<void> _save(WidgetRef ref, AppSettingsCompanion companion) => ref
      .read(settingsMutationProvider.notifier)
      .save(companion, sync: const {SettingsSyncTarget.widget});
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Tokens.gutter,
      Tokens.space2,
      Tokens.gutter,
      0,
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(label),
    subtitle: detail == null ? null : Text(detail!),
    value: value,
    onChanged: onChanged,
  );
}

/// Reproduce en Flutter lo que el proveedor dibuja con RemoteViews, para poder
/// ver el resultado sin tener que salir a la pantalla de inicio.
class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.settings,
    required this.style,
    required this.size,
  });

  final AppSetting settings;
  final WidgetStyle style;
  final WidgetSize size;

  @override
  Widget build(BuildContext context) {
    final light = switch (WidgetTheme.values[settings.widgetTheme]) {
      WidgetTheme.light => true,
      WidgetTheme.dark => false,
      WidgetTheme.system => style == WidgetStyle.ios,
    };

    final accent = Color(settings.widgetAccentColor);
    final background =
        (light ? const Color(0xFFF3EFFA) : const Color(0xFF12101A)).withValues(
          alpha: settings.widgetOpacity,
        );
    final primaryText = light ? Colors.black : Colors.white;
    final secondaryText = light
        ? const Color(0xFF5A5566)
        : const Color(0xFFB3AEC0);

    final compact = size == WidgetSize.compact;
    final showProgress = settings.widgetShowProgress && !compact;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        color: background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (settings.widgetShowCover)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                  ),
                ),
              if (settings.widgetShowCover)
                const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.widgetShowTitle)
                      Text(
                        '24K Magic',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    if (settings.widgetShowArtist)
                      Text(
                        'Bruno Mars',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: secondaryText),
                      ),
                    if (settings.widgetShowNextInQueue)
                      Text(
                        'A continuación: Finesse',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: accent),
                      ),
                  ],
                ),
              ),
              if (compact && settings.widgetShowControls)
                _Controls(
                  accent: accent,
                  foreground: primaryText,
                  compact: true,
                  large: false,
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: Tokens.space2),
            Row(
              children: [
                if (settings.widgetShowDuration)
                  Text(
                    '0:45',
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.space2,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: 0.32,
                        minHeight: 4,
                        color: accent,
                        backgroundColor: secondaryText.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
                if (settings.widgetShowDuration)
                  Text(
                    '3:46',
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
              ],
            ),
          ],
          if (!compact && settings.widgetShowControls) ...[
            const SizedBox(height: Tokens.space1),
            _Controls(
              accent: accent,
              foreground: primaryText,
              compact: false,
              large: size == WidgetSize.large,
            ),
          ],
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.accent,
    required this.foreground,
    required this.compact,
    required this.large,
  });

  final Color accent;
  final Color foreground;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (large) Icon(Icons.shuffle_rounded, size: 20, color: foreground),
        Icon(
          Icons.skip_previous_rounded,
          size: compact ? 24 : 28,
          color: foreground,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space2),
          child: Icon(
            Icons.play_arrow_rounded,
            size: compact ? 28 : 34,
            color: accent,
          ),
        ),
        Icon(
          Icons.skip_next_rounded,
          size: compact ? 24 : 28,
          color: foreground,
        ),
        if (large) Icon(Icons.repeat_rounded, size: 20, color: foreground),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final WidgetStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;
    final light = style == WidgetStyle.ios;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Tokens.durationFast,
        padding: const EdgeInsets.all(Tokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusMedium),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: selected
                ? accent.middle
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Miniatura del aspecto: tarjeta clara o tarjeta oscura.
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                color: light
                    ? const Color(0xFFF3EFFA)
                    : const Color(0xFF12101A),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.play_arrow_rounded,
                color: light ? const Color(0xFF6D00FF) : accent.middle,
              ),
            ),
            const SizedBox(height: Tokens.space2),
            Text(
              light ? 'Tarjeta clara' : 'Tarjeta oscura',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            Text(
              light ? 'Simple y minimalista' : 'Más información a la vista',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentRow extends ConsumerWidget {
  const _AccentRow({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Las mismas identidades que la apariencia de la aplicación, para que el
    // widget no desentone con lo que hay dentro.
    final colors = [
      for (final identity in AccentIdentity.all) identity.middle,
      Colors.white,
      const Color(0xFFFF8A00),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space2,
        Tokens.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color principal'),
          const SizedBox(height: Tokens.space3),
          Wrap(
            spacing: Tokens.space3,
            runSpacing: Tokens.space3,
            children: [
              for (final color in colors)
                GestureDetector(
                  onTap: () => _save(ref, color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: color.toARGB32() == selected
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: color.toARGB32() == selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: color.computeLuminance() > 0.55
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(WidgetRef ref, Color color) => ref
      .read(settingsMutationProvider.notifier)
      .save(
        AppSettingsCompanion(widgetAccentColor: Value(color.toARGB32())),
        sync: const {SettingsSyncTarget.widget},
      );
}

class _OpacitySlider extends ConsumerStatefulWidget {
  const _OpacitySlider({required this.value});

  final double value;

  @override
  ConsumerState<_OpacitySlider> createState() => _OpacitySliderState();
}

class _OpacitySliderState extends ConsumerState<_OpacitySlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space4,
        Tokens.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Opacidad del fondo')),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0.2, 1),
            min: 0.2,
            max: 1,
            onChanged: (next) => setState(() => _dragValue = next),
            onChangeEnd: (next) {
              setState(() => _dragValue = null);
              ref
                  .read(settingsMutationProvider.notifier)
                  .save(
                    AppSettingsCompanion(widgetOpacity: Value(next)),
                    sync: const {SettingsSyncTarget.widget},
                  );
            },
          ),
        ],
      ),
    );
  }
}
