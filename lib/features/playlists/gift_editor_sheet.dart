import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/shared/widgets/accent_picker.dart';

/// Bottom sheet para convertir una lista en regalo o editar su dedicatoria
/// (idea de la novia del usuario: "una lista de canciones para mí").
Future<void> showGiftEditor(
  BuildContext context, {
  required Playlist playlist,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _GiftEditorSheet(playlist: playlist),
);

class _GiftEditorSheet extends ConsumerStatefulWidget {
  const _GiftEditorSheet({required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<_GiftEditorSheet> createState() => _GiftEditorSheetState();
}

class _GiftEditorSheetState extends ConsumerState<_GiftEditorSheet> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _dedicationController;
  late String _accentId;

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
    final isGift = widget.playlist.giftMode;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            Tokens.space4,
            Tokens.gutter,
            Tokens.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isGift ? 'Editar regalo' : 'Convertir en regalo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Tokens.space2),
              Text(
                'Presenta esta lista con una dedicatoria antes de reproducirla.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Tokens.space4),
              TextField(
                controller: _fromController,
                decoration: const InputDecoration(labelText: 'De'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: Tokens.space3),
              TextField(
                controller: _toController,
                decoration: const InputDecoration(labelText: 'Para'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: Tokens.space3),
              TextField(
                controller: _dedicationController,
                decoration: const InputDecoration(labelText: 'Dedicatoria'),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: Tokens.space4),
              Text(
                'Color del regalo',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: Tokens.space3),
              AccentSwatchGrid(
                selected: _accentId,
                onSelected: (identity) =>
                    setState(() => _accentId = identity.id),
              ),
              const SizedBox(height: Tokens.space5),
              Row(
                children: [
                  if (isGift)
                    TextButton(
                      onPressed: () => _save(giftMode: false),
                      child: const Text('Quitar modo regalo'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: Tokens.space2),
                  FilledButton(
                    onPressed: () => _save(giftMode: true),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save({required bool giftMode}) async {
    final navigator = Navigator.of(context);
    await ref
        .read(playlistRepositoryProvider)
        .setGift(
          widget.playlist.id,
          giftMode: giftMode,
          dedication: _dedicationController.text.trim().isEmpty
              ? null
              : _dedicationController.text.trim(),
          giftFrom: _fromController.text.trim().isEmpty
              ? null
              : _fromController.text.trim(),
          giftTo: _toController.text.trim().isEmpty
              ? null
              : _toController.text.trim(),
          giftAccentId: giftMode ? _accentId : null,
        );
    navigator.pop();
  }
}
