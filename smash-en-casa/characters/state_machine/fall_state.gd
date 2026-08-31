class_name FallState
extends State

## Estado de Caída Libre 2D.
## Soporta: Fast Fall, Double Jump, Coyote Jump, Air Dodge, Ataques Aéreos.

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func exit() -> void:
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	
	# Control de Air Drift auténtico (aceleración y fricción aérea 2D)
	if character and character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta)
		if absf(input_vec.x) > 0.1:
			character.update_facing_direction(input_vec.x)
			
		# Detección de Fast Fall auténtico 2D (solo down just-pressed y en descenso)
		if character.is_down_just_pressed() and character.velocity.y > 0.0 and not character.is_fast_falling:
			character.is_fast_falling = true
			character.velocity.y = character.controller.get_fast_fall_speed()
			dbg("fast_fall_activated", {"vy": snapped(character.velocity.y, 0.001)})
		elif character.is_fast_falling:
			character.velocity.y = character.controller.get_fast_fall_speed()

	dbg_tick(delta, {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"fast_fall": character.is_fast_falling if character else false,
		"input_x": snapped(input_vec.x, 0.001)
	})

	# Aterrizaje en el suelo
	if character and character.is_on_floor():
		character.is_fast_falling = false
		dbg("to_idle", {
			"reason": "landed_with_lag",
			"lag_frames": Constants.NORMAL_LANDING_LAG_FRAMES,
			"input_x": snapped(input_vec.x, 0.001)
		})
		state_machine.transition_to("Idle", {"landing_lag": Constants.NORMAL_LANDING_LAG_FRAMES})
		return

	# Coyote Jump
	if character and character.has_coyote_jump() and character.is_jump_just_pressed():
		character.consume_coyote_jump()
		character.is_fast_falling = false
		dbg("to_coyote_jump", {"coyote_time": true})
		state_machine.transition_to("Jump", {"multiplier": 1.0, "is_coyote_jump": true})
		return

	# Doble Salto en el Aire
	if character and character.air_jumps_left > 0 and character.is_jump_just_pressed():
		character.air_jumps_left -= 1
		character.is_fast_falling = false
		dbg("to_double_jump", {"jumps_left": character.air_jumps_left})
		state_machine.transition_to("Jump", {"multiplier": 0.95, "is_double_jump": true})
		return

	# Esquive Aéreo (Air Dodge)
	if character and character.is_shield_pressed() and character.can_air_dodge:
		dbg("to_airdodge")
		state_machine.transition_to("AirDodge")
		return

	# Ataque Aéreo
	if character and character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed_air"})
		state_machine.transition_to("Attack")
		return
