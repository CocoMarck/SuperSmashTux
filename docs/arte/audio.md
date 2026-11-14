# Audio

Documenta los sonidos deseados de personaje (placeholders / uso por defecto) y la convención de formatos de audio del proyecto. No describe todavía una integración completa; aterriza qué se necesita y con qué formato conviene guardarlo.

## Estado actual

- `person.gd::_process_sound` ya calcula los momentos en que debería sonar algo (paso, salto y aterrizaje), pero por ahora solo hace `print`.
- La reproducción real está pendiente. Coincide con el pendiente de `process_sound` en `docs/changelog.md`.
- Los sonidos listados aquí son placeholders: sirven como comportamiento por defecto hasta que cada personaje tenga sus propios SFX.

## Sonidos deseados (ahora)

Se necesitan **nueve** sonidos placeholder, tres variantes por categoría:

| Categoría | Cantidad | Archivos | Cuándo se dispara |
|---|---|---|---|
| Pasos | 3 | `step_01`, `step_02`, `step_03` | Al caminar, correr o caminar agachado (`walking`, `running`, `crouch_move`). |
| Salto | 3 | `jump_01`, `jump_02`, `jump_03` | Primer frame de salto, tanto desde el piso como en el aire (incluye el doble salto de `PowerFighter`). |
| Caída | 3 | `land_01`, `land_02`, `land_03` | Primer frame al tocar el piso tras venir del aire. No debe dispararse mientras el personaje recibe daño. |

Notas:

- Las tres variantes existen para alternarlas y evitar el efecto "metralleta" al repetir el mismo pasito.
- La cadencia de los pasos ya está parametrizada en `person.gd` con `walk_step_interval`, `run_step_interval` y `crouch_move_step_interval`.
- A futuro se contemplan más SFX de personaje (daño recibido, golpe contra techo y pared), pero no son parte de esta tanda.

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
└── land_03.wav

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

## Uso en runtime (futuro)

- **`AudioStreamRandomizer`**: un recurso por categoría que contiene las tres variantes y elige una al azar en cada reproducción. Permite variar pitch y volumen, y usar modo "random no repeats" para no repetir el mismo paso seguido.
- **`AudioStreamPlayer3D`**: para que el sonido se posicione en el mundo. Ubicar el nodo cerca de los pies del personaje y ajustar `max_polyphony` para permitir traslapes.
- **Hook actual**: `person.gd::_process_sound` es el punto donde se decide qué sonido toca; hoy imprime y mañana llamará a los players correspondientes.
- Prioridad actual de eventos en el mismo frame: aterrizaje > salto > paso.

## Licencias

- **Codecs**: WAV/PCM es libre; Ogg Vorbis y Opus son de Xiph.Org con licencia BSD y sin patentes.
- **Samples**: usar CC0 o CC-BY, o generar los placeholders dentro del proyecto. Registrar siempre la fuente y la licencia.

## Referencias

- Godot 4.7 — Importing audio samples: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_audio_samples.html>
- Godot 4.7 — Audio streams: <https://docs.godotengine.org/en/4.7/tutorials/audio/audio_streams.html>
