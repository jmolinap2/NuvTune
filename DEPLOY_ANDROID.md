# Deploy Android a celular

Guia para compilar NuvTune, instalarlo o actualizarlo en tu celular por ADB y
dejar una copia de la APK en el telefono. Este es el mismo flujo que usamos en
Iron Kata, pero adaptado a Flutter.

## Resumen rapido

Desde PowerShell:

```powershell
cd C:\Repos\NuvTune
& 'C:\Program Files\Git\bin\bash.exe' tools/deploy.sh 192.168.1.108:38723
```

Desde Git Bash:

```bash
cd /c/Repos/NuvTune
tools/deploy.sh 192.168.1.108:38723
```

Si el celular ya aparece conectado en `adb devices`, tambien puedes ejecutar:

```bash
tools/deploy.sh
```

## Requisitos en la PC

- Android SDK instalado.
- `adb.exe`: `C:\Android\Sdk\platform-tools\adb.exe`.
- `aapt.exe`: `C:\Android\Sdk\build-tools\36.0.0\aapt.exe`.
- Flutter instalado. El script espera:
  `/c/Users/USER/flutter/bin/flutter`.
- Git Bash instalado en:
  `C:\Program Files\Git\bin\bash.exe`.

Si alguna ruta cambia, edita estas variables al inicio de `tools/deploy.sh`:

```bash
ADB="${ADB:-/c/Android/Sdk/platform-tools/adb.exe}"
AAPT="${AAPT:-/c/Android/Sdk/build-tools/36.0.0/aapt.exe}"
FLUTTER="${FLUTTER:-/c/Users/USER/flutter/bin/flutter}"
```

## Preparar el celular

1. Abre Opciones de desarrollador.
2. Activa Depuracion USB.
3. Activa Depuracion inalambrica.
4. Entra en Depuracion inalambrica.
5. Usa el valor que dice Direccion IP y puerto.

Importante: no confundas los puertos.

- Direccion IP y puerto: se usa para deploy, por ejemplo `192.168.1.108:38723`.
- Vincular dispositivo con codigo: solo sirve para emparejar por primera vez.

El puerto cambia seguido. Si ayer era `38723` y hoy Android muestra otro, usa el
nuevo.

## Verificar conexion

Desde PowerShell:

```powershell
& 'C:\Android\Sdk\platform-tools\adb.exe' devices
```

Desde Git Bash:

```bash
/c/Android/Sdk/platform-tools/adb.exe devices
```

Debe aparecer algo asi:

```text
List of devices attached
192.168.1.108:38723    device
```

Si aparece `unauthorized`, desbloquea el telefono y acepta el permiso de
depuracion. Si aparece `offline`, apaga y prende Depuracion inalambrica o usa el
puerto nuevo.

## Ejecutar deploy completo

Antes de cada deploy de un avance, actualiza `version:` en `pubspec.yaml`.
La regla esta documentada en `VERSIONADO.md`.

Ejemplo recomendado desde PowerShell:

```powershell
cd C:\Repos\NuvTune
& 'C:\Program Files\Git\bin\bash.exe' tools/deploy.sh 192.168.1.108:38723
```

Ejemplo recomendado desde Git Bash:

```bash
cd /c/Repos/NuvTune
tools/deploy.sh 192.168.1.108:38723
```

El script hace esto:

1. Conecta con el dispositivo si pasaste `IP:puerto`.
2. Si no pasaste dispositivo, busca el primer `device` en `adb devices`.
3. Compila:

```bash
flutter build apk --release
```

4. Toma la APK de:

```text
build/app/outputs/flutter-apk/app-release.apk
```

5. Crea una copia de la APK en la raiz del repo:

```text
NuvTune-v<versionName>-b<versionCode>.apk
```

6. Verifica con `aapt dump badging` que el paquete sea:

```text
com.nuvtune.app
```

7. Instala o actualiza en el celular:

```bash
adb install -r --user 0 NuvTune-v<versionName>-b<versionCode>.apk
```

8. Copia la APK al telefono:

```text
/sdcard/APKS - DESARROLLOS/NuvTune-v<versionName>-b<versionCode>.apk
```

9. Si ya existia una copia anterior, la mueve a:

```text
/sdcard/APKS - DESARROLLOS/respaldo/
```

10. Muestra la version instalada con `dumpsys package`.

## Donde se guarda cada cosa

En la PC, la APK que genera Flutter queda aqui:

```text
C:\Repos\NuvTune\build\app\outputs\flutter-apk\app-release.apk
```

Esa APK generada es una salida temporal de build. El script la copia a la raiz
del repo con el nombre de la app y la version:

```text
C:\Repos\NuvTune\NuvTune-v<versionName>-b<versionCode>.apk
```

Ejemplo:

```text
C:\Repos\NuvTune\NuvTune-v1.0.0-b1.apk
```

En el celular, el script guarda otra copia aqui:

```text
/sdcard/APKS - DESARROLLOS/NuvTune-v<versionName>-b<versionCode>.apk
```

Ejemplo:

```text
/sdcard/APKS - DESARROLLOS/NuvTune-v1.0.0-b1.apk
```

Si ya habia una APK con el mismo nombre en el celular, antes de copiar la nueva
la mueve a:

```text
/sdcard/APKS - DESARROLLOS/respaldo/
```

La app instalada no queda como archivo visible en una carpeta normal: Android la
instala internamente dentro del sistema de paquetes. La copia visible del APK es
la de `APKS - DESARROLLOS`.

Nota: el nombre del APK usa `versionName` y `versionCode`. Por ejemplo,
`version: 1.0.1+2` genera `NuvTune-v1.0.1-b2.apk`. Ambos deben actualizarse en
cada avance que se instale.

## Ver ayuda del script

```bash
tools/deploy.sh --help
```

## Configuracion confirmada

El proyecto Flutter ya existe y los valores del script coinciden con la
compilacion real, verificado con `aapt dump badging`:

```text
package: name='com.nuvtune.app' versionCode='1' versionName='1.0.0'
application-label:'NuvTune'
sdkVersion:'30'  targetSdkVersion:'36'
native-code: 'arm64-v8a' 'armeabi-v7a' 'x86_64'
```

- `PACKAGE_NAME=com.nuvtune.app` coincide con el `applicationId`.
- `APP_NAME=NuvTune` coincide con la etiqueta de la aplicacion.
- `VERSION` se lee de `pubspec.yaml`.

Si el `applicationId` cambia, hay que actualizar `PACKAGE_NAME` antes de
instalar para que la verificacion no falle.

## Tamano de la APK

La APK release puede pesar alrededor de 60 a 70 MB porque
`flutter build apk --release` genera una APK unica con varias arquitecturas.
Eso es normal.

Para generar APKs separadas por arquitectura:

```bash
flutter build apk --release --split-per-abi
```

El script usa la APK unica a proposito, porque sirve para cualquier telefono
compatible sin tener que escoger archivo manualmente.

## Requisito de version de Android

`minSdk` es 30 (Android 11). En NuvTune esto tiene sentido por el manejo moderno
de archivos de musica, miniaturas y permisos de almacenamiento con alcance.

## Comandos manuales utiles

Conectar manualmente:

```bash
/c/Android/Sdk/platform-tools/adb.exe connect 192.168.1.108:38723
```

Ver paquete de una APK:

```bash
/c/Android/Sdk/build-tools/36.0.0/aapt.exe dump badging NuvTune-v1.0.0-b1.apk
```

Instalar manualmente:

```bash
/c/Android/Sdk/platform-tools/adb.exe install -r --user 0 NuvTune-v1.0.0-b1.apk
```

Copiar manualmente al telefono desde Git Bash:

```bash
export MSYS_NO_PATHCONV=1
/c/Android/Sdk/platform-tools/adb.exe push NuvTune-v1.0.0-b1.apk "/sdcard/APKS - DESARROLLOS/NuvTune-v1.0.0-b1.apk"
```

## Problemas comunes

`No se encontro pubspec.yaml`

Ejecutaste el script desde una carpeta que no contiene el proyecto Flutter, o el
proyecto todavia no fue creado.

`No hay un dispositivo ADB conectado`

Pasa una direccion `IP:puerto` actual:

```bash
tools/deploy.sh 192.168.1.108:38723
```

`INSTALL_FAILED_USER_RESTRICTED`

En Xiaomi/POCO/HyperOS puede pasar si Android bloquea instalaciones por ADB. El
script ya usa `--user 0`, que suele resolverlo. Si aun falla, revisa en opciones
de desarrollador si existe una opcion como Instalar via USB o permisos de
depuracion.

`INSTALL_FAILED_UPDATE_INCOMPATIBLE`

Ya hay una app instalada con el mismo paquete pero firmada con otra clave. Hay
que desinstalar esa app una vez y luego volver a ejecutar el deploy.

`La compilacion no corresponde al paquete esperado`

El `applicationId` real no coincide con `PACKAGE_NAME`. Revisa el paquete con:

```bash
/c/Android/Sdk/build-tools/36.0.0/aapt.exe dump badging build/app/outputs/flutter-apk/app-release.apk
```

Luego actualiza `PACKAGE_NAME` en `tools/deploy.sh`.

`C:/Program Files/Git/sdcard/...`

Eso es Git Bash convirtiendo rutas del telefono como si fueran rutas de Windows.
El script ya exporta `MSYS_NO_PATHCONV=1` antes de hacer `adb push` y comandos
contra `/sdcard`.

## Consideraciones

- El deploy siempre compila release, no debug.
- La copia local del APK queda en la raiz del repo.
- El telefono conserva una copia en `APKS - DESARROLLOS`.
- La carpeta `respaldo` en el telefono guarda APKs anteriores.
- El puerto de depuracion inalambrica cambia mucho; confirma el actual antes de
  pensar que el script esta mal.
