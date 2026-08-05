# Nota: Plataformas en Character

> Dónde vive hoy la lógica de plataformas (one-way + orillas agarrables), qué hallazgos salieron al revisarla y la propuesta de mover la parte física a `GravityBody3D`. **Aún no aplicado; es análisis y decisión pendiente.**

## Qué hay hoy en `scripts/character.gd`

- **`_one_way_platforms()`** (línea ~460): plataformas de un solo sentido estilo Smash — se atraviesan de abajo hacia arriba, pero sólidas al caer encima. Con tap de abajo estando parado en una, te dejas caer a propósito (drop-through). Incluye *coyote time* al salirte por la orilla.
- **`_get_floor_one_way()`**: busca en las colisiones del último `move_and_slide` si topamos con una `OneWayPlatform`.
- **`_get_feet_y()` / `_get_head_y()` / `_get_body_half_height()`**: medidas del cuerpo (pies/cabeza/media altura) calculadas desde `$CollisionShape3D`, respetando la escala global de la raíz.
- **`_ledge_grab()`** (línea ~583): agarre de orillas de las `GroundPlatform` — si vas cayendo junto a una orilla, te cuelgas; colgado, arriba te subes con impulso y abajo te sueltas.

## Qué es física pura vs qué está pegado al fighter

| Pieza | ¿Pura física? | Detalle |
|---|---|---|
| `_one_way_platforms` | **Sí** | Solo excepciones de colisión (`add/remove_collision_exception_with`), `is_on_floor()`, `get_slide_collision_*`, velocidad. Cero combate. |
| `_get_floor_one_way` | **Sí** | Lee colisiones, nada más. |
| `_get_feet_y` / `_get_head_y` / `_get_body_half_height` | **Sí** | Geometría del `$CollisionShape3D`. |
| `_ledge_grab` | **Mixto** | La *física* (detectar orilla, `_hang_position`, velocity ZERO, subir con impulso) es genérica, pero **mezcla combate**: nullea `_current_attack`, llama `_clear_hitbox()`, usa `$AnimationPlayer`, `$Pivot`, `jump_impulse` y `_jump_count` (que son de `Character`). |

Vars y constantes asociadas: `_drop_through_count`, `_one_way_ignored`, `_last_floor_one_way`, `_one_way_coyote_count`, `DROP_THROUGH_TIME`, `ONE_WAY_MARGIN`, `ONE_WAY_COYOTE_TIME` (one-way) y `_hanging_ledge`, `_hanging_right_side`, `_hang_position`, `_ledge_release_count`, `LEDGE_*` (orillas). El tap de arriba/abajo ya no le pertenece a ningun sistema: `_up_pressed`/`_down_pressed` (con `_was_move_up`/`_was_move_down` de memoria interna) se calculan una sola vez en `_physics_process()`, justo despues de `_collect_input()`, y viven en el bloque de deteccion de inputs pa que one-way y ledge lean el mismo flanco.

## Hallazgos al revisar

1. **`_ledge_grab()` corre ANTES de `_fight()` y `_anim()`** en el pipeline de `_physics_process()`. El propio comentario de `_ledge_grab()` ya lo reconoce: corre después de `_move` y pisa lo que este calculó sin pedir permiso; `_fight` y `_anim` corren después pero se salen temprano si se está colgado, así que no vuelven a pisar el estado. Los tres síntomas de esto ya están resueltos (el orden del pipeline en sí no cambió):
   - ~~Puedes **atacar colgado**~~ **Resuelto**: `_fight()` ahora arranca con un guard (`if _hanging_ledge != null:`) que nullea `_current_attack`, limpia el hitbox con `_clear_hitbox()` y hace `return` antes de procesar cualquier input de ataque.
   - ~~Si te pegan colgado, el knockback se cancela~~ **Resuelto**: `set_damage_move()` (la función que llama `hitbox.gd` al conectar un golpe) ahora suelta la orilla *antes* de registrar el daño — pone `_hanging_ledge = null` y arranca `_ledge_release_count = LEDGE_RELEASE_TIME` (el mismo cooldown que ya usaba el soltarse voluntario con el tap de abajo, para no re-agarrarse solo a la misma orilla al salir volando). Al soltar `_hanging_ledge` ahí, `_ledge_grab()` ya no entra en su rama de "estoy colgado" el frame siguiente, así que no vuelve a snapear a `_hang_position` ni pone `_target_velocity` en cero — el knockback que aplica `_damage_move()` después en el pipeline sobrevive intacto. A propósito no se toca `_target_velocity` dentro de `set_damage_move()`: pisarla ahí cancelaría el golpe que `_damage_move()` está por aplicar.
   - ~~`_anim()` puede voltear el `Pivot`~~ **Resuelto**: `_anim()` ahora arranca con el mismo guard (`if _hanging_ledge != null: return`), así que ya no pisa ni la dirección de vista ni la animación que `_ledge_grab()` ya fijó.
2. **`_get_floor_one_way()` lee colisiones del frame anterior** (`move_and_slide()` corre al final del pipeline). Un frame de lag en la detección "estás parado en una one-way"; si el tap-abajo se siente lento o intermitente, es el primer sospechoso.
3. **Lo que está bien**: las excepciones de colisión solo se agregan/remueven cuando el estado cambia de verdad; el cache `_one_way_ignored` se limpia solo; `get_top_y()` de las plataformas respeta la escala global; y saltar desde una one-way la ignora al subir pero la re-solidifica al caer (comportamiento correcto).

## Propuesta: mover la parte física a `GravityBody3D`

- **Subir a `GravityBody3D`**: `_one_way_platforms`, `_get_floor_one_way`, `_get_feet_y`, `_get_head_y`, `_get_body_half_height` + sus vars y constantes. Es mecánica de cuerpo, no de luchador: serviría para cualquier body futuro (NPCs con IA, enemigos, items con `ObjectWithPhysics`). No crea dependencias raras (`OneWayPlatform`/`GroundPlatform` son `class_name` globales y `$CollisionShape3D` es nombre estándar). Adelgaza `character.gd` y deja de ser "solo gravedad" para ser la base de movimiento física.
- **El `_ledge_grab` conviene moverlo pero requiere desacople**: `GravityBody3D` expondría un virtual tipo `_on_hanging_changed(hanging: bool)` (y un impulso de subida propio), y `Character` lo sobreescribe para nullear ataque, limpiar hitbox y animar. Si se prefiere simple, el ledge se queda en `Character` y solo sube lo de one-way.
- **Bonus**: al reestructurar, de paso se arregla el orden (`_ledge_grab` antes de `_fight`/`_anim`).
- **Orquestación**: el pipeline `_physics_process` se queda en `Character` llamando a los métodos nuevos (menor riesgo). La otra opción (pipeline propio en `GravityBody3D` con virtuals) es refactor más grande.

## Estado

- **No aplicado.** Decisión pendiente entre: (1) solo subir one-way + medidas, (2) subir también el ledge con callback virtual, (3) no tocar por ahora.
