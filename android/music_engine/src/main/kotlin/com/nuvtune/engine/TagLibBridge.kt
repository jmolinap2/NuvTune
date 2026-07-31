package com.nuvtune.engine

/**
 * Declaraciones JNI de libnuvtune_taglib (requerimiento seccion 13.1: TagLib
 * se ocupa de la lectura y escritura persistente de etiquetas).
 *
 * Todas las funciones esperan la ruta de un archivo que la aplicacion posee.
 * [MetadataEditor] es responsable de materializar la copia temporal antes de
 * llamar aqui; este objeto no conoce MediaStore ni el almacenamiento con
 * alcance.
 */
internal object TagLibBridge {

    init {
        System.loadLibrary("nuvtune_taglib")
    }

    /** Codigos devueltos por las funciones de escritura. */
    object ResultCode {
        const val OK = 0
        const val CANNOT_OPEN = -1
        const val SAVE_FAILED = -2
        const val UNSUPPORTED = -3
    }

    /** Claves normalizadas de TagLib::PropertyMap que usa la aplicacion. */
    object Key {
        const val TITLE = "TITLE"
        const val ARTIST = "ARTIST"
        const val ALBUM = "ALBUM"
        const val ALBUM_ARTIST = "ALBUMARTIST"
        const val GENRE = "GENRE"
        const val DATE = "DATE"
        const val TRACK_NUMBER = "TRACKNUMBER"
        const val DISC_NUMBER = "DISCNUMBER"
        const val COMPOSER = "COMPOSER"
        const val COMMENT = "COMMENT"
        const val LYRICS = "LYRICS"
    }

    /** Indices del arreglo devuelto por [nativeReadAudioProperties]. */
    object AudioProperty {
        const val DURATION_MS = 0
        const val BITRATE_KBPS = 1
        const val SAMPLE_RATE_HZ = 2
        const val CHANNELS = 3
        const val BITS_PER_SAMPLE = 4
    }

    /** Pares clave/valor planos, o null si el archivo no se pudo abrir. */
    external fun nativeReadProperties(path: String): Array<String>?

    /**
     * Escribe los pares clave/valor indicados. Un valor vacio borra la clave;
     * las claves ausentes del arreglo no se modifican.
     */
    external fun nativeWriteProperties(path: String, flatKeyValues: Array<String>): Int

    external fun nativeReadAudioProperties(path: String): LongArray?

    external fun nativeReadPicture(path: String): ByteArray?

    external fun nativeReadPictureMimeType(path: String): String?

    external fun nativeWritePicture(path: String, imageBytes: ByteArray, mimeType: String): Int

    external fun nativeRemovePicture(path: String): Int

    external fun nativeSupportsTagWriting(path: String): Boolean

    external fun nativeSupportsPictures(path: String): Boolean

    /**
     * Relee el archivo y confirma que sigue siendo decodificable
     * (requerimiento 7.1: verificar integridad antes de sustituir el original).
     */
    external fun nativeVerifyIntegrity(path: String, expectedDurationMs: Long): Boolean

    /** Convierte los pares planos de [nativeReadProperties] en un mapa. */
    fun readProperties(path: String): Map<String, String>? {
        val flat = nativeReadProperties(path) ?: return null
        val result = LinkedHashMap<String, String>(flat.size / 2)
        var index = 0
        while (index + 1 < flat.size) {
            result[flat[index]] = flat[index + 1]
            index += 2
        }
        return result
    }

    /** Aplana un mapa para [nativeWriteProperties]. */
    fun writeProperties(path: String, values: Map<String, String>): Int {
        val flat = ArrayList<String>(values.size * 2)
        for ((key, value) in values) {
            flat.add(key)
            flat.add(value)
        }
        return nativeWriteProperties(path, flat.toTypedArray())
    }
}
