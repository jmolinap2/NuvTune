# Plan de fases de desarrollo — NuvTune

Este documento reorganiza `requerimiento_reproductor_musica_flutter.md` en **3 fases**, de modo que cada requisito del documento original quede asignado exactamente a una fase. No existe una "fase 4" ni backlog residual: todo lo descrito en el requerimiento cae dentro de Fase 1, 2 o 3.

## 0. Criterio de agrupación

El requerimiento original (sección 18) ya proponía 5 fases. Para llegar a 3 sin perder nada se fusionaron así:

| Fases originales (doc. §18) | Fase nueva |
|---|---|
| Fase 1 — Reproductor funcional | **Fase 1 — Núcleo funcional** |
| Fase 2 — Experiencia completa + Fase 3 — Edición | **Fase 2 — Experiencia completa y edición** |
| Fase 4 — Audio mejorado + Fase 5 — Capacidades tipo VLC | **Fase 3 — Audio avanzado y fuentes extendidas** |

Razón de cada fusión:
- **Fase 2**: "experiencia" (ecualizador básico, letras, historial, Android Auto, widgets) y "edición" (metadatos, portada, M3U) no tienen dependencia técnica entre sí, pero ambas requieren que el núcleo de reproducción (Fase 1) ya exista y ambas son trabajo de "producto completo" antes de tocar procesamiento de señal avanzado.
- **Fase 3**: el procesamiento DSP avanzado (multibanda, normalización, perfiles por salida) y las fuentes remotas (SMB/WebDAV/radio) son, según el propio documento (secciones 3 y 10), explícitamente "una fase posterior" / la fase más avanzada — se agrupan como el trabajo opcional/avanzado que se apoya sobre un producto ya completo y editable.

Todas las secciones transversales (arquitectura, contrato Dart–Kotlin, datos locales, seguridad, rendimiento, pantallas, criterios de aceptación) se reparten dentro de cada fase — ver la matriz de trazabilidad al final.

---

## Fase 1 — Núcleo funcional

### Objetivo
Un reproductor de música local completamente operativo: biblioteca, reproducción en segundo plano, cola persistente, listas básicas y favoritos. Sin edición de metadatos, sin ecualizador, sin fuentes remotas.

### Alcance funcional

**Biblioteca musical (§4.1)**
- Escaneo vía `MediaStore`, ignorando cualquier archivo con MIME de video (aunque tenga pista de audio).
- Vistas: Canciones, Álbumes, Artistas, Carpetas.
- Por vista: buscar, ordenar, filtrar, reproducir todo, reproducir aleatoriamente, agregar a la cola, agregar a una lista, compartir archivo, ver ubicación del archivo, excluir una carpeta del escaneo.
- Recordar posición de scroll y filtros por sección.
- **Resolución explícita**: Género y Compositor (listados en §4.1 como "vistas principales") **no** son pestañas de nivel superior — la pantalla Biblioteca de la §11 solo define 5 pestañas (Canciones/Álbumes/Artistas/Carpetas/Listas). Género y Compositor se implementan como filtros/agrupación dentro de "Canciones" en **Fase 2**, cuando ya existe metadata enriquecida vía TagLib.
- "Editar información" (acción de biblioteca) **no** se activa en esta fase — el botón puede existir en el menú contextual pero deshabilitado/oculto hasta Fase 2.

**Reproductor (§4.2)**
- Controles: reproducir/pausar, anterior/siguiente, avanzar/retroceder (seek), barra de progreso, repetir canción, repetir lista, aleatorio, favorito, ver cola actual, compartir.
- Información visible completa: portada, título, artista, álbum, duración, formato, bitrate, frecuencia de muestreo, profundidad de bits (si está disponible), canales, tamaño de archivo — vía `getTechnicalInfo`.
- Modos de visualización entregados: mini reproductor persistente, reproductor completo, vista de cola, vista técnica del archivo.
- **No** incluidos aún: temporizador de apagado, vista de letras, vista de efectos (llegan en Fase 2/3).

**Cola de reproducción (§4.3)** — completa en esta fase:
- Arrastrar para reordenar, eliminar canción, reproducir a continuación, agregar al final, guardar cola como lista, limpiar cola, restaurar última cola al abrir la app.
- Persistencia en Drift: canciones, orden, canción actual, posición, estado de repetición, estado aleatorio.

**Listas de reproducción (§4.4)** — solo el subconjunto básico:
- Crear, renombrar, cambiar portada (imagen elegida manualmente, sin editor de recorte todavía), ordenar manualmente, duplicar, eliminar sin borrar canciones.
- Favoritos (marcar/desmarcar y vista de favoritos).
- **No** incluidos aún: listas inteligentes, más reproducidas, reproducidas recientemente, añadidas recientemente, exportar/importar M3U, compartir listado (dependen de historial o de generación de archivos — Fase 2).

**Integración con Android (§9)**
- Segundo plano vía `MediaSessionService`: sobrevive apagado de pantalla, cambio de app, Flutter oculto, recreación de UI.
- Controles externos: notificación multimedia, pantalla de bloqueo, botones de auriculares, Bluetooth básico, asistente/controles del sistema. Acciones mínimas: reproducir, pausar, anterior, siguiente, avanzar, retroceder, favorito (si el entorno lo permite).
- Audio focus completo: pausar en llamadas, bajar volumen ante notificaciones/navegación, reanudar solo cuando corresponde, no iniciar reproducción inesperadamente, recordar pausa manual del usuario.
- **No** incluidos aún: Android Auto, relojes inteligentes (llegan como verificación dedicada en Fase 2, aunque técnicamente se apoyan en el `MediaSessionService` de esta fase), widgets de inicio (Fase 2).

**Fuentes de música (§10)**
- Solo "fase principal": almacenamiento interno, tarjeta SD, carpetas elegidas mediante selector del sistema (SAF).

**Formatos (§6)**
- Soporte nativo de Media3/ExoPlayer: MP3, AAC, M4A, FLAC, OGG Vorbis, Opus, WAV, AIFF.
- AMR, WMA y ALAC quedan condicionados ("cuando el motor lo permita") y se confirman/pulen en Fase 2; la extensión de compatibilidad adicional es Fase 3 (§18 Fase 5 original: "Mayor compatibilidad de formatos").

### Pantallas entregadas (§11)
- **Inicio** (versión parcial): Continuar escuchando, Favoritos, Álbumes recientes (por fecha de adición, sin necesitar historial), Listas destacadas. Las secciones "Reproducidas recientemente" y "Más reproducidas" se agregan en Fase 2 cuando exista el historial.
- **Biblioteca**: pestañas Canciones, Álbumes, Artistas, Carpetas, Listas.
- **Reproductor completo**: portada, título/artista, progreso, controles, favorito, cola, menú adicional. (Pestañas "Letras" y "Efectos" no existen todavía.)
- **Cola**: lista reordenable, canción actual destacada, guardar como lista.
- **Ajustes** (subconjunto): Biblioteca (control de escaneo), Carpetas excluidas, Apariencia (tema oscuro), Privacidad (aviso de funcionamiento 100% local, sin cuenta), Acerca de.

### Arquitectura y contrato Dart–Kotlin
- Se crea el **esqueleto completo** de carpetas Flutter (`app/`, `core/`, y todas las carpetas bajo `features/` de la §13, incluidas `equalizer/`, `metadata_editor/`, `lyrics/` vacías) y el esqueleto completo de `android/music_engine/` con todas las clases de la §13 declaradas (aunque varias queden como stub sin lógica).
- Implementadas en esta fase: `MusicPlayerService.kt`, `MediaStoreRepository.kt`, `FlutterMusicPlugin.kt`, `MusicLibraryService.kt` (versión básica, sin Android Auto todavía).
- Contrato Pigeon (§15), métodos: `initialize`, `scanLibrary`, `getSongs`, `setQueue`, `play`, `pause`, `seek`, `skipNext`, `skipPrevious`, `setShuffle`, `setRepeatMode`, `getTechnicalInfo`.
- Eventos: `playbackStateChanged`, `currentTrackChanged`, `positionChanged`, `queueChanged`, `libraryChanged`, `errorOccurred`.

### Datos locales (Drift, §14)
- Favoritos, Listas, Orden de listas, Última posición (persistencia de cola), Carpetas ocultas (exclusión de escaneo), Preferencias básicas.

### Seguridad y rendimiento
- Seguridad (§16): permisos mínimos vía MediaStore/SAF (sin acceso total al almacenamiento), biblioteca local por defecto, no borrar archivos al quitar de una lista, diferenciar "quitar de biblioteca" vs "eliminar del dispositivo", registro de errores sin datos sensibles.
- Rendimiento (§17): escaneo incremental, carga paginada, miniaturas en caché, no decodificar portadas en resolución completa, reproducción y decodificación fuera del hilo de UI, actualización de posición visual con frecuencia moderada, no reconstruir toda la biblioteca por cada cambio, ruta de audio offload por defecto (no hay efectos DSP todavía que la bloqueen).
- Diseño visual base (§12): tema oscuro, navegación inferior (`Inicio | Biblioteca | Listas | Ajustes`), mini reproductor persistente sobre la navegación, tarjetas limpias, controles grandes, sin publicidad ni elementos de video.

### Criterios de aceptación cubiertos (§19)
1, 2, 3, 4, 5, 6, 12, 13, 14, y 15 (estabilidad en sesiones largas, validada aquí y revalidada en cada fase siguiente).

### Explícitamente fuera de esta fase
Ecualizador, mejora de audio, edición de metadatos/portada, letras, temporizador, crossfade/gapless, Android Auto, widgets, listas inteligentes, historial/más reproducidas, M3U, fuentes remotas.

---

## Fase 2 — Experiencia completa y edición

### Objetivo
Convertir el núcleo funcional en un producto completo: ecualizador básico, letras, historial, Android Auto/widgets, edición real de metadatos y portadas, y todas las funciones de calidad de reproducción que no dependen del motor DSP avanzado.

### Alcance funcional

**Biblioteca — ampliación (§4.1)**
- Vistas Géneros y Compositores, implementadas como filtro/agrupación sobre "Canciones" (ver resolución de Fase 1), habilitadas ahora porque TagLib ya expone compositor de forma fiable.
- Acción "Editar información" habilitada en los menús contextuales de biblioteca, abre el editor de metadatos.
- Vistas derivadas de historial: Reproducidas recientemente, Más reproducidas, Añadidas recientemente.

**Metadatos y portada (§7 completo)**
- Integración de **TagLib vía JNI** (`MetadataEditor.kt`, `CoverArtEditor.kt`).
- Editor de información: campos título, artista, artista del álbum, álbum, género, año, número de pista, número de disco, compositor, comentario, letra, portada.
- Modos: edición individual, edición múltiple (lote), aplicar artista/álbum/género/portada en lote.
- Flujo seguro de guardado: validar permisos → archivo temporal → escribir cambios → verificar integridad → sustitución atómica → solicitar reescaneo de MediaStore. Nunca sobrescritura directa sin posibilidad de recuperación.
- Editor de portada: elegir de galería, tomar foto, buscar en archivos, usar imagen copiada, eliminar portada, aplicar portada a todo el álbum, portada solo-app vs. incrustada en archivo. Edición básica: recorte cuadrado, rotación, zoom, ajuste de encuadre, compresión, selección de calidad, previsualización. Tamaño recomendado 1000×1000, JPEG/PNG, límite configurable.
- La app distingue tres tipos de portada: incrustada en la canción, personalizada solo-app, y portada general de álbum.

**Letras (§8)** — completo excepto obtención automática por internet:
- Leer letras incrustadas, mostrar archivos `.lrc`, letras sincronizadas con desplazamiento automático, ajustar desfase, editar texto, asociar archivo LRC, buscar manualmente en archivos locales, mostrar traducción como segunda línea cuando exista.
- La obtención automática de letras desde internet (proveedores legales/APIs autorizadas) se implementa en **Fase 3**, junto con el resto de integraciones dependientes de red.

**Listas de reproducción — resto de funciones (§4.4)**
- Listas inteligentes: agregadas esta semana, calidad FLAC, nunca reproducidas, más de 5 reproducciones, de una carpeta específica, sin portada, sin artista identificado.
- Exportar como M3U, importar M3U, compartir listado.

**Cola de reproducción del reproductor completo**
- Pestaña "Letras" dentro del Reproductor completo (usa el módulo de letras de esta fase).
- Pestaña "Efectos" dentro del Reproductor completo, con el ecualizador básico de esta fase (la versión avanzada llega en Fase 3).

**Calidad de reproducción — §5.5 completo** (no depende del motor de mejora avanzado):
- Reproducción sin espacios (gapless) entre canciones compatibles.
- Crossfade configurable de 0 a 12 segundos.
- Fundido al pausar/reanudar.
- Audio offload cuando sea compatible.
- Modo directo (mínimo procesamiento posible — pensado para FLAC/ALAC/WAV/DAC externo; en esta fase equivale a "sin efectos" porque el motor de mejora aún no existe; en Fase 3 pasa a significar "bypass explícito del DSP avanzado").
- Selección de salida de audio, balance izquierda/derecha, conversión a mono, control de velocidad, control de tono independiente de la velocidad.

**Ecualizador básico (§5.3, parcial)**
- 10 bandas (MVP), presets: Plano, Pop, Rock, Electrónica, Hip hop, Jazz, Clásica, Vocal, Acústica, Graves, Agudos, Personalizado.
- El modo avanzado (15/20 bandas) y el ecualizador por dispositivo de salida (§5.4) se implementan en Fase 3.

**Integración con Android — resto (§9.2)**
- Android Auto (`MediaLibraryService` completo).
- Widgets de inicio.
- Verificación dedicada de compatibilidad con relojes inteligentes (funcionalidad ya presente desde Fase 1 vía `MediaSessionService`/Bluetooth; aquí se certifica formalmente junto con Android Auto).

**Temporizador de apagado** (§4.2).

### Pantallas entregadas (§11)
- **Inicio**: se completan las secciones "Reproducidas recientemente" y "Más reproducidas" (ya hay historial); pantalla de Inicio queda funcionalmente completa.
- **Reproductor completo**: se agregan pestañas Letras y Efectos (básico).
- **Ecualizador y mejora** (parcial): Ecualizador y selección de Perfil (shell de navegación; los perfiles reales de mejora llegan en Fase 3).
- **Editor de canción**: Datos, Portada, Letra, Información técnica (reutiliza componente de Fase 1), Guardar, Restaurar cambios.
- **Ajustes** (resto): Reproducción (gapless/crossfade/velocidad/tono), Calidad, Bluetooth, Android Auto, Metadatos, Copias de seguridad (export/import M3U como respaldo de listas).
- **Diseño visual** (§12, refinamiento): colores dinámicos extraídos de la portada, fondos desenfocados moderados, animaciones suaves.

### Arquitectura y contrato Dart–Kotlin
- Se completan los módulos `playlists`, `metadata_editor`, `lyrics`, `equalizer` (básico) y se amplía `settings`.
- `MusicLibraryService.kt` pasa a implementación completa (Android Auto). `AudioEffectsManager.kt` (EQ básico), `MetadataEditor.kt`, `CoverArtEditor.kt` implementados.
- Contrato Pigeon — se agregan: `editMetadata`, `setCoverArt`, `removeCoverArt`, `setEqualizer` (10 bandas), `setPlaybackSpeed`, `setPitch`.
- Eventos agregados: `metadataUpdated`, `audioDeviceChanged` (detección básica de salida, usada para mostrar el dispositivo activo en Ajustes; el cambio automático de perfil según salida es Fase 3).

### Datos locales (Drift, §14)
- Historial, Contador de reproducciones, Portadas internas (almacenamiento de portadas personalizadas solo-app), Presets de ecualizador.

### Seguridad y rendimiento
- Seguridad (§16): confirmación antes de modificar archivos, escritura vía archivo temporal, copia recuperable durante la operación, validación de imágenes antes de incrustar, límite de tamaño de portada.
- Rendimiento (§17): sin adiciones nuevas más allá de mantener los presupuestos de Fase 1 al añadir historial/EQ (el análisis de volumen en segundo plano llega en Fase 3).

### Criterios de aceptación cubiertos (§19)
7 (parcial — sin clipping con los presets básicos incluidos), 10, 11.

### Explícitamente fuera de esta fase
Modo "Mejorar audio" y sus perfiles, cadena DSP multibanda, normalización, expansión estéreo, limitador, ecualizador por dispositivo de salida, modo avanzado de EQ (15/20 bandas), obtención automática de letras por internet, y todas las fuentes remotas (SMB/NAS/WebDAV/HTTP/radio/M3U remoto/DLNA).

---

## Fase 3 — Audio avanzado y fuentes extendidas

### Objetivo
Añadir el motor de mejora perceptual de audio completo y extender las fuentes de música más allá del almacenamiento local, sin tocar reproducción de video en ningún momento.

### Alcance funcional

**Modo "Mejorar audio" (§5.1, §5.2, §5.3 resto)**
- Interruptor general Mejorar audio: Desactivado/Activado, con comparación instantánea A/B.
- Perfiles: Equilibrado, Claridad, Graves definidos, Suave, Audífonos, Altavoz del teléfono, Personalizado (edición de todos los parámetros).
- Cadena de procesamiento completa, en orden: decodificación → ganancia previa (con reducción automática anti-clipping cuando varias bandas se elevan) → ecualizador → realce de detalle (niveles bajo/medio/alto, con advertencia en "alto" sobre posible sonido artificial en archivos de baja calidad) → procesamiento dinámico multibanda → normalización de volumen (modo en vivo + análisis tipo ReplayGain almacenado localmente) → expansión estéreo opcional (desactivada por defecto, intensidad controlable, limitada para preservar compatibilidad mono, pensada para audífonos) → limitador (siempre activo al final de la cadena cuando la mejora está activa) → salida de audio.
- Ecualizador modo avanzado: 15 o 20 bandas.
- Mensajería de UI explícita: la app nunca debe presentar la mejora como recuperación real de calidad sin pérdida (principio de §5.1/§18 criterio 9).

**Ecualizador por salida (§5.4)**
- Perfiles guardados por tipo de salida: altavoz del teléfono, audífonos cableados, Bluetooth, Android Auto, DAC USB.
- Cambio automático de perfil al detectar cambio de dispositivo de salida (usa el evento `audioDeviceChanged` ya introducido en Fase 2).

**Modo directo — significado final (§5.5)**
- Pasa a significar bypass explícito de toda la cadena de mejora (no solo "sin efectos" como en Fase 2), para FLAC/ALAC/WAV/DAC externo o usuarios que prefieren señal sin procesar.

**Fuentes de música extendidas (§10, "fase posterior")**
- SMB / carpetas compartidas, NAS, WebDAV, HTTP/HTTPS, radios por internet, listas M3U remotas.
- DLNA: **condicionado** — "si se incorpora un módulo específico" (según el propio requerimiento); se evalúa técnicamente al inicio de esta fase y se documenta la decisión, pero no bloquea el resto del alcance de Fase 3.
- Las fuentes remotas deben aparecer siempre separadas de la biblioteca local, nunca mezcladas silenciosamente.

**Letras — obtención automática por internet (§8, resto)**
- Integración opcional usando proveedores legales o APIs autorizadas, consistente con el resto de integraciones de red de esta fase.

**Formatos — compatibilidad extendida (§6, §18 Fase 5 original)**
- Confirmación garantizada de WMA y ALAC ("cuando el motor lo permita" pasa a resolverse aquí) y ampliación general de compatibilidad, incluyendo negociación de formato para streams remotos.

### Pantallas entregadas (§11)
- **Ecualizador y mejora**: pantalla completa — interruptor general, selector de perfil, ecualizador avanzado, graves, claridad, normalización, expansión estéreo, balance (ya existente desde Fase 2, reexpuesto aquí junto al resto), comparación activado/desactivado.
- **Reproductor completo**: pestaña "Efectos" pasa de básica (Fase 2) a completa.
- Nueva sección de biblioteca/navegación para fuentes remotas, claramente separada de "Biblioteca" local (nueva pantalla, no contemplada en la §11 original — ver nota de arquitectura).
- **Ajustes**: se añade gestión de fuentes remotas (altas/bajas de servidores SMB/WebDAV, radios guardadas).

### Arquitectura y contrato Dart–Kotlin
- `AudioEnhancerProcessor.kt` implementado (cadena DSP completa vía `android.media.audiofx`, incluyendo `DynamicsProcessing`).
- `AudioEffectsManager.kt` ampliado a modo avanzado (15/20 bandas) y perfiles por dispositivo de salida.
- **Nota de arquitectura**: el árbol de la §13 no contempla fuentes remotas. En esta fase se añade un módulo nuevo `features/remote_sources` en Flutter y clases nuevas en Kotlin (p. ej. `SmbClient`, `WebDavClient`, `HttpAudioSource`, `InternetRadioService`) no listadas originalmente en el documento de requerimiento — se documentan aquí explícitamente para que no queden huérfanas.
- Contrato Pigeon — se agregan: `setAudioProfile`, `setAudioEnhancement`, `setEqualizer` (extendido a modo avanzado y por-salida). Fuentes remotas requieren métodos adicionales no enumerados en la §15 original (p. ej. `addRemoteSource`, `removeRemoteSource`, `getRemoteStreamInfo`) — a definir con Pigeon siguiendo el mismo patrón tipado.
- Eventos agregados: `processingStateChanged`.

### Datos locales (Drift, §14)
- Perfiles por dispositivo de salida, Análisis de volumen (tipo ReplayGain).
- Extensión de esquema para fuentes remotas (credenciales/URIs de servidores, radios guardadas) — no listada explícitamente en la §14 original; se añade aquí de forma consistente con el resto del modelo (solo se guardan URIs/identificadores, nunca se copia el audio a la base de datos).

### Seguridad y rendimiento
- Rendimiento (§17): limitar análisis de volumen en segundo plano, pausar trabajos pesados con batería baja, asegurar que el audio offload se re-habilite correctamente cuando "Mejorar audio" esté desactivado.
- Seguridad: las fuentes remotas heredan el mismo principio de biblioteca local por defecto (§16) — nunca se activan ni se mezclan sin acción explícita del usuario; credenciales de servidores remotos se almacenan de forma segura (no en texto plano) — requisito derivado y no explícito en el documento original, pero necesario para cumplir el espíritu de la sección 16 al incorporar SMB/NAS/WebDAV.

### Criterios de aceptación cubiertos (§19)
7 (completo, con presets avanzados y limitador), 8, 9.

### Explícitamente fuera de esta fase
Nada del documento de requerimiento queda pendiente después de esta fase. Reproducción de video y cualquier elemento de la lista "No incluido" (§3) permanecen fuera del producto de forma permanente, no como trabajo diferido.

---

## Matriz de trazabilidad (sección del requerimiento → fase)

| Sección del requerimiento | Fase |
|---|---|
| §1 Objetivo | Transversal (visión, no ejecutable por fase) |
| §2 Plataforma y tecnología | F1 (Flutter/Kotlin/Media3/MediaStore) + F2 (TagLib) |
| §3 Alcance | F1–F3 (incluido, repartido); "No incluido" es permanente, ninguna fase |
| §4.1 Biblioteca musical | F1 (núcleo) + F2 (género/compositor/historial) |
| §4.2 Reproductor | F1 (núcleo) + F2 (temporizador, letras, efectos básico) |
| §4.3 Cola | F1 (completa) |
| §4.4 Listas de reproducción | F1 (básico) + F2 (inteligentes, M3U, compartir) |
| §5.1–§5.4 Calidad y DSP avanzado | F3 |
| §5.5 Calidad de reproducción | F2 |
| §6 Formatos | F1 (nativos) + F2 (confirmación WMA/ALAC) + F3 (extensión/remotos) |
| §7 Metadatos y portada | F2 |
| §8 Letras | F2 (local) + F3 (obtención por internet) |
| §9.1 Segundo plano | F1 |
| §9.2 Controles externos | F1 (básico) + F2 (Android Auto, widgets, relojes) |
| §9.3 Audio focus | F1 |
| §10 Fuentes de música | F1 (principal) + F3 (posterior/remotas) |
| §11 Pantallas | Repartidas por pantalla, ver detalle en cada fase |
| §12 Diseño visual | F1 (base) + F2 (refinamiento) |
| §13 Arquitectura | Esqueleto completo en F1; implementación progresiva F1→F3; extensión de fuentes remotas documentada en F3 |
| §14 Datos locales | Repartido por campo, ver detalle en cada fase |
| §15 Contrato Flutter–Android | Repartido por método/evento, ver detalle en cada fase |
| §16 Seguridad e integridad | F1 (permisos/biblioteca local) + F2 (escritura segura) + F3 (fuentes remotas) |
| §17 Rendimiento | F1 (base) + F3 (análisis de volumen/batería) |
| §18 Fases (original) | Reemplazado por este documento |
| §19 Criterios de aceptación | 1,2,3,4,5,6,12,13,14,15 → F1; 7(parcial),10,11 → F2; 7(completo),8,9 → F3 |
| §20 Resultado esperado | Se alcanza íntegramente al cierre de F3 |

## Notas de resolución de ambigüedades

Estas son las decisiones explícitas tomadas donde el documento original era ambiguo o dejaba huérfano algún ítem:

1. **Género/Compositor** no son pestañas propias (la §11 solo define 5 pestañas de Biblioteca); se resuelven como filtros dentro de "Canciones" en Fase 2.
2. **Listas inteligentes** no estaban asignadas a ninguna fase original; se ubicaron en Fase 2 por depender de historial/metadata enriquecida.
3. **Añadidas recientemente** (canciones) se separó de "Reproducidas recientemente"/"Más reproducidas": la primera solo necesita `date_added` de MediaStore (Fase 1), las otras necesitan historial (Fase 2).
4. **DLNA** se mantiene condicionado tal como lo redacta el propio documento ("si se incorpora un módulo específico"); no bloquea el resto de Fase 3.
5. **Audio offload** se implementa desde Fase 1 como ruta por defecto (sin efectos aún) y se revalida en Fase 3 para que se reactive correctamente cuando "Mejorar audio" esté desactivado.
6. **Fuentes remotas** exigen módulos de arquitectura (Flutter y Kotlin) y métodos de contrato Pigeon que no aparecen en las secciones 13/15 originales; se documentaron explícitamente en Fase 3 en vez de dejarlos implícitos.
7. **Relojes inteligentes** no tenían desarrollo dedicado en ninguna fase original; se entregan como subproducto de `MediaSessionService`/Bluetooth de Fase 1 y se certifican formalmente en Fase 2 junto con Android Auto.
