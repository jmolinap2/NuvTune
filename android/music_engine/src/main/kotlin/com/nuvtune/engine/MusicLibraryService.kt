package com.nuvtune.engine

import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.LibraryResult
import androidx.media3.session.MediaLibraryService.LibraryParams
import androidx.media3.session.MediaLibraryService.MediaLibrarySession
import androidx.media3.session.MediaSession
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Biblioteca navegable que se sirve a Android Auto y a cualquier otro cliente
 * de MediaBrowser (requerimiento secciones 9.2 y 13).
 *
 * El arbol se construye sobre la misma biblioteca en memoria que usa la
 * interfaz, asi que no hay dos fuentes de verdad. Solo se exponen las
 * agrupaciones que MediaStore puede resolver por si solo: canciones, albumes,
 * artistas y carpetas. Las listas y los favoritos viven en la base de datos de
 * Flutter y no estan disponibles cuando la interfaz no se ha abierto, asi que no
 * forman parte del arbol.
 */
@OptIn(UnstableApi::class)
internal class MusicLibraryCallback(
    private val library: MediaStoreRepository,
    private val onAndroidAutoConnectionChanged: (Boolean) -> Unit,
) : MediaLibrarySession.Callback {

    override fun onConnect(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
    ): MediaSession.ConnectionResult {
        if (isAndroidAuto(controller)) {
            onAndroidAutoConnectionChanged(true)
        }
        return super.onConnect(session, controller)
    }

    override fun onDisconnected(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
    ) {
        if (isAndroidAuto(controller)) {
            onAndroidAutoConnectionChanged(false)
        }
        super.onDisconnected(session, controller)
    }

    override fun onGetLibraryRoot(
        session: MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        params: LibraryParams?,
    ): ListenableFuture<LibraryResult<MediaItem>> =
        Futures.immediateFuture(
            LibraryResult.ofItem(MediaItemFactory.rootNode(), params),
        )

    override fun onGetItem(
        session: MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        mediaId: String,
    ): ListenableFuture<LibraryResult<MediaItem>> {
        val item = resolveItem(mediaId)
            ?: return Futures.immediateFuture(
                LibraryResult.ofError(LibraryResult.RESULT_ERROR_BAD_VALUE),
            )
        return Futures.immediateFuture(LibraryResult.ofItem(item, null))
    }

    override fun onGetChildren(
        session: MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        parentId: String,
        page: Int,
        pageSize: Int,
        params: LibraryParams?,
    ): ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> {
        val children = childrenOf(parentId)

        // Carga paginada, como pide el requerimiento seccion 17.
        val from = (page * pageSize).coerceAtMost(children.size)
        val to = (from + pageSize).coerceAtMost(children.size)
        val slice = children.subList(from, to)

        return Futures.immediateFuture(
            LibraryResult.ofItemList(ImmutableList.copyOf(slice), params),
        )
    }

    /**
     * Android Auto entrega los MediaItem del arbol, que no llevan URI. Hay que
     * completarlos con la cancion real antes de que el reproductor los acepte.
     */
    override fun onAddMediaItems(
        mediaSession: MediaSession,
        controller: MediaSession.ControllerInfo,
        mediaItems: MutableList<MediaItem>,
    ): ListenableFuture<MutableList<MediaItem>> {
        val resolved = mediaItems.mapNotNull { item ->
            val songId = MediaItemFactory.songIdOf(item.mediaId)
            val song = songId?.let { library.songById(it) }
            song?.let { MediaItemFactory.toMediaItem(it) }
        }.toMutableList()
        return Futures.immediateFuture(resolved)
    }

    private fun childrenOf(parentId: String): List<MediaItem> {
        val songs = library.currentSongs
        return when {
            parentId == MediaItemFactory.ROOT_ID -> listOf(
                MediaItemFactory.browsableNode(MediaItemFactory.NODE_SONGS, "Canciones"),
                MediaItemFactory.browsableNode(MediaItemFactory.NODE_ALBUMS, "Albumes"),
                MediaItemFactory.browsableNode(MediaItemFactory.NODE_ARTISTS, "Artistas"),
                MediaItemFactory.browsableNode(MediaItemFactory.NODE_FOLDERS, "Carpetas"),
            )

            parentId == MediaItemFactory.NODE_SONGS ->
                songs.filter { it.isSupported }.map { MediaItemFactory.toMediaItem(it) }

            parentId == MediaItemFactory.NODE_ALBUMS ->
                songs.groupBy { it.albumId }
                    .map { (albumId, tracks) ->
                        val first = tracks.first()
                        MediaItemFactory.albumNode(
                            albumId = albumId,
                            album = first.album,
                            artist = first.albumArtist ?: first.artist,
                            artworkUri = android.net.Uri.parse(first.uri),
                        )
                    }
                    .sortedBy { it.mediaMetadata.title?.toString()?.lowercase() }

            parentId == MediaItemFactory.NODE_ARTISTS ->
                songs.groupBy { it.artistId }
                    .map { (artistId, tracks) ->
                        MediaItemFactory.artistNode(artistId, tracks.first().artist)
                    }
                    .sortedBy { it.mediaMetadata.title?.toString()?.lowercase() }

            parentId == MediaItemFactory.NODE_FOLDERS ->
                songs.groupBy { it.folderPath }
                    .map { (path, tracks) ->
                        MediaItemFactory.folderNode(path, tracks.first().folderName)
                    }
                    .sortedBy { it.mediaMetadata.title?.toString()?.lowercase() }

            parentId.startsWith(MediaItemFactory.PREFIX_ALBUM) -> {
                val albumId = parentId.removePrefix(MediaItemFactory.PREFIX_ALBUM).toLongOrNull()
                songs.filter { it.albumId == albumId && it.isSupported }
                    .sortedWith(compareBy({ it.discNumber ?: 1 }, { it.trackNumber ?: 0 }))
                    .map { MediaItemFactory.toMediaItem(it) }
            }

            parentId.startsWith(MediaItemFactory.PREFIX_ARTIST) -> {
                val artistId = parentId.removePrefix(MediaItemFactory.PREFIX_ARTIST).toLongOrNull()
                songs.filter { it.artistId == artistId && it.isSupported }
                    .sortedBy { it.title.lowercase() }
                    .map { MediaItemFactory.toMediaItem(it) }
            }

            parentId.startsWith(MediaItemFactory.PREFIX_FOLDER) -> {
                val folderPath = parentId.removePrefix(MediaItemFactory.PREFIX_FOLDER)
                songs.filter { it.folderPath == folderPath && it.isSupported }
                    .sortedBy { it.title.lowercase() }
                    .map { MediaItemFactory.toMediaItem(it) }
            }

            else -> emptyList()
        }
    }

    private fun resolveItem(mediaId: String): MediaItem? {
        val songId = MediaItemFactory.songIdOf(mediaId)
        if (songId != null) {
            return library.songById(songId)?.let { MediaItemFactory.toMediaItem(it) }
        }
        return when (mediaId) {
            MediaItemFactory.ROOT_ID -> MediaItemFactory.rootNode()
            MediaItemFactory.NODE_SONGS ->
                MediaItemFactory.browsableNode(mediaId, "Canciones")
            MediaItemFactory.NODE_ALBUMS ->
                MediaItemFactory.browsableNode(mediaId, "Albumes")
            MediaItemFactory.NODE_ARTISTS ->
                MediaItemFactory.browsableNode(mediaId, "Artistas")
            MediaItemFactory.NODE_FOLDERS ->
                MediaItemFactory.browsableNode(mediaId, "Carpetas")
            else -> null
        }
    }

    private fun isAndroidAuto(controller: MediaSession.ControllerInfo): Boolean =
        controller.packageName in ANDROID_AUTO_PACKAGES

    private companion object {
        val ANDROID_AUTO_PACKAGES = setOf(
            "com.google.android.projection.gearhead",
            "com.google.android.autosimulator",
            "com.google.android.carassistant",
        )
    }
}
