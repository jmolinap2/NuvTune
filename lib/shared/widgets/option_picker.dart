import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

/// Una opción del bottom sheet de [showOptionPicker].
@immutable
class OptionPickerItem<T> {
  const OptionPickerItem({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
  });

  final T value;
  final IconData icon;
  final String label;
  final String description;
}

/// Bottom sheet genérico de selección única: título, lista de [RadioListTile]
/// con icono/etiqueta/descripción, y un texto de ayuda opcional al final.
///
/// Centraliza el patrón que antes se repetía casi idéntico en el selector de
/// escenario del reproductor, el de estilo de visualizador y el de apariencia.
Future<T?> showOptionPicker<T extends Object>(
  BuildContext context, {
  required String title,
  required List<OptionPickerItem<T>> options,
  required T selected,
  String? helperText,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  builder: (context) => RadioGroup<T>(
    groupValue: selected,
    onChanged: (value) => Navigator.of(context).pop(value),
    child: SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: Tokens.space4),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              0,
              Tokens.gutter,
              Tokens.space2,
            ),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final option in options)
            RadioListTile<T>(
              value: option.value,
              secondary: Icon(option.icon),
              title: Text(option.label),
              subtitle: Text(option.description),
            ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.gutter,
                Tokens.space2,
                Tokens.gutter,
                0,
              ),
              child: Text(
                helperText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);
