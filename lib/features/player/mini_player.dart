import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/core/platform/engine_bridge.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/shared/widgets/cover_art.dart';

/// Mini reproductor persistente, encima de la navegacion inferior
/// (requerimiento seccion 12).
///
/// Solo aparece cuando hay una cancion cargada, y se puede arrastrar hacia los
/// lados para cambiar de pista.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  static const height = 68.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider);
    final song = state.currentSong;

    if (song == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(playbackProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/player'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: height - 3,
                child: Dismissible(
                  key: ValueKey('mini-${song.id}'),
                  // Arrastrar cambia de pista en lugar de descartar el widget.
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      controller.skipNext();
                    } else {
                      controller.skipPrevious();
                    }
                    return false;
                  },
                  background: const _SwipeHint(
                    icon: Icons.skip_previous_rounded,
                    alignment: Alignment.centerLeft,
                  ),
                  secondaryBackground: const _SwipeHint(
                    icon: Icons.skip_next_rounded,
                    alignment: Alignment.centerRight,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Hero(
                          tag: 'now-playing-cover-${song.id}',
                          child: CoverArt(
                            song: song,
                            size: 48,
                            borderRadius: 10,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.displayArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: controller.skipPrevious,
                        icon: const Icon(Icons.skip_previous_rounded),
                        tooltip: 'Anterior',
                      ),
                      IconButton(
                        onPressed: controller.togglePlayPause,
                        icon: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                        ),
                        tooltip: state.isPlaying ? 'Pausar' : 'Reproducir',
                      ),
                      IconButton(
                        onPressed: controller.skipNext,
                        icon: const Icon(Icons.skip_next_rounded),
                        tooltip: 'Siguiente',
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              const _MiniProgressBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playbackPositionProvider).valueOrNull;
    final duration = ref.watch(
      playbackProvider.select((state) => state.durationMs),
    );

    final progress = duration <= 0 || position == null
        ? 0.0
        : (position.positionMs / duration).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: progress,
      minHeight: 3,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.12),
    );
  }
}

/// Fondo revelado al arrastrar el mini reproductor. Antes el gesto de
/// cambiar de pista no tenia ninguna pista visual de que existiera, a
/// diferencia del deslizar-para-quitar de la cola.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.icon, required this.alignment});

  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: scheme.primaryContainer,
      child: Icon(icon, color: scheme.onPrimaryContainer),
    );
  }
}
