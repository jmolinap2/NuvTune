package com.nuvtune.engine

import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import com.nuvtune.engine.downloader.MediaStoreWriter
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Arma y abre los archivos `.nuvtune-gift`.
 *
 * Un regalo lleva el audio dentro, no una lista de titulos: la version
 * anterior solo mandaba texto y el receptor tenia que salir a buscar cada
 * cancion en internet, con dos fallos garantizados: la musica que no esta
 * publicada no aparecia, y la que aparecia podia ser un cover o una version
 * en vivo. Con el audio incrustado el receptor obtiene exactamente lo que le
 * regalaron, y sin conexion.
 *
 * El formato es un zip corriente:
 *   gift.json          metadatos (dedicatoria + lista de canciones)
 *   audio/0001.mp3     una entrada por cancion, en el orden de la lista
 *
 * Se conserva la lectura del formato antiguo (JSON suelto, sin comprimir)
 * para que los regalos ya enviados sigan abriendo.
 */
internal class GiftPackager(
    private val context: Context,
    private val library: MediaStoreRepository,
) {

    /** Nombre de la carpeta visible donde se copian las canciones recibidas. */
    private val relativeFolder = "NuvTune regalos"

    /**
     * Escribe el paquete en la cache de la aplicacion y devuelve su ruta.
     * El llamador lo comparte y el sistema se encarga de limpiar la cache.
     */
    fun create(
        suggestedFileName: String,
        metadataJson: String,
        songIds: List<Long>,
    ): String {
        val directory = File(context.cacheDir, "gifts").apply {
            mkdirs()
            // Un regalo anterior ya compartido no tiene por que seguir
            // ocupando espacio: solo interesa el que se esta armando.
            listFiles()?.forEach { it.delete() }
        }
        val target = File(directory, sanitizeFileName(suggestedFileName))

        ZipOutputStream(target.outputStream().buffered()).use { zip ->
            zip.putNextEntry(ZipEntry(METADATA_ENTRY))
            zip.write(metadataJson.toByteArray(Charsets.UTF_8))
            zip.closeEntry()

            songIds.forEachIndexed { index, songId ->
                val song = library.songById(songId) ?: return@forEachIndexed
                val entryName = audioEntryName(index, song.filePath)
                zip.putNextEntry(ZipEntry(entryName))
                // El audio ya esta comprimido (mp3/aac/flac): volver a
                // comprimirlo solo gastaria CPU sin ganar espacio, pero el
                // metodo DEFLATE por defecto mantiene el zip legible por
                // cualquier herramienta, que importa mas aqui.
                context.contentResolver
                    .openInputStream(library.contentUriFor(song.id))
                    ?.use { input -> input.copyTo(zip) }
                zip.closeEntry()
            }
        }

        return target.absolutePath
    }

    /** Metadatos y cuantas canciones traen audio, sin importar nada todavia. */
    fun read(uri: String): GiftPackage {
        val parsed = Uri.parse(uri)
        val size = sizeOf(parsed)

        if (!looksLikeZip(parsed)) {
            // Regalo del formato antiguo: el archivo entero es el JSON.
            val text = context.contentResolver.openInputStream(parsed)
                ?.use { it.readBytes().toString(Charsets.UTF_8) }
                ?: throw IOException("No se pudo abrir el regalo")
            return GiftPackage(
                metadataJson = text,
                embeddedAudioCount = 0,
                sizeBytes = size,
            )
        }

        var metadata: String? = null
        var audioCount = 0L
        forEachEntry(parsed) { entry, stream ->
            when {
                entry.name == METADATA_ENTRY ->
                    metadata = stream.readBytes().toString(Charsets.UTF_8)
                entry.name.startsWith("$AUDIO_PREFIX/") -> audioCount++
            }
        }

        return GiftPackage(
            metadataJson = metadata ?: throw IOException("El regalo no trae dedicatoria"),
            embeddedAudioCount = audioCount,
            sizeBytes = size,
        )
    }

    /**
     * Copia el audio del regalo a la biblioteca de musica del receptor.
     *
     * Los titulos y artistas salen de `gift.json`, no del nombre del archivo:
     * asi la cancion queda en la biblioteca con los mismos datos con los que
     * viajaba, y la lista del regalo la encuentra despues por (titulo,
     * artista).
     */
    fun importAudio(uri: String): Long {
        val parsed = Uri.parse(uri)
        if (!looksLikeZip(parsed)) return 0L

        val metadata = read(uri).metadataJson
        val songs = JSONObject(metadata).optJSONArray("songs")

        var imported = 0L
        forEachEntry(parsed) { entry, stream ->
            if (!entry.name.startsWith("$AUDIO_PREFIX/")) return@forEachEntry

            val index = indexOfEntry(entry.name)
            val song = if (index != null) songs?.optJSONObject(index) else null

            // El stream del zip no se puede rebobinar ni pasar directo a
            // MediaStore mas de una vez, asi que se vuelca a un temporal.
            val temporary = File.createTempFile("gift", null, context.cacheDir)
            try {
                temporary.outputStream().buffered().use { output ->
                    stream.copyTo(output)
                }
                MediaStoreWriter.saveAudio(
                    context = context,
                    source = temporary,
                    displayName = entry.name.substringAfterLast('/'),
                    title = song?.optString("title")?.takeIf { it.isNotBlank() },
                    artist = song?.optString("artist")?.takeIf { it.isNotBlank() },
                    album = song?.optString("album")?.takeIf { it.isNotBlank() },
                    relativeFolder = relativeFolder,
                )
                imported++
            } finally {
                temporary.delete()
            }
        }
        return imported
    }

    private fun forEachEntry(uri: Uri, block: (ZipEntry, ZipInputStream) -> Unit) {
        val input = context.contentResolver.openInputStream(uri)
            ?: throw IOException("No se pudo abrir el regalo")
        ZipInputStream(input.buffered()).use { zip ->
            while (true) {
                val entry = zip.nextEntry ?: break
                if (!entry.isDirectory) block(entry, zip)
                zip.closeEntry()
            }
        }
    }

    /**
     * Un zip empieza siempre por "PK". Se mira la firma en vez de
     * confiar en la extension porque el archivo llega de otra aplicacion.
     */
    private fun looksLikeZip(uri: Uri): Boolean =
        context.contentResolver.openInputStream(uri)?.use { stream ->
            val signature = ByteArray(4)
            stream.read(signature) == 4 &&
                signature[0] == 'P'.code.toByte() &&
                signature[1] == 'K'.code.toByte() &&
                signature[2] == 3.toByte() &&
                signature[3] == 4.toByte()
        } ?: false

    private fun sizeOf(uri: Uri): Long =
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val column = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
            if (column >= 0 && cursor.moveToFirst()) cursor.getLong(column) else 0L
        } ?: 0L

    private fun audioEntryName(index: Int, filePath: String): String {
        val extension = filePath.substringAfterLast('.', "mp3")
        return "$AUDIO_PREFIX/${"%04d".format(index)}.$extension"
    }

    /** `audio/0003.mp3` -> 3, la posicion en la lista de `gift.json`. */
    private fun indexOfEntry(entryName: String): Int? = entryName
        .substringAfterLast('/')
        .substringBeforeLast('.')
        .toIntOrNull()

    private fun sanitizeFileName(name: String): String {
        val safe = name.replace(Regex("[^\\w\\s.-]"), "").trim()
        return if (safe.isEmpty()) "regalo.nuvtune-gift" else safe
    }

    private companion object {
        const val METADATA_ENTRY = "gift.json"
        const val AUDIO_PREFIX = "audio"
    }
}
