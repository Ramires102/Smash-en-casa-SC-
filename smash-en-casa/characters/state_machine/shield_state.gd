class_name ShieldState
extends State

var shieldstun_timer: float = 0.0
var shield_drop_timer: float = 0.0
var is_dropping_shield: bool = false

func enter(_msg: Dictionary = {}) -> void:
	shieldstun_timer = 0.0
	shield_drop_timer = 0.0
	is_dropping_shield = false
	dbg("enter", {"shield_hp": snapped(character.shield_health, 0.001) if character else -1.0})
	if character and character.has_node("Humanoid/ShieldMesh"):
		character.get_node("Humanoid/ShieldMesh").visible = true
		character.update_shield_scale()
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Shield")

func exit() -> void:
	dbg("exit", {"shield_hp": snapped(character.shield_health, 0.001) if character else -1.0})
	if character and character.has_node("Humanoid/ShieldMesh"):
		character.get_node("Humanoid/ShieldMesh").visible = false

func apply_shieldstun(duration: float) -> void:
	shieldstun_timer = duration
	dbg("apply_shieldstun", {"duration": snapped(duration, 0.001)})

func physics_update(delta: float) -> void:
	var trac: float = character.controller.get_traction() if character and character.controller else 30.0
	character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
	dbg_tick(delta, {
		"shield_hp": snapped(character.shield_health, 0.001),
		"shieldstun": snapped(shieldstun_timer, 0.001),
		"drop_timer": snapped(shield_drop_timer, 0.001),
		"dropping": is_dropping_shield
	})

	if shieldstun_timer > 0.0:
		shieldstun_timer -= delta
		return

	character.shield_health -= Character.SHIELD_DRAIN_RATE * delta
	character.update_shield_scale()

	if character.shield_health <= 0.0:
		dbg("break_shield", {"reason": "shield_hp_depleted"})
		character.break_shield()
		return

	if character.is_jump_just_pressed():
		dbg("to_jumpsquat", {"reason": "jump_pressed"})
		state_machine.transition_to("JumpSquat")
		return

	var input_vec: Vector2 = character.get_input_vector()

	if abs(input_vec.x) > 0.5:
		var roll_dir: float = sign(input_vec.x)
		dbg("to_roll", {"reason": "shield_roll_input", "roll_dir": roll_dir})
		state_machine.transition_to("Roll", {"dir": roll_dir})
		return

	if input_vec.y < -0.5:
		dbg("to_spotdodge", {"reason": "shield_down_input", "input_y": snapped(input_vec.y, 0.001)})
		state_machine.transition_to("Spotdodge")
		return

	if not character.is_shield_pressed():
		if not is_dropping_shield:
			is_dropping_shield = true
			shield_drop_timer = 11.0 / 60.0
			character.shield_release_timer = 5.0 / 60.0

		shield_drop_timer -= delta
		if shield_drop_timer <= 0.0:
			if character.is_on_floor():
				dbg("to_idle", {"reason": "shield_drop_finished_ground"})
				state_machine.transition_to("Idle")
			else:
				dbg("to_fall", {"reason": "shield_drop_finished_air"})
				state_machine.transition_to("Fall")
