# Changelog

## Resumen de lo listo (2026-08 a 2026-10)

> Nota histórica (`2026-08-19`): Apenas me di cuenta, pero gdscirpt no tiene para variables privadas. Pero weno, igual es bueno marcarlas como `_var_private`, ya que indica que eso no se toco fuera de la clase dueña. Es una forma de documentar.

### Personajes y combate
- Refactor de hitboxes **LISTO**: `AreaGravity3D`, `Hitbox`, `HitboxDamage` y `HitboxGrab`, con daño, knockback, debug y lifetime; varios hitboxes de daño por movimiento.
- Movimiento base de `Person` **LISTO**: caminar, correr, caminar agachado, salto y salto en el aire.
- Tercer salto de `PowerFighter` **LISTO**: animaciones para salto en piso y aire, con bloqueo de saltos hasta tocar el piso.
- Daño y stun **LISTO**: hitstun normal, heavy hitstun, knockout, mejoras de knockback/hitstun y bloqueo de inputs mientras dura el estado.
- Escudo de `Fighter` **LISTO**: blockstun, pushback, animación placeholder, sin regeneración mientras se rueda y sin gastar capacidad durante el blockstun.
- Ataques de `Fighter` **LISTO**: grab como ataque, ataques con salto, tres ataques neutrales en piso, cancelación de heavy hitstun en ataques aéreos y margen de error para inputs de dirección.
- Animaciones placeholder **LISTO**: knocked out, grabbed/grabbing y escudo.
- Animación de caída al piso **LISTO**: cooldown corto según la velocidad vertical previa, cancelable al recibir daño.
- Corrección de `Person` **LISTO**: bug al combinar mirar arriba/agacharse con movimiento horizontal.

### Arquitectura y refactor
- `Person._physics_process` modular **LISTO**: `Fighter` reutiliza el flujo sin reemplazarlo por completo.
- Funciones de estado **LISTO**: reemplazo de bools redundantes por funciones que consultan sus timers.
- `GravityBody3D` **LISTO**: ancho y alto públicos con `get_width()`/`get_height()`, y eliminación del helper legacy de media altura.
- Constantes de juego **LISTO**: duraciones de stun, efectos, movimientos compartidos y márgenes de perdón en `GameBalance`.
- One-way platforms **LISTO**: lógica movida de `GravityBody3D` a `Person`.
- Archivos **LISTO**: `gravity_body_3d.gd` movido a `characters/`, `area_gravity_3d.gd` movido a `combat/` y carpeta `physics/` eliminada.

### UI y escenas
- Menú principal **LISTO**: menú como escena principal, configuración de controles y regreso al menú desde el juego.
- Interfaz responsiva **LISTO**: menú, controles y HUD ajustables.
- Reorden de escenas/UI **LISTO**: `scenes/levels/`, `scenes/main.tscn` y pantallas de UI en `ui/`; `scripts/menu/` renombrado a `scripts/ui/`.

### Documentación y limpieza
- Limpieza de legacy **LISTO**: eliminación de scripts, escenas, prefabs, animaciones y notas históricas en desuso.
- Docs ordenados **LISTO**: reorganización por dominio (`arquitectura/`, `combate/`, `ia/`, `controles/`, `ui/`, `arte/`) y fusión de notas de controles.
- Scripts ordenados por dominio **LISTO**: `characters/`, `combat/`, `platforms/`, `match/`, `ui/`, y helpers en `combat/`, `frame/`, `input/`.

---

## Pendientes anteriores a noviembre de 2026

### `2026-08-28`
> Aveces ando en modo automático, y pongo cosas redundantes

- Arreglar Bug **FALTA**: hacer ataque con salto mientras `_holding_onto_the_ledge()`, sucede bug visual, porque se eleva first frame del ataque con salto y luego cancela. 
- Efecto visual al hacer movimientos especiales **FALTA**: Ejemplo: Moverse hacia abajo mas rápido. Al bajarse de plataforma.

- `process_sound` **FALTA**: modulo que obtiene señales, para reproducir sonidos, sonido de pasos, de daño recibido, y etc.
    - Contar tiempo al moverse en el piso o en el aire. (Solo cuando no se recibe daño)
    - Obtener señal frame uno al recibir daño.
    - Obtener señal frame uno al caer en el piso.
    - Obtener señal frame uno al saltar en el piso o en el aire.
    - Obtener señal frame uno al caer en cealing/techo o en wall.

- Bug **TESTEAR**: Por alguna extraña razón el `heavy_hitstun`, queda fijado de forma rara. Aun no identifico que lo deja siempre activo. hasta parece random. Ya lo cambie, párese jalar. El pedo era el flag/bool de wait heavy hitstun get up.

- Aceleración horizontal **TESTEAR**: al tener poca, si se mueve rapido, pero queda raro cuando se mueve en el aire aveces, ya que al ser poca, aveces se mueve muy rapido en el aire.

### `2026-09-28`
- **FALTA** `Person` `GravityBody3D` Arraglar **BUG**: Cuando se colisiona en position perfecta, mismo `x, y, z`, salen volando. Cuando saltan, hago que su colision desaparesca `_toggle_body_collisions`, si sucede que cuando caen, y tienen ambos bodys el mismo `x y z`, salen volando hacia arriba.

---
## `2026-11`

#### `2026-11-08`
- `GameManager` **LISTO**: Que el manejo de vidas sea otro modulo. `LivesManager`
- `GameManager` **LISTO**: Que el manejo de tiempo limite o conteo de partida sea otro modulo. Posiblemente se llamara `MatchTime`.
- `GameManager` **LISTO**: Que el conteo regresivo para empezar a jugar, sea otro modulo. `MatchCountdown`
- `GameManager` **FALTA**: Modulo de manejo velocidad de juego. Para hacer efectos de velocidad lenta, o hacer un freaze al dar un golpe killer.
- `GameManager` **FALTA**: Que el manejo de HUD de juego sea otro modulo.

#### `2026-11-09`
- `GameManager` **LISTO**: `PowerFighterSlots` (usa `PowerFighterData`), información del como seran los peleadores, sus vidas, que tipo de peleadores seran etc. Remplazo `MatchSlots`.
- `GameManager` **FALTA**: Tratar `Person` (el papá) en vez de `PowerFighter`, para crecer a más modos de juego. (Por ahora `2026-11-10` medio enredado de hacer, pero posible)

- Helper de nombres **FALTA**: utilidad estática enfocada a `Person` (cubre `PowerFighter` y futuros hijos). Usará `Node.name` directamente; **no** se agrega una propiedad `name` nueva.
