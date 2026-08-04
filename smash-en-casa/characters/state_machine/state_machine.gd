class_name StateMachine
extends Node

signal state_changed(current_state_name: String)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

# Mapeo de alias de ACMD Action States de Super Smash Bros. Ultimate
const ACMD_ALIASES: Dictionary = {
	"wait": "idle",
	"walk": "walk",
	"dash": "dash",
	"run_brake": "runbrake",
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
	"guard_damage": "shield",
	"escape_f": "roll",
	"escape_b": "roll",
	"escape_n": "spotdodge",
	"damage_fly": "hit",
	"damage_fall": "hit",
	"stop_sce": "hit"
}

func _ready() -> void:
	await owner.ready
	_ensure_default_states()
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.character = owner as CharacterBody3D

	if initial_state:
		current_state = initial_state
		current_state.enter()

func _ensure_default_states() -> void:
	if not has_node("Roll"):
		var roll_node := RollState.new()
		roll_node.name = "Roll"
		add_child(roll_node)
	if not has_node("Spotdodge"):
		var dodge_node := SpotDodgeState.new()
		dodge_node.name = "Spotdodge"
		add_child(dodge_node)
	if not has_node("Daze"):
		var daze_node := DazeState.new()
		daze_node.name = "Daze"
		add_child(daze_node)
	if not has_node("JumpSquat"):
		var js_node := JumpSquatState.new()
		js_node.name = "JumpSquat"
		add_child(js_node)
	if not has_node("Walk"):
		var walk_node := WalkState.new()
		walk_node.name = "Walk"
		add_child(walk_node)
	if not has_node("Dash"):
		var dash_node := DashState.new()
		dash_node.name = "Dash"
		add_child(dash_node)
	if not has_node("RunBrake"):
		var rb_node := RunBrakeState.new()
		rb_node.name = "RunBrake"
		add_child(rb_node)
	if not has_node("Pivot"):
		var pivot_node := PivotState.new()
		pivot_node.name = "Pivot"
		add_child(pivot_node)
	if not has_node("Squat"):
		var squat_node := SquatState.new()
		squat_node.name = "Squat"
		add_child(squat_node)

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
	var state_key: String = target_state_name.to_lower()
	if ACMD_ALIASES.has(state_key):
		state_key = ACMD_ALIASES[state_key]

	if not states.has(state_key):
		push_error("Estado inexistente: " + target_state_name)
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_key]
	current_state.enter(msg)
	state_changed.emit(current_state.name)
