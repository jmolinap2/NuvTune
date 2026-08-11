# Instrucciones del proyecto

- NuvTune está en pre-lanzamiento. No conservar compatibilidad con datos,
  índices, preferencias o estructuras internas de versiones que nunca se han
  publicado, salvo que el usuario la pida expresamente.
- Se permiten reestructuraciones grandes cuando simplifiquen el producto. Sí se
  deben proteger datos de desarrollo valiosos (biblioteca, favoritos, letras o
  listas) cuando hacerlo no impida la mejora solicitada.
- Jamás usar `npm`; si hace falta el ecosistema Node, usar `pnpm`.

## Detección de dispositivo Android antes de compilar/instalar/desplegar

Antes de cualquier compilación, instalación o despliegue en Android, detecta
silenciosamente el teléfono mediante ADB. No uses una IP, puerto ni serial de
transporte fijo, porque la depuración inalámbrica cambia de puerto.

ADB está en: `C:\Android\Sdk\platform-tools\adb.exe`

Dispositivo esperado:
- POCO X6 Pro 5G
- model: `2311DRK48G`
- product: `duchamp_global`
- device: `duchamp`

Procedimiento:
1. Ejecuta `adb devices -l`.
2. Si el teléfono no aparece, ejecuta `adb mdns services` y localiza los
   servicios `_adb-tls-connect._tcp`.
3. Conecta los candidatos detectados y confirma su identidad consultando
   `ro.product.model`, `ro.product.device` o los datos mostrados por
   `adb devices -l`.
4. Selecciona el dispositivo por su identidad, nunca por un puerto guardado
   anteriormente.
5. Detecta el sistema de compilación del proyecto, genera el APK
   correspondiente e instálalo con `adb -s <serial_detectado> install -r <apk>`
   (o usa `pwsh tool/deploy.ps1`, que ya implementa este procedimiento).
6. Si el proyecto genera varios APK divididos, utiliza `install-multiple`.
7. No desinstales una versión existente si hay conflicto de firma sin
   consultar primero, porque podría borrar los datos de la aplicación.

No solicites una nueva IP o puerto mientras el dispositivo continúe
vinculado, tenga activa la depuración inalámbrica y sea detectable en la
misma red. Pide intervención únicamente si se perdió la vinculación, mDNS no
encuentra el dispositivo, Android requiere un nuevo emparejamiento, o existen
varios dispositivos que no puedan distinguirse con seguridad.

Haz esta detección sin capturas de pantalla, sin abrir aplicaciones y sin
mostrar actualizaciones innecesarias. Solo informa si existe un problema que
requiera intervención del usuario.

### Si hace falta re-emparejar (pérdida de vinculación)

Cuando el usuario da un código de emparejamiento, el código y el puerto de
`_adb-tls-pairing._tcp` son de un solo uso y expiran: no reutilices un puerto
de una consulta `adb mdns services` anterior ni un código ya usado, aunque
parezca el mismo dato que antes. Antes de cada `adb pair`, vuelve a ejecutar
`adb mdns services` para obtener el puerto de emparejamiento vigente en ese
instante.

Si `adb pair` falla con `protocol fault`, casi siempre es porque el código o
el puerto ya expiraron (a veces por un intento previo, aunque haya fallado) —
pide al usuario que abra de nuevo "Vincular dispositivo con un código de
emparejamiento" para generar un código y puerto frescos, y no reintentes con
los mismos datos.

Tras un `adb pair` exitoso, `adb mdns services` puede no mostrar todavía
`_adb-tls-connect._tcp` (a veces tarda o no aparece). En ese caso usa el
IP:puerto que la propia pantalla "Depuración inalámbrica" del teléfono
muestra bajo "Dirección IP y puerto" (visible sin pedir captura si el usuario
ya la compartió) para el `adb connect`.

Un error de conexión tipo `WSAEACCES`/código `10013` ("Intento de acceso a un
socket no permitido...") en `adb connect` no significa que se perdió el
emparejamiento: normalmente lo resuelve `adb kill-server && adb start-server`
antes de reintentar el `connect`.
