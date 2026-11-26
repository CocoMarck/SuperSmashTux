# Ideas: audio y combate

> IDEA / NO IMPLEMENTADO. Direcciones discutidas el 2026-11-25, registradas de forma superficial.
> No son contratos de datos ni comportamiento actual. Si algo se implementa, pasar a `LISTO` en
> [changelog.md](../changelog.md) y ajustar los docs correspondientes.

## AudioStreamLayerPlayer3D

- Idea: un `Node3D` contenedor que en `new()` construye los `AudioStreamPlayer3D` que necesite.
- API resumida: `play_sound(type: StringName, at_position?)`. El tipo elige el stream por defecto y la posición permite sonar donde ocurrió el evento.
- Objetivo: centralizar SFX y evitar que un solo player corte sonidos al reasignar `stream`.
- Estado: sin pool, cap, prioridades ni gritos definidos. `AudioStreamLayerPlayer3D` no existe hoy en el proyecto.

## Tipo de hitbox

- Idea: agregar metadata de tipo a `HitboxMove` y propagarla al hitbox instanciado.
- Atributo `type: HitboxType` o `type: String`. Con este el objeto golpeado ejemplo `Person` detecta que `Hitbox` le dio, pos reproduce sonido relacionado con su `type`.

## Carga de ataques

- Idea: `FightMove` tendría un dato de carga; el contador vivo sería de `Fighter`, no del move compartido.
- Primer tap de ataque: empieza la carga. Otro input: cancela el estado, pero conserva lo acumulado.
- Segundo tap de ataque: dispara el ataque y reinicia la carga. Daño real reinicia; escudo que bloquea no.
- Estado: sin campo, sin HUD y sin efectos de carga definidos.

## Fuera de alcance

- No documentar aún nombres de gritos, cantidades, matriz completa, cap ni prioridades de players.
- No documentar efectos visuales de carga hasta que existan en código.
