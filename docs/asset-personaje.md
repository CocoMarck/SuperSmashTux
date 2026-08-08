# Asset de Personaje (contrato visual)

> Estructura esperada para los assets de personaje y cómo se instancian dentro de un `CharacterBody3D`. **Propuesta de convención; aplicar al crear assets nuevos.**

## Estructura del asset (escena instanciable)

```
Node3D               # Raíz del asset = el "contrato" del modelo
    Pivot            # Node3D: aquí viven volteos y spin del personaje
        Skeleton3D
            MeshInstance3D
    AnimationPlayer
```

## Uso dentro de un personaje

```
CharacterBody3D      # script Person/Fighter
    CollisionShape3D
    Visual           # Instancia del asset (nodo renombrado)
```

## Reglas

- **Nombres fijos.** `Pivot`, `MeshInstance3D` y `AnimationPlayer` deben llamarse igual en todos los assets. Los scripts acceden por ruta fija (`$Visual/Pivot`, `$Visual/AnimationPlayer`); si cada asset nombrara sus nodos distinto, habría que andar codeando cambios de nombre por asset, y eso no.
- **`MeshInstance3D` siempre con material.** La malla debe traer material asignado (por defecto o propio). Sin material se ve invisible/blanco de más.
- **`Skeleton3D` sí va en el asset, pero solo lo tocan las animaciones.** Las animaciones animan los huesos; **no se usa desde código** (ningún script accede a `Skeleton3D`).
- **El `Pivot` vive dentro del asset** para que volteos, rotación de daño (spin) y animaciones viajen juntos con el modelo.
