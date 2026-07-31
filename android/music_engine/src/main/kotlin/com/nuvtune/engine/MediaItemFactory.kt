package com.nuvtune.engine

import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata

/**
 * Conversion entre [Song] y [MediaItem].
 *
 * El identificador de MediaStore viaja en `mediaId`, de modo que tanto la cola
 * que llega desde Flutter como los elementos que Android Auto pide para
 * reproducir se resuelven contra la misma biblioteca en memoria.
 */
internal object MediaItemFactory {

    /** Prefijos de los nodos de navegacion de Android Auto. */
    const val ROOT_ID = "nuvtune_root"
    const val NODE_SONGS = "nuvtune_songs"
    const val NODE_ALBUMS = "nuvtune_albums"
    const val NODE_ARTISTS = "nuvtune_artists"
    const val NODE_FOLDERS = "nuvtune_folders"
    const val PREFIX_ALBUM = "nuvtune_album:"
    const val PREFIX_ARTIST = "nuvtune_artist:"
    const val PREFIX_FOLDER = "nuvtune_folder:"

    fun songIdOf(mediaId: String): Long? = mediaId.toLongOrNull()

    fun toMediaItem(song: Song): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(song.title)
            .setArtist(song.artist)
            .setAlbumTitle(song.album)
            .setAlbumArtist(song.albumArtist ?: song.artist)
            .setGenre(song.genre)
            .setComposer(song.composer)
            .setDurationMs(song.durationMs)
            .setIsBrowsable(false)
            .setIsPlayable(true)
            .setMediaType(MediaMetadata.MEDIA_TYPE_MUSIC)
            // El cargador de imagenes del motor traduce este URI a la miniatura
            // que genera MediaStore; no se decodifica el audio como imagen.
            .setArtworkUri(Uri.parse(song.uri))
            .apply {
                song.trackNumber?.let { setTrackNumber(it.toInt()) }
                song.discNumber?.let { setDiscNumber(it.toInt()) }
                song.year?.let { setRecordingYear(it.toInt()) }
            }
            .build()

        return MediaItem.Builder()
            .setMediaId(song.id.toString())
            .setUri(Uri.parse(song.uri))
            .setMimeType(song.mimeType)
            .setMediaMetadata(metadata)
            .build()
    }

    fun browsableNode(mediaId: String, title: String): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(title)
            .setIsBrowsable(true)
            .setIsPlayable(false)
            .setMediaType(MediaMetadata.MEDIA_TYPE_FOLDER_MIXED)
            .build()
        return MediaItem.Builder()
            .setMediaId(mediaId)
            .setMediaMetadata(metadata)
            .build()
    }

    fun albumNode(albumId: Long, album: String, artist: String, artworkUri: Uri?): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(album)
            .setArtist(artist)
            .setIsBrowsable(true)
            .setIsPlayable(false)
            .setMediaType(MediaMetadata.MEDIA_TYPE_ALBUM)
            .setArtworkUri(artworkUri)
            .build()
        return MediaItem.Builder()
            .setMediaId("$PREFIX_ALBUM$albumId")
            .setMediaMetadata(metadata)
            .build()
    }

    fun artistNode(artistId: Long, artist: String): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(artist)
            .setIsBrowsable(true)
            .setIsPlayable(false)
            .setMediaType(MediaMetadata.MEDIA_TYPE_ARTIST)
            .build()
        return MediaItem.Builder()
            .setMediaId("$PREFIX_ARTIST$artistId")
            .setMediaMetadata(metadata)
            .build()
    }

    fun folderNode(folderPath: String, folderName: String): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(folderName)
            .setIsBrowsable(true)
            .setIsPlayable(false)
            .setMediaType(MediaMetadata.MEDIA_TYPE_FOLDER_MIXED)
            .build()
        return MediaItem.Builder()
            .setMediaId("$PREFIX_FOLDER$folderPath")
            .setMediaMetadata(metadata)
            .build()
    }

    fun rootNode(): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle("NuvTune")
            .setIsBrowsable(true)
            .setIsPlayable(false)
            .setMediaType(MediaMetadata.MEDIA_TYPE_FOLDER_MIXED)
            .build()
        return MediaItem.Builder()
            .setMediaId(ROOT_ID)
            .setMediaMetadata(metadata)
            .build()
    }
}
