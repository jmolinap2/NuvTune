# Implementacion de Fase 1 y Fase 2

Estado del codigo respecto a `plan_fases_desarrollo.md`. Este documento recoge
lo entregado y, sobre todo, las decisiones tecnicas que se desvian de la letra
del requerimiento o que resuelven algo que el requerimiento no fijaba.

Verificacion al cierre: `flutter analyze` sin incidencias, 12 pruebas unitarias
en verde, APK release compilada y verificada con `aapt` como `com.nuvtune.app`
v1.0.0.

---

## 1. Arquitectura entregada

```text
lib/
  main.dart                      arranque, orientacion y barras del sistema
  app/
    app.dart                     raiz, pantalla de arranque y permisos
    bootstrap.dart               secuencia de inicio
    navigation/                  GoRouter + shell con navegacion inferior
    theme/                       tema oscuro Material 3
    localization/                cadenas de la interfaz
  core/
    platform/                    contrato Pigeon + puente con flujos
    permissions/                 permiso de audio y notificaciones
    utils/                       formatos de duracion, tamano y frecuencia
    providers.dart               cableado de Riverpod
  data/
    db/                          14 tablas de Drift
    repositories/                9 repositorios
  features/
    home library player queue playlists equalizer metadata_editor lyrics settings
  shared/widgets/                portadas con cache, tiles, hojas de acciones

android/music_engine/
  src/main/cpp/                  TagLib 2.1 + utfcpp vendorizados + wrapper JNI
  src/main/kotlin/               17 clases del motor
  src/main/res/                  widget de inicio, Android Auto, iconos
```

`android/music_engine/` se agrega como source set del modulo `:app` en lugar de
como modulo Gradle independiente. La ruta es la que documenta la seccion 13 del
requerimiento; un modulo aparte tendria que declarar por su cuenta el artefacto
de embedding de Flutter, cuya version depende del hash del engine y cambia con
cada actualizacion del SDK.

---

## 2. Decisiones tecnicas que conviene conocer

### 2.1 El ecualizador es DSP propio, no `android.media.audiofx`

El requerimiento pide 10 bandas fijas en el MVP y 15 o 20 en modo avanzado.
`android.media.audiofx.Equalizer` expone el numero de bandas que decide cada
fabricante, normalmente cinco, y con frecuencias distintas segun el modelo. No
sirve para cumplir un numero de bandas fijo.

`EqualizerAudioProcessor` es un `AudioProcessor` de Media3 con filtros de pico
biquad en cascada (recetario de Robert Bristow-Johnson, forma directa II
transpuesta), mas ganancia previa, balance y conversion a mono. Las frecuencias
centrales son deterministas: octava ISO para 10 bandas, dos tercios de octava
para 15 y media octava para 20. El factor de calidad se deriva del ancho de
banda con `Q = 2^(N/2) / (2^N - 1)`.

Ventaja adicional: es el sitio donde encaja la cadena completa de Fase 3
(dinamica multibanda, normalizacion, expansion estereo, limitador).

### 2.2 Antisaturacion de los presets

La ganancia previa efectiva descuenta la banda con mas refuerzo cuando
"evitar saturacion automaticamente" esta activo. Ningun preset incluido pasa de
+6 dB en una banda, asi que con esa resta el criterio de aceptacion 7 se cumple
por construccion, no por casualidad.

### 2.3 El modo directo es el interruptor que decide la cadena, no el ecualizador

`AudioProcessor.isActive()` se consulta al construir la cadena de audio, no en
cada bloque. Si el ecualizador entrase y saliese de la cadena, activarlo durante
la reproduccion exigiria volver a preparar la pista.

La solucion es que el procesador este siempre en la cadena salvo en modo
directo, y que dentro aplique ganancia unidad cuando el ecualizador esta
apagado. Consecuencias, ambas alineadas con el requerimiento:

- Activar y desactivar el ecualizador es inmediato, sin cortes.
- El audio offload solo se pide en modo directo, que es exactamente lo que dice
  la seccion 17: offload cuando los efectos estan desactivados.

Cambiar el modo directo si vuelve a preparar la pista, conservando la posicion.

### 2.4 Crossfade con reproductor secundario

Media3 no tiene crossfade y un solo `ExoPlayer` no puede solapar dos pistas.
`FadeController` crea un reproductor secundario que vive solo durante la ventana
de solape y adelanta la pista siguiente. La sesion multimedia permanece siempre
en el reproductor principal, de modo que la cola, la reproduccion sin espacios y
los controles externos siguen siendo los nativos de Media3.

Al terminar la pista, el principal avanza por si mismo a la que ya sonaba en el
secundario; se le lleva a la posicion alcanzada y se sube su volumen. El salto
es inaudible porque el principal esta en silencio durante el reajuste.

Con crossfade en cero no se crea ningun reproductor secundario, que es la
configuracion por omision y la que permite gapless nativo.

Limitacion conocida: durante el solape la notificacion sigue mostrando la pista
saliente hasta el limite real entre pistas.

### 2.5 Gapless

`ExoPlayer` ya reproduce sin espacios los formatos que declaran su relleno de
codificador (Xing/LAME en MP3, iTunSMPB en AAC, y de forma nativa FLAC, Opus,
Vorbis, ALAC y PCM). No hace falta interruptor para eso.

Lo que si controla el ajuste "reproduccion sin espacios" es `skipSilenceEnabled`,
que elimina el silencio que arrastran los demas formatos en el limite entre
pistas. Es la parte que realmente es configurable.

### 2.6 Escritura de etiquetas: recuperable, no atomica del sistema de archivos

El requerimiento pide sustituir el original "de forma atomica". En Android 11 no
existe forma de renombrar un archivo de medios ajeno dentro de su propia
carpeta, que es lo que daria atomicidad real del sistema de archivos.

Lo que `MetadataEditor` garantiza, y es lo que exige la seccion 16, es que en
ningun momento se sobrescribe el original sin tener una copia recuperable:

1. Validar permisos, con `MediaStore.createWriteRequest` si el sistema lo pide.
2. Copia de respaldo del original y copia de trabajo, ambas en la cache.
3. TagLib escribe sobre la copia de trabajo.
4. Verificacion de integridad: el archivo se relee y se comprueba que sigue
   siendo decodificable y que su duracion no se desvio mas de un segundo.
5. Sustitucion del original. Si la escritura falla a mitad, se restaura desde el
   respaldo antes de devolver el error.
6. Nuevo escaneo de MediaStore.

TagLib solo trabaja sobre archivos que la aplicacion posee, con rutas reales.
Por eso el wrapper JNI no necesita manejar descriptores ni almacenamiento con
alcance.

### 2.7 Portadas: `complexProperties` de TagLib 2.1

La clave `PICTURE` de `complexProperties` unifica APIC de ID3v2,
METADATA_BLOCK_PICTURE de Ogg y FLAC, `covr` de MP4 y WM/Picture de ASF. Un solo
camino de codigo cubre todos los formatos del alcance.

Las cadenas se convierten desde UTF-16 nativo y no con `GetStringUTFChars`,
porque el UTF-8 modificado de Java codifica los caracteres suplementarios como
pares surrogados CESU-8 y corromperia los emojis en las etiquetas.

### 2.8 Deteccion de portada por album

`hasCover` se resuelve una vez por album y no por cancion: los albumes son
ordenes de magnitud menos numerosos y `loadThumbnail` genera y guarda en cache
la miniatura la primera vez.

Consecuencia asumida: en un album donde solo algunas pistas traen portada, todas
quedan marcadas igual. La lista inteligente "canciones sin portada" trabaja por
lo tanto con granularidad de album, y la propia pantalla lo dice.

### 2.9 Numero de disco sin la columna `DISC_NUMBER`

`MediaStore.Audio.AudioColumns.DISC_NUMBER` existe a partir de API 31. Para no
subir el minimo, el numero de disco se decodifica de la columna `TRACK`, que el
escaner de medios de Android rellena como `disco * 1000 + pista`.

### 2.10 Archivos que no son medios (`.lrc`, `.m3u`)

El almacenamiento con alcance no deja leer por ruta un `.lrc` que este junto a
una cancion, ni aparece en MediaStore. `SafManager` traduce una ruta del sistema
de archivos al URI de documento equivalente dentro de una carpeta ya concedida
por el usuario.

Orden de resolucion de letras: correccion guardada en NuvTune, luego `.lrc`
adyacente si la carpeta esta concedida, luego letra incrustada en las etiquetas.
Si no hay carpeta concedida, la letra que el usuario escriba queda en el
almacenamiento privado de la aplicacion.

### 2.11 Selector de carpetas y de archivos nativo, no `file_picker`

`file_picker` se resolvia a la version 3.0.4 por conflictos de dependencias, y
no concede permisos persistentes sobre el arbol elegido. El selector se
implemento con `ACTION_OPEN_DOCUMENT_TREE` y `takePersistableUriPermission`, que
es lo que pide la seccion 16: usar MediaStore y Storage Access Framework.

Compartir tambien es nativo, porque enviar un archivo de MediaStore exige pasar
su URI de contenido con permiso de lectura concedido al receptor.

### 2.12 Favoritos en el boton de la notificacion

Los favoritos viven en la base de datos de Flutter, que el motor no conoce. El
boton de la notificacion, de la pantalla de bloqueo y de Android Auto emite un
comando de sesion personalizado; Flutter alterna el favorito y devuelve el
estado nuevo con `setFavoriteState` para que el icono se dibuje bien.

### 2.13 Riverpod 2.6, no 3.x

`drift_dev` exige `analyzer ^13.0.0` y `riverpod 3.x` arrastra `test ^1.0.0`,
que choca con esa restriccion y con los paquetes fijados por `flutter_test`. Se
usa Riverpod 2.6.1, que ya tiene `Notifier` y `AsyncNotifier`.

Pigeon no es dependencia de desarrollo por el mismo conflicto de `analyzer`: se
invoca como herramienta global y `pigeons/` esta excluido del analizador.

### 2.14 Generos y compositores no son pestanas

La pantalla Biblioteca del requerimiento seccion 11 define cinco pestanas
(Canciones, Albumes, Artistas, Carpetas, Listas). Generos y compositores se
resuelven como agrupaciones, accesibles desde el menu de la barra superior.

### 2.15 Arbol de Android Auto

Solo se exponen las agrupaciones que MediaStore puede resolver por si solo:
canciones, albumes, artistas y carpetas. Las listas, los favoritos y el
historial viven en la base de datos de Flutter y no estan disponibles cuando la
interfaz no se ha abierto, asi que no forman parte del arbol.

---

## 3. Cobertura del requerimiento

### Fase 1

| Requisito | Donde |
|---|---|
| Escaneo por MediaStore ignorando MIME de video | `MediaStoreRepository` |
| Canciones, albumes, artistas, carpetas | `library_screen.dart` |
| Buscar, ordenar, filtrar, reproducir todo, aleatorio | `sort_filter_bar.dart`, `LibraryRepository.query` |
| Agregar a cola, a lista, compartir, ver ubicacion, excluir carpeta | `song_actions_sheet.dart` |
| Recordar orden y filtro por seccion | `AppSettings.librarySortJson` |
| Controles del reproductor y avance relativo | `player_screen.dart` |
| Informacion tecnica completa | `TechnicalInfo` + TagLib |
| Mini reproductor, reproductor completo, cola, vista tecnica | `mini_player.dart`, `player_screen.dart`, `queue_list.dart` |
| Cola editable con arrastre y persistencia completa | `queue_list.dart`, `QueueRepository` |
| Listas: crear, renombrar, portada, orden manual, duplicar, eliminar | `PlaylistRepository`, `playlist_actions.dart` |
| Favoritos | `FavoritesRepository` |
| Segundo plano en `MediaSessionService` | `MusicPlayerService` |
| Notificacion, pantalla de bloqueo, auriculares, Bluetooth | Media3 session + `MediaButtonReceiver` |
| Audio focus completo | `ExoPlayer` con `handleAudioFocus` y `handleAudioBecomingNoisy` |
| Almacenamiento interno, SD y carpetas del selector | MediaStore + `SafManager` |
| Tema oscuro y navegacion inferior | `AppTheme`, `RootShell` |

### Fase 2

| Requisito | Donde |
|---|---|
| Generos y compositores | `LibraryRepository.genres/composers` |
| Reproducidas recientemente, mas reproducidas, anadidas recientemente | `HistoryRepository`, `song_collection_screen.dart` |
| Editor de etiquetas con los 12 campos | `song_editor_screen.dart` |
| Edicion en lote | `batch_editor_screen.dart` |
| Escritura segura con verificacion y restauracion | `MetadataEditor` |
| Editor de portada: galeria, camara, archivos, portapapeles, quitar | `cover_picker.dart`, `CoverArtEditor` |
| Recorte, rotacion, zoom, encuadre, compresion, calidad | recortador nativo, limite 1500 px y 1,5 MB |
| Tres origenes de portada diferenciados | `CoverRepository` + `CustomCovers` |
| Letras incrustadas, `.lrc`, sincronizadas, desfase, edicion, traduccion | `LrcParser`, `lyrics_view.dart` |
| Listas inteligentes (las siete) | `smart_playlists.dart` |
| Exportar, importar y compartir M3U | `m3u.dart`, `playlist_actions.dart` |
| Gapless, crossfade 0-12 s, fundido, offload, modo directo | `AudioEffectsManager`, `FadeController` |
| Balance, mono, velocidad, tono independiente | `EqualizerAudioProcessor`, `PlaybackParameters` |
| Ecualizador 10 bandas y presets | `EqualizerAudioProcessor`, `equalizer_screen.dart` |
| Temporizador de apagado | `SleepTimer` |
| Android Auto | `MusicLibraryCallback` |
| Widget de inicio | `NuvTuneWidgetProvider` |

### Criterios de aceptacion

Cubiertos por esta entrega: 1 a 7 (el 7 con los presets de 10 bandas), 10 a 15.

Los criterios 8 y 9 se refieren al modo "Mejorar audio", que es Fase 3. La
pantalla del ecualizador ya muestra el aviso que exige el criterio 9 y dice
explicitamente que la cadena de mejora perceptual todavia no existe, en lugar de
presentar controles que no hacen nada.

---

## 4. Fuera de esta entrega

Todo lo asignado a Fase 3 en `plan_fases_desarrollo.md`:

- Modo "Mejorar audio" y sus siete perfiles.
- Ganancia previa con realce de detalle, dinamica multibanda, normalizacion tipo
  ReplayGain, expansion estereo y limitador.
- Ecualizador de 15 y 20 bandas: el motor los acepta y calcula sus frecuencias,
  y la interfaz permite elegirlos; lo que falta de Fase 3 son los perfiles por
  dispositivo de salida.
- Perfiles guardados por salida de audio.
- Comparacion instantanea activado/desactivado del procesamiento.
- Fuentes remotas: SMB, NAS, WebDAV, HTTP, radio y listas M3U remotas.
- Obtencion automatica de letras desde internet.
