---
name: comentar-codebase
description: Recorre todos los scripts .gd del proyecto y aplica comentarios pertinentes. Usar cuando se pida "comentar el código", "aplicar el estilo de comentarios a todo el proyecto", "documentar los scripts", o tras actualizar las reglas de comentarios y querer propagarlas a la base de código existente.
---

Vas a recorrer todos los scripts `.gd` del proyecto y dejarlos con el siguiente estilo de comentarios (esta skill es la fuente de verdad del estilo — `.claude/agents/programador-gdscript.md` solo tiene un resumen y apunta acá). El orden de miembros dentro de una clase ya es conocimiento propio del subagente `programador-gdscript` — esta skill se enfoca solo en comentarios.

## Estilo de comentarios

- Comentarios de sección con `#` para agrupar bloques de propiedades o funciones relacionadas (ej. `# Propiedades privadas | Movimientos`, `# Funciones hitbox de ataque.`). Son la forma normal de separar y dar contexto a grupos.
- Docstrings con triple comilla simple (`'''...'''`) SOLO dentro de funciones/métodos, para explicar su propósito cuando no es obvio por el nombre. Nunca como comentario de cabecera de clase o archivo — si una clase necesita explicación general, usar un comentario `#` breve, no un docstring.
- No comentar lo obvio (nombre de una variable, qué hace una línea trivial). Comentar el "por qué" o agrupar, no repetir el "qué" ya evidente por el código.
- Comentarios cortos, de una línea salvo que el contexto realmente lo justifique — nada de párrafos largos.
- Código en inglés, comentarios en español, tono informal (el mismo que ya usa el repo en sus comentarios/docstrings existentes).

## Pasos

1. Antes de tocar nada, corre `mcp__godot__run_project` + `mcp__godot__get_debug_output` (+ `stop_project`) si están disponibles, para anotar los warnings preexistentes como línea base.
2. Usa Glob para listar todos los `scripts/**/*.gd` del proyecto (excluye `.uid`, y cualquier `addons/` de terceros si existiera).
3. Procesa los scripts de a uno o en grupos pequeños relacionados (ej. un script y su clase auxiliar directa), nunca todos de golpe sin verificar. Delega cada grupo al subagente `programador-gdscript`, pasándole el "Estilo de comentarios" de arriba y pidiéndole aplicarlo: comentarios de sección `#`, docstrings `'''...'''` solo dentro de métodos, traducir cualquier comentario en inglés, no comentar lo obvio. Sin tocar lógica, valores, nombres, tipos ni el orden de miembros — es tarea puramente de comentarios.
4. Después de cada grupo modificado, verifica que el proyecto compile igual que en el paso 1 — cualquier error o warning nuevo respecto a la línea base hay que resolverlo antes de seguir con el siguiente grupo.
5. No proceses archivos `.tscn` — esta skill es solo para código GDScript. Si detectas que hace falta tocar una escena, avisa al usuario en vez de invocar `disenador-escenas` por cuenta propia.
6. Al terminar, resume en una lista corta: qué archivos se tocaron, qué comentarios se agregaron/ajustaron/tradujeron en cada uno, y confirma el estado final de compilación.
