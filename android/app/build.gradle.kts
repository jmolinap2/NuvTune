plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nuvtune.app"
    compileSdk = flutter.compileSdkVersion

    // Se fija el NDK instalado en la maquina de desarrollo en lugar de heredar
    // flutter.ndkVersion, para que la compilacion de TagLib sea reproducible.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nuvtune.app"

        // Android 11 es el minimo por tres razones del requerimiento:
        //  - MediaStore.createWriteRequest permite pedir confirmacion antes de
        //    modificar un archivo ajeno (secciones 7.1 y 16).
        //  - ContentResolver.loadThumbnail entrega miniaturas de portada sin
        //    decodificar la imagen completa (seccion 17).
        //  - El almacenamiento con alcance es uniforme, sin la ruta heredada
        //    de permiso total al almacenamiento (seccion 16).
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // ABIs que compila `flutter build apk`.
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    // El motor vive en android/music_engine/ tal como describe la seccion 13
    // del requerimiento. Se agrega como source set del modulo de aplicacion en
    // lugar de como modulo Gradle independiente: un modulo aparte tendria que
    // declarar por su cuenta el artefacto de embedding de Flutter, cuya version
    // depende del hash del engine y cambia en cada actualizacion del SDK.
    sourceSets {
        getByName("main") {
            kotlin.srcDir("../music_engine/src/main/kotlin")
            res.srcDir("../music_engine/src/main/res")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("../music_engine/src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    packaging {
        // TagLib se enlaza estaticamente dentro de libnuvtune_taglib.so, asi
        // que ese .so real no depende de este ajuste. Tiene que ser `true`
        // (empaquetado "legacy", comprimido y extraido a disco) porque el
        // motor de descarga heredado de NuvClip (youtubedl-android) disfraza
        // su runtime de Python como `libpython.zip.so`/`libffmpeg.zip.so`
        // -en realidad archivos ZIP, no binarios nativos- y los abre como
        // archivo de verdad en `nativeLibraryDir` en tiempo de ejecucion. Con
        // `false` (empaquetado moderno, sin comprimir, mapeado directo desde
        // el APK) esos archivos nunca se extraen a disco y la inicializacion
        // del motor falla con `FileNotFoundException` (confirmado en
        // logcat: YoutubeDL.initPython -> ZipUtils.unzip -> libpython.zip.so
        // "No such file or directory").
        jniLibs.useLegacyPackaging = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    val media3 = "1.10.1"

    // Reproduccion, sesion multimedia y biblioteca para Android Auto.
    implementation("androidx.media3:media3-exoplayer:$media3")
    implementation("androidx.media3:media3-session:$media3")
    implementation("androidx.media3:media3-common:$media3")
    implementation("androidx.media3:media3-datasource:$media3")

    // 1.17.0 es la ultima version que compila contra compileSdk 36; a partir
    // de 1.19.0 androidx.core exige compileSdk 37 y AGP 9.1.
    implementation("androidx.core:core-ktx:1.17.0")

    // Storage Access Framework para carpetas elegidas por el usuario.
    implementation("androidx.documentfile:documentfile:1.1.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    // Cliente SMB2/SMB3 para carpetas compartidas y NAS (requerimiento 10).
    // Media3 no habla SMB, de modo que ademas hace falta un DataSource propio
    // (SmbDataSource) que traduzca smb:// a lecturas de este cliente.
    implementation("com.hierynomus:smbj:0.14.0")

    // Motor de descarga (busqueda + descarga de audio), heredado de
    // C:\Repos\NuvClip: yt-dlp + ffmpeg nativos, en vez del cliente Piped
    // anterior que no devolvia resultados descargables en la practica.
    val youtubedlAndroidVer = "0.18.1"
    implementation("io.github.junkfood02.youtubedl-android:library:$youtubedlAndroidVer")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:$youtubedlAndroidVer")

    // youtubedl-android expone `YoutubeDL.getInstance().objectMapper` (usado
    // por YtDlpEngine.search para leer el JSON crudo de "ytsearchN:", que la
    // libreria no modela como tipo propio) pero solo declara Jackson como
    // dependencia de runtime, no de compilacion: sin esto el tipo
    // ObjectMapper no resuelve en tiempo de compilacion aunque si funcione en
    // tiempo de ejecucion.
    implementation("com.fasterxml.jackson.core:jackson-databind:2.15.2")
}
