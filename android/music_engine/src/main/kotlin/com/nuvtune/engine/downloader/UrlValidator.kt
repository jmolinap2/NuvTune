package com.nuvtune.engine.downloader

import java.net.URI

/**
 * Filtra los enlaces pegados directamente a los dominios que yt-dlp sabe
 * resolver bien para este caso de uso (TikTok/Instagram/Facebook/YouTube).
 * Portado de C:\Repos\NuvClip; no se aplica a las busquedas por texto de
 * [YtDlpEngine.search], que nunca pasan por aqui porque no son un enlace.
 */
object UrlValidator {
    private val tiktokHosts = setOf(
        "tiktok.com", "www.tiktok.com", "m.tiktok.com", "vm.tiktok.com", "vt.tiktok.com",
    )
    private val instagramHosts = setOf(
        "instagram.com", "www.instagram.com",
    )
    private val facebookHosts = setOf(
        "facebook.com", "www.facebook.com", "m.facebook.com", "web.facebook.com", "fb.watch",
    )
    private val youtubeHosts = setOf(
        "youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be",
    )
    private val soundcloudHosts = setOf(
        "soundcloud.com", "www.soundcloud.com", "m.soundcloud.com", "on.soundcloud.com",
    )

    fun platformFor(url: String): SourcePlatform {
        val host = hostOf(url) ?: return SourcePlatform.UNKNOWN
        return when {
            tiktokHosts.contains(host) -> SourcePlatform.TIKTOK
            instagramHosts.contains(host) -> SourcePlatform.INSTAGRAM
            facebookHosts.contains(host) -> SourcePlatform.FACEBOOK
            youtubeHosts.contains(host) -> SourcePlatform.YOUTUBE
            soundcloudHosts.contains(host) -> SourcePlatform.SOUNDCLOUD
            else -> SourcePlatform.UNKNOWN
        }
    }

    private fun hostOf(url: String): String? =
        try {
            URI(url.trim()).host?.lowercase()
        } catch (_: Exception) {
            null
        }
}
