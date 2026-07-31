import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/player/player_controller.dart';

/// Modo "Mejorar audio" completo (requerimiento secciones 5.1 y 5.2).
///
/// Vive dentro de la pantalla "Ecualizador y mejora" y de la pestana Efectos
/// del reproductor, por encima del ecualizador, que es el orden real de la
/// cadena de procesamiento.
class EnhancementPanel extends ConsumerWidget {
  const EnhancementPanel({super.key, required this.directMode});

  final bool directMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(enhancementStateProvider);
    final state = stateAsync.valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final active = state.enabled && !directMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: Icon(
            Icons.auto_awesome_rounded,
            color: active ? scheme.primary : null,
          ),
          title: const Text(AppStrings.enhancementTitle),
          subtitle: Text(
            directMode
                ? 'El modo directo la mantiene desactivada.'
                : AppStrings.enhancementSubtitle,
          ),
          value: state.enabled,
          onChanged: directMode ? null : (value) => _save(ref, enabled: value),
        ),

        if (active) ...[
          // Comparacion A/B: apagar y volver a encender sin recargar la pista.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: OutlinedButton.icon(
              onPressed: () => _compare(ref),
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: const Text(AppStrings.enhancementCompare),
            ),
          ),

          _Header(AppStrings.enhancementProfile),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final profile in EnhancementProfile.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_profileLabel(profile)),
                      selected: state.profileIndex == profile.index,
                      onSelected: (_) => _save(ref, profile: profile),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _profileDescription(
                EnhancementProfile.values[state.profileIndex],
              ),
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),

          const SizedBox(height: 8),
          _Header(AppStrings.enhancementDetail),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<DetailLevel>(
              segments: const [
                ButtonSegment(value: DetailLevel.off, label: Text('Sin realce')),
                ButtonSegment(value: DetailLevel.low, label: Text('Bajo')),
                ButtonSegment(value: DetailLevel.medium, label: Text('Medio')),
                ButtonSegment(value: DetailLevel.high, label: Text('Alto')),
              ],
              selected: {DetailLevel.values[state.detailIndex]},
              onSelectionChanged: (selection) =>
                  _save(ref, detail: selection.first),
            ),
          ),
          // Advertencia obligatoria del requerimiento 5.2.
          if (state.detailIndex == DetailLevel.high.index)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.errorContainer,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.enhancementDetailWarning,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          _SliderRow(
            label: AppStrings.enhancementMultiband,
            value: state.multibandStrength,
            valueLabel: _percent(state.multibandStrength),
            onChanged: (value) => _save(ref, multibandStrength: value),
            note: 'Controla graves, medios y agudos por separado, de modo que '
                'un golpe de bajo no apague la voz.',
          ),

          _Header(AppStrings.enhancementNormalization),
          RadioGroup<NormalizationMode>(
            groupValue: NormalizationMode.values[state.normalizationIndex],
            onChanged: (mode) =>
                mode == null ? null : _save(ref, normalization: mode),
            child: const Column(
              children: [
                RadioListTile<NormalizationMode>(
                  value: NormalizationMode.off,
                  title: Text('Desactivada'),
                ),
                RadioListTile<NormalizationMode>(
                  value: NormalizationMode.live,
                  title: Text('En vivo'),
                  subtitle: Text(
                    'Sigue la señal y corrige despacio. No necesita analizar '
                    'nada de antemano.',
                  ),
                ),
                RadioListTile<NormalizationMode>(
                  value: NormalizationMode.analyzed,
                  title: Text('Por análisis'),
                  subtitle: Text(
                    'Usa la medida guardada de cada canción. Respeta la '
                    'dinámica original, pero hay que analizar la biblioteca.',
                  ),
                ),
              ],
            ),
          ),
          if (state.normalizationIndex == NormalizationMode.analyzed.index)
            const _AnalysisTile(),

          _Header(AppStrings.enhancementStereo),
          SwitchListTile(
            title: const Text('Expansión estéreo'),
            subtitle: const Text(
              'Desactivada por omisión. Pensada para audífonos; el canal '
              'central no se toca, de modo que la mezcla a mono sigue siendo '
              'correcta.',
            ),
            value: state.stereoExpansionEnabled,
            onChanged: (value) => _save(ref, stereoExpansionEnabled: value),
          ),
          if (state.stereoExpansionEnabled)
            _SliderRow(
              label: 'Amplitud',
              value: state.stereoWidth,
              valueLabel: _percent(state.stereoWidth),
              onChanged: (value) => _save(ref, stereoWidth: value),
            ),

          ListTile(
            leading: Icon(Icons.shield_moon_rounded, color: scheme.primary),
            title: const Text(AppStrings.enhancementLimiter),
            subtitle: const Text(AppStrings.enhancementLimiterNote),
          ),

          const _OutputProfileTile(),
        ],

        const Divider(height: 32),
      ],
    );
  }

  /// Apaga la mejora dos segundos y la vuelve a encender, para comparar sin
  /// tener que tocar el interruptor dos veces (requerimiento 5.1).
  Future<void> _compare(WidgetRef ref) async {
    final repository = ref.read(enhancementRepositoryProvider);
    await repository.save(enabled: false);
    await ref.read(playbackProvider.notifier).pushEnhancement();
    await Future<void>.delayed(const Duration(seconds: 3));
    await repository.save(enabled: true);
    await ref.read(playbackProvider.notifier).pushEnhancement();
  }

  Future<void> _save(
    WidgetRef ref, {
    bool? enabled,
    EnhancementProfile? profile,
    DetailLevel? detail,
    double? multibandStrength,
    NormalizationMode? normalization,
    bool? stereoExpansionEnabled,
    double? stereoWidth,
  }) async {
    // Tocar un parametro a mano convierte la seleccion en "personalizado": si
    // no, la pantalla mostraria un perfil que ya no corresponde a lo que suena.
    final becomesCustom = detail != null ||
        multibandStrength != null ||
        stereoExpansionEnabled != null ||
        stereoWidth != null;

    await ref.read(enhancementRepositoryProvider).save(
          enabled: enabled,
          profile: profile ?? (becomesCustom ? EnhancementProfile.custom : null),
          detail: detail,
          multibandStrength: multibandStrength,
          normalization: normalization,
          stereoExpansionEnabled: stereoExpansionEnabled,
          stereoWidth: stereoWidth,
        );

    // Al elegir un perfil, el motor devuelve sus valores; se releen para que la
    // pantalla muestre exactamente lo que quedo aplicado.
    if (profile != null && profile != EnhancementProfile.custom) {
      await _persistProfileDefaults(ref, profile);
    }

    await ref.read(playbackProvider.notifier).pushEnhancement();
  }

  /// Copia local de la tabla de perfiles del motor, para que la interfaz pueda
  /// mostrar los valores sin tener que preguntar por cada uno.
  Future<void> _persistProfileDefaults(
    WidgetRef ref,
    EnhancementProfile profile,
  ) async {
    final values = _profileDefaults[profile];
    if (values == null) return;
    await ref.read(enhancementRepositoryProvider).save(
          detail: values.detail,
          multibandStrength: values.multiband,
          stereoExpansionEnabled: values.stereo,
          stereoWidth: values.width,
        );
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _profileLabel(EnhancementProfile profile) => switch (profile) {
        EnhancementProfile.balanced => 'Equilibrado',
        EnhancementProfile.clarity => 'Claridad',
        EnhancementProfile.tightBass => 'Graves definidos',
        EnhancementProfile.smooth => 'Suave',
        EnhancementProfile.headphones => 'Audífonos',
        EnhancementProfile.phoneSpeaker => 'Altavoz del teléfono',
        EnhancementProfile.custom => 'Personalizado',
      };

  static String _profileDescription(EnhancementProfile profile) =>
      switch (profile) {
        EnhancementProfile.balanced =>
          'Corrección discreta, sin coloración apreciable.',
        EnhancementProfile.clarity =>
          'Acentua transitorios y voces. Puede endurecer archivos muy comprimidos.',
        EnhancementProfile.tightBass =>
          'Contiene el grave para que no se desborde ni tape la voz.',
        EnhancementProfile.smooth =>
          'Sin realce y con la dinámica contenida, para escuchar de fondo.',
        EnhancementProfile.headphones =>
          'Único perfil con expansión estéreo, moderada.',
        EnhancementProfile.phoneSpeaker =>
          'Compresión fuerte para ganar volumen útil; sin expansión, que ahí '
              'solo restaría energía al centro.',
        EnhancementProfile.custom =>
          'Todos los parametros quedan bajo tu control.',
      };

  /// Los mismos valores que aplica `EnhancementPresets` en Kotlin.
  static const _profileDefaults = <EnhancementProfile, _ProfileDefaults>{
    EnhancementProfile.balanced:
        _ProfileDefaults(DetailLevel.low, 0.35, false, 0),
    EnhancementProfile.clarity:
        _ProfileDefaults(DetailLevel.medium, 0.45, false, 0),
    EnhancementProfile.tightBass:
        _ProfileDefaults(DetailLevel.low, 0.75, false, 0),
    EnhancementProfile.smooth:
        _ProfileDefaults(DetailLevel.off, 0.55, false, 0),
    EnhancementProfile.headphones:
        _ProfileDefaults(DetailLevel.low, 0.40, true, 0.45),
    EnhancementProfile.phoneSpeaker:
        _ProfileDefaults(DetailLevel.medium, 0.85, false, 0),
  };
}

class _ProfileDefaults {
  const _ProfileDefaults(
    this.detail,
    this.multiband,
    this.stereo,
    this.width,
  );

  final DetailLevel detail;
  final double multiband;
  final bool stereo;
  final double width;
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
    this.note,
  });

  final String label;
  final double value;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final String? note;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.value;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label)),
              Text(
                widget.valueLabel,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0, 1),
            onChanged: (next) => setState(() => _dragValue = next),
            onChangeEnd: (next) {
              setState(() => _dragValue = null);
              widget.onChanged(next);
            },
          ),
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.note!,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// Analiza la biblioteca para la normalizacion por analisis.
class _AnalysisTile extends ConsumerStatefulWidget {
  const _AnalysisTile();

  @override
  ConsumerState<_AnalysisTile> createState() => _AnalysisTileState();
}

class _AnalysisTileState extends ConsumerState<_AnalysisTile> {
  bool _running = false;
  int _done = 0;
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.query_stats_rounded),
      title: const Text('Analizar la biblioteca'),
      subtitle: Text(
        _running
            ? 'Analizando $_done de $_total. Puedes seguir usando la aplicación.'
            : 'Mide la sonoridad real de cada canción. Es un proceso largo y '
                'solo hay que hacerlo una vez por archivo.',
      ),
      trailing: _running
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow_rounded),
      onTap: _running ? null : _analyze,
    );
  }

  Future<void> _analyze() async {
    final repository = ref.read(enhancementRepositoryProvider);
    final engine = ref.read(engineProvider);
    final songs = ref.read(libraryRepositoryProvider).songs;
    final already = await repository.analyzedIds();
    final pending = songs.where((song) => !already.contains(song.id)).toList();

    setState(() {
      _running = true;
      _done = 0;
      _total = pending.length;
    });

    for (final song in pending) {
      if (!mounted) return;
      final analysis = await engine.api.analyzeLoudness(song.id);
      await repository.saveAnalysis(analysis);
      if (!mounted) return;
      setState(() => _done++);
    }

    if (!mounted) return;
    setState(() => _running = false);
    await ref.read(playbackProvider.notifier).pushEnhancement();
  }
}

/// Guarda la configuracion actual como perfil de la salida activa
/// (requerimiento 5.4).
class _OutputProfileTile extends ConsumerWidget {
  const _OutputProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final output = ref.watch(playbackProvider).output;
    final profiles = ref.watch(outputProfilesProvider).valueOrNull ?? const {};
    final saved = profiles[output.index];

    return ListTile(
      leading: const Icon(Icons.headset_rounded),
      title: Text('Guardar para ${_outputLabel(output)}'),
      subtitle: Text(
        saved == null
            ? 'Esta salida todavía no tiene perfil propio. Al guardarlo, '
                'NuvTune lo cargara sola cada vez que la detecte.'
            : 'Ya hay un perfil guardado para esta salida. Se sobrescribirá.',
      ),
      trailing: const Icon(Icons.save_outlined),
      onTap: () => _save(context, ref, output),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AudioOutput output,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final equalizer = await ref.read(equalizerRepositoryProvider).state();
    final enhancement = await ref.read(enhancementRepositoryProvider).state();

    await ref.read(enhancementRepositoryProvider).saveOutputProfile(
          output: output,
          bandCount: equalizer.bandCount,
          gains: equalizerGainsOf(equalizer),
          presetName: equalizer.presetName,
          preampDb: equalizer.preampDb,
          profile: EnhancementProfile.values[enhancement.profileIndex],
          enhancementEnabled: enhancement.enabled,
        );

    messenger.showSnackBar(
      SnackBar(content: Text('Perfil guardado para ${_outputLabel(output)}')),
    );
  }

  static String _outputLabel(AudioOutput output) => switch (output) {
        AudioOutput.speaker => 'el altavoz del teléfono',
        AudioOutput.wiredHeadphones => 'los audífonos con cable',
        AudioOutput.bluetooth => 'Bluetooth',
        AudioOutput.androidAuto => 'Android Auto',
        AudioOutput.usbDac => 'el DAC USB',
      };
}
