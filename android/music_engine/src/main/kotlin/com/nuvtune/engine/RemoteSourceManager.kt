package com.nuvtune.engine

import android.content.Context
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLDecoder

/**
 * Alta, baja y navegacion de fuentes remotas (requerimiento seccion 10).
 *
 * Las fuentes remotas se mantienen deliberadamente separadas de la biblioteca
 * local: no se escanean, no entran en MediaStore y sus canciones llevan
 * identificadores negativos, de modo que nunca pueden mezclarse por accidente
 * con las locales.
 */
internal class RemoteSourceManager(private val context: Context) {

    private val preferences =
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    private val credentials = RemoteCredentialStore(context)
    private val smb = SmbClient()

    // -- Alta y baja ---------------------------------------------------------

    fun list(): List<RemoteSource> {
        val raw = preferences.getString(KEY_SOURCES, null) ?: return emptyList()
        val array = JSONArray(raw)
        return (0 until array.length()).map { index ->
            val item = array.getJSONObject(index)
            val id = item.getLong("id")
            RemoteSource(
                id = id,
                kind = RemoteSourceKind.entries[item.getInt("kind")],
                name = item.getString("name"),
                uri = item.getString("uri"),
                username = item.optString("username").takeIf { it.isNotEmpty() },
                hasPassword = credentials.has(id),
            )
        }
    }

    fun add(
        kind: RemoteSourceKind,
        name: String,
        uri: String,
        username: String?,
        password: String?,
    ): RemoteSource {
        val current = list().toMutableList()
        val id = (current.maxOfOrNull { it.id } ?: 0L) + 1L

        val source = RemoteSource(
            id = id,
            kind = kind,
            name = name,
            uri = uri.trimEnd('/'),
            username = username?.takeIf { it.isNotEmpty() },
            hasPassword = !password.isNullOrEmpty(),
        )

        current.add(source)
        persist(current)
        credentials.save(id, password)
        return source
    }

    fun remove(sourceId: Long) {
        persist(list().filterNot { it.id == sourceId })
        credentials.remove(sourceId)
    }

    private fun persist(sources: List<RemoteSource>) {
        val array = JSONArray()
        for (source in sources) {
            array.put(
                JSONObject().apply {
                    put("id", source.id)
                    put("kind", source.kind.ordinal)
                    put("name", source.name)
                    put("uri", source.uri)
                    put("username", source.username ?: "")
                },
            )
        }
        preferences.edit().putString(KEY_SOURCES, array.toString()).apply()
    }

    // -- Navegacion ----------------------------------------------------------

    fun browse(sourceId: Long, path: String): List<RemoteEntry> {
        val source = list().firstOrNull { it.id == sourceId } ?: return emptyList()
        val username = source.username
        val password = credentials.read(sourceId)

        return when (source.kind) {
            RemoteSourceKind.SMB -> smb.list(
                if (path.isEmpty()) source.uri else path,
                username,
                password,
            )

            RemoteSourceKind.WEBDAV -> listWebDav(
                if (path.isEmpty()) source.uri else path,
                username,
                password,
            )

            // Una emisora o un archivo suelto no tienen arbol que recorrer: la
            // fuente es exactamente una entrada reproducible.
            RemoteSourceKind.HTTP, RemoteSourceKind.RADIO -> listOf(
                RemoteEntry(
                    uri = source.uri,
                    name = source.name,
                    isDirectory = false,
                    mimeType = null,
                    sizeBytes = 0,
                ),
            )
        }
    }

    /**
     * Listado WebDAV por PROPFIND con profundidad 1. Se analiza el XML con
     * expresiones simples en lugar de montar un analizador completo: la
     * respuesta solo se usa para sacar rutas y tamanos.
     */
    private fun listWebDav(
        url: String,
        username: String?,
        password: String?,
    ): List<RemoteEntry> {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "PROPFIND"
            setRequestProperty("Depth", "1")
            setRequestProperty("Content-Type", "application/xml")
            applyBasicAuth(this, username, password)
            doOutput = true
            connectTimeout = TIMEOUT_MS
            readTimeout = TIMEOUT_MS
        }

        connection.outputStream.use { it.write(PROPFIND_BODY.toByteArray()) }

        val body = connection.inputStream.bufferedReader().use { it.readText() }
        connection.disconnect()

        val base = URL(url)
        val entries = mutableListOf<RemoteEntry>()

        for (response in body.split("<D:response", "<d:response", "<response").drop(1)) {
            val href = extractTag(response, "href") ?: continue
            val decoded = URLDecoder.decode(href, "UTF-8")

            // El primer elemento de la respuesta es la propia carpeta pedida.
            val absolute = URL(base, decoded).toString()
            if (absolute.trimEnd('/') == url.trimEnd('/')) continue

            val isDirectory = response.contains("<D:collection", ignoreCase = true) ||
                response.contains("<d:collection", ignoreCase = true) ||
                response.contains("<collection", ignoreCase = true)

            val name = decoded.trimEnd('/').substringAfterLast('/')
            if (name.isEmpty()) continue

            entries.add(
                RemoteEntry(
                    uri = absolute,
                    name = name,
                    isDirectory = isDirectory,
                    mimeType = if (isDirectory) {
                        null
                    } else {
                        extractTag(response, "getcontenttype")
                            ?: SmbClient.guessMimeType(name)
                    },
                    sizeBytes = extractTag(response, "getcontentlength")
                        ?.toLongOrNull() ?: 0L,
                ),
            )
        }

        return entries.sortedWith(
            compareByDescending<RemoteEntry> { it.isDirectory }.thenBy { it.name.lowercase() },
        )
    }

    // -- Conversion a canciones ---------------------------------------------

    /**
     * Construye objetos [Song] reproducibles a partir de URIs remotas.
     *
     * Los identificadores son negativos y derivan del hash de la URI: se
     * mantienen estables entre sesiones (para que favoritos e historial
     * funcionen) y no pueden chocar con los de MediaStore, que siempre son
     * positivos.
     */
    fun resolveSongs(sourceId: Long, uris: List<String>): List<Song> {
        val source = list().firstOrNull { it.id == sourceId } ?: return emptyList()
        return uris.map { uri -> songFor(uri, source.name) }
    }

    fun loadRemotePlaylist(url: String): List<Song> {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = TIMEOUT_MS
            readTimeout = TIMEOUT_MS
        }
        val content = connection.inputStream.bufferedReader().use { it.readText() }
        connection.disconnect()

        val base = URL(url)
        return content.lineSequence()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") }
            .map { entry -> URL(base, entry).toString() }
            .map { absolute -> songFor(absolute, url.substringAfterLast('/')) }
            .toList()
    }

    private fun songFor(uri: String, sourceName: String): Song {
        val name = uri.trimEnd('/').substringAfterLast('/')
            .substringBefore('?')
            .let { URLDecoder.decode(it, "UTF-8") }
        val title = name.substringBeforeLast('.').ifEmpty { sourceName }

        return Song(
            id = remoteIdFor(uri),
            uri = uri,
            filePath = uri,
            title = title,
            artist = sourceName,
            artistId = 0,
            album = sourceName,
            albumId = 0,
            albumArtist = null,
            genre = null,
            composer = null,
            year = null,
            trackNumber = null,
            discNumber = null,
            // La duracion real solo se conoce al abrir el flujo; se deja en
            // cero para no mostrar un dato inventado.
            durationMs = 0,
            mimeType = SmbClient.guessMimeType(name) ?: "audio/*",
            sizeBytes = 0,
            dateAdded = 0,
            dateModified = 0,
            folderPath = uri.substringBeforeLast('/'),
            folderName = sourceName,
            hasCover = false,
            isSupported = true,
        )
    }

    /** Credenciales de la fuente a la que pertenece una URI, para el DataSource. */
    fun credentialsFor(uri: String): Pair<String?, String?> {
        val source = list().firstOrNull { uri.startsWith(it.uri) } ?: return null to null
        return source.username to credentials.read(source.id)
    }

    fun smbClient(): SmbClient = smb

    companion object {
        private const val PREFERENCES_NAME = "nuvtune_remote_sources"
        private const val KEY_SOURCES = "sources"
        private const val TIMEOUT_MS = 15_000

        private const val PROPFIND_BODY =
            """<?xml version="1.0" encoding="utf-8"?>""" +
                """<D:propfind xmlns:D="DAV:"><D:prop>""" +
                """<D:resourcetype/><D:getcontentlength/><D:getcontenttype/>""" +
                """</D:prop></D:propfind>"""

        /** Identificador estable y siempre negativo para una URI remota. */
        fun remoteIdFor(uri: String): Long {
            val hash = uri.hashCode().toLong() and 0x7FFFFFFFL
            return -(hash + 1)
        }

        fun applyBasicAuth(
            connection: HttpURLConnection,
            username: String?,
            password: String?,
        ) {
            if (username.isNullOrEmpty()) return
            val token = Base64.encodeToString(
                "$username:${password ?: ""}".toByteArray(Charsets.UTF_8),
                Base64.NO_WRAP,
            )
            connection.setRequestProperty("Authorization", "Basic $token")
        }

        private fun extractTag(source: String, tag: String): String? {
            val pattern = Regex(
                "<(?:[a-zA-Z0-9]+:)?$tag[^>]*>(.*?)</(?:[a-zA-Z0-9]+:)?$tag>",
                RegexOption.DOT_MATCHES_ALL,
            )
            return pattern.find(source)?.groupValues?.get(1)?.trim()?.takeIf { it.isNotEmpty() }
        }
    }
}
