package com.nuvtune.engine

import android.content.Context
import android.graphics.Color

/**
 * Configuracion del widget de inicio (requerimiento seccion 9.2).
 *
 * Vive en SharedPreferences y no en la base de datos de Flutter porque el
 * widget se dibuja con la aplicacion cerrada: en ese momento Drift no esta
 * abierto y arrancar el motor de Flutter solo para leer un ajuste seria
 * absurdo.
 */
internal object WidgetConfigStore {

    private const val PREFERENCES_NAME = "nuvtune_widget"

    private const val KEY_ENABLED = "enabled"
    private const val KEY_STYLE = "style"
    private const val KEY_THEME = "theme"
    private const val KEY_SIZE = "size"
    private const val KEY_ACCENT = "accent"
    private const val KEY_OPACITY = "opacity"
    private const val KEY_COVER = "cover"
    private const val KEY_TITLE = "title"
    private const val KEY_ARTIST = "artist"
    private const val KEY_CONTROLS = "controls"
    private const val KEY_PROGRESS = "progress"
    private const val KEY_DURATION = "duration"
    private const val KEY_NEXT = "next"
    private const val KEY_OPEN_ON_TAP = "openOnTap"
    private const val KEY_PAUSE_ON_DISCONNECT = "pauseOnDisconnect"
    private const val KEY_RESUME_ON_CONNECT = "resumeOnConnect"

    fun save(context: Context, config: WidgetConfig) {
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ENABLED, config.enabled)
            .putInt(KEY_STYLE, config.style.ordinal)
            .putInt(KEY_THEME, config.theme.ordinal)
            .putInt(KEY_SIZE, config.preferredSize.ordinal)
            .putInt(KEY_ACCENT, config.accentColor.toInt())
            .putFloat(KEY_OPACITY, config.backgroundOpacity.toFloat())
            .putBoolean(KEY_COVER, config.showCover)
            .putBoolean(KEY_TITLE, config.showTitle)
            .putBoolean(KEY_ARTIST, config.showArtist)
            .putBoolean(KEY_CONTROLS, config.showControls)
            .putBoolean(KEY_PROGRESS, config.showProgress)
            .putBoolean(KEY_DURATION, config.showDuration)
            .putBoolean(KEY_NEXT, config.showNextInQueue)
            .putBoolean(KEY_OPEN_ON_TAP, config.openPlayerOnTap)
            .putBoolean(KEY_PAUSE_ON_DISCONNECT, config.pauseOnHeadphonesDisconnect)
            .putBoolean(KEY_RESUME_ON_CONNECT, config.resumeOnHeadphonesConnect)
            .apply()
    }

    fun load(context: Context): WidgetConfig {
        val preferences =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

        return WidgetConfig(
            enabled = preferences.getBoolean(KEY_ENABLED, true),
            style = WidgetStyle.entries[
                preferences.getInt(KEY_STYLE, WidgetStyle.IOS.ordinal),
            ],
            theme = WidgetTheme.entries[
                preferences.getInt(KEY_THEME, WidgetTheme.DARK.ordinal),
            ],
            preferredSize = WidgetSize.entries[
                preferences.getInt(KEY_SIZE, WidgetSize.NORMAL.ordinal),
            ],
            accentColor = preferences.getInt(KEY_ACCENT, DEFAULT_ACCENT).toLong(),
            backgroundOpacity = preferences.getFloat(KEY_OPACITY, 0.92f).toDouble(),
            showCover = preferences.getBoolean(KEY_COVER, true),
            showTitle = preferences.getBoolean(KEY_TITLE, true),
            showArtist = preferences.getBoolean(KEY_ARTIST, true),
            showControls = preferences.getBoolean(KEY_CONTROLS, true),
            showProgress = preferences.getBoolean(KEY_PROGRESS, true),
            showDuration = preferences.getBoolean(KEY_DURATION, false),
            showNextInQueue = preferences.getBoolean(KEY_NEXT, false),
            openPlayerOnTap = preferences.getBoolean(KEY_OPEN_ON_TAP, true),
            pauseOnHeadphonesDisconnect =
                preferences.getBoolean(KEY_PAUSE_ON_DISCONNECT, true),
            resumeOnHeadphonesConnect =
                preferences.getBoolean(KEY_RESUME_ON_CONNECT, false),
        )
    }

    /** Violeta de la marca. */
    private val DEFAULT_ACCENT = Color.parseColor("#FFB14BFF")
}
