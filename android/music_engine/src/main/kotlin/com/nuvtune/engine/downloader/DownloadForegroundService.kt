package com.nuvtune.engine.downloader

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.IBinder
import android.os.StatFs
import android.util.Log
import androidx.core.app.NotificationCompat
import com.nuvtune.app.MainActivity
import com.yausername.youtubedl_android.YoutubeDL
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import java.io.File
import java.util.Collections
import java.util.concurrent.atomic.AtomicInteger

/**
 * Sostiene las descargas activas fuera del ciclo de vida de la Activity, con
 * su propia notificacion. Procesa una a la vez y encola el resto; cuando no
 * queda nada pendiente se detiene, en vez de quedar viva de fondo sin
 * trabajo. Portado de C:\Repos\NuvClip: la unica diferencia real es que aqui
 * el resultado siempre es audio (`MediaStoreWriter.saveAudio`, con
 * metadatos de cancion) en vez de video u audio segun el pedido.
 */
class DownloadForegroundService : Service() {

    private class CancelledBeforeExecution : Exception()

    private val job = Job()
    private val scope = CoroutineScope(Dispatchers.IO + job)
    private lateinit var queue: Channel<QueuedDownload>
    private val pendingCount = AtomicInteger(0)

    private data class QueuedDownload(
        val downloadId: String,
        val sourceUrl: String,
        val formatId: String,
        val suggestedFileName: String,
        val wifiOnly: Boolean,
        val approxTotalBytes: Long?,
        val songTitle: String?,
        val songArtist: String?,
        val songAlbum: String?,
    )

    override fun onCreate() {
        super.onCreate()
        YtDlpEngine.initialize(applicationContext)
        createNotificationChannel()
        queue = Channel(Channel.UNLIMITED)
        scope.launch {
            for (item in queue) {
                runDownload(item)
                if (pendingCount.decrementAndGet() == 0) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val extras = intent?.extras ?: return START_NOT_STICKY
        val downloadId = extras.getString(EXTRA_DOWNLOAD_ID) ?: return START_NOT_STICKY

        pendingCount.incrementAndGet()
        startForeground(
            NOTIFICATION_ID,
            buildNotification(extras.getString(EXTRA_FILE_NAME) ?: downloadId, 0, true),
        )

        queue.trySend(
            QueuedDownload(
                downloadId = downloadId,
                sourceUrl = extras.getString(EXTRA_SOURCE_URL)!!,
                formatId = extras.getString(EXTRA_FORMAT_ID)!!,
                suggestedFileName = extras.getString(EXTRA_FILE_NAME)!!,
                wifiOnly = extras.getBoolean(EXTRA_WIFI_ONLY, false),
                approxTotalBytes = extras.getLong(EXTRA_TOTAL_BYTES, -1L).takeIf { it > 0 },
                songTitle = extras.getString(EXTRA_SONG_TITLE),
                songArtist = extras.getString(EXTRA_SONG_ARTIST),
                songAlbum = extras.getString(EXTRA_SONG_ALBUM),
            )
        )
        return START_NOT_STICKY
    }

    private fun runDownload(item: QueuedDownload) {
        if (cancelledIds.remove(item.downloadId)) {
            DownloadEventBus.emitFailed(item.downloadId, DownloadErrorCode.CANCELLED, null)
            return
        }

        if (item.wifiOnly && !isOnWifi()) {
            DownloadEventBus.emitFailed(item.downloadId, DownloadErrorCode.WIFI_REQUIRED, null)
            return
        }

        val outputDir = File(cacheDir, "downloads").apply { mkdirs() }
        if (item.approxTotalBytes != null && item.approxTotalBytes > StatFs(outputDir.path).availableBytes) {
            DownloadEventBus.emitFailed(item.downloadId, DownloadErrorCode.INSUFFICIENT_STORAGE, null)
            return
        }

        val outputTemplate = File(outputDir, "${item.downloadId}.%(ext)s").absolutePath
        updateNotification(item.suggestedFileName, 0, indeterminate = true)

        try {
            val observedVersion = YtDlpEngine.currentVersion(applicationContext)
            var recoveryUsed = false
            while (true) {
                try {
                    executeDownload(item, outputTemplate)
                    break
                } catch (cancelled: YoutubeDL.CanceledException) {
                    throw cancelled
                } catch (cancelled: CancelledBeforeExecution) {
                    throw cancelled
                } catch (error: Exception) {
                    clearTemporaryFiles(outputDir, item.downloadId)
                    val action = YtDlpEngine.recoveryAction(error)
                    if (recoveryUsed || action == YtDlpEngine.RecoveryAction.NONE) throw error
                    recoveryUsed = true

                    val mayReanalyze = when (action) {
                        YtDlpEngine.RecoveryAction.UPDATE_EXTRACTOR ->
                            runCatching {
                                YtDlpEngine.refreshExtractorForRecovery(
                                    context = applicationContext,
                                    observedVersion = observedVersion,
                                    onUpdateStarted = {
                                        Log.i(TAG, "actualizando yt-dlp para recuperar ${item.downloadId}")
                                        updateNotification(
                                            "Actualizando motor de descarga",
                                            0,
                                            indeterminate = true,
                                        )
                                    },
                                )
                            }.getOrElse {
                                Log.w(TAG, "no se pudo recuperar el extractor", it)
                                false
                            }
                        YtDlpEngine.RecoveryAction.REANALYZE -> true
                        YtDlpEngine.RecoveryAction.NONE -> false
                    }
                    if (!mayReanalyze) throw error
                    if (cancelledIds.remove(item.downloadId)) throw CancelledBeforeExecution()

                    // No se reutiliza a ciegas la solicitud fallida: primero
                    // se confirma que el extractor actualizado puede resolver
                    // de nuevo el enlace y sus cookies vigentes.
                    YtDlpEngine.reanalyzeCurrentExtractor(applicationContext, item.sourceUrl)
                    updateNotification(item.suggestedFileName, 0, indeterminate = true)
                    DownloadEventBus.emitProgress(
                        item.downloadId,
                        0.0,
                        null,
                        0L,
                        item.approxTotalBytes,
                    )
                }
            }

            val producedFile = outputDir.listFiles { file ->
                file.nameWithoutExtension == item.downloadId &&
                    file.extension.equals("mp3", ignoreCase = true)
            }?.firstOrNull()
                ?: error("yt-dlp no genero un archivo de salida")

            val savedUri = MediaStoreWriter.saveAudio(
                applicationContext, producedFile, item.suggestedFileName,
                title = item.songTitle, artist = item.songArtist, album = item.songAlbum,
            )
            val sizeBytes = MediaStoreWriter.sizeOf(applicationContext, savedUri)
            producedFile.delete()

            DownloadEventBus.emitCompleted(item.downloadId, savedUri.toString(), item.suggestedFileName, sizeBytes)
        } catch (cancelled: YoutubeDL.CanceledException) {
            cancelledIds.remove(item.downloadId)
            DownloadEventBus.emitFailed(item.downloadId, DownloadErrorCode.CANCELLED, null)
        } catch (cancelled: CancelledBeforeExecution) {
            DownloadEventBus.emitFailed(item.downloadId, DownloadErrorCode.CANCELLED, null)
        } catch (error: Exception) {
            Log.w(TAG, "descarga fallida para ${item.downloadId}", error)
            DownloadEventBus.emitFailed(item.downloadId, YtDlpEngine.classifyError(error), error.message)
        } finally {
            clearTemporaryFiles(outputDir, item.downloadId)
        }
    }

    private fun executeDownload(item: QueuedDownload, outputTemplate: String) {
        val attempts = YtDlpEngine.cookieModesFor(item.sourceUrl)
            .flatMap { includeCookies ->
                // La portada es opcional y se reintenta sin ella si falla el
                // postprocesado. Cookies y portada no se prueban si el fallo
                // pide reanalizar o actualizar el extractor.
                listOf(includeCookies to true, includeCookies to false)
            }
        var lastError: Exception? = null
        for ((attemptIndex, attempt) in attempts.withIndex()) {
            if (cancelledIds.remove(item.downloadId)) throw CancelledBeforeExecution()
            val (includeCookies, embedThumbnail) = attempt
            try {
                var lastEmitAt = 0L
                val request = YtDlpEngine.buildDownloadRequest(
                    item.sourceUrl,
                    item.formatId,
                    outputTemplate,
                    includeYouTubeCookies = includeCookies,
                    embedThumbnail = embedThumbnail,
                )
                YoutubeDL.getInstance().execute(request, item.downloadId) { percent, etaSeconds, _ ->
                    val now = System.currentTimeMillis()
                    if (now - lastEmitAt < PROGRESS_THROTTLE_MS && percent < 100f) return@execute
                    lastEmitAt = now
                    val downloaded = item.approxTotalBytes
                        ?.let { (it * (percent / 100.0)).toLong() }
                        ?: 0L
                    DownloadEventBus.emitProgress(
                        item.downloadId,
                        percent.toDouble(),
                        etaSeconds.takeIf { it > 0 },
                        downloaded,
                        item.approxTotalBytes,
                    )
                    updateNotification(
                        item.suggestedFileName,
                        percent.toInt(),
                        indeterminate = false,
                    )
                }
                return
            } catch (cancelled: YoutubeDL.CanceledException) {
                throw cancelled
            } catch (error: Exception) {
                lastError = error
                clearTemporaryFiles(File(cacheDir, "downloads"), item.downloadId)
                if (YtDlpEngine.recoveryAction(error) != YtDlpEngine.RecoveryAction.NONE) {
                    throw error
                }
                if (attemptIndex < attempts.lastIndex) {
                    Log.i(
                        TAG,
                        "reintentando ${item.downloadId} " +
                            "(cookies=$includeCookies, portada=$embedThumbnail)",
                    )
                    DownloadEventBus.emitProgress(
                        item.downloadId,
                        0.0,
                        null,
                        0L,
                        item.approxTotalBytes,
                    )
                }
            }
        }
        throw checkNotNull(lastError)
    }

    private fun clearTemporaryFiles(outputDir: File, downloadId: String) {
        outputDir.listFiles { file -> file.name.startsWith("$downloadId.") }
            ?.forEach { it.delete() }
    }

    private fun isOnWifi(): Boolean {
        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = manager.activeNetwork ?: return false
        val capabilities = manager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }

    private fun createNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID, "Descargas", NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Progreso de las descargas de NuvTune"
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    private fun updateNotification(fileName: String, progress: Int, indeterminate: Boolean) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification(fileName, progress, indeterminate))
    }

    private fun buildNotification(fileName: String, progress: Int, indeterminate: Boolean): Notification {
        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Descargando cancion")
            .setContentText(fileName)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openApp)
            .setProgress(100, progress, indeterminate)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        job.cancel()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "NuvTune"
        private const val CHANNEL_ID = "nuvtune_downloads"
        private const val NOTIFICATION_ID = 4201
        private const val PROGRESS_THROTTLE_MS = 400L

        const val EXTRA_DOWNLOAD_ID = "downloadId"
        const val EXTRA_SOURCE_URL = "sourceUrl"
        const val EXTRA_FORMAT_ID = "formatId"
        const val EXTRA_FILE_NAME = "fileName"
        const val EXTRA_WIFI_ONLY = "wifiOnly"
        const val EXTRA_TOTAL_BYTES = "totalBytes"
        const val EXTRA_SONG_TITLE = "songTitle"
        const val EXTRA_SONG_ARTIST = "songArtist"
        const val EXTRA_SONG_ALBUM = "songAlbum"

        private val cancelledIds = Collections.newSetFromMap(java.util.concurrent.ConcurrentHashMap<String, Boolean>())

        fun enqueue(context: Context, request: DownloadRequest) {
            val intent = Intent(context, DownloadForegroundService::class.java).apply {
                putExtra(EXTRA_DOWNLOAD_ID, request.downloadId)
                putExtra(EXTRA_SOURCE_URL, request.sourceUrl)
                putExtra(EXTRA_FORMAT_ID, request.formatId)
                putExtra(EXTRA_FILE_NAME, request.suggestedFileName)
                putExtra(EXTRA_WIFI_ONLY, request.wifiOnly)
                request.approxTotalBytes?.let { putExtra(EXTRA_TOTAL_BYTES, it) }
                request.songTitle?.let { putExtra(EXTRA_SONG_TITLE, it) }
                request.songArtist?.let { putExtra(EXTRA_SONG_ARTIST, it) }
                request.songAlbum?.let { putExtra(EXTRA_SONG_ALBUM, it) }
            }
            context.startForegroundService(intent)
        }

        fun cancel(downloadId: String) {
            cancelledIds.add(downloadId)
            YoutubeDL.getInstance().destroyProcessById(downloadId)
        }
    }
}
