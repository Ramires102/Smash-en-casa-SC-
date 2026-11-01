# ==============================================================================
# ShieldState — Guardia Activa y Opciones Out-of-Shield (Roll, Spotdodge, Jump)
# ==============================================================================
# Muestra la burbuja de escudo, drena su salud gradualmente y permite salir de
# guardia mediante Salto (`JumpSquat`), Rodada (`Roll`) o Esquive (`Spotdodge`).
# Soltar el botón impone 11 frames de bajada de escudo (`shield_drop_timer`).
# ==============================================================================
class_name ShieldState
extends State

const SHIELD_DROP_DURATION_SEC: float = 11.0 / 60.0

var shieldstun_timer: float = 0.0
var shield_drop_timer: float = 0.0
var is_dropping_shield: bool = false

func enter(_msg: Dictionary = {}) -> void:
	shieldstun_timer = 0.0
	shield_drop_timer = 0.0
	is_dropping_shield = false
	if character:
		if character.shield_controller:
			character.shield_controller.set_shield_visible(true)
		character.play_anim("Shield")

func exit() -> void:
	if character and character.shield_controller:
		character.shield_controller.set_shield_visible(false)

func apply_shieldstun(duration: float) -> void:
	shieldstun_timer = duration

func physics_update(delta: float) -> void:
	if character == null:
		return

	var trac: float = character.controller.get_traction() if character.controller else 30.0
	character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if shieldstun_timer > 0.0:
		shieldstun_timer -= delta
		return

	if character.shield_controller:
		character.shield_controller.drain(delta)
	if character.shield_health <= 0.0:
		return

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if absf(input_vec.x) > 0.5:
		state_machine.transition_to("Roll", {"dir": signf(input_vec.x)})
		return

	if input_vec.y < -0.5:
		state_machine.transition_to("Spotdodge")
		return

	if not character.is_shield_pressed():
		if not is_dropping_shield:
			is_dropping_shield = true
			shield_drop_timer = SHIELD_DROP_DURATION_SEC

		shield_drop_timer -= delta
		if shield_drop_timer <= 0.0:
			state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
