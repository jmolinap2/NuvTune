import 'package:flutter/material.dart';
import 'package:nuvtune/shared/widgets/option_picker.dart';

/// Relación de aspecto del contenedor de la escena visual del reproductor en
/// pantalla completa (video, visualizador, letras, portada o video+letras).
enum PlayerSceneAspectRatio {
  full(
    null,
    'Pantalla completa',
    'Usa toda la pantalla del teléfono, sin recuadro. Ideal para modo '
        'fiesta o visualizador.',
    Icons.crop_free_rounded,
  ),
  large(
    4 / 5,
    'Grande',
    '4:5 · video amplio sin ocultar título, progreso ni controles.',
    Icons.crop_portrait_rounded,
  ),
  balanced(
    3 / 4,
    'Equilibrado',
    '3:4 · pensado para tablets o pantallas con más información alrededor.',
    Icons.crop_5_4_rounded,
  ),
  square(
    1 / 1,
    'Cuadrado',
    '1:1 · para carátulas animadas o clips cuadrados.',
    Icons.crop_square_rounded,
  );

  const PlayerSceneAspectRatio(
    this.ratio,
    this.label,
    this.description,
    this.icon,
  );

  /// `null` significa "llenar la pantalla física disponible" (comportamiento
  /// previo): no se fuerza un valor numérico porque la mayoría de teléfonos no
  /// son exactamente 9:16 y forzar ese número introduciría barras laterales
  /// espurias en el contenedor exterior.
  final double? ratio;
  final String label;
  final String description;
  final IconData icon;

  static PlayerSceneAspectRatio fromIndex(int index) =>
      index >= 0 && index < values.length ? values[index] : full;
}

Future<PlayerSceneAspectRatio?> showPlayerSceneAspectRatioPicker(
  BuildContext context, {
  required PlayerSceneAspectRatio selected,
}) => showOptionPicker<PlayerSceneAspectRatio>(
  context,
  title: 'Relación de aspecto de la escena',
  selected: selected,
  helperText:
      'El video siempre se muestra completo en 16:9, sin recortes; el '
      'espacio sobrante se rellena con la portada ampliada y desenfocada.',
  options: [
    for (final ratio in PlayerSceneAspectRatio.values)
      OptionPickerItem(
        value: ratio,
        icon: ratio.icon,
        label: ratio.label,
        description: ratio.description,
      ),
  ],
);
