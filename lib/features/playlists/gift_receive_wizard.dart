import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/features/playlists/gift_auris.dart';
import 'package:nuvtune/features/playlists/gift_import_controller.dart';
import 'package:nuvtune/features/playlists/gift_payload.dart';

class GiftReceiveWizard extends ConsumerStatefulWidget {
  const GiftReceiveWizard({this.initialUri, super.key});

  final String? initialUri;

  @override
  ConsumerState<GiftReceiveWizard> createState() => _GiftReceiveWizardState();
}

class _GiftReceiveWizardState extends ConsumerState<GiftReceiveWizard> {
  int _revealStep = 0;
  bool _changedIdentityAccepted = false;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Recibir un regalo')),
      body: SafeArea(
        child: switch (state.stage) {
          GiftImportStage.idle => _PickStep(
            onPick: () => ref.read(giftImportProvider.notifier).pickAndLoad(),
          ),
          GiftImportStage.reading => const _BusyStep(
            message: 'Auris está comprobando el regalo…',
          ),
          GiftImportStage.reviewing => switch (_revealStep) {
            0 => _ArrivalStep(
              state: state,
              onOpen: () => setState(() => _revealStep = 1),
            ),
            1 => _DedicationRevealStep(
              payload: state.payload!,
              onBack: () => setState(() => _revealStep = 0),
              onContinue: () => setState(() => _revealStep = 2),
            ),
            _ => _ImportReviewStep(
              state: state,
              changedIdentityAccepted: _changedIdentityAccepted,
              onIdentityAccepted: (value) =>
                  setState(() => _changedIdentityAccepted = value),
              onBack: () => setState(() => _revealStep = 1),
              onImport: ref.read(giftImportProvider.notifier).completeImport,
            ),
          },
          GiftImportStage.importing => const _BusyStep(
            message: 'Guardando la música de forma segura…',
          ),
          GiftImportStage.done => _DoneStep(
            state: state,
            onOpen: () => context.pushReplacement(
              '/playlist/${state.playlistId}?from=gift-intro',
            ),
          ),
          GiftImportStage.failed => _FailedStep(
            message: state.error ?? 'No se pudo abrir el regalo',
            onRetry: () async {
              setState(() {
                _revealStep = 0;
                _changedIdentityAccepted = false;
              });
              await ref.read(giftImportProvider.notifier).pickAndLoad();
            },
          ),
        },
      ),
    );
  }
}

class _PickStep extends StatelessWidget {
  const _PickStep({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GiftAuris(
            size: 170,
            message:
                'Dame el archivo y te mostraré su historia antes de guardar nada.',
          ),
          const SizedBox(height: Tokens.space4),
          Text(
            '¿Te enviaron un regalo?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Tokens.space2),
          Text(
            'Elige el archivo .nuvtune-gift. Si llegó por WhatsApp, primero '
            'descárgalo desde el chat.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.space5),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Elegir regalo'),
          ),
        ],
      ),
    );
  }
}

class _ArrivalStep extends StatelessWidget {
  const _ArrivalStep({required this.state, required this.onOpen});

  final GiftImportState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final payload = state.payload!;
    final sender = (payload.from ?? '').isEmpty
        ? 'Alguien especial'
        : payload.from!;
    return _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GiftAuris(
            size: 190,
            message:
                'Encontré un regalo musical para ti. Ya comprobé que puede abrirse.',
          ),
          const SizedBox(height: Tokens.space4),
          Text(
            'De $sender',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if ((payload.to ?? '').isNotEmpty) ...[
            const SizedBox(height: Tokens.space1),
            Text(
              'Para ${payload.to}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: Tokens.space3),
          Text(
            '${state.totalSongs} canciones · ${Formatters.fileSize(state.sizeBytes)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Tokens.space3),
          _SecurityStatusCard(info: payload.security, sender: payload.from),
          const SizedBox(height: Tokens.space5),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Abrir con Auris'),
          ),
          const SizedBox(height: Tokens.space2),
          Text(
            'Todavía no se ha agregado nada a tu biblioteca.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DedicationRevealStep extends StatelessWidget {
  const _DedicationRevealStep({
    required this.payload,
    required this.onBack,
    required this.onContinue,
  });

  final GiftPayload payload;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final dedication = (payload.dedication ?? '').isEmpty
        ? 'Una selección hecha especialmente para ti.'
        : payload.dedication!;
    return _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GiftAuris(size: 115),
          const SizedBox(height: Tokens.space3),
          Text(
            payload.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Tokens.space4),
          Container(
            padding: const EdgeInsets.all(Tokens.space4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(Tokens.radiusXLarge),
            ),
            child: Text(
              '“$dedication”',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: Tokens.space5),
          Row(
            children: [
              TextButton(onPressed: onBack, child: const Text('Atrás')),
              const Spacer(),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.queue_music_rounded),
                label: const Text('Descubrir la música'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportReviewStep extends StatelessWidget {
  const _ImportReviewStep({
    required this.state,
    required this.changedIdentityAccepted,
    required this.onIdentityAccepted,
    required this.onBack,
    required this.onImport,
  });

  final GiftImportState state;
  final bool changedIdentityAccepted;
  final ValueChanged<bool> onIdentityAccepted;
  final VoidCallback onBack;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final payload = state.payload!;
    final theme = Theme.of(context);
    final changed =
        payload.security.signatureStatus == GiftSignatureStatus.signedChanged;
    final duplicate = state.existingPlaylistId != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space2,
            Tokens.gutter,
            Tokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(payload.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: Tokens.space2),
              Text(
                duplicate
                    ? 'Este regalo ya está en tu biblioteca.'
                    : state.hasEmbeddedAudio
                    ? '${state.totalSongs} canciones · ${state.foundCount} ya estaban en tu biblioteca'
                    : '${state.foundCount} de ${state.totalSongs} canciones encontradas',
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
              final alreadyHave = state.match!.resolved[index] != null;
              return ListTile(
                dense: true,
                leading: Icon(
                  alreadyHave
                      ? Icons.check_circle_rounded
                      : state.hasEmbeddedAudio
                      ? Icons.library_add_rounded
                      : Icons.help_outline_rounded,
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
        Container(
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space3,
            Tokens.gutter,
            Tokens.gutter,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (changed)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: changedIdentityAccepted,
                  onChanged: (value) => onIdentityAccepted(value ?? false),
                  title: const Text(
                    'Entiendo que cambió la firma del remitente',
                  ),
                  subtitle: const Text(
                    'Verifica con esa persona que reinstaló o cambió de teléfono.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                )
              else
                Text(
                  duplicate
                      ? 'No se copiará el audio ni se creará otra lista.'
                      : state.hasEmbeddedAudio
                      ? 'Solo se copiarán canciones que aún no estén en la biblioteca.'
                      : 'Es un regalo antiguo: solo se agregarán canciones que ya tengas.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: Tokens.space2),
              Row(
                children: [
                  TextButton(onPressed: onBack, child: const Text('Atrás')),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: changed && !changedIdentityAccepted
                        ? null
                        : onImport,
                    icon: Icon(
                      duplicate
                          ? Icons.open_in_new_rounded
                          : Icons.library_add_check_rounded,
                    ),
                    label: Text(
                      duplicate
                          ? 'Abrir el que ya tienes'
                          : 'Guardar en mi biblioteca',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard({required this.info, required this.sender});

  final GiftSecurityInfo info;
  final String? sender;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, title, detail, color) = switch (info.signatureStatus) {
      GiftSignatureStatus.signedKnown => (
        Icons.verified_user_rounded,
        'Firma válida · dispositivo reconocido',
        'Coincide con regalos anteriores de ${_senderName(sender)}.',
        const Color(0xFF69D39A),
      ),
      GiftSignatureStatus.signedNew => (
        Icons.verified_rounded,
        'Firma válida · remitente nuevo',
        'El archivo está intacto. Confirma la persona por el chat si no lo esperabas.',
        scheme.primary,
      ),
      GiftSignatureStatus.signedChanged => (
        Icons.gpp_maybe_rounded,
        'La identidad del remitente cambió',
        'Puede ser una reinstalación o un teléfono nuevo. Confírmalo antes de importar.',
        scheme.error,
      ),
      GiftSignatureStatus.legacyUnsigned => (
        Icons.shield_outlined,
        'Regalo antiguo sin firma',
        'NuvTune validó su estructura, pero no puede confirmar que siga intacto.',
        scheme.tertiary,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: Tokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: color),
                ),
                const SizedBox(height: Tokens.space1),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
                if (info.fingerprint case final fingerprint?) ...[
                  const SizedBox(height: Tokens.space1),
                  Text(
                    'Huella $fingerprint',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _senderName(String? value) =>
      (value ?? '').isEmpty ? 'este dispositivo' : value!;
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.state, required this.onOpen});

  final GiftImportState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final duplicate = state.existingPlaylistId != null;
    return _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GiftAuris(
            size: 185,
            celebrate: true,
            message: duplicate
                ? 'Este regalo ya estaba a salvo en tu biblioteca.'
                : state.addedCount > 0
                ? 'Guardé ${state.addedCount} canciones nuevas. Ya puedes disfrutarlo.'
                : 'Todo estaba listo. Tu regalo ya puede escucharse.',
          ),
          const SizedBox(height: Tokens.space5),
          FilledButton.icon(
            onPressed: state.playlistId == null ? null : onOpen,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Abrir mi regalo'),
          ),
        ],
      ),
    );
  }
}

class _FailedStep extends StatelessWidget {
  const _FailedStep({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.gpp_bad_rounded, size: 68, color: Color(0xFFFF7085)),
          const SizedBox(height: Tokens.space4),
          Text(
            'Auris detuvo este regalo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Tokens.space2),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: Tokens.space2),
          Text(
            'No se importó ni reprodujo ningún archivo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Tokens.space5),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Elegir otro archivo'),
          ),
        ],
      ),
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
          const GiftAuris(size: 120),
          const SizedBox(height: Tokens.space3),
          const CircularProgressIndicator(),
          const SizedBox(height: Tokens.space3),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CenteredStep extends StatelessWidget {
  const _CenteredStep({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.sizeOf(context).height -
              kToolbarHeight -
              MediaQuery.paddingOf(context).vertical -
              Tokens.gutter * 2,
        ),
        child: Center(child: child),
      ),
    );
  }
}
