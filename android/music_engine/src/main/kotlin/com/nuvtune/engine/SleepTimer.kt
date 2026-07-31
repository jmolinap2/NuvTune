package com.nuvtune.engine

import android.os.Handler
import android.os.SystemClock

/**
 * Temporizador de apagado (requerimiento seccion 4.2).
 *
 * Vive en el servicio y no en la interfaz, de modo que sigue corriendo con la
 * pantalla apagada y con Flutter destruido.
 */
internal class SleepTimer(
    private val handler: Handler,
    private val onFinished: () -> Unit,
) {

    private var deadlineUptimeMs: Long = 0
    private var finishCurrentTrack: Boolean = false
    private var expired: Boolean = false

    private val trigger = Runnable {
        if (finishCurrentTrack) {
            // No se corta la cancion: se marca y el servicio detiene la
            // reproduccion cuando la pista en curso termina.
            expired = true
        } else {
            clear()
            onFinished()
        }
    }

    val isActive: Boolean get() = deadlineUptimeMs > 0

    /** Milisegundos restantes, o null si el temporizador esta apagado. */
    fun remainingMs(): Long? {
        if (deadlineUptimeMs <= 0) return null
        val remaining = deadlineUptimeMs - SystemClock.uptimeMillis()
        return if (remaining > 0) remaining else 0
    }

    fun schedule(durationMs: Long, finishTrack: Boolean) {
        cancel()
        if (durationMs <= 0) return
        finishCurrentTrack = finishTrack
        expired = false
        deadlineUptimeMs = SystemClock.uptimeMillis() + durationMs
        handler.postAtTime(trigger, deadlineUptimeMs)
    }

    fun cancel() {
        handler.removeCallbacks(trigger)
        clear()
    }

    /**
     * Lo llama el servicio cuando termina una pista. Devuelve true si el
     * temporizador ya habia vencido y la reproduccion debe detenerse aqui.
     */
    fun shouldStopAfterCurrentTrack(): Boolean {
        if (!expired) return false
        clear()
        onFinished()
        return true
    }

    private fun clear() {
        deadlineUptimeMs = 0
        expired = false
        finishCurrentTrack = false
    }
}
