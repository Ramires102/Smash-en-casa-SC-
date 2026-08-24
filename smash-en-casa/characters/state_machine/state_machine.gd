class_name StateMachine
extends Node

signal state_changed(current_state_name: String)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

# Estados opcionales para jugabilidad completa mientras se prueba contenido de animaciones.
const COMPAT_STATE_SCRIPTS: Dictionary = {
	"Walk": "res://characters/state_machine/walk_state.gd",
	"Dash": "res://characters/state_machine/dash_state.gd",
	"RunBrake": "res://characters/state_machine/run_brake_state.gd",
	"Pivot": "res://characters/state_machine/pivot_state.gd",
	"Squat": "res://characters/state_machine/squat_state.gd",
	"JumpSquat": "res://characters/state_machine/jumpsquat_state.gd",
	"Daze": "res://characters/state_machine/daze_state.gd",
	"Roll": "res://characters/state_machine/roll_state.gd",
	"Spotdodge": "res://characters/state_machine/spotdodge_state.gd"
}

# Mapeo de alias ACMD hacia FSM jugable.
const ACMD_ALIASES: Dictionary = {
	"wait": "idle",
	"walk": "walk",
	"dash": "dash",
	"run_brake": "run_brake",
	"pivot": "pivot",
	"squat": "squat",
	"jump_squat": "jumpsquat",
	"jump_f": "jump",
	"jump_b": "jump",
	"jump_aerial": "jump",
	"fall_special": "fall",
	"fast_fall": "fall",
	"guard_on": "shield",
	"guard": "shield",
	"guard_off": "shield",
	"guard_damage": "hit",
	"escape_f": "roll",
	"escape_b": "roll",
	"escape_n": "spotdodge",
	"damage_fly": "hit",
	"damage_fall": "hit",
	"stop_sce": "hit"
}

func _ready() -> void:
	await owner.ready
	_ensure_compat_states()
	_cache_states()

	if initial_state:
		current_state = initial_state
		if current_state is State:
			(current_state as State).dbg("enter_initial", {"state": current_state.name})
		current_state.enter()

func _ensure_compat_states() -> void:
	for state_name in COMPAT_STATE_SCRIPTS.keys():
		if has_node(state_name):
			continue
		var script_res: Script = load(COMPAT_STATE_SCRIPTS[state_name])
		if script_res == null:
			continue
		var state_node: Node = Node.new()
		state_node.name = state_name
		state_node.set_script(script_res)
		add_child(state_node)

func _cache_states() -> void:
	states.clear()
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.character = owner as CharacterBody3D

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	var from_state_name: String = current_state.name if current_state else "None"
	var state_key: String = target_state_name.to_lower()
	if ACMD_ALIASES.has(state_key):
		state_key = ACMD_ALIASES[state_key]

	if not states.has(state_key):
		push_error("Estado inexistente: " + target_state_name)
		return

	if current_state is State:
		(current_state as State).dbg("transition_request", {
			"from": from_state_name,
			"to_requested": target_state_name,
			"to_resolved": states[state_key].name,
			"msg": msg
		})
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_key]
	current_state.enter(msg)
	state_changed.emit(current_state.name)
