import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/player/customizable_player_controls.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
import 'package:nuvtune/features/settings/player_density.dart';

void main() {
  group('CustomizablePlayerControls', () {
    testWidgets('la fila de transporte ya no dibuja el favorito', (
      tester,
    ) async {
      // Favorito pertenece al bloque de información de la canción. Si volviera
      // a aparecer aquí habría dos sitios para la misma acción.
      await _pumpControls(
        tester,
        layout: PlayerControlLayout(
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [PlayerControlId.queue],
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byTooltip('Favorito'), findsNothing);
    });

    testWidgets('un diseño guardado que nombre favorito no lo resucita', (
      tester,
    ) async {
      final layout = PlayerControlLayout.fromJsonString(
        '{"primary":["previous","playPause","next"],'
        '"secondary":["queue"],"footer":["favorite"]}',
      );

      await _pumpControls(tester, layout: layout);

      expect(layout.footer, isEmpty);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('dibuja los controles que sí siguen siendo configurables', (
      tester,
    ) async {
      await _pumpControls(
        tester,
        layout: PlayerControlLayout(
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [PlayerControlId.queue],
        ),
      );

      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
    });
  });
}

Future<void> _pumpControls(
  WidgetTester tester, {
  required PlayerControlLayout layout,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: CustomizablePlayerControls(
            layout: layout,
            preset: PlayerControlPreset.custom,
            handedness: ControlHandedness.right,
            density: PlayerDensity.normal,
            state: PlaybackState.initial(),
            controller: PlaybackController(),
            song: _song,
            isFavorite: false,
            onOpenQueue: () {},
          ),
        ),
      ),
    ),
  );
}

final _song = Song(
  id: 1,
  uri: 'content://music/1',
  filePath: '/music/1.mp3',
  title: 'Pista',
  artist: 'Artista',
  artistId: 1,
  album: 'Album',
  albumId: 1,
  durationMs: 180000,
  mimeType: 'audio/mpeg',
  sizeBytes: 1000,
  dateAdded: 0,
  dateModified: 0,
  folderPath: '/music',
  folderName: 'music',
  hasCover: false,
  isSupported: true,
);
