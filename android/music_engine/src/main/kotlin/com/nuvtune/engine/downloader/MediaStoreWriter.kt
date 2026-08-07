package com.nuvtune.engine.downloader

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.IOException

/**
 * Unica via para que una descarga terminada pase de la carpeta cache privada
 * de la app a la biblioteca de musica del usuario. A diferencia de la
 * version original en C:\Repos\NuvClip (que escribe en
 * `MediaStore.Downloads`, generico), esto escribe en `MediaStore.Audio` con
 * `IS_MUSIC = 1` y los metadatos reales de la cancion: asi el archivo queda
 * indexado exactamente igual que cualquier otra cancion de la biblioteca
 * (mismo `IS_MUSIC != 0` que filtra `MediaStoreRepository.querySongs`), con
 * un id de MediaStore normal, sin necesitar ninguna logica de fusion aparte
 * para que aparezca en playlists. Con minSdk 29 esto no requiere ningun
 * permiso de almacenamiento adicional.
 */
object MediaStoreWriter {
    private const val RELATIVE_FOLDER = "NuvTune descargas"

    fun saveAudio(
        context: Context,
        source: File,
        displayName: String,
        title: String?,
        artist: String?,
        album: String?,
    ): Uri {
        val resolver = context.contentResolver
        val mimeType = mimeTypeFor(source.extension)

        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MUSIC}/$RELATIVE_FOLDER")
            put(MediaStore.Audio.Media.IS_MUSIC, 1)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
            if (!title.isNullOrBlank()) put(MediaStore.Audio.Media.TITLE, title)
            if (!artist.isNullOrBlank()) put(MediaStore.Audio.Media.ARTIST, artist)
            if (!album.isNullOrBlank()) put(MediaStore.Audio.Media.ALBUM, album)
        }

        val itemUri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("MediaStore no acepto el registro del archivo")

        try {
            resolver.openOutputStream(itemUri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IOException("No se pudo abrir el destino en MediaStore")
        } catch (error: Exception) {
            // Un registro a medio escribir no debe quedar visible en la
            // biblioteca del usuario ni contar como descarga exitosa.
            resolver.delete(itemUri, null, null)
            throw error
        }

        values.clear()
        values.put(MediaStore.Audio.Media.IS_PENDING, 0)
        resolver.update(itemUri, values, null, null)

        return itemUri
    }

    fun sizeOf(context: Context, uri: Uri): Long =
        context.contentResolver.query(uri, arrayOf(MediaStore.Audio.Media.SIZE), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getLong(0) else 0L
        } ?: 0L

    private fun mimeTypeFor(extension: String): String = when (extension.lowercase()) {
        "mp3" -> "audio/mpeg"
        "m4a" -> "audio/mp4"
        "aac" -> "audio/aac"
        "opus" -> "audio/opus"
        "wav" -> "audio/wav"
        else -> "audio/mpeg"
    }
}
