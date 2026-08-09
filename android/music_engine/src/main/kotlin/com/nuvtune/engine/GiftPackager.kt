package com.nuvtune.engine

import android.content.Context
import android.net.Uri
import android.util.Base64
import com.nuvtune.engine.downloader.MediaStoreWriter
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.security.MessageDigest
import java.util.Locale
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Arma, verifica e importa archivos `.nuvtune-gift`.
 *
 * Los regalos v2 son ZIP firmados por una identidad EC guardada en Android
 * Keystore. La firma cubre `gift.json` y cada byte de audio. El formato JSON
 * suelto y los ZIP v1 siguen abriendo, pero se identifican como no firmados.
 */
internal class GiftPackager(
    private val context: Context,
    private val library: MediaStoreRepository,
) {
    private val relativeFolder = "NuvTune regalos"
    private val identity = GiftIdentityStore(context)
    private var stagedGift: StagedGift? = null

    fun create(
        suggestedFileName: String,
        metadataJson: String,
        songIds: List<Long>,
    ): String {
        val metadataBytes = metadataJson.toByteArray(Charsets.UTF_8)
        if (metadataBytes.size > MAX_METADATA_BYTES) {
            throw IOException("La dedicatoria del regalo es demasiado grande")
        }
        if (songIds.isEmpty() || songIds.size > MAX_SONGS) {
            throw IOException("El regalo debe contener entre 1 y $MAX_SONGS canciones")
        }

        val directory = File(context.cacheDir, "gifts").apply {
            mkdirs()
            listFiles()?.forEach { it.delete() }
        }
        val target = File(directory, sanitizeFileName(suggestedFileName))
        val records = mutableListOf<EntryRecord>()

        try {
            ZipOutputStream(target.outputStream().buffered()).use { zip ->
                records += writeBytesEntry(zip, METADATA_ENTRY, metadataBytes)

                songIds.forEachIndexed { index, songId ->
                    val song = library.songById(songId) ?: return@forEachIndexed
                    val input = context.contentResolver.openInputStream(library.contentUriFor(song.id))
                        ?: return@forEachIndexed
                    input.use {
                        records += writeStreamEntry(
                            zip = zip,
                            name = audioEntryName(index, song.filePath),
                            input = it,
                            limit = MAX_AUDIO_ENTRY_BYTES,
                        )
                    }
                }

                val security = createSecurityDocument(records)
                writeBytesEntry(zip, SECURITY_ENTRY, security)
            }
        } catch (error: Throwable) {
            target.delete()
            throw error
        }
        return target.absolutePath
    }

    /** Copia el archivo a cache privada, lo valida y devuelve solo su resumen. */
    fun read(uri: String): GiftPackage {
        val stagedFile = stageIncoming(Uri.parse(uri))
        return try {
            val parsed = parse(stagedFile)
            stagedGift?.file?.takeIf { it != stagedFile }?.delete()
            stagedGift = StagedGift(sourceUri = uri, file = stagedFile, parsed = parsed)
            GiftPackage(
                metadataJson = decorateMetadata(parsed),
                embeddedAudioCount = parsed.audioCount.toLong(),
                sizeBytes = stagedFile.length(),
            )
        } catch (error: Throwable) {
            stagedFile.delete()
            throw error
        }
    }

    /** Importa unicamente desde la copia privada que ya supero la validacion. */
    fun importAudio(uri: String): Long {
        var staged = stagedGift?.takeIf { it.sourceUri == uri }
        if (staged == null) {
            read(uri)
            staged = stagedGift ?: throw IOException("El regalo no pudo validarse")
        }
        val parsed = staged.parsed
        if (!parsed.isZip) return 0L

        val songs = JSONObject(parsed.metadataJson).getJSONArray("songs")
        val existing = library.currentSongs
            .mapTo(mutableSetOf()) { songKey(it.title, it.artist) }
        var imported = 0L

        forEachZipEntry(staged.file) { entry, stream ->
            if (!AUDIO_ENTRY.matches(entry.name)) return@forEachZipEntry
            val index = indexOfEntry(entry.name)
                ?: throw IOException("Entrada de audio invalida")
            val song = songs.optJSONObject(index)
                ?: throw IOException("El audio no coincide con la lista del regalo")
            val title = song.optString("title").trim()
            val artist = song.optString("artist").trim()
            val key = songKey(title, artist)
            if (key in existing) return@forEachZipEntry

            val temporary = File.createTempFile("gift-audio-", ".tmp", context.cacheDir)
            try {
                temporary.outputStream().buffered().use { output ->
                    copyLimited(stream, output::write, MAX_AUDIO_ENTRY_BYTES)
                }
                MediaStoreWriter.saveAudio(
                    context = context,
                    source = temporary,
                    displayName = entry.name.substringAfterLast('/'),
                    title = title.takeIf { it.isNotBlank() },
                    artist = artist.takeIf { it.isNotBlank() },
                    album = song.optString("album").trim().takeIf { it.isNotBlank() },
                    relativeFolder = relativeFolder,
                )
                existing += key
                imported++
            } finally {
                temporary.delete()
            }
        }

        parsed.security.fullFingerprint?.let { fingerprint ->
            identity.trust(parsed.senderName, fingerprint)
        }
        staged.file.delete()
        stagedGift = null
        return imported
    }

    private fun parse(file: File): ParsedGift {
        if (!looksLikeZip(file)) {
            val metadata = readFileLimited(file, MAX_METADATA_BYTES)
                .toString(Charsets.UTF_8)
            validateMetadata(metadata, emptySet())
            return ParsedGift(
                metadataJson = metadata,
                audioCount = 0,
                isZip = false,
                senderName = JSONObject(metadata).optString("from").trim().ifEmpty { null },
                security = SecurityInfo.unsigned(),
            )
        }

        var metadataBytes: ByteArray? = null
        var securityBytes: ByteArray? = null
        val records = mutableListOf<EntryRecord>()
        val audioIndices = mutableSetOf<Int>()
        val seenNames = mutableSetOf<String>()
        var entryCount = 0
        var totalUncompressed = 0L

        ZipInputStream(file.inputStream().buffered()).use { zip ->
            while (true) {
                val entry = zip.nextEntry ?: break
                entryCount++
                if (entryCount > MAX_ENTRIES) throw IOException("El regalo contiene demasiados archivos")
                validateEntry(entry, seenNames)

                val limit = when (entry.name) {
                    METADATA_ENTRY -> MAX_METADATA_BYTES.toLong()
                    SECURITY_ENTRY -> MAX_SECURITY_BYTES.toLong()
                    else -> MAX_AUDIO_ENTRY_BYTES
                }
                val capture = entry.name == METADATA_ENTRY || entry.name == SECURITY_ENTRY
                val read = readZipEntry(zip, limit, capture)
                totalUncompressed += read.size
                if (totalUncompressed > MAX_TOTAL_UNCOMPRESSED_BYTES) {
                    throw IOException("El regalo descomprimido excede el limite permitido")
                }

                when (entry.name) {
                    METADATA_ENTRY -> metadataBytes = read.bytes
                    SECURITY_ENTRY -> securityBytes = read.bytes
                    else -> {
                        val index = indexOfEntry(entry.name)
                            ?: throw IOException("Entrada de audio invalida")
                        if (!audioIndices.add(index)) {
                            throw IOException("El regalo repite una cancion")
                        }
                    }
                }
                if (entry.name != SECURITY_ENTRY) {
                    records += EntryRecord(entry.name, read.size, read.sha256)
                }
                zip.closeEntry()
            }
        }

        val metadata = metadataBytes?.toString(Charsets.UTF_8)
            ?: throw IOException("El regalo no trae dedicatoria")
        val root = validateMetadata(metadata, audioIndices)
        val senderName = root.optString("from").trim().ifEmpty { null }
        val security = securityBytes?.let { verifySecurity(it, records, senderName) }
            ?: SecurityInfo.unsigned()

        return ParsedGift(
            metadataJson = metadata,
            audioCount = audioIndices.size,
            isZip = true,
            senderName = senderName,
            security = security,
        )
    }

    private fun validateMetadata(metadata: String, audioIndices: Set<Int>): JSONObject {
        val root = runCatching { JSONObject(metadata) }
            .getOrElse { throw IOException("Los metadatos del regalo no son validos") }
        val songs = root.optJSONArray("songs")
            ?: throw IOException("El regalo no contiene una lista de canciones")
        if (songs.length() !in 1..MAX_SONGS) {
            throw IOException("El regalo contiene una cantidad de canciones no permitida")
        }
        if (audioIndices.any { it !in 0 until songs.length() }) {
            throw IOException("El audio no coincide con la lista del regalo")
        }
        return root
    }

    private fun createSecurityDocument(records: List<EntryRecord>): ByteArray {
        val publicKey = identity.publicKeyBytes()
        val entries = JSONArray()
        records.forEach { record ->
            entries.put(
                JSONObject()
                    .put("name", record.name)
                    .put("size", record.size)
                    .put("sha256", encode(record.sha256)),
            )
        }
        val manifest = JSONObject()
            .put("version", FORMAT_VERSION)
            .put("algorithm", GiftIdentityStore.SIGNATURE_ALGORITHM)
            .put("publicKey", encode(publicKey))
            .put("entries", entries)
            .toString()
            .toByteArray(Charsets.UTF_8)
        val signature = identity.sign(manifest)
        return JSONObject()
            .put("manifest", encode(manifest))
            .put("signature", encode(signature))
            .toString()
            .toByteArray(Charsets.UTF_8)
    }

    private fun verifySecurity(
        securityBytes: ByteArray,
        records: List<EntryRecord>,
        senderName: String?,
    ): SecurityInfo {
        val document = runCatching { JSONObject(securityBytes.toString(Charsets.UTF_8)) }
            .getOrElse { throw IOException("La firma del regalo no es valida") }
        val manifestBytes = decode(document.optString("manifest"))
        val signatureBytes = decode(document.optString("signature"))
        val manifest = runCatching { JSONObject(manifestBytes.toString(Charsets.UTF_8)) }
            .getOrElse { throw IOException("La firma del regalo no es valida") }

        if (manifest.optInt("version") != FORMAT_VERSION ||
            manifest.optString("algorithm") != GiftIdentityStore.SIGNATURE_ALGORITHM
        ) {
            throw IOException("El regalo usa una firma no compatible")
        }
        val publicKey = decode(manifest.optString("publicKey"))
        val expected = manifest.optJSONArray("entries")
            ?: throw IOException("La firma del regalo esta incompleta")
        if (expected.length() != records.size) {
            throw IOException("El contenido del regalo fue modificado")
        }

        val actualByName = records.associateBy { it.name }
        val signedNames = mutableSetOf<String>()
        for (index in 0 until expected.length()) {
            val signed = expected.optJSONObject(index)
                ?: throw IOException("La firma del regalo esta incompleta")
            val name = signed.optString("name")
            if (!signedNames.add(name)) throw IOException("La firma repite archivos")
            val actual = actualByName[name]
                ?: throw IOException("El contenido del regalo fue modificado")
            if (signed.optLong("size", -1L) != actual.size ||
                !MessageDigest.isEqual(decode(signed.optString("sha256")), actual.sha256)
            ) {
                throw IOException("El contenido del regalo fue modificado")
            }
        }
        if (!identity.verify(publicKey, manifestBytes, signatureBytes)) {
            throw IOException("La firma del regalo no coincide con su contenido")
        }

        val assessment = identity.assess(senderName, publicKey)
        return SecurityInfo(
            status = assessment.status,
            displayFingerprint = assessment.displayFingerprint,
            fullFingerprint = assessment.fullFingerprint,
        )
    }

    private fun decorateMetadata(parsed: ParsedGift): String {
        val root = JSONObject(parsed.metadataJson)
        root.remove(SECURITY_METADATA_KEY)
        root.put(
            SECURITY_METADATA_KEY,
            JSONObject()
                .put("status", parsed.security.status)
                .put("fingerprint", parsed.security.displayFingerprint)
                .put("formatVersion", if (parsed.security.fullFingerprint == null) 1 else FORMAT_VERSION),
        )
        return root.toString()
    }

    private fun stageIncoming(uri: Uri): File {
        val directory = File(context.cacheDir, "received-gifts").apply {
            mkdirs()
            listFiles()?.forEach { it.delete() }
        }
        val target = File.createTempFile("received-", ".nuvtune-gift", directory)
        val input = when (uri.scheme?.lowercase(Locale.ROOT)) {
            "content" -> context.contentResolver.openInputStream(uri)
            "file" -> {
                val source = File(uri.path ?: throw IOException("Ruta de regalo invalida")).canonicalFile
                val cache = context.cacheDir.canonicalFile
                if (!source.path.startsWith(cache.path + File.separator)) {
                    throw IOException("NuvTune solo acepta archivos compartidos mediante Android")
                }
                source.inputStream()
            }
            else -> null
        } ?: throw IOException("No se pudo abrir el regalo")

        try {
            input.use { source ->
                target.outputStream().buffered().use { output ->
                    copyLimited(source, output::write, MAX_PACKAGE_BYTES)
                }
            }
        } catch (error: Throwable) {
            target.delete()
            throw error
        }
        return target
    }

    private fun validateEntry(entry: ZipEntry, seenNames: MutableSet<String>) {
        val name = entry.name
        if (entry.isDirectory ||
            name.isBlank() ||
            name.startsWith('/') ||
            '\\' in name ||
            name.split('/').any { it == ".." } ||
            !seenNames.add(name)
        ) {
            throw IOException("El regalo contiene una ruta no permitida")
        }
        if (name != METADATA_ENTRY && name != SECURITY_ENTRY && !AUDIO_ENTRY.matches(name)) {
            throw IOException("El regalo contiene un archivo no permitido")
        }
    }

    private fun writeBytesEntry(zip: ZipOutputStream, name: String, bytes: ByteArray): EntryRecord {
        zip.putNextEntry(ZipEntry(name))
        zip.write(bytes)
        zip.closeEntry()
        return EntryRecord(name, bytes.size.toLong(), sha256(bytes))
    }

    private fun writeStreamEntry(
        zip: ZipOutputStream,
        name: String,
        input: InputStream,
        limit: Long,
    ): EntryRecord {
        val digest = MessageDigest.getInstance("SHA-256")
        var size = 0L
        val buffer = ByteArray(BUFFER_SIZE)
        zip.putNextEntry(ZipEntry(name))
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            size += read
            if (size > limit) throw IOException("Una cancion excede el limite permitido")
            digest.update(buffer, 0, read)
            zip.write(buffer, 0, read)
        }
        zip.closeEntry()
        return EntryRecord(name, size, digest.digest())
    }

    private fun readZipEntry(zip: ZipInputStream, limit: Long, capture: Boolean): EntryRead {
        val digest = MessageDigest.getInstance("SHA-256")
        val output = if (capture) ByteArrayOutputStream() else null
        var size = 0L
        val buffer = ByteArray(BUFFER_SIZE)
        while (true) {
            val read = zip.read(buffer)
            if (read < 0) break
            size += read
            if (size > limit) throw IOException("Un archivo del regalo excede el limite permitido")
            digest.update(buffer, 0, read)
            output?.write(buffer, 0, read)
        }
        return EntryRead(size, digest.digest(), output?.toByteArray())
    }

    private fun copyLimited(input: InputStream, write: (ByteArray, Int, Int) -> Unit, limit: Long) {
        var copied = 0L
        val buffer = ByteArray(BUFFER_SIZE)
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            copied += read
            if (copied > limit) throw IOException("El regalo excede el limite permitido")
            write(buffer, 0, read)
        }
    }

    private fun forEachZipEntry(file: File, block: (ZipEntry, ZipInputStream) -> Unit) {
        ZipInputStream(file.inputStream().buffered()).use { zip ->
            while (true) {
                val entry = zip.nextEntry ?: break
                if (!entry.isDirectory) block(entry, zip)
                zip.closeEntry()
            }
        }
    }

    private fun readFileLimited(file: File, limit: Int): ByteArray {
        if (file.length() > limit) throw IOException("El regalo antiguo es demasiado grande")
        return file.readBytes()
    }

    private fun looksLikeZip(file: File): Boolean = file.inputStream().use { stream ->
        val signature = ByteArray(4)
        stream.read(signature) == 4 &&
            signature[0] == 'P'.code.toByte() &&
            signature[1] == 'K'.code.toByte() &&
            signature[2] == 3.toByte() &&
            signature[3] == 4.toByte()
    }

    private fun audioEntryName(index: Int, filePath: String): String {
        val extension = filePath.substringAfterLast('.', "").lowercase(Locale.ROOT)
        if (extension !in AUDIO_EXTENSIONS) {
            throw IOException("Formato de audio no permitido en el regalo")
        }
        return "$AUDIO_PREFIX/${"%04d".format(index)}.$extension"
    }

    private fun indexOfEntry(entryName: String): Int? = entryName
        .substringAfterLast('/')
        .substringBeforeLast('.')
        .toIntOrNull()

    private fun sanitizeFileName(name: String): String {
        val safe = name.replace(Regex("[^\\w\\s.-]"), "").trim().take(100)
        return if (safe.isEmpty()) "NuvTune-Regalo.nuvtune-gift" else safe
    }

    private fun songKey(title: String, artist: String): String =
        "${title.trim().lowercase(Locale.ROOT)}||${artist.trim().lowercase(Locale.ROOT)}"

    private fun sha256(bytes: ByteArray): ByteArray =
        MessageDigest.getInstance("SHA-256").digest(bytes)

    private fun encode(bytes: ByteArray): String = Base64.encodeToString(
        bytes,
        Base64.NO_WRAP or Base64.URL_SAFE or Base64.NO_PADDING,
    )

    private fun decode(value: String): ByteArray {
        if (value.isBlank() || value.length > MAX_BASE64_FIELD) {
            throw IOException("La firma del regalo esta incompleta")
        }
        return runCatching {
            Base64.decode(value, Base64.NO_WRAP or Base64.URL_SAFE or Base64.NO_PADDING)
        }.getOrElse { throw IOException("La firma del regalo no es valida") }
    }

    private data class EntryRecord(val name: String, val size: Long, val sha256: ByteArray)
    private data class EntryRead(
        val size: Long,
        val sha256: ByteArray,
        val bytes: ByteArray?,
    )
    private data class SecurityInfo(
        val status: String,
        val displayFingerprint: String?,
        val fullFingerprint: String?,
    ) {
        companion object {
            fun unsigned() = SecurityInfo(
                GiftIdentityStore.STATUS_UNSIGNED,
                null,
                null,
            )
        }
    }
    private data class ParsedGift(
        val metadataJson: String,
        val audioCount: Int,
        val isZip: Boolean,
        val senderName: String?,
        val security: SecurityInfo,
    )
    private data class StagedGift(
        val sourceUri: String,
        val file: File,
        val parsed: ParsedGift,
    )

    private companion object {
        const val FORMAT_VERSION = 2
        const val METADATA_ENTRY = "gift.json"
        const val SECURITY_ENTRY = "security.json"
        const val SECURITY_METADATA_KEY = "_nuvtuneSecurity"
        const val AUDIO_PREFIX = "audio"
        const val MAX_SONGS = 500
        const val MAX_ENTRIES = MAX_SONGS + 2
        const val MAX_METADATA_BYTES = 256 * 1024
        const val MAX_SECURITY_BYTES = 512 * 1024
        const val MAX_BASE64_FIELD = 1024 * 1024
        const val MAX_PACKAGE_BYTES = 2L * 1024 * 1024 * 1024
        const val MAX_TOTAL_UNCOMPRESSED_BYTES = 2L * 1024 * 1024 * 1024
        const val MAX_AUDIO_ENTRY_BYTES = 512L * 1024 * 1024
        const val BUFFER_SIZE = 64 * 1024
        val AUDIO_EXTENSIONS = setOf(
            "mp3", "m4a", "aac", "flac", "ogg", "opus", "wav", "webm", "amr", "3gp",
        )
        val AUDIO_ENTRY = Regex(
            "^audio/[0-9]{4}\\.(mp3|m4a|aac|flac|ogg|opus|wav|webm|amr|3gp)$",
        )
    }
}
