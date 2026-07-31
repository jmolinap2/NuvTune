// Puente JNI entre TagLibBridge.kt y TagLib 2.1.
//
// Todas las funciones reciben una ruta de archivo real y escribible por la
// aplicacion. El motor Kotlin nunca pasa un archivo ajeno: primero
// materializa una copia temporal propia (requerimiento seccion 7.1), escribe
// sobre ella y solo despues sustituye el original. Por eso aqui no hay
// manejo de descriptores de archivo ni de almacenamiento con alcance.

#include <jni.h>

#include <cstring>
#include <string>
#include <vector>

#include <android/log.h>

// TagLib se agrega con add_subdirectory, asi que el objetivo `tag` propaga sus
// directorios de inclusion internos y los encabezados van sin el prefijo
// "taglib/" que usaria una instalacion del sistema.
#include <fileref.h>
#include <tfile.h>
#include <tpropertymap.h>
#include <tstringlist.h>
#include <tvariant.h>
#include <audioproperties.h>

#define LOG_TAG "NuvTuneTagLib"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {

// Codigos devueltos a Kotlin. Coinciden con TagLibBridge.ResultCode.
constexpr jint kOk = 0;
constexpr jint kCannotOpen = -1;
constexpr jint kSaveFailed = -2;
constexpr jint kUnsupported = -3;

// Java entrega cadenas en UTF-8 modificado, que difiere del UTF-8 real en los
// caracteres suplementarios. Se convierte desde UTF-16 nativo para no
// corromper emojis ni escrituras fuera del plano basico.
TagLib::String toTagLibString(JNIEnv *env, jstring value) {
  if (value == nullptr) {
    return TagLib::String();
  }
  const jsize length = env->GetStringLength(value);
  if (length == 0) {
    return TagLib::String();
  }
  const jchar *chars = env->GetStringChars(value, nullptr);
  TagLib::ByteVector bytes(reinterpret_cast<const char *>(chars),
                           static_cast<unsigned int>(length) * 2);
  env->ReleaseStringChars(value, chars);
  return TagLib::String(bytes, TagLib::String::UTF16LE);
}

// TagLib guarda internamente unidades UTF-16 ensanchadas a wchar_t, asi que
// los pares surrogados sobreviven al truncamiento a jchar.
jstring toJavaString(JNIEnv *env, const TagLib::String &value) {
  const std::wstring wide = value.toWString();
  std::vector<jchar> buffer(wide.size());
  for (size_t i = 0; i < wide.size(); ++i) {
    buffer[i] = static_cast<jchar>(wide[i]);
  }
  return env->NewString(buffer.data(), static_cast<jsize>(buffer.size()));
}

std::string toUtf8Path(JNIEnv *env, jstring path) {
  const char *raw = env->GetStringUTFChars(path, nullptr);
  std::string result(raw == nullptr ? "" : raw);
  if (raw != nullptr) {
    env->ReleaseStringUTFChars(path, raw);
  }
  return result;
}

// La clave PICTURE de complexProperties unifica APIC (ID3v2),
// METADATA_BLOCK_PICTURE (Ogg/FLAC), covr (MP4) y WM/Picture (ASF).
const char *kPictureKey = "PICTURE";

}  // namespace

extern "C" {

JNIEXPORT jobjectArray JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeReadProperties(JNIEnv *env,
                                                          jclass /*clazz*/,
                                                          jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return nullptr;
  }

  const TagLib::PropertyMap properties = file.file()->properties();

  std::vector<TagLib::String> flat;
  flat.reserve(properties.size() * 2);
  for (const auto &entry : properties) {
    // Varios formatos admiten valores repetidos por clave; la aplicacion
    // muestra un solo valor por campo, asi que se unen con "; ".
    TagLib::String joined;
    bool first = true;
    for (const auto &value : entry.second) {
      if (!first) {
        joined += "; ";
      }
      joined += value;
      first = false;
    }
    flat.push_back(entry.first);
    flat.push_back(joined);
  }

  jclass stringClass = env->FindClass("java/lang/String");
  jobjectArray result =
      env->NewObjectArray(static_cast<jsize>(flat.size()), stringClass, nullptr);
  for (size_t i = 0; i < flat.size(); ++i) {
    jstring item = toJavaString(env, flat[i]);
    env->SetObjectArrayElement(result, static_cast<jsize>(i), item);
    env->DeleteLocalRef(item);
  }
  return result;
}

JNIEXPORT jint JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeWriteProperties(JNIEnv *env,
                                                           jclass /*clazz*/,
                                                           jstring path,
                                                           jobjectArray flatKeyValues) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return kCannotOpen;
  }

  TagLib::PropertyMap properties = file.file()->properties();

  const jsize count = env->GetArrayLength(flatKeyValues);
  for (jsize i = 0; i + 1 < count; i += 2) {
    auto keyString = reinterpret_cast<jstring>(
        env->GetObjectArrayElement(flatKeyValues, i));
    auto valueString = reinterpret_cast<jstring>(
        env->GetObjectArrayElement(flatKeyValues, i + 1));

    const TagLib::String key = toTagLibString(env, keyString);
    const TagLib::String value = toTagLibString(env, valueString);

    properties.erase(key);
    // Una cadena vacia significa "borrar el valor" (requerimiento 7.1).
    if (!value.isEmpty()) {
      properties.insert(key, TagLib::StringList(value));
    }

    env->DeleteLocalRef(keyString);
    env->DeleteLocalRef(valueString);
  }

  // Los campos que el formato de destino no soporta se descartan en lugar de
  // abortar la escritura completa.
  const TagLib::PropertyMap rejected = file.file()->setProperties(properties);
  if (!rejected.isEmpty()) {
    for (const auto &entry : rejected) {
      LOGE("propiedad no soportada por el formato: %s",
           entry.first.toCString(true));
    }
  }

  if (!file.file()->save()) {
    return kSaveFailed;
  }
  return kOk;
}

JNIEXPORT jlongArray JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeReadAudioProperties(JNIEnv *env,
                                                               jclass /*clazz*/,
                                                               jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), true,
                       TagLib::AudioProperties::Accurate);
  if (file.isNull() || file.audioProperties() == nullptr) {
    return nullptr;
  }

  const TagLib::AudioProperties *properties = file.audioProperties();

  // Diseno del arreglo: duracion ms, bitrate kbps, muestreo Hz, canales,
  // bits por muestra. -1 marca "no disponible en este formato".
  jlong values[5];
  values[0] = static_cast<jlong>(properties->lengthInMilliseconds());
  values[1] = static_cast<jlong>(properties->bitrate());
  values[2] = static_cast<jlong>(properties->sampleRate());
  values[3] = static_cast<jlong>(properties->channels());
  values[4] = -1;

  // La profundidad de bits solo la exponen los formatos sin perdida
  // (requerimiento 4.2: "cuando este disponible").
  const TagLib::PropertyMap properties_map = file.file()->properties();
  if (properties_map.contains("BITSPERSAMPLE")) {
    const TagLib::StringList list = properties_map["BITSPERSAMPLE"];
    if (!list.isEmpty()) {
      values[4] = static_cast<jlong>(list.front().toInt());
    }
  }

  jlongArray result = env->NewLongArray(5);
  env->SetLongArrayRegion(result, 0, 5, values);
  return result;
}

JNIEXPORT jbyteArray JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeReadPicture(JNIEnv *env,
                                                       jclass /*clazz*/,
                                                       jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return nullptr;
  }

  const TagLib::List<TagLib::VariantMap> pictures =
      file.file()->complexProperties(kPictureKey);
  if (pictures.isEmpty()) {
    return nullptr;
  }

  const TagLib::ByteVector data = pictures.front().value("data").value<TagLib::ByteVector>();
  if (data.isEmpty()) {
    return nullptr;
  }

  jbyteArray result = env->NewByteArray(static_cast<jsize>(data.size()));
  env->SetByteArrayRegion(result, 0, static_cast<jsize>(data.size()),
                          reinterpret_cast<const jbyte *>(data.data()));
  return result;
}

JNIEXPORT jstring JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeReadPictureMimeType(JNIEnv *env,
                                                               jclass /*clazz*/,
                                                               jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return nullptr;
  }

  const TagLib::List<TagLib::VariantMap> pictures =
      file.file()->complexProperties(kPictureKey);
  if (pictures.isEmpty()) {
    return nullptr;
  }

  const TagLib::String mimeType =
      pictures.front().value("mimeType").value<TagLib::String>();
  if (mimeType.isEmpty()) {
    return nullptr;
  }
  return toJavaString(env, mimeType);
}

JNIEXPORT jint JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeWritePicture(JNIEnv *env,
                                                        jclass /*clazz*/,
                                                        jstring path,
                                                        jbyteArray imageBytes,
                                                        jstring mimeType) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return kCannotOpen;
  }

  const jsize size = env->GetArrayLength(imageBytes);
  jbyte *raw = env->GetByteArrayElements(imageBytes, nullptr);
  TagLib::ByteVector data(reinterpret_cast<const char *>(raw),
                         static_cast<unsigned int>(size));
  env->ReleaseByteArrayElements(imageBytes, raw, JNI_ABORT);

  TagLib::VariantMap picture;
  picture.insert("data", data);
  picture.insert("mimeType", toTagLibString(env, mimeType));
  picture.insert("pictureType", TagLib::String("Front Cover"));
  picture.insert("description", TagLib::String());

  // Se reemplaza la lista completa: la aplicacion mantiene una sola portada
  // frontal por archivo (requerimiento 7.2).
  if (!file.file()->setComplexProperties(kPictureKey, {picture})) {
    return kUnsupported;
  }
  if (!file.file()->save()) {
    return kSaveFailed;
  }
  return kOk;
}

JNIEXPORT jint JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeRemovePicture(JNIEnv *env,
                                                         jclass /*clazz*/,
                                                         jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return kCannotOpen;
  }

  if (!file.file()->setComplexProperties(kPictureKey, {})) {
    return kUnsupported;
  }
  if (!file.file()->save()) {
    return kSaveFailed;
  }
  return kOk;
}

JNIEXPORT jboolean JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeSupportsTagWriting(JNIEnv *env,
                                                              jclass /*clazz*/,
                                                              jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return JNI_FALSE;
  }
  return file.file()->readOnly() ? JNI_FALSE : JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeSupportsPictures(JNIEnv *env,
                                                            jclass /*clazz*/,
                                                            jstring path) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), false);
  if (file.isNull() || file.file() == nullptr) {
    return JNI_FALSE;
  }
  return file.file()->complexPropertyKeys().contains(kPictureKey) ? JNI_TRUE
                                                                  : JNI_FALSE;
}

// Relee el archivo tras la escritura y confirma que las etiquetas y las
// propiedades de audio siguen siendo legibles (requerimiento 7.1: "verificar
// integridad" antes de sustituir el original).
JNIEXPORT jboolean JNICALL
Java_com_nuvtune_engine_TagLibBridge_nativeVerifyIntegrity(JNIEnv *env,
                                                           jclass /*clazz*/,
                                                           jstring path,
                                                           jlong expectedDurationMs) {
  const std::string filePath = toUtf8Path(env, path);
  TagLib::FileRef file(filePath.c_str(), true,
                       TagLib::AudioProperties::Accurate);
  if (file.isNull() || file.file() == nullptr ||
      file.audioProperties() == nullptr) {
    return JNI_FALSE;
  }
  if (!file.file()->isValid()) {
    return JNI_FALSE;
  }

  const jlong actual =
      static_cast<jlong>(file.audioProperties()->lengthInMilliseconds());
  if (actual <= 0) {
    return JNI_FALSE;
  }
  // Reescribir etiquetas puede desplazar la duracion calculada unos pocos
  // milisegundos; un cambio mayor a un segundo indica audio danado.
  if (expectedDurationMs > 0) {
    const jlong drift =
        actual > expectedDurationMs ? actual - expectedDurationMs
                                    : expectedDurationMs - actual;
    if (drift > 1000) {
      return JNI_FALSE;
    }
  }
  return JNI_TRUE;
}

}  // extern "C"
