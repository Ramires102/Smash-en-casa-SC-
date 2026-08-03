# Explicación de `systems/input_buffer.gd`

## Resumen
Buffer de comandos que almacena pulsaciones de botones con marcas de tiempo (timestamps) para permitir que los ataques se ejecuten fluidamente aunque el jugador presione el botón unos milisegundos antes de que el personaje vuelva al estado `Idle` o `Fall`.

## Explicación Línea por Línea
```gdscript
1: class_name InputBuffer
2: extends Node

4: @export var buffer_window_seconds: float = 0.15
5: var action_timestamps: Dictionary = {}
```
- Define la ventana de buffer (0.15 segundos = 9 frames aprox.) y el diccionario de acciones activas.

```gdscript
7: func register_action(action_name: String) -> void:
8: 	action_timestamps[action_name] = Time.get_ticks_msec() / 1000.0
```
- Guarda el tiempo exacto en segundos en el que el jugador presionó la acción.

```gdscript
10: func is_action_buffered(action_name: String) -> bool:
11: 	if not action_timestamps.has(action_name): return false
12: 	var now: float = Time.get_ticks_msec() / 1000.0
13: 	return (now - action_timestamps[action_name]) <= buffer_window_seconds
```
- Verifica si la pulsación se realizó dentro de la ventana de buffer permitida.

```gdscript
15: func consume_action(action_name: String) -> void:
16: 	action_timestamps.erase(action_name)
```
- Limpia la acción consumida para evitar ejecuciones duplicadas.

## Comunicación e Interacciones
- **Consumido por**: `Character.gd` y `AttackState.gd`.
