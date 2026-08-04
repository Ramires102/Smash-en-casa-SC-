class_name PivotState
extends State

var pivot_timer: float = 0.0
const PIVOT_DURATION: float = 0.14 # ~9 frames de giro visible
var target_dir: float = 1.0

func enter(msg: Dictionary = {}) -> void:
	pivot_timer = PIVOT_DURATION
	target_dir = msg.get("target_dir", 1.0)
	if character:
		character.set_facing_direction(target_dir)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Pivot")

func physics_update(delta: float) -> void:
	pivot_timer -= delta
	
	# Desaceleración progresiva de la inercia anterior usando la tracción del luchador
	var trac: float = character.controller.get_traction() if character and character.controller else 30.0
	if character:
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * 2.5 * delta)

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	if pivot_timer <= 0.0:
		var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
		if abs(input_vec.x) > 0.1:
			if sign(input_vec.x) == target_dir:
				state_machine.transition_to("Run")
			else:
				state_machine.transition_to("Pivot", {"target_dir": sign(input_vec.x)})
		else:
			state_machine.transition_to("Idle")
