package com.nuvtune.engine.downloader

import android.content.Context
import android.webkit.CookieManager
import java.io.File

/**
 * Sesion de YouTube usada por yt-dlp via `--cookies` (ver
 * [YtDlpEngine.applyCommonOptions]).
 *
 * YouTube bloquea el audio real (no solo el analisis) de casi cualquier
 * video a un cliente anonimo: exige "confirma que no eres un robot" o
 * entrega URLs firmadas que solo sirven para una sonda de ~2 KB y devuelven
 * 403 en cuanto se pide el archivo completo. Medido en el dispositivo con el
 * yt-dlp mas reciente disponible, sin distinguir por video. Iniciar sesion en
 * el WebView de la app (mismo `android.webkit.CookieManager` que usa
 * cualquier WebView del proceso, incluida la del login) resuelve esto igual
 * que en un navegador: las cookies de esa sesion, exportadas aqui a formato
 * Netscape, son las mismas que aceptaria un `cookies.txt` exportado a mano.
 */
object YouTubeCookieJar {
    private const val FILE_NAME = "youtube_cookies.txt"

    /**
     * Cookies que solo aparecen tras iniciar sesion de verdad. Si ninguna
     * esta presente, `CookieManager` solo tiene cookies de consentimiento o
     * idioma de una visita anonima, y guardar ese archivo daria una falsa
     * sensacion de sesion iniciada sin serlo.
     */
    private val authCookieNames = setOf(
        "SAPISID", "APISID", "SSID", "HSID", "SID",
        "__Secure-1PSID", "__Secure-3PSID", "__Secure-3PAPISID",
        "LOGIN_INFO",
    )

    fun file(context: Context): File = File(context.filesDir, FILE_NAME)

    fun hasLogin(context: Context): Boolean {
        val cookieFile = file(context)
        return cookieFile.exists() && cookieFile.length() > 0
    }

    /**
     * Lee las cookies actuales del WebView y las guarda en formato Netscape.
     * Devuelve false (sin escribir nada) si no encuentra cookies de
     * autenticacion reales, para que la interfaz sepa que el usuario todavia
     * no completo el inicio de sesion.
     */
    fun save(context: Context): Boolean {
        val manager = CookieManager.getInstance()
        manager.flush()
        val cookies = parseCookies(manager.getCookie("https://www.youtube.com")) +
            parseCookies(manager.getCookie("https://www.google.com"))
        if (cookies.none { (name, _) -> name in authCookieNames }) {
            return false
        }

        val expiry = (System.currentTimeMillis() / 1000) + COOKIE_LIFETIME_SECONDS
        val builder = StringBuilder("# Netscape HTTP Cookie File\n")
        for ((name, value) in cookies) {
            // dominio, includeSubdomains, ruta, soloHttps, expiracion, nombre, valor
            builder.append(".youtube.com\tTRUE\t/\tTRUE\t$expiry\t$name\t$value\n")
        }
        file(context).writeText(builder.toString())
        return true
    }

    /** Borra la sesion guardada y la del WebView, para que un siguiente inicio de sesion pida usuario y contrasena de nuevo. */
    fun clear(context: Context) {
        file(context).delete()
        CookieManager.getInstance().removeAllCookies(null)
        CookieManager.getInstance().flush()
    }

    private fun parseCookies(raw: String?): List<Pair<String, String>> {
        if (raw.isNullOrBlank()) return emptyList()
        return raw.split(";").mapNotNull { part ->
            val separator = part.indexOf('=')
            if (separator <= 0) return@mapNotNull null
            part.substring(0, separator).trim() to part.substring(separator + 1).trim()
        }
    }

    private const val COOKIE_LIFETIME_SECONDS = 60L * 60 * 24 * 180 // 180 dias
}
