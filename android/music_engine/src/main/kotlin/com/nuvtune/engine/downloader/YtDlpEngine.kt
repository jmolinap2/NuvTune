package com.nuvtune.engine.downloader

import android.content.Context
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.mapper.VideoFormat
import com.yausername.youtubedl_android.mapper.VideoInfo
import java.io.IOException
import java.net.UnknownHostException

/**
 * Envoltorio fino sobre youtubedl-android, portado de C:\Repos\NuvClip. No
 * conoce Flutter ni el ciclo de vida de Android: solo sabe inicializar el
 * binario, buscar, analizar un enlace y construir el comando de descarga.
 * `DownloadEnginePlugin` y `DownloadForegroundService` son quienes lo
 * conectan con Pigeon y con la notificacion en primer plano.
 */
object YtDlpEngine {
    @Volatile
    private var initialized = false

    // Bitrates fijos ofrecidos para la extraccion de audio. NuvTune solo
    // descarga audio (a diferencia de NuvClip, que tambien ofrece video), asi
    // que estos son los unicos formatos que la app realmente usa.
    private val audioQualityKbps = intArrayOf(192, 128, 64)

    @Synchronized
    fun initialize(context: Context) {
        if (initialized) return
        val appContext = context.applicationContext
        YoutubeDL.getInstance().init(appContext)
        FFmpeg.getInstance().init(appContext)
        initialized = true
    }

    fun assertInitialized() {
        check(initialized) { "YtDlpEngine.initialize() no se ha llamado todavia" }
    }

    fun currentVersion(context: Context): String? =
        YoutubeDL.version(context.applicationContext)

    /**
     * Resultado liviano de una busqueda por texto: yt-dlp no tiene un tipo
     * "resultado de busqueda", asi que esto se arma a mano leyendo el JSON
     * crudo de `ytsearchN:` (ver [search]) en vez de la clase [VideoInfo],
     * que no modela listas de resultados (no tiene campo `entries`).
     */
    data class SearchEntry(
        val videoId: String,
        val title: String,
        val author: String?,
        val thumbnailUrl: String?,
        val durationSeconds: Long,
    )

    /**
     * Busca en YouTube por texto libre usando el pseudo-URL `ytsearchN:` que
     * entiende yt-dlp nativamente. Se usa `--flat-playlist` para que sea
     * rapido (un solo listado, sin analizar cada resultado a fondo); el
     * resultado elegido se analiza despues con [analyze] sobre su URL real.
     *
     * La clase tipada [VideoInfo] de youtubedl-android no expone un campo de
     * entradas de lista/busqueda, asi que aqui se ejecuta el comando crudo y
     * se lee el JSON con el `ObjectMapper` que la propia libreria expone,
     * en vez de forzar un mapeo que la libreria no ofrece.
     */
    fun search(query: String, limit: Int): List<SearchEntry> {
        assertInitialized()
        val safeLimit = limit.coerceIn(1, 25)
        val request = YoutubeDLRequest("ytsearch$safeLimit:${query.trim()}")
        request.addOption("--flat-playlist")
        request.addOption("-J")
        request.addOption("--no-warnings")

        val response = YoutubeDL.getInstance().execute(request)
        val root = YoutubeDL.getInstance().objectMapper.readTree(response.out)
        val entries = root?.get("entries") ?: return emptyList()

        val results = ArrayList<SearchEntry>()
        for (entry in entries) {
            val id = entry.get("id")?.asText()?.takeIf { it.isNotBlank() } ?: continue
            results.add(
                SearchEntry(
                    videoId = id,
                    title = entry.get("title")?.asText()?.takeIf { it.isNotBlank() } ?: "Sin título",
                    author = entry.get("uploader")?.asText(),
                    thumbnailUrl = entry.get("thumbnail")?.asText(),
                    durationSeconds = entry.get("duration")?.asLong() ?: 0L,
                )
            )
        }
        return results
    }

    /**
     * Lanza YoutubeDLException con el texto crudo de yt-dlp si algo falla; el
     * llamador (DownloadEnginePlugin) es quien lo clasifica con
     * [classifyError] y arma el [AnalysisResult].
     */
    fun analyze(url: String): VideoInfo {
        assertInitialized()
        val request = YoutubeDLRequest(url)
        // Un enlace a un perfil o a un "reel" dentro de una coleccion no debe
        // arrastrar toda la lista: el usuario eligio un video, no una cuenta.
        request.addOption("--no-playlist")
        request.addOption("--no-warnings")
        return YoutubeDL.getInstance().getInfo(request)
    }

    /** Reintenta una sola vez tras actualizar yt-dlp si cambió el extractor. */
    fun analyzeWithRecovery(context: Context, url: String): VideoInfo =
        try {
            analyze(url)
        } catch (first: Exception) {
            if (classifyError(first) != DownloadErrorCode.EXTRACTOR_OUTDATED) throw first
            updateExtractor(context)
            analyze(url)
        }

    /**
     * URL directa del stream de audio, sin descargar nada. `-g`
     * (`--get-url`) hace que yt-dlp resuelva el formato y escriba la URL en
     * la salida estandar en vez de bajar el archivo; es lo que permite
     * escuchar una vista previa antes de decidir la descarga.
     *
     * La URL caduca (YouTube la firma por tiempo), asi que se resuelve en el
     * momento de reproducir y no se guarda.
     */
    fun audioStreamUrl(sourceUrl: String): String? {
        assertInitialized()
        val request = YoutubeDLRequest(sourceUrl)
        request.addOption("--no-playlist")
        request.addOption("--no-warnings")
        request.addOption("-f", "bestaudio/best")
        request.addOption("-g")
        val response = YoutubeDL.getInstance().execute(request)
        return response.out.lineSequence()
            .map { it.trim() }
            .firstOrNull { it.startsWith("http", ignoreCase = true) }
    }

    fun audioStreamUrlWithRecovery(context: Context, sourceUrl: String): String? =
        try {
            audioStreamUrl(sourceUrl)
        } catch (first: Exception) {
            if (classifyError(first) != DownloadErrorCode.EXTRACTOR_OUTDATED) throw first
            updateExtractor(context)
            audioStreamUrl(sourceUrl)
        }

    /**
     * A diferencia de un desglose por resolucion (NuvClip, que tambien
     * descarga video), estas opciones son tres bitrates fijos, siempre
     * disponibles sin importar que exponga el extractor. El tamaño es una
     * estimacion CBR a partir de la duracion (bitrate * duracion / 8),
     * suficiente para mostrar un tamaño aproximado antes de descargar.
     */
    fun toAudioFormatOptions(info: VideoInfo): List<VideoFormatOption> {
        val durationSeconds = info.duration.toLong()
        return audioQualityKbps.map { kbps ->
            VideoFormatOption(
                formatId = "audio-$kbps",
                qualityLabel = "$kbps kbps",
                fileExtension = "mp3",
                height = null,
                approxSizeBytes = if (durationSeconds > 0) durationSeconds * kbps * 1000L / 8 else null,
            )
        }
    }

    fun buildDownloadRequest(sourceUrl: String, formatId: String, outputPath: String): YoutubeDLRequest {
        val request = YoutubeDLRequest(sourceUrl)
        request.addOption("--no-playlist")
        val kbps = formatId.removePrefix("audio-").toIntOrNull() ?: audioQualityKbps.last()
        // "-f bestaudio/best" deja que yt-dlp elija la mejor fuente de audio
        // disponible; -x + ffmpeg (ya inicializado en initialize()) hace la
        // extraccion real a mp3, sin importar si el origen traia audio y
        // video mezclados (caso comun en TikTok/Instagram).
        request.addOption("-f", "bestaudio/best")
        request.addOption("-x")
        request.addOption("--audio-format", "mp3")
        request.addOption("--audio-quality", "${kbps}K")
        // Conserva la ficha musical dentro del archivo. ffmpeg convierte la
        // miniatura cuando YouTube la entrega como WebP y la incrusta como
        // portada del MP3; MediaStore recibe ademas titulo/artista explicitos.
        request.addOption("--add-metadata")
        request.addOption("--embed-thumbnail")
        request.addOption("--convert-thumbnails", "jpg")
        request.addOption("-o", outputPath)
        return request
    }

    @Synchronized
    fun updateExtractor(context: Context): Pair<Boolean, String?> {
        assertInitialized()
        val status = YoutubeDL.getInstance().updateYoutubeDL(context.applicationContext)
        val updated = status == YoutubeDL.UpdateStatus.DONE
        return updated to currentVersion(context)
    }

    /**
     * Traduce el texto crudo de yt-dlp (stderr, o el mensaje de la
     * excepcion) a uno de los codigos del contrato. yt-dlp no expone codigos
     * de error estructurados, asi que esto es un mejor esfuerzo por
     * coincidencia de texto conocido, no una clasificacion garantizada.
     */
    fun classifyError(throwable: Throwable): DownloadErrorCode {
        if (throwable is UnknownHostException || throwable is IOException) {
            return DownloadErrorCode.NETWORK_LOST
        }
        val text = (throwable.message ?: "").lowercase()
        return when {
            text.contains("unsupported url") -> DownloadErrorCode.UNSUPPORTED_LINK
            text.contains("private") -> DownloadErrorCode.PRIVATE_CONTENT
            text.contains("login") && text.contains("required") -> DownloadErrorCode.PRIVATE_CONTENT
            text.contains("not available") && (text.contains("removed") || text.contains("longer")) ->
                DownloadErrorCode.CONTENT_REMOVED
            text.contains("this content isn't available") || text.contains("no longer available") ||
                text.contains("has been removed") -> DownloadErrorCode.CONTENT_REMOVED
            text.contains("not available in your country") || text.contains("geo-restricted") ||
                text.contains("blocked it in your country") -> DownloadErrorCode.REGION_RESTRICTED
            text.contains("unable to extract") || text.contains("unable to parse") ||
                text.contains("failed to parse json") -> DownloadErrorCode.EXTRACTOR_OUTDATED
            text.contains("unable to download webpage") || text.contains("http error 404") ||
                text.contains("http error 403") -> DownloadErrorCode.FETCH_FAILED
            text.contains("no space left") -> DownloadErrorCode.INSUFFICIENT_STORAGE
            else -> DownloadErrorCode.UNKNOWN
        }
    }
}
