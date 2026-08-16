import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
import 'package:nuvtune/features/settings/player_density.dart';
import 'package:nuvtune/features/settings/settings_components.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

class ControlSettingsScreen extends ConsumerWidget {
  const ControlSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final preset = PlayerControlPreset.byId(settings.playerControlPreset);
    final layout = preset == PlayerControlPreset.custom
        ? PlayerControlLayout.fromJsonString(settings.playerControlLayoutJson)
        : PlayerControlLayout.forPreset(preset);
    final mutation = ref.read(settingsMutationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Control')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: _ControlPreview(
              layout: layout,
              preset: preset,
              handedness: ControlHandedness.byId(
                settings.playerControlHandedness,
              ),
            ),
          ),
          const SettingsSectionLabel('Diseño del reproductor'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Wrap(
              spacing: Tokens.space2,
              runSpacing: Tokens.space2,
              children: [
                for (final option in PlayerControlPreset.values.where(
                  (value) => value != PlayerControlPreset.custom,
                ))
                  ChoiceChip(
                    label: Text(option.label),
                    selected: preset == option,
                    onSelected: (_) => mutation.save(
                      AppSettingsCompanion(
                        playerControlPreset: Value(option.id),
                        playerControlLayoutJson: Value(
                          PlayerControlLayout.forPreset(option).toJsonString(),
                        ),
                      ),
                    ),
                  ),
                if (preset == PlayerControlPreset.custom)
                  const Chip(
                    avatar: Icon(Icons.tune_rounded, size: 17),
                    label: Text('Personalizado'),
                  ),
              ],
            ),
          ),
          if (preset == PlayerControlPreset.oneHanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.gutter,
                Tokens.space3,
                Tokens.gutter,
                0,
              ),
              child: SegmentedButton<ControlHandedness>(
                segments: const [
                  ButtonSegment(
                    value: ControlHandedness.left,
                    icon: Icon(Icons.align_horizontal_left_rounded),
                    label: Text('Izquierda'),
                  ),
                  ButtonSegment(
                    value: ControlHandedness.right,
                    icon: Icon(Icons.align_horizontal_right_rounded),
                    label: Text('Derecha'),
                  ),
                ],
                selected: {
                  ControlHandedness.byId(settings.playerControlHandedness),
                },
                onSelectionChanged: (selection) => mutation.save(
                  AppSettingsCompanion(
                    playerControlHandedness: Value(selection.first.id),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space3,
              Tokens.gutter,
              0,
            ),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/settings/control/layout'),
              icon: const Icon(Icons.drag_indicator_rounded),
              label: const Text('Editar controles visibles y orden'),
            ),
          ),
          const SettingsSectionLabel('Densidad'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El reproductor reparte la altura disponible solo, así que '
                  'los controles nunca quedan fuera de pantalla. Esto ajusta '
                  'cuánto aire deja alrededor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Tokens.space3),
                SegmentedButton<PlayerDensity>(
                  segments: [
                    for (final option in PlayerDensity.values)
                      ButtonSegment(value: option, label: Text(option.label)),
                  ],
                  selected: {PlayerDensity.byId(settings.playerDensity)},
                  onSelectionChanged: (selection) => mutation.save(
                    AppSettingsCompanion(
                      playerDensity: Value(selection.first.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SettingsSectionLabel('Gestos del reproductor'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.touch_app_rounded),
                title: const Text('Doble toque para reproducir o pausar'),
                value: settings.playerGestureDoubleTap,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureDoubleTap: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe_rounded),
                title: const Text('Deslizar para cambiar de canción'),
                subtitle: const Text(
                  'Izquierda: siguiente · derecha: anterior',
                ),
                value: settings.playerGestureSwipeTrack,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureSwipeTrack: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Deslizar para ajustar volumen'),
                subtitle: const Text(
                  'Vertical sobre la portada; en pantalla completa, sobre el '
                  'lado derecho.',
                ),
                value: settings.playerGestureSwipeVolume,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureSwipeVolume: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.keyboard_arrow_down_rounded),
                title: const Text('Deslizar abajo para cerrar'),
                value: settings.playerGestureSwipeDismiss,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(playerGestureSwipeDismiss: Value(value)),
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Reproducción'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.restore_rounded),
                title: const Text(AppStrings.restoreQueue),
                value: settings.restoreQueueOnStart,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(restoreQueueOnStart: Value(value)),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.link_rounded),
                title: const Text(AppStrings.gapless),
                subtitle: const Text(
                  'Elimina el silencio entre pistas compatibles.',
                ),
                value: settings.gaplessEnabled,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(gaplessEnabled: Value(value)),
                  sync: const {SettingsSyncTarget.audio},
                ),
              ),
              _CrossfadeSetting(seconds: settings.crossfadeSeconds),
              SwitchListTile(
                secondary: const Icon(Icons.blur_on_rounded),
                title: const Text(AppStrings.fadeOnPause),
                value: settings.fadeOnPause,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(fadeOnPause: Value(value)),
                  sync: const {SettingsSyncTarget.audio},
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Auriculares y dispositivos'),
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.headset_off_outlined),
                title: const Text('Pausar al desconectar los audífonos'),
                value: settings.widgetPauseOnDisconnect,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(widgetPauseOnDisconnect: Value(value)),
                  sync: const {SettingsSyncTarget.deviceControls},
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.headset_rounded),
                title: const Text('Reanudar al volver a conectarlos'),
                subtitle: const Text(
                  'Solo si la desconexión provocó la pausa.',
                ),
                value: settings.widgetResumeOnConnect,
                onChanged: (value) => mutation.save(
                  AppSettingsCompanion(widgetResumeOnConnect: Value(value)),
                  sync: const {SettingsSyncTarget.deviceControls},
                ),
              ),
              SettingsNavigationRow(
                icon: Icons.widgets_outlined,
                title: 'Widget y controles de inicio',
                subtitle: settings.widgetEnabled
                    ? 'Activo · personalizar apariencia y contenido'
                    : 'Desactivado',
                onTap: () => context.push('/settings/appearance?tab=widget'),
              ),
            ],
          ),
          const SizedBox(height: Tokens.space4),
          const SettingsInfoPanel(
            icon: Icons.directions_car_rounded,
            title: 'Controles administrados por Android',
            message:
                'La notificación, la pantalla de bloqueo y Android Auto conservan los controles estándar de Media3 y el acceso a Favorito.',
          ),
        ],
      ),
    );
  }
}

class ControlLayoutScreen extends ConsumerStatefulWidget {
  const ControlLayoutScreen({super.key});

  @override
  ConsumerState<ControlLayoutScreen> createState() =>
      _ControlLayoutScreenState();
}

class _ControlLayoutScreenState extends ConsumerState<ControlLayoutScreen> {
  String? _source;
  PlayerControlLayout _layout = PlayerControlLayout.complete;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_source != settings.playerControlLayoutJson) {
      _source = settings.playerControlLayoutJson;
      _layout = PlayerControlLayout.fromJsonString(_source!);
    }

    final visible = {
      ..._layout.top,
      ..._layout.metadata,
      ..._layout.primary,
      ..._layout.secondary,
      ..._layout.footer,
    };
    final topControls = _layout.top.toList(growable: false);
    final metadataControls = _layout.metadata.toList(growable: false);
    final primaryControls = _layout.primary.toList(growable: false);
    final secondaryControls = _layout.secondary.toList(growable: false);
    final footerControls = _layout.footer.toList(growable: false);
    final hidden = PlayerControlId.values
        .where((control) => !visible.contains(control))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar controles')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: _ControlPreview(
              layout: _layout,
              preset: PlayerControlPreset.custom,
              handedness: ControlHandedness.byId(
                settings.playerControlHandedness,
              ),
            ),
          ),
          const SettingsSectionLabel('Barra superior'),
          _ReorderSection(
            controls: topControls,
            destination: _ControlDestination.top,
            emptyLabel: 'Sin acciones · admite hasta dos',
            onReorder: (oldIndex, newIndex) {
              final next = [...topControls];
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              _commit(_layout.copyWith(top: next));
            },
            onAction: _handleAction,
          ),
          const SettingsSectionLabel('Junto al título'),
          _ReorderSection(
            controls: metadataControls,
            destination: _ControlDestination.metadata,
            emptyLabel: 'Sin acciones · admite hasta dos',
            onReorder: (oldIndex, newIndex) {
              final next = [...metadataControls];
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              _commit(_layout.copyWith(metadata: next));
            },
            onAction: _handleAction,
          ),
          const SettingsSectionLabel('Controles principales'),
          _ReorderSection(
            controls: primaryControls,
            destination: _ControlDestination.primary,
            onReorder: (oldIndex, newIndex) {
              final next = [...primaryControls];
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              _commit(
                _composeLayout(
                  top: topControls,
                  metadata: metadataControls,
                  primary: next,
                  secondary: secondaryControls,
                  footer: footerControls,
                ),
              );
            },
            onAction: _handleAction,
          ),
          const SettingsSectionLabel('Controles secundarios'),
          _ReorderSection(
            controls: secondaryControls,
            destination: _ControlDestination.secondary,
            onReorder: (oldIndex, newIndex) {
              final next = [...secondaryControls];
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              _commit(
                _composeLayout(
                  top: topControls,
                  metadata: metadataControls,
                  primary: primaryControls,
                  secondary: next,
                  footer: footerControls,
                ),
              );
            },
            onAction: _handleAction,
          ),
          const SettingsSectionLabel('Acciones inferiores'),
          _ReorderSection(
            controls: footerControls,
            destination: _ControlDestination.footer,
            emptyLabel: 'Sin acciones inferiores',
            onReorder: (oldIndex, newIndex) {
              final next = [...footerControls];
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              _commit(_layout.copyWith(footer: next));
            },
            onAction: _handleAction,
          ),
          if (hidden.isNotEmpty) ...[
            const SettingsSectionLabel('Ocultos'),
            SettingsGroup(
              children: [
                for (final control in hidden)
                  ListTile(
                    leading: Icon(control.icon),
                    title: Text(control.label),
                    trailing: TextButton(
                      onPressed: () =>
                          _handleAction(control, _ControlDestination.secondary),
                      child: const Text('Mostrar'),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Tokens.space4),
          const SettingsInfoPanel(
            icon: Icons.lock_outline_rounded,
            title: 'Reproducir o pausar siempre está visible',
            message:
                'Puedes mover Favorito y las demás acciones libremente. La '
                'barra superior admite dos; Reproducir o pausar permanece en '
                'el bloque principal.',
          ),
        ],
      ),
    );
  }

  void _handleAction(PlayerControlId control, _ControlDestination target) {
    if (control == PlayerControlId.playPause &&
        target != _ControlDestination.primary) {
      return;
    }
    final top = [..._layout.top]..remove(control);
    final metadata = [..._layout.metadata]..remove(control);
    final primary = _layout.primary.toList()..remove(control);
    final secondary = _layout.secondary.toList()..remove(control);
    final footer = [..._layout.footer]..remove(control);
    switch (target) {
      case _ControlDestination.top:
        // La barra superior solo tiene sitio para dos acciones. Antes el
        // intento se descartaba en silencio y parecía que ese control (por
        // ejemplo Favorito) no se pudiera colocar ahí nunca.
        if (top.length >= 2) {
          _warnZoneIsFull('La barra superior');
          return;
        }
        top.add(control);
      case _ControlDestination.metadata:
        if (metadata.length >= 2) {
          _warnZoneIsFull('La fila del título');
          return;
        }
        metadata.add(control);
      case _ControlDestination.primary:
        primary.add(control);
      case _ControlDestination.secondary:
        secondary.add(control);
      case _ControlDestination.footer:
        footer.add(control);
      case _ControlDestination.hidden:
        if (control == PlayerControlId.playPause) return;
    }
    _commit(
      _composeLayout(
        top: top,
        metadata: metadata,
        primary: primary,
        secondary: secondary,
        footer: footer,
      ),
    );
  }

  void _warnZoneIsFull(String zone) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$zone admite dos acciones. Quita una para dejar sitio.'),
      ),
    );
  }

  PlayerControlLayout _composeLayout({
    required Iterable<PlayerControlId> top,
    required Iterable<PlayerControlId> metadata,
    required Iterable<PlayerControlId> primary,
    required Iterable<PlayerControlId> secondary,
    required Iterable<PlayerControlId> footer,
  }) => PlayerControlLayout(
    top: top,
    metadata: metadata,
    primary: primary,
    secondary: secondary,
    footer: footer,
  );

  void _commit(PlayerControlLayout next) {
    setState(() {
      _layout = next;
      _source = next.toJsonString();
    });
    ref
        .read(settingsMutationProvider.notifier)
        .save(
          AppSettingsCompanion(
            playerControlPreset: const Value('custom'),
            playerControlLayoutJson: Value(_source!),
          ),
        );
  }
}

enum _ControlDestination { top, metadata, primary, secondary, footer, hidden }

class _ReorderSection extends StatelessWidget {
  const _ReorderSection({
    required this.controls,
    required this.destination,
    required this.onReorder,
    required this.onAction,
    this.emptyLabel,
  });

  final List<PlayerControlId> controls;
  final _ControlDestination destination;
  final ReorderCallback onReorder;
  final void Function(PlayerControlId, _ControlDestination) onAction;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Tokens.radiusMedium),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: controls.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(Tokens.space4),
            child: Text(
              emptyLabel ?? 'Sin controles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: controls.length,
            onReorderItem: onReorder,
            itemBuilder: (context, index) {
              final control = controls[index];
              return ListTile(
                key: ValueKey('${destination.name}-${control.id}'),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator_rounded),
                ),
                title: Text(control.label),
                trailing: PopupMenuButton<_ControlDestination>(
                  tooltip: 'Mover ${control.label}',
                  onSelected: (target) => onAction(control, target),
                  itemBuilder: (context) => [
                    if (destination != _ControlDestination.top)
                      const PopupMenuItem(
                        value: _ControlDestination.top,
                        child: Text('Mover a barra superior'),
                      ),
                    if (destination != _ControlDestination.metadata)
                      const PopupMenuItem(
                        value: _ControlDestination.metadata,
                        child: Text('Mover junto al título'),
                      ),
                    if (destination != _ControlDestination.primary)
                      const PopupMenuItem(
                        value: _ControlDestination.primary,
                        child: Text('Mover a principales'),
                      ),
                    if (destination != _ControlDestination.secondary)
                      const PopupMenuItem(
                        value: _ControlDestination.secondary,
                        child: Text('Mover a secundarios'),
                      ),
                    if (destination != _ControlDestination.footer)
                      const PopupMenuItem(
                        value: _ControlDestination.footer,
                        child: Text('Mover a inferiores'),
                      ),
                    if (control != PlayerControlId.playPause)
                      const PopupMenuItem(
                        value: _ControlDestination.hidden,
                        child: Text('Ocultar'),
                      ),
                  ],
                ),
              );
            },
          ),
  );
}

class _CrossfadeSetting extends ConsumerStatefulWidget {
  const _CrossfadeSetting({required this.seconds});

  final int seconds;

  @override
  ConsumerState<_CrossfadeSetting> createState() => _CrossfadeSettingState();
}

class _CrossfadeSettingState extends ConsumerState<_CrossfadeSetting> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.seconds.toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.multitrack_audio_rounded),
              const SizedBox(width: 16),
              const Expanded(child: Text(AppStrings.crossfade)),
              Text(value < 1 ? 'Desactivado' : '${value.round()} s'),
            ],
          ),
          Slider(
            value: value.clamp(0, 12),
            max: 12,
            divisions: 12,
            onChanged: (next) => setState(() => _dragValue = next),
            onChangeEnd: (next) {
              setState(() => _dragValue = null);
              ref
                  .read(settingsMutationProvider.notifier)
                  .save(
                    AppSettingsCompanion(crossfadeSeconds: Value(next.round())),
                    sync: const {SettingsSyncTarget.audio},
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _ControlPreview extends StatelessWidget {
  const _ControlPreview({
    required this.layout,
    required this.preset,
    required this.handedness,
  });

  final PlayerControlLayout layout;
  final PlayerControlPreset preset;
  final ControlHandedness handedness;

  @override
  Widget build(BuildContext context) {
    final primary = layout.primary.toList(growable: false);
    final secondary = layout.secondary.toList(growable: false);
    final footer = layout.footer.toList(growable: false);
    final alignment = preset == PlayerControlPreset.oneHanded
        ? handedness == ControlHandedness.left
              ? MainAxisAlignment.start
              : MainAxisAlignment.end
        : MainAxisAlignment.center;
    return Container(
      padding: const EdgeInsets.all(Tokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusLarge),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.80),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.keyboard_arrow_down_rounded),
              const Expanded(
                child: Text(
                  'REPRODUCIENDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, letterSpacing: 1.1),
                ),
              ),
              for (final control in layout.top)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(control.icon, size: 20),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.more_vert_rounded, size: 20),
            ],
          ),
          const SizedBox(height: Tokens.space3),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radiusMedium),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
            ),
            child: const Icon(Icons.graphic_eq_rounded, size: 34),
          ),
          const SizedBox(height: Tokens.space3),
          // La fila del título con sus acciones a la derecha, tal como queda
          // en el reproductor.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vista previa',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              for (final control in layout.metadata)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(control.icon, size: 20),
                ),
            ],
          ),
          const SizedBox(height: Tokens.space3),
          _PreviewControlRow(
            controls: primary,
            alignment: alignment,
            expand: preset == PlayerControlPreset.oneHanded,
            emphasizePlayPause: true,
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: Tokens.space2),
            _PreviewControlRow(
              controls: secondary,
              alignment: alignment,
              expand: preset == PlayerControlPreset.oneHanded,
              emphasizePlayPause: false,
            ),
          ],
          if (footer.isNotEmpty) ...[
            const SizedBox(height: Tokens.space2),
            _PreviewControlRow(
              controls: footer,
              alignment: MainAxisAlignment.center,
              expand: false,
              emphasizePlayPause: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewControlRow extends StatelessWidget {
  const _PreviewControlRow({
    required this.controls,
    required this.alignment,
    required this.expand,
    required this.emphasizePlayPause,
  });

  final List<PlayerControlId> controls;
  final MainAxisAlignment alignment;
  final bool expand;
  final bool emphasizePlayPause;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: alignment,
    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
    children: [
      for (final control in controls)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: emphasizePlayPause && control == PlayerControlId.playPause
              ? CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Icon(control.icon),
                )
              : Icon(control.icon, size: 22),
        ),
    ],
  );
}

extension PlayerControlPresentation on PlayerControlId {
  IconData get icon => switch (this) {
    PlayerControlId.favorite => Icons.favorite_border_rounded,
    PlayerControlId.shuffle => Icons.shuffle_rounded,
    PlayerControlId.previous => Icons.skip_previous_rounded,
    PlayerControlId.playPause => Icons.play_arrow_rounded,
    PlayerControlId.next => Icons.skip_next_rounded,
    PlayerControlId.repeat => Icons.repeat_rounded,
    PlayerControlId.seekBackward => Icons.replay_10_rounded,
    PlayerControlId.seekForward => Icons.forward_30_rounded,
    PlayerControlId.queue => Icons.queue_music_rounded,
    PlayerControlId.sleepTimer => Icons.bedtime_outlined,
  };
}
