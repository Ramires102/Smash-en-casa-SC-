class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()

	if character.is_on_floor():
		character.is_fast_falling = false
		if absf(input_vec.x) > 0.15:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return

	if character.has_coyote_jump() and character.is_jump_just_pressed():
		character.consume_coyote_jump()
		character.is_fast_falling = false
		state_machine.transition_to("Jump", {"is_double_jump": false})
		return

	if character.air_jumps_left > 0 and character.is_jump_just_pressed():
		character.air_jumps_left -= 1
		character.is_fast_falling = false
		state_machine.transition_to("Jump", {"is_double_jump": true})
		return

	if character.is_shield_pressed() and character.can_air_dodge:
		state_machine.transition_to("AirDodge")
		return

	# Fast-fall progresivo idéntico a fall_state.ts (18.0 m/s² -> TERMINAL_VELOCITY * 1.25)
	if input_vec.y < -0.5 and character.velocity.y > 0.0:
		character.is_fast_falling = true
		var max_fast_fall: float = 22.0 * 1.25 * Constants.UNIT_SIZE
		character.velocity.y = minf(max_fast_fall, character.velocity.y + (18.0 * Constants.UNIT_SIZE) * delta)

	# Horizontal air drift (lambda = 7.5 con input, AIR_FRICTION = 3.5 sin input)
	if character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta, 7.5)
