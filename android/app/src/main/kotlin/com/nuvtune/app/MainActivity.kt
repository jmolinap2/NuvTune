package com.nuvtune.app

import android.content.Intent
import com.nuvtune.engine.FlutterMusicPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Aloja la interfaz de Flutter y el puente con el motor.
 *
 * El motor no se registra como plugin de Flutter al uso porque necesita
 * resultados de actividad para el Storage Access Framework y para los dialogos
 * de confirmacion de escritura del sistema, y esos resultados llegan aqui.
 */
class MainActivity : FlutterActivity() {

    private var plugin: FlutterMusicPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val created = FlutterMusicPlugin(
            context = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        created.activity = this
        created.attach()
        plugin = created
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
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
