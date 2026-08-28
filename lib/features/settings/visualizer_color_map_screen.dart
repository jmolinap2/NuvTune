import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/visualizer_color_map.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

/// Editor del mapa de colores del visualizador.
///
/// Las paradas se expresan en intensidad (0 % silencio, 100 % pico), no en
/// posición de pantalla: eso es lo que hace que solo las columnas que alcanzan
/// cierta fuerza tomen el color de esa fuerza.
class VisualizerColorMapScreen extends ConsumerWidget {
  const VisualizerColorMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final map = VisualizerColorMap.fromJsonString(
      settings.visualizerColorMapJson,
    );
    final preset = VisualizerColorPreset.matching(map);
    final mode = VisualizerColorMode.byId(settings.visualizerColorMode);

    Future<void> save(VisualizerColorMap next) => ref
        .read(settingsMutationProvider.notifier)
        .save(
          AppSettingsCompanion(
            visualizerColorMapJson: Value(next.toJsonString()),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de colores')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          _MapPreview(map: map, mode: mode),
          const SettingsSectionLabel('Cómo se aplica'),
          RadioGroup<VisualizerColorMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value == null) return;
              ref
                  .read(settingsMutationProvider.notifier)
                  .save(
                    AppSettingsCompanion(visualizerColorMode: Value(value.id)),
                  );
            },
            child: Column(
              children: [
                for (final option in VisualizerColorMode.values)
                  RadioListTile<VisualizerColorMode>(
                    value: option,
                    title: Text(option.label),
                    subtitle: Text(option.description),
                  ),
              ],
            ),
          ),
          const SettingsSectionLabel('Prestablecidos'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Wrap(
              spacing: Tokens.space2,
              runSpacing: Tokens.space2,
              children: [
                for (final option in VisualizerColorPreset.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: preset == option,
                    onSelected: (_) => save(option.map),
                  ),
                if (preset == null)
                  const ChoiceChip(
                    label: Text('Personalizado'),
                    selected: true,
                    onSelected: null,
                  ),
              ],
            ),
          ),
          const SettingsSectionLabel('Paradas de color'),
          for (var index = 0; index < map.stops.length; index++)
            _StopTile(
              key: ValueKey('stop-$index-${map.stops[index].position}'),
              stop: map.stops[index],
              // Los extremos del rango se mantienen fijos: sin una parada en
              // 0 y otra en 1 el mapa dejaría tramos de intensidad sin color
              // definido.
              lockedPosition: index == 0 || index == map.stops.length - 1,
              canDelete: map.stops.length > VisualizerColorMap.minStops,
              onChanged: (next) => save(map.replaceStop(index, next)),
              onDelete: () => save(map.removeStop(index)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space3,
              Tokens.gutter,
              0,
            ),
            child: OutlinedButton.icon(
              onPressed: map.stops.length >= VisualizerColorMap.maxStops
                  ? null
                  : () {
                      final position = map.suggestedPosition();
                      save(
                        map.withStop(
                          VisualizerColorStop(position, map.colorAt(position)),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_rounded),
              label: Text(
                map.stops.length >= VisualizerColorMap.maxStops
                    ? 'Máximo ${VisualizerColorMap.maxStops} colores'
                    : 'Añadir punto de color',
              ),
            ),
          ),
          const SizedBox(height: Tokens.space4),
          const SettingsInfoPanel(
            icon: Icons.gradient_rounded,
            title: 'Se aplica a todas las visualizaciones',
            message:
                'Barras, anillos, ondas, partículas y picos consultan este mismo '
                'mapa con la intensidad que alcanzan, así que un 90 % se ve igual '
                'en cualquier estilo.',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space4,
              Tokens.gutter,
              0,
            ),
            child: TextButton.icon(
              onPressed: () => save(VisualizerColorMap.defaults),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Restaurar el reparto original'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Degradado del mapa sobre una fila de barras de alturas crecientes: deja ver
/// de un vistazo qué color recibe cada nivel de intensidad.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.map, required this.mode});

  final VisualizerColorMap map;
  final VisualizerColorMode mode;

  @override
  Widget build(BuildContext context) {
    final gradient = map.toGradient();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space4,
        Tokens.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radiusSmall),
              gradient: LinearGradient(
                colors: gradient.colors,
                stops: gradient.positions,
              ),
            ),
          ),
          const SizedBox(height: Tokens.space3),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 28; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Builder(
                        builder: (context) {
                          final intensity = (index + 1) / 28;
                          final height = 8 + intensity * 88;
                          // «Por fila» reparte el mapa a lo alto de la barra,
                          // así que una barra corta solo llega a los colores
                          // bajos; «por columna» la pinta de un solo color.
                          final ramp = map.rampTo(intensity);
                          return Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: mode == VisualizerColorMode.column
                                  ? map.colorAt(intensity)
                                  : null,
                              gradient: mode == VisualizerColorMode.row
                                  ? LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: ramp.colors,
                                      stops: ramp.positions,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.space2),
          Text(
            mode == VisualizerColorMode.row
                ? 'Cada nivel de altura tiene su color: solo las barras altas '
                      'llegan a los últimos colores.'
                : 'Cada barra toma un solo color, el de la fuerza que alcanza.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.lockedPosition,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    super.key,
  });

  final VisualizerColorStop stop;
  final bool lockedPosition;
  final bool canDelete;
  final ValueChanged<VisualizerColorStop> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (stop.position * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        Tokens.space2,
        Tokens.gutter,
        0,
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(Tokens.radiusSmall),
            onTap: () async {
              final picked = await showColorEditor(context, stop.color);
              if (picked != null) onChanged(stop.copyWith(color: picked));
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stop.color,
                borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(width: Tokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lockedPosition ? '$percent % (fijo)' : '$percent %',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (lockedPosition)
                  Text(
                    percent == 0
                        ? 'Color en silencio'
                        : 'Color del pico máximo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  Slider(
                    value: stop.position,
                    onChanged: (value) => onChanged(
                      stop.copyWith(
                        position: double.parse(value.toStringAsFixed(2)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: canDelete && !lockedPosition ? onDelete : null,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Quitar color',
          ),
        ],
      ),
    );
  }
}

/// Selector HSV compacto. Se prefiere a una rejilla fija de muestras porque el
/// usuario necesita alcanzar tonos concretos (un naranja cálido exacto, por
/// ejemplo) que ninguna rejilla corta cubriría.
Future<Color?> showColorEditor(BuildContext context, Color initial) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ColorEditorSheet(initial: initial),
  );
}

class _ColorEditorSheet extends StatefulWidget {
  const _ColorEditorSheet({required this.initial});

  final Color initial;

  @override
  State<_ColorEditorSheet> createState() => _ColorEditorSheetState();
}

class _ColorEditorSheetState extends State<_ColorEditorSheet> {
  late HSVColor _color = HSVColor.fromColor(widget.initial);

  Color get _asColor => _color.toColor();

  String get _hex =>
      '#${_asColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Tokens.gutter,
        0,
        Tokens.gutter,
        MediaQuery.viewInsetsOf(context).bottom + Tokens.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _asColor,
                  borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                ),
              ),
              const SizedBox(width: Tokens.space3),
              Text(_hex, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Tokens.space4),
          _ChannelSlider(
            label: 'Tono',
            value: _color.hue,
            max: 360,
            gradient: const [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
            onChanged: (value) =>
                setState(() => _color = _color.withHue(value)),
          ),
          _ChannelSlider(
            label: 'Saturación',
            value: _color.saturation,
            max: 1,
            gradient: [
              HSVColor.fromAHSV(1, _color.hue, 0, _color.value).toColor(),
              HSVColor.fromAHSV(1, _color.hue, 1, _color.value).toColor(),
            ],
            onChanged: (value) =>
                setState(() => _color = _color.withSaturation(value)),
          ),
          _ChannelSlider(
            label: 'Brillo',
            value: _color.value,
            max: 1,
            gradient: [
              Colors.black,
              HSVColor.fromAHSV(1, _color.hue, _color.saturation, 1).toColor(),
            ],
            onChanged: (value) =>
                setState(() => _color = _color.withValue(value)),
          ),
          const SizedBox(height: Tokens.space4),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_asColor),
            child: const Text('Usar este color'),
          ),
        ],
      ),
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final List<Color> gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Tokens.space3),
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(colors: gradient),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(value: value, max: max, onChanged: onChanged),
          ),
        ],
      ),
    ],
  );
}
