import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/playlists/gift_import_controller.dart';

/// Asistente guiado para recibir un regalo, de punta a punta: elegir el
/// archivo, ver que trae y que falta ANTES de importar nada, recuperar de
/// internet lo que el receptor no tenga, y entregar la lista lista para
/// escuchar.
///
/// Sustituye a la funcion unica que habia antes (un icono en la barra de
/// Listas que importaba en silencio y descartaba sin aviso todo lo que no
/// estuviera ya en la biblioteca).
class GiftReceiveWizard extends ConsumerStatefulWidget {
  const GiftReceiveWizard({this.initialUri, super.key});

  /// Uri del archivo cuando el regalo llega desde otra aplicacion
  /// (`ACTION_SEND`/`ACTION_VIEW`), en vez de elegirse a mano.
  final String? initialUri;

  @override
  ConsumerState<GiftReceiveWizard> createState() => _GiftReceiveWizardState();
}

class _GiftReceiveWizardState extends ConsumerState<GiftReceiveWizard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(giftImportProvider.notifier);
      controller.reset();
      final uri = widget.initialUri;
      if (uri != null) controller.loadFromUri(uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(giftImportProvider);

    // Al terminar, se reemplaza el asistente por la portada del regalo: no
    // tiene sentido poder volver "atras" a un asistente ya consumido.
    ref.listen(giftImportProvider, (previous, next) {
      if (next.stage == GiftImportStage.done && next.playlistId != null) {
        context.pushReplacement('/playlist/${next.playlistId}/gift');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Recibir un regalo')),
      body: SafeArea(
        child: switch (state.stage) {
          GiftImportStage.idle => _PickStep(
              onPick: () => ref.read(giftImportProvider.notifier).pickAndLoad(),
            ),
          GiftImportStage.reading =>
            const _BusyStep(message: 'Abriendo el regalo…'),
          GiftImportStage.reviewing => _ReviewStep(state: state),
          GiftImportStage.importing => const _BusyStep(
              message: 'Guardando la música en tu biblioteca…',
            ),
          GiftImportStage.done => const _BusyStep(message: 'Listo'),
          GiftImportStage.failed => _FailedStep(
              message: state.error ?? 'No se pudo abrir el regalo',
              onRetry: () =>
                  ref.read(giftImportProvider.notifier).pickAndLoad(),
            ),
        },
      ),
    );
  }
}

/// Paso 1: elegir el archivo.
class _PickStep extends StatelessWidget {
  const _PickStep({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.card_giftcard_rounded,
      title: '¿Te enviaron un regalo?',
      body: 'Elige el archivo .nuvtune-gift que recibiste. Te mostraré qué '
          'canciones trae antes de agregar nada.\n\n'
          'Si llegó por WhatsApp, tócalo primero en el chat para descargarlo: '
          'queda guardado en Documentos de WhatsApp.',
      primaryLabel: 'Elegir archivo',
      onPrimary: onPick,
    );
  }
}

/// Paso 2: que trae el regalo. Es el paso que antes no existia: el usuario ve
/// el contenido completo antes de que se toque su biblioteca.
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.state});

  final GiftImportState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = state.payload!;
    final theme = Theme.of(context);
    final controller = ref.read(giftImportProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(payload.name, style: theme.textTheme.headlineSmall),
              if ((payload.from ?? '').isNotEmpty) ...[
                const SizedBox(height: Tokens.space1),
                Text(
                  'De ${payload.from}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if ((payload.dedication ?? '').isNotEmpty) ...[
                const SizedBox(height: Tokens.space3),
                Text(
                  '“${payload.dedication}”',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: Tokens.space3),
              Text(
                state.hasEmbeddedAudio
                    ? '${state.totalSongs} canciones · '
                        '${Formatters.fileSize(state.sizeBytes)} de música incluida'
                    : '${state.totalSongs} canciones',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: payload.songs.length,
            itemBuilder: (context, index) {
              final song = payload.songs[index];
              // Con audio incluido no hay nada "faltante": el regalo se basta
              // solo. El icono solo distingue lo que ya estaba en la
              // biblioteca de lo que va a entrar nuevo.
              final alreadyHave = state.match!.resolved[index] != null;
              return ListTile(
                dense: true,
                leading: Icon(
                  state.hasEmbeddedAudio
                      ? (alreadyHave
                          ? Icons.check_circle_rounded
                          : Icons.library_add_rounded)
                      : (alreadyHave
                          ? Icons.check_circle_rounded
                          : Icons.help_outline_rounded),
                  color: alreadyHave
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist.isEmpty ? 'Artista desconocido' : song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
        _StepActions(
          helper: state.hasEmbeddedAudio
              ? 'La música viene dentro del regalo: se guardará en tu '
                  'biblioteca tal como te la enviaron.'
              : 'Este regalo es de una versión antigua y solo trae los '
                  'títulos. Se añadirán las ${state.foundCount} canciones que '
                  'ya tienes.',
          primaryLabel: state.hasEmbeddedAudio
              ? 'Guardar y abrir el regalo'
              : 'Abrir el regalo',
          onPrimary: controller.completeImport,
        ),
      ],
    );
  }
}

class _FailedStep extends StatelessWidget {
  const _FailedStep({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.error_outline_rounded,
      title: 'No se pudo abrir el regalo',
      body: message,
      primaryLabel: 'Elegir otro archivo',
      onPrimary: onRetry,
    );
  }
}

class _BusyStep extends StatelessWidget {
  const _BusyStep({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Tokens.space4),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

}

/// Pantalla de un solo mensaje con una accion, para los pasos que no son una
/// lista (elegir archivo, error).
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: Tokens.space5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Tokens.space3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.space6),
          FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ],
      ),
    );
  }
}

/// Barra de acciones fija al pie de un paso, con su texto de ayuda.
class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.helper,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String helper;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            helper,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.space3),
          FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ],
      ),
    );
  }
}
