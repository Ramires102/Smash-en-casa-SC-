class_name RunState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Run")

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if character == null:
		return

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return

	if character.is_jump_just_pressed():
		state_machine.transition_to("Jump")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if input_vec.y < -0.65 and character.global_position.y < -10.0 and character.is_down_just_pressed():
		character.global_position.y += 12.0
		character.velocity.y = maxf(character.velocity.y, 60.0)
		state_machine.transition_to("Fall")
		return

	if absf(input_vec.x) <= 0.1:
		state_machine.transition_to("Idle")
		return

	character.set_facing_direction(1.0 if input_vec.x > 0.0 else -1.0)
	var run_spd: float = character.controller.get_run_speed() if character.controller else (8.6 * Constants.UNIT_SIZE)
	var target_speed_x: float = input_vec.x * run_spd
	if character.controller:
		character.controller.accelerate_ground_velocity(target_speed_x, delta)
