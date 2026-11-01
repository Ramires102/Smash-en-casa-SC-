# ==============================================================================
# LedgeState — Agarre en el Borde de Plataforma (Ledge Hang)
# ==============================================================================
# Suspende al luchador en un LedgePoint con invulnerabilidad inicial de 0.75s y
# habilita las 5 opciones clásicas de borde: Soltarse (Drop), Saltar, Subir
# normal, Subir atacando o Subir rodando (o caer tras 2.5s colgado).
# ==============================================================================
class_name LedgeState
extends State

const MAX_HANG_TIME: float = 2.5
const MIN_HANG_TIME: float = 0.12
const INVINCIBILITY_DURATION: float = 0.75

var current_ledge: LedgePoint = null
var hang_time: float = 0.0
var _invincible_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	current_ledge = msg.get("ledge", null)
	hang_time = 0.0
	_invincible_timer = INVINCIBILITY_DURATION

	if character:
		character.velocity = Vector2.ZERO
		character.is_fast_falling = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)

		if current_ledge:
			current_ledge.occupy(character)
			character.global_position = current_ledge.get_hang_position_2d()
			character.set_facing_direction(current_ledge.ledge_direction)

		character.play_anim("Ledge")

func physics_update(delta: float) -> void:
	hang_time += delta

	if character and current_ledge:
		character.velocity = Vector2.ZERO
		character.global_position = current_ledge.get_hang_position_2d()

	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0 and character:
			character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	if hang_time < MIN_HANG_TIME or character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()
	var facing: float = character.get_facing_direction()

	# 1. Soltarse del borde (Abajo o Atrás)
	if input_vec.y < -0.4 or input_vec.y > 0.4 or (input_vec.x * facing < -0.4):
		character.release_ledge(0.5)
		character.velocity = Vector2(-facing * 50.0, 100.0)
		state_machine.transition_to("Fall")
		return

	# 2. Salto desde el borde
	if character.is_jump_just_pressed():
		character.release_ledge(0.5)
		var j_vel: float = character.controller.get_jump_velocity() if character.controller else 450.0
		character.velocity = Vector2(facing * 80.0, -j_vel * 0.95)
		state_machine.transition_to("Jump")
		return

	# 3. Subida normal hacia el escenario
	if input_vec.x * facing > 0.4:
		state_machine.transition_to("LedgeGetup", {"type": "normal", "ledge": current_ledge})
		return

	# 4. Ataque desde el borde
	if character.is_attack_just_pressed():
		state_machine.transition_to("LedgeGetup", {"type": "attack", "ledge": current_ledge})
		return

	# 5. Rodada hacia adentro desde el borde
	if character.is_shield_pressed():
		state_machine.transition_to("LedgeGetup", {"type": "roll", "ledge": current_ledge})
		return

	# 6. Caída automática al superar el tiempo máximo colgado
	if hang_time >= MAX_HANG_TIME:
		character.release_ledge(0.6)
		character.velocity = Vector2(0.0, 100.0)
		state_machine.transition_to("Fall")

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	if current_ledge and character and current_ledge.occupant == character:
		current_ledge.release(character)
	current_ledge = null
