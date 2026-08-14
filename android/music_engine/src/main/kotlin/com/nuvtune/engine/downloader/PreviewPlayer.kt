package com.nuvtune.engine.downloader

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Reproduce la vista previa de un resultado de busqueda antes de descargarlo.
 *
 * Deliberadamente NO usa el reproductor principal ([MusicPlayerService]): oir
 * un resultado para decidir si es la cancion correcta no debe reemplazar la
 * cola del usuario ni aparecer en su historial. Es una instancia aparte, que
 * se crea al primer uso y se libera al parar.
 *
 * Pide foco de audio (`handleAudioFocus = true`), de modo que si habia musica
 * sonando el sistema la pausa mientras dura la vista previa y la reanuda al
 * terminar, sin que ninguno de los dos reproductores tenga que conocer al
 * otro.
 */
@OptIn(UnstableApi::class)
internal class PreviewPlayer(private val context: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var player: ExoPlayer? = null
    private val autoStop = Runnable { releasePlayer() }

    /**
     * No retorna hasta que Media3 realmente puede reproducir. Antes el canal
     * respondia apenas publicaba una tarea al hilo principal: la interfaz
     * cambiaba a "detener" aunque el stream hubiera fallado en silencio.
     */
    suspend fun play(streamUrl: String) = withContext(Dispatchers.Main.immediate) {
        suspendCancellableCoroutine { continuation ->
            mainHandler.removeCallbacks(autoStop)
            val active = player ?: ExoPlayer.Builder(context)
                .setMediaSourceFactory(
                    DefaultMediaSourceFactory(context).setDataSourceFactory(
                        DefaultHttpDataSource.Factory()
                            .setAllowCrossProtocolRedirects(true)
                            .setConnectTimeoutMs(PREVIEW_HTTP_TIMEOUT_MS)
                            .setReadTimeoutMs(PREVIEW_HTTP_TIMEOUT_MS)
                            .setUserAgent(BROWSER_USER_AGENT)
                            // yt-dlp entrega una URL de Googlevideo de corta
                            // vida. Ese CDN puede exigir el mismo origen de
                            // YouTube que usó el extractor; HttpURLConnection
                            // no lo añade por sí solo.
                            .setDefaultRequestProperties(
                                mapOf(
                                    "Referer" to "https://www.youtube.com/",
                                    "Origin" to "https://www.youtube.com/",
                                ),
                            ),
                    ),
                )
                .build()
                .also { created ->
                    created.setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                            .setUsage(C.USAGE_MEDIA)
                            .build(),
                        /* handleAudioFocus = */ true,
                    )
                    player = created
                }
            val listener = object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    if (playbackState != Player.STATE_READY || !continuation.isActive) return
                    active.removeListener(this)
                    mainHandler.postDelayed(autoStop, PREVIEW_LIMIT_MS)
                    continuation.resume(Unit)
                }

                override fun onPlayerError(error: PlaybackException) {
                    if (!continuation.isActive) return
                    active.removeListener(this)
                    releasePlayer()
                    continuation.resumeWithException(error)
                }
            }
            active.addListener(listener)
            continuation.invokeOnCancellation {
                mainHandler.post {
                    active.removeListener(listener)
                    releasePlayer()
                }
            }
            active.setMediaItem(MediaItem.fromUri(streamUrl))
            active.prepare()
            active.playWhenReady = true
        }
    }

    fun stop() {
        mainHandler.post {
            releasePlayer()
        }
    }

    private fun releasePlayer() {
        mainHandler.removeCallbacks(autoStop)
        player?.release()
        player = null
    }

    companion object {
        private const val PREVIEW_LIMIT_MS = 45_000L
        private const val PREVIEW_HTTP_TIMEOUT_MS = 10_000
        private const val BROWSER_USER_AGENT =
            "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36"
    }
}
