# Estructura del Proyecto — SuperSmashTux

> Este documento describe la estructura de carpetas y convenciones de nombres para el proyecto Super Smash Tux.

```
supersmashtux/
├── prefabs/          # Escenas reutilizables (personajes, enemigos, items)
├── scenes/           # Escenas del juego (main.tscn, la escena principal, vive en la raíz)
│   └── levels/       # Niveles / mapas jugables (map1.tscn)
├── ui/               # Pantallas de interfaz (no son niveles): main_menu, character_menu, match_menu, fight_hud, controls_menu
│   ├── components/   # Piezas de UI que se instancian dentro de las pantallas
│   │   ├── common/   # Componentes reutilizados entre pantallas (key_hint: aviso de tecla con variantes; marching_border: borde discontinuo que gira; ready_banner: pregunta Sí/No con título configurable, «¿CONTINUAR?» en la selección y «¿LISTOS?» en la configuración)
│   │   ├── hud/      # Componentes del fight_hud (player_plate, countdown, end_window...)
│   │   ├── character_menu/ # Componentes de la selección de personaje (slot_card, roster_tile...)
│   │   └── match_menu/     # Componentes de la Configuración de partida (stage_tile, rule_row)
│   └── themes/       # Theme Kernel (theme_kernel.tres)
├── scripts/          # GDScripts para nodos y lógica del juego
│   ├── characters/   # Cadena de personajes: GravityBody3D -> Person -> Fighter -> PowerFighter
│   ├── controllers/  # Controladores por composicion (nodo hijo de Person): PersonController3D -> PlayerController / NpcController
│   ├── combat/       # Hitboxes (nodos): AreaGravity3D -> Hitbox -> HitboxDamage / HitboxGrab
│   ├── platforms/    # Plataformas: Platform, GroundPlatform, OneWayPlatform
│   ├── match/        # Módulos de la partida, uno por concern (GameManager, LivesManager, MatchTime, MatchCountdown, PowerFighterSlots, CameraFollow, SpawnPoint, PowerFighterConfigurer)
│   ├── ui/           # Scripts de las pantallas de UI en ui/; components/ refleja ui/components/ (common, hud, character_menu, match_menu: stage_tile, rule_row, stage_plan con el plano 2D del nivel)
│   └── helpers/      # Clases de apoyo que NO son nodos: RefCounted y contenedores de datos/constantes
│       ├── combat/   # Datos de ataques: Attacks, PowerAttacks, FightMove, HitboxMove
│       ├── frame/    # Señales-objeto y estados por frame: MoveSignals, MoveStates, FrameMotionSignals, VerticalForceSignals, JumpSignals, MoveInput
│       ├── input/    # Controles: InputSettings (autoload), PlayerInputMap
│       ├── ui/       # Helpers de UI: CharacterCatalog (Entry con config_id, display_name, glyph, model), StageCatalog (escenarios del menú: Random + map1), KeyText (texto de teclas leído del Input Map; lo comparten character_menu y match_menu)
│       ├── characters/ # Fichas de personaje: CharacterRegistry (lee los .cfg), PersonConfig (ficha ya leída)
│       ├── match/    # Datos de partida: PowerFighterData (un slot)
│       └── ...       # Sueltos en la raíz (globales): game_balance.gd, global_utils.gd
├── materials/        # Materiales (.tres)
├── environments/     # Entornos de mundo (.tres)
├── assets/           # Assets raw (modelos, audios, fuentes)
│   ├── models/       # Modelos .glb (y sus texturas), una carpeta por personaje: models/<id>/ (standard, tux)
│   ├── audio/        # Audios fuente
│   │   └── sfx/      # SFX (wavs) y sus randomizers (.tres)
│   └── fonts/        # Fuentes
├── data/             # Configs en texto (.cfg) y, en el futuro, CSV de traducciones
│   ├── templates/    # Plantillas: name.person.cfg, name.fighter.cfg, name.power_fighter.cfg
│   ├── locale/       # (FALTA) strings.csv con columnas keys,en,es
│   └── power_fighters/  # identities.cfg (manifiesto, admite hidden) + configs <id>.person.cfg (p. ej. tux); standard es base hardcodeada sin cfg
├── addons/           # Plugins de Godot (godot_ai: MCP de Godot para agentes de IA)
├── docs/             # Documentación, notas, ideas (estructura.md y changelog.md viven en la raíz de docs/)
│   ├── arquitectura/ # Jerarquía de clases, UML y decisiones de diseño (GameManager, process vs physics_process)
│   ├── combate/      # Hitboxes, ataques normales y power
│   ├── ia/           # NPCs: comportamiento y detección
│   ├── controles/    # Configuración de controles e InputSettings
│   ├── ui/           # Interfaz, UI responsiva e internacionalización (nota-internacionalizacion-ui.md)
│   └── arte/         # Assets, modelos, animaciones y nombres para personajes
├── .claude/          # Config local de Claude Code (agentes, skills, settings)
├── AGENTS.md         # Archivo principal de instrucciones para agentes de IA
├── README.md         # Documento de presentación del proyecto
├── LICENSE           # Licencia Open Source GPL-3.0
├── .mcp.json         # Servidor MCP de Blender para agentes de IA (lo genera mcp-setup)
├── mcp-setup.bat     # Script de configuración del MCP de Blender (mcp-setup.sh en Linux)
├── .gitignore        # Archivo para ignorar archivos y carpetas irrelevantes en Git
├── .gitattributes    # Archivo para definir atributos de archivos en Git
├── icon.png          # Icono del Juego
└── project.godot     # Archivo principal del proyecto Godot
```

## File namespace

| Tipo | Convención | Ejemplo |
|---|---|---|
| Escenas | `snake_case.tscn` | `player.tscn`, `main_menu.tscn` |
| Scripts | `snake_case.gd` | `player.gd`, `camera_follow.gd` |
| Assets | `snake_case.ext` | `ground_texture.png`, `jump_sfx.wav` |
| Configs | `<personaje>.<dominio>.cfg`, plantillas `name.*.cfg` o `identities.cfg` para el manifiesto global | `tux.person.cfg`, `name.fighter.cfg`, `identities.cfg` |
| Recursos | `prefijo_nombre.tres` | `mat_red.tres`, `env_game.tres` |
| Docs | `lower-kebab-case.md` (agrupados por dominio en `docs/<dominio>/`) | `estructura.md`, `titulo-descriptivo.md` |

> `identities.cfg` rompe la convención `<personaje>.<dominio>.cfg` a propósito: es un manifiesto global, no la config de un personaje. Cada sección es un id `snake_case` con `name` visible.

> Los docs se agrupan por dominio en `docs/<dominio>/` (`arquitectura`, `combate`, `ia`, `controles`, `ui`, `arte`). Solo `estructura.md` y `changelog.md` van en la raíz de `docs/`.

> `scripts/` no tiene `.gd` sueltos en la raíz: cada script va en la carpeta de su dominio. Los `class_name` no dependen de la ruta.

> `GameManager` es el script del nodo raíz de cada mapa; los módulos de partida cuelgan de él. `LivesManager`, `MatchTime` y `MatchCountdown` viven como nodos hijos en `map1.tscn`.

## Godot namespace
- Nodos en escenas: **PascalCase** (estándar de Godot: `Player`, `CameraPivot`)
- Señales y métodos: **snake_case** (`on_hit`, `_physics_process`)
- Variables y funciones exportadas: **snake_case** (`@export var jump_velocity`)
- Constantes: **UPPER_SNAKE_CASE** (`const MAX_HEALTH = 100`)
- Enumeraciones: **PascalCase** (`enum PlayerState { Idle, Running, Jumping }`)
> Referente a godot gui, y a gdscript. El C#, usar el namespace estandar.
