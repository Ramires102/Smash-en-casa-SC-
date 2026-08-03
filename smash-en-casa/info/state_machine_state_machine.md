# Explicación de `characters/state_machine/state_machine.gd`

## Resumen
Máquina de Estados Finita (FSM) genérica desacoplada. Registra dinámicamente sus estados hijos, delega el bucle `_physics_process` al estado activo y realiza transiciones seguras con `transition_to()`.

## Explicación Línea por Línea
```gdscript
1: class_name StateMachine
2: extends Node

4: signal state_changed(current_state_name: String)
5: @export var initial_state: State
6: var current_state: State
7: var states: Dictionary = {}
```
- Declara la señal `state_changed`, la referencia al estado inicial y el diccionario `states` donde se indexan los nodos de estado.

```gdscript
9: func _ready() -> void:
10: 	await owner.ready
11: 	for child in get_children():
12: 		if child is State:
13: 			states[child.name.to_lower()] = child
14: 			child.state_machine = self
15: 			child.character = owner as CharacterBody3D
```
- Indexa automáticamente todos los nodos hijos de tipo `State`, inyectando la referencia del `character` dueño y de la `state_machine`.

```gdscript
27: func _physics_process(delta: float) -> void:
28: 	if current_state:
29: 		current_state.physics_update(delta)
```
- Delega el ciclo de física de Godot al `physics_update()` del estado activo actual.

```gdscript
31: func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
32: 	var state_key: String = target_state_name.to_lower()
33: 	if not states.has(state_key): return
34: 	if current_state: current_state.exit()
35: 	current_state = states[state_key]
36: 	current_state.enter(msg)
37: 	state_changed.emit(current_state.name)
```
- `transition_to`: Ejecuta `exit()` en el estado saliente, cambia `current_state`, ejecuta `enter(msg)` en el estado entrante y emite la señal `state_changed`.

## Comunicación e Interacciones
- **Gobernador de**: Nodos `State` (Idle, Run, Jump, Fall, Attack, Hit, Death).
