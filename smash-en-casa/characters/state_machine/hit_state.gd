class_name HitState
extends State

var _pending_knockback: Vector3 = Vector3.ZERO
var _hitlag_remaining: int = 0
var _hitstun_remaining: int = 0
var _visual_shake_offset: Vector3 = Vector3.ZERO

func enter(msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Hit")

	var knockback_vector: Vector3 = msg.get("knockback", Vector3.ZERO)
	var hitstun_frames: int = msg.get("hitstun_frames", 20)
	var hitlag_frames: int = msg.get("hitlag_frames", 6)

	_pending_knockback = knockback_vector
	_hitlag_remaining = hitlag_frames
	_hitstun_remaining = hitstun_frames

	# Durante hitlag, el personaje se congela en el espacio
	if character:
		character.velocity = Vector3.ZERO

	dbg("enter", {
		"knockback": {
			"x": snapped(knockback_vector.x, 0.001),
			"y": snapped(knockback_vector.y, 0.001),
			"length": snapped(knockback_vector.length(), 0.001)
		},
		"hitlag_frames": hitlag_frames,
		"hitstun_frames": hitstun_frames
	})

func exit() -> void:
	_hitlag_remaining = 0
	_hitstun_remaining = 0
	_restore_visual_offset()
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	# ── Fase 1: Hitlag (Freeze frames con micro-vibración de impacto) ──
	if _hitlag_remaining > 0:
		_hitlag_remaining -= 1
		if character:
			character.velocity = Vector3.ZERO
		_apply_hitlag_shake()
		
		if _hitlag_remaining == 0:
			_restore_visual_offset()
			# Hitlag terminó, aplicar vector de lanzamiento real
			if character:
				character.velocity = _pending_knockback
			dbg("hitlag_end", {
				"launch_speed": snapped(_pending_knockback.length(), 0.01)
			})
		return

	# ── Fase 2: Hitstun con Knockback Decay auténtico (Smash: 0.051/frame) ──
	_hitstun_remaining -= 1
	
	if character and character.controller:
		# Decaer la velocidad de lanzamiento a lo largo del vector de inercia
		var decay_rate: float = character.controller.get_knockback_decay_rate()
		var current_speed: float = character.velocity.length()
		if current_speed > 0.001:
			var new_speed: float = maxf(0.0, current_speed - (decay_rate * delta))
			character.velocity = character.velocity.normalized() * new_speed

	dbg_tick(delta, {
		"hitstun_remaining": _hitstun_remaining,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

	# ── Fin del Hitstun -> Recuperación de control ──
	if _hitstun_remaining <= 0:
		if character and character.is_on_floor():
			var input_vec: Vector2 = character.get_input_vector()
			if abs(input_vec.x) > 0.1:
				dbg("to_run", {"reason": "hitstun_finished_ground_input"})
				state_machine.transition_to("Run")
			else:
				dbg("to_idle", {"reason": "hitstun_finished_ground"})
				state_machine.transition_to("Idle")
		else:
			# En el aire pasa fluidamente a Fall preservando la inercia residual
			dbg("to_fall", {"reason": "hitstun_finished_air"})
			state_machine.transition_to("Fall")

func _apply_hitlag_shake() -> void:
	if character and character.has_node("Humanoid"):
		var humanoid: Node3D = character.get_node("Humanoid")
		var shake_x: float = randf_range(-0.06, 0.06)
		var shake_y: float = randf_range(-0.06, 0.06)
		humanoid.position = Vector3(shake_x, shake_y, 0.0)

func _restore_visual_offset() -> void:
	if character and character.has_node("Humanoid"):
		var humanoid: Node3D = character.get_node("Humanoid")
		humanoid.position = Vector3.ZERO
