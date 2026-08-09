import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/gift_intent_service.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/playlists/gift_auris.dart';
import 'package:nuvtune/features/playlists/gift_payload.dart';
import 'package:nuvtune/shared/widgets/accent_picker.dart';

Future<void> showGiftSendWizard(
  BuildContext context, {
  required Playlist playlist,
}) => Navigator.of(context).push<void>(
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
  static const _lastStep = 3;

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _dedicationController;
  late String _accentId;

  int _step = 0;
  bool _sharing = false;
  bool _sharePanelOpened = false;
  List<Song> _songs = const [];
  Set<int> _selectedIds = const {};
  GiftShareChannel _channel = GiftShareChannel.whatsApp;

  List<Song> get _selectedSongs =>
      _songs.where((song) => _selectedIds.contains(song.id)).toList();

  int get _totalBytes =>
      _selectedSongs.fold(0, (total, song) => total + song.sizeBytes);

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(
      text: widget.playlist.giftFrom ?? '',
    );
    _toController = TextEditingController(text: widget.playlist.giftTo ?? '');
    _dedicationController = TextEditingController(
      text: widget.playlist.dedication ?? '',
    );
    _accentId = widget.playlist.giftAccentId ?? AccentIdentity.nebula.id;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final ids = await ref
        .read(playlistRepositoryProvider)
        .songIds(widget.playlist.id);
    if (!mounted) return;
    final songs = ref.read(libraryRepositoryProvider).songsByIds(ids);
    setState(() {
      _songs = songs;
      _selectedIds = songs.map((song) => song.id).toSet();
    });
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
    if (_sharePanelOpened) {
      return Scaffold(
        appBar: AppBar(title: const Text('Regalo preparado')),
        body: SafeArea(
          child: _PreparedStep(
            channel: _channel,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final selected = _selectedSongs;
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear regalo · ${_step + 1} de ${_lastStep + 1}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepDots(current: _step, total: _lastStep + 1),
            Expanded(
              child: switch (_step) {
                0 => _SongsStep(
                  songs: _songs,
                  selectedIds: _selectedIds,
                  onChanged: (songId, selected) => setState(() {
                    final next = {..._selectedIds};
                    selected ? next.add(songId) : next.remove(songId);
                    _selectedIds = next;
                  }),
                ),
                1 => _DedicationStep(
                  fromController: _fromController,
                  toController: _toController,
                  dedicationController: _dedicationController,
                  accentId: _accentId,
                  onAccent: (identity) =>
                      setState(() => _accentId = identity.id),
                ),
                2 => _SummaryStep(
                  playlistName: widget.playlist.name,
                  songCount: selected.length,
                  totalBytes: _totalBytes,
                  from: _fromController.text.trim(),
                  to: _toController.text.trim(),
                  dedication: _dedicationController.text.trim(),
                ),
                _ => _ChannelStep(
                  channel: _channel,
                  onChanged: (value) => setState(() => _channel = value),
                ),
              },
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.gutter),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _sharing
                          ? null
                          : () => setState(() => _step--),
                      child: const Text('Atrás'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _sharing || (_step == 0 && selected.isEmpty)
                        ? null
                        : () {
                            if (_step < _lastStep) {
                              setState(() => _step++);
                            } else {
                              _share(selected);
                            }
                          },
                    icon: _sharing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _step < _lastStep
                                ? Icons.arrow_forward_rounded
                                : (_channel == GiftShareChannel.whatsApp
                                      ? Icons.chat_rounded
                                      : Icons.mail_rounded),
                          ),
                    label: Text(
                      _sharing
                          ? 'Firmando…'
                          : (_step < _lastStep
                                ? 'Continuar'
                                : _channel == GiftShareChannel.whatsApp
                                ? 'Enviar por WhatsApp'
                                : 'Enviar por correo'),
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      final from = _fromController.text.trim();
      final to = _toController.text.trim();
      final dedication = _dedicationController.text.trim();

      await ref
          .read(playlistRepositoryProvider)
          .setGift(
            widget.playlist.id,
            giftMode: true,
            dedication: dedication.isEmpty ? null : dedication,
            giftFrom: from.isEmpty ? null : from,
            giftTo: to.isEmpty ? null : to,
            giftAccentId: _accentId,
          );

      final payload = GiftPayload.create(
        name: widget.playlist.name,
        dedication: dedication.isEmpty ? null : dedication,
        from: from.isEmpty ? null : from,
        to: to.isEmpty ? null : to,
        accentId: _accentId,
        songs: [
          for (final song in songs)
            GiftSong(title: song.title, artist: song.artist, album: song.album),
        ],
      );
      final shortId = payload.giftId!.substring(0, 8);
      final path = await ref.read(engineProvider).api.createGiftPackage(
        'NuvTune-Regalo-$shortId.nuvtune-gift',
        payload.encode(),
        [for (final song in songs) song.id],
      );

      await const GiftIntentService().shareGift(
        path: path,
        channel: _channel,
        subject: 'Un regalo de NuvTune: ${widget.playlist.name}',
        text: to.isEmpty
            ? 'Te envié un regalo musical de NuvTune.'
            : '$to, te envié un regalo musical de NuvTune.',
      );
      if (!mounted) return;
      setState(() {
        _sharing = false;
        _sharePanelOpened = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo preparar el regalo')),
      );
    }
  }
}

class _SongsStep extends StatelessWidget {
  const _SongsStep({
    required this.songs,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<Song> songs;
  final Set<int> selectedIds;
  final void Function(int songId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space2,
            Tokens.gutter,
            Tokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elige la música', style: theme.textTheme.titleLarge),
              const SizedBox(height: Tokens.space1),
              Text(
                '${selectedIds.length} de ${songs.length} canciones · el audio viajará dentro del regalo.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: songs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final selected = selectedIds.contains(song.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) => onChanged(song.id, value ?? false),
                      secondary: const Icon(Icons.music_note_rounded),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

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
          const Center(
            child: GiftAuris(
              size: 105,
              message: 'Yo cuidaré la dedicatoria hasta que la abran.',
            ),
          ),
          const SizedBox(height: Tokens.space4),
          TextField(
            controller: fromController,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'De'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: Tokens.space2),
          TextField(
            controller: toController,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Para'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: Tokens.space2),
          TextField(
            controller: dedicationController,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Dedicatoria'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: Tokens.space3),
          Text(
            'Color del regalo',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: Tokens.space3),
          AccentSwatchGrid(selected: accentId, onSelected: onAccent),
        ],
      ),
    );
  }
}

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 54,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: Tokens.space3),
          Text(
            playlistName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: Tokens.space5),
          const _SecurityCard(),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded),
          SizedBox(width: Tokens.space3),
          Expanded(
            child: Text(
              'NuvTune firmará la dedicatoria y cada archivo de audio. Si '
              'alguien modifica el regalo durante el envío, el receptor no '
              'podrá importarlo.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelStep extends StatelessWidget {
  const _ChannelStep({required this.channel, required this.onChanged});

  final GiftShareChannel channel;
  final ValueChanged<GiftShareChannel> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Tokens.gutter),
      children: [
        Text(
          '¿Cómo quieres enviarlo?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Tokens.space1),
        Text(
          'Se comparte como un único archivo. La música no se sube a servidores de NuvTune.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Tokens.space4),
        _ChannelCard(
          selected: channel == GiftShareChannel.whatsApp,
          icon: Icons.chat_rounded,
          title: 'WhatsApp',
          badge: 'Recomendado',
          description:
              'Abre WhatsApp directamente y conserva el regalo como documento.',
          onTap: () => onChanged(GiftShareChannel.whatsApp),
        ),
        const SizedBox(height: Tokens.space3),
        _ChannelCard(
          selected: channel == GiftShareChannel.email,
          icon: Icons.mail_rounded,
          title: 'Correo',
          description:
              'Úsalo solo si el tamaño cabe en el límite de adjuntos de tu proveedor.',
          warning: true,
          onTap: () => onChanged(GiftShareChannel.email),
        ),
        const SizedBox(height: Tokens.space4),
        Text(
          'El permiso de lectura es temporal y de solo lectura. NuvTune no '
          'puede confirmar la entrega: eso lo indica WhatsApp o tu correo.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
    this.warning = false,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? badge;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = warning ? scheme.tertiary : scheme.primary;
    return Material(
      color: selected
          ? color.withValues(alpha: 0.15)
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Tokens.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(Tokens.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radiusLarge),
            border: Border.all(
              color: selected ? color : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (badge case final label?) ...[
                          const SizedBox(width: Tokens.space2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(
                                Tokens.radiusPill,
                              ),
                            ),
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Tokens.space1),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? color : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreparedStep extends StatelessWidget {
  const _PreparedStep({required this.channel, required this.onClose});

  final GiftShareChannel channel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GiftAuris(
            size: 180,
            celebrate: true,
            message:
                'El regalo está firmado y listo. Ahora tú eliges a quién entregarlo.',
          ),
          const SizedBox(height: Tokens.space5),
          Text(
            channel == GiftShareChannel.whatsApp
                ? 'Abrí WhatsApp con el regalo adjunto.'
                : 'Abrí el panel para elegir tu aplicación de correo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Tokens.space2),
          Text(
            'Comprueba el destinatario antes de pulsar Enviar. NuvTune no '
            'marca el regalo como entregado hasta que la otra aplicación lo haga.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Tokens.space5),
          FilledButton(onPressed: onClose, child: const Text('Terminar')),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Paso ${current + 1} de $total',
      child: Padding(
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
      ),
    );
  }
}
