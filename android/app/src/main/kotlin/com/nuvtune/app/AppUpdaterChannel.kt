package com.nuvtune.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Parte nativa del actualizador: la descarga y la decision de actualizar viven
 * en Dart; aqui solo esta lo que exige Android -numero de compilacion
 * instalado, permiso de "instalar apps desconocidas" y el instalador del
 * sistema-.
 */
class AppUpdaterChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "installedBuild" -> result.success(
                    activity.packageManager
                        .getPackageInfo(activity.packageName, 0)
                        .longVersionCode,
                )
                "canInstall" -> result.success(
                    activity.packageManager.canRequestPackageInstalls(),
                )
                "openInstallSettings" -> {
                    activity.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:${activity.packageName}"),
                        ),
                    )
                    result.success(null)
                }
                "install" -> {
                    val path = call.argument<String>("path")
                        ?: error("Falta la ruta del APK")
                    val uri = FileProvider.getUriForFile(
                        activity,
                        "${activity.packageName}.gift.files",
                        File(path),
                    )
                    activity.startActivity(
                        Intent(Intent.ACTION_VIEW)
                            .setDataAndType(uri, "application/vnd.android.package-archive")
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private companion object {
        const val CHANNEL = "com.nuvtune.app/updater"
    }
}
