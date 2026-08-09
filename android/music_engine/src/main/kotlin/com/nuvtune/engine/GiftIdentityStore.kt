package com.nuvtune.engine

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.security.spec.X509EncodedKeySpec
import java.util.Calendar
import java.util.Date
import java.util.Locale
import javax.security.auth.x500.X500Principal

/** Resultado de comparar la identidad firmante con emisores aceptados antes. */
internal data class GiftIdentityAssessment(
    val status: String,
    val displayFingerprint: String,
    val fullFingerprint: String,
)

/**
 * Identidad local para firmar regalos y memoria TOFU de emisores conocidos.
 *
 * No pretende probar el nombre real de una persona: sin cuentas ni un
 * directorio de claves eso no es posible. Si permite detectar manipulaciones,
 * reconocer el mismo dispositivo en envios posteriores y advertir cuando un
 * nombre conocido aparece firmado por otra clave.
 */
internal class GiftIdentityStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun publicKeyBytes(): ByteArray = signingEntry().certificate.publicKey.encoded

    fun sign(content: ByteArray): ByteArray = Signature.getInstance(SIGNATURE_ALGORITHM).run {
        initSign(signingEntry().privateKey)
        update(content)
        sign()
    }

    fun verify(publicKeyBytes: ByteArray, content: ByteArray, signature: ByteArray): Boolean =
        runCatching {
            val publicKey = KeyFactory.getInstance("EC")
                .generatePublic(X509EncodedKeySpec(publicKeyBytes))
            Signature.getInstance(SIGNATURE_ALGORITHM).run {
                initVerify(publicKey)
                update(content)
                verify(signature)
            }
        }.getOrDefault(false)

    fun assess(senderName: String?, publicKeyBytes: ByteArray): GiftIdentityAssessment {
        val fullFingerprint = fingerprint(publicKeyBytes)
        val trusted = preferences.getStringSet(TRUSTED_FINGERPRINTS, emptySet()).orEmpty()
        val previousForName = senderName
            ?.takeIf { it.isNotBlank() }
            ?.let { preferences.getString(senderPreferenceKey(it), null) }

        val status = when {
            fullFingerprint in trusted -> STATUS_KNOWN
            previousForName != null && previousForName != fullFingerprint -> STATUS_CHANGED
            else -> STATUS_NEW
        }
        return GiftIdentityAssessment(
            status = status,
            displayFingerprint = displayFingerprint(publicKeyBytes),
            fullFingerprint = fullFingerprint,
        )
    }

    fun trust(senderName: String?, fullFingerprint: String) {
        val trusted = preferences.getStringSet(TRUSTED_FINGERPRINTS, emptySet())
            .orEmpty()
            .toMutableSet()
            .apply { add(fullFingerprint) }
        preferences.edit()
            .putStringSet(TRUSTED_FINGERPRINTS, trusted)
            .apply {
                if (!senderName.isNullOrBlank()) {
                    putString(senderPreferenceKey(senderName), fullFingerprint)
                }
            }
            .apply()
    }

    private fun signingEntry(): KeyStore.PrivateKeyEntry {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry)?.let { return it }

        val now = Calendar.getInstance()
        val expires = Calendar.getInstance().apply { add(Calendar.YEAR, 25) }
        val generator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            KEYSTORE_PROVIDER,
        )
        generator.initialize(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
            )
                .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setCertificateSubject(X500Principal("CN=NuvTune Gift Identity"))
                .setCertificateSerialNumber(BigInteger.ONE)
                .setCertificateNotBefore(Date(now.timeInMillis))
                .setCertificateNotAfter(Date(expires.timeInMillis))
                .setUserAuthenticationRequired(false)
                .build(),
        )
        generator.generateKeyPair()

        val refreshed = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        return refreshed.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
    }

    private fun senderPreferenceKey(senderName: String): String {
        val normalized = senderName.trim().lowercase(Locale.ROOT).replace(Regex("\\s+"), " ")
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(normalized.toByteArray(Charsets.UTF_8))
        return SENDER_PREFIX + Base64.encodeToString(
            digest,
            Base64.NO_WRAP or Base64.URL_SAFE or Base64.NO_PADDING,
        )
    }

    private fun fingerprint(publicKeyBytes: ByteArray): String = Base64.encodeToString(
        MessageDigest.getInstance("SHA-256").digest(publicKeyBytes),
        Base64.NO_WRAP or Base64.URL_SAFE or Base64.NO_PADDING,
    )

    private fun displayFingerprint(publicKeyBytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256")
            .digest(publicKeyBytes)
            .take(8)
            .joinToString("") { "%02X".format(it) }
            .chunked(4)
            .joinToString("-")

    companion object {
        const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
        const val STATUS_NEW = "signed_new"
        const val STATUS_KNOWN = "signed_known"
        const val STATUS_CHANGED = "signed_changed"
        const val STATUS_UNSIGNED = "legacy_unsigned"

        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "nuvtune_gift_signing_v1"
        private const val PREFERENCES = "nuvtune_gift_identity"
        private const val TRUSTED_FINGERPRINTS = "trusted_fingerprints"
        private const val SENDER_PREFIX = "sender_"
    }
}
