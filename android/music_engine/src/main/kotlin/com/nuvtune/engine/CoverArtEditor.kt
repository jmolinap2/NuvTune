package com.nuvtune.engine

import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream

/**
 * Validacion y normalizacion de portadas antes de incrustarlas
 * (requerimiento secciones 7.2 y 16).
 *
 * El recorte, la rotacion y el encuadre los hace la interfaz de Flutter; aqui
 * se aplica el limite de tamano y se comprueba que los bytes recibidos sean
 * realmente una imagen decodificable, para no escribir basura dentro de un
 * archivo de audio.
 */
internal class CoverArtEditor(private val context: Context) {

    sealed interface Validation {
        data class Valid(val bytes: ByteArray, val mimeType: String) : Validation
        data class Invalid(val reason: String) : Validation
    }

    /**
     * Comprueba y, si hace falta, reduce la imagen. Devuelve siempre JPEG salvo
     * que la original sea PNG y quepa dentro del limite, porque el PNG conserva
     * la transparencia que algunas portadas usan.
     */
    fun validate(imageBytes: ByteArray, declaredMimeType: String): Validation {
        if (imageBytes.isEmpty()) {
            return Validation.Invalid("La imagen esta vacia")
        }

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return Validation.Invalid("Los datos recibidos no son una imagen valida")
        }

        val mimeType = bounds.outMimeType ?: declaredMimeType
        if (mimeType != MIME_JPEG && mimeType != MIME_PNG) {
            return Validation.Invalid("Solo se admite JPEG o PNG como portada")
        }

        val withinPixelLimit = bounds.outWidth <= MAX_DIMENSION_PX &&
            bounds.outHeight <= MAX_DIMENSION_PX
        val withinByteLimit = imageBytes.size <= MAX_BYTES

        if (withinPixelLimit && withinByteLimit) {
            return Validation.Valid(imageBytes, mimeType)
        }

        val decoded = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            ?: return Validation.Invalid("La imagen no se pudo decodificar")

        val scaled = scaleToLimit(decoded)
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, stream)
        if (scaled !== decoded) {
            scaled.recycle()
        }
        decoded.recycle()

        val result = stream.toByteArray()
        if (result.size > MAX_BYTES) {
            return Validation.Invalid(
                "La portada sigue pasando el limite de ${MAX_BYTES / 1024} KB tras comprimirla",
            )
        }
        return Validation.Valid(result, MIME_JPEG)
    }

    private fun scaleToLimit(source: Bitmap): Bitmap {
        val largestSide = maxOf(source.width, source.height)
        if (largestSide <= MAX_DIMENSION_PX) return source
        val ratio = MAX_DIMENSION_PX.toFloat() / largestSide
        val width = (source.width * ratio).toInt().coerceAtLeast(1)
        val height = (source.height * ratio).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(source, width, height, true)
    }

    /**
     * Imagen presente en el portapapeles (requerimiento 7.2: "usar una imagen
     * copiada"). Flutter no expone el portapapeles de imagenes, asi que se lee
     * aqui.
     */
    fun clipboardImage(): ByteArray? {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip ?: return null
        for (index in 0 until clip.itemCount) {
            val uri = clip.getItemAt(index).uri ?: continue
            val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                ?: continue
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            if (bounds.outWidth > 0 && bounds.outHeight > 0) {
                return bytes
            }
        }
        return null
    }

    companion object {
        const val MIME_JPEG = "image/jpeg"
        const val MIME_PNG = "image/png"

        /** Tamano recomendado por el requerimiento 7.2: 1000 x 1000 px. */
        const val RECOMMENDED_DIMENSION_PX = 1000

        /**
         * Limite duro. Se deja por encima del tamano recomendado para admitir
         * portadas de mayor resolucion sin dejar que crezcan sin control.
         */
        const val MAX_DIMENSION_PX = 1500

        /** Limite de peso de la portada incrustada (requerimiento 16). */
        const val MAX_BYTES = 1_500_000

        const val JPEG_QUALITY = 90
    }
}
