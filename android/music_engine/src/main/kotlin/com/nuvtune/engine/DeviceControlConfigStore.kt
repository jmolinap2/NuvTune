package com.nuvtune.engine

import android.content.Context

/**
 * Configuración global de auriculares, independiente del widget de inicio.
 *
 * La primera lectura recupera las claves históricas de `nuvtune_widget`, de
 * modo que actualizar NuvTune no cambia el comportamiento elegido previamente.
 */
internal object DeviceControlConfigStore {
    private const val PREFERENCES_NAME = "nuvtune_device_controls"
    private const val LEGACY_PREFERENCES_NAME = "nuvtune_widget"
    private const val KEY_PAUSE_ON_DISCONNECT = "pauseOnDisconnect"
    private const val KEY_RESUME_ON_CONNECT = "resumeOnConnect"

    fun save(context: Context, config: DeviceControlConfig) {
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_PAUSE_ON_DISCONNECT, config.pauseOnHeadphonesDisconnect)
            .putBoolean(KEY_RESUME_ON_CONNECT, config.resumeOnHeadphonesConnect)
            .apply()
    }

    fun load(context: Context): DeviceControlConfig {
        val preferences = context.getSharedPreferences(
            PREFERENCES_NAME,
            Context.MODE_PRIVATE,
        )
        val legacy = context.getSharedPreferences(
            LEGACY_PREFERENCES_NAME,
            Context.MODE_PRIVATE,
        )
        return DeviceControlConfig(
            pauseOnHeadphonesDisconnect = preferences.getBoolean(
                KEY_PAUSE_ON_DISCONNECT,
                legacy.getBoolean(KEY_PAUSE_ON_DISCONNECT, true),
            ),
            resumeOnHeadphonesConnect = preferences.getBoolean(
                KEY_RESUME_ON_CONNECT,
                legacy.getBoolean(KEY_RESUME_ON_CONNECT, false),
            ),
        )
    }
}
