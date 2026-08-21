# NuvTune — Auditoría integral y propuesta de reorganización de Ajustes

**Fecha de revisión:** 2026-08-16  
**Repositorio revisado:** `jmolinap2/NuvTune` — rama `master`  
**Objetivo:** inventariar las preferencias y superficies configurables actuales, detectar mezclas conceptuales, evitar duplicidades y definir una arquitectura de Ajustes que pueda crecer sin volver a desordenarse.

---

## 1. Conclusión ejecutiva

La estructura actual de Ajustes ya intenta separar opciones por categorías, pero existen cuatro problemas principales:

1. **`Control` mezcla demasiados dominios.**
   Actualmente contiene diseño de controles, densidad, gestos, comportamiento de reproducción, transiciones, auriculares y acceso al widget.

2. **`Apariencia` mezcla identidad visual de la app con representación audiovisual del reproductor y con la configuración completa del widget.**
   Estos tres conceptos tienen ciclos de uso distintos y deberían evolucionar de forma independiente.

3. **`Widget` está conceptualmente duplicado.**
   Se accede desde `Apariencia` y también desde `Control`, aunque internamente contiene diseño, contenido y comportamiento propios.

4. **`Sistema y ayuda` y `Datos y privacidad` contienen sobre todo información explicativa, mientras las categorías principales concentran demasiadas preferencias reales.**

La regla de organización propuesta es:

> **Una opción debe vivir donde el usuario esperaría buscarla por intención, no donde sea más cómodo implementarla técnicamente.**

La estructura recomendada queda en siete destinos principales:

```text
AJUSTES

Personalización
├── Apariencia
└── Reproductor

Configuración
├── Controles y gestos
├── Reproducción y audio
├── Biblioteca
├── Fuentes y descargas
├── Widget de inicio
└── Sistema
```

`Sistema` agrupa internamente:

```text
Sistema
├── Dispositivos e integración
├── Datos y archivos
├── Diagnóstico
└── Acerca de
```

---

## 2. Alcance de la auditoría

La revisión se realizó sobre las pantallas y persistencia actualmente visibles en el repositorio, principalmente:

- `lib/features/settings/settings_screen.dart`
- `lib/features/settings/appearance_screen.dart`
- `lib/features/settings/control_screen.dart`
- `lib/features/settings/settings_category_screens.dart`
- `lib/features/settings/widgets_screen.dart`
- `lib/data/db/database.dart`
- `lib/features/home/home_screen.dart`
- componentes auxiliares de controles, densidad, visualizadores y temas.

También se revisaron las preferencias persistentes de `AppSettings` para detectar ajustes que existen en base de datos aunque no estén expuestos directamente en la pantalla raíz de Ajustes.

---

## 3. Inventario completo de configuración actual

### 3.1. Pantalla raíz de Ajustes

Actualmente presenta:

#### Tu experiencia
- Control
- Apariencia

#### Configuración
- Audio y calidad
- Biblioteca
- Fuentes y descargas
- Datos y privacidad
- Sistema y ayuda

Además:
- Buscador de ajustes.
- Tarjeta/guía de Auris.

### Evaluación

La pantalla raíz es razonablemente compacta, pero los nombres `Control` y `Apariencia` ocultan demasiadas funciones internas. El problema real está en el segundo nivel.

---

## 4. Inventario actual: Control

Archivo principal:

`lib/features/settings/control_screen.dart`

### 4.1. Diseño del reproductor

Actualmente incluye:

- Preset de controles.
- Distribución completa.
- Distribución para una mano.
- Lado izquierdo/derecho.
- Modo personalizado.
- Editor de controles visibles.
- Orden de controles principales.
- Orden de controles secundarios.
- Controles ocultos.
- Favorito como acción especial.

#### Problema detectado: Favorito

El código actual trata `Favorito` como una acción fija centrada debajo de los controles de reproducción.

Esto contradice la decisión UX más reciente: **Favorito debe estar asociado a la canción y mostrarse junto al título**, a la derecha del bloque de información.

#### Decisión recomendada

Eliminar `favorite` del sistema de `PlayerControlLayout`.

Debe pasar a una preferencia independiente:

```text
Mostrar favorito junto al título    [ON]
```

o, si no se desea ofrecer esa personalización:

```text
Favorito forma parte fija del encabezado de la canción.
```

La segunda opción es preferible porque evita una configuración innecesaria.

---

### 4.2. Densidad

Opciones actuales:

- Compacta.
- Normal.
- Espaciosa.

#### Evaluación

La opción es válida, pero **no pertenece conceptualmente a Controles**.

La densidad modifica la composición visual del reproductor, no la interacción.

#### Destino recomendado

`Reproductor > Diseño > Densidad`

---

### 4.3. Gestos del reproductor

Actualmente:

- Doble toque → reproducir/pausar.
- Deslizar horizontal → cambiar canción.
- Deslizar vertical → volumen.
- Deslizar abajo → cerrar.

#### Evaluación

Está correctamente relacionado con la interacción.

#### Destino recomendado

`Controles y gestos > Gestos`

---

### 4.4. Reproducción

Actualmente dentro de `Control`:

- Restaurar cola al iniciar.
- Gapless.
- Crossfade.
- Fade al pausar.

#### Problema

Ninguna de estas opciones es un control.

Son reglas del motor de reproducción.

#### Destino recomendado

`Reproducción y audio > Reproducción`

---

### 4.5. Auriculares y dispositivos

Actualmente:

- Pausar al desconectar audífonos.
- Reanudar al volver a conectarlos.
- Acceso a Widget y controles de inicio.
- Información sobre notificación, bloqueo y Android Auto.

#### Problema

Se mezclan tres dominios:

- comportamiento de auriculares;
- acceso al widget;
- integraciones del sistema.

#### Destino recomendado

```text
Sistema
└── Dispositivos e integración
    ├── Auriculares
    ├── Bluetooth
    ├── Notificación multimedia
    ├── Pantalla de bloqueo
    └── Android Auto
```

El acceso al widget debe desaparecer de esta pantalla.

---

## 5. Inventario actual: Apariencia

Archivo:

`lib/features/settings/appearance_screen.dart`

Actualmente tiene tres pestañas:

- Aplicación
- Reproductor
- Widget

Esta estructura debe desaparecer como agrupación de primer nivel.

---

## 6. Apariencia de la aplicación actual

### 6.1. Color de acento

Actualmente:

- `AccentIdentity`
- selector de identidad cromática.

#### Evaluación

Correcto como concepto, pero en el futuro debe convertirse en parte de un **tema visual completo**, no ser el eje principal del sistema de temas.

---

### 6.2. Fondo

Actualmente:

- `BackgroundDepth`
- profundidad visual.
- negro puro mediante `pureBlackBackground`.

#### Observación

`pureBlackBackground` está parcialmente duplicado semánticamente con `BackgroundDepth.pureBlack`.

#### Recomendación técnica

Mantener **una sola fuente de verdad**.

Preferible:

```text
backgroundDepth = pureBlack
```

y eliminar progresivamente el booleano redundante.

---

### 6.3. Superficies

Actualmente:

- `GlassIntensity`

#### Evaluación

Correcto como token visual, pero no como única variación estructural de tema.

Un sistema real de temas debería definir:

- material/superficie;
- fondo;
- radios;
- bordes;
- sombra;
- tipografía;
- iconografía;
- densidad;
- textura;
- contraste;
- acento.

---

### 6.4. Reducción de movimiento

Actualmente aparece una explicación indicando que:

- Auris;
- visualizador;
- transiciones;

respetan la preferencia del sistema para reducir animaciones.

#### Evaluación

Esto es **información de accesibilidad**, no una preferencia de Apariencia.

#### Destino recomendado

Si solo informa:

`Sistema > Accesibilidad y compatibilidad`

Si en el futuro hay un override manual:

`Apariencia > Movimiento`

---

## 7. Apariencia del reproductor actual

### 7.1. Color dinámico

- Usa el color dominante de la portada.

#### Destino

`Reproductor > Fondo y ambiente`

---

### 7.2. Fondo de video musical

- Activable.
- Solo Wi‑Fi.

#### Destino

`Reproductor > Fondo y ambiente`

---

### 7.3. Escena visual

- `PlayerVisualScene`

#### Destino

`Reproductor > Diseño`

---

### 7.4. Relación de aspecto

- `PlayerSceneAspectRatio`

#### Destino

`Reproductor > Diseño`

---

### 7.5. Estilo del visualizador

- `VisualizerStyle`
- Automático.
- estilos concretos existentes en el enum.

#### Destino

`Reproductor > Visualizador > Estilo`

---

### 7.6. Calidad del visualizador

Actualmente:

- Eco.
- Normal.
- Ultra.

#### Destino

`Reproductor > Visualizador > Rendimiento`

No debe estar al mismo nivel visual que la selección artística del estilo.

---

### 7.7. Reducir efectos visuales

Actualmente reduce:

- partículas;
- destellos;
- variaciones rápidas de color.

#### Destino

`Reproductor > Visualizador > Rendimiento`

Debe mantener prioridad sobre `Ultra` cuando sea necesario por batería, accesibilidad o ahorro de energía.

---

## 8. Nuevo sistema de color reactivo propuesto

Actualmente el visualizador utiliza una paleta interna y un comportamiento cromático reactivo, pero la configuración propuesta debe ser universal para los estilos que puedan interpretarla.

### 8.1. Editor universal de mapa de color

Ubicación:

```text
Reproductor
└── Visualizador
    └── Color reactivo
```

Configuración base:

```text
0–25 %       Azul / Cian
25–50 %      Violeta
50–75 %      Magenta / Rosa
75–90 %      Naranja / Rosa cálido
90–100 %     Rosa claro / Blanco
Peak          Blanco / color de pico
```

Debe permitir:

- modificar color;
- modificar umbral;
- añadir punto;
- eliminar punto;
- reordenar puntos;
- restaurar preset;
- guardar presets;
- vista previa en tiempo real.

---

### 8.2. Modos de aplicación del color

Debe ser una configuración separada del mapa.

#### Global

La energía general mueve toda la visualización por la paleta.

Ventaja:
- aspecto cohesivo.

Desventaja:
- un pico puede recolorear demasiado la escena.

#### Por columna

Cada banda/columna recibe un color único según su intensidad.

Ejemplo:

```text
columna baja  → cian completa
columna media → violeta completa
columna alta  → rosa completa
peak          → blanco completo o marcador blanco
```

#### Por segmento / intensidad — recomendado

Cada elemento visual interpreta el mapa según su intensidad local.

En barras:

```text
      blanco
      naranja
      rosa
      violeta
      cian
```

Una barra baja puede mostrar solo cian.

Una barra media puede alcanzar cian + violeta + rosa.

Una barra extrema puede llegar hasta naranja/blanco.

### Generalización a otras animaciones

La misma semántica debe traducirse al lenguaje propio de cada estilo:

- **Barras:** segmentos verticales.
- **Ondas:** color local a lo largo de la onda.
- **Aros:** sectores/arcos con distinta energía.
- **Ribbons:** filamentos y zonas energéticas.
- **Prism:** partículas/strands según energía local.
- **Cosmic:** estrellas/orbes según espectro/peak.
- **Electric Waves:** tramos y flares.
- **Partículas:** color por energía de partícula.

### Regla arquitectónica

El visualizador no debe preguntar:

> “¿Qué color soy?”

Debe preguntar:

```text
ColorReactiveMap.resolve(
    intensity,
    position,
    peak,
    applicationMode
)
```

El motor común determina el color; cada visualización decide **dónde aplicarlo**.

---

## 9. Animación de carátula propuesta

Actualmente no debe confundirse con Visualizador.

Ubicación:

```text
Reproductor
└── Carátula
    └── Animación
```

Opciones sugeridas:

- Estática.
- Pulso suave.
- Zoom dinámico.
- Giro/parallax 3D.
- Partículas alrededor.
- Fondo reactivo.

### Regla

La animación de carátula:

- no cambia el audio;
- no cambia el visualizador;
- no pertenece a Tema;
- debe respetar “Reducir movimiento”;
- debe poder desactivarse independientemente.

---

## 10. Sistema de temas real propuesto

Los temas deben modificar la identidad visual completa de la app, no solamente el color de acento.

Ubicación:

```text
Apariencia
└── Tema
```

### 10.1. Nebula Glass

Características:

- oscuro;
- fondos profundos/degradados;
- superficies translúcidas;
- glass elevado;
- bordes suaves iluminados;
- glow;
- radios amplios;
- tipografía moderna;
- espaciado equilibrado;
- sensación inmersiva.

No debe forzar los colores del visualizador.

### 10.2. AMOLED Mono

Características:

- negro puro;
- superficies planas;
- mínima transparencia;
- mínima sombra;
- bordes discretos;
- alto contraste;
- iconografía lineal;
- densidad algo más compacta;
- orientado a legibilidad, concentración y consumo.

No significa “Nebula pero verde”.

Debe cambiar materialidad y jerarquía.

### 10.3. Paper Loft

Características:

- superficies claras/cálidas;
- tarjetas tipo papel;
- sombras suaves;
- poco glow;
- radios medios;
- mayor aire vertical;
- tipografía con carácter editorial;
- fondos suaves o texturizados;
- jerarquía visual más tradicional.

No debe limitarse a cambiar el fondo a blanco.

---

## 11. Personalización avanzada del tema

Ubicación:

```text
Apariencia
├── Tema
└── Personalizar tema
```

Debe poder modificar, según el tema:

- acento;
- superficie;
- profundidad;
- intensidad de borde;
- nivel de sombra;
- redondez;
- contraste de texto;
- textura;
- densidad;
- espaciado;
- estilo de iconos;
- estilo tipográfico.

### Regla importante

No todos los temas tienen que exponer exactamente los mismos sliders.

Ejemplo:

`AMOLED Mono` no necesita intensidad de Glass si su identidad es plana.

La interfaz debe mostrar solo tokens compatibles con el tema activo.

---

## 12. Widget de inicio actual

Archivo:

`lib/features/settings/widgets_screen.dart`

Actualmente incluye:

### Activación
- habilitar widget;
- número de widgets colocados.

### Vista previa
- preview interno.

### Estilo
- estilos disponibles.

### Tamaño
- 4x1.
- 4x2.
- 4x3.

### Apariencia
- claro.
- oscuro.
- según estilo.
- color de acento.
- opacidad.

### Contenido
- portada;
- título;
- artista;
- controles;
- barra de progreso;
- duración;
- siguiente canción.

### Comportamiento
- abrir reproductor al tocar.

### Instrucciones
- cómo añadir el widget.

### Conclusión

Tiene suficiente alcance para ser una sección independiente.

No debe seguir siendo una pestaña de Apariencia ni un enlace secundario dentro de Control.

---

## 13. Reproducción y audio actual

En `AppSettings` existen:

- `restoreQueueOnStart`
- `gaplessEnabled`
- `crossfadeSeconds`
- `fadeOnPause`
- `fadeOnPauseMs`
- `playbackSpeed`
- `playbackPitch`

### Hallazgo

`playbackSpeed` y `playbackPitch` existen en persistencia aunque no forman parte visible de la actual pantalla `Audio y calidad` revisada.

Esto debe resolverse de una de dos maneras:

### Opción A — son controles contextuales y no ajustes globales

Mantenerlos en el reproductor/ecualizador y documentar que la última velocidad/tono utilizados se persisten, pero no son una preferencia de Ajustes.

### Opción B — son defaults globales

Exponer:

```text
Reproducción y audio
└── Reproducción
    ├── Velocidad predeterminada
    └── Tono predeterminado
```

**No se debe dejar el significado ambiguo.**

Recomendación: **Opción A**, salvo que exista un caso real de uso para fijarlos globalmente.

---

## 14. Audio y calidad actual

Actualmente contiene:

### Procesamiento
- Ecualizador.
- Direct Mode.
- Offload.

### Salida actual
- información de dispositivo.

### Estado

Esta sección es conceptualmente correcta.

### Nueva ubicación

```text
Reproducción y audio
├── Reproducción
└── Audio
    ├── Ecualizador
    ├── Direct Mode
    ├── Offload
    └── Salida
```

---

## 15. Ecualizador y mejora de audio

La base de datos contiene además:

### EqualizerState
- habilitado;
- número de bandas;
- ganancias;
- preamp;
- prevención automática de clipping;
- balance;
- mono;
- preset.

### EqualizerPresets
- presets personalizados.

### EnhancementState
- habilitado;
- perfil;
- nivel de detalle;
- multibanda;
- normalización;
- target level;
- expansión estéreo;
- ancho estéreo.

### OutputProfiles
- perfil por salida;
- EQ por salida;
- mejora por salida.

### LoudnessAnalyses
- ganancia;
- pico;
- análisis por canción.

### Regla de agrupación

Todo esto pertenece a:

```text
Reproducción y audio
└── Audio
    ├── Ecualizador
    ├── Mejora de sonido
    ├── Normalización
    ├── Balance y mono
    └── Perfiles por dispositivo
```

Si parte de estas opciones vive dentro del ecualizador, debe mantenerse un único acceso canónico desde `Reproducción y audio`.

---

## 16. Biblioteca actual

Actualmente:

### Escaneo
- volver a escanear.
- escanear al iniciar.
- fecha del último escaneo.

### Carpetas
- carpetas excluidas.
- carpetas fuente.

### Estado

Está correctamente agrupado.

Se mantiene como:

```text
Biblioteca
├── Escaneo
├── Carpetas de origen
└── Carpetas excluidas
```

---

## 17. Configuración de Inicio

La base de datos contiene:

`homeSectionsJson`

La pantalla Inicio permite:

- seleccionar secciones;
- ordenar/activar secciones mediante configuración contextual.

Secciones actuales:

- continuar escuchando;
- favoritos;
- reproducidos recientemente;
- álbumes recientes;
- más reproducidos;
- listas destacadas.

### Decisión de arquitectura

No es obligatorio trasladar esta configuración a Ajustes.

Es preferible mantenerla **contextual en Inicio**, porque el usuario ve inmediatamente lo que está configurando.

Sin embargo, el buscador global de Ajustes puede indexarla como:

```text
Personalizar Inicio
```

y abrir directamente el editor contextual.

### Regla

Las preferencias contextuales pueden vivir fuera de Ajustes si:

1. el contexto es obvio;
2. hay vista previa inmediata;
3. el buscador de Ajustes puede encontrarlas.

---

## 18. Orden de Biblioteca

Existe:

`librarySortJson`

### Recomendación

Mantener orden/filtro dentro de cada vista de Biblioteca.

No trasladarlo a Ajustes globales.

La persistencia solo recuerda el estado elegido.

---

## 19. Temporizador

Existen:

- `sleepTimerMinutes`
- `sleepTimerFinishTrack`

### Recomendación

El temporizador es una acción de reproducción contextual.

Debe vivir en:

- reproductor;
- hoja de acciones;
- control personalizable.

No debe convertirse en una categoría de Ajustes.

Si se desea recordar defaults:

```text
Reproducción y audio
└── Temporizador
    └── Finalizar canción actual por defecto
```

pero solo si existe un caso de uso claro.

---

## 20. Fuentes y descargas actual

Actualmente:

- fuentes remotas;
- SMB;
- WebDAV;
- enlaces directos;
- radio;
- descargas de internet.

### Nuevo nombre recomendado

`Fuentes y descargas` es válido.

Internamente:

```text
Fuentes y descargas
├── Fuentes remotas
│   ├── SMB
│   ├── WebDAV
│   ├── Enlaces
│   └── Radio
└── Descargas
```

No mezclar aquí las carpetas locales escaneadas: esas pertenecen a Biblioteca.

---

## 21. Datos y privacidad actual

Actualmente incluye:

- incrustar portada en archivo;
- escritura segura;
- exportación M3U;
- funcionamiento local.

### Problema

Solo la primera es una preferencia.

Las demás son información o acciones contextuales.

### Reorganización

```text
Sistema
└── Datos y archivos
    ├── Metadatos
    │   └── Incrustar portada en archivo
    ├── Escritura segura
    ├── Exportación
    └── Privacidad
```

### Exportación M3U

Si la exportación solo ocurre desde cada lista, no crear un botón duplicado en Ajustes.

Mostrar únicamente una explicación o eliminarla si no aporta una acción útil.

---

## 22. Sistema y ayuda actual

Actualmente:

### Diagnóstico
- registro de reproducción.

### Compatibilidad
- Bluetooth;
- cable;
- pantalla de bloqueo;
- Android Auto.

### Acerca de
- información de NuvTune.

### Reorganización

```text
Sistema
├── Dispositivos e integración
├── Datos y archivos
├── Diagnóstico
└── Acerca de
```

Esto permite crecer sin convertir “Sistema y ayuda” en un cajón de sastre.

---

## 23. Estructura final propuesta

### Pantalla raíz

```text
AJUSTES

Personalización

[ Apariencia ]
Tema, superficies y estilo de la aplicación

[ Reproductor ]
Escena, carátula, fondo y visualizador


Configuración

Controles y gestos
Botones, distribución e interacción

Reproducción y audio
Reproducción, ecualizador, procesamiento y salida

Biblioteca
Escaneo, carpetas y contenido local

Fuentes y descargas
Red, radio, enlaces y contenido descargado

Widget de inicio
Diseño, contenido y comportamiento

Sistema
Dispositivos, datos, diagnóstico y acerca de
```

---

## 24. Árbol completo recomendado

```text
Ajustes
│
├── Apariencia
│   ├── Tema
│   │   ├── Nebula Glass
│   │   ├── AMOLED Mono
│   │   └── Paper Loft
│   │
│   ├── Modo
│   │   ├── Sistema
│   │   ├── Claro
│   │   └── Oscuro
│   │
│   └── Personalizar tema
│       ├── Acento
│       ├── Superficies
│       ├── Fondo / profundidad
│       ├── Bordes
│       ├── Sombras
│       ├── Redondez
│       ├── Tipografía
│       ├── Iconografía
│       ├── Densidad general
│       └── Textura
│
├── Reproductor
│   ├── Diseño
│   │   ├── Escenario
│   │   ├── Relación de aspecto
│   │   └── Densidad
│   │
│   ├── Carátula
│   │   └── Animación
│   │
│   ├── Fondo y ambiente
│   │   ├── Color dinámico desde portada
│   │   └── Video musical en Wi‑Fi
│   │
│   └── Visualizador
│       ├── Estilo
│       ├── Color reactivo
│       │   ├── Preset
│       │   ├── Editor del mapa
│       │   └── Modo de aplicación
│       │       ├── Por intensidad
│       │       ├── Por columna
│       │       └── Global
│       ├── Calidad
│       │   ├── Eco
│       │   ├── Normal
│       │   └── Ultra
│       └── Reducir efectos
│
├── Controles y gestos
│   ├── Distribución
│   │   ├── Preset
│   │   ├── Mano dominante
│   │   └── Editar controles
│   └── Gestos
│       ├── Doble toque
│       ├── Swipe de canción
│       ├── Swipe de volumen
│       └── Swipe para cerrar
│
├── Reproducción y audio
│   ├── Reproducción
│   │   ├── Restaurar cola
│   │   ├── Gapless
│   │   ├── Crossfade
│   │   └── Fade al pausar
│   │
│   └── Audio
│       ├── Ecualizador
│       ├── Mejora de sonido
│       ├── Normalización
│       ├── Balance / mono
│       ├── Direct Mode
│       ├── Offload
│       └── Perfiles por salida
│
├── Biblioteca
│   ├── Escanear ahora
│   ├── Escanear al abrir
│   ├── Carpetas origen
│   └── Carpetas excluidas
│
├── Fuentes y descargas
│   ├── Fuentes remotas
│   │   ├── SMB
│   │   ├── WebDAV
│   │   ├── Enlaces
│   │   └── Radio
│   └── Descargas
│
├── Widget de inicio
│   ├── Activar
│   ├── Diseño
│   │   ├── Estilo
│   │   ├── Tamaño
│   │   ├── Tema
│   │   ├── Acento
│   │   └── Opacidad
│   ├── Contenido
│   │   ├── Portada
│   │   ├── Título
│   │   ├── Artista
│   │   ├── Controles
│   │   ├── Progreso
│   │   ├── Duración
│   │   └── Siguiente canción
│   └── Comportamiento
│       └── Abrir reproductor al tocar
│
└── Sistema
    ├── Dispositivos e integración
    │   ├── Pausar al desconectar auriculares
    │   ├── Reanudar al conectar
    │   ├── Bluetooth
    │   ├── Notificación multimedia
    │   ├── Pantalla de bloqueo
    │   └── Android Auto
    │
    ├── Datos y archivos
    │   ├── Incrustar portada
    │   ├── Escritura segura
    │   ├── Exportación
    │   └── Privacidad
    │
    ├── Diagnóstico
    │   └── Registro de reproducción
    │
    └── Acerca de
        ├── NuvTune
        ├── versión
        └── información técnica
```

---

## 25. Matriz de migración: ubicación actual → ubicación nueva

| Opción | Ubicación actual | Ubicación propuesta |
|---|---|---|
| AccentIdentity | Apariencia > Aplicación | Apariencia > Tema/Personalización |
| BackgroundDepth | Apariencia > Aplicación | Apariencia > Personalización |
| Pure Black | Apariencia > Aplicación | Tema/Modo, sin booleano redundante |
| GlassIntensity | Apariencia > Aplicación | Apariencia > Superficies |
| Color dinámico portada | Apariencia > Reproductor | Reproductor > Fondo y ambiente |
| Video musical | Apariencia > Reproductor | Reproductor > Fondo y ambiente |
| Escena | Apariencia > Reproductor | Reproductor > Diseño |
| Relación de aspecto | Apariencia > Reproductor | Reproductor > Diseño |
| Visualizador | Apariencia > Reproductor | Reproductor > Visualizador |
| Calidad visualizador | Apariencia > Reproductor | Reproductor > Visualizador > Rendimiento |
| Reducir efectos | Apariencia > Reproductor | Reproductor > Visualizador > Rendimiento |
| Widget | Apariencia | Widget de inicio |
| Preset controles | Control | Controles y gestos |
| Mano dominante | Control | Controles y gestos |
| Orden de controles | Control | Controles y gestos |
| Favorito | Control/layout | Reproductor: acción fija junto al título |
| Densidad player | Control | Reproductor > Diseño |
| Gestos | Control | Controles y gestos |
| Restaurar cola | Control | Reproducción y audio |
| Gapless | Control | Reproducción y audio |
| Crossfade | Control | Reproducción y audio |
| Fade pausa | Control | Reproducción y audio |
| Pausa desconexión | Control | Sistema > Dispositivos |
| Reanudar conexión | Control | Sistema > Dispositivos |
| EQ | Audio y calidad | Reproducción y audio |
| Direct Mode | Audio y calidad | Reproducción y audio |
| Offload | Audio y calidad | Reproducción y audio |
| Escaneo | Biblioteca | Biblioteca |
| Carpetas | Biblioteca | Biblioteca |
| SMB/WebDAV/Radio | Fuentes | Fuentes y descargas |
| Descargas | Fuentes | Fuentes y descargas |
| Embed cover | Datos y privacidad | Sistema > Datos y archivos |
| Escritura segura | Datos y privacidad | Sistema > Datos y archivos |
| M3U | Datos y privacidad | Acción contextual / Datos |
| Registro de fallos | Sistema y ayuda | Sistema > Diagnóstico |
| Bluetooth/bloqueo | Sistema y ayuda | Sistema > Dispositivos |
| Android Auto | Sistema y ayuda | Sistema > Dispositivos |
| Acerca de | Sistema y ayuda | Sistema > Acerca de |
| Home sections | Inicio contextual | Mantener contextual |
| Library sort | Biblioteca contextual | Mantener contextual |
| Sleep timer | Player contextual | Mantener contextual |

---

## 26. Configuraciones nuevas necesarias

Estas configuraciones **no deben confundirse con ajustes existentes**. Son extensiones propuestas.

### Tema real

Persistir:

```text
appThemeId
appThemeMode
```

Ejemplo:

```text
nebula_glass
amoled_mono
paper_loft
```

### Overrides de tema

Evitar crear una columna por cada detalle si los temas van a crecer.

Preferible:

```text
themeOverridesJson
```

con versión de esquema:

```json
{
  "version": 1,
  "borderIntensity": 0.5,
  "shadowIntensity": 0.4,
  "cornerScale": 1.0,
  "surfaceStyle": "glass"
}
```

### Animación de carátula

```text
playerCoverAnimationId
```

### Mapa de color reactivo

```text
visualizerColorMapJson
visualizerColorMode
visualizerColorPresetId
```

Ejemplo conceptual:

```json
{
  "version": 1,
  "points": [
    {"value": 0.00, "color": "#00CFFF"},
    {"value": 0.25, "color": "#7127FF"},
    {"value": 0.50, "color": "#FF2D9A"},
    {"value": 0.75, "color": "#FF6A38"},
    {"value": 0.90, "color": "#FFC28B"},
    {"value": 1.00, "color": "#FFFFFF"}
  ]
}
```

---

## 27. Reglas para evitar futuras mezclas

Antes de añadir cualquier nueva opción debe responderse:

### ¿Cambia cómo se ve toda la app?
→ `Apariencia`

### ¿Cambia lo que se ve específicamente mientras suena música?
→ `Reproductor`

### ¿Cambia cómo el usuario interactúa con los botones o gestos?
→ `Controles y gestos`

### ¿Cambia cómo se reproduce o procesa el audio?
→ `Reproducción y audio`

### ¿Cambia qué archivos forman la biblioteca local?
→ `Biblioteca`

### ¿Cambia de dónde se obtiene música externa?
→ `Fuentes y descargas`

### ¿Cambia el widget Android?
→ `Widget de inicio`

### ¿Cambia una integración del SO, privacidad, archivos o diagnóstico?
→ `Sistema`

### ¿Solo afecta una pantalla y tiene feedback inmediato?
→ preferir configuración contextual dentro de esa pantalla.

---

## 28. Política de configuración contextual

No todo debe ir a Ajustes.

Mantener fuera de Ajustes:

- orden de una lista;
- filtro de Biblioteca;
- temporizador;
- velocidad temporal;
- pitch temporal;
- configuración de secciones de Inicio;
- exportar una playlist específica;
- acciones sobre una canción concreta.

### Principio

**Ajustes contiene preferencias duraderas.  
La pantalla contextual contiene decisiones operativas.**

---

## 29. Buscador de Ajustes

El buscador actual debe mantenerse y ampliarse.

Debe indexar no solo destinos, sino subopciones.

Ejemplos:

```text
"crossfade"
→ Reproducción y audio > Reproducción > Crossfade

"favorito"
→ Reproductor / información del botón junto al título

"visualizador"
→ Reproductor > Visualizador

"color"
→ Apariencia
→ Reproductor > Visualizador > Color reactivo

"widget"
→ Widget de inicio

"auriculares"
→ Sistema > Dispositivos e integración

"secciones inicio"
→ abrir editor contextual de Inicio
```

Debe permitir deep-links.

---

## 30. Navegación y rutas recomendadas

Evitar pestañas múltiples dentro de una única pantalla gigante.

Rutas sugeridas:

```text
/settings
/settings/appearance
/settings/appearance/theme
/settings/appearance/customize

/settings/player
/settings/player/cover
/settings/player/visualizer
/settings/player/visualizer/colors

/settings/controls
/settings/controls/layout
/settings/controls/gestures

/settings/playback
/settings/playback/audio
/settings/playback/equalizer
/settings/playback/enhancement

/settings/library

/settings/sources

/settings/widget

/settings/system
/settings/system/devices
/settings/system/data
/settings/system/diagnostics
/settings/system/about
```

---

## 31. Vista previa

Las áreas visuales deben ofrecer preview inmediato.

### Apariencia
Preview de:

- Inicio;
- Biblioteca;
- tarjeta;
- navegación;
- botón;
- texto.

### Reproductor
Preview de:

- escena;
- carátula;
- título;
- favorito a la derecha;
- visualizador;
- controles.

### Visualizador
Preview animado simplificado.

### Widget
Preview del tamaño seleccionado.

### Regla

No poner previews en Audio, Biblioteca, Sistema o Privacidad salvo que ayuden a entender una opción.

---

## 32. Dependencias entre configuraciones

Debe existir lógica explícita para evitar estados contradictorios.

### Tema AMOLED

Si el tema fuerza negro puro:

- ocultar o deshabilitar controles de profundidad incompatibles;
- no mantener dos estados competidores.

### Reduce Motion del sistema

Debe tener prioridad sobre:

- animación de carátula;
- partículas;
- visualizador;
- transiciones decorativas.

### Reducir efectos visuales

Debe afectar solo al reproductor/visualizador, no sustituir la accesibilidad global.

### Calidad Eco

Debe reducir:

- FPS;
- bandas;
- partículas;
- glow;
- complejidad.

No debe cambiar el mapa de color elegido.

### Power Saver / batería baja

Puede forzar temporalmente Eco.

Debe mostrarse como estado efectivo, no sobrescribir permanentemente la preferencia del usuario.

### Direct Mode / Offload

Cuando no exista PCM/FFT real:

- el visualizador debe indicar o manejar modo ambiental;
- no simular beats falsos;
- la UI no debe prometer reacción espectral real cuando no está disponible.

---

## 33. Persistencia: evitar deuda técnica

### Recomendación

Separar conceptualmente los settings aunque sigan viviendo inicialmente en `AppSettings`.

A medio plazo:

```text
AppAppearanceSettings
PlayerAppearanceSettings
PlaybackSettings
ControlSettings
WidgetSettings
LibrarySettings
SystemSettings
```

No es obligatorio crear seis tablas inmediatamente.

Lo importante es que:

- nombres de campos indiquen su dominio;
- serializers tengan versión;
- enums persistentes usen IDs estables;
- no depender de índice de enum cuando pueda reordenarse.

La implementación de `playerVisualizerQuality` ya sigue correctamente este criterio al guardar un ID estable.

---

## 34. Migraciones necesarias

Si se implementa la reorganización visual **sin cambiar persistencia**, no hace falta migración de datos.

Si se implementan temas reales:

1. agregar `appThemeId`;
2. mapear configuración actual a un tema inicial;
3. mantener `accentId`, `backgroundDepth` y `glassIntensity` como overrides durante transición;
4. eliminar campos redundantes solo en una migración posterior.

Ejemplo de mapeo:

```text
pureBlackBackground = true
→ appThemeId = amoled_mono

resto
→ appThemeId = nebula_glass
```

No inferir `Paper Loft` automáticamente porque actualmente no existe equivalente claro.

---

## 35. Prioridad de implementación

### Fase 1 — Reorganización sin cambiar comportamiento

- Crear nuevas rutas.
- Mover controles.
- Separar Widget.
- Separar Reproductor.
- Mover reproducción fuera de Control.
- Mover auriculares a Sistema.
- Corregir Favorito.
- Actualizar buscador.
- No tocar motor.

Riesgo: bajo.

### Fase 2 — Sistema de temas real

- `appThemeId`.
- Nebula Glass.
- AMOLED Mono.
- Paper Loft.
- tokens semánticos.
- eliminar hardcodes visuales incompatibles.

Riesgo: medio.

### Fase 3 — Visualizador configurable

- mapa de colores;
- modos Global / Columna / Intensidad;
- presets;
- preview;
- integración con todos los painters.

Riesgo: medio-alto por consistencia gráfica y rendimiento.

### Fase 4 — Animación de carátula

- presets;
- integración con accesibilidad;
- optimización energética.

Riesgo: medio.

---

## 36. Criterios de aceptación

La reorganización puede considerarse terminada cuando:

- [ ] ninguna opción de reproducción permanezca en Control;
- [ ] Widget tenga una única pantalla canónica;
- [ ] Reproductor sea independiente de Apariencia de aplicación;
- [ ] Favorito ya no se describa como botón centrado bajo controles;
- [ ] Densidad esté en Reproductor;
- [ ] auriculares estén en Sistema/Dispositivos;
- [ ] el buscador encuentre cada ajuste en su nueva ruta;
- [ ] no existan dos entradas que configuren la misma preferencia;
- [ ] los ajustes contextuales permanezcan en su contexto;
- [ ] todos los deep-links antiguos tengan redirección o sean actualizados;
- [ ] los valores persistidos actuales se conserven;
- [ ] los tests cubran rutas y mutaciones;
- [ ] Reduce Motion siga teniendo prioridad;
- [ ] Eco/Normal/Ultra no modifiquen la elección cromática;
- [ ] los nuevos temas cambien materialidad, no solo color;
- [ ] visualizador y tema de aplicación permanezcan desacoplados;
- [ ] el widget no herede accidentalmente preferencias incompatibles del tema principal.

---

## 37. Tests recomendados

### Navegación

- cada entrada abre la pantalla correcta;
- búsqueda abre deep-link correcto;
- back stack consistente.

### Persistencia

- mover una opción de pantalla no altera su valor;
- migración conserva preferencias anteriores.

### Temas

- los tres temas producen `ThemeData` diferente;
- cambio de tema no cambia configuración del visualizador;
- overrides son restaurables.

### Visualizador

- mapa de color es válido;
- puntos ordenados 0–1;
- no hay rangos vacíos;
- no se permiten dos puntos incompatibles en la misma posición salvo regla explícita;
- todos los estilos soportados reciben color;
- estilos no soportados usan fallback controlado.

### Accesibilidad

- reduce motion desactiva animaciones incompatibles;
- alto contraste mantiene legibilidad;
- texto cumple contraste mínimo razonable.

### Widget

- tamaño filtra contenido que no cabe;
- preview coincide con RemoteViews;
- widget funciona con app cerrada.

---

## 38. Decisiones que NO deben quedar abiertas

Para evitar futuros cabos sueltos, estas decisiones se fijan desde esta propuesta:

1. **Tema de aplicación y visualizador son sistemas independientes.**
2. **El visualizador no hereda automáticamente el acento del tema.**
3. **Favorito pertenece al bloque de información de la canción.**
4. **Widget es una sección independiente.**
5. **Densidad del reproductor pertenece a Reproductor.**
6. **Gapless/Crossfade/Fade pertenecen a Reproducción.**
7. **Auriculares y Android Auto pertenecen a Sistema/Dispositivos.**
8. **Ajustes contextuales no se duplican en Ajustes globales.**
9. **Los temas deben cambiar estructura/materialidad, no solo color.**
10. **El color reactivo debe ser universal, pero cada visualización lo interpreta según su geometría.**
11. **La calidad del visualizador controla rendimiento, no identidad cromática.**
12. **La accesibilidad del sistema tiene prioridad sobre efectos decorativos.**
13. **No se deben guardar índices de enum nuevos cuando un ID estable sea más seguro.**
14. **Toda nueva preferencia debe tener un único propietario conceptual.**

---

## 39. Estado de campos persistentes actuales

Resumen de `AppSettings` revisado:

### Biblioteca
- `scanOnStart`
- `lastScanAt`

### Apariencia
- `useDynamicColor`
- `pureBlackBackground`
- `accentId`
- `backgroundDepth`
- `glassIntensity`

### Reproducción
- `restoreQueueOnStart`
- `gaplessEnabled`
- `crossfadeSeconds`
- `fadeOnPause`
- `fadeOnPauseMs`

### Calidad
- `directMode`
- `allowOffload`
- `playbackSpeed`
- `playbackPitch`

### Metadatos
- `embedCoverInFile`

### Widget
- `widgetEnabled`
- `widgetStyle`
- `widgetTheme`
- `widgetSize`
- `widgetAccentColor`
- `widgetOpacity`
- `widgetShowCover`
- `widgetShowTitle`
- `widgetShowArtist`
- `widgetShowControls`
- `widgetShowProgress`
- `widgetShowDuration`
- `widgetShowNextInQueue`
- `widgetOpenOnTap`
- `widgetPauseOnDisconnect`
- `widgetResumeOnConnect`

### Temporizador
- `sleepTimerMinutes`
- `sleepTimerFinishTrack`

### Inicio
- `homeSectionsJson`

### Biblioteca contextual
- `librarySortJson`

### Reproductor visual
- `videoBackgroundEnabled`
- `playerVisualizerStyle`
- `playerVisualizerQuality`
- `reduceVisualizerEffects`
- `playerVisualScene`
- `playerSceneAspectRatio`

### Controles
- `playerControlPreset`
- `playerControlLayoutJson`
- `playerControlHandedness`
- `playerDensity`
- `playerGestureDoubleTap`
- `playerGestureSwipeTrack`
- `playerGestureSwipeVolume`
- `playerGestureSwipeDismiss`

### Hallazgo técnico importante

Los nombres `widgetPauseOnDisconnect` y `widgetResumeOnConnect` son incorrectos conceptualmente.

No son preferencias del widget.

Deberían migrar eventualmente a:

```text
pauseOnHeadphonesDisconnect
resumeOnHeadphonesConnect
```

Esto reduce deuda semántica y evita que futuras búsquedas en código las clasifiquen mal.

---

## 40. Resultado esperado

Después de esta reorganización, un usuario debería poder razonar así sin aprender la estructura interna de NuvTune:

> “Quiero cambiar cómo se ve la app” → Apariencia.

> “Quiero cambiar la animación o el visualizador” → Reproductor.

> “Quiero mover botones o cambiar gestos” → Controles y gestos.

> “Quiero cambiar crossfade o ecualizador” → Reproducción y audio.

> “Quiero decidir qué música local aparece” → Biblioteca.

> “Quiero conectar SMB o descargar música” → Fuentes y descargas.

> “Quiero cambiar el widget” → Widget.

> “Quiero configurar auriculares, revisar errores o ver información de la app” → Sistema.

Si esa predicción es consistente, la arquitectura de información está funcionando.

---

## 41. Recomendación final

Implementar primero **la reorganización sin alterar comportamiento ni almacenamiento**.

No conviene desarrollar simultáneamente:

- nuevo árbol de Ajustes;
- sistema de temas;
- editor cromático;
- nuevas animaciones;

porque dificultaría separar errores de navegación, persistencia y renderizado.

Orden recomendado:

```text
1. Reorganizar Ajustes.
2. Corregir Favorito.
3. Crear temas reales.
4. Crear editor universal de color reactivo.
5. Añadir animaciones de carátula.
6. Afinar previews y presets.
```

Esta secuencia deja una arquitectura estable antes de añadir más configuración y evita volver a mezclar responsabilidades.

---

## 42. Auditoría de huecos: funciones contextuales y subsistemas fuera de Ajustes

La revisión inicial estaba correctamente centrada en la arquitectura de **Ajustes**, pero no cerraba el inventario completo del producto. Para evitar que la reorganización futura ignore funciones importantes que viven fuera de Ajustes, se incorporan aquí los subsistemas contextuales que deben conservar propietario, acceso y protagonismo explícitos.

### Regla adicional

Una función puede quedar fuera de `Ajustes` y aun así ser una parte principal del producto.

Por tanto, el inventario de arquitectura debe distinguir:

```text
Preferencias globales
→ Ajustes

Preferencias contextuales persistentes
→ pantalla propietaria + acceso desde buscador cuando aporte valor

Acciones operativas
→ contexto donde se ejecutan

Funciones diferenciales del producto
→ navegación/contexto propio + documentación funcional explícita
```

---

## 43. Regalos musicales — función diferencial principal

`Regalos` no es una simple opción de una playlist.

El repositorio contiene un subsistema específico compuesto, entre otros, por:

```text
features/playlists/
├── gift_auris.dart
├── gift_editor_sheet.dart
├── gift_import_controller.dart
├── gift_intro_screen.dart
├── gift_payload.dart
├── gift_receive_wizard.dart
└── gift_send_wizard.dart
```

Además:

- existe acceso directo **Recibir un regalo** desde la pantalla principal de Listas;
- una lista puede convertirse en regalo desde sus acciones;
- una playlist con `giftMode` se intercepta antes de abrirse y presenta primero su introducción;
- existe un flujo independiente de envío;
- existe un flujo independiente de recepción;
- el formato recibido es `.nuvtune-gift`;
- Auris participa en la presentación del regalo;
- el estado de regalo se persiste dentro de `Playlists`.

### Persistencia identificada

```text
giftMode
dedication
giftFrom
giftTo
giftAccentId
giftId
```

### Flujo de envío

```text
Playlist
→ Regalar esta lista…
→ Elegir canciones
→ Dedicatoria
→ De / Para
→ Identidad cromática
→ Resumen
→ Canal de envío
→ Crear paquete
→ Compartir
```

### Flujo de recepción

```text
Recibir un regalo
→ Elegir / abrir .nuvtune-gift
→ Validación
→ Presentación de llegada
→ De / Para
→ Dedicatoria
→ Revisión del contenido
→ Importación
→ Introducción de la playlist regalo
→ Reproducir
```

### Propietario UX

```text
Listas
└── Regalos
```

### NO debe ubicarse en

- Ajustes.
- Apariencia.
- Datos y archivos.
- Fuentes y descargas.

### Sí debe tener

- acceso visible desde Listas;
- acción visible en una playlist;
- documentación funcional propia;
- pruebas de ida y vuelta;
- tratamiento de errores de importación;
- compatibilidad/versionado del payload;
- validación de duplicados mediante `giftId`;
- presentación coherente con Auris.

### Protagonismo de producto

`Regalos musicales` debe considerarse una **función diferencial de NuvTune**, al mismo nivel documental que reproducción, biblioteca, audio avanzado y experiencia visual.

---

## 44. Listas de reproducción — dominio contextual completo

La auditoría inicial mencionaba acciones M3U, pero no inventariaba el dominio completo de playlists.

El propietario funcional es:

```text
Listas
```

Funciones existentes o documentadas en el repositorio:

- crear playlist;
- renombrar;
- cambiar portada;
- duplicar;
- eliminar sin borrar canciones;
- orden manual;
- añadir canciones;
- exportar M3U;
- importar M3U;
- compartir listado;
- convertir/enviar como regalo;
- recibir/importar regalo;
- presentación especial de playlist regalo;
- listas inteligentes.

### Decisión de arquitectura

Estas funciones **no deben migrarse a Ajustes**.

Ajustes solo puede contener defaults globales si algún día existen.

### Menú contextual recomendado

```text
Playlist
├── Reproducir
├── Editar contenido / orden
├── Renombrar
├── Cambiar portada
├── Duplicar
├── Regalar esta lista…
├── Exportar M3U
├── Importar M3U
├── Compartir listado
└── Eliminar
```

`Regalar esta lista…` debe conservar identidad propia y no quedar enterrado dentro de `Compartir`.

---

## 45. Listas inteligentes y colecciones

El repositorio dispone de rutas para:

```text
/collection/:kind
/smart/:kind
```

y de implementación específica en `smart_playlists.dart`.

También existen colecciones como:

- Favoritos.
- Reproducidas recientemente.
- Más reproducidas.
- Añadidas recientemente.
- agrupaciones por álbum;
- artista;
- carpeta;
- género;
- compositor.

### Decisión

Son **navegación y contenido**, no configuración global.

### Relación con Ajustes

Ajustes puede controlar únicamente:

- cómo se escanea;
- qué carpetas participan;
- defaults globales reales.

No debe controlar el contenido dinámico de estas colecciones.

---

## 46. Letras — subsistema contextual del reproductor

El repositorio contiene:

```text
features/lyrics/
├── lrc_parser.dart
└── lyrics_view.dart
```

La documentación técnica existente describe soporte para:

- letras incrustadas;
- archivos `.lrc`;
- letras sincronizadas;
- desfase;
- edición/corrección;
- persistencia mediante `LyricsOverrides`.

### Propietario UX

```text
Reproductor
└── Letras
```

### Configuración contextual

Acciones como:

- editar;
- corregir;
- sincronizar;
- desplazar tiempo;

deben vivir en la vista de Letras o en las acciones de la canción.

### Ajustes globales

No crear una categoría `Letras` dentro de Ajustes salvo que aparezcan preferencias globales reales, por ejemplo:

```text
Tamaño de letra
Alineación
Mostrar traducción automáticamente
Fuente predeterminada
```

Mientras esas preferencias no existan, el subsistema debe permanecer contextual.

---

## 47. Editor de metadatos y portadas

El repositorio contiene:

```text
features/metadata_editor/
├── song_editor_screen.dart
├── batch_editor_screen.dart
└── cover_picker.dart
```

Existen rutas dedicadas para:

```text
/song/:id/edit
/batch-edit
```

La edición incluye operaciones de metadatos individuales y en lote, además de portada.

### Propietario UX

```text
Canción / selección de canciones
└── Editar metadatos
```

### Relación con Ajustes

La preferencia:

```text
embedCoverInFile
```

sí pertenece a:

```text
Sistema
└── Datos y archivos
    └── Metadatos
```

porque define **cómo se persiste** una modificación.

En cambio:

- editar título;
- artista;
- álbum;
- género;
- compositor;
- número de pista;
- portada;
- edición en lote;

son acciones contextuales y no deben duplicarse en Ajustes.

### Regla

Separar claramente:

```text
qué editar
→ editor contextual

cómo escribir el cambio
→ preferencia global de Datos y archivos
```

---

## 48. Cola de reproducción

El repositorio contiene:

```text
features/queue/
├── queue_screen.dart
└── queue_list.dart
```

y rutas independientes:

```text
/queue
```

Además existe persistencia de:

```text
QueueEntries
QueueState
```

### Propietario UX

```text
Reproductor
└── Cola
```

### Acciones contextuales

- consultar cola;
- reordenar;
- cambiar posición;
- reproducir una entrada;
- modificar el contenido de la cola.

### Ajuste global asociado

Solo:

```text
Restaurar cola al iniciar
```

pertenece a:

```text
Reproducción y audio
└── Reproducción
```

No trasladar la administración de la cola a Ajustes.

---

## 49. Fuentes remotas — detalle que debe quedar explícito

El repositorio no trata las fuentes remotas como parte silenciosa de la biblioteca local.

Tipos actuales:

```text
SMB
WebDAV
HTTP
Radio
```

Comportamientos:

- SMB/WebDAV pueden requerir usuario y contraseña;
- las credenciales se guardan protegidas por Android Keystore;
- HTTP y Radio se reproducen directamente;
- SMB/WebDAV disponen de navegación remota;
- las fuentes pueden añadirse y eliminarse;
- el contenido remoto no se mezcla silenciosamente con la biblioteca local.

### Propietario

```text
Fuentes y descargas
└── Fuentes remotas
```

### Subestructura recomendada

```text
Fuentes remotas
├── Añadir fuente
│   ├── SMB
│   ├── WebDAV
│   ├── HTTP
│   └── Radio
├── Fuentes guardadas
└── Credenciales y seguridad
```

### No mezclar con

- carpetas locales;
- biblioteca escaneada;
- playlists;
- descargas terminadas.

---

## 50. Descargas de Internet y autenticación

La auditoría inicial agrupaba correctamente Descargas dentro de `Fuentes y descargas`, pero faltaba inventariar su superficie real.

El repositorio contiene:

```text
features/downloads/
├── song_search_screen.dart
├── downloads_controller.dart
├── download_details_sheet.dart
└── youtube_login_screen.dart
```

Rutas:

```text
/downloads
/downloads/youtube-login
```

### Implicaciones UX

`Descargas` incluye al menos:

- búsqueda;
- detalle previo/estado de descarga;
- controlador de descarga;
- flujo específico de autenticación de YouTube.

### Decisión de arquitectura

```text
Fuentes y descargas
└── Descargas de Internet
    ├── Buscar
    ├── Estado / detalle
    └── Sesión de proveedor cuando sea necesaria
```

La autenticación de un proveedor **no debe ir a Sistema > Cuenta** si su único propósito es habilitar esa fuente.

Debe permanecer junto a la función que la necesita.

### Biblioteca

Una descarga finalizada que se guarda en MediaStore pasa a formar parte de la biblioteca mediante el flujo normal de contenido local.

No crear una segunda biblioteca paralela de “descargadas” salvo requerimiento explícito.

---

## 51. Mejora de audio — superficie real a considerar

Existe un subsistema:

```text
features/enhancement/
└── enhancement_panel.dart
```

y persistencia dedicada:

```text
EnhancementState
OutputProfiles
LoudnessAnalyses
```

La reorganización ya lo colocaba bajo `Reproducción y audio`, pero debe quedar explícita la separación:

```text
Reproducción y audio
└── Audio
    ├── Ecualizador
    ├── Mejora de sonido
    ├── Normalización
    ├── Estéreo
    ├── Balance / mono
    ├── Direct Mode
    ├── Offload
    └── Perfiles por salida
```

### Regla de dependencia

`Direct Mode` debe tener autoridad clara sobre la cadena DSP.

No mostrar simultáneamente controles como activos si el modo directo los está anulando.

La interfaz debe representar:

```text
valor configurado
vs.
estado efectivo
```

cuando exista una diferencia.

---

## 52. Navegación principal real

La navegación inferior actual se organiza en cuatro ramas persistentes:

```text
Inicio
Biblioteca
Listas
Ajustes
```

El reproductor completo, cola, ecualizador, editor, fuentes remotas, descargas y regalos se abren fuera del shell principal.

### Implicación para la reorganización

No convertir cada grupo de Ajustes en una nueva pestaña de navegación principal.

La reorganización propuesta afecta al **interior de Ajustes**, no a la navegación inferior.

### Funciones con rutas independientes identificadas

Entre otras:

```text
/player
/queue
/equalizer
/album/:id
/artist/:id
/folder
/genre/:name
/composer/:name
/collection/:kind
/smart/:kind
/remote-sources
/remote/:id
/playlist/:id
/gift/receive
/playlist/:id/gift
/song/:id/edit
/batch-edit
/downloads
/downloads/youtube-login
```

La política de deep-links del buscador de Ajustes debe respetar esta separación.

---

## 53. Mapa de propietarios funcionales

Para cerrar ambigüedades futuras:

| Función | Propietario principal | ¿Va en Ajustes? |
|---|---|---|
| Tema de aplicación | Apariencia | Sí |
| Visualizador | Reproductor | Sí, preferencias |
| Animación de carátula | Reproductor | Sí, preferencia |
| Controles visibles | Controles y gestos | Sí |
| Gestos | Controles y gestos | Sí |
| Cola | Reproductor | No, salvo restauración |
| Letras | Reproductor | No, salvo futuros defaults globales |
| Edición de metadatos | Canción / selección | No |
| Portada de canción | Editor contextual | No |
| Persistencia de portada | Datos y archivos | Sí |
| Playlists | Listas | No |
| Regalos musicales | Listas > Regalos | No |
| Smart playlists | Biblioteca/Listas | No |
| Temporizador | Reproductor | No, salvo default real |
| Crossfade | Reproducción | Sí |
| Gapless | Reproducción | Sí |
| Ecualizador | Audio | Sí / pantalla dedicada |
| Mejora de audio | Audio | Sí / panel dedicado |
| Fuentes remotas | Fuentes y descargas | Sí como gestión |
| Credenciales SMB/WebDAV | Fuentes remotas | Contextual a la fuente |
| Descargas | Fuentes y descargas | Sí como acceso/gestión |
| Login YouTube | Descargas | No como categoría independiente |
| Inicio configurable | Inicio | No |
| Orden/filtro Biblioteca | Biblioteca | No |
| Widget Android | Widget de inicio | Sí |
| Auriculares | Sistema > Dispositivos | Sí |
| Android Auto | Sistema > Dispositivos | Sí |
| Registro de fallos | Sistema > Diagnóstico | Sí |

---

## 54. Brecha documental del repositorio: README y documentación de producto

La arquitectura de código actual contiene más capacidades de las que comunica la documentación principal.

El `README.md` del repositorio sigue siendo esencialmente el README inicial generado por Flutter y no representa el producto.

### Debe documentar como mínimo

```text
NuvTune
├── Biblioteca local
├── Reproducción y cola
├── Ecualizador / mejora de audio
├── Metadatos y portadas
├── Letras
├── Fuentes remotas
├── Descargas
├── Experiencia visual / visualizadores
├── Widgets e integración Android
└── Regalos musicales
```

### Regalos debe figurar como función diferencial

No como una nota dentro de “Playlists”, sino con identidad suficiente para explicar:

- qué problema resuelve;
- cómo se crea;
- qué contiene;
- cómo se comparte;
- cómo se recibe;
- cómo se valida;
- cómo se presenta;
- cómo se importa.

---

## 55. Checklist de cobertura funcional completa

Antes de considerar cerrada esta documentación, comprobar:

### Navegación
- [ ] Inicio.
- [ ] Biblioteca.
- [ ] Listas.
- [ ] Ajustes.
- [ ] Reproductor.
- [ ] Cola.

### Biblioteca y contenido
- [ ] Canciones.
- [ ] Álbumes.
- [ ] Artistas.
- [ ] Carpetas.
- [ ] Géneros.
- [ ] Compositores.
- [ ] Favoritos.
- [ ] Historial.
- [ ] Colecciones inteligentes.
- [ ] Orden y filtros contextuales.

### Playlists
- [ ] Crear.
- [ ] Renombrar.
- [ ] Portada.
- [ ] Reordenar.
- [ ] Duplicar.
- [ ] Eliminar.
- [ ] Importar M3U.
- [ ] Exportar M3U.
- [ ] Compartir listado.

### Regalos
- [ ] Crear regalo.
- [ ] Seleccionar canciones.
- [ ] Dedicatoria.
- [ ] De / Para.
- [ ] Identidad visual.
- [ ] Payload.
- [ ] Compartir.
- [ ] Recibir.
- [ ] Validar.
- [ ] Evitar duplicados.
- [ ] Introducción.
- [ ] Importar.
- [ ] Auris.

### Metadatos
- [ ] Editor individual.
- [ ] Editor en lote.
- [ ] Portada.
- [ ] Persistencia segura.
- [ ] Política de incrustación.

### Letras
- [ ] Incrustadas.
- [ ] LRC.
- [ ] Sincronización.
- [ ] Offset.
- [ ] Overrides/edición.

### Audio
- [ ] EQ.
- [ ] Presets.
- [ ] Preamp.
- [ ] Anti-clipping.
- [ ] Balance.
- [ ] Mono.
- [ ] Mejora.
- [ ] Normalización.
- [ ] Estéreo.
- [ ] Direct Mode.
- [ ] Offload.
- [ ] Perfiles por salida.

### Reproducción
- [ ] Gapless.
- [ ] Crossfade.
- [ ] Fade.
- [ ] Restaurar cola.
- [ ] Velocidad/tono contextual.
- [ ] Temporizador.

### Fuentes y descargas
- [ ] SMB.
- [ ] WebDAV.
- [ ] HTTP.
- [ ] Radio.
- [ ] Credenciales.
- [ ] Navegación remota.
- [ ] Búsqueda de descargas.
- [ ] Detalle/estado.
- [ ] Login del proveedor cuando aplique.
- [ ] Integración final con MediaStore.

### Experiencia visual
- [ ] Temas reales.
- [ ] Acento.
- [ ] Superficies.
- [ ] Fondo.
- [ ] Reproductor.
- [ ] Escena.
- [ ] Aspect ratio.
- [ ] Carátula.
- [ ] Visualizador.
- [ ] Color reactivo.
- [ ] Calidad.
- [ ] Reducción de efectos.
- [ ] Reduce Motion.

### Controles e integración
- [ ] Presets.
- [ ] Reordenamiento.
- [ ] Gestos.
- [ ] Favorito junto al título.
- [ ] Auriculares.
- [ ] Bluetooth.
- [ ] Notificación.
- [ ] Pantalla de bloqueo.
- [ ] Android Auto.
- [ ] Widget.

### Sistema
- [ ] Datos y archivos.
- [ ] Diagnóstico.
- [ ] Privacidad.
- [ ] Acerca de.
- [ ] Búsqueda de Ajustes.
- [ ] Deep-links.
- [ ] Migraciones.
- [ ] Tests.

---

## 56. Conclusión revisada de cobertura

Después de añadir los apartados anteriores, la documentación ya no debe tratar NuvTune únicamente como un conjunto de preferencias.

La arquitectura queda dividida en tres niveles:

```text
1. Navegación y dominios principales
   Inicio / Biblioteca / Listas / Ajustes

2. Funciones contextuales
   Reproductor / Cola / Letras / Metadatos / Regalos / Colecciones

3. Preferencias globales
   Apariencia / Reproductor / Controles / Audio / Biblioteca /
   Fuentes / Widget / Sistema
```

Esta separación evita dos errores:

1. mover funciones importantes a Ajustes solo porque tienen opciones;
2. omitir funciones de producto porque no son preferencias globales.

**Regalos musicales queda explícitamente definido como función diferencial principal dentro del dominio Listas, no como un ajuste secundario.**

