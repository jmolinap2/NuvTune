package com.nuvtune.engine

/**
 * Estado de reproduccion compartido dentro del proceso.
 *
 * Lo escribe [MusicPlayerService], que es el unico que observa el reproductor, y
 * lo leen [FlutterMusicPlugin] para emitir los eventos del contrato y
 * [NuvTuneWidgetProvider] para pintar el widget. Asi el estado se calcula en un
 * solo sitio aunque lo consuman varios destinos.
 *
 * Todo el acceso ocurre en el hilo principal.
 */
internal object PlaybackStateHolder {

    interface Listener {
        fun onSnapshot(snapshot: PlaybackSnapshot) {}
        /// El indice no viaja aqui: lo lleva [onSnapshot], que es su unica
        /// fuente hacia Flutter.
        fun onQueue(queue: List<Song>) {}
        fun onTrack(index: Int, songId: Long?) {}
        fun onPosition(positionMs: Long, durationMs: Long, bufferedMs: Long) {}
        fun onAudioOutput(output: AudioOutput, deviceName: String) {}
        fun onLibrary(songCount: Int) {}
        fun onMetadata(song: Song) {}
        fun onSleepTimerFinished() {}
        fun onFavoriteToggleRequested(songId: Long) {}
        fun onError(code: String, message: String) {}
    }

    private val listeners = mutableListOf<Listener>()

    var snapshot: PlaybackSnapshot = emptySnapshot()
        private set

    var queue: List<Song> = emptyList()
        private set

    var currentIndex: Int = -1
        private set

    var audioOutput: AudioOutput = AudioOutput.SPEAKER
        private set

    var audioOutputName: String = "Altavoz del telefono"
        private set

    fun addListener(listener: Listener) {
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    val currentSong: Song? get() = queue.getOrNull(currentIndex)

    /** Siguiente pista de la cola, para el widget de inicio (seccion 9.2). */
    val nextSong: Song? get() = queue.getOrNull(currentIndex + 1)

    fun publishSnapshot(value: PlaybackSnapshot) {
        snapshot = value
        forEachListener { it.onSnapshot(value) }
    }

    /// [index] alimenta [currentSong] y [nextSong], que el widget de inicio lee
    /// dentro de este mismo proceso; hacia Flutter no sale, para no duplicar la
    /// autoridad del indice.
    fun publishQueue(value: List<Song>, index: Int) {
        queue = value
        currentIndex = index
        forEachListener { it.onQueue(value) }
    }

    fun publishTrack(index: Int, songId: Long?) {
        currentIndex = index
        forEachListener { it.onTrack(index, songId) }
    }

    fun publishPosition(positionMs: Long, durationMs: Long, bufferedMs: Long) {
        forEachListener { it.onPosition(positionMs, durationMs, bufferedMs) }
    }

    fun publishAudioOutput(output: AudioOutput, deviceName: String) {
        audioOutput = output
        audioOutputName = deviceName
        forEachListener { it.onAudioOutput(output, deviceName) }
    }

    fun publishLibrary(songCount: Int) {
        forEachListener { it.onLibrary(songCount) }
    }

    fun publishMetadata(song: Song) {
        queue = queue.map { if (it.id == song.id) song else it }
        forEachListener { it.onMetadata(song) }
    }

    fun publishSleepTimerFinished() {
        forEachListener { it.onSleepTimerFinished() }
    }

    fun publishFavoriteToggleRequested(songId: Long) {
        forEachListener { it.onFavoriteToggleRequested(songId) }
    }

    fun publishError(code: String, message: String) {
        forEachListener { it.onError(code, message) }
    }

    /**
     * Se itera sobre una copia porque un oyente puede darse de baja durante la
     * entrega, por ejemplo cuando Flutter se destruye al girar la pantalla.
     */
    private inline fun forEachListener(action: (Listener) -> Unit) {
        for (listener in listeners.toList()) {
            action(listener)
        }
    }

    fun emptySnapshot() = PlaybackSnapshot(
        isPlaying = false,
        processingState = ProcessingState.IDLE,
        positionMs = 0,
        durationMs = 0,
        bufferedMs = 0,
        currentIndex = -1,
        currentSongId = null,
        shuffleEnabled = false,
        repeatMode = RepeatMode.OFF,
        speed = 1.0,
        pitch = 1.0,
        sleepTimerRemainingMs = null,
    )
}
