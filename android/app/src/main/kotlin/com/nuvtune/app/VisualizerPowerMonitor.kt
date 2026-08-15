package com.nuvtune.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Expone a Flutter solo el estado energetico que afecta al visualizador.
 *
 * No sondea la bateria: Android entrega un Intent sticky inicial y despues
 * notifica cambios. El receptor existe solo mientras Flutter escucha el
 * EventChannel, de modo que fuera de la pantalla consumidora no queda trabajo
 * periodico ni una referencia viva a la Activity.
 */
class VisualizerPowerMonitor(
    context: Context,
    messenger: BinaryMessenger,
) : EventChannel.StreamHandler {

    companion object {
        private const val CHANNEL = "com.nuvtune.app/visualizer_power_state"
        private const val LOW_BATTERY_FALLBACK = 0.15
    }

    private val appContext = context.applicationContext
    private val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
    private val channel = EventChannel(messenger, CHANNEL)

    private var eventSink: EventChannel.EventSink? = null
    private var receiverRegistered = false
    private var lastBatteryIntent: Intent? = null
    private var lowBatteryBroadcast: Boolean? = null

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_BATTERY_CHANGED -> lastBatteryIntent = Intent(intent)
                Intent.ACTION_BATTERY_LOW -> lowBatteryBroadcast = true
                Intent.ACTION_BATTERY_OKAY -> lowBatteryBroadcast = false
            }
            emitState()
        }
    }

    init {
        channel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stopListening()
        eventSink = events

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(Intent.ACTION_BATTERY_LOW)
            addAction(Intent.ACTION_BATTERY_OKAY)
            addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        }
        lastBatteryIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            appContext.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            appContext.registerReceiver(receiver, filter)
        }
        receiverRegistered = true
        emitState()
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    fun dispose() {
        stopListening()
        channel.setStreamHandler(null)
    }

    private fun stopListening() {
        if (receiverRegistered) {
            runCatching { appContext.unregisterReceiver(receiver) }
            receiverRegistered = false
        }
        eventSink = null
        // El próximo listener debe reconstruir el estado desde el Intent
        // sticky actual. Conservar ACTION_BATTERY_LOW de una sesión anterior
        // podría forzar Eco incluso después de que la batería se recuperó.
        lastBatteryIntent = null
        lowBatteryBroadcast = null
    }

    private fun emitState() {
        val battery = lastBatteryIntent ?: readBatteryState()
        if (lastBatteryIntent == null && battery != null) {
            lastBatteryIntent = battery
        }

        val rawLevel = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val rawScale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryLevel = if (rawLevel >= 0 && rawScale > 0) {
            (rawLevel.toDouble() / rawScale.toDouble()).coerceIn(0.0, 1.0)
        } else {
            null
        }
        val status = battery?.getIntExtra(
            BatteryManager.EXTRA_STATUS,
            BatteryManager.BATTERY_STATUS_UNKNOWN,
        ) ?: BatteryManager.BATTERY_STATUS_UNKNOWN
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        val systemReportsLow = battery?.getBooleanExtra(
            BatteryManager.EXTRA_BATTERY_LOW,
            false,
        ) ?: false
        val isBatteryLow = lowBatteryBroadcast
            ?: (systemReportsLow || (batteryLevel != null && batteryLevel <= LOW_BATTERY_FALLBACK))

        eventSink?.success(
            mapOf(
                "batteryLevel" to batteryLevel,
                "isCharging" to isCharging,
                "isBatteryLow" to isBatteryLow,
                "isPowerSaveMode" to powerManager.isPowerSaveMode,
            ),
        )
    }

    private fun readBatteryState(): Intent? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        appContext.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            Context.RECEIVER_EXPORTED,
        )
    } else {
        @Suppress("UnspecifiedRegisterReceiverFlag")
        appContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }
}
