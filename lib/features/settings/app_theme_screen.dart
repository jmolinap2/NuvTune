import 'package:flutter/material.dart';
import 'package:nuvtune/features/settings/appearance_screen.dart';

/// Apariencia de la app: la identidad visual y nada más.
///
/// Vive en su propia pantalla y no como pestaña de «Personalización» porque
/// mezclar el tema global con la edición del reproductor obligaba a entender
/// que dos cosas de alcance distinto compartían sitio. El tema afecta a toda
/// la aplicación; el escenario, el visualizador y los controles solo afectan
/// al reproductor.
class AppThemeScreen extends StatelessWidget {
  const AppThemeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Apariencia de la app'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Controla la identidad visual de toda la aplicación.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    ),
    body: const AppThemePanel(),
  );
}
