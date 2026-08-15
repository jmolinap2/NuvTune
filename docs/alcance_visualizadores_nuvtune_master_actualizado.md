# Alcance técnico actualizado — Visualizadores reactivos de NuvTune

## 1. Objetivo del documento

Definir el alcance técnico real para mejorar el sistema de visualizadores de NuvTune tomando como base el estado actual del repositorio `master`.

Este documento distingue explícitamente entre:

- `EXISTE`: ya está implementado en el repositorio actual.
- `MANTENER`: está correctamente resuelto y no requiere rediseño.
- `REFACTORIZAR`: existe, pero conviene reorganizarlo.
- `AGREGAR`: todavía no existe y forma parte de la propuesta.

El objetivo principal es evitar que cada visualizador evolucione con una lógica de reacción musical diferente.

La propuesta es:

```text
Un solo motor común de dinámica musical
+
múltiples representaciones visuales
```

Cada estilo debe seguir teniendo una identidad visual propia, pero todos deben compartir la misma lógica de:

- energía;
- respuesta temporal;
- graves;
- medios;
- agudos;
- beat;
- color;
- saturación;
- luminosidad;
- glow;
- descenso.

---

# 2. Estado actual del repositorio

Actualmente existen los siguientes estilos:

```text
Automático
Frecuencias 360°
Partículas fluidas
Espectro minimalista
Ondas eléctricas
Viaje psicodélico
```

No existe actualmente un estilo `Hybrid`.

El modo `Automático` no pinta una animación propia.

Su responsabilidad es seleccionar de forma estable uno de los estilos concretos según la canción.

Flujo actual:

```text
VisualizerStyle.automatic
        ↓
resolveFor(seed)
        ↓
estilo concreto
```

Estado:

```text
MANTENER
```

---

# 3. Escenario visual del reproductor

NuvTune ya separa el contenido visual principal mediante `PlayerVisualScene`.

Escenarios actuales:

```text
Video
Visualizador
Video + letras
Letras
Portada
```

El escenario `Visualizador` está pensado como una animación reactiva a pantalla amplia.

Esto significa que el visualizador ya debe considerarse una parte formal del reproductor y no únicamente una portada alternativa.

Estado:

```text
EXISTE
MANTENER
```

---

# 4. Flujo actual de datos

Actualmente la arquitectura relevante es aproximadamente:

```text
Music Engine
    ↓
AudioAnalysisFrame
    ↓
audioAnalysisProvider
    ↓
ReactiveAudioVisualizer
    ↓
_VisualizerPainter
    ↓
Painter específico
```

`AudioAnalysisFrame` entrega:

```text
level
bass
mid
treble
beat
spectrum[]
```

Esto ya proporciona una buena base para un motor común.

Estado:

```text
EXISTE
```

---

# 5. Problema arquitectónico actual

Actualmente `_VisualizerPainter` recibe directamente el `AudioAnalysisFrame`.

Después cada estilo interpreta esos valores por su cuenta.

Ejemplo conceptual:

```text
AudioAnalysisFrame
        ↓
_VisualizerPainter
        ├── _paintRibbons()
        ├── _paintPrism()
        ├── _paintSpectrum()
        ├── _paintElectricWaves()
        └── _paintCosmicOrbs()
```

Cada método calcula individualmente:

- amplitudes;
- energía local;
- intensidad;
- colores;
- blur;
- glow;
- respuesta al beat.

Esto funciona, pero puede generar inconsistencias cuando el sistema crezca.

Estado:

```text
REFACTORIZAR
```

---

# 6. Arquitectura objetivo

Se propone introducir una capa intermedia:

```text
AudioAnalysisFrame
        ↓
VisualizerDynamicsEngine
        ↓
VisualizerDynamicsState
        ↓
_VisualizerPainter
        ├── Ribbons
        ├── Prism
        ├── MinimalSpectrum
        ├── ElectricWaves
        └── CosmicOrbs
```

El objetivo no es reemplazar los painters.

El objetivo es que los painters dejen de decidir qué significa musicalmente un valor.

El motor común responde:

```text
¿Qué está haciendo la música?
```

El painter responde:

```text
¿Cómo dibujo eso?
```

---

# 7. VisualizerDynamicsEngine

Estado:

```text
AGREGAR
```

Responsabilidades propuestas:

- normalizar energía;
- calcular energía global;
- aplicar attack;
- aplicar release;
- suavizar cambios;
- mantener peaks;
- generar impulso de beat;
- calcular saturación;
- calcular luminosidad;
- calcular glow;
- generar información cromática;
- entregar valores coherentes a todos los estilos.

No debe contener:

- `Canvas`;
- `Path`;
- geometría;
- posiciones;
- órbitas;
- círculos;
- barras;
- partículas concretas.

---

# 8. VisualizerDynamicsState

Estado:

```text
AGREGAR
```

Modelo sugerido:

```dart
class VisualizerDynamicsState {
  final double energy;

  final double level;
  final double bass;
  final double mid;
  final double treble;

  final double beat;
  final double beatImpulse;

  final double brightness;
  final double saturation;
  final double glow;

  final double hue;

  final List<double> spectrum;
  final List<double> peaks;
}
```

Este objeto representa el estado visual derivado de la música.

---

# 9. Energía global

Actualmente algunos estilos ya construyen energía combinando diferentes componentes.

Sin embargo, esto no está centralizado.

Estado:

```text
REFACTORIZAR
```

Propuesta inicial:

```dart
energy =
    level * 0.38 +
    bass * 0.30 +
    mid * 0.20 +
    treble * 0.12;
```

Después:

```dart
energy = energy.clamp(0.0, 1.0);
```

El cálculo real debe calibrarse con pruebas.

La idea importante es que exista una sola definición de `energy`.

---

# 10. Attack y Release

Actualmente no existe una capa visual común que aplique un comportamiento uniforme de subida y descenso.

Estado:

```text
AGREGAR
```

Comportamiento deseado:

```text
subida rápida
↓
pico
↓
descenso suave
```

Ejemplo:

```dart
if (input > current) {
  current += (input - current) * attack;
} else {
  current += (input - current) * release;
}
```

Valores iniciales orientativos:

```text
attack  = 0.55
release = 0.12
```

Estos valores deben ser configurables.

---

# 11. Peak Hold

En el `master` actual no existe un sistema global de peak-hold.

Estado:

```text
AGREGAR
```

El peak debe ser común como concepto.

Representación por estilo:

```text
MinimalSpectrum
→ marcador sobre barra

Ribbons
→ pico radial

ElectricWaves
→ destello sobre cresta

Prism
→ partícula más luminosa

CosmicOrbs
→ flare o expansión
```

Regla:

```text
Peak = estado común
Representación del peak = específica por estilo
```

---

# 12. Paleta actual

Actualmente existe una paleta estable por canción.

Se deriva de un `seed` estable y genera una combinación cercana a:

```text
cian
azul
magenta
```

Esto es una buena base.

Estado:

```text
EXISTE
MANTENER
```

Sin embargo, la paleta actual no representa todavía un sistema completo de evolución cromática gobernado por energía.

---

# 13. Color dinámico por energía

Estado:

```text
AGREGAR
```

La paleta base se mantiene.

Lo que cambia es la intensidad con la que se utiliza.

Ejemplo:

```text
energía baja
→ azul oscuro / cian tenue

energía media
→ cian / azul eléctrico / violeta

energía alta
→ violeta / magenta

pico
→ magenta / rosa brillante
```

No debe cambiar el color de forma aleatoria.

Debe existir interpolación.

---

# 14. Saturación dinámica

Actualmente la saturación se define principalmente en la creación de la paleta.

No existe una saturación global gobernada por la intensidad de la música.

Estado:

```text
AGREGAR
```

Propuesta:

```text
0.0 energía → 60 %
0.5 energía → 82 %
1.0 energía → 100 %
```

El objetivo es evitar que el visualizador se vea apagado.

---

# 15. Luminosidad dinámica

Estado:

```text
AGREGAR
```

La luminosidad debe reaccionar a la música.

Ejemplo:

```text
tranquilo
→ brillo contenido

medio
→ brillo perceptible

pico
→ puntos concretos casi blancos
```

No debe aumentar uniformemente toda la pantalla.

---

# 16. Glow dinámico

Actualmente varios estilos ya usan blur y glow.

Ejemplos existentes:

```text
Ribbons
ElectricWaves
CosmicOrbs
Prism
```

Estado:

```text
EXISTE
REFACTORIZAR
```

El problema no es la ausencia de glow.

El problema es que su intensidad se calcula de manera local dentro de cada painter.

Propuesta:

```dart
double glow;
```

generado por `VisualizerDynamicsEngine`.

Cada estilo decide cómo traducirlo a:

```text
blur
opacity
halo
blend
```

---

# 17. Problema visual detectado: contraste

La visualización actual puede percibirse apagada cuando el fondo y los elementos activos tienen luminancias demasiado similares.

Estado:

```text
AGREGAR / CALIBRAR
```

Correcciones:

- fondo más oscuro;
- menos neblina uniforme;
- más diferencia de luminancia;
- glow localizado;
- mayor brillo en picos;
- colores activos más saturados.

---

# 18. Fondo inmersivo

Actualmente existe `_paintImmersiveAtmosphere`.

Este sistema ya:

- crea halos;
- introduce partículas ambientales;
- utiliza `bass`, `mid`, `level` y `spectrum`.

Estado:

```text
EXISTE
MANTENER
```

Sin embargo, la intensidad debe calibrarse para evitar una niebla excesiva.

Regla recomendada:

```text
fondo = soporte visual
visualizador = protagonista
```

---

# 19. Modo Live

Cuando existe análisis real:

```text
hasLiveAnalysis == true
```

el visualizador utiliza información real de audio.

Estado:

```text
EXISTE
MANTENER
```

Se debe conservar como fuente principal.

---

# 20. Modo Ambient / Direct Mode

Cuando el motor funciona en modo directo/offload y no existen cuadros PCM, NuvTune genera un movimiento procedural suave.

El código actual evita generar falsos beats.

Estado:

```text
EXISTE
MANTENER
```

Esto es correcto.

El sistema debe seguir diferenciando:

```text
Live
```

de:

```text
Ambient
```

El modo ambiental nunca debe pretender representar un FFT real.

---

# 21. Ribbons / Frecuencias 360°

Estado:

```text
EXISTE
```

Actualmente utiliza:

- spectrum;
- beat;
- color;
- flutter;
- varios anillos en modo amplio.

Debe migrarse para consumir el estado común.

Ejemplo futuro:

```text
spectrum
→ longitud radial

beatImpulse
→ expansión

energy
→ intensidad

glow
→ blur

saturation
→ color
```

Estado futuro:

```text
REFACTORIZAR
```

---

# 22. Prism / Partículas fluidas

Estado:

```text
EXISTE
```

Actualmente ya utiliza:

- bass;
- mid;
- treble;
- beat;
- spectrum;
- partículas;
- flujo orbital.

La geometría debe mantenerse específica del estilo.

Debe centralizarse únicamente la dinámica musical.

Estado futuro:

```text
REFACTORIZAR
```

---

# 23. MinimalSpectrum

Estado:

```text
EXISTE
```

Actualmente representa el espectro mediante barras.

Este estilo es el candidato principal para incorporar:

```text
attack/release
peak hold
color dinámico
glow normalizado
```

Pero esas mejoras no deben quedar exclusivas de este estilo.

Estado futuro:

```text
REFACTORIZAR
```

---

# 24. ElectricWaves

Estado:

```text
EXISTE
```

Actualmente ya combina múltiples señales musicales.

El estilo debe seguir interpretando:

```text
bass
→ amplitud

mid
→ curvatura

treble
→ vibración

beat
→ impulso
```

Pero la intensidad general, saturación y glow deberían venir del motor común.

Estado futuro:

```text
REFACTORIZAR
```

---

# 25. CosmicOrbs / Viaje psicodélico

Estado:

```text
EXISTE
```

Actualmente utiliza:

- nebulosa;
- estrellas;
- túneles;
- cintas;
- profundidad;
- bass;
- mid;
- treble;
- beat.

La geometría debe permanecer específica.

Debe adoptar el estado común para:

```text
energy
brightness
saturation
glow
beatImpulse
```

Estado futuro:

```text
REFACTORIZAR
```

---

# 26. Hybrid

Actualmente no existe.

Estado:

```text
NO EXISTE
```

No debe mencionarse como funcionalidad actual.

Puede evaluarse en el futuro como un estilo opcional que combine:

```text
barras
ondas
peaks
partículas
```

Pero no forma parte necesaria de este alcance.

---

# 27. Partículas

Actualmente varios estilos ya incluyen partículas.

Estado:

```text
EXISTE
```

Se recomienda centralizar únicamente las señales que determinan su intensidad:

```text
treble
beat
energy
```

Cada estilo conserva:

```text
posición
trayectoria
tamaño
geometría
```

Estado futuro:

```text
REFACTORIZAR PARCIALMENTE
```

---

# 28. Reduce Motion

Actualmente `ReactiveAudioVisualizer` respeta:

```dart
MediaQuery.disableAnimationsOf(context)
```

Estado:

```text
EXISTE
MANTENER
```

Puede ampliarse en el futuro para reducir:

- partículas;
- flashes;
- vibraciones;
- desplazamientos complejos.

Pero la integración base ya existe.

---

# 29. RepaintBoundary

El visualizador ya está aislado mediante:

```dart
RepaintBoundary
```

Estado:

```text
EXISTE
MANTENER
```

Esto es correcto para evitar repintar innecesariamente el resto de la pantalla.

---

# 30. AnimatedBuilder

La animación se controla actualmente mediante un `AnimationController` y `AnimatedBuilder`.

Estado:

```text
EXISTE
MANTENER
```

No es necesario reemplazar este mecanismo para implementar el motor común.

---

# 31. Rendimiento

No se propone convertir el sistema en una arquitectura excesivamente compleja.

La prioridad debe ser:

```text
1. mantener 60 FPS
2. evitar reconstrucciones de widgets
3. mantener cálculo fuera del árbol de UI
4. reutilizar valores derivados
5. evitar blur excesivo
```

La refactorización debe reducir duplicación, no aumentar coste.

---

# 32. Qué debe ser global

Centralizar:

```text
normalización
energy
attack
release
beatImpulse
peak hold
brightness
saturation
glow
hue
```

---

# 33. Qué debe seguir siendo específico

Mantener dentro de cada painter:

```text
Canvas
Path
Rect
RRect
geometría
órbitas
rotaciones
perspectiva
cantidad de curvas
posición de partículas
tipo de barras
tipo de túnel
```

---

# 34. Regla arquitectónica

Si una lógica responde:

```text
¿Qué está haciendo la música?
```

debe pertenecer a:

```text
VisualizerDynamicsEngine
```

Ejemplos:

```text
hay mucha energía
hay un beat
los graves están altos
el sonido está descendiendo
```

Si responde:

```text
¿Cómo dibujo esa información?
```

debe pertenecer al painter.

Ejemplos:

```text
barra
círculo
onda
partícula
órbita
túnel
```

---

# 35. Fase 1 — Motor común mínimo

Agregar:

```text
VisualizerDynamicsEngine
VisualizerDynamicsState
```

Centralizar:

```text
energy
brightness
saturation
glow
```

No modificar todavía profundamente las geometrías.

---

# 36. Fase 2 — Respuesta temporal

Agregar:

```text
attack
release
beatImpulse
```

Objetivo:

```text
subidas rápidas
descensos suaves
beats legibles
```

---

# 37. Fase 3 — Peak Hold

Agregar:

```text
peaks[]
```

Primero utilizarlo en `MinimalSpectrum`.

Después cada estilo puede interpretar el peak de forma distinta.

---

# 38. Fase 4 — Migración de estilos

Migrar:

```text
Ribbons
Prism
MinimalSpectrum
ElectricWaves
CosmicOrbs
```

para que consuman:

```text
VisualizerDynamicsState
```

y reduzcan cálculos duplicados.

---

# 39. Fase 5 — Calibración visual

Probar una misma canción con todos los estilos.

Validar:

- percepción de energía similar;
- colores coherentes;
- mismo comportamiento de descenso;
- beats equivalentes;
- contraste suficiente;
- ausencia de opacidad excesiva.

---

# 40. Criterios de aceptación

La implementación se considera correcta cuando:

1. Todos los estilos reciben un estado común de dinámica.
2. Existe una única definición de energía visual.
3. Attack/release es consistente.
4. Los beats se normalizan antes de llegar al painter.
5. El color responde a la intensidad.
6. La saturación responde a la intensidad.
7. El glow responde a la intensidad.
8. Los estilos conservan su identidad visual.
9. El modo Ambient sigue sin inventar beats.
10. `Automatic` sigue seleccionando un estilo concreto.
11. No se introduce degradación perceptible de rendimiento.
12. `MinimalSpectrum`, `Ribbons`, `Prism`, `ElectricWaves` y `CosmicOrbs` comparten el mismo lenguaje de reacción musical.

---

# 41. Resumen por estado

## EXISTE

```text
AudioAnalysisFrame
audioAnalysisProvider
ReactiveAudioVisualizer
VisualizerStyle
Automatic
Ribbons
Prism
MinimalSpectrum
ElectricWaves
CosmicOrbs
PlayerVisualScene
Live analysis
Ambient mode
palette por canción
RepaintBoundary
reduceMotion
AnimationController
```

## MANTENER

```text
selección automática por seed
modo Live / Ambient
separación de escenas del reproductor
geometría propia de cada estilo
RepaintBoundary
reduceMotion
```

## REFACTORIZAR

```text
cálculo de energía local
glow local
intensidad local
respuesta cromática local
interpretación duplicada de bass/mid/treble/beat
```

## AGREGAR

```text
VisualizerDynamicsEngine
VisualizerDynamicsState
attack/release global
peak hold
beatImpulse
saturación dinámica global
luminosidad dinámica global
glow normalizado global
evolución cromática según energía
```

## NO EXISTE ACTUALMENTE

```text
Hybrid
```

---

# 42. Resultado esperado

La arquitectura final debe quedar conceptualmente así:

```text
                Audio
                  ↓
          AudioAnalysisFrame
                  ↓
       VisualizerDynamicsEngine
                  ↓
       VisualizerDynamicsState
                  ↓
     ┌────────────┼────────────┐
     ↓            ↓            ↓
 Ribbons        Prism       Spectrum
     ↓            ↓            ↓
 geometría     partículas     barras

     ↓            ↓
 Electric       Cosmic
 Waves          Orbs
```

Todos reciben la misma interpretación musical.

Cada uno decide únicamente cómo representarla.

---

# 43. Conclusión

El alcance correcto no es mejorar solamente una animación.

Tampoco es copiar exactamente los mismos efectos entre todos los estilos.

El objetivo es construir una capa común que traduzca:

```text
audio
```

en:

```text
dinámica visual
```

y dejar que cada visualizador traduzca después esa dinámica en su propia geometría.

La fórmula final es:

```text
Misma música
+
Misma interpretación de energía
+
Misma respuesta temporal
+
Misma lógica de color
+
Distintas representaciones visuales
```

Con esto NuvTune tendrá visualizadores más coherentes, más fáciles de mantener y más simples de mejorar en el futuro.
