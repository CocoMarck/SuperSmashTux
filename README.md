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
- [Blender 5.1+](https://www.blender.org/download/) (opcional si se quiere editar los modelos 3D)

## Cómo abrir el proyecto

1. Clona el repositorio.
2. Abre Godot 4+ y selecciona "Importar", apuntando al directorio raíz del proyecto.
3. Corre la escena principal (`scenes/main.tscn`) desde el editor.

Si vas a trabajar con un agente de IA, ejecutá además `mcp-setup.bat` antes de arrancarlo (ver [Desarrollo con IA](#desarrollo-con-ia)).

Para más detalles sobre la estructura de carpetas y convenciones del proyecto, revisa [docs/estructura.md](./docs/estructura.md).

## Desarrollo con IA

El proyecto incluye un archivo `.mcp.json` que conecta agentes de IA (OpenCode, Codex, etc.) con dos programas, para que puedan trabajar por su cuenta:

| Servidor | Qué permite | Requisitos |
|---|---|---|
| `godot` | Modificar escenas y correr el juego, vía [godot-mcp](https://github.com/Coding-Solo/godot-mcp) | [Node.js 18+](https://nodejs.org) |
| `blender` | Inspeccionar y editar la escena abierta en Blender, vía [MCP oficial de Blender Lab](https://www.blender.org/lab/mcp-server/) | [Blender 5.1+](https://www.blender.org/download/) y [uv](https://docs.astral.sh/uv/) |

Ambos se configuran con **mcp-setup.bat**, que hay que ejecutar antes de usar el MCP por primera vez. Al abrirlo aparece un menú para elegir qué configurar. El script detecta los ejecutables por su cuenta y escribe `GODOT_PATH` y `BLENDER_PATH` en el `.mcp.json`.

Después de ejecutarlo hay que reiniciar el agente de código para que tome la configuración nueva.

### Sobre el MCP de Godot

Es una sola pieza: el servidor **godot-mcp**, que el agente de código lanza con `npx`. `npx` descarga el paquete la primera vez que se usa, solo se necesita tener Node.js y que `GODOT_PATH` apunte al ejecutable de Godot, (lo resuelve `mcp-setup.bat`).

Permite crear escenas y nodos, leer la información del proyecto, y correr el juego para después leer su salida de depuración, que es la forma más directa de que el agente diagnostique errores en tiempo de ejecución.

A diferencia de Blender, **no hace falta tener el editor abierto**: el servidor invoca a Godot por línea de comandos cuando lo necesita.

### Sobre el MCP de Blender

El MCP oficial de Blender son **dos piezas** que se comunican por un socket TCP en `localhost:9876`:

- un **add-on** que corre dentro de Blender y ejecuta los pedidos;
- el servidor **`blender-mcp`**, que lanza el agente de código.

`mcp-setup.bat` se encarga de las dos: instala `uv` con winget, agrega el repositorio de extensiones `https://lab.blender.org/` y desde ahí instala y habilita el add-on. Instalarlo desde el repositorio permite recibir actualizaciones.

A tener en cuenta:

- **Cerrar Blender antes de ejecutar `mcp-setup.bat`:** Una instancia abierta sobrescribe sus preferencias al cerrarse y se perdería el add-on recién instalado. Si el script detecta Blender abierto, avisa y omite ese paso.
- **Abrir Blender antes de usar sus herramientas:** El add-on levanta el servidor al arrancar, así que sin Blender abierto el agente no puede conectarse.

## Licencia

Este proyecto está bajo la licencia [GPL-3.0](./LICENSE).

## Contribuir

El proyecto es open source y las contribuciones son bienvenidas. Asegurate de seguir las directrices descritas en [AGENTS.md](./AGENTS.md) si vas a usar un agente de IA para contribuir.
