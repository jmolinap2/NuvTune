import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/features/player/customizable_player_controls.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/settings/player_control_layout.dart';
import 'package:nuvtune/features/settings/player_density.dart';

void main() {
  group('CustomizablePlayerControls favorito', () {
    testWidgets('se dibuja una sola vez en la fila primaria', (tester) async {
      await _pumpControls(
        tester,
        layout: PlayerControlLayout(
          primary: const [
            PlayerControlId.favorite,
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [PlayerControlId.queue],
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byTooltip('Favorito'), findsOneWidget);
    });

    testWidgets('permanece oculto cuando no forma parte del layout', (
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

      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byTooltip('Favorito'), findsNothing);
    });

    testWidgets('queda centrado cuando el usuario lo coloca abajo', (
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
          secondary: const [
            PlayerControlId.seekBackward,
            PlayerControlId.queue,
          ],
          footer: const [PlayerControlId.favorite],
        ),
      );

      final favorite = find.byIcon(Icons.favorite_border_rounded);
      final favoriteCenter = tester.getCenter(favorite);
      final controlsBounds = tester.getRect(
        find.byType(CustomizablePlayerControls),
      );
      final otherIcons = find.byType(Icon).evaluate().where((element) {
        final icon = element.widget as Icon;
        return icon.icon != Icons.favorite_border_rounded;
      });
      final lowestOtherControl = otherIcons
          .map(
            (element) => tester
                .getBottomRight(
                  find.byElementPredicate(
                    (candidate) => identical(candidate, element),
                  ),
                )
                .dy,
          )
          .reduce((a, b) => a > b ? a : b);

      expect(favoriteCenter.dx, closeTo(controlsBounds.center.dx, 0.01));
      expect(tester.getTopLeft(favorite).dy, greaterThan(lowestOtherControl));
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
