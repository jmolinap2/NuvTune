package com.nuvtune.engine

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper

/**
 * Pausa al desconectar los auriculares y, si el usuario lo pide, reanuda al
 * volver a conectarlos (requerimiento seccion 9.2, comportamiento del widget).
 *
 * Media3 trae `setHandleAudioBecomingNoisy`, pero es un interruptor que se fija
 * al construir el reproductor y no se puede cambiar despues. Como el ajuste es
 * del usuario y la reanudacion automatica no existe en Media3, aqui se lleva
 * todo el comportamiento en un solo sitio y el reproductor se construye con esa
 * bandera desactivada, de modo que no haya dos duenos de la misma decision.
 */
internal class HeadphoneMonitor(
    private val context: Context,
    private val onPause: () -> Unit,
    private val onResume: () -> Unit,
) {

    private val handler = Handler(Looper.getMainLooper())
    private var registered = false

    /**
     * Solo se reanuda si la pausa la provoco esta clase. Si el usuario habia
     * pausado a mano, conectar unos auriculares no debe arrancar la musica:
     * es justo lo que el requerimiento 9.3 prohibe.
     */
    private var pausedByDisconnect = false

    private val noisyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != AudioManager.ACTION_AUDIO_BECOMING_NOISY) return
            if (!DeviceControlConfigStore.load(this@HeadphoneMonitor.context)
                    .pauseOnHeadphonesDisconnect
            ) {
                return
            }
            if (!PlaybackStateHolder.snapshot.isPlaying) return

            pausedByDisconnect = true
            onPause()
        }
    }

    private val deviceCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
            val config = DeviceControlConfigStore.load(context)
            if (!config.resumeOnHeadphonesConnect) return
            if (!pausedByDisconnect) return
            if (addedDevices?.any { it.isHeadphone } != true) return

            pausedByDisconnect = false
            onResume()
        }
    }

    fun start() {
        if (registered) return
        registered = true

        context.registerReceiver(
            noisyReceiver,
            IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY),
        )
        audioManager().registerAudioDeviceCallback(deviceCallback, handler)
    }

    fun stop() {
        if (!registered) return
        registered = false

        runCatching { context.unregisterReceiver(noisyReceiver) }
        runCatching { audioManager().unregisterAudioDeviceCallback(deviceCallback) }
    }

    /** El usuario pauso a mano: olvida que la pausa fue por desconexion. */
    fun onManualPause() {
        pausedByDisconnect = false
    }

    private fun audioManager() =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private companion object {
        val AudioDeviceInfo.isHeadphone: Boolean
            get() = type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                type == AudioDeviceInfo.TYPE_USB_HEADSET
    }
}
