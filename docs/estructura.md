# Estructura del Proyecto — SuperSmashTux

```
supersmashtux/
├── prefabs/          # Escenas reutilizables (player, enemigos, items)
├── scenes/           # Escenas principales (main, niveles, menús, UI)
├── scripts/          # GDScripts
├── assets/           # Assets raw (texturas, modelos, audios fuente)
├── docs/             # Documentación, notas, ideas
├── AGENTS.md         # Instrucciones para la IA
└── project.godot
```

## File namespace

| Tipo | Convención | Ejemplo |
|---|---|---|
| Escenas | `snake_case.tscn` | `player.tscn`, `main_menu.tscn` |
| Scripts | `snake_case.gd` | `player.gd`, `camera_follow.gd` |
| Assets | `snake_case.ext` | `ground_texture.png`, `jump_sfx.wav` |
| Docs | `lower-kebak-case.md` | `estructura.md`, `titulo-descriptivo.md` |

## Godot namespace
- Nodos en escenas: **PascalCase** (estándar de Godot: `Player`, `CameraPivot`)
- Señales y métodos: **snake_case** (`on_hit`, `_physics_process`)
- Variables y funciones exportadas: **snake_case** (`@export var jump_velocity`)
> Referente a godot gui, y a gdscript. El C#, usar el namespace estandar.
