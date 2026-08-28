import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';
import 'package:nuvtune/shared/widgets/option_picker.dart';

/// Movimiento aplicado a la línea activa de una letra sincronizada.
enum LyricsAnimationStyle {
  soft(
    'soft',
    'Suave',
    'Cambia tamaño, peso y color sin distraer.',
    Icons.blur_on_rounded,
  ),
  karaoke(
    'karaoke',
    'Karaoke',
    'Rellena la línea de izquierda a derecha mientras transcurre.',
    Icons.mic_external_on_rounded,
  ),
  pulse(
    'pulse',
    'Pulso',
    'La línea activa brilla y respira con el ritmo.',
    Icons.graphic_eq_rounded,
  ),
  rise(
    'rise',
    'Ascenso',
    'La línea activa entra desde abajo y la anterior se retira.',
    Icons.vertical_align_top_rounded,
  );

  const LyricsAnimationStyle(this.id, this.label, this.description, this.icon);

  final String id;
  final String label;
  final String description;
  final IconData icon;

  static LyricsAnimationStyle byId(String? id) => values.firstWhere(
    (style) => style.id == id,
    orElse: () => LyricsAnimationStyle.soft,
  );
}

/// Avance de una línea entre su marca y la siguiente. Es puro para que el
/// renderer de pantalla normal y el inmersivo compartan exactamente el mismo
/// contrato de karaoke.
double synchronizedLyricProgress({
  required int positionMs,
  required int lineStartMs,
  required int? nextLineStartMs,
  int fallbackDurationMs = 3200,
}) {
  final end = nextLineStartMs != null && nextLineStartMs > lineStartMs
      ? nextLineStartMs
      : lineStartMs + fallbackDurationMs;
  if (positionMs <= lineStartMs) return 0;
  if (positionMs >= end) return 1;
  return (positionMs - lineStartMs) / (end - lineStartMs);
}

Future<void> showLyricsAnimationStylePicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected = LyricsAnimationStyle.byId(
    ref.read(settingsProvider).valueOrNull?.lyricsAnimationStyle,
  );
  final choice = await showOptionPicker<LyricsAnimationStyle>(
    context,
    title: 'Animación de letras',
    selected: selected,
    helperText:
        'Los efectos se aplican a letras sincronizadas. Una letra sin tiempos '
        'permanece estable y desplazable.',
    options: [
      for (final style in LyricsAnimationStyle.values)
        OptionPickerItem(
          value: style,
          icon: style.icon,
          label: style.label,
          description: style.description,
        ),
    ],
  );
  if (choice == null) return;
  await ref
      .read(settingsMutationProvider.notifier)
      .save(AppSettingsCompanion(lyricsAnimationStyle: Value(choice.id)));
}
