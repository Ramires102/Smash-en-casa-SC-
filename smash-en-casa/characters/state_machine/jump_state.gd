class_name JumpState
extends State

## Estado de Salto 2D.
## En Godot 2D, el salto es velocidad Y negativa (-), alcanzando el ápice en vy >= 0.

func enter(msg: Dictionary = {}) -> void:
	var mult: float = msg.get("multiplier", 1.0)
	var jump_vel: float = character.controller.get_jump_velocity() if (character and character.controller) else 500.0
	if character:
		character.velocity.y = -jump_vel * mult
		if msg.has("initial_vx"):
			character.velocity.x = msg["initial_vx"]
	
	dbg("enter", {
		"jump_mult": mult,
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"vx": snapped(character.velocity.x if character else 0.0, 0.001)
	})
	
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Jump")

func exit() -> void:
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	
	# Control de Air Drift auténtico con aceleración y fricción aérea 2D
	if character and character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta)
		if absf(input_vec.x) > 0.1:
			character.update_facing_direction(input_vec.x)
	
	dbg_tick(delta, {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"input_x": snapped(input_vec.x, 0.001)
	})

	# Doble Salto
	if character and character.air_jumps_left > 0 and character.is_jump_just_pressed():
		character.air_jumps_left -= 1
		dbg("to_double_jump_from_jump", {"jumps_left": character.air_jumps_left})
		state_machine.transition_to("Jump", {"multiplier": 0.95, "is_double_jump": true})
		return

	# Esquive Aéreo (Air Dodge)
	if character and character.is_shield_pressed() and character.can_air_dodge:
		dbg("to_airdodge_from_jump")
		state_machine.transition_to("AirDodge")
		return

	# Al alcanzar el ápice del salto en 2D (vy >= 0) transiciona a caída
	if character and character.velocity.y >= 0.0:
		dbg("to_fall", {"reason": "apex_reached", "vy": snapped(character.velocity.y, 0.001)})
		state_machine.transition_to("Fall")
		return

	if character and character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed_air"})
		state_machine.transition_to("Attack")
		return
