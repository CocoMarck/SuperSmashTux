<p align="center">
  <img src="icon.png" width="96" alt="icon" style="margin-bottom: -12px;">
</p>
<h1 align="center">Super Smash Tux</h1>

Videojuego de peleas inspirado en Super Smash Bros, con los personajes más famosos del software libre. Hecho en Godot 4 usando GDScript.

## Características de juego

- Combate multijugador local para 2 jugadores.
- Soporte para teclado y gamepad.

## Requisitos

- [Godot Engine 4+](https://godotengine.org/download)
- [Node.js 18+](https://nodejs.org) (opcional si se quiere usar MCP para agentes de IA)

## Cómo abrir el proyecto

1. Clona el repositorio.
2. Abre Godot 4+ y selecciona "Importar", apuntando al directorio raíz del proyecto.
3. Corre la escena principal (`scenes/main.tscn`) desde el editor.

Para más detalles sobre la estructura de carpetas y convenciones del proyecto, revisa [docs/estructura.md](./docs/estructura.md).

## Desarrollo con IA

El proyecto incluye un `.mcp.json` que conecta agentes de IA (Claude Code, Cursor, Cline) con Godot vía [godot-mcp](https://github.com/Coding-Solo/godot-mcp), para que puedan correr el juego y leer los errores de la consola por su cuenta.

Para usarlo hace falta [Node.js 18+](https://nodejs.org) y ajustar la ruta `GODOT_PATH` dentro de `.mcp.json`, que apunta al ejecutable de Godot de cada ordenador.

## Licencia

Este proyecto está bajo la licencia [GPL-3.0](./LICENSE).

## Contribuir

El proyecto es open source y las contribuciones son bienvenidas. Asegurate de seguir las directrices descritas en [AGENTS.md](./AGENTS.md) si vas a usar un agente de IA para contribuir.
