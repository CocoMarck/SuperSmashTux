# Configurar controles (rebinding) — Godot Style

> Cómo implementar un menú que deje al jugador remapear sus controles, persistirlos y recargarlos al
> arrancar. Approach oficial de Godot: eventos + `InputMap` + `ConfigFile` en `user://`.

## La idea de fondo

**No usamos archivos de texto plano inventados.** Godot ya modela los controles con dos piezas:

- **`InputMap`**: un singleton global donde viven las *acciones* (ej. `player1_jump`) y sus eventos
  asociados (tecla, botón de pad, eje del stick). Las acciones se definen en `project.godot` y se cargan
  al abrir el juego.
- **`InputEvent`** (y sus hijos `InputEventKey`, `InputEventJoypadButton`, `InputEventJoypadMotion`):
  son *Resources*. Eso quiere decir que se serializan solos, así que para guardar la config del usuario
  alcanza con guardar los eventos con un `ConfigFile`:

```
user://controls.cfg   <- no es texto libre, son eventos serializados por Godot
```

Por qué NO tocar `project.godot` en runtime (`InputMap.save_to_project_settings()`): el proyecto
exportado es de solo lectura, así que ese método sirve solo para el editor. La config del jugador final
siempre vive en `user://`.

## Los pasos del flujo

1. **Definir acciones + defaults** en `project.godot` (ya está hecho: `player1_*` y `player2_*`).
2. **Cargar** al arrancar: un *autoload* `InputSettings` lee `user://controls.cfg` y, si existe,
   reescribe los eventos de cada acción sobre el `InputMap`. Corre antes de que spawnien los
   personajes, así el remap está listo desde el primer frame.
3. **Capturar** en el menú: el jugador toca el slot que quiere remapear y el script escucha el
   siguiente evento Real que entra por `_input()`.
4. **Aplicar en vivo**: se borra el evento viejo del mismo tipo y se agrega el nuevo. Como el
   `InputMap` es global, los cambios se sienten al instante (se pueden probar sin cerrar el menú).
5. **Guardar**: se serializa una "foto" completa de las 20 acciones y se escribe el `.cfg`.
6. **Restablecer**: `InputMap.load_from_project_settings()` y se borra el `.cfg`.

Los personajes NO cambian: `player.gd` ya lee con `Input.is_action_pressed(input_map.jump)` etc., y eso
consulta el `InputMap` en vivo.

## Cómo arrancar: `scripts/helpers/input_settings.gd` (autoload)

Esqueleto mínimo del autoload (registrado en `project.godot` como
`InputSettings="*res://scripts/helpers/input_settings.gd"`):

```gdscript
## Autoload InputSettings
extends Node

const SAVE_PATH := "user://controls.cfg"
const INPUT_MAP_1 := "input_map_1"
const INPUT_MAP_2 := "input_map_2"

func _ready() -> void:
	load_settings()

# Carga la config guardada y la reaplica al InputMap.
func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for action in _action_names():
		var events: Array = cfg.get_value("controls", action, [])
		if events.is_empty() and not cfg.has_section_key("controls", action):
			continue # esta accion no se toco, conserva su default
		InputMap.action_erase_events(action)
		for event in events:
			InputMap.action_add_event(action, event)

# Guarda el estado completo de las acciones (foto completa).
func save_settings() -> void:
	var cfg := ConfigFile.new()
	for action in _action_names():
		cfg.set_value("controls", action, InputMap.action_get_events(action))
	cfg.save(SAVE_PATH)

# Vuelve a los defaults del project.godot y borra la config de usuario.
func reset_to_defaults() -> void:
	InputMap.load_from_project_settings()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# Todas las acciones de todos los jugadores, sacadas del GlobalUtils.
func _action_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for player in GlobalUtils.PLAYER_INPUT_MAPS.values():
		names.append_array([
			player.move_left, player.move_right, player.move_up, player.move_down,
			player.jump, player.attack, player.walk, player.grab, player.shield,
			player.power_attack,
		])
	return names
```

Destacar:

- Se guardan **todas** las acciones (foto completa), no solo las que cambiaron. Simplifica el `load` de
  forma determinista: si una acción no está en el cfg, conserva su default.
- Los `InputEvent` se guardan solos (`store`/`get_value`) porque son `Resource`.
- `load` borra los eventos actuales con `action_erase_events` antes de agregar los guardados, para no
  acumular duplicados.
- En el proyecto las acciones se recorren desde `GlobalUtils.PLAYER_INPUT_MAPS`, que ya es la fuente de
  verdad; no hardcodeemos las 20 por fuera.

## Cómo capturar el input nuevo (en el script del menú)

```gdscript
func _input(event: InputEvent) -> void:
	if not _capturing or _capture_action.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_apply_capture(action, KeyBinding.INPUT_MAP_1, event)
	elif event is InputEventJoypadButton and event.pressed:
		_apply_capture(action, KeyBinding.INPUT_MAP_2, event)
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		# Normalizar el eje del stick: las direcciones dieron +/-1.0
		event.axis_value = signf(event.axis_value)
		_apply_capture(action, KeyBinding.INPUT_MAP_2, event)
```

Para aplicar el rebind respetando el mapeo dual teclado+pad del proyecto, se sustituye **solo el evento
del mismo tipo**:

```gdscript
func apply_event(action: StringName, binding_type: int, new_event: InputEvent) -> void:
	for event in InputMap.action_get_events(action):
		if binding_type == KeyBinding.INPUT_MAP_1 and event is InputEventKey:
			InputMap.action_erase_event(action, event)
		elif binding_type == KeyBinding.INPUT_MAP_2 and (event is InputEventJoypadButton \
				or event is InputEventJoypadMotion):
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, new_event)
```

Para mostrar la tecla actual en la UI: `event.as_text()`.

## Peculiaridades detectadas en este proyecto

- **`player1_move_*` usan `device: 0` en las teclas** (como si el teclado fuera el pad 0), mientras
  `player2_*` y el resto usan `device: -1` (cualquier teclado). Estandarizar a `device: -1` al
  capturar teclas para que cualquiera funcione en ambos jugadores.
- El movimiento del stick usa `InputEventJoypadMotion` con `axis_value ±1.0` por dirección; al capturar
  hay que normalizar con `signf()` (una pulsada real del stick llega con cualquier valor entre -1 y 1).
- La UI se arma desde `GlobalUtils.PLAYER_INPUT_MAPS`: una pestaña por jugador (`TabContainer`) y, por
  acción, dos slots — teclado y pad — mostrando `event.as_text()`.

## Ver también

- `docs/estructura.md` — convenciones de carpetas y que `scripts/helpers/` es para clases que NO son
  nodos (salvo que el autoload, que es un `Node` global, viva en `scripts/` raíz si se prefiere).
- [Documentación de Godot: InputMap](https://docs.godotengine.org/en/stable/classes/class_inputmap.html).
- [Documentación de Godot: ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html).
- [Documentación de Godot: InputEvent](https://docs.godotengine.org/en/stable/classes/class_inputevent.html).