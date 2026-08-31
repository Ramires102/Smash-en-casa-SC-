class_name HitState
extends State

## Estado de Hitstun 2D puro porteado 1:1 desde Splash N Dash (CharacterSM.gd:848-879).
## Implementa: hitlag freeze, wall/floor bounce 2D, per-component decay, y transición a Tumble.

var _pending_knockback: Vector2 = Vector2.ZERO
var _hitlag_remaining: int = 0
var _hitstun_remaining: int = 0
var _knockback_scalar: float = 0.0  ## KB escalar de SND para bounce/tumble thresholds
var _captured_hitlag_di: Vector2 = Vector2.ZERO

# ── Per-component decay de SND (Hitboxes.gd:108-118, CharacterSM.gd:862-870) ──
var _hdecay: float = 0.0
var _vdecay: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Hit")

	var knockback_vector: Vector2 = msg.get("knockback", Vector2.ZERO)
	var hitstun_frames: int = msg.get("hitstun_frames", 20)
	var hitlag_frames: int = msg.get("hitlag_frames", 6)

	_pending_knockback = knockback_vector
	_knockback_scalar = msg.get("knockback_scalar", knockback_vector.length())
	_hitlag_remaining = hitlag_frames
	_hitstun_remaining = hitstun_frames
	_captured_hitlag_di = Vector2.ZERO
	
	_hdecay = msg.get("hdecay", 0.0)
	_vdecay = msg.get("vdecay", 0.0)

	if character:
		character.velocity = Vector2.ZERO

	dbg("enter", {
		"knockback": {
			"x": snapped(knockback_vector.x, 0.001),
			"y": snapped(knockback_vector.y, 0.001),
			"length": snapped(knockback_vector.length(), 0.001)
		},
		"kb_scalar": snapped(_knockback_scalar, 0.001),
		"hitlag_frames": hitlag_frames,
		"hitstun_frames": hitstun_frames,
		"hdecay": snapped(_hdecay, 0.001),
		"vdecay": snapped(_vdecay, 0.001)
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
	# ── Fase 1: Hitlag (Freeze frames con micro-vibración) ──
	if _hitlag_remaining > 0:
		_hitlag_remaining -= 1
		if character:
			_captured_hitlag_di = character.get_input_vector()
		if character:
			character.velocity = Vector2.ZERO
		_apply_hitlag_shake()
		
		if _hitlag_remaining == 0:
			_restore_visual_offset()
			var di_result: Dictionary = KnockbackCalculator.apply_hitlag_di(_pending_knockback, _captured_hitlag_di)
			_pending_knockback = di_result.get("vector", _pending_knockback)
			_hdecay = float(di_result.get("hdecay", _hdecay))
			_vdecay = float(di_result.get("vdecay", _vdecay))
			if character:
				character.velocity = _pending_knockback
			# Transición directa a Tumble si KB >= 24 (CharacterSM.gd:874-876)
			if _knockback_scalar >= Constants.TUMBLE_KB_THRESHOLD:
				dbg("to_tumble", {
					"kb_scalar": snapped(_knockback_scalar, 0.01),
					"hitstun": _hitstun_remaining,
					"di_x": snapped(_captured_hitlag_di.x, 0.001),
					"di_y": snapped(_captured_hitlag_di.y, 0.001)
				})
				state_machine.transition_to("Tumble", {
					"initial_velocity": _pending_knockback,
					"hitstun_frames": _hitstun_remaining,
					"knockback_scalar": _knockback_scalar,
					"hdecay": _hdecay,
					"vdecay": _vdecay
				})
				return
			dbg("hitlag_end", {
				"launch_speed": snapped(_pending_knockback.length(), 0.01),
				"di_x": snapped(_captured_hitlag_di.x, 0.001),
				"di_y": snapped(_captured_hitlag_di.y, 0.001)
			})
		return

	# ── Fase 2: Hitstun con per-component decay (CharacterSM.gd:862-870) ──
	_hitstun_remaining -= 1
	
	if character:
		# ── Wall/Floor Bounce 2D (CharacterSM.gd:850-853) ──
		if _knockback_scalar >= Constants.BOUNCE_KB_THRESHOLD:
			var collision: KinematicCollision2D = character.move_and_collide(character.velocity * delta)
			if collision:
				var normal: Vector2 = collision.get_normal()
				character.velocity = character.velocity.bounce(normal) * Constants.BOUNCE_ELASTICITY
		
		# ── Decay vertical por frame (CharacterSM.gd:862-864) ──
		# En 2D Y negativo es UP: si velocity.y < 0 desacelera hacia abajo (hacia 0)
		if character.velocity.y < 0.0:
			character.velocity.y += _vdecay * Constants.KB_DECAY_V_FACTOR
			character.velocity.y = clampf(character.velocity.y, character.velocity.y, 0.0)
		
		# ── Decay horizontal por frame (CharacterSM.gd:865-870) ──
		if character.velocity.x < 0.0:
			character.velocity.x += (_hdecay) * Constants.KB_DECAY_H_FACTOR * -1.0
			character.velocity.x = clampf(character.velocity.x, character.velocity.x, 0.0)
		elif character.velocity.x > 0.0:
			character.velocity.x -= _hdecay * Constants.KB_DECAY_H_FACTOR
			character.velocity.x = clampf(character.velocity.x, 0.0, character.velocity.x)

	dbg_tick(delta, {
		"hitstun_remaining": _hitstun_remaining,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"speed": snapped(character.velocity.length() if character else 0.0, 0.01)
	})

	# ── Fin del Hitstun → Transición exacta de SND (CharacterSM.gd:872-879) ──
	if _hitstun_remaining <= 0:
		if _knockback_scalar >= Constants.TUMBLE_KB_THRESHOLD:
			dbg("to_tumble_end", {"reason": "hitstun_expired_high_kb"})
			state_machine.transition_to("Tumble", {
				"initial_velocity": character.velocity if character else Vector2.ZERO,
				"hitstun_frames": 0,
				"knockback_scalar": _knockback_scalar
			})
		else:
			if character and character.is_on_floor():
				var input_vec: Vector2 = character.get_input_vector()
				if abs(input_vec.x) > 0.1:
					dbg("to_run", {"reason": "hitstun_finished_ground_input"})
					state_machine.transition_to("Run")
				else:
					dbg("to_idle", {"reason": "hitstun_finished_ground"})
					state_machine.transition_to("Idle")
			else:
				dbg("to_fall", {"reason": "hitstun_finished_air"})
				state_machine.transition_to("Fall")

func _apply_hitlag_shake() -> void:
	if character and character.visual_root_3d:
		var shake_x: float = randf_range(-0.06, 0.06)
		var shake_y: float = randf_range(-0.06, 0.06)
		character.visual_root_3d.position = Vector3(shake_x, shake_y, 0.0)

func _restore_visual_offset() -> void:
	if character and character.visual_root_3d:
		character.visual_root_3d.position = Vector3.ZERO
