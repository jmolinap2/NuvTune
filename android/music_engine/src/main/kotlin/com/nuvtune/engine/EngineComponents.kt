package com.nuvtune.engine

import android.content.Context

/**
 * Contenedor de las piezas del motor que viven durante todo el proceso.
 *
 * [MusicPlayerService] y [FlutterMusicPlugin] corren en el mismo proceso y
 * necesitan compartir exactamente la misma biblioteca en memoria y el mismo
 * procesador de audio: si cada uno creara los suyos, mover una banda del
 * ecualizador desde la interfaz no afectaria al reproductor.
 *
 * Los comandos de reproduccion no pasan por aqui: viajan por MediaController
 * hacia la sesion multimedia, que es lo que arranca el servicio cuando hace
 * falta y lo mantiene vivo con la interfaz destruida.
 */
internal object EngineComponents {

    private var components: Components? = null

    fun get(context: Context): Components {
        val existing = components
        if (existing != null) return existing
        PlaybackFailureLog.attach(context.applicationContext)
        val created = Components(context.applicationContext)
        components = created
        return created
    }

    class Components(context: Context) {
        val library = MediaStoreRepository(context)
        val effects = AudioEffectsManager(context)
        val metadataEditor = MetadataEditor(context, library)
        val coverArtEditor = CoverArtEditor(context)
        val safManager = SafManager(context)
        val lyricsReader = LyricsReader(context, library, safManager, metadataEditor)
        val shareHelper = ShareHelper(context, library)
        val loudnessAnalyzer = LoudnessAnalyzer(context)
        val remoteSources = RemoteSourceManager(context)
    }
}
