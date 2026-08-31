class_name LedgeGetupState
extends State

## Estado de subida/recuperación desde el borde (Ledge Getup) en 2D.
## Interpola suavemente al personaje a la superficie del escenario con invulnerabilidad temporal.

var getup_type: String = "normal"  # "normal", "roll", "attack"
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var progress_time: float = 0.0
var total_duration: float = 0.32
var is_invulnerable: bool = true

func enter(msg: Dictionary = {}) -> void:
	getup_type = msg.get("type", "normal")
	var ledge: LedgePoint = msg.get("ledge", null)

	if character:
		start_pos = character.global_position
		character.velocity = Vector2.ZERO
		character.is_fast_falling = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)
		is_invulnerable = true

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

		if character.has_node("AnimationController"):
			var anim_ctrl: Node = character.get_node("AnimationController")
			if getup_type == "roll":
				anim_ctrl.play_animation("Roll")
			elif getup_type == "attack":
				anim_ctrl.play_animation("Attack")
			else:
				anim_ctrl.play_animation("LedgeGetup")

	progress_time = 0.0
	dbg("enter", {
		"type": getup_type,
		"duration": total_duration,
		"target_x": snapped(target_pos.x, 0.01),
		"target_y": snapped(target_pos.y, 0.01)
	})

func physics_update(delta: float) -> void:
	progress_time += delta
	var t: float = clampf(progress_time / total_duration, 0.0, 1.0)
	var ease_t: float = t * t * (3.0 - 2.0 * t)

	if character:
		character.global_position = start_pos.lerp(target_pos, ease_t)
		character.velocity = Vector2.ZERO

	dbg_tick(delta, {
		"progress": snapped(t, 0.01),
		"invulnerable": is_invulnerable
	})

	if progress_time >= total_duration:
		_finish_getup()

func _finish_getup() -> void:
	if character:
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
		if absf(input_vec.x) > 0.1:
			dbg("to_run", {"reason": "getup_finished_with_input"})
			state_machine.transition_to("Run")
		else:
			dbg("to_idle", {"reason": "getup_finished_neutral"})
			state_machine.transition_to("Idle")

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	dbg("exit", {"type": getup_type})
