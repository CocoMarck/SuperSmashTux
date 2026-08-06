# Nota: Cámara dinámica

> Cómo funciona la cámara estilo Smash Bros del juego. Script: `scripts/camera_follow.gd`.

## La idea de fondo

La cámara es como un camarógrafo: su único trabajo es que todos los peleadores quepan en la foto, sin quedar ni muy lejos ni muy encima, pero con límites.

## Las dos cajas

En la escena hay dos `Area3D` invisibles, una dentro de la otra, ajustables desde el editor:

- **`CameraArea`** (la chica): hasta dónde la cámara te sigue. Si te sales, deja de perseguirte y se queda apuntando al borde por donde saliste.
- **`PlayArea`** (la grande): hasta dónde le importas. Si te sales de ésta, la cámara te olvida por completo y reencuadra a los que quedan. A futuro será la zona de muerte.

El espacio entre las dos es tierra de nadie: ya no te siguen pero todavía cuentas pal encuadre. Ahí es donde te vas saliendo de pantalla, y donde en el futuro aparecerá la burbuja de jugador fuera de cuadro.

## Qué hace en cada frame

1. Junta a todos los peleadores de la escena y descarta a los que salieron del `PlayArea`.
2. A los que salieron de la `CameraArea` (pero siguen dentro del `PlayArea`) los trata como si estuvieran pegados a su borde. El recorte es **por eje**: si te sales por la derecha, tu posición horizontal se queda clavada en el borde, pero la vertical sigue contando en vivo.
3. Junta las posiciones de esos peleadores en un solo cuadro que los abarca a todos.
4. De ese cuadro saca las dos cosas que necesita: hacia dónde apuntar (su centro) y qué tan regados están los peleadores (su tamaño).
5. Traduce "qué tan regados" a una distancia de cámara, de forma proporcional: todos encimados es lo más cerca posible, y en esquinas opuestas de la `CameraArea` es lo más lejos. Todo lo de en medio cae proporcionalmente en medio.
6. No salta directo al objetivo: se desliza un suavemente cada frame hacia ahí.

## La regla que más se siente

**Se aleja rápido pero se acerca lento.** Es a propósito: si se alejara lento, en una pelea rápida la gente se sale de pantalla y no ves nada de la acción. Si se acercara rápido, la cámara da tirones cada vez que los peleadores se juntan y marea al que está viendo.

De pilón, como la cámara nunca salta (siempre se desliza), absorbe el teletransporte del knockback — que avienta a los personajes muy lejos de un frame a otro — sin que se note el brinco.

## Cómo se ajusta

- Las dos cajas se arrastran y redimensionan directo en el editor; el código lee su geometría en vivo cada frame, no hay que tocar el script para reencuadrar el nivel. La `CameraArea` es la que manda en el zoom: entre más chica, más dramático el acercamiento cuando los peleadores se juntan.
- En el inspector del `CameraPivot` hay perillas para qué tan cerca y qué tan lejos puede llegar la cámara, y qué tan rápido abre (se aleja) y cierra (se acerca).

## Un detalle de configuración que vale la pena dejar anotado

`play_area` y `camera_area` son propiedades del script que apuntan a nodos (`Area3D`). En el `.tscn`, eso **obliga** a que el nodo `CameraPivot` declare `node_paths=PackedStringArray("play_area", "camera_area")` en su línea `[node ...]`. Sin ese atributo, Godot deja las propiedades en `null` **sin avisar con ningún warning**, y el sistema falla en silencio (la cámara deja de encuadrar bien, sin error visible). Ya pasó una vez y costó encontrarlo — si algún día la cámara "no jala", es lo primero que hay que revisar.

## Qué NO hace todavía

- **Burbuja de jugador fuera de pantalla**: cuando un peleador está entre `CameraArea` y `PlayArea` (o más lejos), en Smash aparece un icono en el borde de pantalla indicando dónde está. No está implementado.
- **Zona de muerte**: hoy salir del `PlayArea` solo saca al peleador del encuadre, no lo mata ni le quita nada.

Decisión de diseño: cuando se implementen, ambos sistemas irán **independientes** de la cámara. La burbuja se resolverá preguntándole a la cámara si el jugador cae dentro de lo que se ve en pantalla, sin depender del zoom actual ni de las cajas — para no acoplar esa lógica al sistema de encuadre.
