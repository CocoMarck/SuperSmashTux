# Nota: Configuración de controles (rebindings)

> Cómo hacer el menú de "Configurar controles" Godot Style: capturar el input nuevo, aplicarlo al
> `InputMap` en caliente, guardarlo en `user://controls.cfg` y recargarlo al arrancar.

## La respuesta corta

**No uses un archivo de texto plano.** La manera Godot Style son dos piezas que ya existen en el motor:

- **`InputMap`**: el mapa de acciones global del juego. Tus acciones `player1_*` / `player2_*` ya viven
  aquí (definidas en `project.godot`). Cada acción es una lista de **eventos** (`InputEventKey`,
  `InputEventJoypadButton`, `InputEventJoypadMotion`).
- **`ConfigFile`**: un archivo de configuración al estilo INI que Godot lee escribe solo. Se guarda en
  `user://` (no en el repo), y como los `InputEvent` son `Resource`, Godot los serializa sin que tu des
  ese paso.

```gdscript
# Guardar: una foto del InputMap completo.
var config: ConfigFile = ConfigFile.new()
for action in GlobalUtils.PLAYER_INPUT_MAPS.keys():
	config.set_value("controls", action, InputMap.action_get_events(action))
config.save("user://controls.cfg")
```

Cargar es el inverso: si el archivo existe, borrar los eventos actuales de la acción y agregar los
guardados. Con eso el jugador mapea en un menú, se prueba al instante y persiste entre partidas.

## Dónde queda el archivo en cada sistema

`user://` es un alias que resuelve a una carpeta **fuera del proyecto** (nunca va al repo ni a la
build). La ruta real depende del sistema y usa el `config/name` del proyecto (aquí `SuperSmashTux`):

| Sistema | Ruta de `user://` |
|---|---|
| **Linux (clásico)** | `~/.local/share/godot/app_userdata/SuperSmashTux/` |
| **Linux (con `XDG_DATA_HOME`)** | `$XDG_DATA_HOME/godot/app_userdata/SuperSmashTux/` |
| **Windows** | `%APPDATA%\Godot\app_userdata\SuperSmashTux\` |
| **macOS** | `~/Library/Application Support/Godot/app_userdata/SuperSmashTux/` |

En tu máquina Linux el archivo `controls.cfg` completo de 8.5 KB quedó en:

```
/home/jean_abraham/.local/share/godot/app_userdata/SuperSmashTux/controls.cfg
```

Para verificar que se guardó: el archivo existe y contiene las 20 acciones (`player1_*` y `player2_*`)
con sus `InputEvent`. Si quieres resetear los controles a mano (fuera del juego), solo borra ese archivo.

> Nota: si juegas desde el editor o desde un export y el `config/name` cambia, cambia también la carpeta
> — el `user://` se resuelve por nombre de proyecto, no por ruta del repo.

## Arquitectura de slots: dos mapas de input por acción

Por diseño, el menú solo permite remapear **dos mapas de input por acción**, sin repetir:

- **`Slot.INPUT_MAP_1`** — primer mapa de entrada. Hoy es el dispositivo de PC (teclado,
  `InputEventKey`; mouse `InputEventMouseButton` como posibilidad a futuro).
- **`Slot.INPUT_MAP_2`** — segundo mapa de entrada. Hoy el gamepad: botones
  (`InputEventJoypadButton`) y movimiento de stick (`InputEventJoypadMotion`).

O sea: **por arquitectura, una acción tiene como máximo un bind en `INPUT_MAP_1` y un bind en
`INPUT_MAP_2`**. La captura sustituye *solo* el evento del mismo mapa que el que llega, para que uno no
pise al otro.

Además — y esto queda intencionalmente **ambiguo hasta que lo definamos bien** — **no se puede repetir
input**: veremos exactamente en qué términos (¿nada de dos acciones con la misma tecla? ¿una acción no
puede tomar un bind ya usado en otra? ¿solo dentro del mismo jugador o también entre jugadores?) mientras
implementamos la captura.

## Por qué "foto completa de todo" y no solo del default

Guardamos **todas** las acciones en cada save (o al menos las que el menú deja tocar), no solo las que
cambiaron. Así al cargar no hace falta reconciliar: si la acción está en el archivo, se sobreescribe;
si no, se queda con el default de `project.godot`. Simple y determinista.

## Reset a defaults — el truco

Para volver a los controles de fábrica, hoguera limpia:

```gdscript
func reset_all_to_defaults() -> void:
	InputMap.load_from_project_settings()   # restaura lo del project.godot
	DirAccess.remove_absolute("user://controls.cfg")
```

`InputMap.load_from_project_settings()` re-importa los defaults del proyecto, descartando lo que haya en
caliente. No hay que "inventar" el default por acción.

## La captura del input (el corazón del menú)

En la escena del menú, cuando el jugador hace clic en un "slot": se pone en modo *esperando*, y en
`_input()` se agarra el primer evento relevante:

```gdscript
func _input(event: InputEvent) -> void:
	if not _capturing:
		return
	# Solo reporta una captura por vez
	if event is InputEventKey and event.pressed and not event.echo:
		_apply_binding(_current_action, event)
	elif event is InputEventJoypadButton and event.pressed:
		_apply_binding(_current_action, event)
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		event.axis_value = signf(event.axis_value)  # normaliza a -1.0 / 1.0
		_apply_binding(_current_action, event)
```

`_apply_binding()` hace el reemplazo limpio: borra de la acción solo los eventos del **mismo tipo** que
el que llegó (para no pisar tecla↔pad) y agrega el nuevo:

```gdscript
func _apply_binding(action: StringName, new_event: InputEvent) -> void:
	for e in InputMap.action_get_events(action):
		var mismo_tipo := (e is InputEventKey and new_event is InputEventKey) \
			or (e.get_class().begins_with("InputEventJoypad") and new_event.get_class().begins_with("InputEventJoypad"))
		if mismo_tipo:
			InputMap.action_erase_event(action, e)
	InputMap.action_add_event(action, new_event)
	_save()
	_update_ui()
```

### Cómo tocar los `InputEventJoypadMotion` en el editor de escena

En el `project.godot`, el movimiento con stick se ve así (para `player1_move_left`):

```
, Object(InputEventJoypadMotion,...,"device":0,"axis":0,"axis_value":-1.0,"script":null)
```

- `device`: 0 (pad del jugador 1) o 1 (jugador 2).
- `axis`: 0 = eje X (stick), 1 = eje Y.
- `axis_value`: **-1.0 ó 1.0** dependiendo de la dirección. **OJO**: al capturar de live input viene
  como fracción (ej. `0.7`); por eso se normaliza con `signf()` antes de guardar.

### Ajustar el `deadzone` del movimiento

Las acciones de movimiento tienen un `deadzone` (0.2 o 0.5) que Godot también guarda en el
`ConfigFile`/`project.godot`. Si remapeas solo un eje, el deadzone se conserva porque no lo borramos;
solo se re-emite el `axis_value` normalizado. No toques el deadzone desde el menú por ahora.

## Inconsistencia detectada en `project.godot` (a corregir si te toca)

En `project.godot` las acciones de **teclado** de P1 están con `device: 0` (p. ej. `player1_move_left`
con `"device":0` en su `InputEventKey`) mientras las de P2 y el resto usan `device: -1` (cualquier
teclado). `device: -1` es lo correcto para teclado: `0` ahí es un valor raro. Al capturar/guardar eventos
nuevos, normalízalo a `-1` para teclas y guarda el `device` real del pad solo en eventos de joypad.

**Caso real visto en vivo:** al guardar desde el editor el teclado reportó `device: 16`, y esa foto quedó
en `controls.cfg`. Resultado: `player1_move_left` etc. quedaron atadas a ese dispositivo y P1 ya no
responde con *cualquier* teclado. Por eso la normalización a `device: -1` en la captura no es cosmética:
es necesaria para que el rebind funcione en cualquier PC. Si ya tienes un `.cfg` contaminado, borra el
archivo (ver rutas arriba) para volver a defaults.

## Orquestación en el proyecto

Según `AGENTS.md`, el dev humano codea los scripts de gameplay; el agente documenta, propone y pregunta.
Este doc es la guía; el `input_settings.gd` lo escribe el dev (o el agente si se le pide explícitamente).

## Archivos y estructura

- `user://controls.cfg` — guardado en tiempo real, no va al repo (ver rutas por sistema arriba).
- `scripts/helpers/input_settings.gd` — autoload `InputSettings` con `load_settings()` /
  `save_settings()`. Se registra en `[autoload]` de `project.godot`.
- `scripts/menu/controls_menu.gd` (con su escena `scenes/controls.tscn`) — la UI del menú de controles:
  pestañas P1/P2, dos mapas de input por acción (`Slot.INPUT_MAP_1` y `Slot.INPUT_MAP_2`), captura de
  input y guardado.
- Un método de carga al arrancar: es el `_ready()` del autoload, que corre antes de que los jugadores
  lean el `InputMap`.

## Ver también

- `docs/estructura.md` — convenciones de carpetas y nombres del proyecto.
- `scripts/helpers/player_input_map.gd` y `scripts/helpers/global_utils.gd` — cómo se declaran las
  acciones y el mapa P1/P2.
- [Documentación de Godot: InputMap](https://docs.godotengine.org/en/stable/classes/class_inputmap.html)
- [Documentación de Godot: ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html)
