package com.nuvtune.engine

import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Obtencion de letras por internet (requerimiento seccion 8).
 *
 * Usa LRCLIB, que es un proveedor abierto, gratuito y sin clave de API, cuyo
 * contenido lo aporta la comunidad bajo licencia libre. Es la razon de elegirlo
 * frente a los catalogos comerciales: el requerimiento pide expresamente
 * proveedores legales o APIs autorizadas, y raspar un servicio cerrado no lo
 * seria.
 *
 * Es la unica funcion de la aplicacion que sale a la red sin que exista una
 * fuente remota dada de alta, y por eso la interfaz la ofrece como una accion
 * explicita del usuario, nunca automatica.
 */
internal object OnlineLyrics {

    /**
     * Devuelve el `.lrc` sincronizado si el proveedor lo tiene; si no, la letra
     * plana; y nulo cuando no hay coincidencia razonable.
     */
    fun fetch(
        title: String,
        artist: String,
        album: String,
        durationMs: Long,
    ): String? {
        val url = buildString {
            append(ENDPOINT)
            append("?track_name=").append(encode(title))
            append("&artist_name=").append(encode(artist))
            if (album.isNotEmpty()) {
                append("&album_name=").append(encode(album))
            }
        }

        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = TIMEOUT_MS
            readTimeout = TIMEOUT_MS
            // El proveedor pide identificar la aplicacion cliente.
            setRequestProperty("User-Agent", USER_AGENT)
        }

        try {
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            return pickBest(JSONArray(body), durationMs)
        } finally {
            connection.disconnect()
        }
    }

    /**
     * De todos los resultados se queda con el que mas se acerque en duracion.
     * Sin ese filtro es facil traer la letra de una version en directo o de un
     * remix que no encaja con los tiempos del archivo.
     */
    private fun pickBest(results: JSONArray, durationMs: Long): String? {
        var bestSynced: String? = null
        var bestPlain: String? = null
        var bestDelta = Long.MAX_VALUE

        for (index in 0 until results.length()) {
            val item = results.optJSONObject(index) ?: continue
            val durationSeconds = item.optDouble("duration", 0.0)
            val delta = if (durationMs > 0 && durationSeconds > 0) {
                kotlin.math.abs((durationSeconds * 1000).toLong() - durationMs)
            } else {
                0L
            }

            if (durationMs > 0 && delta > MAX_DURATION_DELTA_MS) continue
            if (delta >= bestDelta) continue

            val synced = item.optString("syncedLyrics").takeIf { it.isNotEmpty() }
            val plain = item.optString("plainLyrics").takeIf { it.isNotEmpty() }
            if (synced == null && plain == null) continue

            bestDelta = delta
            bestSynced = synced
            bestPlain = plain
        }

        return bestSynced ?: bestPlain
    }

    private fun encode(value: String): String = URLEncoder.encode(value, "UTF-8")

    private const val ENDPOINT = "https://lrclib.net/api/search"
    private const val USER_AGENT = "NuvTune/1.0 (reproductor de musica local)"
    private const val TIMEOUT_MS = 12_000
    private const val MAX_DURATION_DELTA_MS = 8_000L
}
