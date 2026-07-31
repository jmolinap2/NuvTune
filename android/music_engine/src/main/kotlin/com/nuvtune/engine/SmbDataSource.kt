package com.nuvtune.engine

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.BaseDataSource
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener
import java.io.IOException
import java.io.InputStream

/**
 * Permite a Media3 reproducir directamente desde `smb://` (requerimiento 10).
 *
 * ExoPlayer sabe leer archivos locales y HTTP, pero no SMB: sin esta clase una
 * cancion de un NAS habria que descargarla entera antes de sonar. Aqui se lee
 * por bloques igual que en cualquier otra fuente, de modo que la reproduccion
 * empieza de inmediato y el salto de posicion sigue funcionando.
 */
@OptIn(UnstableApi::class)
internal class SmbDataSource(
    private val client: SmbClient,
    private val credentials: (String) -> Pair<String?, String?>,
) : BaseDataSource(true) {

    private var uri: Uri? = null
    private var openFile: SmbClient.OpenFile? = null
    private var stream: InputStream? = null
    private var bytesRemaining: Long = 0
    private var opened = false

    override fun open(dataSpec: DataSpec): Long {
        uri = dataSpec.uri
        transferInitializing(dataSpec)

        val address = dataSpec.uri.toString()
        val (username, password) = credentials(address)
        val file = client.open(address, username, password)
            ?: throw IOException("No se pudo abrir $address")

        openFile = file
        stream = file.file.getInputStream()

        if (dataSpec.position > 0) {
            var toSkip = dataSpec.position
            while (toSkip > 0) {
                val skipped = stream!!.skip(toSkip)
                if (skipped <= 0) throw IOException("No se pudo posicionar en $address")
                toSkip -= skipped
            }
        }

        bytesRemaining = if (dataSpec.length == C.LENGTH_UNSET.toLong()) {
            file.length - dataSpec.position
        } else {
            dataSpec.length
        }

        opened = true
        transferStarted(dataSpec)
        return bytesRemaining
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (length == 0) return 0
        if (bytesRemaining == 0L) return C.RESULT_END_OF_INPUT

        val toRead = minOf(length.toLong(), bytesRemaining).toInt()
        val read = stream?.read(buffer, offset, toRead) ?: C.RESULT_END_OF_INPUT
        if (read == -1) return C.RESULT_END_OF_INPUT

        bytesRemaining -= read
        bytesTransferred(read)
        return read
    }

    override fun getUri(): Uri? = uri

    override fun close() {
        uri = null
        runCatching { stream?.close() }
        stream = null
        openFile?.close()
        openFile = null
        bytesRemaining = 0
        if (opened) {
            opened = false
            transferEnded()
        }
    }

    /** Fabrica que se enchufa al `DefaultMediaSourceFactory` del reproductor. */
    class Factory(
        private val client: SmbClient,
        private val credentials: (String) -> Pair<String?, String?>,
    ) : DataSource.Factory {

        private val listeners = mutableListOf<TransferListener>()

        fun addTransferListener(listener: TransferListener) = apply {
            listeners.add(listener)
        }

        override fun createDataSource(): DataSource {
            val source = SmbDataSource(client, credentials)
            for (listener in listeners) {
                source.addTransferListener(listener)
            }
            return source
        }
    }
}
