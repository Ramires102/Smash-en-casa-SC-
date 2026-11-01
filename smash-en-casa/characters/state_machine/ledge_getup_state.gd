# ==============================================================================
# LedgeGetupState — Subida al Escenario desde el Borde (Normal, Roll o Attack)
# ==============================================================================
# Interpola con curva Smoothstep al personaje desde el punto de agarre hasta la
# superficie segura de la plataforma manteniendo invulnerabilidad temporal.
# ==============================================================================
class_name LedgeGetupState
extends State

var getup_type: String = "normal"
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var progress_time: float = 0.0
var total_duration: float = 0.32

func enter(msg: Dictionary = {}) -> void:
	getup_type = String(msg.get("type", "normal"))
	var ledge: LedgePoint = msg.get("ledge", null)
	progress_time = 0.0

	if character == null:
		return

	start_pos = character.global_position
	character.velocity = Vector2.ZERO
	character.is_fast_falling = false
	character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)

	if ledge:
		if getup_type == "roll":
			target_pos = ledge.get_roll_position_2d()
			total_duration = 0.45
		else:
			target_pos = ledge.get_stand_position_2d()
			total_duration = 0.30 if getup_type == "normal" else 0.38
	else:
		var facing: float = character.get_facing_direction()
		target_pos = start_pos + Vector2(facing * 30.0, -35.0)
		total_duration = 0.30

	if getup_type == "roll":
		character.play_anim("Roll")
	elif getup_type == "attack":
		character.play_anim("Attack")
	else:
		character.play_anim("LedgeGetup")

func physics_update(delta: float) -> void:
	progress_time += delta
	var t: float = clampf(progress_time / total_duration, 0.0, 1.0)
	var ease_t: float = t * t * (3.0 - 2.0 * t)

	if character:
		character.global_position = start_pos.lerp(target_pos, ease_t)
		character.velocity = Vector2.ZERO

	if progress_time >= total_duration:
		_finish_getup()

func _finish_getup() -> void:
	if character == null:
		return
	character.global_position = target_pos
	character.velocity = Vector2.ZERO
	character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	character.release_ledge(0.6)

	if getup_type == "attack":
		var atk: AttackData = character.get_current_attack()
		if atk:
			state_machine.transition_to("Attack", {"attack_data": atk})
			return

	var input_vec: Vector2 = character.get_input_vector()
	state_machine.transition_to("Run" if absf(input_vec.x) > 0.1 else "Idle")

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
