import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_visual_scene.dart';
import 'package:nuvtune/features/player/visualizer_style.dart';
import 'package:nuvtune/features/lyrics/lyrics_animation_style.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

Future<void> showVisualizationPicker(
  BuildContext context,
  WidgetRef ref, {
  Future<void> Function(PlayerVisualScene scene)? onOpenFullscreen,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) =>
      _VisualizationPickerSheet(onOpenFullscreen: onOpenFullscreen),
);

class _VisualizationPickerSheet extends ConsumerWidget {
  const _VisualizationPickerSheet({this.onOpenFullscreen});

  final Future<void> Function(PlayerVisualScene scene)? onOpenFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    final scene = PlayerVisualScene.fromIndex(settings.playerVisualScene);
    final style = VisualizerStyle.fromIndex(settings.playerVisualizerStyle);
    final mutation = ref.read(settingsMutationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: scene.showsVisualizer ? 0.86 : 0.64,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            Tokens.gutter,
            0,
            Tokens.gutter,
            Tokens.space5,
          ),
          children: [
            Text(
              'Visualización del reproductor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Tokens.space1),
            Text(
              'Primero elige qué ocupa el escenario. Las opciones que dependan de esa escena aparecerán después.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Tokens.space4),
            if (onOpenFullscreen != null) ...[
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onOpenFullscreen!(scene);
                },
                icon: const Icon(Icons.fullscreen_rounded),
                label: Text('Abrir ${scene.label} en pantalla completa'),
              ),
              const SizedBox(height: Tokens.space4),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: Tokens.space2,
                mainAxisSpacing: Tokens.space2,
              ),
              itemCount: PlayerVisualScene.values.length,
              itemBuilder: (context, index) {
                final option = PlayerVisualScene.values[index];
                return _SceneCard(
                  scene: option,
                  selected: scene == option,
                  onTap: () => mutation.save(
                    AppSettingsCompanion(
                      playerVisualScene: Value(option.index),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: Tokens.space5),
            if (scene.showsVisualizer) ...[
              Text(
                'Estilo del visualizador',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Tokens.space1),
              Text(
                'El color y la energía se ajustan aparte en Personalización → Movimiento.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: Tokens.space3),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: Tokens.space2,
                  mainAxisSpacing: Tokens.space2,
                ),
                itemCount: VisualizerStyle.values.length,
                itemBuilder: (context, index) {
                  final option = VisualizerStyle.values[index];
                  return _StyleCard(
                    style: option,
                    selected: style == option,
                    onTap: () => mutation.save(
                      AppSettingsCompanion(
                        playerVisualizerStyle: Value(option.index),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: Tokens.space3),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.casino_outlined),
                title: const Text('Colores aleatorios'),
                subtitle: const Text(
                  'Cambios fluidos de paleta, sin parpadeos bruscos.',
                ),
                value: settings.visualizerRandomColors,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(visualizerRandomColors: Value(value)),
                ),
              ),
            ] else
              _DependencyMessage(scene: scene),
            if (scene.showsLyrics) ...[
              const SizedBox(height: Tokens.space5),
              Text(
                'Animación de letras',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Tokens.space2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  LyricsAnimationStyle.byId(settings.lyricsAnimationStyle).icon,
                ),
                title: Text(
                  LyricsAnimationStyle.byId(
                    settings.lyricsAnimationStyle,
                  ).label,
                ),
                subtitle: Text(
                  LyricsAnimationStyle.byId(
                    settings.lyricsAnimationStyle,
                  ).description,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLyricsAnimationStylePicker(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.selected,
    required this.onTap,
  });

  final PlayerVisualScene scene;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${scene.label}. ${scene.description}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
        child: Ink(
          padding: const EdgeInsets.all(Tokens.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radiusMedium),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: selected ? 0.22 : 0.07),
                scheme.surfaceContainerHigh,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(scene.icon, color: selected ? scheme.primary : null),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                ],
              ),
              Text(
                scene.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final VisualizerStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${style.label}. ${style.description}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radiusMedium),
            color: scheme.surfaceContainerHigh,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Tokens.radiusMedium - 2),
                  ),
                  child: CustomPaint(
                    painter: _StyleThumbnailPainter(
                      style: style,
                      primary: scheme.primary,
                      secondary: scheme.tertiary,
                      background: scheme.surfaceContainerLowest,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Tokens.space2),
                child: Row(
                  children: [
                    Icon(style.icon, size: 18),
                    const SizedBox(width: Tokens.space2),
                    Expanded(
                      child: Text(
                        style.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: scheme.primary,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DependencyMessage extends StatelessWidget {
  const _DependencyMessage({required this.scene});

  final PlayerVisualScene scene;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Tokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(scene.icon, color: scheme.primary),
          const SizedBox(width: Tokens.space3),
          Expanded(
            child: Text(
              '${scene.label} no utiliza un estilo de visualizador. Elige Visualizador para configurar sus formas y efectos.',
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleThumbnailPainter extends CustomPainter {
  const _StyleThumbnailPainter({
    required this.style,
    required this.primary,
    required this.secondary,
    required this.background,
  });

  final VisualizerStyle style;
  final Color primary;
  final Color secondary;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primary, secondary],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final center = size.center(Offset.zero);

    switch (style) {
      case VisualizerStyle.automatic:
        canvas.drawCircle(center, size.shortestSide * 0.22, paint);
        canvas.drawLine(
          Offset(size.width * 0.22, size.height * 0.72),
          Offset(size.width * 0.78, size.height * 0.28),
          paint,
        );
      case VisualizerStyle.ribbons:
        for (var index = 0; index < 3; index++) {
          canvas.drawCircle(
            center,
            size.shortestSide * (0.13 + index * 0.09),
            paint,
          );
        }
      case VisualizerStyle.prism:
        for (var row = 0; row < 4; row++) {
          for (var column = 0; column < 7; column++) {
            final y = size.height * (0.25 + row * 0.17);
            final x = size.width * (0.16 + column * 0.115);
            canvas.drawCircle(Offset(x, y), 2.4 + row * 0.4, paint);
          }
        }
      case VisualizerStyle.dynamicSpectrum:
        for (var index = 0; index < 11; index++) {
          final height = size.height * (0.18 + (index % 5) * 0.10);
          final x = size.width * (0.12 + index * 0.077);
          canvas.drawLine(
            Offset(x, size.height * 0.78),
            Offset(x, size.height * 0.78 - height),
            paint,
          );
        }
      case VisualizerStyle.electricWaves:
        for (var wave = 0; wave < 3; wave++) {
          final path = Path();
          for (var step = 0; step <= 24; step++) {
            final x = size.width * step / 24;
            final y =
                size.height *
                (0.35 + wave * 0.15 + math.sin(step * 0.75 + wave) * 0.08);
            if (step == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          canvas.drawPath(path, paint);
        }
      case VisualizerStyle.cosmicOrbs:
        for (var index = 0; index < 5; index++) {
          final angle = index * math.pi * 0.4;
          final radius = size.shortestSide * (0.08 + index * 0.025);
          final orbit = size.shortestSide * 0.27;
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * orbit,
            radius,
            paint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_StyleThumbnailPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.background != background;
}
