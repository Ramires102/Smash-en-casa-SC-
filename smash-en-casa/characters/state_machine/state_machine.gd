# ==============================================================================
# StateMachine — Máquina de Estados Finitos (FSM) del Luchador
# ==============================================================================
# Registra automáticamente todos sus nodos hijos de tipo State y delega en un
# único estado activo (`current_state`) las llamadas de input, renderizado y
# física. Garantiza que el luchador nunca tenga dos estados contradictorios a la
# vez (ej. no puede correr y estar aturdido simultáneamente).
# ==============================================================================
class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready
	_cache_states()

	if initial_state:
		current_state = initial_state
		current_state.dbg("enter_initial", {"state": current_state.name})
		current_state.enter()

func _cache_states() -> void:
	states.clear()
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.character = owner as Character

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Cambia de estado cerrando el actual (`exit`) e iniciando el nuevo (`enter`).
func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	var state_key: String = target_state_name.to_lower()
	if not states.has(state_key):
		push_error("StateMachine: estado inexistente '%s'" % target_state_name)
		return

	if current_state:
		current_state.dbg("transition_request", {
			"from": String(current_state.name),
			"to": states[state_key].name,
			"msg": msg
		})
		current_state.exit()

	current_state = states[state_key]
	current_state.enter(msg)
