package com.nuvtune.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin

/**
 * Ecualizador grafico, ganancia previa, balance y conversion a mono
 * (requerimiento secciones 5.3 y 5.5).
 *
 * Se implementa como AudioProcessor propio en lugar de usar
 * android.media.audiofx.Equalizer porque esa API expone el numero de bandas que
 * decide cada fabricante (normalmente cinco) y con frecuencias distintas segun
 * el dispositivo. El requerimiento pide 10 bandas fijas en el MVP y 15 o 20 en
 * modo avanzado, de modo que las bandas deben ser deterministas.
 *
 * Orden interno de la cadena, segun la seccion 5.3: ganancia previa, luego
 * ecualizador. El control de velocidad y tono lo aplica despues el
 * SonicAudioProcessor que Media3 agrega al final de la cadena por omision.
 */
@OptIn(UnstableApi::class)
internal class EqualizerAudioProcessor : BaseAudioProcessor() {

    /**
     * Coeficientes ya calculados para una frecuencia de muestreo concreta. Es
     * inmutable: el hilo de interfaz publica una instancia nueva y el hilo de
     * audio la lee sin bloquear.
     */
    private class Coefficients(
        val bandCount: Int,
        /** Cinco coeficientes normalizados por banda: b0, b1, b2, a1, a2. */
        val values: FloatArray,
        val preampLinear: Float,
        val leftGain: Float,
        val rightGain: Float,
        val mono: Boolean,
        val bypass: Boolean,
    )

    @Volatile
    private var settings: EqualizerSettings = defaultSettings(BANDS_10)

    /**
     * Cuando el modo directo esta activo el procesador se declara inactivo y
     * Media3 lo saca de la cadena, lo que permite audio offload
     * (requerimiento secciones 5.5 y 17).
     */
    @Volatile
    private var directMode: Boolean = false

    @Volatile
    private var coefficients: Coefficients? = null

    private var configuredSampleRate: Int = 0
    private var configuredChannelCount: Int = 0

    /** Estado de cada biquad: [canal][banda * 2] con las dos muestras previas. */
    private var filterState: Array<FloatArray> = emptyArray()

    fun updateSettings(newSettings: EqualizerSettings) {
        settings = newSettings
        rebuildCoefficients()
    }

    fun updateDirectMode(enabled: Boolean) {
        directMode = enabled
    }

    fun currentSettings(): EqualizerSettings = settings

    override fun onConfigure(
        inputAudioFormat: AudioProcessor.AudioFormat,
    ): AudioProcessor.AudioFormat {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT &&
            inputAudioFormat.encoding != C.ENCODING_PCM_FLOAT
        ) {
            throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
        }
        configuredSampleRate = inputAudioFormat.sampleRate
        configuredChannelCount = inputAudioFormat.channelCount
        filterState = Array(configuredChannelCount) { FloatArray(MAX_BANDS * 2) }
        rebuildCoefficients()
        return inputAudioFormat
    }

    override fun isActive(): Boolean = !directMode

    override fun onFlush() {
        for (channel in filterState) {
            channel.fill(0f)
        }
    }

    override fun onReset() {
        filterState = emptyArray()
        coefficients = null
        configuredSampleRate = 0
        configuredChannelCount = 0
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val limit = inputBuffer.limit()
        val remaining = limit - inputBuffer.position()
        if (remaining == 0) return

        val output = replaceOutputBuffer(remaining)
        val active = coefficients

        if (active == null || active.bypass) {
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
        active: Coefficients,
    ) {
        val channels = configuredChannelCount
        val frame = FloatArray(channels)
        while (input.remaining() >= channels * 2) {
            for (channel in 0 until channels) {
                frame[channel] = input.short / PCM16_SCALE
            }
            processFrame(frame, active)
            for (channel in 0 until channels) {
                output.putShort(toPcm16(frame[channel]))
            }
        }
    }

    private fun processPcmFloat(
        input: ByteBuffer,
        output: ByteBuffer,
        active: Coefficients,
    ) {
        val channels = configuredChannelCount
        val frame = FloatArray(channels)
        while (input.remaining() >= channels * 4) {
            for (channel in 0 until channels) {
                frame[channel] = input.float
            }
            processFrame(frame, active)
            for (channel in 0 until channels) {
                output.putFloat(clamp(frame[channel]))
            }
        }
    }

    /**
     * Aplica, en este orden: mono, ganancia previa, cascada de biquads y
     * balance. La conversion a mono va primero para que ambos canales
     * atraviesen filtros con el mismo estado y no se desfasen.
     */
    private fun processFrame(frame: FloatArray, active: Coefficients) {
        val channels = frame.size

        if (active.mono && channels >= 2) {
            var sum = 0f
            for (channel in 0 until channels) {
                sum += frame[channel]
            }
            val mixed = sum / channels
            for (channel in 0 until channels) {
                frame[channel] = mixed
            }
        }

        for (channel in 0 until channels) {
            var sample = frame[channel] * active.preampLinear
            val state = filterState[channel]
            for (band in 0 until active.bandCount) {
                val offset = band * 5
                val b0 = active.values[offset]
                val b1 = active.values[offset + 1]
                val b2 = active.values[offset + 2]
                val a1 = active.values[offset + 3]
                val a2 = active.values[offset + 4]

                // Forma directa II transpuesta: dos registros de estado por
                // banda y menor error de redondeo que la forma directa I.
                val stateOffset = band * 2
                val z1 = state[stateOffset]
                val z2 = state[stateOffset + 1]
                val result = b0 * sample + z1
                state[stateOffset] = b1 * sample - a1 * result + z2
                state[stateOffset + 1] = b2 * sample - a2 * result
                sample = result
            }
            frame[channel] = sample
        }

        if (channels >= 2) {
            frame[0] *= active.leftGain
            frame[1] *= active.rightGain
        }

        for (channel in 0 until channels) {
            frame[channel] = clamp(frame[channel])
        }
    }

    private fun rebuildCoefficients() {
        val sampleRate = configuredSampleRate
        if (sampleRate <= 0) {
            coefficients = null
            return
        }

        val current = settings
        val gains = current.bandGainsDb
        val bandCount = gains.size
        val frequencies = centerFrequencies(bandCount)
        val bandwidthOctaves = bandwidthOctavesFor(bandCount)
        val q = qualityFactor(bandwidthOctaves)

        val values = FloatArray(bandCount * 5)
        for (band in 0 until bandCount) {
            val gainDb = gains[band].coerceIn(MIN_GAIN_DB, MAX_GAIN_DB)
            writePeakingCoefficients(
                target = values,
                offset = band * 5,
                frequencyHz = frequencies[band],
                gainDb = gainDb,
                q = q,
                sampleRate = sampleRate,
            )
        }

        // Ganancia previa efectiva. Cuando varias bandas suben, se descuenta la
        // banda mas alta para no llegar al limitador con la senal saturada
        // (requerimiento seccion 5.3: la ganancia previa debe disminuir
        // automaticamente).
        var preampDb = current.preampDb
        if (current.autoPreventClipping) {
            val highestBoost = gains.maxOrNull() ?: 0.0
            if (highestBoost > 0.0) {
                preampDb -= highestBoost
            }
        }

        val balance = current.balance.coerceIn(-1.0, 1.0)

        val everythingNeutral = !current.enabled ||
            (gains.all { it == 0.0 } && preampDb == 0.0 && balance == 0.0 && !current.monoOutput)

        coefficients = Coefficients(
            bandCount = bandCount,
            values = values,
            preampLinear = dbToLinear(preampDb).toFloat(),
            // El balance atenua el canal opuesto en lugar de amplificar, para
            // no introducir clipping al desplazar la imagen.
            leftGain = (if (balance > 0) 1.0 - balance else 1.0).toFloat(),
            rightGain = (if (balance < 0) 1.0 + balance else 1.0).toFloat(),
            mono = current.monoOutput,
            bypass = everythingNeutral,
        )
    }

    companion object {
        const val BANDS_10 = 10
        const val BANDS_15 = 15
        const val BANDS_20 = 20
        const val MAX_BANDS = BANDS_20

        const val MIN_GAIN_DB = -12.0
        const val MAX_GAIN_DB = 12.0

        private const val PCM16_SCALE = 32768f

        /** Bandas de octava ISO. */
        private val frequencies10 = doubleArrayOf(
            31.5, 63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0,
        )

        /** Bandas de un tercio de octava reducidas a 15 puntos. */
        private val frequencies15 = doubleArrayOf(
            25.0, 40.0, 63.0, 100.0, 160.0, 250.0, 400.0, 630.0,
            1000.0, 1600.0, 2500.0, 4000.0, 6300.0, 10000.0, 16000.0,
        )

        /** Bandas de media octava, el reparto habitual de un grafico de 20. */
        private val frequencies20 = doubleArrayOf(
            25.0, 35.0, 50.0, 70.0, 100.0, 140.0, 200.0, 280.0, 400.0, 560.0,
            800.0, 1100.0, 1600.0, 2200.0, 3200.0, 4500.0, 6300.0, 9000.0,
            12500.0, 18000.0,
        )

        fun centerFrequencies(bandCount: Int): DoubleArray = when (bandCount) {
            BANDS_15 -> frequencies15
            BANDS_20 -> frequencies20
            else -> frequencies10
        }

        private fun bandwidthOctavesFor(bandCount: Int): Double = when (bandCount) {
            BANDS_15 -> 2.0 / 3.0
            BANDS_20 -> 0.5
            else -> 1.0
        }

        /**
         * Factor de calidad que corresponde a un ancho de banda dado en
         * octavas: Q = 2^(N/2) / (2^N - 1).
         */
        private fun qualityFactor(bandwidthOctaves: Double): Double =
            2.0.pow(bandwidthOctaves / 2.0) / (2.0.pow(bandwidthOctaves) - 1.0)

        private fun dbToLinear(db: Double): Double = 10.0.pow(db / 20.0)

        /**
         * Filtro de pico (peaking EQ) del recetario de Robert Bristow-Johnson,
         * normalizado por a0.
         */
        private fun writePeakingCoefficients(
            target: FloatArray,
            offset: Int,
            frequencyHz: Double,
            gainDb: Double,
            q: Double,
            sampleRate: Int,
        ) {
            // Una banda por encima de Nyquist no puede filtrarse: se deja como
            // paso directo.
            if (frequencyHz >= sampleRate / 2.0) {
                target[offset] = 1f
                target[offset + 1] = 0f
                target[offset + 2] = 0f
                target[offset + 3] = 0f
                target[offset + 4] = 0f
                return
            }

            val amplitude = 10.0.pow(gainDb / 40.0)
            val omega = 2.0 * Math.PI * frequencyHz / sampleRate
            val cosOmega = cos(omega)
            val alpha = sin(omega) / (2.0 * q)

            val b0 = 1.0 + alpha * amplitude
            val b1 = -2.0 * cosOmega
            val b2 = 1.0 - alpha * amplitude
            val a0 = 1.0 + alpha / amplitude
            val a1 = -2.0 * cosOmega
            val a2 = 1.0 - alpha / amplitude

            target[offset] = (b0 / a0).toFloat()
            target[offset + 1] = (b1 / a0).toFloat()
            target[offset + 2] = (b2 / a0).toFloat()
            target[offset + 3] = (a1 / a0).toFloat()
            target[offset + 4] = (a2 / a0).toFloat()
        }

        private fun clamp(value: Float): Float = when {
            value > 1f -> 1f
            value < -1f -> -1f
            else -> value
        }

        private fun toPcm16(value: Float): Short =
            (clamp(value) * 32767f).toInt().toShort()

        fun defaultSettings(bandCount: Int) = EqualizerSettings(
            enabled = false,
            bandGainsDb = List(bandCount) { 0.0 },
            preampDb = 0.0,
            autoPreventClipping = true,
            balance = 0.0,
            monoOutput = false,
        )

        /** Numeros de banda que acepta el motor (requerimiento seccion 5.3). */
        fun isSupportedBandCount(bandCount: Int): Boolean =
            bandCount == BANDS_10 || bandCount == BANDS_15 || bandCount == BANDS_20
    }
}
