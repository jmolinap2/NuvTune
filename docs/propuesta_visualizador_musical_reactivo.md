# Propuesta técnica — Visualizador musical reactivo en tiempo real

## 1. Objetivo

Implementar un visualizador musical programático para el reproductor que:

- Reaccione en tiempo real al contenido real de la música.
- Cambie forma, amplitud, brillo, saturación y color según la intensidad del audio.
- Permita apreciar claramente tanto las subidas como los descensos de energía.
- Mantenga una estética moderna, limpia y coherente con la interfaz actual.
- Evite animaciones prerenderizadas, GIFs, videos o recursos imposibles de sincronizar correctamente.
- Sea viable en Flutter y suficientemente eficiente para dispositivos Android de gama media.

La visualización propuesta se basa en cuatro elementos principales:

1. Barras de espectro.
2. Ondas suavizadas.
3. Picos de caída.
4. Partículas y glow reactivos.

El diseño final debe sentirse vivo, pero no caótico.

---

# 2. Concepto visual general

La base actual del reproductor se conserva:

- Fondo oscuro.
- Controles inferiores.
- Información de canción.
- Barra de progreso.
- Navegación superior.
- Zona central reservada para el visualizador.

La mejora se concentra principalmente en la zona del visualizador.

El objetivo es pasar de un ecualizador relativamente simple a una composición por capas:

```text
┌─────────────────────────────────┐
│                                 │
│        partículas sutiles       │
│        ·  ·   · ·   ·           │
│                                 │
│      ondas fluidas reactivas    │
│    ~~~~~~~\____/~~~~\____      │
│                                 │
│        picos de caída           │
│          •      •               │
│          |      |               │
│   ███ █████ ███████ ████        │
│   ███ █████ ███████ ████        │
│   barras FFT reactivas          │
│                                 │
└─────────────────────────────────┘
```

Cada capa responde a una característica diferente del audio.

---

# 3. Principio fundamental

Nada importante debe moverse de forma completamente aleatoria.

La música debe controlar la visualización.

La cadena de procesamiento propuesta es:

```text
Audio
  ↓
PCM / FFT
  ↓
AudioAnalyzer
  ↓
Características musicales
  ├── bassEnergy
  ├── midEnergy
  ├── trebleEnergy
  ├── rms
  ├── spectrum[]
  ├── spectralFlux
  └── beat
  ↓
VisualizerController
  ↓
Estado visual suavizado
  ↓
CustomPainter / Fragment Shader
```

---

# 4. Datos de audio requeridos

## 4.1 FFT

La FFT permite conocer cuánta energía existe en diferentes frecuencias.

Ejemplo conceptual:

```text
Frecuencia
20 Hz                         20 kHz
│                                │
████ ███████ ███ █████ ███ ██ ███
```

La salida puede transformarse en aproximadamente 48 a 96 bandas visuales.

No se recomienda dibujar directamente cientos o miles de bins de FFT.

Se deben agrupar.

Ejemplo:

```dart
List<double> visualBands;
```

Valores normalizados:

```text
0.0 → ausencia de energía
1.0 → energía máxima normalizada
```

---

# 5. División por bandas musicales

## 5.1 Graves

Rango aproximado:

```text
20 Hz – 250 Hz
```

Controlan principalmente:

- Pulso general.
- Altura global de las ondas.
- Expansión visual.
- Intensidad del glow.
- Reacciones al bombo.

Variable:

```dart
double bassEnergy;
```

---

## 5.2 Medios

Rango aproximado:

```text
250 Hz – 4 kHz
```

Controlan:

- Forma principal de las ondas.
- Deformaciones visibles.
- Movimiento de capas.
- Parte importante de voces, guitarras y sintetizadores.

Variable:

```dart
double midEnergy;
```

---

## 5.3 Agudos

Rango aproximado:

```text
4 kHz – 16/20 kHz
```

Controlan:

- Partículas.
- Destellos pequeños.
- Detalles rápidos.
- Brillos puntuales.

Variable:

```dart
double trebleEnergy;
```

---

# 6. Energía global

Además del espectro, se debe calcular una energía global.

Puede utilizarse RMS.

Variable:

```dart
double rms;
```

Uso:

- Intensidad general.
- Saturación.
- Luminosidad.
- Cantidad de partículas.
- Amplitud global.

Ejemplo:

```text
RMS bajo
↓
visualización tranquila

RMS medio
↓
visualización activa

RMS alto
↓
visualización intensa
```

---

# 7. Suavizado

Este punto es obligatorio.

Si se dibujan directamente los valores de FFT, el resultado se verá demasiado nervioso.

Se debe aplicar suavizado temporal.

## 7.1 Ataque

Cuando una frecuencia sube, la respuesta debe ser relativamente rápida.

Ejemplo:

```dart
attack = 0.55;
```

---

## 7.2 Decay

Cuando baja, la animación debe descender de forma progresiva.

Ejemplo conceptual:

```text
0.90
0.78
0.67
0.57
0.48
0.40
0.33
0.27
0.22
0.20
```

Esto permite apreciar claramente la caída.

Implementación conceptual:

```dart
if (input > current) {
  current += (input - current) * attack;
} else {
  current += (input - current) * release;
}
```

Donde:

```dart
attack  = 0.55;
release = 0.12;
```

Estos valores deben ser configurables.

---

# 8. Barras de espectro

Las barras seguirán siendo una parte importante del diseño.

## Características

- Entre 48 y 72 barras.
- Bordes redondeados.
- Separación uniforme.
- Altura basada en FFT.
- Color interpolado.
- Glow variable.
- Descenso suavizado.

Ejemplo:

```text
▂ ▃ ▅ ▇ ▆ ▄ ▃ ▅ █ ▆ ▄ ▂
```

---

# 9. Peak Hold

Cada barra puede mantener un pequeño marcador de pico.

Ejemplo:

```text
       •
       │

      █
      █
    █ █
  █ █ █
```

El marcador:

- Sube inmediatamente.
- Permanece unos milisegundos.
- Desciende lentamente.

Esto mejora mucho la percepción del descenso.

Modelo:

```dart
class PeakState {
  double value;
  double velocity;
  Duration holdTime;
}
```

Valores iniciales sugeridos:

```text
Peak hold:   80–140 ms
Peak decay:  lento
```

---

# 10. Ondas superpuestas

Se añadirán entre 3 y 5 ondas.

No deben generarse aleatoriamente.

Deben derivarse del espectro.

Ejemplo:

```text
~~~~~~\____/~~~~\_______
   ~~~~~\__/~~~~~~~~
~~~~\________/~~~~~~
```

Cada onda puede representar una región diferente:

```text
Wave 1 → graves
Wave 2 → medios bajos
Wave 3 → medios
Wave 4 → agudos suavizados
```

---

# 11. Generación de las ondas

Se puede utilizar una interpolación spline o Bézier.

Entrada:

```dart
List<double> frequencySamples;
```

Conversión aproximada:

```text
frecuencia → punto Y
posición banda → punto X
```

Después se interpola.

Flutter:

```dart
Path path = Path();
```

Y posteriormente:

```dart
canvas.drawPath(...)
```

Para una versión más avanzada puede utilizarse un fragment shader.

---

# 12. Comportamiento de las ondas

## Música tranquila

```text
amplitud pequeña
velocidad baja
poco glow
```

## Música media

```text
mayor amplitud
más separación entre ondas
más saturación
```

## Música intensa

```text
ondas grandes
mayor glow
colores más cálidos
más partículas
```

---

# 13. Colores dinámicos

Los colores no serán completamente estáticos.

Tampoco deben cambiar aleatoriamente.

Se utilizará una paleta controlada por energía.

Paleta principal:

```text
Azul oscuro
↓
Cian
↓
Azul eléctrico
↓
Violeta
↓
Magenta
↓
Rosa claro
```

---

# 14. Mapeo de energía a color

Ejemplo:

```text
0.00 → azul oscuro
0.20 → cian oscuro
0.40 → cian brillante
0.60 → azul/violeta
0.80 → violeta/magenta
1.00 → magenta/rosa
```

El cambio será interpolado.

No habrá saltos abruptos.

---

# 15. Implementación con HSV/HSL

Es preferible cambiar hue, saturación y luminosidad.

Ejemplo:

```dart
double hue = lerpDouble(195, 315, energy)!;
double saturation = lerpDouble(0.65, 1.0, energy)!;
double lightness = lerpDouble(0.38, 0.62, energy)!;
```

Ventaja:

- El color evoluciona gradualmente.
- Se mantiene una identidad cromática coherente.
- No aparecen colores aleatorios que rompan el diseño.

---

# 16. Distribución de color por frecuencia

Además de la energía global, las frecuencias pueden influir.

Ejemplo:

```text
Graves  → cian / azul
Medios  → azul / violeta
Agudos  → violeta / magenta
```

Esto permite que diferentes zonas del espectro tengan diferentes tonos.

Ejemplo visual:

```text
Cian       Azul      Violeta     Magenta
████ █████ ███████ █████ █████ █████
```

---

# 17. Glow dinámico

El glow debe reaccionar a la música.

No debe permanecer siempre al máximo.

Ejemplo:

```dart
blurRadius = lerpDouble(
  3,
  16,
  energy,
)!;
```

Opacidad:

```dart
glowOpacity = lerpDouble(
  0.12,
  0.70,
  energy,
)!;
```

---

# 18. Partículas

Las partículas serán complementarias.

No deben dominar la interfaz.

Cantidad aproximada:

```text
Estado tranquilo: 5–15 visibles
Estado medio:     15–35
Pico:             30–60
```

Cada partícula debe tener:

```dart
class AudioParticle {
  Offset position;
  Offset velocity;

  double life;
  double size;
  double opacity;

  double hue;
}
```

---

# 19. Generación de partículas

Las partículas pueden generarse cuando:

```text
trebleEnergy > threshold
```

o cuando exista un beat.

Ejemplo:

```dart
if (trebleEnergy > 0.7) {
  spawnParticles();
}
```

---

# 20. Beat Detection

Se recomienda incorporar detección sencilla de beat.

Puede utilizarse:

- Energía de graves.
- Spectral Flux.
- Promedio móvil.

Conceptualmente:

```text
energiaActual > promedioReciente × threshold
```

Entonces:

```dart
beatDetected = true;
```

---

# 21. Qué ocurre durante un beat

Un beat puede provocar:

```text
+8 % expansión general
+20 % glow
+partículas
+incremento temporal de saturación
```

El efecto debe durar aproximadamente:

```text
80–180 ms
```

No debe producir saltos exagerados.

---

# 22. Movimiento del fondo

El fondo no será completamente estático.

Sin embargo, el movimiento debe ser extremadamente sutil.

Se puede variar:

- Gradiente.
- Glow central.
- Intensidad azul.
- Mancha radial.

Ejemplo:

```text
tranquilo → #07141f
intenso   → #07152c + halo violeta
```

---

# 23. Estado visual según intensidad

## Nivel 1 — Muy bajo

```text
barras pequeñas
ondas suaves
azul oscuro
casi sin partículas
glow mínimo
```

---

## Nivel 2 — Bajo

```text
cian tenue
ondas visibles
barras activas
```

---

## Nivel 3 — Medio

```text
azul eléctrico
ondas más amplias
partículas ocasionales
```

---

## Nivel 4 — Alto

```text
azul + violeta
barras altas
glow evidente
más partículas
```

---

## Nivel 5 — Pico

```text
violeta + magenta
máxima saturación
ondas amplias
partículas
peak hold visible
```

---

# 24. Transición durante una canción

Ejemplo:

```text
INTRO

Azul oscuro
Ondas pequeñas
Pocas partículas

        ↓

VERSO

Cian
Movimiento medio

        ↓

PRE-CORO

Azul eléctrico
Más glow
Ondas creciendo

        ↓

CORO

Violeta / magenta
Barras altas
Partículas
Peak hold
Mayor amplitud

        ↓

BREAK

Descenso gradual
Menos partículas
Vuelta progresiva a azul
```

---

# 25. Arquitectura propuesta

```text
AudioPlaybackService
        │
        │ PCM / FFT
        ▼
AudioAnalyzer
        │
        ├── SpectrumAnalyzer
        ├── EnergyAnalyzer
        ├── BeatDetector
        └── FrequencyBandAnalyzer
        │
        ▼
VisualizerController
        │
        ├── SpectrumState
        ├── WaveState
        ├── ParticleState
        ├── ColorState
        └── GlowState
        │
        ▼
VisualizerRenderer
        │
        ├── SpectrumPainter
        ├── WavePainter
        ├── PeakPainter
        ├── ParticlePainter
        └── GlowPainter
```

---

# 26. Modelo de estado

Ejemplo:

```dart
class VisualizerState {
  final List<double> spectrum;
  final List<double> peaks;

  final double bassEnergy;
  final double midEnergy;
  final double trebleEnergy;

  final double rms;

  final bool beatDetected;

  final double visualEnergy;

  final double hue;
  final double glowIntensity;
}
```

---

# 27. VisualizerController

Responsabilidades:

- Recibir datos del analizador.
- Normalizar valores.
- Aplicar attack/release.
- Controlar peaks.
- Interpolar colores.
- Actualizar partículas.
- Generar estado visual.

No debe dibujar directamente.

Esto mantiene separación de responsabilidades.

---

# 28. Renderer

El renderer solamente recibe el estado y dibuja.

Ejemplo:

```dart
class MusicVisualizerPainter extends CustomPainter {
  final VisualizerState state;

  MusicVisualizerPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    drawGlow(canvas, size);
    drawParticles(canvas, size);
    drawSpectrum(canvas, size);
    drawWaves(canvas, size);
    drawPeaks(canvas, size);
  }
}
```

---

# 29. Orden recomendado de dibujo

```text
1. Background glow
2. Partículas traseras
3. Barras
4. Ondas
5. Peak markers
6. Partículas delanteras
```

---

# 30. FPS

Objetivo:

```text
60 FPS
```

No es necesario analizar el audio 60 veces por segundo.

Ejemplo:

```text
FFT → 25–40 Hz
Render → 60 FPS
```

El renderer interpola entre muestras.

Esto reduce carga.

---

# 31. Número de bandas

Recomendado:

```text
48 bandas → modo rendimiento
64 bandas → estándar
96 bandas → alta calidad
```

Valor inicial recomendado:

```text
64
```

---

# 32. Optimización

Evitar:

```dart
setState(...)
```

para toda la página en cada frame.

Preferir:

- `CustomPainter`
- `RepaintBoundary`
- `ValueNotifier`
- `AnimationController`
- Render aislado

La interfaz de reproducción no debe reconstruirse completa por cada actualización del FFT.

---

# 33. RepaintBoundary

El visualizador debe estar aislado:

```dart
RepaintBoundary(
  child: MusicVisualizer(),
)
```

Así los controles inferiores no necesitan repintarse continuamente.

---

# 34. Fragment Shader

No es obligatorio para la primera versión.

Puede añadirse posteriormente para:

- Glow avanzado.
- Blur.
- Distorsiones.
- Ondas líquidas.
- Gradientes complejos.

Primera implementación:

```text
CustomPainter
```

Versión avanzada:

```text
CustomPainter + Fragment Shader
```

---

# 35. Perfiles de calidad

## Eco

```text
32–48 bandas
30 FPS
pocas partículas
blur reducido
```

## Normal

```text
64 bandas
60 FPS
partículas moderadas
```

## Ultra

```text
96 bandas
60 FPS
más partículas
shader
```

---

# 36. Parámetros configurables

```dart
class VisualizerConfig {
  int bandCount;

  double attack;
  double release;

  double bassBoost;
  double midBoost;
  double trebleBoost;

  double waveIntensity;
  double particleIntensity;

  double glowIntensity;

  bool enableParticles;
  bool enableWaves;
  bool enablePeakHold;

  int qualityLevel;
}
```

---

# 37. Valores iniciales sugeridos

```text
Bandas:                64

Attack:                0.55
Release:               0.12

Wave layers:           4

Peak hold:             100 ms

Peak decay:            0.94

Particle limit:        40

FFT update:            30 Hz

Renderer:              60 FPS
```

---

# 38. Modo ahorro de batería

Cuando el dispositivo:

- Tiene batería baja.
- Está en segundo plano.
- Tiene pantalla apagada.

El visualizador debe:

```text
reducir FPS
↓
reducir partículas
↓
desactivar blur pesado
```

Si la pantalla está apagada:

```text
detener render visual
```

El audio continúa normalmente.

---

# 39. Accesibilidad

Añadir opción:

```text
Reducir efectos visuales
```

Esto puede:

- Desactivar partículas.
- Reducir cambios rápidos de luminosidad.
- Reducir glow.
- Limitar variación cromática.

---

# 40. Presets

Se recomienda permitir diferentes estilos visuales usando el mismo motor.

## Spectrum

```text
barras + peak
```

## Flow

```text
ondas + partículas
```

## Hybrid

```text
barras + ondas + partículas
```

## Circle

```text
barras circulares
```

La propuesta principal sería:

```text
Hybrid
```

---

# 41. Preset Hybrid recomendado

Composición:

```text
Background
↓
Partículas
↓
64 barras
↓
4 ondas
↓
Peak Hold
↓
Glow
```

Peso visual aproximado:

```text
Barras       45 %
Ondas        35 %
Partículas   10 %
Glow         10 %
```

---

# 42. Comportamiento cuando no existe FFT disponible

No todos los motores de reproducción entregan FFT directamente.

Fallback:

```text
RMS
+
waveform PCM
```

La visualización puede continuar utilizando:

- Amplitud.
- Energía.
- Waveform.

Pero pierde precisión frecuencial.

---

# 43. Datos que NO deben controlar el visualizador

No utilizar:

- posición de reproducción;
- metadata de canción;
- tiempo aleatorio;
- números pseudoaleatorios como fuente principal.

La aleatoriedad solo se permite para pequeños detalles visuales:

```text
posición de partículas
dirección inicial
duración
```

La cantidad de partículas sigue dependiendo de la música.

---

# 44. Resultado esperado

El reproductor debe sentirse distinto según la canción.

Una canción tranquila:

```text
azul
fluida
poca luminosidad
movimiento relajado
```

Una canción intensa:

```text
cian
azul
violeta
magenta
barras altas
ondas grandes
partículas
glow
```

Una caída musical:

```text
las barras bajan
los peak markers permanecen brevemente
las ondas pierden amplitud gradualmente
las partículas dejan de generarse
el magenta vuelve a azul
el glow disminuye
```

Todo sucede progresivamente.

---

# 45. Prioridad de implementación

## Fase 1

Implementar:

- FFT.
- 64 barras.
- Attack/release.
- Gradiente dinámico.
- Peak hold.

Con esto ya existe un visualizador sólido.

---

## Fase 2

Añadir:

- 3–4 ondas.
- Interpolación spline.
- Glow dinámico.

---

## Fase 3

Añadir:

- partículas;
- beat detection;
- cambios cromáticos avanzados.

---

## Fase 4

Añadir:

- perfiles de calidad;
- modo ahorro;
- presets;
- shader opcional.

---

# 46. Recomendación final

No reemplazar el visualizador actual por una animación completamente diferente.

Evolucionarlo.

Mantener:

```text
barras reactivas
```

y añadir progresivamente:

```text
barras
+
peak hold
+
ondas
+
color dinámico
+
glow
+
partículas
```

El aspecto final sigue siendo reconocible como un visualizador musical, pero gana profundidad y expresividad.

La característica más importante será el comportamiento temporal:

```text
sube rápido
↓
mantiene el pico
↓
desciende suavemente
```

acompañado por:

```text
azul
↓
cian
↓
violeta
↓
magenta
```

según la energía real de la música.

De esta forma el visualizador no será una decoración independiente del audio, sino una representación visual coherente de lo que está sonando.

---

# Actualización visual — corrección de opacidad, contraste y jerarquía

## Problema detectado

La versión visual actual se percibe demasiado apagada y opaca. La base es funcional, pero la representación necesita más contraste, saturación, brillo y presencia visual.

## 1. Poco contraste

El fondo y la visualización están demasiado cerca en luminosidad.

Problemas:

- Las barras no destacan suficientemente.
- La animación no “salta” a la vista.
- Se pierde profundidad.
- Incluso en momentos intensos, el visualizador parece contenido.

### Corrección

- Oscurecer el fondo.
- Incrementar la diferencia de luminancia entre fondo y elementos activos.
- Reservar los blancos y tonos más luminosos para picos.
- Evitar que toda la pantalla tenga el mismo nivel de brillo.

## 2. Saturación baja

Los azules y morados actuales se perciben suaves o lavados.

### Corrección

Usar una paleta más viva:

```text
Azul oscuro
↓
Cian
↓
Azul eléctrico
↓
Violeta
↓
Magenta
↓
Rosa brillante
```

La saturación debe aumentar con la energía musical.

Ejemplo:

```text
Energía baja  → saturación 55–65 %
Energía media → saturación 75–85 %
Pico          → saturación 95–100 %
```

## 3. Glow débil

Las barras actuales emiten poco halo luminoso y se sienten planas.

### Corrección

El glow debe reaccionar al audio:

```text
Música tranquila:
blur bajo
opacity baja

Música intensa:
blur alto
opacity alta
```

Ejemplo conceptual:

```dart
blurRadius = lerpDouble(3, 16, energy)!;
glowOpacity = lerpDouble(0.12, 0.70, energy)!;
```

No debe permanecer siempre al máximo.

## 4. Fondo demasiado brumoso

La neblina gris-azulada resta fuerza visual y reduce la definición de los colores.

### Corrección

Usar un fondo más limpio:

```text
azul marino muy oscuro
+
gradiente radial sutil
+
halo reactivo
```

Evitar una capa gris uniforme sobre toda la pantalla.

## 5. Jerarquía visual débil

El visualizador debe ser claramente el elemento dominante de la zona central.

Jerarquía recomendada:

```text
Visualizador
↓
Información de canción
↓
Controles
```

### Corrección

- Más contraste.
- Mayor rango de amplitud.
- Glow reactivo.
- Más variación cromática.
- Picos de energía más evidentes.
- Descensos claramente visibles.
- Partículas discretas en momentos intensos.

---

# Comportamiento visual recomendado según intensidad

## Nivel 1 — Muy bajo

```text
barras pequeñas
ondas suaves
azul oscuro
casi sin partículas
glow mínimo
saturación contenida
```

## Nivel 2 — Bajo

```text
cian tenue
ondas visibles
barras activas
contraste moderado
```

## Nivel 3 — Medio

```text
azul eléctrico
ondas más amplias
partículas ocasionales
glow perceptible
```

## Nivel 4 — Alto

```text
azul + violeta
barras altas
glow fuerte
más partículas
más saturación
```

## Nivel 5 — Pico

```text
violeta + magenta + rosa
máxima saturación
zonas puntuales casi blancas
ondas amplias
peak hold visible
glow intenso
```

---

# Evolución de color durante la música

Los colores no deben ser estáticos ni aleatorios.

Deben evolucionar según la energía real del audio:

```text
0.00 → azul oscuro
0.20 → cian oscuro
0.40 → cian brillante
0.60 → azul/violeta
0.80 → violeta/magenta
1.00 → magenta/rosa
```

La transición debe ser interpolada para evitar cambios bruscos.

---

# Luminosidad dinámica

La luminosidad también debe reaccionar a la música.

```text
Tranquilo:
luminosidad contenida

Medio:
brillo perceptible

Pico:
detalles puntuales casi blancos
```

No debe iluminarse toda la pantalla por igual.

Los elementos que pueden aumentar de brillo son:

- Barras activas.
- Bordes de ondas.
- Peak markers.
- Partículas.
- Glow central.

---

# Recomendación visual consolidada

La versión final debe corregir claramente la sensación apagada mediante:

```text
menos neblina
+
fondo más oscuro
+
más contraste
+
más saturación
+
más brillo localizado
+
glow reactivo
+
mejor jerarquía visual
```

La propuesta completa queda entonces:

```text
FFT real
+
64 barras
+
attack/release
+
peak hold
+
3–4 ondas
+
color dinámico
+
saturación dinámica
+
luminosidad dinámica
+
glow reactivo
+
partículas discretas
+
beat detection
```

La animación debe:

```text
subir rápido
↓
mantener el pico
↓
descender suavemente
```

y el color debe acompañar la energía:

```text
azul oscuro
↓
cian
↓
azul eléctrico
↓
violeta
↓
magenta
↓
rosa brillante
```

El objetivo final no es solo que el visualizador se mueva, sino que se vea claramente vivo, tenga presencia y represente de forma coherente lo que está ocurriendo en la música.
