# Personalización: temas, controles y movimiento

Estado: implementado en `1.5.0+20`.

## Organización

La pantalla **Personalización** separa Tema, Reproductor, Movimiento y Widget.
El reproductor enlaza su editor de diseño y controles desde la misma pantalla.

## Temas

- Modo: Sistema, Claro, Oscuro o AMOLED.
- Tema base: Nocturno, Violeta, Cálido o Monocromo.
- El color de énfasis y la intensidad de vidrio son ajustes independientes.
- Una instalación anterior conserva el modo oscuro; el antiguo fondo negro se
  migra al modo AMOLED.

## Controles del reproductor

El diseño guarda cuatro zonas: `top`, `primary`, `secondary` y `footer`.
Cada acción puede moverse u ocultarse, incluido Favorito. La barra superior
admite hasta dos acciones. Reproducir/Pausar se normaliza siempre a la zona
principal y nunca puede ocultarse.

El lector mantiene compatibilidad con el JSON anterior de dos zonas y mueve
Favorito a `footer`, preservando el aspecto que tenía antes de esta versión.

## Movimiento y visualizador

Perfiles disponibles: Sin animación, Calmada, Equilibrada, Enérgica y
Personalizada. El perfil personalizado permite ajustar intensidad, suavidad,
respuesta al ritmo y partículas en niveles de 0 a 3.

El visualizador puede usar una paleta derivada de la canción, del énfasis del
tema, neutra o sin efectos cromáticos. La reducción de animaciones de Android,
el ahorro de batería y la protección térmica tienen prioridad.

El selector gráfico de visualización reúne escena y estilo. Los estilos solo
se muestran cuando la escena elegida es **Visualizador**, evitando presentar
una opción que no tendría efecto visible.

## Persistencia y migración

Drift usa el esquema 15. Se añadieron preferencias estables para modo de tema,
perfil y niveles de movimiento, y fuente de color del visualizador. Los datos
de biblioteca, favoritos, listas, letras y cola no se reescriben.
