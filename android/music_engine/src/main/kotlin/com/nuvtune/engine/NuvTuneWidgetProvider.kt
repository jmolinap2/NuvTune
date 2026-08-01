package com.nuvtune.engine

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.SystemClock
import android.view.KeyEvent
import android.view.View
import android.widget.RemoteViews
import androidx.media3.session.MediaButtonReceiver
import com.nuvtune.app.R

/**
 * Widget de inicio configurable (requerimiento seccion 9.2).
 *
 * Los controles se envian como eventos de boton multimedia al
 * MediaButtonReceiver de Media3, de modo que funcionan igual que los de unos
 * auriculares aunque la interfaz de Flutter no exista, y sin necesidad de
 * arrancar la actividad.
 *
 * El aspecto sale de [WidgetConfigStore]. El tamaño no: se toma del que el
 * usuario le haya dado al widget en la pantalla de inicio, porque el tamaño
 * elegido en ajustes es solo una preferencia y el lanzador manda.
 */
class NuvTuneWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                widgetId,
                buildViews(context, appWidgetManager.getAppWidgetOptions(widgetId)),
            )
        }
    }

    /** Al redimensionar hay que repintar: cambia que filas caben. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        appWidgetManager.updateAppWidget(appWidgetId, buildViews(context, newOptions))
    }

    private fun buildViews(context: Context, options: Bundle?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.nuvtune_widget)
        val config = WidgetConfigStore.load(context)
        val size = resolveSize(options, config.preferredSize)
        val palette = Palette.of(config)

        val song = PlaybackStateHolder.currentSong
        val snapshot = PlaybackStateHolder.snapshot
        val isPlaying = snapshot.isPlaying

        applyBackground(views, palette)
        applyTexts(views, context, config, palette, song)
        applyCover(views, context, config, song)
        applyProgress(views, config, size, palette, snapshot, song)
        applyControls(views, context, config, size, palette, isPlaying)

        views.setOnClickPendingIntent(
            R.id.widget_root,
            if (config.openPlayerOnTap) openAppIntent(context) else noOpIntent(context),
        )

        return views
    }

    // -- Piezas --------------------------------------------------------------

    private fun applyBackground(views: RemoteViews, palette: Palette) {
        // setColorStateList sobre el fondo permite teñir la forma redondeada sin
        // tener que mantener un drawable por combinacion de color y opacidad.
        views.setInt(R.id.widget_card, "setBackgroundColor", Color.TRANSPARENT)
        views.setInt(
            R.id.widget_card,
            "setBackgroundResource",
            R.drawable.nuvtune_widget_background,
        )
        views.setColorStateList(
            R.id.widget_card,
            "setBackgroundTintList",
            android.content.res.ColorStateList.valueOf(palette.background),
        )
    }

    private fun applyTexts(
        views: RemoteViews,
        context: Context,
        config: WidgetConfig,
        palette: Palette,
        song: Song?,
    ) {
        views.setViewVisibility(
            R.id.widget_title,
            if (config.showTitle) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_artist,
            if (config.showArtist) View.VISIBLE else View.GONE,
        )

        views.setTextViewText(
            R.id.widget_title,
            song?.title ?: context.getString(R.string.nuvtune_widget_empty_title),
        )
        views.setTextViewText(
            R.id.widget_artist,
            song?.artist ?: context.getString(R.string.nuvtune_widget_empty_artist),
        )
        views.setTextColor(R.id.widget_title, palette.primaryText)
        views.setTextColor(R.id.widget_artist, palette.secondaryText)

        val nextSong = PlaybackStateHolder.nextSong
        val showNext = config.showNextInQueue && nextSong != null
        views.setViewVisibility(
            R.id.widget_next_up,
            if (showNext) View.VISIBLE else View.GONE,
        )
        if (showNext) {
            views.setTextViewText(
                R.id.widget_next_up,
                context.getString(R.string.nuvtune_widget_next_up, nextSong.title),
            )
            views.setTextColor(R.id.widget_next_up, palette.accent)
        }
    }

    private fun applyCover(
        views: RemoteViews,
        context: Context,
        config: WidgetConfig,
        song: Song?,
    ) {
        views.setViewVisibility(
            R.id.widget_cover,
            if (config.showCover) View.VISIBLE else View.GONE,
        )
        if (!config.showCover) return

        val cover = song?.let {
            EngineComponents.get(context).library.loadThumbnail(it.id, COVER_SIZE)
        }
        if (cover != null) {
            views.setImageViewBitmap(R.id.widget_cover, cover)
        } else {
            views.setImageViewResource(R.id.widget_cover, R.drawable.ic_stat_nuvtune)
        }
    }

    private fun applyProgress(
        views: RemoteViews,
        config: WidgetConfig,
        size: WidgetSize,
        palette: Palette,
        snapshot: PlaybackSnapshot,
        song: Song?,
    ) {
        // En 4x1 no cabe la barra por mucho que el usuario la pida.
        val show = config.showProgress && size != WidgetSize.COMPACT
        views.setViewVisibility(
            R.id.widget_progress_row,
            if (show) View.VISIBLE else View.GONE,
        )
        if (!show) return

        val duration = if (snapshot.durationMs > 0) {
            snapshot.durationMs
        } else {
            song?.durationMs ?: 0L
        }
        val progress = if (duration > 0) {
            ((snapshot.positionMs.toDouble() / duration) * PROGRESS_MAX).toInt()
        } else {
            0
        }
        views.setProgressBar(R.id.widget_progress, PROGRESS_MAX, progress, false)
        views.setColorStateList(
            R.id.widget_progress,
            "setProgressTintList",
            android.content.res.ColorStateList.valueOf(palette.accent),
        )

        val showTimes = config.showDuration
        views.setViewVisibility(
            R.id.widget_position,
            if (showTimes) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_duration,
            if (showTimes) View.VISIBLE else View.GONE,
        )
        if (showTimes) {
            views.setTextViewText(R.id.widget_position, formatTime(snapshot.positionMs))
            views.setTextViewText(R.id.widget_duration, formatTime(duration))
            views.setTextColor(R.id.widget_position, palette.secondaryText)
            views.setTextColor(R.id.widget_duration, palette.secondaryText)
        }
    }

    private fun applyControls(
        views: RemoteViews,
        context: Context,
        config: WidgetConfig,
        size: WidgetSize,
        palette: Palette,
        isPlaying: Boolean,
    ) {
        if (!config.showControls) {
            views.setViewVisibility(R.id.widget_controls, View.GONE)
            views.setViewVisibility(R.id.widget_inline_controls, View.GONE)
            return
        }

        // En 4x1 los controles van en la misma fila que el texto; en los demas
        // tamaños ocupan su propia fila centrada.
        val inline = size == WidgetSize.COMPACT
        views.setViewVisibility(
            R.id.widget_inline_controls,
            if (inline) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_controls,
            if (inline) View.GONE else View.VISIBLE,
        )

        // Aleatorio y repetir solo en 4x3, que es donde hay sitio de sobra.
        val extras = size == WidgetSize.LARGE && !inline
        views.setViewVisibility(
            R.id.widget_shuffle,
            if (extras) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_repeat,
            if (extras) View.VISIBLE else View.GONE,
        )

        val playIcon =
            if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play

        val previous = if (inline) R.id.widget_inline_previous else R.id.widget_previous
        val playPause =
            if (inline) R.id.widget_inline_play_pause else R.id.widget_play_pause
        val next = if (inline) R.id.widget_inline_next else R.id.widget_next

        views.setImageViewResource(playPause, playIcon)

        // El boton de reproduccion lleva el acento; el resto, el color de texto.
        for (id in listOf(previous, next, R.id.widget_shuffle, R.id.widget_repeat)) {
            views.setColorStateList(
                id,
                "setImageTintList",
                android.content.res.ColorStateList.valueOf(palette.primaryText),
            )
        }
        views.setColorStateList(
            playPause,
            "setImageTintList",
            android.content.res.ColorStateList.valueOf(palette.accent),
        )

        views.setOnClickPendingIntent(
            previous,
            mediaButtonIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS),
        )
        views.setOnClickPendingIntent(
            playPause,
            mediaButtonIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE),
        )
        views.setOnClickPendingIntent(
            next,
            mediaButtonIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT),
        )
    }

    // -- Utilidades ----------------------------------------------------------

    /**
     * Colores efectivos del widget.
     *
     * El estilo iOS es una tarjeta clara y el VLC una oscura; el tema del
     * usuario puede forzar uno u otro, y la transparencia se aplica sobre el
     * color de fondo resultante.
     */
    private class Palette(
        val background: Int,
        val primaryText: Int,
        val secondaryText: Int,
        val accent: Int,
    ) {
        companion object {
            fun of(config: WidgetConfig): Palette {
                val light = when (config.theme) {
                    WidgetTheme.LIGHT -> true
                    WidgetTheme.DARK -> false
                    // "Seguir al sistema" no es consultable de forma fiable
                    // desde un widget, de modo que se resuelve por estilo: el
                    // aspecto iOS es claro y el VLC es oscuro.
                    WidgetTheme.SYSTEM -> config.style == WidgetStyle.IOS
                }

                val base = if (light) LIGHT_BACKGROUND else DARK_BACKGROUND
                val alpha = (config.backgroundOpacity.coerceIn(0.0, 1.0) * 255).toInt()

                return Palette(
                    background = Color.argb(
                        alpha,
                        Color.red(base),
                        Color.green(base),
                        Color.blue(base),
                    ),
                    primaryText = if (light) Color.BLACK else Color.WHITE,
                    secondaryText = if (light) LIGHT_SECONDARY else DARK_SECONDARY,
                    accent = config.accentColor.toInt(),
                )
            }

            private const val LIGHT_BACKGROUND = 0xFFF3EFFA.toInt()
            private const val DARK_BACKGROUND = 0xFF12101A.toInt()
            private const val LIGHT_SECONDARY = 0xFF5A5566.toInt()
            private const val DARK_SECONDARY = 0xFFB3AEC0.toInt()
        }
    }

    /**
     * Tamaño real del widget en la pantalla de inicio. Cada celda de la rejilla
     * ronda los 70 dp de alto, de modo que el umbral distingue 4x1, 4x2 y 4x3.
     */
    private fun resolveSize(options: Bundle?, preferred: WidgetSize): WidgetSize {
        val height = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
        if (height <= 0) return preferred
        return when {
            height < 110 -> WidgetSize.COMPACT
            height < 200 -> WidgetSize.NORMAL
            else -> WidgetSize.LARGE
        }
    }

    private fun formatTime(milliseconds: Long): String {
        val totalSeconds = (milliseconds / 1000).coerceAtLeast(0)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return "%d:%02d".format(minutes, seconds)
    }

    private fun mediaButtonIntent(context: Context, keyCode: Int): PendingIntent {
        // Ruta por broadcast al MediaButtonReceiver de Media3 (el mismo que
        // atiende los botones de auriculares y Bluetooth). El servicio recibe el
        // KeyEvent aunque este dormido en segundo plano; llamar startService()
        // directo al MediaLibraryService desde un widget no dispara la accion
        // porque Media3 solo procesa MEDIA_BUTTON cuando llega por el receiver.
        val now = SystemClock.uptimeMillis()
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClass(context, MediaButtonReceiver::class.java)
            putExtra(
                Intent.EXTRA_KEY_EVENT,
                KeyEvent(now, now, KeyEvent.ACTION_DOWN, keyCode, 0),
            )
        }
        return PendingIntent.getBroadcast(
            context,
            keyCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN)
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN_APP,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /**
     * Intento que no hace nada, para cuando el usuario desactiva "abrir al
     * tocar": sin el, el widget conservaria el intento anterior.
     */
    private fun noOpIntent(context: Context): PendingIntent = PendingIntent.getActivity(
        context,
        REQUEST_NO_OP,
        Intent(),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    companion object {
        private const val COVER_SIZE = 144
        private const val REQUEST_OPEN_APP = 1000
        private const val REQUEST_NO_OP = 1001
        private const val PROGRESS_MAX = 1000

        /**
         * Vuelve a pintar todos los widgets colocados. Lo llama el plugin cuando
         * cambia la pista, el estado de reproduccion o la configuracion.
         */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, NuvTuneWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            if (widgetIds.isEmpty()) return

            val provider = NuvTuneWidgetProvider()
            for (widgetId in widgetIds) {
                manager.updateAppWidget(
                    widgetId,
                    provider.buildViews(context, manager.getAppWidgetOptions(widgetId)),
                )
            }
        }

        fun placedCount(context: Context): Int {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, NuvTuneWidgetProvider::class.java)
            return manager.getAppWidgetIds(component).size
        }
    }
}
