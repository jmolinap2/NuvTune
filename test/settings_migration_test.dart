import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/data/db/database.dart';

void main() {
  test(
    'migración 10 a 13 conserva ajustes y añade controles, regalos y densidad',
    () async {
      final executor = NativeDatabase.memory(
        setup: (raw) {
          raw.execute(_appSettingsV10);
          raw.execute(_playlistsV10);
          raw.execute('''
          INSERT INTO app_settings (
            id, accent_id, background_depth, gapless_enabled,
            widget_pause_on_disconnect, widget_resume_on_connect
          ) VALUES (0, 'solar', 'black', 0, 0, 1)
        ''');
          raw.execute('PRAGMA user_version = 10');
        },
      );
      final database = NuvTuneDatabase.forTesting(executor);
      addTearDown(database.close);

      final settings = await database.select(database.appSettings).getSingle();

      expect(settings.accentId, 'solar');
      expect(settings.backgroundDepth, 'black');
      expect(settings.gaplessEnabled, isFalse);
      expect(settings.widgetPauseOnDisconnect, isFalse);
      expect(settings.widgetResumeOnConnect, isTrue);
      expect(settings.playerControlPreset, 'complete');
      expect(settings.playerControlHandedness, 'right');
      expect(settings.playerGestureDoubleTap, isTrue);
      expect(settings.playerGestureSwipeTrack, isTrue);
      expect(settings.playerGestureSwipeVolume, isTrue);
      expect(settings.playerGestureSwipeDismiss, isTrue);
      // La densidad llega con la migración 13. Un reproductor sin este valor
      // no sabría repartir la altura, así que el defecto tiene que existir
      // para una base de datos que nunca lo vio.
      expect(settings.playerDensity, 'normal');
      final playlist = await database.select(database.playlists).getSingle();
      expect(playlist.name, 'Sin perder');
      expect(playlist.giftId, isNull);
    },
  );
}

const _playlistsV10 = '''
CREATE TABLE playlists (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  cover_path TEXT NULL,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
  gift_mode INTEGER NOT NULL DEFAULT 0,
  dedication TEXT NULL,
  gift_from TEXT NULL,
  gift_to TEXT NULL,
  gift_accent_id TEXT NULL
);
INSERT INTO playlists (name, gift_mode, dedication)
VALUES ('Sin perder', 1, 'Con cariño');
''';

const _appSettingsV10 = '''
CREATE TABLE app_settings (
  id INTEGER NOT NULL PRIMARY KEY DEFAULT 0,
  scan_on_start INTEGER NOT NULL DEFAULT 1,
  last_scan_at INTEGER NULL,
  use_dynamic_color INTEGER NOT NULL DEFAULT 1,
  pure_black_background INTEGER NOT NULL DEFAULT 0,
  accent_id TEXT NOT NULL DEFAULT 'nebula',
  background_depth TEXT NOT NULL DEFAULT 'night',
  glass_intensity TEXT NOT NULL DEFAULT 'medium',
  restore_queue_on_start INTEGER NOT NULL DEFAULT 1,
  gapless_enabled INTEGER NOT NULL DEFAULT 1,
  crossfade_seconds INTEGER NOT NULL DEFAULT 0,
  fade_on_pause INTEGER NOT NULL DEFAULT 1,
  fade_on_pause_ms INTEGER NOT NULL DEFAULT 250,
  direct_mode INTEGER NOT NULL DEFAULT 0,
  allow_offload INTEGER NOT NULL DEFAULT 1,
  playback_speed REAL NOT NULL DEFAULT 1,
  playback_pitch REAL NOT NULL DEFAULT 1,
  embed_cover_in_file INTEGER NOT NULL DEFAULT 1,
  widget_enabled INTEGER NOT NULL DEFAULT 1,
  widget_style INTEGER NOT NULL DEFAULT 0,
  widget_theme INTEGER NOT NULL DEFAULT 1,
  widget_size INTEGER NOT NULL DEFAULT 1,
  widget_accent_color INTEGER NOT NULL DEFAULT 4289805311,
  widget_opacity REAL NOT NULL DEFAULT 0.92,
  widget_show_cover INTEGER NOT NULL DEFAULT 1,
  widget_show_title INTEGER NOT NULL DEFAULT 1,
  widget_show_artist INTEGER NOT NULL DEFAULT 1,
  widget_show_controls INTEGER NOT NULL DEFAULT 1,
  widget_show_progress INTEGER NOT NULL DEFAULT 1,
  widget_show_duration INTEGER NOT NULL DEFAULT 0,
  widget_show_next_in_queue INTEGER NOT NULL DEFAULT 0,
  widget_open_on_tap INTEGER NOT NULL DEFAULT 1,
  widget_pause_on_disconnect INTEGER NOT NULL DEFAULT 1,
  widget_resume_on_connect INTEGER NOT NULL DEFAULT 0,
  sleep_timer_minutes INTEGER NOT NULL DEFAULT 30,
  sleep_timer_finish_track INTEGER NOT NULL DEFAULT 1,
  home_sections_json TEXT NOT NULL DEFAULT '[]',
  library_sort_json TEXT NOT NULL DEFAULT '{}',
  video_background_enabled INTEGER NOT NULL DEFAULT 1,
  player_visualizer_style INTEGER NOT NULL DEFAULT 0,
  player_visual_scene INTEGER NOT NULL DEFAULT 0,
  player_scene_aspect_ratio INTEGER NOT NULL DEFAULT 0
)
''';
