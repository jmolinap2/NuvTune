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

    /**
     * Abre la ubicacion del archivo en el explorador del sistema, posicionado
     * en su carpeta.
     *
     * Antes se intentaba primero un `ACTION_VIEW` sobre el URI de documento de
     * la carpeta y solo se recurria al selector si aquel fallaba. Medido en el
     * dispositivo, ese primer intento es lo que rompia la funcion: el intent
     * SI resuelve y DocumentsUI SI arranca -por eso [launch] devolvia true y el
     * segundo camino no llegaba a ejecutarse nunca-, pero la actividad se
     * destruye sola en el mismo instante porque nadie concedio permiso sobre
     * ese URI, de modo que el usuario solo veia un parpadeo:
     *
     *     SmartPower: com.google.android.documentsui background->idle R(become invisible)
     *     SurfaceFlinger: onHandleDestroyed: ... FilesActivity
     *
     * Queda un unico camino, el que se comprobo que se sostiene abierto. El
     * URI inicial tiene que ser de arbol ([DocumentsContract.buildTreeDocumentUri]):
     * `EXTRA_INITIAL_URI` ignora un URI de documento suelto y el selector abre
     * en la raiz en vez de en la carpeta de la cancion.
     */
    fun revealFile(songId: Long) {
        val song = library.songById(songId) ?: return

        val browseFolder = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            treeUriForFolder(song.folderPath)?.let {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, it)
            }
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

    private fun treeUriForFolder(folderPath: String): Uri? {
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
        return DocumentsContract.buildTreeDocumentUri(
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
