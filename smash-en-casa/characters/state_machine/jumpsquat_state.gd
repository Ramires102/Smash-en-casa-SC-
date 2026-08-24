class_name JumpSquatState
extends State

var squat_timer: float = 0.0
const SQUAT_DURATION: float = 3.0 / 60.0 # Exactamente 3 frames en Smash Ultimate
var is_short_hop: bool = true

func enter(_msg: Dictionary = {}) -> void:
	squat_timer = SQUAT_DURATION
	is_short_hop = true
	dbg("enter", {
		"squat_timer": snapped(squat_timer, 0.001),
		"vx_entering": snapped(character.velocity.x if character else 0.0, 0.001)
	})
	
	# En Smash, la inercia terrestre no se anula instantáneamente a 0; desacelera suavemente con tracción.
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("JumpSquat")

func exit() -> void:
	dbg("exit", {"short_hop": is_short_hop})

func physics_update(delta: float) -> void:
	squat_timer -= delta
	
	# Desacelerar con tracción durante los 3 frames de jumpsquat
	if character and character.controller:
		var trac: float = character.controller.get_traction()
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
	
	dbg_tick(delta, {
		"squat_timer": snapped(squat_timer, 0.001),
		"jump_held": character.is_jump_held() if character else false,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001)
	})

	# Si se mantiene presionado Jump durante las 3 frames -> Full Hop; si se suelta -> Short Hop
	if character and character.is_jump_held():
		is_short_hop = false

	if squat_timer <= 0.0:
		var jump_mult: float = 0.75 if is_short_hop else 1.0
		var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
		dbg("to_jump", {
			"reason": "jumpsquat_finished",
			"jump_mult": jump_mult,
			"inherited_vx": snapped(character.velocity.x if character else 0.0, 0.001)
		})
		state_machine.transition_to("Jump", {
			"multiplier": jump_mult,
			"initial_vx": character.velocity.x if character else 0.0,
			"input_x": input_vec.x
		})
