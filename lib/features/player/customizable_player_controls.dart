import 'package:flutter/material.dart' hide RepeatMode;
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/player/sleep_timer_sheet.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
import 'package:nuvtune/features/settings/player_density.dart';

class CustomizablePlayerControls extends StatelessWidget {
  const CustomizablePlayerControls({
    required this.layout,
    required this.preset,
    required this.handedness,
    required this.density,
    required this.state,
    required this.controller,
    required this.song,
    required this.isFavorite,
    required this.onOpenQueue,
    super.key,
  });

  final PlayerControlLayout layout;
  final PlayerControlPreset preset;
  final ControlHandedness handedness;
  final PlayerDensity density;
  final PlaybackState state;
  final PlaybackController controller;
  final Song song;
  final bool isFavorite;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final oneHanded = preset == PlayerControlPreset.oneHanded;
    final alignment = oneHanded
        ? handedness == ControlHandedness.left
              ? WrapAlignment.start
              : WrapAlignment.end
        : WrapAlignment.center;
    final primaryControls = layout.primary.toList(growable: false);
    final secondaryControls = layout.secondary.toList(growable: false);
    final footerControls = layout.footer.toList(growable: false);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: alignment,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: oneHanded ? 2 : 6,
            runSpacing: Tokens.space2,
            children: [
              for (final control in primaryControls)
                _button(context, control, primary: true),
            ],
          ),
        ),
        if (secondaryControls.isNotEmpty) ...[
          SizedBox(height: density.gap(Tokens.space2)),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: alignment,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                for (final control in secondaryControls)
                  _button(context, control, primary: false),
              ],
            ),
          ),
        ],
        if (footerControls.isNotEmpty) ...[
          SizedBox(height: density.gap(Tokens.space2)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              for (final control in footerControls)
                _button(context, control, primary: false),
            ],
          ),
        ],
      ],
    );
  }

  Widget _button(
    BuildContext context,
    PlayerControlId control, {
    required bool primary,
  }) {
    if (control == PlayerControlId.playPause) {
      return Semantics(
        button: true,
        label: state.isPlaying ? 'Pausar' : 'Reproducir',
        child: IconButton.filled(
          iconSize: _scaled(34),
          padding: EdgeInsets.all(_scaled(14)),
          tooltip: state.isPlaying ? 'Pausar' : 'Reproducir',
          onPressed: controller.togglePlayPause,
          icon: Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final active = switch (control) {
      PlayerControlId.shuffle => state.snapshot.shuffleEnabled,
      PlayerControlId.repeat => state.snapshot.repeatMode != RepeatMode.off,
      PlayerControlId.sleepTimer =>
        state.snapshot.sleepTimerRemainingMs != null,
      _ => false,
    };

    return IconButton(
      iconSize: _scaled(primary ? 30 : 23),
      tooltip: _tooltip(control),
      onPressed: () => _invoke(context, control),
      color: active ? scheme.primary : null,
      icon: Icon(_icon(control)),
    );
  }

  /// Tamaño de icono ya ajustado a la densidad elegida. Se redondea porque un
  /// icono a media unidad logica se dibuja borroso.
  double _scaled(double base) => (base * density.iconScale).roundToDouble();

  void _invoke(BuildContext context, PlayerControlId control) {
    switch (control) {
      case PlayerControlId.shuffle:
        controller.toggleShuffle();
      case PlayerControlId.previous:
        controller.skipPrevious();
      case PlayerControlId.playPause:
        controller.togglePlayPause();
      case PlayerControlId.next:
        controller.skipNext();
      case PlayerControlId.repeat:
        controller.cycleRepeatMode();
      case PlayerControlId.seekBackward:
        controller.seekRelative(-10000);
      case PlayerControlId.seekForward:
        controller.seekRelative(30000);
      case PlayerControlId.queue:
        onOpenQueue();
      case PlayerControlId.sleepTimer:
        showSleepTimerSheet(context);
    }
  }

  String _tooltip(PlayerControlId control) => switch (control) {
    PlayerControlId.shuffle =>
      state.snapshot.shuffleEnabled ? 'Aleatorio activado' : AppStrings.shuffle,
    PlayerControlId.previous => 'Anterior',
    PlayerControlId.playPause => state.isPlaying ? 'Pausar' : 'Reproducir',
    PlayerControlId.next => 'Siguiente',
    PlayerControlId.repeat => switch (state.snapshot.repeatMode) {
      RepeatMode.off => AppStrings.repeatOff,
      RepeatMode.all => AppStrings.repeatAll,
      RepeatMode.one => AppStrings.repeatOne,
    },
    PlayerControlId.seekBackward => 'Retroceder 10 segundos',
    PlayerControlId.seekForward => 'Avanzar 30 segundos',
    PlayerControlId.queue => AppStrings.queue,
    PlayerControlId.sleepTimer => AppStrings.sleepTimer,
  };

  IconData _icon(PlayerControlId control) => switch (control) {
    PlayerControlId.shuffle => Icons.shuffle_rounded,
    PlayerControlId.previous => Icons.skip_previous_rounded,
    PlayerControlId.playPause =>
      state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
    PlayerControlId.next => Icons.skip_next_rounded,
    PlayerControlId.repeat =>
      state.snapshot.repeatMode == RepeatMode.one
          ? Icons.repeat_one_rounded
          : Icons.repeat_rounded,
    PlayerControlId.seekBackward => Icons.replay_10_rounded,
    PlayerControlId.seekForward => Icons.forward_30_rounded,
    PlayerControlId.queue => Icons.queue_music_rounded,
    PlayerControlId.sleepTimer =>
      state.snapshot.sleepTimerRemainingMs == null
          ? Icons.bedtime_outlined
          : Icons.bedtime_rounded,
  };
}
