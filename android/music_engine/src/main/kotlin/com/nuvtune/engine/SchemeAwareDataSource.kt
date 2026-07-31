package com.nuvtune.engine

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener

/**
 * Elige la fuente de datos segun el esquema de la URI (requerimiento seccion 10).
 *
 * Media3 resuelve por si solo `file://`, `content://`, `http://` y `https://`,
 * de modo que aqui solo hay que desviar `smb://` hacia [SmbDataSource]. La
 * decision se toma al abrir y no al construir, porque una misma cola puede
 * mezclar canciones locales y de un NAS.
 */
@OptIn(UnstableApi::class)
internal class SchemeAwareDataSource(
    private val local: DataSource,
    private val smb: DataSource,
) : DataSource {

    private var active: DataSource = local

    override fun open(dataSpec: DataSpec): Long {
        active = if (dataSpec.uri.scheme.equals(SMB_SCHEME, ignoreCase = true)) smb else local
        return active.open(dataSpec)
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int =
        active.read(buffer, offset, length)

    override fun getUri(): Uri? = active.uri

    override fun getResponseHeaders(): Map<String, List<String>> = active.responseHeaders

    override fun close() = active.close()

    override fun addTransferListener(transferListener: TransferListener) {
        local.addTransferListener(transferListener)
        smb.addTransferListener(transferListener)
    }

    class Factory(
        private val local: DataSource.Factory,
        private val smb: DataSource.Factory,
    ) : DataSource.Factory {
        override fun createDataSource(): DataSource =
            SchemeAwareDataSource(local.createDataSource(), smb.createDataSource())
    }

    private companion object {
        const val SMB_SCHEME = "smb"
    }
}
