class_name SquatState
extends State

## Estado de Agachado (Crouch / Squat)
## Permite: agacharse en el suelo, frenar suavemente, Down-Tilts / Smashes,
## Spotdodge (con Escudo), y atravesar plataformas flotantes con tap hacia abajo.

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Squat")

func exit() -> void:
	dbg("exit")

func physics_update(delta: float) -> void:
	if not character:
		return
		
	# Frenado suave hacia 0 mientras está agachado
	var trac: float = character.controller.get_traction() if character.controller else 300.0
	character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	dbg_tick(delta, {
		"input_x": snapped(character.get_input_vector().x, 0.001),
		"input_y": snapped(character.get_input_vector().y, 0.001),
		"vx": snapped(character.velocity.x, 0.001)
	})

	# Si ya no está en el suelo (ej: empujado o cae por el borde)
	if not character.is_on_floor():
		dbg("to_fall", {"reason": "left_floor"})
		state_machine.transition_to("Fall")
		return

	# Atravesar plataforma suave solo si presiona DOWN nuevamente estando sobre plataforma flotante
	if character.is_down_just_pressed() and character.global_position.y < -10.0:
		character.global_position.y += 12.0
		character.velocity.y = maxf(character.velocity.y, 60.0)
		dbg("to_fall", {"reason": "platform_drop_from_squat_tap"})
		state_machine.transition_to("Fall")
		return

	# Escudo / Spotdodge desde agachado
	if character.is_shield_pressed():
		var input_y: float = character.get_input_vector().y
		if input_y < -0.5:
			dbg("to_spotdodge", {"reason": "crouch_shield_spotdodge"})
			state_machine.transition_to("Spotdodge")
		else:
			dbg("to_shield", {"reason": "crouch_shield_pressed"})
			state_machine.transition_to("Shield")
		return

	# Ataques desde agachado (Down Tilt / Down Smash / Down Special)
	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "crouch_attack_pressed"})
		state_machine.transition_to("Attack")
		return

	# Salto desde agachado
	if character.is_jump_just_pressed():
		dbg("to_jumpsquat", {"reason": "crouch_jump_pressed"})
		state_machine.transition_to("JumpSquat")
		return

	var input_vec: Vector2 = character.get_input_vector()

	# Reanudar estado de pie cuando se suelta la flechita abajo
	if input_vec.y >= -0.5:
		if absf(input_vec.x) > 0.1:
			if character.is_dash_intent():
				dbg("to_dash", {"reason": "dash_intent_from_squat", "input_x": snapped(input_vec.x, 0.001)})
				state_machine.transition_to("Dash")
			else:
				dbg("to_walk", {"reason": "horizontal_input_from_squat", "input_x": snapped(input_vec.x, 0.001)})
				state_machine.transition_to("Walk")
		else:
			dbg("to_idle", {"reason": "neutral_from_squat"})
			state_machine.transition_to("Idle")
		return
