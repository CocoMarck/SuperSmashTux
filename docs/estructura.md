# Estructura del Proyecto — SuperSmashTux

> Este documento describe la estructura de carpetas y convenciones de nombres para el proyecto Super Smash Tux.

```
supersmashtux/
├── prefabs/          # Escenas reutilizables (personajes, enemigos, items)
├── scenes/           # Escenas principales (main, niveles, menús, UI)
├── scripts/          # GDScripts para nodos y lógica del juego
│   └── helpers/      # Clases de apoyo que NO son nodos: RefCounted y contenedores de datos/constantes
├── animations/       # Recursos de animación (.res)
├── materials/        # Materiales (.tres)
├── environments/     # Entornos de mundo (.tres)
├── assets/           # Assets raw (texturas, modelos, audios fuente) — aún no creada
├── docs/             # Documentación, notas, ideas
├── .claude/          # Config local de Claude Code (agentes, skills, settings)
├── AGENTS.md         # Archivo principal de instrucciones para agentes de IA
├── README.md         # Documento de presentación del proyecto
├── LICENSE           # Licencia Open Source GPL-3.0
├── .mcp.json         # Servidor MCP de Godot para agentes de IA
├── mcp-setup.bat     # Script de configuración del servidor MCP
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
| Docs | `lower-kebab-case.md` | `estructura.md`, `titulo-descriptivo.md` |

## Godot namespace
- Nodos en escenas: **PascalCase** (estándar de Godot: `Player`, `CameraPivot`)
- Señales y métodos: **snake_case** (`on_hit`, `_physics_process`)
- Variables y funciones exportadas: **snake_case** (`@export var jump_velocity`)
- Constantes: **UPPER_SNAKE_CASE** (`const MAX_HEALTH = 100`)
- Enumeraciones: **PascalCase** (`enum PlayerState { Idle, Running, Jumping }`)
> Referente a godot gui, y a gdscript. El C#, usar el namespace estandar.
