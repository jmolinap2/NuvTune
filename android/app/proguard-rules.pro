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
