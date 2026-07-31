import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/data/repositories/equalizer_repository.dart';
import 'package:nuvtune/features/enhancement/enhancement_panel.dart';
import 'package:nuvtune/features/player/player_controller.dart';

/// Presets del requerimiento seccion 5.3.
///
/// Las curvas estan definidas sobre las diez bandas de octava. El motor
/// remuestrea la curva cuando el usuario elige 15 o 20 bandas, de modo que un
/// preset suena igual con cualquier resolucion.
const _presetCurves = <String, List<double>>{
  'Plano': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  'Pop': [-1, -0.5, 0, 2, 3.5, 3, 1.5, 0, -0.5, -1],
  'Rock': [4, 3, 1.5, -0.5, -1.5, -0.5, 1.5, 3, 3.5, 4],
  'Electrónica': [4.5, 3.5, 1, 0, -1.5, 1.5, 0.5, 1, 3.5, 4.5],
  'Hip hop': [5, 4, 1.5, 2.5, -0.5, -0.5, 1, -0.5, 1.5, 2.5],
  'Jazz': [3, 2, 1, 1.5, -1, -1, 0, 1, 2, 3],
  'Clásica': [3.5, 2.5, 1.5, 0.5, -1, -1, 0, 1.5, 2.5, 3.5],
  'Vocal': [-2, -1.5, -0.5, 1.5, 3.5, 3.5, 2.5, 1.5, 0, -1],
  'Acústica': [3, 2.5, 1.5, 0.5, 1, 1, 1.5, 2, 2, 1.5],
  'Graves': [6, 5, 3.5, 1.5, 0, 0, 0, 0, 0, 0],
  'Agudos': [0, 0, 0, 0, 0, 1.5, 3, 4.5, 5.5, 6],
};

const _customPresetName = 'Personalizado';

/// Frecuencias de las bandas del motor, para dibujar las etiquetas.
final equalizerBandsProvider =
    FutureProvider.family<EqualizerBands, int>((ref, bandCount) {
  return ref.watch(engineProvider).api.getEqualizerBands(bandCount);
});

/// Pantalla "Ecualizador y mejora" (requerimiento seccion 11).
///
/// Reune la cadena completa en el mismo orden en que procesa el audio: primero
/// el modo "Mejorar audio" con sus perfiles, el realce, la dinamica multibanda,
/// la normalizacion, la expansion estereo y el limitador; despues el
/// ecualizador grafico con su ganancia previa, el balance y la conversión a
/// mono; y al final la velocidad y el tono.
class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(equalizerStateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.equalizer),
        actions: [
          PopupMenuButton<int>(
            tooltip: AppStrings.bandsMode,
            icon: const Icon(Icons.tune_rounded),
            onSelected: (bandCount) => _changeBandCount(ref, bandCount),
            itemBuilder: (context) => [
              for (final count in [10, 15, 20])
                CheckedPopupMenuItem(
                  value: count,
                  checked: stateAsync.valueOrNull?.bandCount == count,
                  child: Text('$count bandas'),
                ),
            ],
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (state) => EqualizerBody(state: state, settings: settings),
      ),
    );
  }

  Future<void> _changeBandCount(WidgetRef ref, int bandCount) async {
    final repository = ref.read(equalizerRepositoryProvider);
    final current = await repository.state();
    final currentGains =
        EqualizerRepository.decodeGains(current.gainsJson, current.bandCount);

    // Al cambiar la resolucion se recalcula la curva del preset activo. Si era
    // personalizada, se conserva lo que se pueda y el resto queda a cero.
    final curve = _presetCurves[current.presetName];
    final gains = curve == null
        ? EqualizerRepository.decodeGains(
            _encode(currentGains),
            bandCount,
          )
        : _resampleCurve(curve, bandCount);

    await repository.save(bandCount: bandCount, gains: gains);
    await ref.read(playbackProvider.notifier).pushAudioSettings();
  }

  static String _encode(List<double> gains) =>
      '[${gains.map((value) => value.toString()).join(',')}]';
}

/// Cuerpo del ecualizador, compartido por la pantalla completa y por la
/// pestana "Efectos" del reproductor.
class EqualizerBody extends ConsumerWidget {
  const EqualizerBody({
    super.key,
    required this.state,
    required this.settings,
  });

  final EqualizerStateData state;
  final AppSetting? settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final gains = equalizerGainsOf(state);
    final bandsAsync = ref.watch(equalizerBandsProvider(state.bandCount));
    final directMode = settings?.directMode ?? false;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Aviso honesto que exige el requerimiento seccion 5.1.
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHigh,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.enhancementHonesty,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (directMode)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.errorContainer,
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El modo directo está activo: se omite toda la cadena de '
                    'procesamiento, incluidos la mejora, el ecualizador, el '
                    'balance y la conversión a mono.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // La mejora va antes que el ecualizador en la pantalla porque tambien
        // va antes en la cadena real de procesamiento (requerimiento 5.2).
        EnhancementPanel(directMode: directMode),

        SwitchListTile(
          title: const Text(AppStrings.equalizerEnabled),
          subtitle: const Text(
            'Se puede activar y desactivar mientras suena la música.',
          ),
          value: state.enabled,
          onChanged: (value) => _save(ref, enabled: value),
        ),

        const Divider(),

        // Perfil
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            AppStrings.preset,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final name in [..._presetCurves.keys, _customPresetName])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(name),
                    selected: state.presetName == name,
                    onSelected: name == _customPresetName
                        ? null
                        : (_) => _applyPreset(ref, name),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Bandas
        bandsAsync.when(
          loading: () => const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SizedBox(
            height: 120,
            child: Center(child: Text('$error')),
          ),
          data: (bands) => _BandSliders(
            bands: bands,
            gains: gains,
            enabled: state.enabled && !directMode,
            onChanged: (index, value) {
              final updated = [...gains];
              updated[index] = value;
              _save(
                ref,
                gains: updated,
                presetName: _matchPreset(updated, state.bandCount),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => _applyPreset(ref, 'Plano'),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text(AppStrings.resetEqualizer),
          ),
        ),

        const Divider(height: 32),

        // Ganancia previa
        _SliderTile(
          label: AppStrings.preamp,
          value: state.preampDb,
          min: -12,
          max: 12,
          valueLabel: Formatters.gainDb(state.preampDb),
          enabled: state.enabled && !directMode,
          onChanged: (value) => _save(ref, preampDb: value),
        ),
        SwitchListTile(
          title: const Text(AppStrings.autoPreventClipping),
          subtitle: const Text(
            'Baja la ganancia previa cuando varias bandas suben, para que los '
            'presets no saturen.',
          ),
          value: state.autoPreventClipping,
          onChanged: state.enabled && !directMode
              ? (value) => _save(ref, autoPreventClipping: value)
              : null,
        ),

        const Divider(height: 32),

        // Balance y mono (requerimiento seccion 5.5).
        _SliderTile(
          label: AppStrings.balance,
          value: state.balance,
          min: -1,
          max: 1,
          valueLabel: _balanceLabel(state.balance),
          enabled: !directMode,
          onChanged: (value) => _save(ref, balance: value),
        ),
        SwitchListTile(
          title: const Text(AppStrings.monoOutput),
          subtitle: const Text('Mezcla los dos canales en uno.'),
          value: state.monoOutput,
          onChanged: directMode ? null : (value) => _save(ref, monoOutput: value),
        ),

        const Divider(height: 32),

        // Velocidad y tono (requerimiento seccion 5.5).
        _SpeedAndPitch(settings: settings),

        const Divider(height: 32),

        SwitchListTile(
          title: const Text(AppStrings.directMode),
          subtitle: const Text(AppStrings.directModeNote),
          value: directMode,
          onChanged: (value) async {
            await ref.read(settingsRepositoryProvider).update(
                  AppSettingsCompanion(directMode: Value(value)),
                );
            await ref.read(playbackProvider.notifier).pushAudioSettings();
          },
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'La cadena completa de mejora perceptual (dinámica multibanda, '
            'normalización de volumen, expansión estéreo y limitador) forma '
            'parte de la Fase 3 del plan y todavía no está disponible.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Future<void> _applyPreset(WidgetRef ref, String name) async {
    final state = await ref.read(equalizerRepositoryProvider).state();
    final curve = _presetCurves[name];
    if (curve == null) return;
    await ref.read(equalizerRepositoryProvider).save(
          gains: _resampleCurve(curve, state.bandCount),
          presetName: name,
        );
    await ref.read(playbackProvider.notifier).pushAudioSettings();
  }

  Future<void> _save(
    WidgetRef ref, {
    bool? enabled,
    List<double>? gains,
    double? preampDb,
    bool? autoPreventClipping,
    double? balance,
    bool? monoOutput,
    String? presetName,
  }) async {
    await ref.read(equalizerRepositoryProvider).save(
          enabled: enabled,
          gains: gains,
          preampDb: preampDb,
          autoPreventClipping: autoPreventClipping,
          balance: balance,
          monoOutput: monoOutput,
          presetName: presetName,
        );
    await ref.read(playbackProvider.notifier).pushAudioSettings();
  }

  static String _balanceLabel(double balance) {
    if (balance.abs() < 0.02) return 'Centrado';
    final percent = (balance.abs() * 100).round();
    return balance < 0 ? 'Izquierda $percent%' : 'Derecha $percent%';
  }

  static String _matchPreset(List<double> gains, int bandCount) {
    for (final entry in _presetCurves.entries) {
      final candidate = _resampleCurve(entry.value, bandCount);
      final matches = candidate.length == gains.length &&
          List.generate(gains.length, (index) => index)
              .every((index) => (candidate[index] - gains[index]).abs() < 0.05);
      if (matches) return entry.key;
    }
    return _customPresetName;
  }
}

/// Remuestrea una curva de 10 bandas al numero de bandas pedido, interpolando en
/// escala logaritmica de frecuencia, que es como se percibe el espectro.
List<double> _resampleCurve(List<double> curve, int bandCount) {
  if (bandCount == curve.length) return List<double>.from(curve);

  final result = <double>[];
  for (var index = 0; index < bandCount; index++) {
    final ratio = index / (bandCount - 1) * (curve.length - 1);
    final lower = ratio.floor();
    final upper = ratio.ceil().clamp(0, curve.length - 1);
    final fraction = ratio - lower;
    result.add(curve[lower] + (curve[upper] - curve[lower]) * fraction);
  }
  return result;
}

class _BandSliders extends StatelessWidget {
  const _BandSliders({
    required this.bands,
    required this.gains,
    required this.enabled,
    required this.onChanged,
  });

  final EqualizerBands bands;
  final List<double> gains;
  final bool enabled;
  final void Function(int index, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = gains.length;

    return SizedBox(
      height: 268,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var index = 0; index < count; index++)
              SizedBox(
                width: count > 12 ? 40 : 52,
                child: Column(
                  children: [
                    SizedBox(
                      height: 24,
                      child: Text(
                        Formatters.gainDb(gains[index]),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: gains[index].abs() < 0.05
                              ? scheme.onSurfaceVariant
                              : scheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: gains[index].clamp(
                            bands.minGainDb,
                            bands.maxGainDb,
                          ),
                          min: bands.minGainDb,
                          max: bands.maxGainDb,
                          divisions: 48,
                          onChanged: enabled
                              ? (value) => onChanged(index, value)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 22,
                      child: Text(
                        Formatters.frequency(bands.centerFrequenciesHz[index]),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _SpeedAndPitch extends ConsumerWidget {
  const _SpeedAndPitch({required this.settings});

  final AppSetting? settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = settings?.playbackSpeed ?? 1;
    final pitch = settings?.playbackPitch ?? 1;

    return Column(
      children: [
        _SliderTile(
          label: AppStrings.playbackSpeed,
          value: speed,
          min: 0.5,
          max: 2,
          valueLabel: Formatters.speed(speed),
          enabled: true,
          onChanged: (value) async {
            await ref.read(settingsRepositoryProvider).update(
                  AppSettingsCompanion(playbackSpeed: Value(value)),
                );
            ref.read(playbackProvider.notifier).setSpeed(value);
          },
        ),
        _SliderTile(
          label: AppStrings.playbackPitch,
          value: pitch,
          min: 0.5,
          max: 2,
          valueLabel: '${pitch.toStringAsFixed(2)}x',
          enabled: true,
          onChanged: (value) async {
            await ref.read(settingsRepositoryProvider).update(
                  AppSettingsCompanion(playbackPitch: Value(value)),
                );
            ref.read(playbackProvider.notifier).setPitch(value);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'El tono se controla por separado de la velocidad.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
