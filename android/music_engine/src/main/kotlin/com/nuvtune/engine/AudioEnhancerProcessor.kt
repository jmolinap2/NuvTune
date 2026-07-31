package com.nuvtune.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Cadena de mejora perceptual (requerimiento seccion 5.2).
 *
 * Va inmediatamente despues de [EqualizerAudioProcessor], de modo que el orden
 * total de la cadena es exactamente el que fija el requerimiento:
 *
 *   decodificacion -> ganancia previa -> ecualizador   (EqualizerAudioProcessor)
 *   -> realce de detalle -> dinamica multibanda -> normalizacion
 *   -> expansion estereo -> limitador -> salida        (esta clase)
 *
 * Se implementa como DSP propio y no con `android.media.audiofx.DynamicsProcessing`
 * por la misma razon que el ecualizador: esa API delega en la implementacion del
 * fabricante, que no garantiza ni el numero de bandas ni las frecuencias, y el
 * resultado dejaria de ser reproducible entre dispositivos.
 *
 * El limitador es lo ultimo de la cadena y no se puede desactivar mientras la
 * mejora este activa: es lo que impide que la suma de refuerzos sature la
 * salida.
 */
@OptIn(UnstableApi::class)
internal class AudioEnhancerProcessor : BaseAudioProcessor() {

    /**
     * Parametros ya convertidos a coeficientes para una frecuencia de muestreo
     * concreta. Inmutable: el hilo de interfaz publica una instancia nueva y el
     * hilo de audio la lee sin bloquear.
     */
    private class Tuning(
        val detailMix: Float,
        val detailDriveGain: Float,
        val compressorEnabled: Boolean,
        val bandThresholdsDb: FloatArray,
        val bandRatios: FloatArray,
        val bandAttack: FloatArray,
        val bandRelease: FloatArray,
        val bandMakeup: FloatArray,
        val normalizationGain: Float,
        val normalizationAdaptive: Boolean,
        val normalizationTargetRms: Float,
        val stereoWidth: Float,
        val limiterThreshold: Float,
        val limiterRelease: Float,
    )

    @Volatile
    private var settings: EnhancementSettings = defaultSettings()

    @Volatile
    private var directMode: Boolean = false

    @Volatile
    private var tuning: Tuning? = null

    private var sampleRate: Int = 0
    private var channelCount: Int = 0

    // -- Estado de los filtros de cruce ------------------------------------
    // Linkwitz-Riley de cuarto orden: dos Butterworth de segundo orden en
    // cascada por cada rama, de modo que la suma de las bandas queda plana.
    private var lowSplit: Array<BiquadPair> = emptyArray()
    private var highSplit: Array<BiquadPair> = emptyArray()
    private var detailHighPass: Array<BiquadPair> = emptyArray()

    // -- Estado de los compresores -----------------------------------------
    private var bandEnvelope: Array<FloatArray> = emptyArray()

    // -- Estado de la normalizacion en vivo --------------------------------
    private var runningRms: Float = 0f
    private var adaptiveGain: Float = 1f

    // -- Estado del limitador ----------------------------------------------
    private var lookAhead: Array<FloatArray> = emptyArray()
    private var lookAheadIndex: Int = 0
    private var lookAheadSize: Int = 0
    private var limiterGain: Float = 1f

    fun updateSettings(newSettings: EnhancementSettings) {
        settings = newSettings
        rebuildTuning()
    }

    fun updateDirectMode(enabled: Boolean) {
        directMode = enabled
    }

    fun currentSettings(): EnhancementSettings = settings

    /**
     * Solo el modo directo saca el procesador de la cadena, que es lo que el
     * requerimiento 5.5 pide para FLAC/ALAC/WAV y DAC externo: el procesador
     * deja de existir para Media3 y con ello se vuelve a permitir audio
     * offload.
     *
     * Apagar la mejora no lo saca de la cadena, solo lo deja en paso directo.
     * Es deliberado: reconstruir la cadena obliga a volver a preparar la pista
     * y la comparacion A/B del requerimiento 5.1 tiene que ser instantanea.
     */
    override fun isActive(): Boolean = !directMode

    override fun onConfigure(
        inputAudioFormat: AudioProcessor.AudioFormat,
    ): AudioProcessor.AudioFormat {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT &&
            inputAudioFormat.encoding != C.ENCODING_PCM_FLOAT
        ) {
            throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
        }
        sampleRate = inputAudioFormat.sampleRate
        channelCount = inputAudioFormat.channelCount

        lowSplit = Array(channelCount) { BiquadPair() }
        highSplit = Array(channelCount) { BiquadPair() }
        detailHighPass = Array(channelCount) { BiquadPair() }
        bandEnvelope = Array(BAND_COUNT) { FloatArray(channelCount) }

        lookAheadSize = max(1, (sampleRate * LOOK_AHEAD_MS / 1000.0).toInt())
        lookAhead = Array(channelCount) { FloatArray(lookAheadSize) }
        lookAheadIndex = 0
        limiterGain = 1f
        adaptiveGain = 1f
        runningRms = 0f

        rebuildTuning()
        return inputAudioFormat
    }

    override fun onFlush() {
        for (pair in lowSplit) pair.reset()
        for (pair in highSplit) pair.reset()
        for (pair in detailHighPass) pair.reset()
        for (band in bandEnvelope) band.fill(0f)
        for (channel in lookAhead) channel.fill(0f)
        lookAheadIndex = 0
        limiterGain = 1f
        adaptiveGain = 1f
        runningRms = 0f
    }

    override fun onReset() {
        lowSplit = emptyArray()
        highSplit = emptyArray()
        detailHighPass = emptyArray()
        bandEnvelope = emptyArray()
        lookAhead = emptyArray()
        tuning = null
        sampleRate = 0
        channelCount = 0
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val limit = inputBuffer.limit()
        val remaining = limit - inputBuffer.position()
        if (remaining == 0) return

        val output = replaceOutputBuffer(remaining)
        val active = tuning

        if (active == null) {
            output.put(inputBuffer)
        } else if (inputAudioFormat.encoding == C.ENCODING_PCM_16BIT) {
            processPcm16(inputBuffer, output, active)
        } else {
            processPcmFloat(inputBuffer, output, active)
        }

        inputBuffer.position(limit)
        output.flip()
    }

    private fun processPcm16(
        input: ByteBuffer,
        output: ByteBuffer,
        active: Tuning,
    ) {
        val frame = FloatArray(channelCount)
        while (input.remaining() >= channelCount * 2) {
            for (channel in 0 until channelCount) {
                frame[channel] = input.short / PCM16_SCALE
            }
            processFrame(frame, active)
            for (channel in 0 until channelCount) {
                output.putShort((clamp(frame[channel]) * 32767f).toInt().toShort())
            }
        }
    }

    private fun processPcmFloat(
        input: ByteBuffer,
        output: ByteBuffer,
        active: Tuning,
    ) {
        val frame = FloatArray(channelCount)
        while (input.remaining() >= channelCount * 4) {
            for (channel in 0 until channelCount) {
                frame[channel] = input.float
            }
            processFrame(frame, active)
            for (channel in 0 until channelCount) {
                output.putFloat(clamp(frame[channel]))
            }
        }
    }

    /** Aplica la cadena completa a una trama, en el orden de la seccion 5.2. */
    private fun processFrame(frame: FloatArray, active: Tuning) {
        applyDetail(frame, active)
        applyMultiband(frame, active)
        applyNormalization(frame, active)
        applyStereoWidth(frame, active)
        applyLimiter(frame, active)
    }

    /**
     * Realce de detalle: se separa la banda alta, se le aplica saturacion suave
     * para generar armonicos y se remezcla en proporcion baja. No devuelve
     * informacion que el archivo no tenga; solo acentua los transitorios que ya
     * estan presentes, y por eso la interfaz lo advierte en el nivel alto.
     */
    private fun applyDetail(frame: FloatArray, active: Tuning) {
        if (active.detailMix <= 0f) return
        for (channel in frame.indices) {
            val high = detailHighPass[channel].processHighPass(frame[channel])
            val excited = softSaturate(high * active.detailDriveGain)
            frame[channel] += excited * active.detailMix
        }
    }

    /**
     * Procesamiento dinamico de tres bandas. Cada banda lleva su propio
     * detector de envolvente y su propia reduccion, de modo que un golpe de
     * graves no apaga los agudos como haria un compresor de banda ancha.
     */
    private fun applyMultiband(frame: FloatArray, active: Tuning) {
        if (!active.compressorEnabled) return

        for (channel in frame.indices) {
            val sample = frame[channel]

            // Cruce de tres vias: bajo, medio y alto.
            val low = lowSplit[channel].processLowPass(sample)
            val aboveLow = sample - low
            val high = highSplit[channel].processHighPass(aboveLow)
            val mid = aboveLow - high

            val bands = floatArrayOf(low, mid, high)
            var sum = 0f
            for (band in 0 until BAND_COUNT) {
                val value = bands[band]
                val envelope = updateEnvelope(
                    previous = bandEnvelope[band][channel],
                    value = abs(value),
                    attack = active.bandAttack[band],
                    release = active.bandRelease[band],
                )
                bandEnvelope[band][channel] = envelope
                sum += value * bandGain(envelope, band, active) * active.bandMakeup[band]
            }
            frame[channel] = sum
        }
    }

    /**
     * Normalizacion de volumen. En modo analizado se aplica la ganancia
     * calculada previamente para la pista (tipo ReplayGain), que es estatica y
     * no altera la dinamica. En modo en vivo se sigue la energia de la senal y
     * se corrige despacio hacia el objetivo.
     */
    private fun applyNormalization(frame: FloatArray, active: Tuning) {
        if (active.normalizationGain != 1f) {
            for (channel in frame.indices) {
                frame[channel] *= active.normalizationGain
            }
        }

        if (!active.normalizationAdaptive) return

        var energy = 0f
        for (channel in frame.indices) {
            energy += frame[channel] * frame[channel]
        }
        energy /= frame.size

        // Media movil de la energia, con una constante larga para que los
        // silencios y los golpes no muevan la ganancia de forma audible.
        runningRms += (sqrt(energy) - runningRms) * RMS_SMOOTHING

        if (runningRms > NORMALIZATION_FLOOR) {
            val desired = (active.normalizationTargetRms / runningRms)
                .coerceIn(MIN_NORMALIZATION_GAIN, MAX_NORMALIZATION_GAIN)
            adaptiveGain += (desired - adaptiveGain) * NORMALIZATION_SMOOTHING
        }

        for (channel in frame.indices) {
            frame[channel] *= adaptiveGain
        }
    }

    /**
     * Expansion estereo por medio y lados. El componente medio no se toca, de
     * modo que la mezcla a mono sigue siendo correcta: es la condicion que pide
     * el requerimiento para no romper la compatibilidad.
     */
    private fun applyStereoWidth(frame: FloatArray, active: Tuning) {
        if (active.stereoWidth == 1f || frame.size < 2) return
        val mid = (frame[0] + frame[1]) * 0.5f
        val side = (frame[0] - frame[1]) * 0.5f * active.stereoWidth
        frame[0] = mid + side
        frame[1] = mid - side
    }

    /**
     * Limitador de pico con anticipacion. La senal sale retrasada
     * [LOOK_AHEAD_MS] milisegundos, lo justo para que la ganancia ya este baja
     * cuando llega el pico y no se oiga el ataque del limitador.
     */
    private fun applyLimiter(frame: FloatArray, active: Tuning) {
        var peak = 0f
        for (channel in frame.indices) {
            val stored = lookAhead[channel][lookAheadIndex]
            lookAhead[channel][lookAheadIndex] = frame[channel]
            frame[channel] = stored
            val magnitude = abs(lookAhead[channel][lookAheadIndex])
            if (magnitude > peak) peak = magnitude
        }
        lookAheadIndex = (lookAheadIndex + 1) % lookAheadSize

        val required = if (peak > active.limiterThreshold) {
            active.limiterThreshold / peak
        } else {
            1f
        }

        // Ataque instantaneo y recuperacion lenta: bajar tarde produce
        // distorsion, subir rapido produce bombeo.
        limiterGain = if (required < limiterGain) {
            required
        } else {
            limiterGain + (required - limiterGain) * active.limiterRelease
        }

        for (channel in frame.indices) {
            frame[channel] = clamp(frame[channel] * limiterGain)
        }
    }

    private fun bandGain(envelope: Float, band: Int, active: Tuning): Float {
        if (envelope <= 0f) return 1f
        val levelDb = 20f * log10(envelope + EPSILON)
        val threshold = active.bandThresholdsDb[band]
        if (levelDb <= threshold) return 1f
        val excess = levelDb - threshold
        val reductionDb = excess * (1f - 1f / active.bandRatios[band])
        return 10f.pow(-reductionDb / 20f)
    }

    private fun rebuildTuning() {
        val rate = sampleRate
        if (rate <= 0) {
            tuning = null
            return
        }

        val current = settings
        if (!current.enabled) {
            tuning = null
            return
        }

        for (channel in 0 until channelCount) {
            lowSplit[channel].configureLinkwitzRiley(LOW_CROSSOVER_HZ, rate)
            highSplit[channel].configureLinkwitzRiley(HIGH_CROSSOVER_HZ, rate)
            detailHighPass[channel].configureLinkwitzRiley(DETAIL_CROSSOVER_HZ, rate)
        }

        val detail = current.detail
        val strength = current.multibandStrength.coerceIn(0.0, 1.0).toFloat()

        // Los umbrales bajan y las relaciones suben con la intensidad elegida:
        // en cero el compresor no toca nada, en uno trabaja de forma evidente.
        val thresholds = FloatArray(BAND_COUNT) { band ->
            BASE_THRESHOLDS_DB[band] - strength * THRESHOLD_RANGE_DB
        }
        val ratios = FloatArray(BAND_COUNT) { band ->
            1f + (BASE_RATIOS[band] - 1f) * strength
        }
        val makeup = FloatArray(BAND_COUNT) { band ->
            10f.pow(strength * MAKEUP_DB[band] / 20f)
        }

        val normalization = when (current.normalization) {
            NormalizationMode.OFF -> 1f
            NormalizationMode.LIVE -> 1f
            NormalizationMode.ANALYZED -> dbToLinear(current.trackGainDb).toFloat()
        }

        tuning = Tuning(
            detailMix = DETAIL_MIX[detail.ordinal],
            detailDriveGain = DETAIL_DRIVE[detail.ordinal],
            compressorEnabled = strength > 0f,
            bandThresholdsDb = thresholds,
            bandRatios = ratios,
            bandAttack = FloatArray(BAND_COUNT) { band ->
                timeConstant(ATTACK_MS[band], rate)
            },
            bandRelease = FloatArray(BAND_COUNT) { band ->
                timeConstant(RELEASE_MS[band], rate)
            },
            bandMakeup = makeup,
            normalizationGain = normalization,
            normalizationAdaptive = current.normalization == NormalizationMode.LIVE,
            normalizationTargetRms = dbToLinear(current.targetLevelDb).toFloat(),
            // La expansion estereo esta desactivada por omision y su intensidad
            // esta limitada, tal como pide el requerimiento.
            stereoWidth = if (current.stereoExpansionEnabled) {
                (1.0 + current.stereoWidth.coerceIn(0.0, 1.0) * (MAX_WIDTH - 1.0)).toFloat()
            } else {
                1f
            },
            limiterThreshold = LIMITER_THRESHOLD,
            limiterRelease = timeConstantComplement(LIMITER_RELEASE_MS, rate),
        )
    }

    /**
     * Par de biquads en cascada, que es lo que forma un Linkwitz-Riley de
     * cuarto orden a partir de dos Butterworth de segundo orden.
     */
    private class BiquadPair {
        private var b0 = 1f
        private var b1 = 0f
        private var b2 = 0f
        private var a1 = 0f
        private var a2 = 0f

        private var lowZ1 = 0f
        private var lowZ2 = 0f
        private var lowZ3 = 0f
        private var lowZ4 = 0f

        private var highB0 = 1f
        private var highB1 = 0f
        private var highB2 = 0f
        private var highZ1 = 0f
        private var highZ2 = 0f
        private var highZ3 = 0f
        private var highZ4 = 0f

        fun reset() {
            lowZ1 = 0f; lowZ2 = 0f; lowZ3 = 0f; lowZ4 = 0f
            highZ1 = 0f; highZ2 = 0f; highZ3 = 0f; highZ4 = 0f
        }

        fun configureLinkwitzRiley(frequencyHz: Double, sampleRate: Int) {
            val nyquist = sampleRate / 2.0
            val frequency = frequencyHz.coerceAtMost(nyquist * 0.95)
            val omega = 2.0 * Math.PI * frequency / sampleRate
            val cosOmega = cos(omega)
            val alpha = sin(omega) / (2.0 * BUTTERWORTH_Q)
            val a0 = 1.0 + alpha

            a1 = (-2.0 * cosOmega / a0).toFloat()
            a2 = ((1.0 - alpha) / a0).toFloat()

            b0 = ((1.0 - cosOmega) / 2.0 / a0).toFloat()
            b1 = ((1.0 - cosOmega) / a0).toFloat()
            b2 = b0

            highB0 = ((1.0 + cosOmega) / 2.0 / a0).toFloat()
            highB1 = (-(1.0 + cosOmega) / a0).toFloat()
            highB2 = highB0
        }

        fun processLowPass(input: Float): Float {
            val first = b0 * input + lowZ1
            lowZ1 = b1 * input - a1 * first + lowZ2
            lowZ2 = b2 * input - a2 * first
            val second = b0 * first + lowZ3
            lowZ3 = b1 * first - a1 * second + lowZ4
            lowZ4 = b2 * first - a2 * second
            return second
        }

        fun processHighPass(input: Float): Float {
            val first = highB0 * input + highZ1
            highZ1 = highB1 * input - a1 * first + highZ2
            highZ2 = highB2 * input - a2 * first
            val second = highB0 * first + highZ3
            highZ3 = highB1 * first - a1 * second + highZ4
            highZ4 = highB2 * first - a2 * second
            return second
        }
    }

    companion object {
        private const val BAND_COUNT = 3
        private const val PCM16_SCALE = 32768f
        private const val EPSILON = 1e-9f

        private const val BUTTERWORTH_Q = 0.70710678

        private const val LOW_CROSSOVER_HZ = 250.0
        private const val HIGH_CROSSOVER_HZ = 4000.0
        private const val DETAIL_CROSSOVER_HZ = 5000.0

        /** Mezcla del armonico generado, por nivel de realce. */
        private val DETAIL_MIX = floatArrayOf(0f, 0.12f, 0.24f, 0.40f)
        private val DETAIL_DRIVE = floatArrayOf(1f, 2.0f, 3.2f, 4.8f)

        private val BASE_THRESHOLDS_DB = floatArrayOf(-18f, -20f, -22f)
        private const val THRESHOLD_RANGE_DB = 8f
        private val BASE_RATIOS = floatArrayOf(3.0f, 2.5f, 2.0f)
        private val MAKEUP_DB = floatArrayOf(3.0f, 2.5f, 2.0f)

        private val ATTACK_MS = floatArrayOf(20f, 10f, 4f)
        private val RELEASE_MS = floatArrayOf(250f, 160f, 90f)

        private const val LOOK_AHEAD_MS = 3.0
        private const val LIMITER_THRESHOLD = 0.97f
        private const val LIMITER_RELEASE_MS = 120f

        private const val RMS_SMOOTHING = 0.0005f
        private const val NORMALIZATION_SMOOTHING = 0.0002f
        private const val NORMALIZATION_FLOOR = 0.0015f
        private const val MIN_NORMALIZATION_GAIN = 0.25f
        private const val MAX_NORMALIZATION_GAIN = 4f

        private const val MAX_WIDTH = 1.8

        /**
         * Saturacion suave. Se usa `tanh` porque su curva no tiene esquinas: el
         * armonico aparece de forma gradual en lugar de recortar.
         */
        private fun softSaturate(value: Float): Float {
            val exp2x = exp(2.0 * value)
            return ((exp2x - 1.0) / (exp2x + 1.0)).toFloat()
        }

        private fun updateEnvelope(
            previous: Float,
            value: Float,
            attack: Float,
            release: Float,
        ): Float = if (value > previous) {
            value + (previous - value) * attack
        } else {
            value + (previous - value) * release
        }

        /** Coeficiente de un filtro de un polo para una constante de tiempo. */
        private fun timeConstant(milliseconds: Float, sampleRate: Int): Float =
            exp(-1.0 / (sampleRate * milliseconds / 1000.0)).toFloat()

        private fun timeConstantComplement(milliseconds: Float, sampleRate: Int): Float =
            1f - timeConstant(milliseconds, sampleRate)

        private fun dbToLinear(db: Double): Double = 10.0.pow(db / 20.0)

        private fun clamp(value: Float): Float = when {
            value > 1f -> 1f
            value < -1f -> -1f
            else -> value
        }

        /**
         * Convierte una medida de energia RMS a decibelios, que es lo que usa
         * el analisis de sonoridad almacenado.
         */
        fun rmsToDb(rms: Double): Double = 20.0 * ln(rms + EPSILON) / ln(10.0)

        fun defaultSettings() = EnhancementSettings(
            enabled = false,
            profile = EnhancementProfile.BALANCED,
            detail = DetailLevel.OFF,
            multibandStrength = 0.0,
            normalization = NormalizationMode.OFF,
            targetLevelDb = -14.0,
            stereoExpansionEnabled = false,
            stereoWidth = 0.0,
            trackGainDb = 0.0,
        )
    }
}
