# Explicación de `characters/animation_controller.gd`

## Resumen
Abstracción limpia sobre el nodo `AnimationPlayer` de Godot para reproducir animaciones por nombre de forma segura.

## Explicación Línea por Línea
```gdscript
1: class_name AnimationController
2: extends Node

4: @export var animation_player: AnimationPlayer

6: func play_animation(anim_name: String) -> void:
7: 	if animation_player and animation_player.has_animation(anim_name):
8: 		animation_player.play(anim_name)
```
- `play_animation`: Valida la existencia del reproductor y la existencia de la animación antes de invocar `play()`, previniendo errores en tiempo de ejecución.

## Comunicación e Interacciones
- **Consumido por**: Todos los estados de la FSM (`IdleState`, `RunState`, `JumpState`, `AttackState`, etc.).
