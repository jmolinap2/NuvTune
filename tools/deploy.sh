#!/usr/bin/env bash
# Compila e instala la APK release de NuvTune.
# Uso: tools/deploy.sh [ip:puerto-de-depuracion-inalambrica]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADB="${ADB:-/c/Android/Sdk/platform-tools/adb.exe}"
AAPT="${AAPT:-/c/Android/Sdk/build-tools/36.0.0/aapt.exe}"
FLUTTER="${FLUTTER:-/c/Users/USER/flutter/bin/flutter}"
DEVICE="${1:-}"

APP_NAME="NuvTune"
PACKAGE_NAME="com.nuvtune.app"

usage() {
  cat <<EOF
Uso:
  tools/deploy.sh [ip:puerto]

Ejemplos:
  tools/deploy.sh 192.168.1.108:38723
  tools/deploy.sh

Variables opcionales:
  ADB=/c/Android/Sdk/platform-tools/adb.exe
  AAPT=/c/Android/Sdk/build-tools/36.0.0/aapt.exe
  FLUTTER=/c/Users/USER/flutter/bin/flutter
EOF
}

if [[ "${DEVICE:-}" == "-h" || "${DEVICE:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "$ROOT/pubspec.yaml" ]]; then
  echo "No se encontro pubspec.yaml en $ROOT. Crea primero el proyecto Flutter de NuvTune." >&2
  exit 1
fi

for TOOL in "$ADB" "$AAPT" "$FLUTTER"; do
  if [[ ! -x "$TOOL" ]]; then
    echo "No se encontro o no se puede ejecutar: $TOOL" >&2
    echo "Actualiza ADB, AAPT o FLUTTER al inicio de tools/deploy.sh si tu ruta es distinta." >&2
    exit 1
  fi
done

if [[ -n "$DEVICE" ]]; then
  "$ADB" connect "$DEVICE" >/dev/null || true
fi

if [[ -z "$DEVICE" ]]; then
  DEVICE="$($ADB devices | awk '$2 == "device" { print $1; exit }')"
fi

if [[ -z "$DEVICE" ]]; then
  echo "No hay un dispositivo ADB conectado. Indica ip:puerto o activa la depuracion inalambrica." >&2
  exit 2
fi

cd "$ROOT"
echo "==> Compilando APK release de $APP_NAME"
"$FLUTTER" build apk --release

PUBSPEC_VERSION="$(awk '/^version:/ { print $2; exit }' pubspec.yaml)"
if [[ -z "$PUBSPEC_VERSION" ]]; then
  echo "No se encontro version en pubspec.yaml. Define algo como: version: 1.0.1+2" >&2
  exit 5
fi
VERSION_NAME="${PUBSPEC_VERSION%%+*}"
BUILD_NUMBER="${PUBSPEC_VERSION#*+}"
if [[ "$BUILD_NUMBER" == "$PUBSPEC_VERSION" || -z "$BUILD_NUMBER" ]]; then
  echo "La version debe incluir versionCode, por ejemplo: version: ${VERSION_NAME}+2" >&2
  exit 5
fi
FILE_VERSION="${VERSION_NAME}-b${BUILD_NUMBER}"

SOURCE_APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
RELEASE_APK="$ROOT/${APP_NAME}-v${FILE_VERSION}.apk"
# Carpeta compartida del telefono donde el usuario recoge las APK de todos sus
# proyectos. El apostrofo forma parte del nombre real: "APK'S - DESARROLLOS".
PHONE_DIR="/sdcard/APK'S - DESARROLLOS"
PHONE_DEST="$PHONE_DIR/${APP_NAME}-v${FILE_VERSION}.apk"

if [[ ! -f "$SOURCE_APK" ]]; then
  echo "No se encontro la APK release generada en $SOURCE_APK." >&2
  exit 3
fi

cp -f "$SOURCE_APK" "$RELEASE_APK"

if ! "$AAPT" dump badging "$RELEASE_APK" | grep -q "package: name='$PACKAGE_NAME'"; then
  echo "La compilacion no corresponde al paquete esperado $PACKAGE_NAME." >&2
  echo "Actualiza PACKAGE_NAME en tools/deploy.sh si el applicationId final es otro." >&2
  exit 4
fi

echo "==> Instalando $APP_NAME $VERSION_NAME+$BUILD_NUMBER en $DEVICE"
# HyperOS rechaza la instalacion por ADB con INSTALL_FAILED_USER_RESTRICTED si
# no se indica el usuario destino. Instalar en el usuario 0 es la via que
# acepta sin tener que abrir "Instalar via USB" en opciones de desarrollador.
"$ADB" -s "$DEVICE" install -r --user 0 "$RELEASE_APK"

# Git Bash reescribe cualquier argumento con pinta de ruta absoluta a su
# equivalente de Windows antes de entregarselo a adb.exe, de modo que
# "/sdcard/..." llegaria al telefono como "C:/Program Files/Git/sdcard/...".
# MSYS_NO_PATHCONV=1 desactiva esa reescritura para las rutas del dispositivo;
# la ruta local de la APK si necesita convertirse, y de eso se encarga cygpath.
HOST_APK="$(cygpath -m "$RELEASE_APK")"
PHONE_BACKUP_DIR="$PHONE_DIR/respaldo"
export MSYS_NO_PATHCONV=1

# El apostrofo del nombre de la carpeta obliga a distinguir dos caminos:
#
#  - "adb push" viaja por el protocolo de sincronizacion, sin pasar por ningun
#    interprete, de modo que la ruta se toma literal.
#  - "adb shell" concatena los argumentos y los ejecuta con sh en el telefono,
#    donde el apostrofo si abre una comilla. Por eso cada orden de shell se
#    manda como una sola cadena, con la ruta entre comillas dobles.
# "test -f \"$PHONE_DEST\"" solo cubre el nombre exacto de esta version: un
# bump de version (o de build) deja la APK anterior suelta en $PHONE_DIR sin
# respaldar. En su lugar, se listan TODAS las "$APP_NAME"-*.apk existentes y se
# mueven todas a respaldo/ antes del push.
EXISTING_APKS="$("$ADB" -s "$DEVICE" shell "ls -1 \"$PHONE_DIR\"/${APP_NAME}-*.apk 2>/dev/null")"
if [[ -n "$EXISTING_APKS" ]]; then
  "$ADB" -s "$DEVICE" shell "mkdir -p \"$PHONE_BACKUP_DIR\""
  while IFS= read -r REMOTE_APK; do
    REMOTE_APK="${REMOTE_APK%$'\r'}"
    [[ -z "$REMOTE_APK" ]] && continue
    # El glob no encontro nada: el shell del telefono devuelve el patron tal
    # cual en lugar de una lista vacia.
    [[ "$REMOTE_APK" == *'*.apk' ]] && continue
    BACKUP_NAME="$(basename "$REMOTE_APK" .apk)-$(date +%Y%m%d-%H%M%S).apk"
    echo "==> Respaldando la APK anterior del telefono: $(basename "$REMOTE_APK")"
    "$ADB" -s "$DEVICE" shell "mv \"$REMOTE_APK\" \"$PHONE_BACKUP_DIR/$BACKUP_NAME\""
  done <<< "$EXISTING_APKS"
fi

echo "==> Copiando la APK al telefono"
"$ADB" -s "$DEVICE" shell "mkdir -p \"$PHONE_DIR\""
"$ADB" -s "$DEVICE" push "$HOST_APK" "$PHONE_DEST"

echo "==> Verificando version instalada"
"$ADB" -s "$DEVICE" shell dumpsys package "$PACKAGE_NAME" | grep -E 'versionCode=|versionName='
echo "==> Despliegue completado: $RELEASE_APK"
