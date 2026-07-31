package com.nuvtune.engine

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper

/**
 * Detecta por que salida esta sonando la musica (requerimiento seccion 5.4) y
 * avisa cuando cambia, para que el motor emita `audioDeviceChanged`.
 *
 * Android no ofrece una consulta directa de "salida activa para medios" antes de
 * API 31, asi que se resuelve por prioridad de conexion, que es el mismo orden
 * que aplica el enrutador de audio del sistema: DAC USB, Bluetooth, cable y por
 * ultimo el altavoz integrado.
 */
internal class AudioOutputMonitor(context: Context) {

    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var callback: AudioDeviceCallback? = null

    /**
     * Android Auto no aparece como dispositivo de salida: se marca cuando el
     * controlador conectado a la sesion es el proyector de Android Auto.
     */
    @Volatile
    var androidAutoConnected: Boolean = false
        set(value) {
            val changed = field != value
            field = value
            if (changed) {
                notifyChange()
            }
        }

    private var listener: ((AudioOutput, String) -> Unit)? = null

    fun start(onChanged: (AudioOutput, String) -> Unit) {
        listener = onChanged
        val deviceCallback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
                notifyChange()
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
                notifyChange()
            }
        }
        audioManager.registerAudioDeviceCallback(deviceCallback, Handler(Looper.getMainLooper()))
        callback = deviceCallback
        notifyChange()
    }

    fun stop() {
        callback?.let { audioManager.unregisterAudioDeviceCallback(it) }
        callback = null
        listener = null
    }

    private fun notifyChange() {
        val current = listener ?: return
        val (output, name) = resolveCurrentOutput()
        current(output, name)
    }

    fun resolveCurrentOutput(): Pair<AudioOutput, String> {
        if (androidAutoConnected) {
            return AudioOutput.ANDROID_AUTO to "Android Auto"
        }

        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

        // El orden de esta lista define la prioridad de enrutado.
        val priority = listOf(
            AudioOutput.USB_DAC to setOf(
                AudioDeviceInfo.TYPE_USB_DEVICE,
                AudioDeviceInfo.TYPE_USB_HEADSET,
                AudioDeviceInfo.TYPE_USB_ACCESSORY,
            ),
            AudioOutput.BLUETOOTH to setOf(
                AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                AudioDeviceInfo.TYPE_BLE_HEADSET,
                AudioDeviceInfo.TYPE_BLE_SPEAKER,
                AudioDeviceInfo.TYPE_HEARING_AID,
            ),
            AudioOutput.WIRED_HEADPHONES to setOf(
                AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                AudioDeviceInfo.TYPE_WIRED_HEADSET,
            ),
        )

        for ((output, types) in priority) {
            val match = devices.firstOrNull { it.type in types }
            if (match != null) {
                return output to (match.productName?.toString() ?: output.name)
            }
        }

        return AudioOutput.SPEAKER to "Altavoz del telefono"
    }
}
