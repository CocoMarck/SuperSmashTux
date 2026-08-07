# Notas de Problemas

## Modelos y Animaciones
Para que funcine adecuadamente el escalado y posicion, lo mejor es hacerlo por script. Establecer escala por script, el size del mesh, y su pos. 

Tema animaciones, no hay mucho problema, funcionan adecuadamente. Lo mejor es usar Blender, ya que este se comunica muy bien con godot.

Tema materiales, asegurarse de meterle uno a la malla, para que se pueda remplazar o agregar en Godot. De lo contrario, pos no se puede poner material a la malla.

Tema posición direccion, y eso, se batalla. Ya que se tendra que fixiear, al menos que de antemano ya se tenga todo diseñado.

Asegurarse que el origen de la malla sea en medio de esta. Para mejor integración. El Pivot el Node3D que almacene la malla, tambien que este el origin en medio de la malla.

- **Origen al centro, frente -Z, escala 1:1 (1u = 1m), material base en Blender. Si queda escrita, todos los modelos futuros la siguen y el "se batalla" desaparece.**

