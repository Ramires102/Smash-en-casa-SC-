# Explicación de `shared/helpers.gd`

## Resumen
Ofrece funciones auxilares de física 2.5D para asegurar que los personajes permanezcan bloqueados en la coordenada Z deseada.

## Explicación Línea por Línea
```gdscript
1: class_name Helpers
2: extends RefCounted
```
- Clase utilitaria con métodos estáticos.

```gdscript
4: static func constrain_to_2d_plane(node: Node3D, z_pos: float = 0.0) -> void:
5: 	if node:
6: 		node.global_position.z = z_pos
```
- `constrain_to_2d_plane`: Recibe un nodo 3D (como `CharacterBody3D`) y fuerza su posición global en el eje Z a `z_pos` (0.0 por defecto). Esto evita desplazamientos fuera del plano de juego 2.5D tras colisiones o impulsos.

## Comunicación e Interacciones
- **Consumido por**: `Character.gd` en `_physics_process()` en cada frame.
