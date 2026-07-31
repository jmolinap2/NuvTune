package com.nuvtune.engine

import android.os.Handler
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer

/**
 * Crossfade y fundido al pausar o reanudar (requerimiento seccion 5.5).
 *
 * Media3 no trae crossfade: un solo ExoPlayer no puede solapar dos pistas. El
 * solape se consigue con un reproductor secundario que solo vive durante la
 * ventana de crossfade y adelanta la pista siguiente. La sesion multimedia
 * permanece siempre en el reproductor principal, asi que la cola, la
 * reproduccion sin espacios y los controles externos siguen siendo los nativos
 * de Media3.
 *
 * Secuencia del solape:
 *  1. Cuando al principal le quedan `crossfadeMs`, se crea el secundario con la
 *     pista siguiente y empieza a sonar en silencio.
 *  2. Cada tick el principal baja y el secundario sube.
 *  3. Al terminar la pista, el principal avanza solo a esa misma pista. En ese
 *     momento se le lleva a la posicion que alcanzo el secundario y se sube su
 *     volumen mientras se libera el secundario. El salto de posicion es
 *     inaudible porque el principal esta en silencio durante el reajuste.
 *
 * Con `crossfadeSeconds` en cero no se crea ningun reproductor secundario y la
 * reproduccion es la de un solo ExoPlayer, que es la que permite gapless nativo.
 */
@OptIn(UnstableApi::class)
internal class FadeController(
    private val primary: ExoPlayer,
    private val createSecondary: () -> ExoPlayer,
    private val handler: Handler,
) {

    var crossfadeMs: Int = 0
        set(value) {
            field = value
            if (value <= 0) {
                cancelOverlap()
            }
        }

    var fadeOnPauseEnabled: Boolean = true
    var fadeOnPauseMs: Int = 250

    private var secondary: ExoPlayer? = null
    private var ticking = false
    private var activeRamp: Runnable? = null

    private val tick = object : Runnable {
        override fun run() {
            evaluateOverlap()
            if (ticking) {
                handler.postDelayed(this, TICK_MS)
            }
        }
    }

    fun start() {
        if (ticking) return
        ticking = true
        handler.post(tick)
    }

    fun release() {
        ticking = false
        handler.removeCallbacks(tick)
        cancelRamp()
        cancelOverlap()
    }

    // -- Crossfade -----------------------------------------------------------

    private fun evaluateOverlap() {
        if (crossfadeMs <= 0 || !primary.isPlaying) {
            cancelOverlap()
            return
        }

        val duration = primary.duration
        if (duration == C.TIME_UNSET) {
            return
        }

        val remaining = duration - primary.currentPosition
        if (remaining <= 0 || remaining > crossfadeMs) {
            cancelOverlap()
            return
        }

        val followingIndex = primary.nextMediaItemIndex
        if (followingIndex == C.INDEX_UNSET) {
            return
        }

        val player = secondary ?: startOverlap(followingIndex) ?: return

        val progress = (1f - remaining.toFloat() / crossfadeMs).coerceIn(0f, 1f)
        primary.volume = 1f - progress
        player.volume = progress
    }

    private fun startOverlap(followingIndex: Int): ExoPlayer? {
        val item = primary.getMediaItemAt(followingIndex)
        val player = createSecondary()
        player.setMediaItem(item)
        player.volume = 0f
        player.prepare()
        player.play()
        secondary = player
        return player
    }

    /**
     * El principal acaba de avanzar por si mismo a la pista que el secundario
     * ya estaba reproduciendo.
     */
    fun onAutomaticTransition() {
        val player = secondary ?: return
        val handoffPosition = player.currentPosition
        primary.volume = 0f
        primary.seekTo(handoffPosition)
        cancelOverlap()
        rampPrimaryVolume(from = 0f, to = 1f, durationMs = HANDOFF_RAMP_MS)
    }

    /**
     * El usuario cambio de pista a mano: se descarta el solape en curso y el
     * volumen vuelve a la unidad de inmediato.
     */
    fun onManualTransition() {
        cancelRamp()
        cancelOverlap()
        primary.volume = 1f
    }

    private fun cancelOverlap() {
        secondary?.let {
            it.stop()
            it.release()
        }
        secondary = null
    }

    // -- Fundido al pausar y reanudar ----------------------------------------

    fun pauseWithFade() {
        if (!fadeOnPauseEnabled || !primary.isPlaying) {
            primary.pause()
            return
        }
        cancelRamp()
        rampPrimaryVolume(from = primary.volume, to = 0f, durationMs = fadeOnPauseMs) {
            primary.pause()
            primary.volume = 1f
        }
    }

    fun playWithFade() {
        cancelRamp()
        if (!fadeOnPauseEnabled) {
            primary.volume = 1f
            primary.play()
            return
        }
        primary.volume = 0f
        primary.play()
        rampPrimaryVolume(from = 0f, to = 1f, durationMs = fadeOnPauseMs)
    }

    private fun rampPrimaryVolume(
        from: Float,
        to: Float,
        durationMs: Int,
        onFinished: () -> Unit = {},
    ) {
        if (durationMs <= 0) {
            primary.volume = to
            onFinished()
            return
        }

        val startedAt = System.currentTimeMillis()
        val ramp = object : Runnable {
            override fun run() {
                val elapsed = System.currentTimeMillis() - startedAt
                val progress = (elapsed.toFloat() / durationMs).coerceIn(0f, 1f)
                primary.volume = from + (to - from) * progress
                if (progress < 1f) {
                    handler.postDelayed(this, RAMP_STEP_MS)
                } else {
                    activeRamp = null
                    onFinished()
                }
            }
        }
        activeRamp = ramp
        handler.post(ramp)
    }

    private fun cancelRamp() {
        activeRamp?.let { handler.removeCallbacks(it) }
        activeRamp = null
    }

    private companion object {
        /**
         * 200 ms mantiene el paso del crossfade suave sin despertar el hilo
         * principal con frecuencia (requerimiento seccion 17).
         */
        const val TICK_MS = 200L
        const val RAMP_STEP_MS = 16L

        /** Subida del principal tras el relevo; corta para que no se note. */
        const val HANDOFF_RAMP_MS = 150
    }
}
