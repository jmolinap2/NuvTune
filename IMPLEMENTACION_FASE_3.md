# Fase 3 — Audio avanzado y fuentes extendidas

Complementa `IMPLEMENTACION_FASE_1_2.md`. Recoge lo que se construyó en Fase 3,
las decisiones que se apartan de la letra del requerimiento y por qué, y lo que
queda sin verificar.

## 1. Cadena de mejora de audio (§5.1, §5.2)

### Qué se construyó

`AudioEnhancerProcessor.kt` implementa la cadena completa como un
`AudioProcessor` de Media3 encadenado justo después del ecualizador. El orden
total coincide exactamente con el del requerimiento:

```
decodificación
  → ganancia previa (anti-clipping automático)   ┐ EqualizerAudioProcessor
  → ecualizador                                   ┘   (Fase 2)
  → realce de detalle                             ┐
  → dinámica multibanda (3 bandas)                │
  → normalización de volumen                      │ AudioEnhancerProcessor
  → expansión estéreo                             │   (Fase 3)
  → limitador                                     ┘
  → velocidad y tono (SonicAudioProcessor de Media3)
  → salida
```

Detalle de cada etapa:

| Etapa | Implementación |
|---|---|
| Realce de detalle | Filtro paso alto en 5 kHz, saturación suave `tanh` para generar armónicos, remezcla en proporción baja. Cuatro niveles. |
| Dinámica multibanda | Cruces Linkwitz-Riley de 4.º orden en 250 Hz y 4 kHz. Detector de envolvente, umbral y relación por banda, con ataque y recuperación distintos por banda. |
| Normalización | Modo en vivo (media móvil de energía con corrección lenta) y modo por análisis (ganancia medida por pista). |
| Expansión estéreo | Medio/lados: el componente medio no se toca, de modo que la mezcla a mono no pierde nada. Amplitud limitada a 1,8×. |
| Limitador | Anticipación de 3 ms, ataque instantáneo y recuperación de 120 ms. |

### Decisión: DSP propio, no `DynamicsProcessing`

El plan de fases proponía `android.media.audiofx.DynamicsProcessing`. No se usó,
por la misma razón que en Fase 2 se descartó `audiofx.Equalizer`: esa API delega
en la implementación del fabricante, que no garantiza ni el número de bandas ni
las frecuencias de cruce. El resultado sonaría distinto en cada teléfono y el
requerimiento describe una cadena concreta, no "lo que el fabricante ofrezca".

El coste de la decisión es real y conviene tenerlo presente: el DSP corre en el
hilo de audio en coma flotante, sin aceleración por hardware.

### Decisión: apagar la mejora no la saca de la cadena

`isActive()` depende solo del modo directo. Con la mejora apagada el procesador
sigue en la cadena, en paso directo. Es lo que permite que la comparación A/B
del §5.1 sea instantánea: sacar el procesador obligaría a volver a preparar la
pista y se oiría un corte. El modo directo sí lo saca, y por eso es también lo
que devuelve la posibilidad de audio offload (§17).

### Decisión: los perfiles no tocan el ecualizador

Un perfil ("Equilibrado", "Audífonos", "Altavoz del teléfono"…) fija los
parámetros de la cadena de mejora, pero **no** reescribe la curva del
ecualizador. Sobrescribir la curva del usuario al elegir un perfil sería
destruir su trabajo sin avisar. La pantalla muestra los valores exactos que
aplica cada perfil, y tocar cualquiera de ellos convierte la selección en
"Personalizado" para que lo mostrado y lo que suena nunca se contradigan.

La contrapartida honesta: "Altavoz del teléfono" no compensa la falta de graves
del altavoz con una curva; se limita a comprimir más fuerte y anular la
expansión estéreo.

## 2. Normalización por análisis (§5.2)

`LoudnessAnalyzer.kt` decodifica el archivo completo con `MediaExtractor` +
`MediaCodec` y calcula RMS y pico en una sola pasada. La ganancia resultante se
recorta para que el pico no rebase el umbral del limitador: subir una pista sin
mirar su pico solo consigue que el limitador trabaje toda la canción.

Es una operación cara. La interfaz la lanza como acción explícita, canción a
canción, mostrando el progreso, y salta las que ya tienen medida.

## 3. Ecualizador por salida (§5.4)

Tabla `OutputProfiles` con la salida como clave (altavoz, cable, Bluetooth,
Android Auto, DAC USB). Guarda curva, preset, ganancia previa y perfil de
mejora.

Al cambiar de **tipo** de salida se carga el perfil guardado para ella. Si esa
salida no tiene perfil, no se toca nada: cambiar de auriculares a altavoz no
puede borrar la curva que el usuario acaba de ajustar.

## 4. Modo directo — significado final (§5.5)

Pasa de "sin efectos" a bypass explícito de toda la cadena: los dos
procesadores se declaran inactivos y Media3 los retira, con lo que la ruta de
audio offload vuelve a estar disponible.

## 5. Fuentes remotas (§10)

| Fuente | Estado | Cómo |
|---|---|---|
| HTTP/HTTPS | Completo | Nativo de Media3 |
| Radio por internet | Completo | Nativo de Media3 |
| Listas M3U remotas | Completo | Descarga y resolución de rutas relativas |
| WebDAV | Completo | `PROPFIND` con profundidad 1 y autenticación básica |
| SMB / NAS | Completo | `smbj` + `SmbDataSource` propio para Media3 |
| DLNA | **No implementado** | Ver abajo |

### SMB necesitó un `DataSource` propio

Media3 entiende `file://`, `content://` y `http(s)://`, pero no `smb://`. Sin
`SmbDataSource` habría que descargar la canción entera antes de reproducirla.
Con él se lee por bloques, la reproducción empieza de inmediato y el salto de
posición funciona. `SchemeAwareDataSource` decide por esquema **al abrir**, de
modo que una misma cola puede mezclar canciones locales y de un NAS.

Coste: `smbj` arrastra Bouncy Castle y la APK pasa de 65,9 MB a 70,4 MB.

### DLNA: decisión documentada

El requerimiento lo condiciona a "si se incorpora un módulo específico" y el
plan de fases obligaba a evaluarlo y documentar la decisión. **No se
implementa.** DLNA/UPnP exige descubrimiento SSDP, análisis de descripciones de
dispositivo y un cliente ContentDirectory; no hay biblioteca mantenida para
Android que no esté abandonada, y escribirla desde cero es un proyecto en sí
mismo. SMB y WebDAV cubren el mismo caso de uso real —música en un NAS de casa—
con protocolos que sí tienen cliente sólido.

### Separación de lo local y lo remoto

El requerimiento exige que nunca se mezclen en silencio. Se garantiza así:

- Las fuentes remotas viven en su propia pantalla, fuera de Biblioteca.
- No entran en el escaneo ni en MediaStore.
- Sus identificadores son **negativos**, derivados del hash de la URI. Los de
  MediaStore son siempre positivos, de modo que la colisión es imposible por
  construcción, no por convención.

### Credenciales

`RemoteCredentialStore.kt` cifra las contraseñas con AES/GCM usando una clave
generada en la Keystore de Android. La clave nunca sale del almacén del sistema:
una copia de seguridad restaurada en otro teléfono no puede descifrar nada. La
contraseña nunca viaja de vuelta a Flutter — el contrato solo expone
`hasPassword`. Requisito derivado de §16, no explícito en el documento original.

## 6. Letras por internet (§8)

`OnlineLyrics.kt` consulta **LRCLIB** (`lrclib.net`), proveedor abierto, gratuito
y sin clave de API, con contenido aportado por la comunidad bajo licencia libre.
Se eligió precisamente porque el requerimiento pide proveedores legales o APIs
autorizadas: raspar un servicio comercial cerrado no lo sería.

De los resultados se elige el más cercano en duración, con tolerancia de 8
segundos, para no traer la letra de un directo o un remix que no encaje con los
tiempos del archivo.

Es la única función que sale a la red por una canción local, y por eso se pide
siempre a mano, nunca de forma automática.

## 7. Formatos (§6)

WMA y ALAC ya estaban declarados en `FormatSupport.kt` y se comprueban contra
`MediaCodecList(REGULAR_CODECS)` del dispositivo real, de modo que la aplicación
informa de lo que ese teléfono puede decodificar en lugar de prometer una lista
fija. Los flujos remotos negocian formato por el mismo camino.

## 8. Cambios de esquema

Base de datos en versión **2**. La migración crea únicamente las tablas nuevas
(`EnhancementState`, `OutputProfiles`, `LoudnessAnalyses`, `SavedRadios`) y no
toca las anteriores, de modo que una instalación existente conserva favoritos,
listas, historial y cola.

## 9. Lo que no está verificado

Conviene ser explícito, porque "compila y arranca" no es lo mismo que "suena
bien":

- **La cadena DSP no tiene pruebas automatizadas ni verificación por
  instrumento.** Está verificado que compila, que se carga y que la aplicación
  reproduce con ella en la cadena. Los valores de umbral, relación y tiempos de
  cada banda son puntos de partida razonados, no medidos.
- **SMB y WebDAV no se han probado contra un servidor real** en este entorno.
  El código de listado y el `DataSource` están completos, pero no hay
  constancia de una reproducción efectiva desde un NAS.
- **La obtención de letras no se ha probado contra el servicio real.**
- El **análisis de sonoridad** no está limitado por batería. El requerimiento
  §17 pide pausar trabajos pesados con batería baja; hoy solo se lanza a mano y
  se puede cancelar saliendo de la pantalla, que no es lo mismo.
