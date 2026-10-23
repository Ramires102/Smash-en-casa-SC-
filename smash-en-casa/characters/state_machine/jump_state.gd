class_name JumpState
extends State

func enter(msg: Dictionary = {}) -> void:
	var is_short_hop: bool = msg.get("short_hop", false)
	var is_double_jump: bool = msg.get("is_double_jump", false)
	var mult: float = msg.get("multiplier", 1.0)

	if character and character.controller:
		var base_vy: float = character.controller.get_short_hop_velocity() if is_short_hop else character.controller.get_jump_velocity()
		character.velocity.y = -base_vy * mult

		var input_vec: Vector2 = character.get_input_vector()
		if is_double_jump:
			# En Smash, el doble salto redirige instantáneamente la velocidad horizontal hacia donde apunta el stick
			if absf(input_vec.x) > 0.15:
				character.velocity.x = input_vec.x * character.controller.get_air_speed()
			else:
				character.velocity.x *= 0.35
		elif msg.has("initial_vx"):
			var init_vx: float = float(msg["initial_vx"])
			# Si salta desde quieto pero inclina el stick, darle impulso horizontal inicial de despegue
			if absf(init_vx) < 30.0 and absf(input_vec.x) > 0.15:
				character.velocity.x = input_vec.x * (character.controller.get_air_speed() * 0.75)
			else:
				character.velocity.x = init_vx

	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Jump")

	# Si el jugador hizo Short-Hop Aerial (Salto + Ataque durante JumpSquat), ejecutar el aéreo en el frame 1
	if msg.get("instant_aerial", false) and character and character.is_attack_just_pressed():
		state_machine.transition_to("Attack")

func physics_update(delta: float) -> void:
	if character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()

	if character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta)

	# Permitir activar Fast-Fall apenas estemos cerca del ápice del salto (vy >= Constants.FASTFALL_MIN_VY)
	if character.velocity.y >= Constants.FASTFALL_MIN_VY and character.consume_fastfall_intent() and not character.is_fast_falling:
		character.is_fast_falling = true
		character.velocity.y = character.controller.get_fast_fall_speed() if character.controller else 550.0
		state_machine.transition_to("Fall")
		return

	# Doble Salto
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
		return

	# Aterrizaje si tocó plataforma subiendo/en el ápice
	if character.is_on_floor() and character.velocity.y >= 0.0:
		state_machine.transition_to("Idle", {"landing_lag": Constants.NORMAL_LANDING_LAG_FRAMES})
		return

	# Al alcanzar el ápice del salto pasa a Fall
	if character.velocity.y >= 0.0:
		state_machine.transition_to("Fall")
