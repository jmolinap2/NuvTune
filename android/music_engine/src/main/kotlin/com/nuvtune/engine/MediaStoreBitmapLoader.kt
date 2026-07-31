package com.nuvtune.engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.util.BitmapLoader
import androidx.media3.common.util.UnstableApi
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.SettableFuture
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Carga la portada para la notificacion multimedia, la pantalla de bloqueo y
 * Android Auto.
 *
 * El cargador por omision de Media3 descargaria el URI y trataria de
 * decodificarlo como imagen; aqui los URI de portada son los de la propia
 * cancion en MediaStore, asi que se traducen a la miniatura que genera el
 * sistema. De paso se cumple el requerimiento seccion 17: no se decodifica la
 * portada en resolucion completa.
 */
@OptIn(UnstableApi::class)
internal class MediaStoreBitmapLoader(
    private val library: MediaStoreRepository,
) : BitmapLoader {

    private val executor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "NuvTuneBitmapLoader").apply { isDaemon = true }
    }

    override fun supportsMimeType(mimeType: String): Boolean =
        mimeType.startsWith("image/")

    override fun decodeBitmap(data: ByteArray): ListenableFuture<Bitmap> {
        val future = SettableFuture.create<Bitmap>()
        executor.execute {
            val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size)
            if (bitmap != null) {
                future.set(bitmap)
            } else {
                future.setException(IllegalArgumentException("Los bytes no son una imagen"))
            }
        }
        return future
    }

    override fun loadBitmap(uri: Uri): ListenableFuture<Bitmap> {
        val future = SettableFuture.create<Bitmap>()
        executor.execute {
            val songId = uri.lastPathSegment?.toLongOrNull()
            val bitmap = songId?.let { library.loadThumbnail(it, NOTIFICATION_COVER_SIZE) }
            if (bitmap != null) {
                future.set(bitmap)
            } else {
                future.setException(IllegalStateException("Sin portada para $uri"))
            }
        }
        return future
    }

    private companion object {
        /**
         * Tamano suficiente para la notificacion expandida y para la tarjeta de
         * Android Auto, sin cargar la portada completa en memoria.
         */
        const val NOTIFICATION_COVER_SIZE = 512
    }
}
