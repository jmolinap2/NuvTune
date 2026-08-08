package com.nuvtune.app

import android.content.Intent
import android.media.AudioManager
import com.nuvtune.engine.FlutterMusicPlugin
import com.nuvtune.engine.downloader.DownloadEnginePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

/**
 * Aloja la interfaz de Flutter y el puente con el motor.
 *
 * El motor no se registra como plugin de Flutter al uso porque necesita
 * resultados de actividad para el Storage Access Framework y para los dialogos
 * de confirmacion de escritura del sistema, y esos resultados llegan aqui.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val SYSTEM_VOLUME_CHANNEL = "com.nuvtune.app/system_volume"
        private const val GIFT_INTENT_CHANNEL = "com.nuvtune.app/gift_intent"
    }

    private var plugin: FlutterMusicPlugin? = null
    private var systemVolumeChannel: MethodChannel? = null
    private var giftIntentChannel: MethodChannel? = null

    /**
     * Uri del archivo de regalo con el que se abrio la aplicacion, a la
     * espera de que Dart la consuma. Se guarda en vez de enviarse porque en
     * un arranque en frio el intent llega antes de que exista el motor de
     * Flutter que podria recibirlo.
     */
    private var pendingGiftUri: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        pendingGiftUri = extractGiftUri(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // `launchMode="singleTop"`: con la aplicacion ya abierta el regalo
        // llega por aqui y no por onCreate.
        extractGiftUri(intent)?.let { pendingGiftUri = it }
    }

    /**
     * Acepta las dos formas en que puede llegar un archivo: `ACTION_VIEW`
     * (tocarlo en un gestor de archivos) y `ACTION_SEND` (compartirlo hacia
     * NuvTune desde otra aplicacion).
     */
    private fun extractGiftUri(intent: Intent?): String? = when (intent?.action) {
        Intent.ACTION_VIEW -> intent.data?.toString()
        Intent.ACTION_SEND ->
            @Suppress("DEPRECATION")
            intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.toString()
        else -> null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        giftIntentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GIFT_INTENT_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "takePendingGift") {
                    result.success(pendingGiftUri)
                    // Se consume una sola vez: un hot restart o una segunda
                    // consulta no deben reabrir el mismo regalo como si
                    // acabara de llegar.
                    pendingGiftUri = null
                } else {
                    result.notImplemented()
                }
            }
        }
        val created = FlutterMusicPlugin(
            context = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        created.activity = this
        created.attach()
        plugin = created

        // Motor de descarga (busqueda + descarga de audio): a diferencia del
        // motor de reproduccion, no necesita resultados de actividad, asi que
        // se registra por el mecanismo estandar de plugins de Flutter.
        flutterEngine.plugins.add(DownloadEnginePlugin())

        systemVolumeChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_VOLUME_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                val maximum = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    .coerceAtLeast(1)
                when (call.method) {
                    "getMusicVolume" -> {
                        val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                        result.success(current.toDouble() / maximum)
                    }
                    "setMusicVolume" -> {
                        val requested = call.argument<Number>("volume")?.toDouble()
                        if (requested == null || !requested.isFinite()) {
                            result.error("invalid_volume", "El volumen debe estar entre 0 y 1", null)
                            return@setMethodCallHandler
                        }
                        val target = (requested.coerceIn(0.0, 1.0) * maximum)
                            .roundToInt()
                            .coerceIn(0, maximum)
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
                        result.success(target.toDouble() / maximum)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        systemVolumeChannel?.setMethodCallHandler(null)
        systemVolumeChannel = null
        giftIntentChannel?.setMethodCallHandler(null)
        giftIntentChannel = null
        plugin?.let {
            it.activity = null
            it.detach()
        }
        plugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("FlutterActivity no expone ActivityResultLauncher; el motor necesita este callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (plugin?.onActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
