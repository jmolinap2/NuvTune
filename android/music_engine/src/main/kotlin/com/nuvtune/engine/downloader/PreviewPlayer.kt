package com.nuvtune.engine.downloader

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer

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

    /** Debe llamarse desde el hilo principal: ExoPlayer lo exige. */
    fun play(streamUrl: String) {
        mainHandler.post {
            val active = player ?: ExoPlayer.Builder(context)
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
            active.setMediaItem(MediaItem.fromUri(streamUrl))
            active.prepare()
            active.play()
        }
    }

    fun stop() {
        mainHandler.post {
            player?.release()
            player = null
        }
    }
}
