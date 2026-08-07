package com.nuvtune.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

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

    /**
     * El analisis se activa solo mientras el reproductor completo esta visible.
     * Se hace aqui, sobre el PCM que NuvTune ya procesa, para no solicitar
     * permiso de microfono ni depender de android.media.audiofx.Visualizer.
     */
    @Volatile
    private var analysisEnabled: Boolean = false

    @Volatile
    private var analysisListener: ((AudioAnalysisFrame) -> Unit)? = null

    private var configuredSampleRate: Int = 0
    private var configuredChannelCount: Int = 0

    /** Estado de cada biquad: [canal][banda * 2] con las dos muestras previas. */
    private var filterState: Array<FloatArray> = emptyArray()

    private var wasAnalyzing = false
    private var analysisFrames = 0
    private var analysisEnergy = 0.0
    private var bassEnergy = 0.0
    private var midEnergy = 0.0
    private var trebleEnergy = 0.0
    private var analysisLowPass = 0f
    private var analysisMidPass = 0f
    private var analysisPeak = 0.08
    private var bassEnvelope = 0.0
    private var beatPulse = 0.0
    private var smoothedLevel = 0.0
    private var smoothedBass = 0.0
    private var smoothedMid = 0.0
    private var smoothedTreble = 0.0

    /**
     * Ventana espectral reutilizable. El PCM se reduce como maximo a 32 kHz,
     * suficiente para representar hasta 16 kHz y mantener una ventana Hann de
     * 2048 muestras economica incluso con archivos de alta resolucion.
     */
    private val spectrumWindow = DoubleArray(SPECTRUM_FFT_SIZE) { index ->
        0.5 - 0.5 * cos(2.0 * Math.PI * index / (SPECTRUM_FFT_SIZE - 1))
    }
    private val spectrumRing = DoubleArray(SPECTRUM_FFT_SIZE)
    private val spectrumReal = DoubleArray(SPECTRUM_FFT_SIZE)
    private val spectrumImaginary = DoubleArray(SPECTRUM_FFT_SIZE)
    private val spectrumRaw = DoubleArray(SPECTRUM_BAND_COUNT)
    private val smoothedSpectrum = DoubleArray(SPECTRUM_BAND_COUNT)
    private val spectrumBandStartBins = IntArray(SPECTRUM_BAND_COUNT)
    private val spectrumBandEndBins = IntArray(SPECTRUM_BAND_COUNT)

    private var spectrumSampleRate = 0
    private var spectrumWriteIndex = 0
    private var spectrumSampleCount = 0
    private var spectrumResamplePhase = 0
    private var spectrumResampleSum = 0.0
    private var spectrumResampleCount = 0
    private var spectrumPeak = SPECTRUM_INITIAL_PEAK

    fun updateSettings(newSettings: EqualizerSettings) {
        settings = newSettings
        rebuildCoefficients()
    }

    fun updateDirectMode(enabled: Boolean) {
        directMode = enabled
    }

    fun currentSettings(): EqualizerSettings = settings

    fun setAnalysisEnabled(enabled: Boolean) {
        analysisEnabled = enabled
    }

    fun setAnalysisListener(listener: ((AudioAnalysisFrame) -> Unit)?) {
        analysisListener = listener
    }

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
        resetAnalysis()
        rebuildCoefficients()
        return inputAudioFormat
    }

    override fun isActive(): Boolean = !directMode

    override fun onFlush() {
        for (channel in filterState) {
            channel.fill(0f)
        }
        resetAnalysis()
    }

    override fun onReset() {
        filterState = emptyArray()
        coefficients = null
        configuredSampleRate = 0
        configuredChannelCount = 0
        resetAnalysis()
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val limit = inputBuffer.limit()
        val remaining = limit - inputBuffer.position()
        if (remaining == 0) return

        val output = replaceOutputBuffer(remaining)
        val active = coefficients

        if (analysisEnabled && analysisListener != null) {
            wasAnalyzing = true
            analyze(inputBuffer.duplicate().order(inputBuffer.order()))
        } else if (wasAnalyzing) {
            resetAnalysis()
        }

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

    /**
     * Calcula el resumen RMS de tres regiones tonales y conserva una ventana
     * remuestreada para el espectro FFT de 24 bandas. Todo se ejecuta sobre el
     * duplicado del PCM, sin alterar la posicion ni la ruta de reproduccion.
     */
    private fun analyze(input: ByteBuffer) {
        val channels = configuredChannelCount
        val sampleRate = configuredSampleRate
        if (channels <= 0 || sampleRate <= 0) return

        val bytesPerSample = if (inputAudioFormat.encoding == C.ENCODING_PCM_16BIT) 2 else 4
        val frameBytes = channels * bytesPerSample
        val targetFrames = max(1, sampleRate / ANALYSIS_UPDATES_PER_SECOND)
        val lowAlpha = 1.0 - exp(-2.0 * Math.PI * LOW_CROSSOVER_HZ / sampleRate)
        val midAlpha = 1.0 - exp(-2.0 * Math.PI * MID_CROSSOVER_HZ / sampleRate)

        while (input.remaining() >= frameBytes) {
            var mono = 0f
            for (channel in 0 until channels) {
                mono += if (bytesPerSample == 2) {
                    input.short / PCM16_SCALE
                } else {
                    input.float
                }
            }
            mono /= channels

            collectSpectrumSample(mono.toDouble(), sampleRate)

            analysisLowPass += (lowAlpha * (mono - analysisLowPass)).toFloat()
            analysisMidPass += (midAlpha * (mono - analysisMidPass)).toFloat()
            val bass = analysisLowPass
            val mid = analysisMidPass - analysisLowPass
            val treble = mono - analysisMidPass

            analysisEnergy += mono * mono
            bassEnergy += bass * bass
            midEnergy += mid * mid
            trebleEnergy += treble * treble
            analysisFrames++

            if (analysisFrames >= targetFrames) publishAnalysisFrame()
        }
    }

    private fun publishAnalysisFrame() {
        val count = analysisFrames.coerceAtLeast(1).toDouble()
        val rawLevel = sqrt(analysisEnergy / count)
        val rawBass = sqrt(bassEnergy / count)
        val rawMid = sqrt(midEnergy / count)
        val rawTreble = sqrt(trebleEnergy / count)

        // Pico adaptativo: canciones masterizadas a distinto volumen conservan
        // una animacion con recorrido, sin convertir silencios en golpes.
        analysisPeak = max(rawLevel, analysisPeak * 0.985).coerceAtLeast(0.035)
        val adaptiveGain = (0.72 / analysisPeak).coerceIn(1.0, 12.0)
        val level = (rawLevel * adaptiveGain).coerceIn(0.0, 1.0)
        val bass = (rawBass * adaptiveGain * 1.45).coerceIn(0.0, 1.0)
        val mid = (rawMid * adaptiveGain * 1.45).coerceIn(0.0, 1.0)
        val treble = (rawTreble * adaptiveGain * 1.8).coerceIn(0.0, 1.0)

        smoothedLevel = smooth(smoothedLevel, level, 0.42)
        smoothedBass = smooth(smoothedBass, bass, 0.48)
        smoothedMid = smooth(smoothedMid, mid, 0.38)
        smoothedTreble = smooth(smoothedTreble, treble, 0.32)

        bassEnvelope = smooth(bassEnvelope, bass, 0.12)
        val transient = ((bass - bassEnvelope * 1.16) * 5.5).coerceIn(0.0, 1.0)
        beatPulse = max(transient, beatPulse * 0.55)

        analysisListener?.invoke(
            AudioAnalysisFrame(
                level = smoothedLevel,
                bass = smoothedBass,
                mid = smoothedMid,
                treble = smoothedTreble,
                beat = beatPulse,
                spectrum = calculateSpectrum(),
            ),
        )

        analysisFrames = 0
        analysisEnergy = 0.0
        bassEnergy = 0.0
        midEnergy = 0.0
        trebleEnergy = 0.0
    }

    private fun resetAnalysis() {
        wasAnalyzing = false
        analysisFrames = 0
        analysisEnergy = 0.0
        bassEnergy = 0.0
        midEnergy = 0.0
        trebleEnergy = 0.0
        analysisLowPass = 0f
        analysisMidPass = 0f
        analysisPeak = 0.08
        bassEnvelope = 0.0
        beatPulse = 0.0
        smoothedLevel = 0.0
        smoothedBass = 0.0
        smoothedMid = 0.0
        smoothedTreble = 0.0
        resetSpectrum()
    }

    private fun smooth(previous: Double, value: Double, amount: Double): Double =
        previous + (value - previous) * amount

    /**
     * Remuestreo por promedio de area. Evita alimentar la FFT con 96/192 kHz
     * cuando el ultimo rango visible termina en 16 kHz y, a diferencia de
     * descartar muestras, atenua el aliasing antes de reducir la frecuencia.
     */
    private fun collectSpectrumSample(sample: Double, sourceSampleRate: Int) {
        val targetSampleRate = spectrumSampleRate
        if (targetSampleRate <= 0 || sourceSampleRate <= 0) return

        spectrumResampleSum += sample
        spectrumResampleCount++
        spectrumResamplePhase += targetSampleRate
        if (spectrumResamplePhase < sourceSampleRate) return

        spectrumResamplePhase -= sourceSampleRate
        spectrumRing[spectrumWriteIndex] = spectrumResampleSum / spectrumResampleCount
        spectrumWriteIndex = (spectrumWriteIndex + 1) % SPECTRUM_FFT_SIZE
        spectrumSampleCount = min(spectrumSampleCount + 1, SPECTRUM_FFT_SIZE)
        spectrumResampleSum = 0.0
        spectrumResampleCount = 0
    }

    /**
     * Devuelve una instantanea independiente porque Pigeon la serializa en el
     * hilo principal despues de que el hilo de audio entrega el cuadro.
     */
    private fun calculateSpectrum(): List<Double> {
        if (spectrumSampleCount < SPECTRUM_FFT_SIZE || spectrumSampleRate <= 0) {
            return smoothedSpectrum.toList()
        }

        // writeIndex apunta a la muestra mas antigua una vez lleno el anillo.
        for (index in 0 until SPECTRUM_FFT_SIZE) {
            val sampleIndex = (spectrumWriteIndex + index) % SPECTRUM_FFT_SIZE
            spectrumReal[index] = spectrumRing[sampleIndex] * spectrumWindow[index]
            spectrumImaginary[index] = 0.0
        }
        fftRadix2(spectrumReal, spectrumImaginary)

        var strongestBand = 0.0
        val amplitudeScale = 4.0 / SPECTRUM_FFT_SIZE
        for (band in 0 until SPECTRUM_BAND_COUNT) {
            val start = spectrumBandStartBins[band]
            val end = spectrumBandEndBins[band]
            var maximumPower = 0.0
            var powerSum = 0.0
            for (bin in start until end) {
                val real = spectrumReal[bin]
                val imaginary = spectrumImaginary[bin]
                val power = real * real + imaginary * imaginary
                maximumPower = max(maximumPower, power)
                powerSum += power
            }
            val binCount = max(1, end - start)
            val meanPower = powerSum / binCount
            // El pico conserva lineas tonales; la media estabiliza ruido y
            // mezclas densas sin favorecer artificialmente bandas mas anchas.
            val magnitude = sqrt(maximumPower * 0.72 + meanPower * 0.28) * amplitudeScale
            spectrumRaw[band] = magnitude
            strongestBand = max(strongestBand, magnitude)
        }

        spectrumPeak = max(strongestBand, spectrumPeak * SPECTRUM_PEAK_DECAY)
            .coerceAtLeast(SPECTRUM_MINIMUM_PEAK)
        val adaptiveGain = (SPECTRUM_TARGET_PEAK / spectrumPeak)
            .coerceIn(1.0, SPECTRUM_MAX_GAIN)

        for (band in 0 until SPECTRUM_BAND_COUNT) {
            val raw = spectrumRaw[band]
            val target = if (raw < SPECTRUM_NOISE_FLOOR) {
                0.0
            } else {
                (raw * adaptiveGain).coerceIn(0.0, 1.0).pow(SPECTRUM_COMPRESSION)
            }
            val amount = if (target >= smoothedSpectrum[band]) {
                SPECTRUM_ATTACK
            } else {
                SPECTRUM_RELEASE
            }
            smoothedSpectrum[band] = smooth(smoothedSpectrum[band], target, amount)
                .coerceIn(0.0, 1.0)
        }
        return smoothedSpectrum.toList()
    }

    /** FFT iterativa radix-2 in-place, sin asignaciones por cuadro. */
    private fun fftRadix2(real: DoubleArray, imaginary: DoubleArray) {
        val size = real.size
        var reversed = 0
        for (index in 1 until size) {
            var bit = size shr 1
            while (reversed and bit != 0) {
                reversed = reversed xor bit
                bit = bit shr 1
            }
            reversed = reversed xor bit
            if (index < reversed) {
                val realValue = real[index]
                real[index] = real[reversed]
                real[reversed] = realValue
                val imaginaryValue = imaginary[index]
                imaginary[index] = imaginary[reversed]
                imaginary[reversed] = imaginaryValue
            }
        }

        var blockSize = 2
        while (blockSize <= size) {
            val angle = -2.0 * Math.PI / blockSize
            val stepReal = cos(angle)
            val stepImaginary = sin(angle)
            val half = blockSize / 2
            var blockStart = 0
            while (blockStart < size) {
                var twiddleReal = 1.0
                var twiddleImaginary = 0.0
                for (offset in 0 until half) {
                    val evenIndex = blockStart + offset
                    val oddIndex = evenIndex + half
                    val oddReal = real[oddIndex] * twiddleReal -
                        imaginary[oddIndex] * twiddleImaginary
                    val oddImaginary = real[oddIndex] * twiddleImaginary +
                        imaginary[oddIndex] * twiddleReal
                    val evenReal = real[evenIndex]
                    val evenImaginary = imaginary[evenIndex]

                    real[evenIndex] = evenReal + oddReal
                    imaginary[evenIndex] = evenImaginary + oddImaginary
                    real[oddIndex] = evenReal - oddReal
                    imaginary[oddIndex] = evenImaginary - oddImaginary

                    val nextTwiddleReal = twiddleReal * stepReal -
                        twiddleImaginary * stepImaginary
                    twiddleImaginary = twiddleReal * stepImaginary +
                        twiddleImaginary * stepReal
                    twiddleReal = nextTwiddleReal
                }
                blockStart += blockSize
            }
            blockSize = blockSize shl 1
        }
    }

    private fun resetSpectrum() {
        spectrumRing.fill(0.0)
        spectrumReal.fill(0.0)
        spectrumImaginary.fill(0.0)
        spectrumRaw.fill(0.0)
        smoothedSpectrum.fill(0.0)
        spectrumWriteIndex = 0
        spectrumSampleCount = 0
        spectrumResamplePhase = 0
        spectrumResampleSum = 0.0
        spectrumResampleCount = 0
        spectrumPeak = SPECTRUM_INITIAL_PEAK

        spectrumSampleRate = min(configuredSampleRate, SPECTRUM_TARGET_SAMPLE_RATE)
            .coerceAtLeast(0)
        if (spectrumSampleRate <= 0) {
            spectrumBandStartBins.fill(0)
            spectrumBandEndBins.fill(0)
            return
        }

        val binWidth = spectrumSampleRate.toDouble() / SPECTRUM_FFT_SIZE
        val highestFrequency = min(
            SPECTRUM_MAX_FREQUENCY_HZ,
            spectrumSampleRate * SPECTRUM_NYQUIST_MARGIN,
        )
        val frequencyRatio = highestFrequency / SPECTRUM_MIN_FREQUENCY_HZ
        for (band in 0 until SPECTRUM_BAND_COUNT) {
            val lowFrequency = SPECTRUM_MIN_FREQUENCY_HZ *
                frequencyRatio.pow(band.toDouble() / SPECTRUM_BAND_COUNT)
            val highFrequency = SPECTRUM_MIN_FREQUENCY_HZ *
                frequencyRatio.pow((band + 1.0) / SPECTRUM_BAND_COUNT)
            val start = ceil(lowFrequency / binWidth).toInt()
                .coerceIn(1, SPECTRUM_FFT_SIZE / 2 - 1)
            val end = ceil(highFrequency / binWidth).toInt()
                .coerceIn(start + 1, SPECTRUM_FFT_SIZE / 2)
            spectrumBandStartBins[band] = start
            spectrumBandEndBins[band] = end
        }
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
        private const val ANALYSIS_UPDATES_PER_SECOND = 24
        private const val LOW_CROSSOVER_HZ = 240.0
        private const val MID_CROSSOVER_HZ = 2600.0

        private const val SPECTRUM_BAND_COUNT = 24
        private const val SPECTRUM_FFT_SIZE = 2048
        private const val SPECTRUM_TARGET_SAMPLE_RATE = 32000
        private const val SPECTRUM_MIN_FREQUENCY_HZ = 40.0
        private const val SPECTRUM_MAX_FREQUENCY_HZ = 16000.0
        private const val SPECTRUM_NYQUIST_MARGIN = 0.48
        private const val SPECTRUM_INITIAL_PEAK = 0.04
        private const val SPECTRUM_MINIMUM_PEAK = 0.004
        private const val SPECTRUM_TARGET_PEAK = 0.82
        private const val SPECTRUM_MAX_GAIN = 36.0
        private const val SPECTRUM_PEAK_DECAY = 0.975
        private const val SPECTRUM_NOISE_FLOOR = 0.0006
        private const val SPECTRUM_COMPRESSION = 0.72
        private const val SPECTRUM_ATTACK = 0.58
        private const val SPECTRUM_RELEASE = 0.2

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
