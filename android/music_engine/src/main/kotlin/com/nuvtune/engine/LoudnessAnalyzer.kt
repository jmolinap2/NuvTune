package com.nuvtune.engine

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.sqrt

/**
 * Analisis de sonoridad por pista, al estilo de ReplayGain (requerimiento 5.2).
 *
 * Decodifica el archivo completo y devuelve la ganancia que lo acerca al nivel
 * objetivo, junto con el pico real. El pico importa tanto como la ganancia: si
 * se subiera una pista sin mirarlo, el limitador tendria que trabajar en toda
 * la cancion y se oiria.
 *
 * Es una operacion cara, asi que la capa de Flutter la lanza en segundo plano y
 * la suspende con bateria baja (requerimiento 17).
 */
internal class LoudnessAnalyzer(private val context: Context) {

    fun analyze(songId: Long, uri: Uri): LoudnessAnalysis {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null

        try {
            extractor.setDataSource(context, uri, null)
            val trackIndex = selectAudioTrack(extractor)
                ?: return LoudnessAnalysis(songId, 0.0, 0.0)

            extractor.selectTrack(trackIndex)
            val format = extractor.getTrackFormat(trackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME)
                ?: return LoudnessAnalysis(songId, 0.0, 0.0)

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()

            val accumulator = Accumulator()
            decodeInto(extractor, codec, accumulator)

            return accumulator.toAnalysis(songId)
        } finally {
            runCatching { codec?.stop() }
            runCatching { codec?.release() }
            runCatching { extractor.release() }
        }
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int? {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) return index
        }
        return null
    }

    private fun decodeInto(
        extractor: MediaExtractor,
        codec: MediaCodec,
        accumulator: Accumulator,
    ) {
        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false

        while (!outputDone) {
            if (!inputDone) {
                val inputIndex = codec.dequeueInputBuffer(TIMEOUT_US)
                if (inputIndex >= 0) {
                    val buffer = codec.getInputBuffer(inputIndex)!!
                    val size = extractor.readSampleData(buffer, 0)
                    if (size < 0) {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            0,
                            0,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                        inputDone = true
                    } else {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            size,
                            extractor.sampleTime,
                            0,
                        )
                        extractor.advance()
                    }
                }
            }

            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            if (outputIndex >= 0) {
                val buffer = codec.getOutputBuffer(outputIndex)
                if (buffer != null && bufferInfo.size > 0) {
                    buffer.position(bufferInfo.offset)
                    buffer.limit(bufferInfo.offset + bufferInfo.size)
                    accumulator.add(buffer.order(ByteOrder.nativeOrder()).asShortBuffer())
                }
                codec.releaseOutputBuffer(outputIndex, false)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    outputDone = true
                }
            }
        }
    }

    /** Suma de cuadrados y pico, calculados en una sola pasada. */
    private class Accumulator {
        private var squaredSum = 0.0
        private var sampleCount = 0L
        private var peak = 0.0

        fun add(samples: java.nio.ShortBuffer) {
            while (samples.hasRemaining()) {
                val value = samples.get() / PCM16_SCALE
                squaredSum += value * value
                sampleCount++
                val magnitude = abs(value)
                if (magnitude > peak) peak = magnitude
            }
        }

        fun toAnalysis(songId: Long): LoudnessAnalysis {
            if (sampleCount == 0L) return LoudnessAnalysis(songId, 0.0, 0.0)

            val rms = sqrt(squaredSum / sampleCount)
            if (rms <= 0.0) return LoudnessAnalysis(songId, 0.0, peak)

            val levelDb = 20.0 * log10(rms)
            val rawGain = TARGET_LEVEL_DB - levelDb

            // La ganancia no puede llevar el pico por encima del umbral del
            // limitador: si lo hiciera, se recortaria en lugar de sonar mas
            // alto. Se reduce hasta donde el pico lo permita.
            val headroomDb = if (peak > 0.0) {
                20.0 * log10(LIMITER_HEADROOM / peak)
            } else {
                MAX_GAIN_DB
            }

            val gain = rawGain
                .coerceAtMost(headroomDb)
                .coerceIn(MIN_GAIN_DB, MAX_GAIN_DB)

            return LoudnessAnalysis(songId, gain, peak)
        }
    }

    companion object {
        private const val TIMEOUT_US = 10_000L
        private const val PCM16_SCALE = 32768.0

        /** Mismo objetivo que usa la normalizacion en vivo. */
        private const val TARGET_LEVEL_DB = -14.0
        private const val LIMITER_HEADROOM = 0.97
        private const val MIN_GAIN_DB = -12.0
        private const val MAX_GAIN_DB = 12.0
    }
}
