package com.nuvtune.engine.downloader

import android.content.Context
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.mapper.VideoFormat
import com.yausername.youtubedl_android.mapper.VideoInfo
import java.io.File
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

    /**
     * Valor de `--js-runtimes`, resuelto una sola vez en [initialize].
     *
     * youtubedl-android empaqueta QuickJS como `libqjs.so`, pero yt-dlp solo
     * habilita `deno` por defecto, de modo que nunca lo encontraba y trabajaba
     * "sin runtime de JavaScript". Medido en el dispositivo: sin esto, YouTube
     * fuerza SABR, descarta los formatos directos y `-g` termina devolviendo un
     * manifiesto HLS (que ExoPlayer no puede leer: responde 403) o directamente
     * "Sign in to confirm you're not a bot". Con QuickJS habilitado, el mismo
     * video resuelve a un itag de audio directo de forma estable.
     */
    @Volatile
    private var jsRuntime: String? = null

    /** Guardado en [initialize]; lo necesitan las cookies de YouTube. */
    private lateinit var appContext: Context

    // Bitrates fijos ofrecidos para la extraccion de audio. NuvTune solo
    // descarga audio (a diferencia de NuvClip, que tambien ofrece video), asi
    // que estos son los unicos formatos que la app realmente usa.
    private val audioQualityKbps = intArrayOf(192, 128, 64)

    @Synchronized
    fun initialize(context: Context) {
        if (initialized) return
        appContext = context.applicationContext
        YoutubeDL.getInstance().init(appContext)
        FFmpeg.getInstance().init(appContext)
        jsRuntime = resolveQuickJs(appContext)
        initialized = true
    }

    /**
     * Android solo permite ejecutar binarios desde `nativeLibraryDir`, que es
     * justo donde el empaquetado heredado (`useLegacyPackaging = true`) deja
     * `libqjs.so`. Si no estuviera, el APK esta mal armado: se falla aqui en
     * vez de seguir sin runtime y acabar en un "actualiza el motor" enganoso.
     */
    private fun resolveQuickJs(context: Context): String {
        val binary = File(context.applicationInfo.nativeLibraryDir, QUICK_JS_LIB_NAME)
        check(binary.canExecute()) {
            "$QUICK_JS_LIB_NAME no es ejecutable en ${binary.parent}: " +
                "el APK no incluye el runtime de JavaScript que YouTube exige"
        }
        return "quickjs:${binary.absolutePath}"
    }

    fun assertInitialized() {
        check(initialized) { "YtDlpEngine.initialize() no se ha llamado todavia" }
    }

    fun currentVersion(context: Context): String? =
        YoutubeDL.version(context.applicationContext)

    /**
     * Resultado liviano de una busqueda por texto: yt-dlp no tiene un tipo
     * "resultado de busqueda", asi que esto se arma a mano leyendo el JSON
     * crudo de cada buscador (ver [search]) en vez de la clase [VideoInfo],
     * que no modela listas de resultados (no tiene campo `entries`).
     */
    data class SearchEntry(
        val sourceUrl: String,
        val platform: SourcePlatform,
        val title: String,
        val author: String?,
        val thumbnailUrl: String?,
        val durationSeconds: Long,
    )

    /**
     * Busca en YouTube y SoundCloud a la vez y combina los resultados.
     *
     * YouTube exige ahora sesion iniciada para entregar el audio real de casi
     * cualquier video a un cliente anonimo (SABR + PO token); sin sesion,
     * `analyzeUrl`/`startDownload` fallan con "confirma que no eres un robot"
     * la mayoria de las veces (medido en el dispositivo, incluso con el
     * yt-dlp mas reciente disponible). SoundCloud no impone esa barrera, asi
     * que sus resultados sirven de respaldo inmediato aunque el usuario no
     * haya iniciado sesion — a cambio de un catalogo mas volcado a subidas de
     * usuarios y covers que a la pista oficial.
     *
     * Cada fuente se aisla con `runCatching`: si una falla (red, formato
     * inesperado), la otra igual entrega resultados en vez de que la
     * busqueda entera quede en cero.
     */
    fun search(query: String, limit: Int): List<SearchEntry> {
        assertInitialized()
        val safeLimit = limit.coerceIn(1, 25)
        val youtubeLimit = (safeLimit + 1) / 2
        val soundcloudLimit = safeLimit - youtubeLimit

        val results = ArrayList<SearchEntry>()
        results += runCatching { searchYoutube(query, youtubeLimit) }.getOrElse { emptyList() }
        results += runCatching { searchSoundCloud(query, soundcloudLimit) }.getOrElse { emptyList() }
        return results
    }

    /**
     * `ytsearchN:` es el pseudo-URL que entiende yt-dlp nativamente. Se usa
     * `--flat-playlist` para que sea rapido (un solo listado, sin analizar
     * cada resultado a fondo): el `id` de cada entrada basta para reconstruir
     * una URL publica y estable (`watch?v=`), que se resuelve de verdad
     * despues con [analyze] cuando el usuario elige un resultado.
     */
    private fun searchYoutube(query: String, limit: Int): List<SearchEntry> {
        if (limit <= 0) return emptyList()
        val request = YoutubeDLRequest("ytsearch$limit:${query.trim()}")
        applyCommonOptions(request)
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
                    sourceUrl = "https://www.youtube.com/watch?v=$id",
                    platform = SourcePlatform.YOUTUBE,
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
     * A diferencia de YouTube, aqui NO se usa `--flat-playlist`: sus entradas
     * "planas" traen una URL interna (`api.soundcloud.com/tracks/...`) que
     * falla con 401 al reutilizarla despues en `analyzeUrl`/`startPreview`
     * (medido en el dispositivo). Se paga la resolucion completa de cada
     * resultado para que `webpage_url` sea la URL publica reutilizable.
     */
    private fun searchSoundCloud(query: String, limit: Int): List<SearchEntry> {
        if (limit <= 0) return emptyList()
        val request = YoutubeDLRequest("scsearch$limit:${query.trim()}")
        applyCommonOptions(request)
        request.addOption("-J")
        request.addOption("--no-warnings")

        val response = YoutubeDL.getInstance().execute(request)
        val root = YoutubeDL.getInstance().objectMapper.readTree(response.out)
        val entries = root?.get("entries") ?: return emptyList()

        val results = ArrayList<SearchEntry>()
        for (entry in entries) {
            val url = entry.get("webpage_url")?.asText()?.takeIf { it.isNotBlank() } ?: continue
            results.add(
                SearchEntry(
                    sourceUrl = url,
                    platform = SourcePlatform.SOUNDCLOUD,
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
        applyCommonOptions(request)
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
        applyCommonOptions(request)
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
        applyCommonOptions(request)
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

    /**
     * Opciones que necesita **toda** invocacion de yt-dlp. Viven en un unico
     * sitio a proposito: una ruta que se quede sin el runtime de JavaScript
     * vuelve a caer en el fallo de SABR/HLS que costo diagnosticar.
     *
     * Los limites de red los aplica el propio extractor (no una espera
     * externa): si el CDN deja una conexion a medio abrir, el proceso nativo
     * termina con su diagnostico real y se puede clasificar, en vez de quedarse
     * colgado sin que la vista previa ni el servicio puedan responder.
     */
    private fun applyCommonOptions(request: YoutubeDLRequest) {
        request.addOption("--js-runtimes", jsRuntime ?: resolveQuickJsOrFail())
        request.addOption("--socket-timeout", SOCKET_TIMEOUT_SECONDS.toString())
        request.addOption("--retries", NETWORK_RETRIES.toString())
        request.addOption("--fragment-retries", NETWORK_RETRIES.toString())
        request.addOption("--extractor-retries", NETWORK_RETRIES.toString())
        // No se cachea junto a jsRuntime: el usuario puede iniciar sesion (o
        // cerrarla) en cualquier momento de la sesion de la app, y cada
        // llamada debe ver el estado actual, no el de cuando se inicializo
        // el motor. Es un simple chequeo de archivo, no una llamada de red.
        if (YouTubeCookieJar.hasLogin(appContext)) {
            request.addOption("--cookies", YouTubeCookieJar.file(appContext).absolutePath)
        }
    }

    private fun resolveQuickJsOrFail(): String =
        error("YtDlpEngine.initialize() no se ha llamado todavia")

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
                text.contains("failed to parse json") ||
                text.contains("signature") -> DownloadErrorCode.EXTRACTOR_OUTDATED
            // El anti-bot y el 429 son limitaciones temporales de YouTube, no
            // un extractor viejo: mandarlos a EXTRACTOR_OUTDATED hacia que la
            // app pidiera "actualizar el motor de descarga", que no arregla
            // nada. Se busca "not a bot" y no "you're not a bot" porque yt-dlp
            // escribe un apostrofo tipografico (U+2019), no el ASCII.
            text.contains("not a bot") || text.contains("too many requests") ||
                text.contains("http error 429") -> DownloadErrorCode.FETCH_FAILED
            text.contains("unable to download webpage") || text.contains("http error 404") ||
                text.contains("http error 403") -> DownloadErrorCode.FETCH_FAILED
            text.contains("no space left") -> DownloadErrorCode.INSUFFICIENT_STORAGE
            else -> DownloadErrorCode.UNKNOWN
        }
    }

    private const val SOCKET_TIMEOUT_SECONDS = 15
    private const val NETWORK_RETRIES = 1

    /** Nombre con el que youtubedl-android empaqueta el binario de QuickJS. */
    private const val QUICK_JS_LIB_NAME = "libqjs.so"
}
