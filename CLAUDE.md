# Reglas de arquitectura de NuvTune

Estas reglas no son estilo: son las que evitan la clase de fallo que ya costó
varias sesiones de diagnóstico en este repositorio. Se aplican a código nuevo y
al que se toque.

## 1. Un solo escritor por dato

**Cada dato de estado tiene exactamente una fuente. Si dos caminos pueden
escribir el mismo campo, es un defecto, aunque hoy no se note.**

Cuando dos escritores comparten un campo, el valor depende del orden de llegada
—que nadie garantiza— y el síntoma es intermitente, dependiente de la velocidad
del dispositivo, e imposible de reproducir a mano.

Casos reales de este repositorio:

- **El índice de la pista en curso viajaba en tres eventos distintos**
  (`playbackStateChanged`, `currentTrackChanged`, `queueChanged`) y los tres lo
  escribían en Flutter. Ahora su única fuente es `PlaybackSnapshot.currentIndex`;
  `queueChanged` sólo lleva la lista y el motor emite un snapshot junto a cada
  cambio de cola (incluido `onTimelineChanged`) para que no haga falta deducirlo.
- **El índice visible del carrusel de portadas tenía dos escritores**: el índice
  del motor y las notificaciones de scroll del propio carrusel. Al pasar de la
  pista 146 a la 147, `animateToPage` arrancaba en la página 146.0 y las
  notificaciones devolvían `round() == 146` durante la primera mitad de la
  animación: la portada mostraba 147, volvía a 146 y terminaba en 147. Eso era
  el parpadeo que el usuario reportó durante semanas.

## 2. Autoridad explícita en vez de banderas

Cuando varios actores compiten por un mismo estado (motor, gesto del usuario,
orden en vuelo), se modela **quién manda** con un tipo explícito, no con
booleanos sueltos que haya que combinar mentalmente.

`_CarouselAuthority` (`player_screen.dart`) es el patrón a seguir: `engine`,
`drag`, `pendingEngine`. El valor visible sale de un `switch` sobre la autoridad,
así que por construcción no puede haber dos orígenes a la vez. Sustituyó a tres
banderas (`_pageSyncPending`, `_pageSyncScheduled`, `_pageSyncNeedsJump`) cuyas
combinaciones nadie podía razonar.

Para distinguir un gesto real de una animación propia, usar la señal que el
framework ya da (`ScrollStartNotification.dragDetails != null`), nunca una
bandera propia que haya que acordarse de subir y bajar.

## 3. Invariantes convergentes, no reparaciones puntuales

Preferir *"al terminar cada fotograma en que el dedo no manda, la página visible
coincide con el índice visible"* antes que *"cuando cambia X, mover Y"*. Un
invariante que se aplica siempre es idempotente, se recupera solo tras un
desmontaje y no necesita recordar trabajo pendiente.

## 4. Sin código defensivo ni caminos de reserva

Prohibido: `try/catch` que traga, valores por defecto que enmascaran un estado
imposible, tiempos máximos "por si acaso", reintentos ciegos, banderas
`isSomethingWeird`. Si un estado no debería ocurrir, que falle de forma visible.

Corolario: si una espera depende de recibir un valor concreto, hay que
replantearla para que **cualquier** respuesta de la autoridad la cierre. Ejemplo:
`pendingEngine` termina con el primer índice que reporte el motor, coincida o no
con el pedido —el motor es la verdad— y por eso no necesita un tiempo máximo.

## 5. La intención del usuario se ordena, no se deduce

Una acción explícita (tocar una portada, el botón de "a continuación") manda la
orden al motor directamente. Nunca animar la interfaz y deducir después la
intención de un efecto secundario del scroll: eso obliga a que una animación
propia sea indistinguible de un gesto, que es exactamente la raíz de la regla 1.

## 6. Medir antes de arreglar

Los fallos de reproducción y de transición se diagnostican con datos del
dispositivo real, no por inspección:

- `EngineTrace` (`adb logcat -s NuvTuneTrace`) traza órdenes, transiciones con su
  motivo, discontinuidades y errores, con marca de tiempo. Fue lo que demostró
  que un toque en "siguiente" producía **una** orden y **una** transición, y que
  el "saltó tres canciones" era el carrusel recorriendo cientos de portadas
  intermedias en modo aleatorio (146 → 753), no el motor saltándose pistas.
- `PlaybackFailureLog` (Ajustes → Registro de reproducción) es el registro de
  producto: escaneo, fallo manual, salto automático y pistas que terminan antes
  de su duración declarada.

Un diagnóstico estático (comparar el MIME contra los decodificadores del
dispositivo) **no** sustituye a medir: no detecta archivos corruptos que declaran
un formato soportado.

## Despliegue

`pwsh tool/deploy.ps1` es el único script de despliegue. Compila release e
instala resolviendo el teléfono por identidad (`model:2311DRK48G`), nunca por ip
o puerto guardado, y lo reconecta por mDNS si hace falta. Después mueve la APK
anterior de NuvTune a `APK'S - DESARROLLOS/respaldo`, copia la actual a la
carpeta principal y conserva solo los cuatro respaldos más recientes de
NuvTune; no toca las APK de otros proyectos. `-Action logs` vuelca los errores
de NuvTune sin el ruido de MIUI. Ante conflicto de firma se detiene y avisa en
vez de desinstalar, porque desinstalar borraría la biblioteca y las listas del
usuario.
