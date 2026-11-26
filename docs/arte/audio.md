# Audio

Documenta los SFX de personaje (placeholders / uso por defecto), la integración parcial ya metida y la convención de formatos. Falta cerrar la arquitectura de players.

## Estado actual

- **Archivos**: 18 WAV en `assets/audio/sfx/`. Cinco categorías con tres variantes y su randomizer: `rand_step.tres`, `rand_jump.tres`, `rand_land.tres`, `rand_attack.tres`, `rand_hit.tres`. `whip_01/02/03.wav` son placeholders sin randomizer ni uso en código.
- **`Person`**: `person.gd` exporta `stream_jump` / `stream_step` / `stream_land` / `stream_hit` (`AudioStreamRandomizer`) y cachea `_audio_stream_player: AudioStreamPlayer3D`.
- **`Fighter`**: `fighter.gd` exporta `stream_attack` y define `fight_moves_with_simple_sound` / `fight_moves_with_hitspawn_sound` para elegir cuándo suena.
- **Prefab**: `standard_power_fighter.tscn` trae el nodo `AudioStreamPlayer3D`; ya no guarda defaults de listas de sonido en la root (`prefabs/standard_power_fighter.tscn:19-35`).
- **Config de Tux**: las listas de sonido viven en `data/characters/tux.fighter.cfg:3-11`, dentro de `[fight_moves]`, y las aplica `PowerFighterConfigurer` con `_apply_fighter_config()`.
- **Detección de eventos**: `Person::_process_sound()` corre `_movement_sounds()` y luego el hook `_attack_sounds()`; `Person` lo deja vacío y `Fighter` lo implementa. Movimiento = paso/salto/caída/golpe recibido; ataque = first frame o primer frame de hitbox según lista.
- **Reproducción real**: ya llama `play()`, pero sigue el `print` de placeholder. Pendiente decidir players fijos o un esquema dinámico; ver [audio-y-combate.md](../ideas/audio-y-combate.md).
- **`set_script` resuelto**: el prefab ya trae `script = power_fighter.gd` en el root y el configurer asigna `controller` (nodo hijo) en vez de `set_script`, así que los `@export` de escena (grupos `SFX`) sobreviven y los `stream_*` ya no llegan `null`. Ver [nota-power-fighter-controller.md](../arquitectura/nota-power-fighter-controller.md).
- Los sonidos listados aquí son placeholders: sirven como comportamiento por defecto hasta que cada personaje tenga sus propios SFX.

## Sonidos placeholders (ahora)

Son **18** WAV: cinco categorías usadas con tres variantes cada una y un sexto set de látigo aún sin usar.

| Categoría | Cantidad | Archivos | Cuándo se dispara |
|---|---|---|---|
| Pasos | 3 | `step_01`, `step_02`, `step_03` | Al caminar, correr o caminar agachado (`walking`, `running`, `crouch_move`). |
| Salto | 3 | `jump_01`, `jump_02`, `jump_03` | Primer frame de salto, tanto desde el piso como en el aire (incluye el doble salto de `PowerFighter`). |
| Caída | 3 | `land_01`, `land_02`, `land_03` | Primer frame al tocar el piso tras venir del aire. No debe dispararse mientras el personaje recibe daño. |
| Ataque | 3 | `attack_01`, `attack_02`, `attack_03` | `Fighter`: first frame de `fight_moves_with_simple_sound` o primer frame de hitbox de `fight_moves_with_hitspawn_sound`. Siempre `stream_attack`. |
| Golpe recibido | 3 | `hit_01`, `hit_02`, `hit_03` | Primer frame de daño vía `set_damage(dmg, dir)`. No es el sonido del ataque que pega. |
| Látigo | 3 | `whip_01`, `whip_02`, `whip_03` | Placeholder: sin randomizer ni referencia en código. |

Notas:

- Las tres variantes existen para alternarlas y evitar el efecto "metralleta" al repetir el mismo pasito.
- La cadencia de los pasos ya está parametrizada en `person.gd` con `walk_step_interval`, `run_step_interval` y `crouch_move_step_interval`.
- Idea futura (sin diseño): SFX específicos por ataque (proyectil/fuego) y centralización en `AudioStreamLayerPlayer3D`; detalle superficial en [audio-y-combate.md](../ideas/audio-y-combate.md).

## Formato recomendado: WAV vs Ogg Vorbis

Godot 4.7 importa **WAV, Ogg Vorbis y MP3**. Opus no está soportado de forma nativa para importar, así que se descarta por ahora.

| Uso | Formato | Ajustes |
|---|---|---|
| Pasos, saltos, caídas y demás SFX cortos y repetitivos | **WAV** | Mono, 16-bit, 44.1 o 48 kHz. Trim y normalize. Sin reverb horneado. |
| Música, ambiente y voces largas | **Ogg Vorbis** (`.ogg`) | Mono si es posicional 3D; stereo para música. 96–128 kbps es suficiente. |
| Web / móvil con CPU limitado y muchos sonidos comprimidos | **MP3** | Solo si el rendimiento lo requiere. |

### Por qué WAV para los SFX

- Reproducirlo cuesta muy poco CPU, así que aguanta muchas voces simultáneas (pasos, golpes, efectos al mismo tiempo).
- No tiene latencia de decodificación; el sonido suena en el frame en que se pide.
- Permite variar pitch en runtime sin artefactos, útil para los pasos.
- La documentación oficial de Godot recomienda WAV para efectos cortos y repetitivos.

Al importar un WAV, Godot permite comprimirlo como PCM (sin compresión), IMA ADPCM o Quite OK Audio (QOA, el modo por defecto). Para SFX muy cortos, PCM es la opción más directa; QOA sirve si se quiere reducir tamaño sin notar mucho la pérdida.

### Por qué Ogg Vorbis para música y sonidos largos

- Archivos mucho más chicos que WAV con buena calidad.
- Es el formato comprimido nativo de Godot, con soporte de loop y punto de loop.
- Su costo de decodificación importa cuando hay muchas voces comprimidas a la vez; en música/ambiente eso no es problema.

### Sobre WAV y Microsoft

WAV/RIFF es una especificación definida por Microsoft e IBM, pero es **abierta y libre de regalías**. Usar WAV no impone ninguna licencia de Microsoft ni ata el proyecto a su ecosistema. Si se busca un stack totalmente Xiph, Ogg Vorbis es la alternativa; ambos son válidos.

### Opus

Técnicamente es más moderno y eficiente que Vorbis, y también es libre de patentes (Xiph, licencia BSD). El problema es práctico: **Godot 4.7 no lo importa de forma nativa**. Usarlo requeriría decodificarlo por fuera o un GDExtension, lo cual no se justifica para este proyecto.

## Nombres y ubicación

Convención `snake_case`, como el resto de assets:

```text
assets/audio/sfx/
├── step_01.wav
├── step_02.wav
├── step_03.wav
├── jump_01.wav
├── jump_02.wav
├── jump_03.wav
├── land_01.wav
├── land_02.wav
├── land_03.wav
├── attack_01.wav
├── attack_02.wav
├── attack_03.wav
├── hit_01.wav
├── hit_02.wav
├── hit_03.wav
├── rand_step.tres    # AudioStreamRandomizer con las 3 variantes de paso
├── rand_jump.tres    # AudioStreamRandomizer con las 3 variantes de salto
├── rand_land.tres    # AudioStreamRandomizer con las 3 variantes de caída
├── rand_attack.tres  # AudioStreamRandomizer con las 3 variantes de ataque
└── rand_hit.tres     # AudioStreamRandomizer con las 3 variantes de golpe recibido

assets/audio/music/
└── <nombre>.ogg
```

- Los assets pesados viven en el Drive del proyecto (ver `docs/arte/assets.md`); el repo guarda la convención y, si se decide, los placeholders.
- Al agregar audios definitivos, incluir un `README.md` en la carpeta con la licencia y atribución de cada archivo. Se recomienda **CC0** para placeholders generados o descargados de bancos libres.
- Evitar guardar los masters en 24-bit/96 kHz dentro del repo; se importan ya recortados y normalizados.

## Ajustes de importación en Godot

### WAV

- **Force > Mono**: activado para SFX posicionales.
- **Edit > Trim**: activado para quitar silencios al inicio y final.
- **Edit > Normalize**: activado para emparejar volúmenes.
- **Edit > Loop Mode**: desactivado para one-shots (pasos, saltos, caídas).
- **Compress > Mode**: PCM para SFX cortos; QOA si se busca menor tamaño.

### Ogg Vorbis

- **Loop**: activado solo para música y ambiente.
- **Loop Offset**: ajustar si se quiere repetir solo una parte del track.
- **BPM / Beat Count / Bar Beats**: solo relevantes para música interactiva.
- Mantener mono si el sonido se va a reproducir con `AudioStreamPlayer3D`.

## Uso en runtime

- **`AudioStreamRandomizer`**: un recurso por categoría (`rand_step.tres`, `rand_jump.tres`, `rand_land.tres`, `rand_attack.tres`, `rand_hit.tres`) con tres variantes; elige una al azar en cada reproducción. Permite variar pitch y volumen, y usar modo "random no repeats" para no repetir el mismo paso seguido.
- **`AudioStreamPlayer3D`**: para que el sonido se posicione en el mundo. Ubicar el nodo cerca de los pies del personaje y ajustar `max_polyphony` para permitir traslapes.
- **Hook real**: `Person::_process_sound()` llama `_movement_sounds()` y luego `_attack_sounds()`; `Fighter` lo sobrescribe y usa `_current_attack.name` contra las dos listas. El hook de `Person` sigue vacío.
- **Un player vs varios**: con un solo `AudioStreamPlayer3D` hay que cambiar `stream` por categoría, y asignar `stream` llama `stop()`, así que se corta el sonido anterior. La decisión entre canales fijos y `AudioStreamLayerPlayer3D` sigue pendiente.
- Prioridad real en el mismo frame (última asignación gana): ataque > golpe recibido > salto > caída > paso.

## Known issues

- Sigue el `print` de placeholder en `_movement_sounds()`.
- Un solo `AudioStreamPlayer3D` corta el sonido anterior al reasignar `stream`; por eso sigue abierta la decisión de players.
- En Tux, cuatro power attacks suenan al spawnear desde `tux.fighter.cfg`: `down_power_attack`, `up_power_attack`, `air_down_power_attack` y `air_up_power_attack`. Siguen mudos `power_attack` y `air_power_attack`. El stream sigue siendo `stream_attack`.
- El hit de ataque suena al spawnear hitbox, no al conectar; el escudo suena hit aunque bloquee. La dirección futura está en [audio-y-combate.md](../ideas/audio-y-combate.md).

## Licencias

- **Codecs**: WAV/PCM es libre; Ogg Vorbis y Opus son de Xiph.Org con licencia BSD y sin patentes.
- **Samples**: usar CC0 o CC-BY, o generar los placeholders dentro del proyecto. Registrar siempre la fuente y la licencia.

## Referencias

- Godot 4.7 — Importing audio samples: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_audio_samples.html>
- Godot 4.7 — Audio streams: <https://docs.godotengine.org/en/4.7/tutorials/audio/audio_streams.html>
