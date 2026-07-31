# Reproductor de música local — Requerimiento funcional y técnico

## 1. Objetivo

Crear una aplicación móvil moderna para reproducir y organizar música, inspirada en la simplicidad de Samsung Music y en la flexibilidad de VLC, pero dedicada exclusivamente a archivos de audio.

La aplicación debe:

- Reproducir música almacenada en el dispositivo.
- Organizar canciones por pista, álbum, artista, género, carpeta y lista.
- Funcionar con la pantalla apagada y desde los controles del sistema.
- Permitir editar metadatos e imagen de portada.
- Incluir ecualizador y herramientas de mejora perceptual del sonido.
- Reproducir múltiples formatos, no solamente MP3.
- Mantener una interfaz limpia, rápida y sin funciones de video.
- Ser completamente funcional sin cuenta ni conexión a internet.

> La aplicación puede mejorar la percepción de un MP3 mediante ecualización, compresión, normalización, expansión estéreo y procesamiento de detalle. No puede recuperar de forma exacta la información que se perdió durante la compresión original.

---

## 2. Plataforma y tecnología

### Aplicación

- **Flutter**
- **Dart**
- Material 3
- Riverpod para estado
- GoRouter para navegación
- Drift para información local de la aplicación

### Motor Android

- **Kotlin**
- **Jetpack Media3 / ExoPlayer**
- `MediaSessionService` para reproducción en segundo plano
- `MediaLibraryService` para biblioteca y Android Auto
- `MediaStore` para descubrir canciones del dispositivo
- APIs `android.media.audiofx` para efectos de audio
- Plugin Flutter propio mediante Platform Channels o Pigeon

### Metadatos

- **TagLib** integrado mediante JNI para leer y escribir:
  - Título
  - Artista
  - Álbum
  - Género
  - Año
  - Número de pista
  - Compositor
  - Letra incrustada
  - Imagen de portada

La aplicación será local. No necesita backend para su funcionamiento principal.

---

## 3. Alcance

### Incluido

- Música local.
- Archivos de audio.
- Listas de reproducción.
- Ecualizador.
- Mejora perceptual de audio.
- Edición de metadatos.
- Edición de portada.
- Reproducción en segundo plano.
- Bluetooth, auriculares y controles multimedia.
- Android Auto.
- Música desde carpetas seleccionadas.
- Fuentes musicales de red en una fase posterior.

### No incluido

- Reproducción de videos.
- Biblioteca de películas.
- Subtítulos.
- Conversión o edición de video.
- Red social.
- Tienda de música.
- Suscripción obligatoria.
- Carga automática de archivos a la nube.

La aplicación debe ignorar archivos con MIME de video, aunque contengan una pista de audio.

---

# 4. Funciones principales

## 4.1 Biblioteca musical

La aplicación escaneará la música disponible mediante `MediaStore`.

Vistas principales:

- Canciones
- Álbumes
- Artistas
- Carpetas
- Géneros
- Compositores
- Listas
- Favoritos
- Reproducidas recientemente
- Más reproducidas
- Añadidas recientemente

Cada vista permitirá:

- Buscar.
- Ordenar.
- Filtrar.
- Reproducir todo.
- Reproducir aleatoriamente.
- Agregar a la cola.
- Agregar a una lista.
- Editar información.
- Compartir el archivo.
- Ver ubicación del archivo.
- Excluir una carpeta del escaneo.

La aplicación debe recordar la posición de desplazamiento y filtros utilizados en cada sección.

---

## 4.2 Reproductor

Controles básicos:

- Reproducir y pausar.
- Canción anterior y siguiente.
- Avanzar o retroceder.
- Barra de progreso.
- Repetir canción.
- Repetir lista.
- Reproducción aleatoria.
- Favorito.
- Cola actual.
- Temporizador de apagado.
- Compartir.
- Mostrar información técnica.

Información visible:

- Portada.
- Título.
- Artista.
- Álbum.
- Duración.
- Formato.
- Bitrate.
- Frecuencia de muestreo.
- Profundidad de bits, cuando esté disponible.
- Canales.
- Tamaño del archivo.

Modos de visualización:

- Mini reproductor persistente.
- Reproductor completo.
- Vista de cola.
- Vista de letras.
- Vista de efectos de sonido.
- Vista técnica del archivo.

---

## 4.3 Cola de reproducción

La cola será editable sin detener la música.

Acciones:

- Arrastrar para cambiar el orden.
- Eliminar una canción.
- Reproducir a continuación.
- Agregar al final.
- Guardar la cola como lista.
- Limpiar la cola.
- Restaurar la última cola al abrir la aplicación.

La cola debe guardar:

- Canciones.
- Orden.
- Canción actual.
- Posición actual.
- Estado de repetición.
- Estado aleatorio.

---

## 4.4 Listas de reproducción

Tipos:

- Listas creadas por el usuario.
- Favoritos.
- Más reproducidas.
- Reproducidas recientemente.
- Añadidas recientemente.
- Listas inteligentes.

Ejemplos de listas inteligentes:

- Canciones agregadas esta semana.
- Música con calidad FLAC.
- Canciones nunca reproducidas.
- Canciones con más de cinco reproducciones.
- Música de una carpeta específica.
- Canciones sin portada.
- Canciones sin artista identificado.

Funciones:

- Crear.
- Renombrar.
- Cambiar portada.
- Ordenar manualmente.
- Duplicar.
- Exportar como M3U.
- Importar M3U.
- Compartir listado.
- Eliminar sin borrar las canciones.

---

# 5. Calidad y procesamiento de audio

## 5.1 Principio realista

Un archivo MP3 pierde información durante su compresión. La aplicación no debe afirmar que convierte mágicamente un MP3 en audio sin pérdida.

Sí puede mejorar la experiencia mediante procesamiento digital:

- Corregir frecuencias.
- Reducir sensación de sonido apagado.
- Recuperar presencia perceptual.
- Controlar picos.
- Igualar el volumen entre canciones.
- Ampliar moderadamente la imagen estéreo.
- Mejorar claridad en audífonos pequeños.
- Adaptar el sonido al tipo de salida.

El usuario podrá escuchar inmediatamente la diferencia activando o desactivando el procesamiento.

---

## 5.2 Modo “Mejorar audio”

Interruptor principal:

```text
Mejorar audio: Desactivado / Activado
```

Perfiles iniciales:

### Equilibrado

Mejora leve y segura para uso general.

### Claridad

Realza voces, detalles y frecuencias medias-altas sin exagerar agudos.

### Graves definidos

Refuerza graves, pero controla resonancias y evita saturación.

### Suave

Reduce agudos agresivos y fatiga auditiva.

### Audífonos

Ajusta graves, imagen estéreo y dinámica para auriculares.

### Altavoz del teléfono

Compensa las limitaciones del altavoz integrado y controla picos.

### Personalizado

Permite modificar todos los parámetros.

---

## 5.3 Cadena de procesamiento

Orden recomendado:

```text
Decodificación
    ↓
Ganancia previa
    ↓
Ecualizador
    ↓
Realce de detalle
    ↓
Procesamiento dinámico multibanda
    ↓
Normalización de volumen
    ↓
Expansión estéreo opcional
    ↓
Limitador
    ↓
Salida de audio
```

### Ganancia previa

Reduce o aumenta el nivel antes del ecualizador.

Debe disminuir automáticamente cuando varias bandas se elevan para evitar clipping.

### Ecualizador

- 10 bandas en el MVP.
- 15 o 20 bandas en modo avanzado.
- Presets:
  - Plano
  - Pop
  - Rock
  - Electrónica
  - Hip hop
  - Jazz
  - Clásica
  - Vocal
  - Acústica
  - Graves
  - Agudos
  - Personalizado

### Procesamiento dinámico

Se utilizará para:

- Controlar graves excesivos.
- Dar presencia a sonidos débiles.
- Evitar diferencias bruscas.
- Proteger contra saturación.
- Mejorar escucha a bajo volumen.

### Normalización

Dos modos:

- Normalización durante la reproducción.
- Análisis de volumen tipo ReplayGain almacenado localmente.

No debe modificar el archivo original salvo que el usuario solicite una exportación procesada en una futura fase.

### Realce de detalle

Procesamiento moderado para reforzar armónicos y presencia.

Debe incluir tres niveles:

- Bajo
- Medio
- Alto

El nivel alto mostrará una advertencia porque puede introducir sonido artificial en archivos de baja calidad.

### Expansión estéreo

- Desactivada por defecto.
- Intensidad controlable.
- Limitada para evitar pérdida de compatibilidad mono.
- Disponible principalmente con audífonos.

### Limitador

Siempre debe actuar al final de la cadena cuando la mejora de audio esté activa.

Su función es prevenir clipping y picos molestos.

---

## 5.4 Ecualizador por salida

La aplicación guardará configuraciones diferentes para:

- Altavoz del teléfono.
- Audífonos cableados.
- Bluetooth.
- Android Auto.
- Dispositivo USB DAC.

Al cambiar la salida, se aplicará automáticamente el perfil correspondiente.

---

## 5.5 Calidad de reproducción

Opciones:

- Reproducción sin espacios entre canciones compatibles.
- Crossfade configurable entre 0 y 12 segundos.
- Fundido al pausar y reanudar.
- Audio offload cuando sea compatible para ahorrar batería.
- Evitar remezcla o procesamiento cuando el modo directo esté activo.
- Selección de salida.
- Balance izquierda/derecha.
- Conversión a mono.
- Control de velocidad.
- Control de tono independiente de la velocidad.

### Modo directo

Desactiva mejoras y reproduce con el menor procesamiento posible.

Pensado para:

- FLAC.
- ALAC.
- WAV.
- DAC externo.
- Usuarios que prefieren señal sin efectos.

---

# 6. Formatos

Formatos prioritarios:

- MP3
- AAC
- M4A
- FLAC
- OGG Vorbis
- Opus
- WAV
- AIFF
- AMR
- WMA, cuando el dispositivo o motor lo permita
- ALAC, cuando el motor lo permita

La interfaz debe indicar cuando un formato no sea compatible con el dispositivo.

La aplicación no debe mostrar archivos de video ni tratarlos como canciones.

---

# 7. Metadatos y portada

## 7.1 Editor de información

Campos editables:

- Título
- Artista
- Artista del álbum
- Álbum
- Género
- Año
- Número de pista
- Número de disco
- Compositor
- Comentario
- Letra
- Portada

Modos:

- Editar una canción.
- Editar varias canciones.
- Aplicar artista, álbum, género o portada en lote.

Antes de guardar:

- Validar permisos.
- Crear archivo temporal.
- Escribir cambios.
- Verificar integridad.
- Sustituir el original de forma atómica.
- Solicitar nuevo escaneo de MediaStore.

No se debe sobrescribir directamente un archivo sin posibilidad de recuperación.

---

## 7.2 Editor de portada

Opciones:

- Elegir imagen de la galería.
- Tomar fotografía.
- Buscar en archivos.
- Usar una imagen copiada.
- Eliminar portada.
- Aplicar la misma portada a todo el álbum.
- Usar portada únicamente dentro de la aplicación.
- Incrustar portada en el archivo.

Edición básica:

- Recorte cuadrado.
- Rotación.
- Zoom.
- Ajuste de encuadre.
- Compresión.
- Selección de calidad.
- Previsualización.

Tamaño recomendado:

- 1000 × 1000 px.
- JPEG o PNG.
- Límite configurable para evitar archivos excesivamente grandes.

La aplicación debe distinguir entre:

- Portada incrustada en la canción.
- Portada personalizada almacenada solamente por la aplicación.
- Portada general del álbum.

---

# 8. Letras

Funciones:

- Leer letras incrustadas.
- Mostrar archivos `.lrc`.
- Letras sincronizadas.
- Desplazamiento automático.
- Ajustar desfase.
- Editar texto.
- Asociar un archivo LRC.
- Buscar manualmente dentro de archivos locales.
- Mostrar traducción como segunda línea, cuando exista.

La obtención automática desde internet quedará como integración opcional y deberá usar proveedores legales o APIs autorizadas.

---

# 9. Integración con Android

## 9.1 Segundo plano

La música continuará cuando:

- Se apague la pantalla.
- Se cambie de aplicación.
- Flutter deje de estar visible.
- El sistema recree la interfaz.

El reproductor y la sesión multimedia vivirán en un `MediaSessionService`.

---

## 9.2 Controles externos

Compatibilidad con:

- Notificación multimedia.
- Pantalla de bloqueo.
- Botones de auriculares.
- Bluetooth.
- Relojes inteligentes.
- Android Auto.
- Asistente y controles del sistema.
- Widgets de inicio.

Acciones mínimas externas:

- Reproducir.
- Pausar.
- Anterior.
- Siguiente.
- Avanzar.
- Retroceder.
- Favorito, cuando el entorno lo permita.

---

## 9.3 Audio focus

Comportamiento:

- Pausar durante llamadas.
- Bajar volumen temporalmente ante navegación o notificaciones.
- Reanudar únicamente cuando corresponda.
- No iniciar reproducción inesperadamente.
- Recordar si el usuario pausó manualmente.

---

# 10. Fuentes de música

## Fase principal

- Almacenamiento interno.
- Tarjeta SD.
- Carpetas elegidas mediante selector del sistema.

## Fase posterior

Inspirada en la flexibilidad de VLC, pero solo para audio:

- SMB / carpetas compartidas.
- NAS.
- WebDAV.
- HTTP/HTTPS.
- Radios por internet.
- Listas M3U remotas.
- Servidores compatibles con DLNA, si se incorpora un módulo específico.

Las fuentes remotas deben aparecer separadas de la biblioteca local y nunca mezclarse silenciosamente.

---

# 11. Pantallas

## Inicio

Secciones configurables:

- Continuar escuchando.
- Favoritos.
- Reproducidas recientemente.
- Álbumes recientes.
- Más reproducidas.
- Listas destacadas.

## Biblioteca

Pestañas:

- Canciones
- Álbumes
- Artistas
- Carpetas
- Listas

## Reproductor completo

- Portada grande.
- Título y artista.
- Progreso.
- Controles.
- Favorito.
- Cola.
- Letras.
- Efectos.
- Menú adicional.

## Cola

- Lista reordenable.
- Canción actual destacada.
- Guardar como lista.

## Ecualizador y mejora

- Interruptor general.
- Perfil.
- Ecualizador.
- Graves.
- Claridad.
- Normalización.
- Expansión estéreo.
- Balance.
- Comparación activado/desactivado.

## Editor de canción

- Datos.
- Portada.
- Letra.
- Información técnica.
- Guardar.
- Restaurar cambios.

## Ajustes

- Biblioteca.
- Carpetas excluidas.
- Apariencia.
- Reproducción.
- Calidad.
- Bluetooth.
- Android Auto.
- Metadatos.
- Copias de seguridad.
- Privacidad.
- Acerca de.

---

# 12. Diseño visual

Estilo recomendado:

- Interfaz oscura moderna.
- Portada como elemento visual principal.
- Colores dinámicos extraídos de la portada.
- Fondos desenfocados moderados.
- Tarjetas limpias.
- Controles grandes.
- Animaciones suaves.
- Navegación simple.
- Sin publicidad.
- Sin elementos de video.
- Sin pantallas innecesarias.

Navegación inferior:

```text
Inicio | Biblioteca | Listas | Ajustes
```

El mini reproductor permanecerá encima de la navegación cuando exista una canción cargada.

---

# 13. Arquitectura

```text
Flutter
├── app
│   ├── navigation
│   ├── theme
│   └── localization
├── core
│   ├── errors
│   ├── permissions
│   ├── platform
│   └── utils
└── features
    ├── home
    ├── library
    ├── player
    ├── queue
    ├── playlists
    ├── equalizer
    ├── metadata_editor
    ├── lyrics
    └── settings
```

Módulo Android:

```text
android/
└── music_engine/
    ├── MusicPlayerService.kt
    ├── MusicLibraryService.kt
    ├── MediaStoreRepository.kt
    ├── AudioEffectsManager.kt
    ├── AudioEnhancerProcessor.kt
    ├── MetadataEditor.kt
    ├── CoverArtEditor.kt
    └── FlutterMusicPlugin.kt
```

---

## 13.1 Responsabilidades

### Flutter

- Pantallas.
- Navegación.
- Estado visual.
- Biblioteca presentada al usuario.
- Listas y favoritos.
- Ajustes.
- Editor de portada.
- Comunicación con el motor.

### Kotlin

- Reproducción.
- Sesión multimedia.
- Servicio en segundo plano.
- Cola real.
- Audio focus.
- MediaStore.
- Efectos.
- Android Auto.
- Bluetooth.
- Escritura segura de archivos.

### TagLib

- Lectura y escritura persistente de etiquetas.
- Imágenes incrustadas.
- Propiedades de formatos compatibles.

---

# 14. Datos locales

Drift almacenará:

- Favoritos.
- Listas.
- Orden de listas.
- Historial.
- Contador de reproducciones.
- Última posición.
- Carpetas ocultas.
- Portadas internas.
- Presets.
- Perfiles por dispositivo de salida.
- Análisis de volumen.
- Preferencias.

La música no será copiada a la base de datos.

Se guardarán URI, identificadores de MediaStore y datos derivados.

---

# 15. Contrato Flutter–Android

Métodos principales:

```text
initialize
scanLibrary
getSongs
setQueue
play
pause
seek
skipNext
skipPrevious
setShuffle
setRepeatMode
setPlaybackSpeed
setPitch
setAudioProfile
setEqualizer
setAudioEnhancement
editMetadata
setCoverArt
removeCoverArt
getTechnicalInfo
```

Eventos:

```text
playbackStateChanged
currentTrackChanged
positionChanged
queueChanged
audioDeviceChanged
libraryChanged
metadataUpdated
processingStateChanged
errorOccurred
```

Pigeon es preferible a cadenas manuales de `MethodChannel`, porque permite generar contratos tipados entre Dart y Kotlin.

---

# 16. Seguridad e integridad

- No solicitar acceso total al almacenamiento sin necesidad.
- Usar MediaStore y Storage Access Framework.
- Pedir confirmación antes de modificar archivos.
- Escribir cambios mediante archivo temporal.
- Mantener copia recuperable durante la operación.
- Validar imágenes antes de incrustarlas.
- Limitar tamaño de portada.
- No borrar archivos al eliminar elementos de listas.
- Diferenciar “quitar de biblioteca” y “eliminar del dispositivo”.
- Registrar errores sin guardar nombres sensibles en servicios externos.
- Toda la biblioteca permanecerá local por defecto.

---

# 17. Rendimiento

- Escaneo incremental.
- Miniaturas en caché.
- Carga paginada.
- No decodificar portadas grandes en resolución completa.
- Reproducción y DSP fuera del hilo de interfaz.
- Audio offload cuando los efectos estén desactivados.
- Actualizar posición visual con frecuencia moderada.
- Limitar análisis de volumen en segundo plano.
- Pausar trabajos pesados con batería baja.
- Evitar reconstruir toda la biblioteca por cada cambio.

---

# 18. Fases

## Fase 1 — Reproductor funcional

- Biblioteca local.
- Canciones, álbumes, artistas y carpetas.
- Reproductor.
- Cola.
- Fondo y notificación.
- Favoritos.
- Listas.
- Tema oscuro.

## Fase 2 — Experiencia completa

- Ecualizador.
- Presets.
- Temporizador.
- Crossfade.
- Gapless.
- Letras.
- Historial.
- Más reproducidas.
- Android Auto.
- Widgets.

## Fase 3 — Edición

- Edición de metadatos.
- Portada individual.
- Portada por álbum.
- Edición en lote.
- M3U.
- Copia segura y recuperación.

## Fase 4 — Audio mejorado

- Perfiles de mejora.
- Procesamiento multibanda.
- Normalización.
- Limitador.
- Perfil por dispositivo.
- Comparación instantánea.

## Fase 5 — Capacidades tipo VLC

- SMB.
- NAS.
- WebDAV.
- Radio por internet.
- Listas remotas.
- Mayor compatibilidad de formatos.
- Sin incorporar reproducción de video.

---

# 19. Criterios de aceptación principales

1. La aplicación solo muestra y reproduce audio.
2. Puede reproducir con pantalla apagada.
3. Los controles de auriculares y Bluetooth funcionan.
4. La cola se conserva al cerrar la interfaz.
5. Puede organizar música por canción, álbum, artista y carpeta.
6. Puede crear listas y favoritos.
7. El ecualizador no provoca clipping con los presets incluidos.
8. El modo Mejorar audio puede activarse y desactivarse durante la reproducción.
9. La mejora no se presenta como recuperación real de calidad sin pérdida.
10. Puede cambiar la portada sin corromper el archivo.
11. Los cambios de etiquetas aparecen después en MediaStore.
12. El usuario puede excluir carpetas.
13. La aplicación no necesita cuenta ni backend.
14. No contiene módulos de video.
15. La reproducción permanece estable durante sesiones largas.

---

# 20. Resultado esperado

Una aplicación de música local que combine:

- La organización simple de Samsung Music.
- La compatibilidad y flexibilidad asociadas con VLC.
- Una experiencia moderna en Flutter.
- Integración nativa sólida con Android.
- Edición real de metadatos y portadas.
- Procesamiento de audio útil y transparente.
- Funcionamiento sin publicidad, cuenta ni servidor obligatorio.

Arquitectura final:

```text
Flutter
    ↓
Plugin tipado Dart–Kotlin
    ↓
Media3 + MediaSessionService
    ↓
Audio Effects / DSP
    ↓
AudioTrack y dispositivo de salida

MediaStore
    ↓
Biblioteca local

TagLib
    ↓
Metadatos y portadas
```

---

# Referencias técnicas

- Samsung Music: https://www.samsung.com/uk/support/mobile-devices/samsung-music-app/
- VLC para Android: https://www.videolan.org/vlc/download-android.html
- Jetpack Media3: https://developer.android.com/media/media3
- Reproducción en segundo plano: https://developer.android.com/media/media3/session/background-playback
- Biblioteca multimedia: https://developer.android.com/media/media3/session/serve-content
- Efectos de audio Android: https://developer.android.com/reference/android/media/audiofx/package-summary
- DynamicsProcessing: https://developer.android.com/reference/android/media/audiofx/DynamicsProcessing
- MediaStore Audio: https://developer.android.com/reference/android/provider/MediaStore.Audio
- TagLib: https://github.com/taglib/taglib
