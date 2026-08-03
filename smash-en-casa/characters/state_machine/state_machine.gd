class_name StateMachine
extends Node

signal state_changed(current_state_name: String)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.character = owner as CharacterBody3D

	if initial_state:
		current_state = initial_state
		current_state.enter()

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
	if not states.has(state_key):
		push_error("Estado inexistente: " + target_state_name)
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_key]
	current_state.enter(msg)
	state_changed.emit(current_state.name)
