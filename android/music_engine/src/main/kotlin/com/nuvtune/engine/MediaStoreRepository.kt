package com.nuvtune.engine

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.database.ContentObserver
import android.graphics.Bitmap
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Descubre la musica del dispositivo mediante MediaStore (requerimiento
 * seccion 4.1) y mantiene la biblioteca en memoria para que tanto Flutter como
 * Android Auto lean la misma fuente.
 */
internal class MediaStoreRepository(private val context: Context) {

    private val resolver: ContentResolver get() = context.contentResolver

    @Volatile
    private var songs: List<Song> = emptyList()

    @Volatile
    private var songsById: Map<Long, Song> = emptyMap()

    @Volatile
    private var excludedFolderPaths: List<String> = emptyList()

    /** Presencia de portada resuelta por album, no por cancion. */
    private val albumCoverPresence = HashMap<Long, Boolean>()

    private var observer: ContentObserver? = null

    val currentSongs: List<Song> get() = songs

    fun songById(id: Long): Song? = songsById[id]

    fun contentUriFor(id: Long): Uri =
        ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)

    /**
     * Observa MediaStore para reconstruir la biblioteca cuando cambia
     * (requerimiento seccion 17: escaneo incremental, sin reconstruir todo por
     * cada cambio propio de la aplicacion).
     */
    fun startObserving(onChanged: () -> Unit) {
        if (observer != null) return
        val handler = Handler(Looper.getMainLooper())
        val contentObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                onChanged()
            }
        }
        resolver.registerContentObserver(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            true,
            contentObserver,
        )
        observer = contentObserver
    }

    fun stopObserving() {
        observer?.let { resolver.unregisterContentObserver(it) }
        observer = null
    }

    suspend fun scan(excludedFolders: List<String>, forceFullRescan: Boolean): List<Song> =
        withContext(Dispatchers.IO) {
            excludedFolderPaths = excludedFolders.map { normalizeFolder(it) }
            if (forceFullRescan) {
                albumCoverPresence.clear()
            }
            val scanned = querySongs()
            resolveCoverPresence(scanned)
            val withCovers = scanned.map { song ->
                song.copy(hasCover = albumCoverPresence[song.albumId] == true)
            }
            songs = withCovers
            songsById = withCovers.associateBy { it.id }
            withCovers
        }

    private fun querySongs(): List<Song> {
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ARTIST_ID,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
        )

        // IS_MUSIC excluye tonos de llamada, alarmas y notificaciones.
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val order = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"

        val result = ArrayList<Song>()
        resolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            order,
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val artistIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST_ID)
            val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val albumArtistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ARTIST)
            val genreColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)
            val composerColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)
            val yearColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)
            val trackColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
            val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val addedColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val modifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)

            while (cursor.moveToNext()) {
                val mimeType = cursor.getString(mimeColumn) ?: continue

                // Requerimiento seccion 3: se ignoran los archivos con MIME de
                // video aunque contengan una pista de audio.
                if (mimeType.startsWith("video/", ignoreCase = true)) continue

                val filePath = cursor.getString(dataColumn) ?: continue
                val folderPath = File(filePath).parent ?: continue
                if (isExcluded(folderPath)) continue

                val id = cursor.getLong(idColumn)
                val rawTrack = cursor.getInt(trackColumn)

                result.add(
                    Song(
                        id = id,
                        uri = contentUriFor(id).toString(),
                        filePath = filePath,
                        title = cursor.getString(titleColumn) ?: File(filePath).nameWithoutExtension,
                        artist = cursor.getString(artistColumn) ?: UNKNOWN_ARTIST,
                        artistId = cursor.getLong(artistIdColumn),
                        album = cursor.getString(albumColumn) ?: UNKNOWN_ALBUM,
                        albumId = cursor.getLong(albumIdColumn),
                        albumArtist = cursor.getString(albumArtistColumn),
                        genre = cursor.getString(genreColumn),
                        composer = cursor.getString(composerColumn),
                        year = cursor.getInt(yearColumn).takeIf { it > 0 }?.toLong(),
                        trackNumber = decodeTrackNumber(rawTrack),
                        discNumber = decodeDiscNumber(rawTrack),
                        durationMs = cursor.getLong(durationColumn),
                        mimeType = mimeType,
                        sizeBytes = cursor.getLong(sizeColumn),
                        dateAdded = cursor.getLong(addedColumn),
                        dateModified = cursor.getLong(modifiedColumn),
                        folderPath = folderPath,
                        folderName = File(folderPath).name,
                        hasCover = false,
                        isSupported = FormatSupport.isSupported(mimeType),
                    )
                )
            }
        }
        return result
    }

    /**
     * MediaStore codifica el numero de pista de los albumes de varios discos
     * como disco * 1000 + pista. Es la convencion que usa el propio escaner de
     * medios de Android, y evita depender de la columna DISC_NUMBER, que solo
     * existe a partir de API 31.
     */
    private fun decodeTrackNumber(rawTrack: Int): Long? = when {
        rawTrack <= 0 -> null
        rawTrack > 1000 -> (rawTrack % 1000).toLong()
        else -> rawTrack.toLong()
    }

    private fun decodeDiscNumber(rawTrack: Int): Long? =
        if (rawTrack > 1000) (rawTrack / 1000).toLong() else null

    /**
     * La portada se comprueba una vez por album y no por cancion: los albumes
     * son ordenes de magnitud menos numerosos y loadThumbnail genera y guarda
     * en cache la miniatura la primera vez (requerimiento seccion 17).
     *
     * Consecuencia asumida: en un album donde solo algunas pistas traen
     * portada, todas quedan marcadas igual. La lista inteligente "canciones sin
     * portada" trabaja por lo tanto con granularidad de album.
     */
    private fun resolveCoverPresence(scanned: List<Song>) {
        val albumRepresentative = LinkedHashMap<Long, Song>()
        for (song in scanned) {
            albumRepresentative.putIfAbsent(song.albumId, song)
        }
        for ((albumId, song) in albumRepresentative) {
            if (albumCoverPresence.containsKey(albumId)) continue
            albumCoverPresence[albumId] = loadThumbnail(song.id, COVER_PROBE_SIZE) != null
        }
    }

    private fun normalizeFolder(path: String): String =
        path.trimEnd('/').lowercase()

    private fun isExcluded(folderPath: String): Boolean {
        if (excludedFolderPaths.isEmpty()) return false
        val normalized = normalizeFolder(folderPath)
        return excludedFolderPaths.any { excluded ->
            normalized == excluded || normalized.startsWith("$excluded/")
        }
    }

    /** Miniatura cuadrada generada por el sistema, sin decodificar el original. */
    fun loadThumbnail(songId: Long, size: Int): Bitmap? {
        val uri = contentUriFor(songId)
        return runCatching { resolver.loadThumbnail(uri, Size(size, size), null) }.getOrNull()
    }

    /** Miniatura codificada en JPEG para cruzar el canal hacia Flutter. */
    fun loadThumbnailBytes(songId: Long, size: Int): CoverImage? {
        val bitmap = loadThumbnail(songId, size) ?: return null
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, COVER_JPEG_QUALITY, stream)
        return CoverImage(
            songId = songId,
            bytes = stream.toByteArray(),
            width = bitmap.width.toLong(),
            height = bitmap.height.toLong(),
        )
    }

    /**
     * Informacion tecnica del archivo. Los datos que MediaStore no expone
     * (bitrate exacto, frecuencia de muestreo, profundidad de bits) los aporta
     * TagLib (requerimiento seccion 4.2).
     */
    fun technicalInfo(songId: Long): TechnicalInfo? {
        val song = songById(songId) ?: return null
        val audioProperties = TagLibBridge.nativeReadAudioProperties(song.filePath)

        val bitrateKbps = audioProperties?.get(TagLibBridge.AudioProperty.BITRATE_KBPS)
        val sampleRate = audioProperties?.get(TagLibBridge.AudioProperty.SAMPLE_RATE_HZ)
        val channels = audioProperties?.get(TagLibBridge.AudioProperty.CHANNELS)
        val bitsPerSample = audioProperties?.get(TagLibBridge.AudioProperty.BITS_PER_SAMPLE)

        return TechnicalInfo(
            songId = songId,
            filePath = song.filePath,
            mimeType = song.mimeType,
            container = FormatSupport.containerName(song.mimeType),
            codec = FormatSupport.codecName(song.mimeType),
            durationMs = song.durationMs,
            sizeBytes = song.sizeBytes,
            bitrateBps = bitrateKbps?.takeIf { it > 0 }?.times(1000),
            sampleRateHz = sampleRate?.takeIf { it > 0 },
            bitsPerSample = bitsPerSample?.takeIf { it > 0 },
            channels = channels?.takeIf { it > 0 },
            isSupported = song.isSupported,
            unsupportedReason = FormatSupport.unsupportedReason(song.mimeType),
        )
    }

    /**
     * Pide a MediaStore releer un archivo concreto tras una escritura de
     * etiquetas (requerimiento seccion 7.1).
     */
    fun requestRescan(filePath: String) {
        MediaScannerConnection.scanFile(context, arrayOf(filePath), null, null)
    }

    /** Refresca una sola cancion del cache tras editar sus etiquetas. */
    fun refreshSong(songId: Long): Song? {
        val updated = queryOne(songId) ?: return null
        val withCover = updated.copy(hasCover = albumCoverPresence[updated.albumId] == true)
        songs = songs.map { if (it.id == songId) withCover else it }
        songsById = songs.associateBy { it.id }
        return withCover
    }

    private fun queryOne(songId: Long): Song? {
        val previous = songsById[songId] ?: return null
        val projection = arrayOf(
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ARTIST_ID,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_MODIFIED,
        )
        resolver.query(contentUriFor(songId), projection, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) return null
            val rawTrack = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK))
            return previous.copy(
                title = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE))
                    ?: previous.title,
                artist = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST))
                    ?: UNKNOWN_ARTIST,
                artistId = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST_ID)),
                album = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM))
                    ?: UNKNOWN_ALBUM,
                albumId = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)),
                albumArtist = cursor.getString(
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ARTIST)
                ),
                genre = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)),
                composer = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)),
                year = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR))
                    .takeIf { it > 0 }?.toLong(),
                trackNumber = decodeTrackNumber(rawTrack),
                discNumber = decodeDiscNumber(rawTrack),
                sizeBytes = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)),
                dateModified = cursor.getLong(
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
                ),
            )
        }
        return null
    }

    /** Invalida la portada en cache de un album tras incrustar una nueva. */
    fun invalidateAlbumCover(albumId: Long) {
        albumCoverPresence.remove(albumId)
    }

    private companion object {
        const val UNKNOWN_ARTIST = "Artista desconocido"
        const val UNKNOWN_ALBUM = "Album desconocido"
        const val COVER_PROBE_SIZE = 64
        const val COVER_JPEG_QUALITY = 88
    }
}
