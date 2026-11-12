# Nota: MatchTime — reloj de la partida

> Implementado en `scripts/match/match_time.gd` como nodo hijo del mapa.
> Reemplaza el nombre `MatchClock` de notas anteriores. Verificado el 2026-11-11.

## Responsabilidad

`MatchTime` es un módulo `Node` que **solo** cuenta el tiempo de la partida. No conoce vidas, daño
ni ganador. `GameManager` lo configura, lo arranca, escucha sus señales y decide el ganador cuando
recibe `time_out`.

Separación de responsabilidades:

- `MatchTime`: cuánto falta o cuánto ha pasado, y avisar cuando se acaba el límite.
- `GameManager`: cuándo arranca, cuándo se detiene y quién gana.
- `FightHud`: solo pinta el número que recibe en `mm:ss`.
- `LivesManager`: sigue siendo la fuente de las vidas restantes.
- `MatchCountdown`: es otro módulo; el 3-2-1 previo no es parte del reloj.

## API real

- `@export_range(0, 99, 1) time_limit_minutes: int = 0`: límite en minutos. `0` significa **sin
  límite**, no “reloj apagado”.
- `setup()`: reinicia el reloj con el límite actual y emite el segundo inicial para que el HUD pueda
  pintarlo. No lo arranca.
- `start()` / `stop()`: controlan si el reloj avanza.
- Señales:
  - `time_changed(seconds: int)`: segundo entero actual. Con límite son segundos **restantes**; sin
    límite son segundos **transcurridos**.
  - `time_out`: se emite una sola vez cuando el límite llega a cero.

Comportamiento en `_process(delta)`:

- Si `time_limit_minutes > 0`, descuenta el tiempo y emite con `ceili()` para que el HUD muestre
  `03:00`, `02:59`, etc. Al llegar a cero emite `time_out` y se detiene.
- Si `time_limit_minutes == 0`, acumula el tiempo y emite con `floori()`, como cronómetro hacia
  arriba.

Es `_process`, no `_physics_process`, porque no depende de colisiones ni de un `delta` fijo de
física.

## Flujo real

```mermaid
flowchart LR
    CM[CharacterMenu] -->|TIME_OPTIONS[time_index]| GM[GameManager]
    GM -->|set_time_limit| MT[MatchTime]
    GM -->|setup| MT
    CD[MatchCountdown] -->|finished| GM
    GM -->|start tras el letrero| MT
    MT -->|time_changed| GM
    GM -->|match_time_changed| HUD[FightHud]
    MT -->|time_out| GM
    GM -->|get_winner| END[match_ended]
```

## Integración

- `MatchTime` vive como nodo hijo del mapa (`MatchTime` en `map1.tscn`), igual que `LivesManager` y
  `MatchCountdown`.
- `CharacterMenu._start_match()` llama `level.set_time_limit(TIME_OPTIONS[time_index])` antes de
  cambiar de escena (`scripts/ui/character_menu.gd:340`).
- `GameManager.set_time_limit(minutes)` aplica el valor al nodo `MatchTime`. El manager ya no expone
  `time_limit_minutes` como propiedad propia.
- `GameManager._ready()` conecta `time_changed` y `time_out`, y llama `MatchTime.setup()` para dejar
  pintado el tiempo inicial.
- El reloj no arranca hasta que termina la cuenta inicial y el letrero de ¡PELEA!, en
  `GameManager._on_countdown_finished()`. Si hubo cuenta, los peleadores estuvieron congelados
  durante la espera.
- `GameManager._end_match()` detiene el reloj, congela al ganador y emite `match_ended`.
- `FightHud` formatea el número recibido; no necesita saber si es restante o transcurrido.

## Fin de partida por tiempo

Cuando `MatchTime` emite `time_out`, `GameManager._on_time_out()` cierra la partida con
`_end_match(get_winner())`. El ganador se decide así:

1. Solo cuentan los peleadores con instancia válida y al menos una vida restante.
2. Gana quien tenga **más vidas restantes** (`LivesManager.get_lives()`).
3. Si empatan en vidas, gana quien tenga **menor `damage_percentage`**.
4. Si siguen empatados, `get_winner()` devuelve `null` y `match_ended(null)` representa un empate.

`get_valid_fighters()` devuelve una copia filtrada del roster para no exponer referencias muertas.
`get_winner()` y `_determine_the_winner()` son públicos para que el HUD pueda consultar al ganador
actual si lo necesita.

## Casos límite

- `time_limit_minutes == 0` no desactiva el reloj: cuenta hacia arriba.
- `setup()` emite el segundo inicial aunque el reloj todavía no esté corriendo.
- `time_out` se emite una sola vez; después de eso el reloj queda detenido.
- No hay sudden death ni reglas extra de desempate: si vidas y daño empatan, es empate.
- Abrir `map1.tscn` directo deja la partida sin peleadores porque `PowerFighterSlots` está vacío; el
  reloj no sustituye el lineup.

## Ver también

- [nota-match-countdown.md](nota-match-countdown.md): el 3-2-1 previo a la pelea.
- [nota-game-manager-modular.md](nota-game-manager-modular.md): módulos de la partida y
  responsabilidades.
- [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md): cómo se llena el lineup por
  slot antes de cambiar de escena.
