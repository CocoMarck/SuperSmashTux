# Nota: UI responsiva de SuperSmashTux

Cómo se hace responsiva la interfaz del juego y **por qué NO usamos el stretch mode
`canvas_items` de Project Settings**, aunque sea lo que la mayoría del foro recomienda.

## La técnica usada en el proyecto

Nada de escalar "todo el mundo". Cada UI se adapta por **anclas y contenedores**, siempre dentro de
un `CanvasLayer`:

1. **`CanvasLayer`**: todo elemento de UI vive dentro de uno. Desacopla la interfaz del mundo 2D/3D
   y hace que sus `Control` se anclen limpios al viewport. Es el patrón usado en `main.tscn`,
   `controls_menu.tscn` y `fight_canvas_layer.tscn`.
2. **Anchors**: posicionan relativo al viewport sin tamaños duros. Ejemplos del proyecto:
   - Menú principal y menú de controles: `Control` raíz con **Full Rect** (anchors 0,0 → 1,1).
   - Botón `Back to menu`: anchors **1,1** (esquina inferior derecha) con offsets negativos como margen.
3. **Containers**: centran y reparten el espacio sin calcular nada. `CenterContainer` + `VBoxContainer`
   centran el menú principal; `TabContainer` en Full Rect reparte el menú de controles.
4. **Layout en el editor**: seleccionar un nodo → botón **Layout** → **Full Rect / Center**.
   Escribir anclas a mano en el `.tscn` también jala.

Con esto la UI **se recentra y se reacomoda** a cualquier resolución. Esa es la parte que ya está
hecha en el proyecto.

## Por qué NO usamos `window/stretch/mode="canvas_items"`

> Nota: NO está en `project.godot`. Es una decisión, no un olvido.

La receta más popular en el [foro de Godot](https://forum.godotengine.org/t/how-to-resize-ui-elements-based-on-screen-size/64740)
para "UI responsiva" es activar en Project Settings → Display → Window → Stretch → Mode
**`canvas_items`**. Escala todo el viewport (y con él toda la UI) proporcional a la resolución base.

En SuperSmashTux **no lo queremos**, porque necesitamos UI que **se salga de la pantalla**.

### El caso concreto: los tags de los jugadores

Se necesita mostrar sobre cada personaje unos "tags" (nombre o marcador del jugador) que típicamente
**flotan fuera de los bordes de la ventana**: cuando el personaje está en la orilla de la arena, su
tag debe quedar parcial o totalmente **fuera del área visible**.

Si activáramos `canvas_items`, el viewport entero se redimensiona/escala y nunca hay espacio "fuera
de la pantalla": todo lo que se dibuja queda dentro de la resolución escalada. Un elemento que se
quiera salir se recorta siempre contra ese viewport escalado.

En cambio, si la UI **no** escala (viewports `Control` de tamaño real, anclados al viewport), podemos
tener elementos cuyo rect se extienda más allá del área visible — exactamente lo que pide el caso de
los tags pegados a un personaje que se sale de cámara.

Resumen de la decisión:

| Enfoque | Qué hace | Por qué no aquí |
|---|---|---|
| `canvas_items` | Escala todo el viewport + UI con la resolución | No permite UI fuera de pantalla (tags de jugador). Además estira y puede verse borroso/pixelado, como nota [este hilo del foro](https://forum.godotengine.org/t/how-to-resize-ui-elements-based-on-screen-size/64740). |
| Anclas + containers (lo usado) | La UI se recentra/reacomoda, no escala | Permite rects de UI más grandes que la pantalla. La UI sigue siendo responsiva al cambio de resolución. |

### Sacrificio aceptado

El "tamaño" de los elementos (botones, textos, tabs) NO crece con la pantalla: en una ventana gigante
los botones se ven igual de grandes, solo mejor acomodados. Es el costo correcto para tener UI que
pueda desbordar el viewport. Si algún día se quisiera agrandar la UI en pantallas grandes, se hace por
**control selector / escala por nodo**, no con stretch global.

## Documentación oficial de referencia

- Godot: [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
  (explica stretch modes, incluido `canvas_items`).
- Foro: [How to resize UI elements based on screen size?](https://forum.godotengine.org/t/how-to-resize-ui-elements-based-on-screen-size/64740)
  (hilo donde se recomienda `canvas_items`, y el trade-off de usarlo).