package com.nuvtune.engine

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * Registro persistente de todo lo que falla al leer o reproducir musica.
 *
 * Existe porque el chequeo de compatibilidad que se hacia antes (comparar el
 * MIME contra la lista de decodificadores del telefono) solo detecta una
 * fraccion de los fallos reales: un archivo puede declarar un formato
 * soportado y aun asi fallar al decodificarlo (corrupcion, descarga
 * incompleta, cabecera malformada). Sin un registro de lo que pasa de
 * verdad en el telefono del usuario, cualquier diagnostico es una
 * suposicion.
 *
 * Cubre las tres formas en que una cancion puede fallar:
 *  - [Stage.SCAN]: el escaneo de la biblioteca la marca como no soportada
 *    por su MIME, antes de intentar reproducirla siquiera.
 *  - [Stage.MANUAL_PLAY]: el usuario la toco a proposito y el reproductor
 *    no pudo abrirla.
 *  - [Stage.AUTO_SKIP]: fallo mientras la cola avanzaba sola (aleatorio o
 *    reproduccion continua), sin que el usuario la tocara.
 *  - [Stage.SHORT_PLAYBACK]: no hubo ningun error, pero la pista termino
 *    mucho antes de lo que su duracion declarada prometia -sintoma tipico
 *    de un archivo truncado que el extractor no rechaza, solo acorta.
 *
 * El archivo es JSON Lines (un objeto por linea) para poder revisarlo con
 * cualquier editor de texto o exportarlo tal cual.
 */
internal object PlaybackFailureLog {

    enum class Stage { SCAN, MANUAL_PLAY, AUTO_SKIP, SHORT_PLAYBACK }

    private const val FILE_NAME = "playback_failures.jsonl"

    /** Techo generoso: miles de entradas de texto plano pesan poco. */
    private const val MAX_BYTES = 2 * 1024 * 1024L
    private const val TRIM_TARGET_LINES = 1000

    /**
     * Ventana durante la cual no se repite la misma entrada.
     *
     * Sin esto, cada rescaneo de la biblioteca (que puede pasar varias veces
     * por sesion: al abrir la app, al detectar un cambio externo, tras
     * importar un regalo) volvia a escribir la misma cancion no soportada
     * una vez por archivo, llenando el registro de miles de copias
     * identicas de las mismas 5 canciones y ahogando cualquier fallo real de
     * reproduccion. 30 minutos es suficiente para no repetir dentro de una
     * misma sesion de uso, mientras sigue mostrando si el problema persiste
     * dia tras dia.
     */
    private const val DEDUPE_WINDOW_MS = 30 * 60 * 1000L

    private lateinit var logFile: File
    private val lastLoggedAt = HashMap<String, Long>()

    @Synchronized
    fun attach(context: Context) {
        if (::logFile.isInitialized) return
        logFile = File(context.filesDir, FILE_NAME)
    }

    @Synchronized
    fun record(
        stage: Stage,
        songId: Long?,
        title: String?,
        filePath: String?,
        mimeType: String?,
        code: String?,
        message: String,
    ) {
        if (!::logFile.isInitialized) return

        val now = System.currentTimeMillis()
        val dedupeKey = "${stage.name}|$songId|$message"
        val last = lastLoggedAt[dedupeKey]
        if (last != null && now - last < DEDUPE_WINDOW_MS) return
        lastLoggedAt[dedupeKey] = now

        val entry = JSONObject().apply {
            put("ts", now)
            put("stage", stage.name)
            put("songId", songId ?: JSONObject.NULL)
            put("title", title ?: JSONObject.NULL)
            put("filePath", filePath ?: JSONObject.NULL)
            put("mimeType", mimeType ?: JSONObject.NULL)
            put("code", code ?: JSONObject.NULL)
            put("message", message)
        }
        runCatching {
            logFile.appendText(entry.toString() + "\n")
            // Se revisa el tamaño solo despues de escribir, no antes: es un
            // stat() barato y evita releer el archivo entero en cada entrada.
            if (logFile.length() > MAX_BYTES) trim()
        }
    }

    private fun trim() {
        val kept = logFile.readLines().takeLast(TRIM_TARGET_LINES)
        logFile.writeText(if (kept.isEmpty()) "" else kept.joinToString("\n") + "\n")
    }

    @Synchronized
    fun readAllAsJson(): String {
        if (!::logFile.isInitialized || !logFile.exists()) return "[]"
        val lines = logFile.readLines().filter { it.isNotBlank() }
        return lines.joinToString(prefix = "[", postfix = "]", separator = ",")
    }

    @Synchronized
    fun clear() {
        if (::logFile.isInitialized) logFile.writeText("")
        // Vaciar el registro a mano es una señal de "quiero volver a ver todo
        // desde cero": la ventana de deduplicacion no debe seguir ocultando
        // entradas que el usuario acaba de borrar a proposito.
        lastLoggedAt.clear()
    }

    /** Ruta del archivo, para compartirlo tal cual con `ShareHelper`. */
    @Synchronized
    fun fileForSharing(): File? =
        if (::logFile.isInitialized && logFile.exists() && logFile.length() > 0) logFile else null
}
