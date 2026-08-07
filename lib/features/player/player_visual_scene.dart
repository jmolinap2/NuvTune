import 'package:flutter/material.dart';
import 'package:nuvtune/shared/widgets/option_picker.dart';

/// Escenario persistente de la pestaña principal del reproductor.
enum PlayerVisualScene {
  video,
  visualizer,
  both,
  lyrics,
  cover;

  static PlayerVisualScene fromIndex(int index) =>
      index >= 0 && index < PlayerVisualScene.values.length
      ? PlayerVisualScene.values[index]
      : PlayerVisualScene.video;

  String get label => switch (this) {
    PlayerVisualScene.video => 'Video',
    PlayerVisualScene.visualizer => 'Visualizador',
    PlayerVisualScene.both => 'Video + letras',
    PlayerVisualScene.lyrics => 'Letras',
    PlayerVisualScene.cover => 'Portada',
  };

  String get description => switch (this) {
    PlayerVisualScene.video =>
      'Video musical limpio como fondo, sin animaciones superpuestas.',
    PlayerVisualScene.visualizer =>
      'Animación reactiva a pantalla amplia, incluso si existe portada.',
    PlayerVisualScene.both =>
      'Video musical con la letra sincronizada superpuesta cuando existe.',
    PlayerVisualScene.lyrics =>
      'Letra protagonista, con seguimiento cuando está sincronizada.',
    PlayerVisualScene.cover =>
      'Carrusel de portadas sin video ni visualización reactiva.',
  };

  IconData get icon => switch (this) {
    PlayerVisualScene.video => Icons.smart_display_rounded,
    PlayerVisualScene.visualizer => Icons.graphic_eq_rounded,
    PlayerVisualScene.both => Icons.subtitles_rounded,
    PlayerVisualScene.lyrics => Icons.lyrics_rounded,
    PlayerVisualScene.cover => Icons.album_rounded,
  };

  bool get requestsVideo =>
      this == PlayerVisualScene.video || this == PlayerVisualScene.both;

  bool get showsVisualizer => this == PlayerVisualScene.visualizer;

  bool get showsLyrics =>
      this == PlayerVisualScene.lyrics || this == PlayerVisualScene.both;

  bool get showsCover => this == PlayerVisualScene.cover;
}

Future<PlayerVisualScene?> showPlayerVisualScenePicker(
  BuildContext context, {
  required PlayerVisualScene selected,
}) => showOptionPicker<PlayerVisualScene>(
  context,
  title: 'Escenario del reproductor',
  selected: selected,
  helperText:
      'Video y Video + letras usan YouTube únicamente por Wi-Fi. '
      'Letras puede buscar en internet cuando no hay una versión '
      'local; Portada nunca carga contenido de red.',
  options: [
    for (final scene in PlayerVisualScene.values)
      OptionPickerItem(
        value: scene,
        icon: scene.icon,
        label: scene.label,
        description: scene.description,
      ),
  ],
);
