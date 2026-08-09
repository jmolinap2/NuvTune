# Deploy Android de NuvTune

NuvTune tiene un unico script de despliegue:

```powershell
pwsh tool/deploy.ps1
```

El deploy es local, genera una APK release, la instala por ADB y mantiene una
copia versionada en el almacenamiento compartido del telefono.

## Requisitos

- Flutter instalado y disponible en `PATH`, o en una de las rutas conocidas
  por `tool/deploy.ps1`.
- Android SDK con `adb` disponible en `PATH`, `C:\Android\Sdk` o el SDK del
  usuario local.
- El POCO X6 Pro vinculado previamente para depuracion inalambrica.
- El telefono y la PC conectados a la misma red.

No hace falta guardar la IP ni el puerto de depuracion. El script identifica el
telefono por modelo/producto y, si no esta conectado, busca por mDNS el puerto
que Android anuncia en ese momento.

## Version antes del deploy

Cada avance que se instale debe incrementar `version:` en `pubspec.yaml`:

```yaml
version: 1.3.2+9
```

- `1.3.2` es el `versionName` visible.
- `9` es el `versionCode` interno de Android y siempre debe aumentar.

El nombre de la APK se construye con ambos valores:

```text
NuvTune-v1.3.2-b9.apk
```

## Flujo predeterminado

Al ejecutar:

```powershell
pwsh tool/deploy.ps1
```

el script realiza, en este orden:

1. Encuentra el POCO X6 Pro conectado o lo reconecta por mDNS.
2. Ejecuta `flutter build apk --release`.
3. Copia la salida de Flutter a la raiz del repositorio con el nombre
   versionado `NuvTune-v<versionName>-b<versionCode>.apk`.
4. Instala la APK con `adb install -r --user 0`, conservando la biblioteca,
   favoritos, listas y demas datos de NuvTune.
5. Sube la APK nueva a un nombre temporal en el telefono. La APK vigente no se
   modifica si la transferencia falla.
6. Mueve todas las APK anteriores de NuvTune desde:

   ```text
   /sdcard/APK'S - DESARROLLOS/
   ```

   hacia:

   ```text
   /sdcard/APK'S - DESARROLLOS/respaldo/
   ```

7. Coloca la APK nueva, con su nombre versionado, en la carpeta principal.
8. Ordena los respaldos de NuvTune desde el mas reciente y elimina los que
   excedan el limite de cuatro.
9. Muestra el `versionName` y `versionCode` instalados.

El resultado en el telefono es:

- En `APK'S - DESARROLLOS` queda una sola APK actual de NuvTune.
- En `respaldo` quedan como maximo las cuatro APK anteriores mas recientes de
  NuvTune.
- Las APK de Iron Kata, NuvClip y los otros proyectos no se modifican.

## Acciones disponibles

```powershell
# Deploy completo release (accion predeterminada)
pwsh tool/deploy.ps1

# Mismo flujo con una APK debug
pwsh tool/deploy.ps1 -DebugBuild

# Solo identificar o reconectar el telefono
pwsh tool/deploy.ps1 -Action device

# Solo compilar
pwsh tool/deploy.ps1 -Action build

# Solo instalar la APK ya compilada
pwsh tool/deploy.ps1 -Action install

# Deploy completo, abrir NuvTune y seguir sus logs durante 30 segundos
pwsh tool/deploy.ps1 -Action run

# Mostrar errores recientes de NuvTune
pwsh tool/deploy.ps1 -Action logs

# Seguir logs durante un tiempo especifico
pwsh tool/deploy.ps1 -Action logs -Seconds 45
```

Las acciones `deploy` y `run` ejecutan el flujo completo de respaldo, copia y
rotacion. `build` e `install` son acciones parciales y no modifican la carpeta
de APK compartida del telefono.

## Seguridad de los datos

La instalacion usa `-r` para conservar los datos. Si Android informa un
conflicto de firma, el script se detiene y no desinstala NuvTune automaticamente,
porque una desinstalacion borraria sus datos locales.

La limpieza se limita estrictamente a archivos con el patron `NuvTune-*.apk`
dentro de `respaldo`. Nunca elimina APK de otros proyectos.

## Salidas

Salida original de Flutter:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Copia versionada local:

```text
NuvTune-v<versionName>-b<versionCode>.apk
```

Copia actual en el telefono:

```text
/sdcard/APK'S - DESARROLLOS/NuvTune-v<versionName>-b<versionCode>.apk
```

## Problemas comunes

### No se encuentra el telefono

Comprueba que la depuracion inalambrica este encendida y que el telefono este
en la misma red que la PC. Si Android elimino el vinculo, hay que emparejarlo
manualmente una vez.

### Conflicto de firma

La APK instalada fue firmada con otra clave. El script no la desinstala porque
eso borraria los datos. La desinstalacion debe decidirse y ejecutarse
manualmente.

### No se encuentra Flutter o ADB

Agrega la herramienta al `PATH` o actualiza las rutas candidatas en
`tool/deploy.ps1`.
