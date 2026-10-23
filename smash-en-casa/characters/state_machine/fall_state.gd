class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func physics_update(delta: float) -> void:
	if character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()

	if character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta)

	# Fast-Fall con soporte para el buffer de ápice
	if character.velocity.y >= Constants.FASTFALL_MIN_VY and character.consume_fastfall_intent() and not character.is_fast_falling:
		character.is_fast_falling = true
		character.velocity.y = character.controller.get_fast_fall_speed()
	elif character.is_fast_falling and character.controller:
		character.velocity.y = character.controller.get_fast_fall_speed()

	# Aterrizaje en el suelo
	if character.is_on_floor():
		character.is_fast_falling = false
		state_machine.transition_to("Idle", {"landing_lag": Constants.NORMAL_LANDING_LAG_FRAMES})
		return

	# Coyote Jump
	if character.has_coyote_jump() and character.is_jump_just_pressed():
		character.consume_coyote_jump()
		character.is_fast_falling = false
		state_machine.transition_to("Jump", {"multiplier": 1.0, "is_coyote_jump": true})
		return

	# Doble Salto en el Aire
	if character.air_jumps_left > 0 and character.is_jump_just_pressed():
		character.air_jumps_left -= 1
		character.is_fast_falling = false
		state_machine.transition_to("Jump", {"multiplier": 0.94, "is_double_jump": true})
		return

	# Esquive Aéreo (Air Dodge)
	if character.is_shield_just_pressed() and character.can_air_dodge:
		state_machine.transition_to("AirDodge")
		return

	# Ataque Aéreo
	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
