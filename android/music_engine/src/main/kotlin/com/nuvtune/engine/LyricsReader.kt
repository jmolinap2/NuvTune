package com.nuvtune.engine

import android.content.Context
import java.io.File

/**
 * Letras incrustadas y archivos `.lrc` (requerimiento seccion 8).
 *
 * Un `.lrc` junto a la cancion no es un archivo de medios, asi que el
 * almacenamiento con alcance no permite leerlo por ruta ni aparece en
 * MediaStore. Se busca en dos sitios, en este orden:
 *
 *  1. Junto al archivo de audio, si el usuario concedio esa carpeta por SAF.
 *  2. En el almacenamiento privado de la aplicacion, donde quedan las letras
 *     que el usuario escribio o asocio a mano.
 *
 * La obtencion automatica desde internet corresponde a Fase 3.
 */
internal class LyricsReader(
    private val context: Context,
    private val library: MediaStoreRepository,
    private val safManager: SafManager,
    private val metadataEditor: MetadataEditor,
) {

    private val privateDirectory: File
        get() = File(context.filesDir, LYRICS_DIRECTORY).apply { mkdirs() }

    fun read(songId: Long): LyricsPayload {
        val song = library.songById(songId)
            ?: return LyricsPayload(embedded = null, lrcContent = null, lrcSource = null)

        val embedded = metadataEditor.readEmbeddedLyrics(songId)?.takeIf { it.isNotBlank() }

        val sidecar = readSidecar(song)
        if (sidecar != null) {
            return LyricsPayload(
                embedded = embedded,
                lrcContent = sidecar.first,
                lrcSource = sidecar.second,
            )
        }

        val privateFile = privateFileFor(songId)
        if (privateFile.exists()) {
            return LyricsPayload(
                embedded = embedded,
                lrcContent = privateFile.readText(),
                lrcSource = privateFile.absolutePath,
            )
        }

        return LyricsPayload(embedded = embedded, lrcContent = null, lrcSource = null)
    }

    private fun readSidecar(song: Song): Pair<String, String>? {
        val audioFile = File(song.filePath)
        val candidate = File(audioFile.parentFile, "${audioFile.nameWithoutExtension}.lrc")
        val documentUri = safManager.documentUriForPath(candidate.absolutePath) ?: return null
        if (!safManager.documentExists(documentUri)) return null
        val content = runCatching { safManager.readText(documentUri) }.getOrNull() ?: return null
        return content to candidate.absolutePath
    }

    /**
     * Guarda la letra sincronizada. Si la carpeta de la cancion esta concedida
     * se escribe el `.lrc` al lado del audio, que es lo que esperan los demas
     * reproductores; si no, queda en el almacenamiento privado.
     *
     * Devuelve la ruta o el URI donde quedo guardada.
     */
    fun saveLrc(songId: Long, content: String): String {
        val song = library.songById(songId)
            ?: throw IllegalArgumentException("La cancion $songId no esta en la biblioteca")

        val audioFile = File(song.filePath)
        val displayName = "${audioFile.nameWithoutExtension}.lrc"
        val sidecarUri = safManager.createSiblingDocument(
            siblingFilePath = song.filePath,
            displayName = displayName,
            mimeType = LRC_MIME_TYPE,
        )

        if (sidecarUri != null) {
            safManager.writeText(sidecarUri, content)
            return File(audioFile.parentFile, displayName).absolutePath
        }

        val privateFile = privateFileFor(songId)
        privateFile.writeText(content)
        return privateFile.absolutePath
    }

    /** Asocia un `.lrc` elegido con el selector del sistema a una cancion. */
    fun associateDocument(songId: Long, content: String): String {
        val privateFile = privateFileFor(songId)
        privateFile.writeText(content)
        return privateFile.absolutePath
    }

    private fun privateFileFor(songId: Long) = File(privateDirectory, "$songId.lrc")

    private companion object {
        const val LYRICS_DIRECTORY = "lyrics"

        // Los proveedores de documentos no reconocen un MIME propio para LRC.
        const val LRC_MIME_TYPE = "text/plain"
    }
}
