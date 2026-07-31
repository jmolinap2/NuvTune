package com.nuvtune.engine

import android.media.MediaCodecList

/**
 * Resuelve si el dispositivo puede decodificar un formato de audio
 * (requerimiento seccion 6: "La interfaz debe indicar cuando un formato no sea
 * compatible con el dispositivo").
 *
 * La lista de decodificadores se consulta una sola vez y se guarda en memoria.
 */
internal object FormatSupport {

    /**
     * Contenedores cuyo audio es PCM sin comprimir. Media3 los extrae y los
     * entrega directamente al AudioTrack, sin depender de un decodificador
     * registrado en MediaCodecList.
     */
    private val pcmContainers = setOf(
        "audio/wav",
        "audio/x-wav",
        "audio/wave",
        "audio/vnd.wave",
        "audio/aiff",
        "audio/x-aiff",
    )

    /**
     * MIME del contenedor tal como lo reporta MediaStore, mapeado al MIME del
     * decodificador que registra MediaCodecList.
     */
    private val decoderMimeByContainer = mapOf(
        "audio/mpeg" to "audio/mpeg",
        "audio/mp3" to "audio/mpeg",
        "audio/x-mpeg" to "audio/mpeg",
        "audio/aac" to "audio/mp4a-latm",
        "audio/aacp" to "audio/mp4a-latm",
        "audio/mp4" to "audio/mp4a-latm",
        "audio/m4a" to "audio/mp4a-latm",
        "audio/x-m4a" to "audio/mp4a-latm",
        "audio/mp4a-latm" to "audio/mp4a-latm",
        "audio/flac" to "audio/flac",
        "audio/x-flac" to "audio/flac",
        "audio/ogg" to "audio/vorbis",
        "audio/vorbis" to "audio/vorbis",
        "audio/x-vorbis+ogg" to "audio/vorbis",
        "audio/opus" to "audio/opus",
        "audio/x-opus+ogg" to "audio/opus",
        "audio/amr" to "audio/3gpp",
        "audio/3gpp" to "audio/3gpp",
        "audio/amr-wb" to "audio/amr-wb",
        "audio/x-ms-wma" to "audio/x-ms-wma",
        "audio/alac" to "audio/alac",
        "audio/x-alac" to "audio/alac",
    )

    private val availableDecoderMimes: Set<String> by lazy {
        val result = HashSet<String>()
        val codecs = MediaCodecList(MediaCodecList.REGULAR_CODECS)
        for (info in codecs.codecInfos) {
            if (info.isEncoder) continue
            for (type in info.supportedTypes) {
                result.add(type.lowercase())
            }
        }
        result
    }

    fun isSupported(mimeType: String): Boolean {
        val mime = mimeType.lowercase()
        if (mime in pcmContainers) return true
        val decoderMime = decoderMimeByContainer[mime] ?: return false
        return decoderMime in availableDecoderMimes
    }

    /** Motivo legible para la interfaz cuando el formato no es reproducible. */
    fun unsupportedReason(mimeType: String): String? {
        if (isSupported(mimeType)) return null
        val mime = mimeType.lowercase()
        return if (decoderMimeByContainer.containsKey(mime)) {
            "Este dispositivo no incluye un decodificador para $mimeType"
        } else {
            "Formato no reconocido por el motor: $mimeType"
        }
    }

    /** Nombre corto del codec para la vista tecnica (requerimiento 4.2). */
    fun codecName(mimeType: String): String = when (mimeType.lowercase()) {
        "audio/mpeg", "audio/mp3", "audio/x-mpeg" -> "MP3"
        "audio/aac", "audio/aacp", "audio/mp4a-latm" -> "AAC"
        "audio/mp4", "audio/m4a", "audio/x-m4a" -> "AAC (MP4)"
        "audio/flac", "audio/x-flac" -> "FLAC"
        "audio/ogg", "audio/vorbis", "audio/x-vorbis+ogg" -> "Vorbis"
        "audio/opus", "audio/x-opus+ogg" -> "Opus"
        "audio/wav", "audio/x-wav", "audio/wave", "audio/vnd.wave" -> "PCM (WAV)"
        "audio/aiff", "audio/x-aiff" -> "PCM (AIFF)"
        "audio/amr", "audio/3gpp" -> "AMR-NB"
        "audio/amr-wb" -> "AMR-WB"
        "audio/x-ms-wma" -> "WMA"
        "audio/alac", "audio/x-alac" -> "ALAC"
        else -> mimeType
    }

    /** Nombre del contenedor para la vista tecnica. */
    fun containerName(mimeType: String): String = when (mimeType.lowercase()) {
        "audio/mpeg", "audio/mp3", "audio/x-mpeg" -> "MPEG"
        "audio/mp4", "audio/m4a", "audio/x-m4a", "audio/alac", "audio/x-alac" -> "MP4"
        "audio/flac", "audio/x-flac" -> "FLAC"
        "audio/ogg", "audio/vorbis", "audio/x-vorbis+ogg", "audio/opus", "audio/x-opus+ogg" -> "Ogg"
        "audio/wav", "audio/x-wav", "audio/wave", "audio/vnd.wave" -> "RIFF"
        "audio/aiff", "audio/x-aiff" -> "AIFF"
        "audio/x-ms-wma" -> "ASF"
        "audio/amr", "audio/3gpp", "audio/amr-wb" -> "3GPP"
        else -> mimeType.substringAfter('/').uppercase()
    }

    /**
     * Formatos que admiten reproduccion sin espacios entre canciones
     * (requerimiento 5.5). El resto lleva relleno del codificador que produce
     * un silencio audible en el limite.
     */
    fun supportsGapless(mimeType: String): Boolean = when (mimeType.lowercase()) {
        "audio/flac", "audio/x-flac",
        "audio/wav", "audio/x-wav", "audio/wave", "audio/vnd.wave",
        "audio/aiff", "audio/x-aiff",
        "audio/opus", "audio/x-opus+ogg",
        "audio/ogg", "audio/vorbis", "audio/x-vorbis+ogg",
        "audio/alac", "audio/x-alac" -> true
        // MP3 y AAC solo son gapless cuando el archivo trae la informacion de
        // relleno (Xing/LAME o iTunSMPB); Media3 la lee cuando esta presente.
        else -> false
    }
}
