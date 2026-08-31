class_name LedgeState
extends State

## Estado de agarre en borde de plataforma 2D (Ledge Hang).
## El personaje queda suspendido en el borde con invulnerabilidad temporal y opciones de recuperación.

var current_ledge: LedgePoint = null
var hang_time: float = 0.0
var max_hang_time: float = 2.5
var min_hang_time: float = 0.12
var invincibility_duration: float = 0.75
var _invincible_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	current_ledge = msg.get("ledge", null)
	hang_time = 0.0
	_invincible_timer = invincibility_duration

	if character:
		character.velocity = Vector2.ZERO
		character.is_fast_falling = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)
		
		if current_ledge:
			current_ledge.occupy(character)
			character.global_position = current_ledge.get_hang_position_2d()
			character.set_facing_direction(current_ledge.ledge_direction)

		if character.has_node("AnimationController"):
			character.get_node("AnimationController").play_animation("Ledge")

	dbg("enter", {
		"ledge": current_ledge.name if current_ledge else "None",
		"direction": current_ledge.ledge_direction if current_ledge else 1.0
	})

func physics_update(delta: float) -> void:
	hang_time += delta

	if character and current_ledge:
		character.velocity = Vector2.ZERO
		character.global_position = current_ledge.get_hang_position_2d()

	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0 and character:
			character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	dbg_tick(delta, {
		"hang_time": snapped(hang_time, 0.01),
		"invincible": _invincible_timer > 0.0
	})

	if hang_time < min_hang_time:
		return

	if character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()
	var facing: float = character.get_facing_direction()

	# 1. Soltarse hacia abajo o atrás (Drop)
	if input_vec.y < -0.4 or input_vec.y > 0.4 or (input_vec.x * facing < -0.4):
		dbg("ledge_action", {"action": "drop"})
		character.release_ledge(0.5)
		character.velocity = Vector2(-facing * 50.0, 100.0)
		state_machine.transition_to("Fall")
		return

	# 2. Salto desde el borde (Ledge Jump)
	if character.is_jump_just_pressed():
		dbg("ledge_action", {"action": "jump"})
		character.release_ledge(0.5)
		character.velocity = Vector2(facing * 80.0, -character.jump_velocity * 0.95)
		state_machine.transition_to("Jump")
		return

	# 3. Subir normalmente (Normal Getup)
	if input_vec.x * facing > 0.4:
		dbg("ledge_action", {"action": "normal_getup"})
		state_machine.transition_to("LedgeGetup", {"type": "normal", "ledge": current_ledge})
		return

	# 4. Ataque desde el borde (Ledge Attack)
	if character.is_attack_just_pressed():
		dbg("ledge_action", {"action": "attack_getup"})
		state_machine.transition_to("LedgeGetup", {"type": "attack", "ledge": current_ledge})
		return

	# 5. Rodar al subir (Ledge Roll)
	if character.is_shield_pressed():
		dbg("ledge_action", {"action": "roll_getup"})
		state_machine.transition_to("LedgeGetup", {"type": "roll", "ledge": current_ledge})
		return

	# 6. Auto-drop por límite de tiempo
	if hang_time >= max_hang_time:
		character.release_ledge(0.6)
		character.velocity = Vector2(0.0, 100.0)
		state_machine.transition_to("Fall")

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	if current_ledge and character and current_ledge.occupant == character:
		current_ledge.release(character)
	current_ledge = null
