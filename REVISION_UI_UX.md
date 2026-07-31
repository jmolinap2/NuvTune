# Revisión honesta de interfaz y experiencia de uso

Estado: las tres fases están implementadas y desplegadas. Este documento **no**
habla de funciones que falten, sino de todo lo que hoy impide que NuvTune se
sienta una aplicación cuidada en lugar de una aplicación completa.

Está ordenado por impacto real sobre la percepción, no por dificultad. Cada
punto dice qué pasa, dónde se ve y por qué importa.

---

## Corregido después de esta revisión

El origen del problema fue mío: existía un sistema visual completo en `img/`
—paleta, tipografía Space Grotesk, tarjetas de vidrio, degradado de marca de
tres paradas— y no lo abrí. Construí contra el requerimiento en texto y entregué
Material 3 de fábrica. Lo corregido hasta ahora:

- **Sistema de diseño real** en [design_tokens.dart](lib/app/theme/design_tokens.dart):
  paleta del mockup, degradado de marca, escala de espaciado y de radios,
  duraciones. Ninguna pantalla vuelve a escribir números sueltos.
- **Space Grotesk empaquetada** (`assets/fonts/`, licencia OFL incluida), con
  escala tipográfica completa en el tema. No se descarga en ejecución: la
  aplicación funciona sin conexión.
- **Componentes del sistema** en [glass.dart](lib/shared/widgets/glass.dart):
  `GlassCard`, `IconBadge`, `GradientButton`, `GradientPlayButton`,
  `GradientText`, `PillChip`, `SectionLabel`.
- **Personalización de apariencia** ([appearance_screen.dart](lib/features/settings/appearance_screen.dart)):
  seis identidades cromáticas, tres profundidades de fondo, tres intensidades de
  vidrio y vista previa construida con los componentes reales. Persistido en
  base de datos (esquema v3).
- **A1 resuelto**: tildes y eñes en toda la interfaz.
- **B1 resuelto**: `ErrorWidget.builder` propio; un fallo de construcción ya no
  puede dejar la aplicación en gris.
- **A2 resuelto**: Inicio ya no puede quedar casi vacío — por debajo de tres
  secciones con contenido se completa con «Añadidas recientemente» y una fila de
  artistas, que existen desde el primer escaneo.
- **Icono de la aplicación**: era el de la plantilla de Flutter. Ahora es un
  icono adaptativo propio con la «N» de la marca sobre el degradado de
  identidad, más capa monocroma para los iconos temáticos de Android 13+.
- **Widget de inicio configurable**: estilo (tarjeta clara o tarjeta oscura),
  tamaño 4x1/4x2/4x3, tema, color principal, opacidad del fondo, siete campos
  de información y tres opciones de comportamiento, con vista previa en la
  propia pantalla de ajustes. La pausa al desconectar los audífonos y la
  reanudación al reconectarlos son reales, no informativas: se sacó esa
  responsabilidad de Media3 a [HeadphoneMonitor.kt](android/music_engine/src/main/kotlin/com/nuvtune/engine/HeadphoneMonitor.kt)
  para que fuera configurable.

Lo que sigue en este documento continúa pendiente.

---

## Bloque A — Lo que se nota en los primeros diez segundos

### A1. La interfaz entera está escrita sin tildes ni eñes

**El problema más visible de todos, y el más barato de arreglar.**

Todo el texto de la aplicación es ASCII puro: `Anadidas recientemente`,
`Editar informacion`, `Repetir cancion`, `Carpetas de musica`, `ultimo escaneo`,
`Lo que se anade son armonicos calculados`.

`Anadidas` y `anade` no son solo faltas de ortografía: sin la eñe son palabras
distintas. Un usuario hispanohablante lo lee como descuido en la primera
pantalla, antes de haber tocado nada.

- **Dónde**: [strings.dart](lib/app/localization/strings.dart) y los literales
  sueltos repartidos por las pantallas.
- **Coste**: mecánico. Un repaso del archivo de textos y de los literales
  incrustados.
- **Nota**: no hay ninguna limitación técnica que lo justifique. Flutter y el
  archivo fuente manejan UTF-8 sin problema.

### A2. La pantalla de Inicio queda casi vacía

Con una biblioteca recién escaneada y sin historial, Inicio muestra una sola
fila ("Álbumes recientes") y deja **el 70 % de la pantalla en negro**. Las demás
secciones colapsan a `SizedBox.shrink()` cuando no tienen datos.

Es correcto por dentro y desastroso por fuera: la primera pantalla que ve el
usuario parece rota.

- **Dónde**: [home_screen.dart](lib/features/home/home_screen.dart) — todas las
  secciones devuelven `SizedBox.shrink()` si su lista está vacía.
- **Qué haría**: que Inicio nunca pueda quedar por debajo de un mínimo. Si no
  hay historial, ofrecer "Añadidas recientemente" y una fila de artistas, que
  existen desde el primer escaneo. Y una tarjeta de bienvenida la primera vez,
  en lugar de vacío.

### A3. Las portadas ausentes son una letra en una caja gris

Con la biblioteca real, la mayoría de álbumes no tiene carátula y la cuadrícula
se convierte en una rejilla de cuadros grises con una inicial. Funciona, pero es
el aspecto más pobre de la aplicación y ocupa la mayor superficie de píxeles.

- **Dónde**: `GroupCover` / `CoverArt` en [shared/widgets/](lib/shared/widgets/).
- **Qué haría**: generar un degradado determinista a partir del hash del nombre
  del álbum, con la inicial en tipografía grande y bajo contraste. Sigue siendo
  un marcador de posición, pero deja de parecer un error de carga.

### A4. Los errores se muestran como excepciones en crudo

Hay varios `Center(child: Text('$error'))`. Si algo falla, el usuario ve el
`toString()` de una excepción de Dart.

- **Dónde**: [settings_screen.dart](lib/features/settings/settings_screen.dart),
  [equalizer_screen.dart](lib/features/equalizer/equalizer_screen.dart) y la
  vista de letras.
- **Qué haría**: un componente de error con causa en lenguaje natural, icono y
  botón de reintento. El detalle técnico, detrás de "Ver detalles".

---

## Bloque B — Fragilidad estructural

### B1. Una sola excepción de construcción deja toda la app en gris

Ya ocurrió: `PlaybackState.currentSong` lanzaba `RangeError` con el índice
centinela `-1`, la pantalla de Inicio no podía construirse y Flutter pintó su
`ErrorWidget` de release, que es un rectángulo gris a pantalla completa. El bug
concreto está corregido y con prueba de regresión, pero **el modo de fallo
sigue ahí**: cualquier excepción futura en un `build` producirá exactamente lo
mismo.

- **Qué haría**: instalar un `ErrorWidget.builder` propio en
  [bootstrap.dart](lib/app/bootstrap.dart), que muestre una tarjeta contenida
  ("Esta sección no se pudo mostrar") en lugar de tragarse la pantalla entera.
  Un fallo en una fila de Inicio no debería impedir usar la Biblioteca.

### B2. Cobertura de pruebas mínima y en el sitio equivocado

18 pruebas, todas de funciones puras (formateo, análisis LRC, estado de
reproducción). No hay ni una prueba de widget, y **la cadena DSP completa de
Fase 3 no tiene ninguna**: sus umbrales, relaciones y tiempos son valores
razonados, no medidos.

- **Qué haría**: pruebas de widget para los estados vacíos y de error de cada
  pantalla —que es justo donde aparecieron los fallos reales— y pruebas de
  señal para el DSP en Kotlin (entrada conocida, verificación de ganancia y de
  ausencia de recorte).

---

## Bloque C — Navegación y arquitectura de la información

### C1. Géneros y compositores están escondidos en un menú de tres puntos

Son dos de las agrupaciones que el requerimiento nombra explícitamente y hoy
viven detrás del `PopupMenuButton` de la barra superior, junto con "Añadidas
recientemente". Nadie las va a encontrar.

- **Qué haría**: una fila de chips de agrupación bajo la barra de pestañas de
  Biblioteca, siempre visible.

### C2. La pestaña "Efectos" del reproductor es una pantalla de ajustes entera

Al añadirla monté dentro el mismo cuerpo que la pantalla "Ecualizador y mejora",
para que ambos sitios controlen exactamente lo mismo. La consecuencia es que
desde el reproductor se accede a una lista larguísima con analizador de
sonoridad, perfiles por salida y avisos legales.

- **Qué haría**: en el reproductor, una versión compacta —interruptor de mejora,
  selector de perfil, curva del ecualizador y poco más— con un enlace a la
  pantalla completa. La coherencia de estado se mantiene igual; lo que cambia es
  cuánto se muestra.

### C3. Con 1201 canciones no hay forma rápida de moverse

La lista de canciones es un `ListView` plano. Para llegar a la letra M hay que
arrastrar mucho.

- **Qué haría**: barra de desplazamiento rápido con índice alfabético, y
  cabeceras de sección fijas al ordenar por título o artista.

### C4. La posición de scroll no sobrevive al cierre de la aplicación

El requerimiento §4.1 pide recordar la posición por sección. Hoy se recuerda al
cambiar de pestaña, gracias a `AutomaticKeepAliveClientMixin`, pero no entre
sesiones. El orden y el filtro sí se guardan.

### C5. Las listas inteligentes se mezclan con las del usuario

En la pantalla Listas conviven colecciones fijas, siete listas inteligentes y
las listas propias, todas como filas idénticas. Las del usuario, que son las que
importan, quedan sepultadas al final.

---

## Bloque D — Retroalimentación, movimiento y detalle

### D1. Todo lo que carga es un círculo giratorio

`CircularProgressIndicator` en el escaneo, la biblioteca, el ecualizador, las
letras y el explorador remoto. No hay ni un esqueleto de contenido.

- **Qué haría**: esqueletos con la forma real de la lista. La percepción de
  velocidad cambia mucho más que la velocidad real.

### D2. Las portadas aparecen de golpe

Se pintan sin transición según llegan del disco, lo que produce un parpadeo al
desplazar. Un `FadeInImage` de 150 ms lo resuelve.

### D3. No hay respuesta háptica en ninguna acción

Marcar favorito, reordenar la cola, activar la mejora, completar el análisis: en
un reproductor de música, donde muchas acciones se hacen sin mirar, la ausencia
de vibración se nota.

### D4. Las transiciones entre pantallas son las de fábrica

El reproductor completo, que es la pantalla insignia, aparece con la animación
por defecto de `go_router`. Debería subir desde el mini reproductor con una
transición de contenedor compartido sobre la portada.

### D5. No se ve qué canción está sonando dentro de las listas

Al abrir un álbum mientras suena una de sus canciones, nada la distingue. Falta
el indicador clásico: barras animadas y el título en color de acento.

### D6. Las acciones destructivas no se pueden deshacer

Quitar una canción de una lista o vaciar la cola son inmediatos y definitivos.
Borrar del dispositivo sí pide confirmación, que es lo crítico, pero el resto se
resolvería mejor con un `SnackBar` con "Deshacer" que con un diálogo.

---

## Bloque E — Sistema visual

### E1. No hay escala tipográfica ni de espaciado

Los tamaños de letra están puestos a mano y sin patrón: `11.5`, `12`, `12.5`,
`13`, `15`, `18`. Los rellenos también: `EdgeInsets.fromLTRB(16, 12, 16, 4)`,
`(20, 16, 20, 8)`, `(4, 4, 4, 0)`. El resultado es que nada está desalineado de
forma evidente, pero tampoco alineado.

- **Qué haría**: una escala de espaciado de cuatro o cinco valores y usar
  `textTheme` en lugar de tamaños literales.

### E2. Los iconos mezclan estilos

Conviven `_rounded` y `_outlined` en la misma pantalla —`Icons.folder_off_outlined`
junto a `Icons.autorenew_rounded` en Ajustes—. Es sutil pero delata falta de
sistema.

### E3. Los textos de ayuda son demasiado largos

Ajustes se lee como documentación. La explicación de la escritura segura ocupa
tres líneas; la del limitador, otras tres. Es honesto, pero convierte una
pantalla de configuración en un manual.

- **Qué haría**: una línea de subtítulo y el resto detrás de un icono de
  información.

### E4. Solo hay tema oscuro

El requerimiento pide tema oscuro y eso se cumple. Pero no existe modo claro ni
seguimiento del ajuste del sistema, y en 2026 se percibe como una carencia.

---

## Bloque F — Accesibilidad

### F1. Los controles de solo icono no tienen etiqueta semántica

Muchos `IconButton` llevan `tooltip`, que TalkBack aprovecha, pero los controles
compuestos —la tarjeta "Continuar escuchando", las celdas de álbum, los
deslizadores de banda del ecualizador— no exponen nada legible. Un ecualizador
de 20 bandas sin etiquetas es inutilizable con lector de pantalla.

### F2. Sin comprobación de tamaños de letra grandes

Hay `Text` con `maxLines: 1` y `TextOverflow.ellipsis` en filas de altura fija.
Con la letra al 150 % del sistema, es previsible que se corte o desborde.

### F3. Contraste sin verificar

Con "fondo negro puro" activado, `onSurfaceVariant` sobre negro absoluto queda
al límite de la relación 4.5:1 de WCAG AA. No está medido.

---

## Bloque G — Adaptabilidad

### G1. No hay diseño para horizontal ni para tableta

Todo asume una columna estrecha. En horizontal, el reproductor completo apila
portada y controles verticalmente y deja mucho espacio muerto a los lados.

### G2. Rellenos inferiores fijos frente al mini reproductor

Varias listas usan un `padding` inferior constante (`bottom: 24`, `bottom: 28`)
para dejar sitio al mini reproductor. Cuando no hay nada sonando, ese hueco
sobra; cuando sí, en algunos sitios se queda corto.

---

## Bloque H — Rendimiento

### H1. `albumById` recalcula toda la agrupación de álbumes

```dart
SongGroup? albumById(int albumId) =>
    albums().firstWhereOrNull((group) => group.key == albumId.toString());
```

`albums()` agrupa y ordena las 1201 canciones enteras para devolver un solo
álbum. Se llama al abrir cada álbum. Lo mismo ocurre con `artistById`.

- **Dónde**: [library_repository.dart](lib/data/repositories/library_repository.dart)
- **Qué haría**: cachear las agrupaciones e invalidarlas en cada escaneo.

### H2. El análisis de sonoridad no respeta la batería

El requerimiento §17 pide pausar los trabajos pesados con batería baja. El
analizador decodifica archivos completos uno tras otro sin mirar el nivel de
batería ni si el teléfono está en ahorro de energía.

### H3. El DSP corre en coma flotante sin aceleración

Consecuencia asumida de implementar la cadena a mano en lugar de usar
`audiofx` —decisión justificada en
[IMPLEMENTACION_FASE_3.md](IMPLEMENTACION_FASE_3.md)—, pero su consumo real de
batería no se ha medido.

---

## Si solo se pudiera hacer una tanda

Por relación entre esfuerzo y percepción:

1. **A1** — poner las tildes y las eñes. Horas de trabajo, cambia por completo
   la impresión de cuidado.
2. **A2** — que Inicio nunca se vea vacío.
3. **A3** — marcadores de portada con degradado en lugar de caja gris.
4. **B1** — `ErrorWidget.builder` propio, para que un fallo no vuelva a costar
   la aplicación entera.
5. **D1 + D2** — esqueletos de carga y aparición gradual de las portadas.

Con esas cinco, NuvTune pasa de "completa" a "cuidada". El resto es
refinamiento sobre una base ya sólida.
