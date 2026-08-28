import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';

/// Pantalla de dedicatoria que se muestra al abrir una playlist regalo, antes
/// del detalle normal (idea del usuario: "una lista de canciones para mí").
class GiftIntroScreen extends ConsumerWidget {
  const GiftIntroScreen({required this.playlistId, super.key});

  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final playlist = playlists
        .where((item) => item.id == playlistId)
        .firstOrNull;

    if (playlist == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final accent = AccentIdentity.byId(
      playlist.giftAccentId ?? AccentIdentity.nebula.id,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.start, accent.middle, accent.end],
          ),
        ),
        child: SafeArea(child: _GiftIntroBody(playlist: playlist)),
      ),
    );
  }
}

class _GiftIntroBody extends StatefulWidget {
  const _GiftIntroBody({required this.playlist});

  final Playlist playlist;

  @override
  State<_GiftIntroBody> createState() => _GiftIntroBodyState();
}

class _GiftIntroBodyState extends State<_GiftIntroBody> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final hasFrom = (playlist.giftFrom ?? '').trim().isNotEmpty;
    final hasTo = (playlist.giftTo ?? '').trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(Tokens.gutter),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: Tokens.durationSlow,
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, 0.08),
              duration: Tokens.durationSlow,
              curve: Curves.easeOut,
              child: Column(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                  const SizedBox(height: Tokens.space5),
                  if (hasFrom || hasTo)
                    Text(
                      [
                        if (hasFrom) 'De ${playlist.giftFrom}',
                        if (hasTo) 'Para ${playlist.giftTo}',
                      ].join(' — '),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: Tokens.space3),
                  Text(
                    playlist.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((playlist.dedication ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: Tokens.space4),
                    Text(
                      playlist.dedication!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: Tokens.durationSlow,
            curve: Curves.easeOut,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: Tokens.space4),
                ),
                onPressed: () =>
                    context.go('/playlist/${playlist.id}?from=gift-intro'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Reproducir'),
              ),
            ),
          ),
          const SizedBox(height: Tokens.space3),
        ],
      ),
    );
  }
}
