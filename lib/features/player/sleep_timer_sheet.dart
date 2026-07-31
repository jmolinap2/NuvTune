import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_controller.dart';

/// Temporizador de apagado (requerimiento seccion 4.2).
Future<void> showSleepTimerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const _SleepTimerSheet(),
    );

class _SleepTimerSheet extends ConsumerStatefulWidget {
  const _SleepTimerSheet();

  @override
  ConsumerState<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<_SleepTimerSheet> {
  static const _presets = [10, 15, 30, 45, 60, 90];

  int? _minutes;
  bool? _finishTrack;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final minutes = _minutes ?? settings?.sleepTimerMinutes ?? 30;
    final finishTrack = _finishTrack ?? settings?.sleepTimerFinishTrack ?? true;

    final remaining = ref.watch(
      playbackProvider.select((state) => state.snapshot.sleepTimerRemainingMs),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.sleepTimer,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),

            if (remaining != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Activo: quedan ${Formatters.duration(remaining)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),

            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _presets)
                  ChoiceChip(
                    label: Text('$preset min'),
                    selected: minutes == preset,
                    onSelected: (_) => setState(() => _minutes = preset),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            Slider(
              value: minutes.toDouble().clamp(5, 180),
              min: 5,
              max: 180,
              divisions: 35,
              label: '$minutes min',
              onChanged: (value) => setState(() => _minutes = value.round()),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terminar la canción en curso'),
              subtitle: const Text(
                'La música se detiene al final de la pista, no a mitad.',
              ),
              value: finishTrack,
              onChanged: (value) => setState(() => _finishTrack = value),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                if (remaining != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(playbackProvider.notifier).cancelSleepTimer();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar temporizador'),
                    ),
                  ),
                if (remaining != null) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      ref.read(playbackProvider.notifier).startSleepTimer(
                            Duration(minutes: minutes),
                            finishCurrentTrack: finishTrack,
                          );
                      // Se recuerda la eleccion para la proxima vez.
                      await ref.read(settingsRepositoryProvider).update(
                            AppSettingsCompanion(
                              sleepTimerMinutes: Value(minutes),
                              sleepTimerFinishTrack: Value(finishTrack),
                            ),
                          );
                      navigator.pop();
                    },
                    child: const Text('Activar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
