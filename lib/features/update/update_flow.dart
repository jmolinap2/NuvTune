import 'package:flutter/material.dart';
import 'package:nuvtune/core/update/app_updater.dart';

/// Comprueba si hay una version nueva y, si la hay, ofrece instalarla.
///
/// Con [manual] falso (arranque de la app) solo habla cuando hay algo nuevo:
/// sin internet o al dia no molesta. Con [manual] verdadero (Ajustes) siempre
/// responde.
Future<void> checkForUpdates(
  BuildContext context, {
  required bool manual,
}) async {
  final updater = AppUpdater();
  final result = await updater.check();
  if (!context.mounted) return;

  switch (result) {
    case UpdateAvailable(:final info):
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UpdateDialog(updater: updater, info: info),
      );
    case UpToDate():
      if (manual) _toast(context, 'NuvTune está al día');
    case CheckFailed(:final reason):
      if (manual) _toast(context, reason);
  }
}

void _toast(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.updater, required this.info});

  final AppUpdater updater;
  final UpdateInfo info;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _start() async {
    final updater = widget.updater;
    if (!await updater.canInstall()) {
      // Android exige este permiso una vez; al volver, el usuario toca de nuevo.
      await updater.openInstallSettings();
      setState(
        () => _error =
            'Permite instalar desde NuvTune y vuelve a pulsar Actualizar.',
      );
      return;
    }
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final apk = await updater.download(
        widget.info,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      await updater.install(apk);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final megabytes = (info.bytes / (1024 * 1024)).toStringAsFixed(0);
    final downloading = _progress != null;
    return AlertDialog(
      title: const Text('Actualización disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${info.name} (compilación ${info.build}) · $megabytes MB'),
          const SizedBox(height: 8),
          Text(info.message),
          if (downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('Más tarde'),
        ),
        FilledButton(
          onPressed: downloading ? null : _start,
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}
