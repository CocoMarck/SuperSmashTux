# Estructura del Proyecto — SuperSmashTux

> Este documento describe la estructura de carpetas y convenciones de nombres para el proyecto Super Smash Tux.

```
supersmashtux/
├── prefabs/          # Escenas reutilizables (personajes, enemigos, items)
├── scenes/           # Escenas del juego (main.tscn, la escena principal, vive en la raíz)
│   └── levels/       # Niveles / mapas jugables (map1.tscn)
├── ui/               # Pantallas de interfaz (no son niveles): main_menu, fight_hud, controls_menu
├── scripts/          # GDScripts para nodos y lógica del juego
│   ├── characters/   # Personajes: Person -> Fighter -> PowerFighter -> Player / NPC
│   ├── combat/       # Hitboxes (nodos): Hitbox, HitboxDamage, HitboxGrab
│   ├── physics/      # Gravedad personalizada: GravityBody3D, AreaGravity3D
│   ├── platforms/    # Plataformas: Platform, GroundPlatform, OneWayPlatform
│   ├── match/        # Módulos de la partida, uno por concern (GameManager, CameraFollow, SpawnPoint)
│   ├── ui/           # Scripts de las pantallas de UI en ui/ (botones, menú de controles)
│   └── helpers/      # Clases de apoyo que NO son nodos: RefCounted y contenedores de datos/constantes
│       ├── combat/   # Datos de ataques: Attacks, PowerAttacks, FightMove, HitboxMove
│       ├── frame/    # Señales-objeto y estados por frame: MoveSignals, MoveStates, FrameMotionSignals, VerticalForceSignals
│       ├── input/    # Controles: InputSettings (autoload), PlayerInputMap
│       └── ...       # Sueltos en la raíz: game_balance.gd (constantes de balance), global_utils.gd
├── materials/        # Materiales (.tres)
├── environments/     # Entornos de mundo (.tres)
├── assets/           # Assets raw (texturas, modelos, audios fuente) — aún no creada
├── addons/           # Plugins de Godot (godot_ai: MCP de Godot para agentes de IA)
├── docs/             # Documentación, notas, ideas (estructura.md y changelog.md viven en la raíz de docs/)
│   ├── arquitectura/ # Jerarquía de clases, UML y decisiones de diseño (GameManager, process vs physics_process)
│   ├── combate/      # Hitboxes, ataques normales y power
│   ├── ia/           # NPCs: comportamiento y detección
│   ├── controles/    # Configuración de controles e InputSettings
│   ├── ui/           # Interfaz y UI responsiva
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
| Recursos | `prefijo_nombre.tres` | `mat_red.tres`, `env_game.tres` |
| Docs | `lower-kebab-case.md` (agrupados por dominio en `docs/<dominio>/`) | `estructura.md`, `titulo-descriptivo.md` |

> Los docs se agrupan por dominio en `docs/<dominio>/` (`arquitectura`, `combate`, `ia`, `controles`, `ui`, `arte`). Solo `estructura.md` y `changelog.md` van en la raíz de `docs/`.

> `scripts/` no tiene `.gd` sueltos en la raíz: cada script va en la carpeta de su dominio. Los `class_name` no dependen de la ruta.

## Godot namespace
- Nodos en escenas: **PascalCase** (estándar de Godot: `Player`, `CameraPivot`)
- Señales y métodos: **snake_case** (`on_hit`, `_physics_process`)
- Variables y funciones exportadas: **snake_case** (`@export var jump_velocity`)
- Constantes: **UPPER_SNAKE_CASE** (`const MAX_HEALTH = 100`)
- Enumeraciones: **PascalCase** (`enum PlayerState { Idle, Running, Jumping }`)
> Referente a godot gui, y a gdscript. El C#, usar el namespace estandar.
