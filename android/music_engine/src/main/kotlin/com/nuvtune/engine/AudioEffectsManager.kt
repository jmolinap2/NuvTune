package com.nuvtune.engine

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.RenderersFactory
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink

/**
 * Concentra el procesamiento de audio y las opciones de calidad de
 * reproduccion (requerimiento secciones 5.3 y 5.5).
 *
 * El orden completo que fija el requerimiento 5.2 se reparte en dos
 * procesadores encadenados:
 *
 *  1. [EqualizerAudioProcessor]: ganancia previa, ecualizador, balance y mono.
 *  2. [AudioEnhancerProcessor]: realce de detalle, dinamica multibanda,
 *     normalizacion, expansion estereo y limitador.
 *
 * El control de velocidad y tono lo aporta el SonicAudioProcessor que Media3
 * agrega al final de la cadena por omision.
 */
@OptIn(UnstableApi::class)
internal class AudioEffectsManager(private val context: Context) {

    val equalizerProcessor = EqualizerAudioProcessor()
    val enhancerProcessor = AudioEnhancerProcessor()

    @Volatile
    var options: PlaybackOptions = defaultOptions()
        private set

    @Volatile
    private var analysisRequested = false

    fun applyEqualizer(settings: EqualizerSettings) {
        equalizerProcessor.updateSettings(settings)
    }

    fun currentEqualizer(): EqualizerSettings = equalizerProcessor.currentSettings()

    fun applyEnhancement(settings: EnhancementSettings) {
        enhancerProcessor.updateSettings(settings)
    }

    fun currentEnhancement(): EnhancementSettings = enhancerProcessor.currentSettings()

    fun setAnalysisEnabled(enabled: Boolean) {
        analysisRequested = enabled
        equalizerProcessor.setAnalysisEnabled(enabled && !options.directMode)
    }

    fun setAnalysisListener(listener: ((AudioAnalysisFrame) -> Unit)?) {
        equalizerProcessor.setAnalysisListener(listener)
    }

    /**
     * Aplica las opciones de calidad. Devuelve true si el cambio requiere que
     * el reproductor vuelva a preparar la pista, lo que ocurre solamente al
     * entrar o salir del modo directo: ahi cambia la presencia del procesador
     * en la cadena y con ella la posibilidad de usar audio offload.
     */
    fun applyOptions(newOptions: PlaybackOptions): Boolean {
        val previous = options
        options = newOptions
        equalizerProcessor.updateDirectMode(newOptions.directMode)
        equalizerProcessor.setAnalysisEnabled(analysisRequested && !newOptions.directMode)
        enhancerProcessor.updateDirectMode(newOptions.directMode)
        return previous.directMode != newOptions.directMode ||
            previous.allowOffload != newOptions.allowOffload
    }

    /**
     * Solo se pide offload cuando no hay procesamiento en la cadena
     * (requerimiento seccion 17: "audio offload cuando los efectos esten
     * desactivados").
     */
    fun offloadPreferences(): TrackSelectionParameters.AudioOffloadPreferences {
        val current = options
        val mode = if (current.directMode && current.allowOffload) {
            TrackSelectionParameters.AudioOffloadPreferences.AUDIO_OFFLOAD_MODE_ENABLED
        } else {
            TrackSelectionParameters.AudioOffloadPreferences.AUDIO_OFFLOAD_MODE_DISABLED
        }
        return TrackSelectionParameters.AudioOffloadPreferences.Builder()
            .setAudioOffloadMode(mode)
            .build()
    }

    /**
     * Inserta los dos procesadores propios al principio de la cadena de audio,
     * en el orden que fija el requerimiento 5.2. setAudioProcessors conserva la
     * cadena por omision de Media3, de modo que el salto de silencios y el
     * Sonic de velocidad y tono siguen presentes despues.
     */
    fun createRenderersFactory(): RenderersFactory =
        object : DefaultRenderersFactory(context) {
            override fun buildAudioSink(
                context: Context,
                enableFloatOutput: Boolean,
                enableAudioTrackPlaybackParams: Boolean,
            ): AudioSink = DefaultAudioSink.Builder(context)
                .setAudioProcessors(arrayOf(equalizerProcessor, enhancerProcessor))
                .setEnableFloatOutput(enableFloatOutput)
                .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
                .build()
        }

    companion object {
        const val MAX_CROSSFADE_SECONDS = 12

        fun defaultOptions() = PlaybackOptions(
            gaplessEnabled = true,
            crossfadeSeconds = 0,
            fadeOnPause = true,
            fadeOnPauseMs = 250,
            directMode = false,
            allowOffload = true,
        )
    }
}
