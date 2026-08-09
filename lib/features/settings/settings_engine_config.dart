import 'package:nuvtune/core/platform/music_engine.g.dart';
import 'package:nuvtune/data/db/database.dart';

/// Traduce las preferencias del widget al contrato del motor Android.
WidgetConfig widgetConfigOf(AppSetting settings) => WidgetConfig(
  enabled: settings.widgetEnabled,
  style: WidgetStyle.values[settings.widgetStyle],
  theme: WidgetTheme.values[settings.widgetTheme],
  preferredSize: WidgetSize.values[settings.widgetSize],
  accentColor: settings.widgetAccentColor,
  backgroundOpacity: settings.widgetOpacity,
  showCover: settings.widgetShowCover,
  showTitle: settings.widgetShowTitle,
  showArtist: settings.widgetShowArtist,
  showControls: settings.widgetShowControls,
  showProgress: settings.widgetShowProgress,
  showDuration: settings.widgetShowDuration,
  showNextInQueue: settings.widgetShowNextInQueue,
  openPlayerOnTap: settings.widgetOpenOnTap,
);

/// Traduce el comportamiento global de auriculares al contrato nativo.
DeviceControlConfig deviceControlConfigOf(AppSetting settings) =>
    DeviceControlConfig(
      pauseOnHeadphonesDisconnect: settings.widgetPauseOnDisconnect,
      resumeOnHeadphonesConnect: settings.widgetResumeOnConnect,
    );
