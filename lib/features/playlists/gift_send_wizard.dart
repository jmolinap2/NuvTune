
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/playlists/gift_payload.dart';
import 'package:nuvtune/shared/widgets/accent_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Asistente guiado para regalar una lista: repasar las canciones, escribir
/// la dedicatoria y compartir, con los pasos a la vista.
///
/// Sustituye al par de acciones sueltas que habia antes ("Convertir en
/// regalo…" y "Compartir regalo", perdidas entre otras diez opciones del menu
/// de la lista, sin ninguna relacion visible entre si).
Future<void> showGiftSendWizard(
  BuildContext context, {
  required Playlist playlist,
}) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => GiftSendWizard(playlist: playlist),
        fullscreenDialog: true,
      ),
    );

class GiftSendWizard extends ConsumerStatefulWidget {
  const GiftSendWizard({required this.playlist, super.key});

  final Playlist playlist;

  @override
  ConsumerState<GiftSendWizard> createState() => _GiftSendWizardState();
}

class _GiftSendWizardState extends ConsumerState<GiftSendWizard> {
  static const _lastStep = 2;

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _dedicationController;
  late String _accentId;

  int _step = 0;
  bool _sharing = false;
  List<Song> _songs = const [];

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.playlist.giftFrom ?? '');
    _toController = TextEditingController(text: widget.playlist.giftTo ?? '');
    _dedicationController =
        TextEditingController(text: widget.playlist.dedication ?? '');
    _accentId = widget.playlist.giftAccentId ?? AccentIdentity.nebula.id;
    _loadSongs();
  }

  /// Peso aproximado del regalo: la suma de los archivos que van dentro. Se
  /// muestra antes de enviar porque un regalo con audio pesa de verdad y el
  /// usuario tiene que poder decidir con ese dato a la vista.
  int get _totalBytes =>
      _songs.fold(0, (total, song) => total + song.sizeBytes);

  Future<void> _loadSongs() async {
    final ids =
        await ref.read(playlistRepositoryProvider).songIds(widget.playlist.id);
    if (!mounted) return;
    setState(() => _songs = ref.read(libraryRepositoryProvider).songsByIds(ids));
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dedicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = _songs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Regalar · paso ${_step + 1} de ${_lastStep + 1}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepDots(current: _step, total: _lastStep + 1),
            Expanded(
              child: switch (_step) {
                0 => _SongsStep(songs: songs),
                1 => _DedicationStep(
                    fromController: _fromController,
                    toController: _toController,
                    dedicationController: _dedicationController,
                    accentId: _accentId,
                    onAccent: (identity) =>
                        setState(() => _accentId = identity.id),
                  ),
                _ => _SummaryStep(
                    playlistName: widget.playlist.name,
                    songCount: songs.length,
                    totalBytes: _totalBytes,
                    from: _fromController.text.trim(),
                    to: _toController.text.trim(),
                    dedication: _dedicationController.text.trim(),
                  ),
              },
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.gutter),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Atrás'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _sharing
                        ? null
                        : () {
                            if (_step < _lastStep) {
                              setState(() => _step++);
                            } else {
                              _share(songs);
                            }
                          },
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _step < _lastStep
                                ? Icons.arrow_forward_rounded
                                : Icons.card_giftcard_rounded,
                          ),
                    label: Text(
                      _sharing
                          ? 'Preparando…'
                          : (_step < _lastStep ? 'Continuar' : 'Enviar regalo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(List<Song> songs) async {
    setState(() => _sharing = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final from = _fromController.text.trim();
      final to = _toController.text.trim();
      final dedication = _dedicationController.text.trim();

      // El regalo se guarda tambien en la lista de origen: asi el emisor
      // conserva la dedicatoria que escribio y puede volver a enviarla sin
      // reescribirla.
      await ref.read(playlistRepositoryProvider).setGift(
            widget.playlist.id,
            giftMode: true,
            dedication: dedication.isEmpty ? null : dedication,
            giftFrom: from.isEmpty ? null : from,
            giftTo: to.isEmpty ? null : to,
            giftAccentId: _accentId,
          );

      final payload = GiftPayload(
        name: widget.playlist.name,
        dedication: dedication.isEmpty ? null : dedication,
        from: from.isEmpty ? null : from,
        to: to.isEmpty ? null : to,
        accentId: _accentId,
        songs: [
          for (final song in songs)
            GiftSong(
              title: song.title,
              artist: song.artist,
              album: song.album,
            ),
        ],
      );

      // El empaquetado lo hace el motor nativo: el audio se copia dentro del
      // archivo leyendolo de MediaStore, sin pasar decenas de megabytes por
      // el canal de plataforma.
      final safeName =
          widget.playlist.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final path = await ref.read(engineProvider).api.createGiftPackage(
            '${safeName.isEmpty ? 'regalo' : safeName}.nuvtune-gift',
            payload.encode(),
            [for (final song in songs) song.id],
          );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: widget.playlist.name,
          text: to.isEmpty
              ? 'Te regalo esta playlist: ${widget.playlist.name}'
              : '$to, te regalo esta playlist: ${widget.playlist.name}',
        ),
      );
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo preparar el regalo')),
      );
    }
  }
}

/// Paso 1: que canciones van dentro.
class _SongsStep extends StatelessWidget {
  const _SongsStep({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space3,
            Tokens.gutter,
            Tokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vas a regalar ${songs.length} canciones',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: Tokens.space1),
              Text(
                'La música va dentro del regalo: quien lo reciba las escucha '
                'tal cual, sin buscar nada ni necesitar internet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) => ListTile(
              dense: true,
              leading: const Icon(Icons.music_note_rounded),
              title: Text(
                songs[index].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                songs[index].artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paso 2: la dedicatoria (los mismos campos del editor de regalo anterior).
class _DedicationStep extends StatelessWidget {
  const _DedicationStep({
    required this.fromController,
    required this.toController,
    required this.dedicationController,
    required this.accentId,
    required this.onAccent,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController dedicationController;
  final String accentId;
  final ValueChanged<AccentIdentity> onAccent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dedícalo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Tokens.space1),
          Text(
            'Esto es lo primero que verá al abrirlo. Puedes dejarlo vacío.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: Tokens.space4),
          TextField(
            controller: fromController,
            decoration: const InputDecoration(labelText: 'De'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: Tokens.space3),
          TextField(
            controller: toController,
            decoration: const InputDecoration(labelText: 'Para'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: Tokens.space3),
          TextField(
            controller: dedicationController,
            decoration: const InputDecoration(labelText: 'Dedicatoria'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: Tokens.space4),
          Text('Color del regalo',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Tokens.space3),
          AccentSwatchGrid(selected: accentId, onSelected: onAccent),
        ],
      ),
    );
  }
}

/// Paso 3: repaso antes de enviar.
class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.playlistName,
    required this.songCount,
    required this.totalBytes,
    required this.from,
    required this.to,
    required this.dedication,
  });

  final String playlistName;
  final int songCount;
  final int totalBytes;
  final String from;
  final String to;
  final String dedication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.card_giftcard_rounded,
              size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: Tokens.space4),
          Text(playlistName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: Tokens.space2),
          Text(
            [
              '$songCount canciones',
              Formatters.fileSize(totalBytes),
              if (from.isNotEmpty) 'De $from',
              if (to.isNotEmpty) 'Para $to',
            ].join(' · '),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (dedication.isNotEmpty) ...[
            const SizedBox(height: Tokens.space4),
            Text(
              '“$dedication”',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const Spacer(),
          Text(
            'Se enviará un solo archivo con la música adentro. Quien lo '
            'reciba solo tiene que tocarlo para abrirlo en NuvTune.\n'
            'Prepararlo puede tardar un momento por el peso.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de paso: la pista visual que pedia el usuario ("wizards guiados,
/// como los juegos que te guian a los botones o acciones").
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < total; index++)
            AnimatedContainer(
              duration: Tokens.durationFast,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index <= current
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Tokens.radiusPill),
              ),
            ),
        ],
      ),
    );
  }
}
