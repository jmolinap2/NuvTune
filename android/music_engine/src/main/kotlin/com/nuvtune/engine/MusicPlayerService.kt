package com.nuvtune.engine

import android.app.PendingIntent
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Timeline
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.session.CommandButton
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.nuvtune.app.R

/**
 * Reproductor y sesion multimedia (requerimiento secciones 9.1, 9.2 y 9.3).
 *
 * Extiende MediaLibraryService, que es MediaSessionService mas la biblioteca
 * navegable, de forma que un solo servicio cubre la reproduccion en segundo
 * plano, la notificacion, los botones de auriculares y Android Auto.
 *
 * La reproduccion vive aqui y no en el proceso de la interfaz, asi que continua
 * con la pantalla apagada, al cambiar de aplicacion y cuando el sistema destruye
 * la interfaz de Flutter.
 */
@OptIn(UnstableApi::class)
class MusicPlayerService : MediaLibraryService() {

    private val handler = Handler(Looper.getMainLooper())

    private lateinit var components: EngineComponents.Components
    private lateinit var player: ExoPlayer
    private lateinit var librarySession: MediaLibrarySession
    private lateinit var fadeController: FadeController
    private lateinit var sleepTimer: SleepTimer
    private lateinit var outputMonitor: AudioOutputMonitor

    /**
     * Pausa al desconectar los auriculares y reanudacion opcional al
     * reconectarlos, ambas configurables desde Ajustes > Widgets.
     */
    private val headphoneMonitor by lazy {
        HeadphoneMonitor(
            context = this,
            onPause = { fadeController.pauseWithFade() },
            onResume = { player.play() },
        )
    }

    /** Estado del boton de favorito que dibuja la notificacion. */
    private var currentSongIsFavorite = false

    private val positionTicker = object : Runnable {
        override fun run() {
            if (player.isPlaying) {
                PlaybackStateHolder.publishPosition(
                    positionMs = player.currentPosition,
                    durationMs = player.duration.takeIf { it != C.TIME_UNSET } ?: 0L,
                    bufferedMs = player.bufferedPosition,
                )
            }
            handler.postDelayed(this, POSITION_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        components = EngineComponents.get(this)

        player = buildPlayer()
        applyPlaybackOptions()

        fadeController = FadeController(
            primary = player,
            createSecondary = ::buildPlayer,
            handler = handler,
        )
        fadeController.start()

        sleepTimer = SleepTimer(handler) {
            fadeController.pauseWithFade()
            PlaybackStateHolder.publishSleepTimerFinished()
            publishSnapshot()
        }

        val callback = MusicLibraryCallback(
            library = components.library,
            onAndroidAutoConnectionChanged = { connected ->
                outputMonitor.androidAutoConnected = connected
            },
        )

        librarySession = MediaLibrarySession.Builder(this, player, ServiceCallback(callback))
            .setBitmapLoader(MediaStoreBitmapLoader(components.library))
            .setSessionActivity(launchAppIntent())
            .build()

        val notificationProvider = DefaultMediaNotificationProvider.Builder(this)
            .setChannelId(NOTIFICATION_CHANNEL_ID)
            .setChannelName(R.string.nuvtune_notification_channel_name)
            .build()
        notificationProvider.setSmallIcon(R.drawable.ic_stat_nuvtune)
        setMediaNotificationProvider(notificationProvider)

        updateFavoriteButton()

        player.addListener(PlayerListener())

        outputMonitor = AudioOutputMonitor(this)
        outputMonitor.start { output, name ->
            PlaybackStateHolder.publishAudioOutput(output, name)
        }

        components.library.startObserving {
            // MediaStore cambio por algo externo a la aplicacion. Se relee la
            // biblioteca conservando las carpetas excluidas ya configuradas.
            PlaybackStateHolder.publishLibrary(components.library.currentSongs.size)
        }

        headphoneMonitor.start()

        handler.post(positionTicker)
        instance = this
    }

    private fun buildPlayer(): ExoPlayer =
        ExoPlayer.Builder(this, components.effects.createRenderersFactory())
            .setMediaSourceFactory(buildMediaSourceFactory())
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                // El propio ExoPlayer gestiona el foco de audio: pausa en
                // llamadas, baja el volumen ante notificaciones y no reanuda si
                // el usuario habia pausado a mano (requerimiento seccion 9.3).
                /* handleAudioFocus = */ true,
            )
            // Pausa al desconectar los auriculares.
            // La pausa al desconectar los auriculares la lleva HeadphoneMonitor,
            // porque el usuario puede desactivarla y ademas puede pedir que se
            // reanude al reconectar, cosa que Media3 no ofrece. Dejarlo aqui en
            // true daria dos duenos de la misma decision.
            .setHandleAudioBecomingNoisy(false)
            .setWakeMode(C.WAKE_MODE_LOCAL)
            .build()

    /**
     * Fabrica de fuentes que entiende, ademas de los esquemas nativos de Media3
     * (archivo local, content:// y http/https), el esquema `smb://` de las
     * carpetas compartidas (requerimiento seccion 10).
     *
     * El reparto se hace por esquema: todo lo que no sea SMB sigue exactamente
     * el camino de siempre.
     */
    private fun buildMediaSourceFactory(): DefaultMediaSourceFactory =
        DefaultMediaSourceFactory(
            SchemeAwareDataSource.Factory(
                local = DefaultDataSource.Factory(this),
                smb = SmbDataSource.Factory(
                    components.remoteSources.smbClient(),
                    components.remoteSources::credentialsFor,
                ),
            ),
        )

    /**
     * Traslada las opciones de calidad al reproductor.
     *
     * Sobre gapless: ExoPlayer ya reproduce sin espacios los formatos que
     * declaran su relleno de codificador, sin necesidad de interruptor. Lo que
     * añade esta opcion es el salto del silencio que arrastran los demas
     * formatos en el limite entre pistas, que es la parte configurable.
     */
    private fun applyPlaybackOptions() {
        val options = components.effects.options
        player.skipSilenceEnabled = options.gaplessEnabled
        player.trackSelectionParameters = player.trackSelectionParameters
            .buildUpon()
            .setAudioOffloadPreferences(components.effects.offloadPreferences())
            .build()
        if (::fadeController.isInitialized) {
            fadeController.crossfadeMs = (options.crossfadeSeconds * 1000).toInt()
            fadeController.fadeOnPauseEnabled = options.fadeOnPause
            fadeController.fadeOnPauseMs = options.fadeOnPauseMs.toInt()
        }
    }

    private fun launchAppIntent(): PendingIntent {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(Intent.ACTION_MAIN)
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaLibrarySession =
        librarySession

    /**
     * La musica sigue cuando el usuario retira la aplicacion de recientes; el
     * servicio solo se detiene si no habia nada reproduciendose (requerimiento
     * seccion 9.1).
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        if (!player.playWhenReady || player.mediaItemCount == 0) {
            stopSelf()
        }
    }

    override fun onDestroy() {
        instance = null
        handler.removeCallbacks(positionTicker)
        sleepTimer.cancel()
        fadeController.release()
        outputMonitor.stop()
        headphoneMonitor.stop()
        components.library.stopObserving()
        librarySession.release()
        player.release()
        super.onDestroy()
    }

    // -- Comandos que no caben en MediaController ----------------------------

    /**
     * Ordenes que el plugin envia directamente porque no forman parte del
     * vocabulario de una sesion multimedia. El plugin y el servicio comparten
     * proceso, de modo que esto es una llamada de metodo y no comunicacion entre
     * procesos.
     *
     * Todas necesitan un reproductor vivo. Los ajustes que deben sobrevivir sin
     * servicio (ecualizador y opciones de calidad) se guardan en
     * [AudioEffectsManager], que vive en [EngineComponents], y se aplican al
     * reproductor en [onCreate] y en [onEffectsChanged].
     */
    internal fun handleEngineCommand(command: EngineCommand) {
        when (command) {
            is EngineCommand.SetSleepTimer -> {
                sleepTimer.schedule(command.durationMs, command.finishCurrentTrack)
                publishSnapshot()
            }

            EngineCommand.CancelSleepTimer -> {
                sleepTimer.cancel()
                publishSnapshot()
            }

            EngineCommand.PlayWithFade -> fadeController.playWithFade()
            EngineCommand.PauseWithFade -> fadeController.pauseWithFade()

            is EngineCommand.SetFavoriteState -> {
                currentSongIsFavorite = command.isFavorite
                updateFavoriteButton()
            }
        }
    }

    /**
     * El plugin ya escribio los ajustes nuevos en [AudioEffectsManager]; aqui
     * solo se trasladan al reproductor. [needsReprepare] llega en true cuando el
     * cambio afecta a la composicion de la cadena de audio.
     */
    internal fun onEffectsChanged(needsReprepare: Boolean) {
        applyPlaybackOptions()
        if (needsReprepare) {
            reprepareAtCurrentPosition()
        }
    }

    /**
     * Entrar o salir del modo directo cambia la cadena de audio, y la cadena
     * solo se reconstruye cuando el reproductor vuelve a preparar la pista. Se
     * conserva la posicion para que el cambio sea casi imperceptible.
     */
    private fun reprepareAtCurrentPosition() {
        if (player.mediaItemCount == 0) return
        val index = player.currentMediaItemIndex
        val position = player.currentPosition
        val wasPlaying = player.isPlaying
        player.seekTo(index, position)
        player.prepare()
        if (wasPlaying) {
            player.play()
        }
    }

    private fun updateFavoriteButton() {
        val iconResource = if (currentSongIsFavorite) {
            R.drawable.ic_notification_favorite
        } else {
            R.drawable.ic_notification_favorite_border
        }
        val button = CommandButton.Builder()
            .setDisplayName(if (currentSongIsFavorite) "Quitar de favoritos" else "Favorito")
            .setIconResId(iconResource)
            .setSessionCommand(SessionCommand(COMMAND_TOGGLE_FAVORITE, Bundle.EMPTY))
            .build()
        librarySession.setCustomLayout(ImmutableList.of(button))
    }

    private fun publishSnapshot() {
        PlaybackStateHolder.publishSnapshot(buildSnapshot())
    }

    private fun buildSnapshot(): PlaybackSnapshot {
        val index = player.currentMediaItemIndex.takeIf { player.mediaItemCount > 0 } ?: -1
        val songId = player.currentMediaItem?.mediaId?.toLongOrNull()
        return PlaybackSnapshot(
            isPlaying = player.isPlaying,
            processingState = when (player.playbackState) {
                Player.STATE_BUFFERING -> ProcessingState.BUFFERING
                Player.STATE_READY -> ProcessingState.READY
                Player.STATE_ENDED -> ProcessingState.ENDED
                else -> ProcessingState.IDLE
            },
            positionMs = player.currentPosition,
            durationMs = player.duration.takeIf { it != C.TIME_UNSET } ?: 0L,
            bufferedMs = player.bufferedPosition,
            currentIndex = index.toLong(),
            currentSongId = songId,
            shuffleEnabled = player.shuffleModeEnabled,
            repeatMode = when (player.repeatMode) {
                Player.REPEAT_MODE_ONE -> RepeatMode.ONE
                Player.REPEAT_MODE_ALL -> RepeatMode.ALL
                else -> RepeatMode.OFF
            },
            speed = player.playbackParameters.speed.toDouble(),
            pitch = player.playbackParameters.pitch.toDouble(),
            sleepTimerRemainingMs = sleepTimer.remainingMs(),
        )
    }

    private fun publishQueue() {
        val queue = ArrayList<Song>(player.mediaItemCount)
        for (index in 0 until player.mediaItemCount) {
            val mediaId = player.getMediaItemAt(index).mediaId
            val song = mediaId.toLongOrNull()?.let { components.library.songById(it) }
            if (song != null) {
                queue.add(song)
            }
        }
        val index = player.currentMediaItemIndex.takeIf { player.mediaItemCount > 0 } ?: -1
        PlaybackStateHolder.publishQueue(queue, index)
    }

    private inner class PlayerListener : Player.Listener {

        override fun onEvents(player: Player, events: Player.Events) {
            if (events.containsAny(
                    Player.EVENT_PLAYBACK_STATE_CHANGED,
                    Player.EVENT_IS_PLAYING_CHANGED,
                    Player.EVENT_PLAY_WHEN_READY_CHANGED,
                    Player.EVENT_SHUFFLE_MODE_ENABLED_CHANGED,
                    Player.EVENT_REPEAT_MODE_CHANGED,
                    Player.EVENT_PLAYBACK_PARAMETERS_CHANGED,
                    Player.EVENT_POSITION_DISCONTINUITY,
                )
            ) {
                publishSnapshot()
            }
        }

        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            when (reason) {
                Player.MEDIA_ITEM_TRANSITION_REASON_AUTO,
                Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT,
                -> fadeController.onAutomaticTransition()

                else -> fadeController.onManualTransition()
            }

            // El temporizador con la opcion de terminar la cancion detiene la
            // reproduccion justo en el limite entre pistas.
            if (sleepTimer.shouldStopAfterCurrentTrack()) {
                fadeController.pauseWithFade()
                PlaybackStateHolder.publishSleepTimerFinished()
            }

            PlaybackStateHolder.publishTrack(
                index = player.currentMediaItemIndex,
                songId = mediaItem?.mediaId?.toLongOrNull(),
            )
            publishSnapshot()
        }

        override fun onTimelineChanged(timeline: Timeline, reason: Int) {
            publishQueue()
        }

        override fun onPlayerError(error: PlaybackException) {
            val song = player.currentMediaItem?.mediaId?.toLongOrNull()
                ?.let { components.library.songById(it) }
            val detail = song?.let { "${it.title} (${it.mimeType})" } ?: "la pista actual"
            PlaybackStateHolder.publishError(
                error.errorCodeName,
                "No se pudo reproducir $detail: ${error.localizedMessage ?: error.errorCodeName}",
            )
        }
    }

    /**
     * Envuelve el callback de biblioteca para atender ademas el comando
     * personalizado de favorito.
     */
    private inner class ServiceCallback(
        private val delegate: MusicLibraryCallback,
    ) : MediaLibrarySession.Callback by delegate {

        override fun onConnect(
            session: MediaSession,
            controller: MediaSession.ControllerInfo,
        ): MediaSession.ConnectionResult {
            val base = delegate.onConnect(session, controller)
            return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                .setAvailablePlayerCommands(base.availablePlayerCommands)
                .setAvailableSessionCommands(
                    base.availableSessionCommands
                        .buildUpon()
                        .add(SessionCommand(COMMAND_TOGGLE_FAVORITE, Bundle.EMPTY))
                        .build(),
                )
                .build()
        }

        override fun onCustomCommand(
            session: MediaSession,
            controller: MediaSession.ControllerInfo,
            customCommand: SessionCommand,
            args: Bundle,
        ): ListenableFuture<SessionResult> {
            if (customCommand.customAction != COMMAND_TOGGLE_FAVORITE) {
                return Futures.immediateFuture(
                    SessionResult(SessionResult.RESULT_ERROR_NOT_SUPPORTED),
                )
            }
            val songId = player.currentMediaItem?.mediaId?.toLongOrNull()
                ?: return Futures.immediateFuture(
                    SessionResult(SessionResult.RESULT_ERROR_INVALID_STATE),
                )

            // Los favoritos viven en la base de datos de Flutter: el motor solo
            // traslada la intencion y espera que le devuelvan el estado nuevo.
            PlaybackStateHolder.publishFavoriteToggleRequested(songId)
            return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
        }
    }

    companion object {
        /**
         * Instancia viva del servicio. El plugin la usa para las ordenes que
         * requieren el reproductor; cuando es null no hay nada reproduciendose y
         * esas ordenes no tienen efecto que aplicar.
         */
        @Volatile
        internal var instance: MusicPlayerService? = null
            private set

        const val COMMAND_TOGGLE_FAVORITE = "com.nuvtune.engine.TOGGLE_FAVORITE"
        private const val NOTIFICATION_CHANNEL_ID = "nuvtune_playback"

        /**
         * Media vez por segundo basta para una barra de progreso y mantiene el
         * consumo bajo (requerimiento seccion 17).
         */
        private const val POSITION_INTERVAL_MS = 500L
    }
}

/** Ordenes del plugin al servicio que no son comandos de sesion multimedia. */
internal sealed interface EngineCommand {
    data class SetSleepTimer(val durationMs: Long, val finishCurrentTrack: Boolean) : EngineCommand
    data object CancelSleepTimer : EngineCommand
    data object PlayWithFade : EngineCommand
    data object PauseWithFade : EngineCommand
    data class SetFavoriteState(val songId: Long, val isFavorite: Boolean) : EngineCommand
}
