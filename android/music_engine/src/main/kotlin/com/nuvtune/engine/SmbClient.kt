package com.nuvtune.engine

import com.hierynomus.msdtyp.AccessMask
import com.hierynomus.mssmb2.SMB2CreateDisposition
import com.hierynomus.mssmb2.SMB2ShareAccess
import com.hierynomus.smbj.SMBClient
import com.hierynomus.smbj.auth.AuthenticationContext
import com.hierynomus.smbj.share.DiskShare
import com.hierynomus.smbj.share.File
import java.util.EnumSet

/**
 * Acceso a carpetas compartidas SMB2/SMB3 y NAS (requerimiento seccion 10).
 *
 * Una URI `smb://servidor/recurso/carpeta/archivo.flac` se descompone en
 * servidor, recurso compartido y ruta dentro del recurso, que es como espera
 * trabajar smbj.
 */
internal class SmbClient {

    /** Partes de una URI smb:// ya separadas. */
    data class Location(
        val host: String,
        val share: String,
        val path: String,
    )

    fun list(uri: String, username: String?, password: String?): List<RemoteEntry> {
        val location = parse(uri) ?: return emptyList()

        return withShare(location, username, password) { share ->
            share.list(location.path)
                .filter { it.fileName != "." && it.fileName != ".." }
                .map { item ->
                    val isDirectory = item.fileAttributes and DIRECTORY_ATTRIBUTE != 0L
                    val childPath = if (location.path.isEmpty()) {
                        item.fileName
                    } else {
                        "${location.path}\\${item.fileName}"
                    }
                    RemoteEntry(
                        uri = buildUri(location.host, location.share, childPath),
                        name = item.fileName,
                        isDirectory = isDirectory,
                        mimeType = if (isDirectory) null else guessMimeType(item.fileName),
                        sizeBytes = item.endOfFile,
                    )
                }
                .sortedWith(compareByDescending<RemoteEntry> { it.isDirectory }
                    .thenBy { it.name.lowercase() })
        }
    }

    /**
     * Abre un archivo para lectura. El llamador es responsable de cerrar tanto
     * el archivo como la conexion que devuelve.
     */
    fun open(uri: String, username: String?, password: String?): OpenFile? {
        val location = parse(uri) ?: return null

        val client = SMBClient()
        val connection = client.connect(location.host)
        val session = connection.authenticate(authContext(username, password))
        val share = session.connectShare(location.share) as? DiskShare
            ?: run {
                connection.close()
                return null
            }

        val file = share.openFile(
            location.path,
            EnumSet.of(AccessMask.GENERIC_READ),
            null,
            SMB2ShareAccess.ALL,
            SMB2CreateDisposition.FILE_OPEN,
            null,
        )
        return OpenFile(client, file, file.fileInformation.standardInformation.endOfFile)
    }

    /** Archivo remoto abierto junto con el cliente que lo mantiene vivo. */
    class OpenFile(
        private val client: SMBClient,
        val file: File,
        val length: Long,
    ) {
        fun close() {
            runCatching { file.close() }
            runCatching { client.close() }
        }
    }

    private fun <T> withShare(
        location: Location,
        username: String?,
        password: String?,
        block: (DiskShare) -> T,
    ): T {
        SMBClient().use { client ->
            val connection = client.connect(location.host)
            val session = connection.authenticate(authContext(username, password))
            val share = session.connectShare(location.share) as DiskShare
            return block(share)
        }
    }

    private fun authContext(username: String?, password: String?): AuthenticationContext =
        if (username.isNullOrEmpty()) {
            AuthenticationContext.anonymous()
        } else {
            AuthenticationContext(username, (password ?: "").toCharArray(), null)
        }

    companion object {
        private const val DIRECTORY_ATTRIBUTE = 0x10L

        /**
         * `smb://host/share/carpeta/archivo` -> host, share y `carpeta\archivo`.
         * smbj usa la barra invertida como separador dentro del recurso.
         */
        fun parse(uri: String): Location? {
            val withoutScheme = uri.removePrefix("smb://")
            if (withoutScheme == uri) return null

            val segments = withoutScheme.split('/').filter { it.isNotEmpty() }
            if (segments.size < 2) return null

            return Location(
                host = segments[0],
                share = segments[1],
                path = segments.drop(2).joinToString("\\"),
            )
        }

        fun buildUri(host: String, share: String, path: String): String {
            val normalized = path.replace('\\', '/')
            return if (normalized.isEmpty()) {
                "smb://$host/$share"
            } else {
                "smb://$host/$share/$normalized"
            }
        }

        fun guessMimeType(name: String): String? = when (name.substringAfterLast('.', "").lowercase()) {
            "mp3" -> "audio/mpeg"
            "flac" -> "audio/flac"
            "m4a", "aac" -> "audio/mp4"
            "ogg", "oga" -> "audio/ogg"
            "opus" -> "audio/opus"
            "wav" -> "audio/wav"
            "aiff", "aif" -> "audio/aiff"
            "wma" -> "audio/x-ms-wma"
            else -> null
        }
    }
}
