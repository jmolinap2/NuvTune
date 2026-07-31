package com.nuvtune.engine

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import java.io.File

/**
 * Acceso a carpetas y archivos mediante Storage Access Framework
 * (requerimiento secciones 10 y 16: usar MediaStore y SAF, sin pedir acceso
 * total al almacenamiento).
 *
 * Sirve para dos cosas:
 *  - Las carpetas que el usuario elige como fuente de musica.
 *  - Los archivos que no son medios (`.lrc`, `.m3u`), que el almacenamiento con
 *    alcance no deja leer por ruta aunque esten junto a las canciones.
 */
internal class SafManager(private val context: Context) {

    private val resolver get() = context.contentResolver

    fun openFolderIntent(): Intent =
        Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }

    fun openDocumentIntent(mimeTypes: List<String>): Intent =
        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeTypes.firstOrNull() ?: "*/*"
            if (mimeTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

    fun createDocumentIntent(suggestedName: String, mimeType: String): Intent =
        Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, suggestedName)
        }

    /** Conserva el permiso concedido para que sobreviva al reinicio. */
    fun persistFolderPermission(treeUri: Uri) {
        resolver.takePersistableUriPermission(
            treeUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
    }

    fun releaseFolderPermission(treeUri: Uri) {
        resolver.releasePersistableUriPermission(
            treeUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
    }

    fun grantedFolders(): List<GrantedFolder> =
        resolver.persistedUriPermissions
            .filter { it.isReadPermission }
            .mapNotNull { permission ->
                val path = treeRootPath(permission.uri) ?: return@mapNotNull null
                GrantedFolder(uri = permission.uri.toString(), displayPath = path)
            }

    fun folderInfo(treeUri: Uri): GrantedFolder? {
        val path = treeRootPath(treeUri) ?: return null
        return GrantedFolder(uri = treeUri.toString(), displayPath = path)
    }

    fun readText(uri: Uri): String = readBytes(uri).decodeToString()

    fun readBytes(uri: Uri): ByteArray =
        resolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw IllegalStateException("No se pudo leer $uri")

    fun writeText(uri: Uri, content: String) {
        resolver.openOutputStream(uri, "wt")?.use { it.write(content.encodeToByteArray()) }
            ?: throw IllegalStateException("No se pudo escribir $uri")
    }

    fun documentName(uri: Uri): String? =
        resolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }

    fun documentMimeType(uri: Uri): String? = resolver.getType(uri)

    /**
     * Traduce una ruta del sistema de archivos al URI de documento equivalente
     * dentro de una carpeta ya concedida. Devuelve null si ninguna carpeta
     * concedida contiene esa ruta.
     */
    fun documentUriForPath(filePath: String): Uri? {
        for (permission in resolver.persistedUriPermissions) {
            if (!permission.isReadPermission) continue
            val treeUri = permission.uri
            val treeDocumentId = runCatching {
                DocumentsContract.getTreeDocumentId(treeUri)
            }.getOrNull() ?: continue

            val volume = treeDocumentId.substringBefore(':')
            val volumeRoot = volumeRootPath(volume) ?: continue
            val treeRelative = treeDocumentId.substringAfter(':')
            val treeRoot = if (treeRelative.isEmpty()) volumeRoot else "$volumeRoot/$treeRelative"

            if (filePath != treeRoot && !filePath.startsWith("$treeRoot/")) continue

            val relativeToVolume = filePath.removePrefix("$volumeRoot/")
            return DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                "$volume:$relativeToVolume",
            )
        }
        return null
    }

    /**
     * Crea un archivo junto a [siblingFilePath] dentro de una carpeta concedida.
     * Se usa para guardar un `.lrc` al lado de su cancion (requerimiento 8).
     */
    fun createSiblingDocument(
        siblingFilePath: String,
        displayName: String,
        mimeType: String,
    ): Uri? {
        val parentPath = File(siblingFilePath).parent ?: return null
        val parentUri = documentUriForPath(parentPath) ?: return null

        val existing = documentUriForPath("$parentPath/$displayName")
        if (existing != null && documentExists(existing)) {
            return existing
        }

        return runCatching {
            DocumentsContract.createDocument(resolver, parentUri, mimeType, displayName)
        }.getOrNull()
    }

    fun documentExists(uri: Uri): Boolean =
        resolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID), null, null, null)
            ?.use { it.moveToFirst() } == true

    private fun treeRootPath(treeUri: Uri): String? {
        val treeDocumentId = runCatching {
            DocumentsContract.getTreeDocumentId(treeUri)
        }.getOrNull() ?: return null
        val volume = treeDocumentId.substringBefore(':')
        val volumeRoot = volumeRootPath(volume) ?: return null
        val relative = treeDocumentId.substringAfter(':')
        return if (relative.isEmpty()) volumeRoot else "$volumeRoot/$relative"
    }

    /**
     * "primary" es el almacenamiento interno; cualquier otro identificador es el
     * UUID de una tarjeta SD, que el sistema monta en /storage/<UUID>.
     */
    private fun volumeRootPath(volume: String): String? = when {
        volume.equals("primary", ignoreCase = true) ->
            Environment.getExternalStorageDirectory().absolutePath
        volume.isNotEmpty() -> "/storage/$volume"
        else -> null
    }
}
