class_name JumpSquatState
extends State

var squat_timer: float = 0.0
const SQUAT_DURATION: float = 3.0 / 60.0 # Exactamente 3 frames
var is_short_hop: bool = true

func enter(_msg: Dictionary = {}) -> void:
	squat_timer = SQUAT_DURATION
	is_short_hop = true
	dbg("enter", {"squat_timer": snapped(squat_timer, 0.001)})
	if character:
		character.velocity.x = 0.0
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("JumpSquat")

func exit() -> void:
	dbg("exit", {"short_hop": is_short_hop})

func physics_update(delta: float) -> void:
	squat_timer -= delta
	dbg_tick(delta, {
		"squat_timer": snapped(squat_timer, 0.001),
		"jump_held": character.is_jump_held() if character else false
	})

	# Si se mantiene presionado Jump durante las 3 frames -> Full Hop
	if character and character.is_jump_held():
		is_short_hop = false

	if squat_timer <= 0.0:
		var jump_mult: float = 0.75 if is_short_hop else 1.0
		dbg("to_jump", {"reason": "jumpsquat_finished", "jump_mult": jump_mult})
		state_machine.transition_to("Jump", {"multiplier": jump_mult})
