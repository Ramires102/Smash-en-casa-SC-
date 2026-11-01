# ==============================================================================
# HitState — Recepción de Daño: Hitlag (Freeze Frames) y Hitstun (Vuelo)
# ==============================================================================
# Se divide en dos etapas consecutivas:
#   1. Hitlag: congela al defensor vibrando en el sitio para dar peso al golpe.
#   2. Hitstun: aplica el vector de Knockback e impide actuar durante N frames,
#      permitiendo una ligera influencia direccional (DI) con el stick.
# ==============================================================================
class_name HitState
extends State

var _pending_knockback: Vector2 = Vector2.ZERO
var _hitlag_remaining: int = 0
var _hitstun_remaining: int = 0
var _knockback_scalar: float = 0.0
var _is_sliding_knockdown: bool = false

func enter(msg: Dictionary = {}) -> void:
	var knockback_vector: Vector2 = msg.get("knockback", Vector2.ZERO)
	var hitstun_frames: int = int(msg.get("hitstun_frames", 20))
	var hitlag_frames: int = int(msg.get("hitlag_frames", 5))

	_pending_knockback = knockback_vector
	_knockback_scalar = float(msg.get("knockback_scalar", knockback_vector.length() / Constants.UNIT_SIZE))
	_hitlag_remaining = hitlag_frames
	_hitstun_remaining = maxi(1, hitstun_frames)
	_is_sliding_knockdown = bool(msg.get("sliding_knockdown", false))

	if character:
		character.velocity = _pending_knockback if _hitlag_remaining <= 0 else Vector2.ZERO
		if character.anim_controller:
			character.anim_controller.is_sliding_knockdown = _is_sliding_knockdown
			character.anim_controller.play_animation("Hit", 1.0, 0.02)

	var shake_amt: float = clampf(_knockback_scalar * 0.25, 2.0, 10.0)
	Events.camera_shake_requested.emit(shake_amt)

func exit() -> void:
	_hitlag_remaining = 0
	_hitstun_remaining = 0
	_is_sliding_knockdown = false
	if character and character.anim_controller:
		character.anim_controller.is_sliding_knockdown = false
	_restore_visual_offset()

func physics_update(delta: float) -> void:
	if character == null:
		return

	# Fase 1: Hitlag (congelamiento + vibración visual)
	if _hitlag_remaining > 0:
		_hitlag_remaining -= 1
		character.velocity = Vector2.ZERO
		_apply_hitlag_shake()
		if _hitlag_remaining == 0:
			_restore_visual_offset()
			character.velocity = _pending_knockback
		return

	# Fase 2: Hitstun (vuelo por knockback o deslizamiento contra la lona)
	if _is_sliding_knockdown and character.is_on_floor():
		character.velocity.x = CharacterController.damp(character.velocity.x, 0.0, 7.5, delta)
		character.velocity.y = 0.0
	else:
		var move_x: float = character.get_input_vector().x
		if absf(move_x) > 0.1:
			character.velocity.x += move_x * (3.5 * Constants.UNIT_SIZE) * delta
		character.velocity.x = CharacterController.damp(character.velocity.x, 0.0, 1.8, delta)

	_hitstun_remaining -= 1
	if _hitstun_remaining <= 0:
		_is_sliding_knockdown = false
		if character.anim_controller:
			character.anim_controller.is_sliding_knockdown = false
		state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")

func _apply_hitlag_shake() -> void:
	if character and character.visual_controller:
		var amp: float = clampf(_knockback_scalar * 0.002, 0.025, 0.075)
		var sign_dir: float = 1.0 if (_hitlag_remaining % 2 == 0) else -1.0
		character.visual_controller.hitlag_shake_offset = Vector3(sign_dir * amp, randf_range(-amp * 0.5, amp * 0.5), 0.0)

func _restore_visual_offset() -> void:
	if character and character.visual_controller:
		character.visual_controller.hitlag_shake_offset = Vector3.ZERO
