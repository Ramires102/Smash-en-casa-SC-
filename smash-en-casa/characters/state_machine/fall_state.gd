# ==============================================================================
# FallState — Estado de Descenso Aéreo y Caída Rápida (Fast-Fall)
# ==============================================================================
# Gestiona la deriva horizontal en caída, el salto Coyote justo tras salir de un
# borde, el doble salto, el esquive aéreo y la aceleración voluntaria hacia abajo
# (`Fast-Fall`) al inclinar el stick inferiormente.
# ==============================================================================
class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.play_anim("Fall")

func physics_update(delta: float) -> void:
	if character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()

	if character.is_on_floor():
		character.is_fast_falling = false
		state_machine.transition_to("Run" if absf(input_vec.x) > 0.15 else "Idle")
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

	# Fast-fall progresivo al empujar el stick hacia abajo durante el descenso
	if input_vec.y < -0.5 and character.velocity.y > 0.0:
		character.is_fast_falling = true
		var max_fast_fall: float = character.controller.get_fast_fall_speed() if character.controller else (22.0 * 1.25 * Constants.UNIT_SIZE)
		character.velocity.y = minf(max_fast_fall, character.velocity.y + (18.0 * Constants.UNIT_SIZE) * delta)

	if character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta, 7.5)
