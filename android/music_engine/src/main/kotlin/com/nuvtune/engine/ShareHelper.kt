package com.nuvtune.engine

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.provider.MediaStore

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
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(library.contentUriFor(song.id), song.mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        launch(Intent.createChooser(intent, "Abrir ubicacion"))
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

    private fun launch(intent: Intent) {
        // Se lanza desde el contexto de aplicacion porque el motor no siempre
        // tiene una actividad viva.
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            PlaybackStateHolder.publishError(
                "share_unavailable",
                "No hay ninguna aplicacion que pueda atender esta accion",
            )
        }
    }
}
