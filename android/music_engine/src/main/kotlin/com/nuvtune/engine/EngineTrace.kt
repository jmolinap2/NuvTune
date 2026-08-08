package com.nuvtune.engine

import android.util.Log
import androidx.media3.common.Player

/**
 * Traza de diagnostico del avance entre pistas.
 *
 * Existe para responder una pregunta concreta que a simple vista no se puede
 * contestar: cuando el usuario toca "siguiente" una vez y el reproductor
 * avanza tres canciones, ¿son tres ordenes que llegan al motor, o es una sola
 * orden y el motor descarta dos pistas por su cuenta? Las transiciones ocurren
 * en milisegundos, asi que mirar la pantalla no alcanza; cada evento se
 * imprime con su marca de tiempo y su motivo para poder reconstruir la
 * secuencia exacta desde `adb logcat -s NuvTuneTrace`.
 *
 * Es diagnostico temporal, no registro de producto: lo que le importa al
 * usuario final vive en [PlaybackFailureLog].
 */
internal object EngineTrace {

    const val TAG = "NuvTuneTrace"

    fun log(message: String) {
        Log.d(TAG, message)
    }

    /** Nombre legible del motivo de [Player.Listener.onMediaItemTransition]. */
    fun transitionReason(reason: Int): String = when (reason) {
        Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT -> "REPEAT"
        Player.MEDIA_ITEM_TRANSITION_REASON_AUTO -> "AUTO(termino sola)"
        Player.MEDIA_ITEM_TRANSITION_REASON_SEEK -> "SEEK(orden explicita)"
        Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED -> "PLAYLIST_CHANGED"
        else -> "DESCONOCIDO($reason)"
    }

    /** Nombre legible del motivo de [Player.Listener.onPositionDiscontinuity]. */
    fun discontinuityReason(reason: Int): String = when (reason) {
        Player.DISCONTINUITY_REASON_AUTO_TRANSITION -> "AUTO_TRANSITION"
        Player.DISCONTINUITY_REASON_SEEK -> "SEEK"
        Player.DISCONTINUITY_REASON_SEEK_ADJUSTMENT -> "SEEK_ADJUSTMENT"
        Player.DISCONTINUITY_REASON_SKIP -> "SKIP"
        Player.DISCONTINUITY_REASON_REMOVE -> "REMOVE"
        Player.DISCONTINUITY_REASON_INTERNAL -> "INTERNAL"
        Player.DISCONTINUITY_REASON_SILENCE_SKIP -> "SILENCE_SKIP"
        else -> "DESCONOCIDO($reason)"
    }
}
