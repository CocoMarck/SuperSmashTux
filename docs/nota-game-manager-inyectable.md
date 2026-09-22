# Idea: GameManager inyectable a los mapas

> **Estado: SOLO IDEA.** No es tarea activa. Se anota para no perder la arquitectura que se quiere
> alcanzar cuando se mueva el sistema de mapas.

## La idea

Hoy el `GameManager` vive dentro de `scenes/map1.tscn` (cableado a mano en el editor con sus
`@export`). Eso mezcla dos responsabilidades en el mismo archivo: la **partida** (quién sale, cuántas
vidas, cómo se gestionan las muertes) y el **mapa** (plataformas, spawn points, play area, cámara).

El plan a futuro: **inyectar el GameManager al mapa desde donde se arma la pelea** (igual como el
`fight_canvas_layer` se inyecta al mapa desde `button_start.gd`). Así:

- **`map1.tscn` (y cualquier mapa futuro)** = solo cosas de mapa: plataformas, `SpawnPoint`s,
  `PlayArea`, cámara, decoración. **Nada de managers.**
- **GameManager (o lo que lo sustituya)** = un módulo aparte, inyectable, que se monta sobre el mapa
  que se le pase. Lleva la regla de partida: tipos de personaje, vidas, respawn, etc.

## Precondiciones (lo que un mapa "bien hecho" debe traer sí o sí)

Para que el GameManager inyectado funcione, el mapa tiene que ofrecerle la información que necesita,
posiblemente por convención (grupos o nombres):

- Sus `SpawnPoint`s.
- Su `PlayArea`.

## Criterio de validación: crashes buenos

**Sin validar nada.** No queremos `push_warning` ni fail-open que disfracen un mapa mal armado. Si el
mapa no trae lo que el GameManager necesita, **que truene el crash a propósito**: el error es del autor
del mapa, y un crash claro lo obliga a arreglarlo bien, no a esconderlo. Menos tolerancia, más
calidad en los niveles.

## Por qué todavía no se hace

- El fix inmediato del bug de `current_scene` no depende de esto: basta aplicar
  `host_node`/`_level_root` (ver `changelog.md`, sección `2026-09-22`).
- La inyección obliga a re-cablear en código los `@export` (array de spawn points, `play_area`,
  `character_types`, vidas), porque al crearse en runtime llegan con sus defaults.
- No es necesario para el ciclo actual; se hace cuando se mueva el sistema de mapas completo.