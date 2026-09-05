import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nuvtune/app/localization/strings.dart';

/// Confirmacion para una accion destructiva e irreversible.
///
/// Centraliza el patron de dialogo que antes se repetia por separado en cada
/// pantalla (eliminar cancion, eliminar lista): titulo, mensaje, boton rojo
/// de confirmacion con vibracion y boton de cancelar. Devuelve `true` solo si
/// se confirmo.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = AppStrings.delete,
  String cancelLabel = AppStrings.cancel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(dialogContext).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
