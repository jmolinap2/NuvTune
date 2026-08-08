package com.nuvtune.engine

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.MoreExecutors
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Implementacion del contrato tipado del requerimiento seccion 15.
 *
 * Reparte cada llamada en tres destinos:
 *  - Los comandos de reproduccion van por [MediaController] a la sesion
 *    multimedia, que es lo que arranca [MusicPlayerService] y lo mantiene vivo.
 *  - Los ajustes de audio se escriben en [AudioEffectsManager], compartido por
 *    todo el proceso, y se avisa al servicio para que los traslade al
 *    reproductor.
 *  - La biblioteca, los metadatos y el almacenamiento se atienden aqui mismo,
 *    porque no dependen de que haya reproduccion en curso.
 */
@OptIn(UnstableApi::class)
internal class FlutterMusicPlugin(
    private val context: Context,
    private val messenger: BinaryMessenger,
) : MusicEngineHostApi, PlaybackStateHolder.Listener {

    /** La actividad solo existe mientras la interfaz esta viva. */
    var activity: Activity? = null

    private val flutterApi = MusicEngineFlutterApi(messenger)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val components = EngineComponents.get(context)
    private val outputProbe = AudioOutputMonitor(context)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var controller: MediaController? = null
    private val pendingActivityResults =
        HashMap<Int, CompletableDeferred<Pair<Int, Intent?>>>()
    private val giftPackager by lazy { GiftPackager(context, components.library) }

    fun attach() {
        MusicEngineHostApi.setUp(messenger, this)
        PlaybackStateHolder.addListener(this)
        components.effects.setAnalysisListener { frame ->
            mainHandler.post { flutterApi.audioAnalysisChanged(frame) {} }
        }
    }

    fun detach() {
        MusicEngineHostApi.setUp(messenger, null)
        PlaybackStateHolder.removeListener(this)
        components.effects.setAnalysisEnabled(false)
        components.effects.setAnalysisListener(null)
        controller?.release()
        controller = null
        scope.cancel()
    }

    /** Lo llama MainActivity; devuelve true si el resultado era para el motor. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val pending = pendingActivityResults.remove(requestCode) ?: return false
        pending.complete(resultCode to data)
        return true
    }

    // -- Inicializacion ------------------------------------------------------

    override fun initialize(callback: (Result<Unit>) -> Unit) {
        if (controller != null) {
            callback(Result.success(Unit))
            return
        }
        val token = SessionToken(
            context,
            ComponentName(context, MusicPlayerService::class.java),
        )
        val future = MediaController.Builder(context, token).buildAsync()
        future.addListener(
            {
                controller = future.get()
                callback(Result.success(Unit))
            },
            MoreExecutors.directExecutor(),
        )
    }

    // -- Biblioteca ----------------------------------------------------------

    override fun scanLibrary(
        excludedFolderPaths: List<String>,
        forceFullRescan: Boolean,
        callback: (Result<Long>) -> Unit,
    ) {
        scope.launch {
            val songs = components.library.scan(excludedFolderPaths, forceFullRescan)
            flutterApi.libraryChanged(songs.size.toLong()) {}
            callback(Result.success(songs.size.toLong()))
        }
    }

    override fun getSongs(callback: (Result<List<Song>>) -> Unit) {
        callback(Result.success(components.library.currentSongs))
    }

    override fun rescanFile(filePath: String, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            withContext(Dispatchers.IO) { components.library.requestRescan(filePath) }
            callback(Result.success(Unit))
        }
    }

    override fun getTechnicalInfo(songId: Long, callback: (Result<TechnicalInfo>) -> Unit) {
        scope.launch {
            val info = withContext(Dispatchers.IO) { components.library.technicalInfo(songId) }
            if (info == null) {
                callback(Result.failure(IllegalArgumentException("Cancion $songId no encontrada")))
            } else {
                callback(Result.success(info))
            }
        }
    }

    override fun getCover(songId: Long, size: Long, callback: (Result<CoverImage?>) -> Unit) {
        scope.launch {
            val cover = withContext(Dispatchers.IO) {
                components.library.loadThumbnailBytes(songId, size.toInt())
            }
            callback(Result.success(cover))
        }
    }

    // -- Cola y reproduccion -------------------------------------------------

    override fun setQueue(
        songs: List<Song>,
        startIndex: Long,
        positionMs: Long,
        startPlaying: Boolean,
    ) {
        val target = controller ?: return
        val items = songs.map { MediaItemFactory.toMediaItem(it) }
        target.setMediaItems(items, startIndex.toInt(), positionMs)
        target.prepare()
        if (startPlaying) {
            target.play()
        }
    }

    override fun addToQueueNext(songs: List<Song>) {
        val target = controller ?: return
        val insertAt = (target.currentMediaItemIndex + 1).coerceAtMost(target.mediaItemCount)
        target.addMediaItems(insertAt, songs.map { MediaItemFactory.toMediaItem(it) })
    }

    override fun addToQueueEnd(songs: List<Song>) {
        controller?.addMediaItems(songs.map { MediaItemFactory.toMediaItem(it) })
    }

    override fun removeQueueItem(index: Long) {
        controller?.removeMediaItem(index.toInt())
    }

    override fun moveQueueItem(fromIndex: Long, toIndex: Long) {
        controller?.moveMediaItem(fromIndex.toInt(), toIndex.toInt())
    }

    override fun clearQueue() {
        controller?.clearMediaItems()
    }

    override fun playQueueIndex(index: Long) {
        val target = controller ?: return
        target.seekTo(index.toInt(), 0)
        target.play()
    }

    /**
     * El fundido al reanudar necesita manipular el volumen del reproductor, algo
     * que MediaController no expone. Cuando el servicio esta vivo la orden va por
     * ahi; si no lo esta, no hay volumen que atenuar.
     */
    override fun play() {
        val service = MusicPlayerService.instance
        if (service != null) {
            service.handleEngineCommand(EngineCommand.PlayWithFade)
        } else {
            controller?.play()
        }
    }

    override fun pause() {
        val service = MusicPlayerService.instance
        if (service != null) {
            service.handleEngineCommand(EngineCommand.PauseWithFade)
        } else {
            controller?.pause()
        }
    }

    override fun stop() {
        controller?.stop()
    }

    override fun seek(positionMs: Long) {
        controller?.seekTo(positionMs)
    }

    override fun seekRelative(deltaMs: Long) {
        val target = controller ?: return
        val duration = target.duration
        val destination = (target.currentPosition + deltaMs).coerceAtLeast(0)
        target.seekTo(if (duration > 0) destination.coerceAtMost(duration) else destination)
    }

    override fun skipNext() {
        controller?.seekToNextMediaItem()
    }

    override fun skipPrevious() {
        controller?.seekToPreviousMediaItem()
    }

    override fun setShuffle(enabled: Boolean) {
        controller?.shuffleModeEnabled = enabled
    }

    override fun setRepeatMode(mode: RepeatMode) {
        controller?.repeatMode = when (mode) {
            RepeatMode.OFF -> Player.REPEAT_MODE_OFF
            RepeatMode.ONE -> Player.REPEAT_MODE_ONE
            RepeatMode.ALL -> Player.REPEAT_MODE_ALL
        }
    }

    override fun setPlaybackSpeed(speed: Double) {
        val target = controller ?: return
        target.playbackParameters =
            PlaybackParameters(speed.toFloat(), target.playbackParameters.pitch)
    }

    override fun setPitch(pitch: Double) {
        val target = controller ?: return
        target.playbackParameters =
            PlaybackParameters(target.playbackParameters.speed, pitch.toFloat())
    }

    override fun setAudioAnalysisEnabled(enabled: Boolean) {
        components.effects.setAnalysisEnabled(enabled)
    }

    override fun getPlaybackSnapshot(callback: (Result<PlaybackSnapshot>) -> Unit) {
        callback(Result.success(PlaybackStateHolder.snapshot))
    }

    override fun setFavoriteState(songId: Long, isFavorite: Boolean) {
        MusicPlayerService.instance?.handleEngineCommand(
            EngineCommand.SetFavoriteState(songId, isFavorite),
        )
    }

    // -- Temporizador --------------------------------------------------------

    override fun setSleepTimer(durationMs: Long, finishCurrentTrack: Boolean) {
        MusicPlayerService.instance?.handleEngineCommand(
            EngineCommand.SetSleepTimer(durationMs, finishCurrentTrack),
        )
    }

    override fun cancelSleepTimer() {
        MusicPlayerService.instance?.handleEngineCommand(EngineCommand.CancelSleepTimer)
    }

    // -- Efectos y calidad ---------------------------------------------------

    override fun setEqualizer(settings: EqualizerSettings) {
        components.effects.applyEqualizer(settings)
        MusicPlayerService.instance?.onEffectsChanged(needsReprepare = false)
    }

    override fun setPlaybackOptions(options: PlaybackOptions) {
        val needsReprepare = components.effects.applyOptions(options)
        MusicPlayerService.instance?.onEffectsChanged(needsReprepare)
    }

    override fun getEqualizerBands(bandCount: Long, callback: (Result<EqualizerBands>) -> Unit) {
        val count = bandCount.toInt()
        if (!EqualizerAudioProcessor.isSupportedBandCount(count)) {
            callback(
                Result.failure(
                    IllegalArgumentException("El motor admite 10, 15 o 20 bandas, no $count"),
                ),
            )
            return
        }
        callback(
            Result.success(
                EqualizerBands(
                    centerFrequenciesHz = EqualizerAudioProcessor.centerFrequencies(count).toList(),
                    minGainDb = EqualizerAudioProcessor.MIN_GAIN_DB,
                    maxGainDb = EqualizerAudioProcessor.MAX_GAIN_DB,
                ),
            ),
        )
    }

    override fun getCurrentAudioOutput(callback: (Result<AudioOutput>) -> Unit) {
        callback(Result.success(outputProbe.resolveCurrentOutput().first))
    }

    // -- Mejora de audio -----------------------------------------------------

    override fun setEnhancement(settings: EnhancementSettings) {
        // Un perfil distinto de "personalizado" define los parametros de la
        // cadena; se resuelven aqui para que Flutter no tenga que duplicar la
        // tabla de perfiles.
        val resolved = if (settings.profile == EnhancementProfile.CUSTOM) {
            settings
        } else {
            EnhancementPresets.apply(settings.profile, settings)
        }
        components.effects.applyEnhancement(resolved)
        MusicPlayerService.instance?.onEffectsChanged(needsReprepare = false)
    }

    override fun analyzeLoudness(songId: Long, callback: (Result<LoudnessAnalysis>) -> Unit) {
        scope.launch {
            val result = withContext(Dispatchers.IO) {
                val song = components.library.songById(songId)
                    ?: return@withContext LoudnessAnalysis(songId, 0.0, 0.0)
                runCatching {
                    components.loudnessAnalyzer.analyze(songId, Uri.parse(song.uri))
                }.getOrElse { LoudnessAnalysis(songId, 0.0, 0.0) }
            }
            callback(Result.success(result))
        }
    }

    // -- Widget de inicio ----------------------------------------------------

    override fun setWidgetConfig(config: WidgetConfig) {
        WidgetConfigStore.save(context, config)
        NuvTuneWidgetProvider.refreshAll(context)
    }

    override fun countPlacedWidgets(callback: (Result<Long>) -> Unit) {
        callback(Result.success(NuvTuneWidgetProvider.placedCount(context).toLong()))
    }

    // -- Fuentes remotas -----------------------------------------------------

    override fun listRemoteSources(callback: (Result<List<RemoteSource>>) -> Unit) {
        scope.launch {
            val sources = withContext(Dispatchers.IO) { components.remoteSources.list() }
            callback(Result.success(sources))
        }
    }

    override fun addRemoteSource(
        kind: RemoteSourceKind,
        name: String,
        uri: String,
        username: String?,
        password: String?,
        callback: (Result<RemoteSource>) -> Unit,
    ) {
        scope.launch {
            val source = withContext(Dispatchers.IO) {
                components.remoteSources.add(kind, name, uri, username, password)
            }
            callback(Result.success(source))
        }
    }

    override fun removeRemoteSource(sourceId: Long, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            withContext(Dispatchers.IO) { components.remoteSources.remove(sourceId) }
            callback(Result.success(Unit))
        }
    }

    override fun browseRemoteSource(
        sourceId: Long,
        path: String,
        callback: (Result<List<RemoteEntry>>) -> Unit,
    ) {
        scope.launch {
            val result = withContext(Dispatchers.IO) {
                runCatching { components.remoteSources.browse(sourceId, path) }
            }
            result.fold(
                onSuccess = { callback(Result.success(it)) },
                onFailure = { callback(Result.failure(it)) },
            )
        }
    }

    override fun resolveRemoteSongs(
        sourceId: Long,
        uris: List<String>,
        callback: (Result<List<Song>>) -> Unit,
    ) {
        scope.launch {
            val songs = withContext(Dispatchers.IO) {
                components.remoteSources.resolveSongs(sourceId, uris)
            }
            callback(Result.success(songs))
        }
    }

    override fun loadRemotePlaylist(url: String, callback: (Result<List<Song>>) -> Unit) {
        scope.launch {
            val result = withContext(Dispatchers.IO) {
                runCatching { components.remoteSources.loadRemotePlaylist(url) }
            }
            result.fold(
                onSuccess = { callback(Result.success(it)) },
                onFailure = { callback(Result.failure(it)) },
            )
        }
    }

    // -- Letras por internet -------------------------------------------------

    override fun fetchLyricsOnline(
        title: String,
        artist: String,
        album: String,
        durationMs: Long,
        callback: (Result<String?>) -> Unit,
    ) {
        scope.launch {
            val lyrics = withContext(Dispatchers.IO) {
                runCatching { OnlineLyrics.fetch(title, artist, album, durationMs) }
                    .getOrNull()
            }
            callback(Result.success(lyrics))
        }
    }

    // -- Metadatos y portada -------------------------------------------------

    override fun editMetadata(edit: MetadataEdit, callback: (Result<WriteResult>) -> Unit) {
        scope.launch {
            callback(Result.success(runWrite(edit.songId) {
                components.metadataEditor.writeTags(edit)
            }))
        }
    }

    override fun editMetadataBatch(
        edits: List<MetadataEdit>,
        callback: (Result<List<WriteResult>>) -> Unit,
    ) {
        scope.launch {
            // Se procesan de una en una: cada escritura crea una copia de
            // trabajo del tamano del archivo y hacerlas en paralelo llenaria la
            // cache del dispositivo.
            val results = edits.map { edit ->
                runWrite(edit.songId) { components.metadataEditor.writeTags(edit) }
            }
            callback(Result.success(results))
        }
    }

    override fun setCoverArt(
        songId: Long,
        imageBytes: ByteArray,
        mimeType: String,
        callback: (Result<WriteResult>) -> Unit,
    ) {
        scope.launch {
            callback(Result.success(writeCover(songId, imageBytes, mimeType)))
        }
    }

    override fun setCoverArtBatch(
        songIds: List<Long>,
        imageBytes: ByteArray,
        mimeType: String,
        callback: (Result<List<WriteResult>>) -> Unit,
    ) {
        scope.launch {
            val results = songIds.map { writeCover(it, imageBytes, mimeType) }
            callback(Result.success(results))
        }
    }

    override fun removeCoverArt(songId: Long, callback: (Result<WriteResult>) -> Unit) {
        scope.launch {
            callback(Result.success(runWrite(songId) {
                components.metadataEditor.removeCover(songId)
            }))
        }
    }

    override fun getEmbeddedCover(songId: Long, callback: (Result<ByteArray?>) -> Unit) {
        scope.launch {
            val bytes = withContext(Dispatchers.IO) {
                components.metadataEditor.readEmbeddedCover(songId)
            }
            callback(Result.success(bytes))
        }
    }

    private suspend fun writeCover(
        songId: Long,
        imageBytes: ByteArray,
        mimeType: String,
    ): WriteResult {
        val validation = withContext(Dispatchers.Default) {
            components.coverArtEditor.validate(imageBytes, mimeType)
        }
        return when (validation) {
            is CoverArtEditor.Validation.Invalid -> WriteResult(
                outcome = WriteOutcome.UNSUPPORTED_FORMAT,
                songId = songId,
                message = validation.reason,
                permissionGranted = true,
            )

            is CoverArtEditor.Validation.Valid -> runWrite(songId) {
                components.metadataEditor.writeCover(
                    songId,
                    validation.bytes,
                    validation.mimeType,
                )
            }
        }
    }

    /**
     * Ejecuta una escritura y, si el sistema pide confirmacion del usuario,
     * muestra el dialogo y repite la operacion una sola vez
     * (requerimiento seccion 16).
     */
    private suspend fun runWrite(
        songId: Long,
        operation: suspend () -> EditResult,
    ): WriteResult {
        when (val first = operation()) {
            is EditResult.Done -> return finishWrite(songId, first)

            is EditResult.NeedsConsent -> {
                val granted = requestUserConsent(first.intentSender)
                if (!granted) {
                    return WriteResult(
                        outcome = WriteOutcome.DENIED_BY_USER,
                        songId = songId,
                        message = "El usuario no autorizo modificar el archivo",
                        permissionGranted = false,
                    )
                }
                return when (val retry = operation()) {
                    is EditResult.Done -> finishWrite(songId, retry)
                    is EditResult.NeedsConsent -> WriteResult(
                        outcome = WriteOutcome.NEEDS_USER_CONSENT,
                        songId = songId,
                        message = "El sistema sigue exigiendo confirmacion para este archivo",
                        permissionGranted = false,
                    )
                }
            }
        }
    }

    private fun finishWrite(songId: Long, result: EditResult.Done): WriteResult {
        if (result.outcome == WriteOutcome.SUCCESS) {
            val refreshed = components.library.refreshSong(songId)
            if (refreshed != null) {
                PlaybackStateHolder.publishMetadata(refreshed)
            }
        }
        return WriteResult(
            outcome = result.outcome,
            songId = songId,
            message = result.message,
            permissionGranted = true,
        )
    }

    private suspend fun requestUserConsent(intentSender: IntentSender): Boolean {
        val (resultCode, _) = awaitActivityResult(REQUEST_WRITE_CONSENT) { host ->
            host.startIntentSenderForResult(intentSender, REQUEST_WRITE_CONSENT, null, 0, 0, 0)
        } ?: return false
        return resultCode == Activity.RESULT_OK
    }

    // -- Letras --------------------------------------------------------------

    override fun getLyrics(songId: Long, callback: (Result<LyricsPayload>) -> Unit) {
        scope.launch {
            val payload = withContext(Dispatchers.IO) { components.lyricsReader.read(songId) }
            callback(Result.success(payload))
        }
    }

    override fun saveLrcFile(
        songId: Long,
        lrcContent: String,
        callback: (Result<String>) -> Unit,
    ) {
        scope.launch {
            val path = withContext(Dispatchers.IO) {
                components.lyricsReader.saveLrc(songId, lrcContent)
            }
            callback(Result.success(path))
        }
    }

    // -- Almacenamiento ------------------------------------------------------

    override fun pickFolder(callback: (Result<GrantedFolder?>) -> Unit) {
        scope.launch {
            val outcome = awaitActivityResult(REQUEST_PICK_FOLDER) { host ->
                host.startActivityForResult(
                    components.safManager.openFolderIntent(),
                    REQUEST_PICK_FOLDER,
                )
            }
            val treeUri = outcome?.takeIf { it.first == Activity.RESULT_OK }?.second?.data
            if (treeUri == null) {
                callback(Result.success(null))
                return@launch
            }
            components.safManager.persistFolderPermission(treeUri)
            callback(Result.success(components.safManager.folderInfo(treeUri)))
        }
    }

    override fun getGrantedFolders(callback: (Result<List<GrantedFolder>>) -> Unit) {
        callback(Result.success(components.safManager.grantedFolders()))
    }

    override fun releaseFolder(uri: String, callback: (Result<Unit>) -> Unit) {
        components.safManager.releaseFolderPermission(Uri.parse(uri))
        callback(Result.success(Unit))
    }

    override fun pickDocument(
        mimeTypes: List<String>,
        callback: (Result<PickedDocument?>) -> Unit,
    ) {
        scope.launch {
            val outcome = awaitActivityResult(REQUEST_PICK_DOCUMENT) { host ->
                host.startActivityForResult(
                    components.safManager.openDocumentIntent(mimeTypes),
                    REQUEST_PICK_DOCUMENT,
                )
            }
            val documentUri = outcome?.takeIf { it.first == Activity.RESULT_OK }?.second?.data
            if (documentUri == null) {
                callback(Result.success(null))
                return@launch
            }
            callback(
                Result.success(
                    PickedDocument(
                        uri = documentUri.toString(),
                        name = components.safManager.documentName(documentUri)
                            ?: documentUri.lastPathSegment.orEmpty(),
                        mimeType = components.safManager.documentMimeType(documentUri),
                    ),
                ),
            )
        }
    }

    override fun readDocumentText(uri: String, callback: (Result<String>) -> Unit) {
        scope.launch {
            val text = withContext(Dispatchers.IO) {
                components.safManager.readText(Uri.parse(uri))
            }
            callback(Result.success(text))
        }
    }

    override fun readDocumentBytes(uri: String, callback: (Result<ByteArray>) -> Unit) {
        scope.launch {
            val bytes = withContext(Dispatchers.IO) {
                components.safManager.readBytes(Uri.parse(uri))
            }
            callback(Result.success(bytes))
        }
    }

    override fun createTextDocument(
        suggestedName: String,
        mimeType: String,
        content: String,
        callback: (Result<String?>) -> Unit,
    ) {
        scope.launch {
            val outcome = awaitActivityResult(REQUEST_CREATE_DOCUMENT) { host ->
                host.startActivityForResult(
                    components.safManager.createDocumentIntent(suggestedName, mimeType),
                    REQUEST_CREATE_DOCUMENT,
                )
            }
            val documentUri = outcome?.takeIf { it.first == Activity.RESULT_OK }?.second?.data
            if (documentUri == null) {
                callback(Result.success(null))
                return@launch
            }
            withContext(Dispatchers.IO) {
                components.safManager.writeText(documentUri, content)
            }
            callback(Result.success(documentUri.toString()))
        }
    }

    override fun getClipboardImage(callback: (Result<ByteArray?>) -> Unit) {
        scope.launch {
            val bytes = withContext(Dispatchers.IO) {
                components.coverArtEditor.clipboardImage()
            }
            callback(Result.success(bytes))
        }
    }

    override fun shareSongs(songIds: List<Long>, callback: (Result<Unit>) -> Unit) {
        components.shareHelper.shareSongs(songIds)
        callback(Result.success(Unit))
    }

    override fun shareText(subject: String, text: String, callback: (Result<Unit>) -> Unit) {
        components.shareHelper.shareText(subject, text)
        callback(Result.success(Unit))
    }

    override fun revealFile(songId: Long, callback: (Result<Unit>) -> Unit) {
        components.shareHelper.revealFile(songId)
        callback(Result.success(Unit))
    }

    override fun deleteSongFile(songId: Long, callback: (Result<WriteResult>) -> Unit) {
        scope.launch {
            val intentSender = components.shareHelper.deleteRequest(listOf(songId))
            if (intentSender == null) {
                callback(
                    Result.success(
                        WriteResult(
                            outcome = WriteOutcome.UNSUPPORTED_FORMAT,
                            songId = songId,
                            message = "La cancion ya no esta en la biblioteca",
                            permissionGranted = true,
                        ),
                    ),
                )
                return@launch
            }
            val outcome = awaitActivityResult(REQUEST_DELETE_FILE) { host ->
                host.startIntentSenderForResult(
                    intentSender,
                    REQUEST_DELETE_FILE,
                    null,
                    0,
                    0,
                    0,
                )
            }
            val accepted = outcome?.first == Activity.RESULT_OK
            callback(
                Result.success(
                    WriteResult(
                        outcome = if (accepted) {
                            WriteOutcome.SUCCESS
                        } else {
                            WriteOutcome.DENIED_BY_USER
                        },
                        songId = songId,
                        message = if (accepted) null else "El usuario cancelo la eliminacion",
                        permissionGranted = accepted,
                    ),
                ),
            )
        }
    }

    // -- Regalos --------------------------------------------------------------

    override fun createGiftPackage(
        suggestedFileName: String,
        metadataJson: String,
        songIds: List<Long>,
        callback: (Result<String>) -> Unit,
    ) {
        scope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) {
                    giftPackager.create(suggestedFileName, metadataJson, songIds)
                }
            }
            callback(result)
        }
    }

    override fun readGiftPackage(uri: String, callback: (Result<GiftPackage>) -> Unit) {
        scope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) { giftPackager.read(uri) }
            }
            callback(result)
        }
    }

    override fun importGiftAudio(uri: String, callback: (Result<Long>) -> Unit) {
        scope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) { giftPackager.importAudio(uri) }
            }
            callback(result)
        }
    }

    // -- Registro de fallos de reproduccion ------------------------------------

    override fun readPlaybackFailureLog(callback: (Result<String>) -> Unit) {
        scope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) { PlaybackFailureLog.readAllAsJson() }
            }
            callback(result)
        }
    }

    override fun clearPlaybackFailureLog(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) { PlaybackFailureLog.clear() }
            }
            callback(result)
        }
    }

    /**
     * Lanza una accion que necesita actividad y espera su resultado. Devuelve
     * null si la interfaz no esta viva, situacion en la que no hay ninguna
     * pantalla donde mostrar el dialogo del sistema.
     */
    private suspend fun awaitActivityResult(
        requestCode: Int,
        launch: (Activity) -> Unit,
    ): Pair<Int, Intent?>? {
        val host = activity ?: return null
        val deferred = CompletableDeferred<Pair<Int, Intent?>>()
        pendingActivityResults[requestCode] = deferred
        launch(host)
        return deferred.await()
    }

    // -- Eventos hacia Flutter -----------------------------------------------

    override fun onSnapshot(snapshot: PlaybackSnapshot) {
        flutterApi.playbackStateChanged(snapshot) {}
        NuvTuneWidgetProvider.refreshAll(context)
    }

    override fun onQueue(queue: List<Song>, currentIndex: Int) {
        flutterApi.queueChanged(queue, currentIndex.toLong()) {}
    }

    override fun onTrack(index: Int, songId: Long?) {
        flutterApi.currentTrackChanged(index.toLong(), songId) {}
        NuvTuneWidgetProvider.refreshAll(context)
    }

    override fun onPosition(positionMs: Long, durationMs: Long, bufferedMs: Long) {
        flutterApi.positionChanged(positionMs, durationMs, bufferedMs) {}
    }

    override fun onAudioOutput(output: AudioOutput, deviceName: String) {
        flutterApi.audioDeviceChanged(output, deviceName) {}
    }

    override fun onLibrary(songCount: Int) {
        flutterApi.libraryChanged(songCount.toLong()) {}
    }

    override fun onMetadata(song: Song) {
        flutterApi.metadataUpdated(song) {}
    }

    override fun onSleepTimerFinished() {
        flutterApi.sleepTimerFinished {}
    }

    override fun onFavoriteToggleRequested(songId: Long) {
        flutterApi.favoriteToggleRequested(songId) {}
    }

    override fun onError(code: String, message: String) {
        flutterApi.errorOccurred(code, message) {}
    }

    private companion object {
        const val REQUEST_PICK_FOLDER = 4101
        const val REQUEST_PICK_DOCUMENT = 4102
        const val REQUEST_CREATE_DOCUMENT = 4103
        const val REQUEST_WRITE_CONSENT = 4104
        const val REQUEST_DELETE_FILE = 4105
    }
}
