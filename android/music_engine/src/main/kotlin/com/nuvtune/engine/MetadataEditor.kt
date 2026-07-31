package com.nuvtune.engine

import android.content.ContentResolver
import android.content.Context
import android.content.IntentSender
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream

/** Resultado interno de una escritura sobre un archivo de audio. */
internal sealed interface EditResult {

    data class Done(val outcome: WriteOutcome, val message: String? = null) : EditResult

    /**
     * El sistema exige que el usuario confirme la modificacion del archivo. El
     * plugin debe lanzar [intentSender] desde la actividad y repetir la
     * operacion si el usuario acepta.
     */
    data class NeedsConsent(val intentSender: IntentSender) : EditResult
}

/**
 * Escritura persistente de etiquetas mediante TagLib (requerimiento seccion
 * 7.1).
 *
 * Sobre el caracter atomico de la sustitucion: en Android 11 no existe forma de
 * renombrar un archivo de medios ajeno dentro de su propia carpeta, que es lo
 * que daria atomicidad real del sistema de archivos. Lo que si se garantiza, y
 * es lo que exige la seccion 16, es que en ningun momento se sobrescribe el
 * original sin tener una copia recuperable: si la escritura final falla a medio
 * camino, el original se restaura desde el respaldo antes de devolver el error.
 */
internal class MetadataEditor(
    private val context: Context,
    private val library: MediaStoreRepository,
) {

    private val resolver: ContentResolver get() = context.contentResolver

    /** El formato admite escritura de etiquetas. */
    fun supportsTagWriting(songId: Long): Boolean {
        val song = library.songById(songId) ?: return false
        return TagLibBridge.nativeSupportsTagWriting(song.filePath)
    }

    fun supportsPictures(songId: Long): Boolean {
        val song = library.songById(songId) ?: return false
        return TagLibBridge.nativeSupportsPictures(song.filePath)
    }

    fun readProperties(songId: Long): Map<String, String>? {
        val song = library.songById(songId) ?: return null
        return TagLibBridge.readProperties(song.filePath)
    }

    fun readEmbeddedCover(songId: Long): ByteArray? {
        val song = library.songById(songId) ?: return null
        return TagLibBridge.nativeReadPicture(song.filePath)
    }

    fun readEmbeddedLyrics(songId: Long): String? {
        val song = library.songById(songId) ?: return null
        return TagLibBridge.readProperties(song.filePath)?.get(TagLibBridge.Key.LYRICS)
    }

    suspend fun writeTags(edit: MetadataEdit): EditResult = withRecoverableWrite(edit.songId) { path ->
        val values = LinkedHashMap<String, String>()
        edit.title?.let { values[TagLibBridge.Key.TITLE] = it }
        edit.artist?.let { values[TagLibBridge.Key.ARTIST] = it }
        edit.albumArtist?.let { values[TagLibBridge.Key.ALBUM_ARTIST] = it }
        edit.album?.let { values[TagLibBridge.Key.ALBUM] = it }
        edit.genre?.let { values[TagLibBridge.Key.GENRE] = it }
        edit.year?.let { values[TagLibBridge.Key.DATE] = it }
        edit.trackNumber?.let { values[TagLibBridge.Key.TRACK_NUMBER] = it }
        edit.discNumber?.let { values[TagLibBridge.Key.DISC_NUMBER] = it }
        edit.composer?.let { values[TagLibBridge.Key.COMPOSER] = it }
        edit.comment?.let { values[TagLibBridge.Key.COMMENT] = it }
        edit.lyrics?.let { values[TagLibBridge.Key.LYRICS] = it }

        if (values.isEmpty()) {
            TagLibBridge.ResultCode.OK
        } else {
            TagLibBridge.writeProperties(path, values)
        }
    }

    suspend fun writeCover(
        songId: Long,
        imageBytes: ByteArray,
        mimeType: String,
    ): EditResult = withRecoverableWrite(songId) { path ->
        TagLibBridge.nativeWritePicture(path, imageBytes, mimeType)
    }

    suspend fun removeCover(songId: Long): EditResult = withRecoverableWrite(songId) { path ->
        TagLibBridge.nativeRemovePicture(path)
    }

    /**
     * Ejecuta [mutate] sobre una copia de trabajo y sustituye el original solo
     * si la verificacion de integridad pasa.
     *
     * Pasos, en el orden que fija la seccion 7.1:
     * validar permisos, crear archivo temporal, escribir cambios, verificar
     * integridad, sustituir el original y pedir nuevo escaneo de MediaStore.
     */
    private suspend fun withRecoverableWrite(
        songId: Long,
        mutate: (workPath: String) -> Int,
    ): EditResult = withContext(Dispatchers.IO) {
        val song = library.songById(songId)
            ?: return@withContext EditResult.Done(
                WriteOutcome.UNSUPPORTED_FORMAT,
                "La cancion ya no esta en la biblioteca",
            )

        if (!TagLibBridge.nativeSupportsTagWriting(song.filePath)) {
            return@withContext EditResult.Done(
                WriteOutcome.UNSUPPORTED_FORMAT,
                "El formato ${song.mimeType} no admite escritura de etiquetas",
            )
        }

        val uri = library.contentUriFor(songId)

        // 1. Validar permisos de escritura antes de tocar nada.
        val consent = requestConsentIfNeeded(songId)
        if (consent != null) {
            return@withContext EditResult.NeedsConsent(consent)
        }

        val workDirectory = File(context.cacheDir, WORK_DIRECTORY).apply { mkdirs() }
        val extension = File(song.filePath).extension
        val backup = File(workDirectory, "backup_$songId.$extension")
        val work = File(workDirectory, "work_$songId.$extension")

        try {
            // 2. Copia recuperable del original y copia de trabajo.
            resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(backup).use { output -> input.copyTo(output) }
            } ?: return@withContext EditResult.Done(
                WriteOutcome.INTEGRITY_CHECK_FAILED,
                "No se pudo leer el archivo original",
            )
            backup.copyTo(work, overwrite = true)

            // 3. Escribir los cambios sobre la copia de trabajo.
            val code = mutate(work.absolutePath)
            if (code != TagLibBridge.ResultCode.OK) {
                return@withContext EditResult.Done(outcomeFor(code), messageFor(code, song))
            }

            // 4. Verificar integridad: el archivo debe seguir siendo
            //    decodificable y conservar su duracion.
            if (!TagLibBridge.nativeVerifyIntegrity(work.absolutePath, song.durationMs)) {
                return@withContext EditResult.Done(
                    WriteOutcome.INTEGRITY_CHECK_FAILED,
                    "El archivo resultante no paso la verificacion y no se aplico ningun cambio",
                )
            }

            // 5. Sustituir el original. Si falla a mitad, se restaura desde el
            //    respaldo antes de devolver el error.
            val replaced = runCatching { streamInto(uri, work) }
            if (replaced.isFailure) {
                runCatching { streamInto(uri, backup) }
                return@withContext EditResult.Done(
                    WriteOutcome.INTEGRITY_CHECK_FAILED,
                    "La escritura fallo y el archivo original fue restaurado",
                )
            }

            // 6. Pedir a MediaStore que relea el archivo.
            library.requestRescan(song.filePath)
            library.invalidateAlbumCover(song.albumId)

            EditResult.Done(WriteOutcome.SUCCESS)
        } finally {
            backup.delete()
            work.delete()
        }
    }

    private fun streamInto(uri: android.net.Uri, source: File) {
        // "rwt" trunca el archivo destino antes de escribir.
        resolver.openFileDescriptor(uri, "rwt")?.use { descriptor ->
            FileOutputStream(descriptor.fileDescriptor).use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
                output.flush()
                output.fd.sync()
            }
        } ?: throw IllegalStateException("MediaStore no entrego un descriptor de escritura")
    }

    /**
     * Comprueba si la aplicacion puede escribir el archivo. Devuelve el
     * IntentSender del dialogo del sistema cuando hace falta que el usuario
     * confirme (requerimiento seccion 16: pedir confirmacion antes de modificar
     * archivos).
     */
    private fun requestConsentIfNeeded(songId: Long): IntentSender? {
        val uri = library.contentUriFor(songId)
        return try {
            resolver.openFileDescriptor(uri, "rw")?.close()
            null
        } catch (_: SecurityException) {
            MediaStore.createWriteRequest(resolver, listOf(uri)).intentSender
        }
    }

    private fun outcomeFor(code: Int): WriteOutcome = when (code) {
        TagLibBridge.ResultCode.UNSUPPORTED -> WriteOutcome.UNSUPPORTED_FORMAT
        else -> WriteOutcome.INTEGRITY_CHECK_FAILED
    }

    private fun messageFor(code: Int, song: Song): String = when (code) {
        TagLibBridge.ResultCode.CANNOT_OPEN ->
            "TagLib no pudo abrir la copia de trabajo de ${song.title}"
        TagLibBridge.ResultCode.SAVE_FAILED ->
            "TagLib no pudo guardar los cambios en ${song.title}"
        TagLibBridge.ResultCode.UNSUPPORTED ->
            "El formato ${song.mimeType} no admite este campo"
        else -> "Error desconocido de TagLib (codigo $code)"
    }

    private companion object {
        const val WORK_DIRECTORY = "metadata_work"
    }
}
