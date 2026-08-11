# El nombre de TagLibBridge y de sus metodos nativos forma parte del simbolo
# que exporta libnuvtune_taglib.so (Java_com_nuvtune_engine_TagLibBridge_*).
# Si R8 los renombra, el enlace JNI falla al cargar la biblioteca.
-keepclasseswithmembernames,includedescriptorclasses class com.nuvtune.engine.TagLibBridge {
    native <methods>;
}
-keep class com.nuvtune.engine.TagLibBridge { *; }

# El servicio, el receptor de botones multimedia y el proveedor del widget se
# instancian por nombre desde el manifest.
-keep class com.nuvtune.engine.MusicPlayerService { *; }
-keep class com.nuvtune.engine.NuvTuneWidgetProvider { *; }

# Las clases generadas por Pigeon se serializan por posicion; conservar sus
# miembros evita sorpresas al reflejar los enums.
-keep class com.nuvtune.engine.Song { *; }
-keep class com.nuvtune.engine.TechnicalInfo { *; }
-keep class com.nuvtune.engine.PlaybackSnapshot { *; }
-keep class com.nuvtune.engine.EqualizerSettings { *; }
-keep class com.nuvtune.engine.PlaybackOptions { *; }
-keep class com.nuvtune.engine.MetadataEdit { *; }
-keep class com.nuvtune.engine.WriteResult { *; }
-keep class com.nuvtune.engine.CoverImage { *; }
-keep class com.nuvtune.engine.LyricsPayload { *; }
-keep class com.nuvtune.engine.GrantedFolder { *; }
-keep class com.nuvtune.engine.PickedDocument { *; }
-keep class com.nuvtune.engine.EqualizerBands { *; }
-keep class com.nuvtune.engine.EnhancementSettings { *; }
-keep class com.nuvtune.engine.LoudnessAnalysis { *; }
-keep class com.nuvtune.engine.RemoteSource { *; }
-keep class com.nuvtune.engine.RemoteEntry { *; }
-keep enum com.nuvtune.engine.** { *; }

# youtubedl-android convierte el JSON de yt-dlp a sus modelos `mapper` con
# Jackson. En release R8 los estaba renombrando y `getInfo()` terminaba en
# "Unable to parse video information", bloqueando detalles y descargas.
-keep class com.yausername.youtubedl_android.mapper.** { *; }
-keepattributes Signature,*Annotation*

# smbj resuelve dialectos, tipos de mensaje y factorias por reflexion sobre sus
# propios enums, de modo que renombrarlos rompe la conexion en tiempo de
# ejecucion y no en compilacion.
-keep class com.hierynomus.** { *; }
-keep class net.engio.mbassy.** { *; }
-dontwarn com.hierynomus.**
-dontwarn net.engio.mbassy.**

# Bouncy Castle trae proveedores para JVM de escritorio que Android no incluye.
-keep class org.bouncycastle.jcajce.provider.** { *; }
-keep class org.bouncycastle.jce.provider.** { *; }
-dontwarn org.bouncycastle.**
-dontwarn javax.naming.**

# slf4j sin backend: smbj lo usa para registrar y en Android no hay enlace.
-dontwarn org.slf4j.**

# youtubedl-android desempaqueta sus binarios (python/yt-dlp) con
# commons-compress al iniciar. ExtraFieldUtils instancia AsiExtraField y el
# resto de los ZipExtraField por reflexion (Class.forName().newInstance())
# segun el ID de cabecera del zip; sin conservar sus constructores, R8 rompe
# esa instanciacion con "class X is not a concrete class" y
# DownloadEngineHostApi.initialize falla, dejando la busqueda de descargas sin
# resultados.
-keep class org.apache.commons.compress.archivers.zip.** { *; }
-dontwarn org.apache.commons.compress.**
