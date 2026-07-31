package com.nuvtune.engine

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Guarda las contrasenas de los servidores remotos cifradas con la Keystore de
 * Android (requerimiento seccion 16).
 *
 * La clave nunca sale del almacen de claves del sistema: aqui solo viajan el
 * texto cifrado y su vector de inicializacion. Una copia de seguridad del
 * telefono que se restaure en otro dispositivo no puede descifrar nada, que es
 * precisamente lo que se busca.
 */
internal class RemoteCredentialStore(context: Context) {

    private val preferences =
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun save(sourceId: Long, password: String?) {
        if (password.isNullOrEmpty()) {
            preferences.edit().remove(key(sourceId)).apply()
            return
        }

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(password.toByteArray(Charsets.UTF_8))

        // El vector de inicializacion se guarda junto al texto cifrado; no es
        // secreto, pero tiene que ser distinto en cada escritura.
        val payload = Base64.encodeToString(cipher.iv, Base64.NO_WRAP) +
            SEPARATOR +
            Base64.encodeToString(encrypted, Base64.NO_WRAP)

        preferences.edit().putString(key(sourceId), payload).apply()
    }

    fun read(sourceId: Long): String? {
        val payload = preferences.getString(key(sourceId), null) ?: return null
        val parts = payload.split(SEPARATOR)
        if (parts.size != 2) return null

        val iv = Base64.decode(parts[0], Base64.NO_WRAP)
        val encrypted = Base64.decode(parts[1], Base64.NO_WRAP)

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.DECRYPT_MODE,
            secretKey(),
            GCMParameterSpec(TAG_LENGTH_BITS, iv),
        )
        return String(cipher.doFinal(encrypted), Charsets.UTF_8)
    }

    fun has(sourceId: Long): Boolean = preferences.contains(key(sourceId))

    fun remove(sourceId: Long) {
        preferences.edit().remove(key(sourceId)).apply()
    }

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(PROVIDER).apply { load(null) }
        val existing = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing

        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            PROVIDER,
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build(),
        )
        return generator.generateKey()
    }

    private fun key(sourceId: Long) = "source_$sourceId"

    companion object {
        private const val PREFERENCES_NAME = "nuvtune_remote_credentials"
        private const val PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "nuvtune_remote_credentials"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val TAG_LENGTH_BITS = 128
        private const val SEPARATOR = ":"
    }
}
