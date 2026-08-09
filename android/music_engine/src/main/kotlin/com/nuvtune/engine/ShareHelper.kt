package com.nuvtune.engine

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import java.io.File

/**
 * Compartir canciones y listados, y abrir la ubicacion de un archivo
 * (requerimiento seccion 4.1).
 *
 * Se resuelve de forma nativa porque compartir un archivo de MediaStore exige
 * pasar su URI de contenido con permiso de lectura concedido al receptor; una
 * ruta del sistema de archivos no serviria bajo almacenamiento con alcance.
 */
internal class ShareHelper(
    private val context: Context,
    private val library: MediaStoreRepository,
) {

    fun shareSongs(songIds: List<Long>) {
        val songs = songIds.mapNotNull { library.songById(it) }
        if (songs.isEmpty()) return

        val uris = songs.map { library.contentUriFor(it.id) }
        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                type = songs.first().mimeType
                putExtra(Intent.EXTRA_STREAM, uris.first())
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "audio/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            }
        }

        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        launch(Intent.createChooser(intent, "Compartir"))
    }

    fun shareText(subject: String, text: String) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, text)
        }
        launch(Intent.createChooser(intent, subject))
    }

    /** Abre la ubicacion del archivo en un explorador del sistema. */
    fun revealFile(songId: Long) {
        val song = library.songById(songId) ?: return

        // ACTION_VIEW sobre el URI de audio abre un reproductor, no la carpeta.
        // Los exploradores de Android entienden en cambio el URI de documento
        // del directorio. Si el fabricante no ofrece esa accion, abrimos el
        // selector del sistema ya posicionado en la carpeta como alternativa.
        val folderUri = documentUriForFolder(song.folderPath)
        val viewFolder = folderUri?.let { uri ->
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, DocumentsContract.Document.MIME_TYPE_DIR)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        if (viewFolder != null && launch(viewFolder)) return

        val browseFolder = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            folderUri?.let { putExtra(DocumentsContract.EXTRA_INITIAL_URI, it) }
        }
        if (!launch(browseFolder)) {
            PlaybackStateHolder.publishError(
                "file_browser_unavailable",
                "No hay un explorador de archivos disponible",
            )
        }
    }

    /**
     * Intenta borrar sin dialogo cuando MediaStore reconoce a NuvTune como
     * propietario (por ejemplo, una descarga creada por la propia app).
     * `null` indica que Android exige consentimiento del usuario.
     */
    fun tryDeleteDirectly(songId: Long): Boolean? {
        val uri = library.songById(songId)?.let { library.contentUriFor(it.id) }
            ?: return false
        return try {
            context.contentResolver.delete(uri, null, null) > 0
        } catch (_: SecurityException) {
            null
        }
    }

    /**
     * Elimina el archivo del dispositivo. El requerimiento seccion 16 exige
     * diferenciar esto de "quitar de biblioteca", que no borra nada.
     */
    fun deleteRequest(songIds: List<Long>): android.content.IntentSender? {
        val uris = songIds.mapNotNull { library.songById(it)?.let { song -> library.contentUriFor(song.id) } }
        if (uris.isEmpty()) return null
        return MediaStore.createDeleteRequest(context.contentResolver, uris).intentSender
    }

    private fun documentUriForFolder(folderPath: String): Uri? {
        val normalized = File(folderPath).absolutePath.replace('\\', '/')
        val externalPrefix = "/storage/emulated/0/"
        val documentId = when {
            normalized.startsWith(externalPrefix, ignoreCase = true) ->
                "primary:${normalized.removePrefix(externalPrefix)}"
            normalized.startsWith("/storage/", ignoreCase = true) -> {
                val rest = normalized.removePrefix("/storage/")
                val volume = rest.substringBefore('/')
                val relative = rest.substringAfter('/', missingDelimiterValue = "")
                if (volume.isBlank()) return null
                "$volume:$relative"
            }
            else -> return null
        }.trimEnd('/')
        return DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            documentId,
        )
    }

    private fun launch(intent: Intent): Boolean {
        // Se lanza desde el contexto de aplicacion porque el motor no siempre
        // tiene una actividad viva.
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (error: ActivityNotFoundException) {
            Log.w(TAG, "No hay actividad para ${intent.action} (${intent.data})", error)
            false
        }
    }

    private companion object {
        const val TAG = "NuvTuneStorage"
    }
}
