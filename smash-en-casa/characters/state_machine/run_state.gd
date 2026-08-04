class_name RunState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Run")

func physics_update(_delta: float) -> void:
	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if abs(input_vec.x) < 0.1:
		state_machine.transition_to("RunBrake")
		return

	var current_facing: float = character.get_facing_direction()
	if sign(input_vec.x) != current_facing and abs(input_vec.x) > 0.1:
		state_machine.transition_to("Pivot", {"target_dir": sign(input_vec.x)})
		return

	var run_spd: float = character.controller.get_run_speed() if character.controller else 10.0
	character.velocity.x = input_vec.x * run_spd
	character.update_facing_direction(input_vec.x)

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
