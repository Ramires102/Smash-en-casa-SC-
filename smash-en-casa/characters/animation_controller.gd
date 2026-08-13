class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer

# Referencia al personaje padre para detectar si tiene modelo real
var _character: Node = null
var _has_real_model: bool = false

func _ready() -> void:
	_character = get_parent()
	if animation_player:
		# Esperar un frame para que load_character() haya instanciado el ModelRoot
		await get_tree().process_frame
		_has_real_model = _character != null and _character.has_node("Humanoid/ModelRoot")
		if _has_real_model:
			_setup_real_model_animations()
		else:
			_setup_placeholder_animations()

func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func stop() -> void:
	if animation_player:
		animation_player.stop()

func _setup_placeholder_animations() -> void:
	var lib: AnimationLibrary
	if animation_player.has_animation_library(""):
		lib = animation_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)

	# Añadir RESET para asegurar que los miembros vuelvan a su lugar al cambiar de estado
	lib.add_animation("RESET", _create_reset_animation())

	# Animaciones ultra exageradas estéticas JoJo / MUGEN meme para John Placeholder
	lib.add_animation("Idle", _create_idle_animation())
	lib.add_animation("Walk", _create_walk_animation())
	lib.add_animation("Run", _create_run_animation())
	lib.add_animation("RunBrake", _create_run_brake_animation())
	lib.add_animation("Pivot", _create_pivot_animation())
	lib.add_animation("Squat", _create_squat_animation())
	lib.add_animation("JumpSquat", _create_jump_squat_animation())
	lib.add_animation("Jump", _create_jump_animation())
	lib.add_animation("Fall", _create_fall_animation())
	lib.add_animation("FastFall", _create_fast_fall_animation())
	lib.add_animation("Attack", _create_attack_animation())
	lib.add_animation("Hit", _create_hit_animation())
	lib.add_animation("Shield", _create_shield_animation())
	lib.add_animation("Roll", _create_roll_animation())
	lib.add_animation("Spotdodge", _create_spotdodge_animation())

# ─────────────────────────────────────────────────────────────
# ANIMACIONES PARA MODELO REAL (ModelRoot = cuerpo completo)
# Animan posición Y y rotación del nodo completo sin necesitar
# los nombres de los huesos del esqueleto
# ─────────────────────────────────────────────────────────────
func _setup_real_model_animations() -> void:
	var lib: AnimationLibrary
	if animation_player.has_animation_library(""):
		lib = animation_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)

	if not lib.has_animation("Idle"):    lib.add_animation("Idle",    _real_idle_anim())
	if not lib.has_animation("Walk"):    lib.add_animation("Walk",    _real_walk_anim())
	if not lib.has_animation("Run"):     lib.add_animation("Run",     _real_run_anim())
	if not lib.has_animation("Jump"):    lib.add_animation("Jump",    _real_jump_anim())
	if not lib.has_animation("Fall"):    lib.add_animation("Fall",    _real_fall_anim())
	if not lib.has_animation("Hit"):     lib.add_animation("Hit",     _real_hit_anim())
	if not lib.has_animation("Attack"):  lib.add_animation("Attack",  _real_attack_anim())
	if not lib.has_animation("Shield"):  lib.add_animation("Shield",  _real_shield_anim())
	if not lib.has_animation("RunBrake"): lib.add_animation("RunBrake", _real_brake_anim())
	if not lib.has_animation("RESET"):   lib.add_animation("RESET",   _real_reset_anim())

# Pose neutra — devuelve el modelo a posición y rotación base
func _real_reset_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.001
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0, Vector3(0.0, -0.9, 0.0))
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0, Vector3(0, 0, 0))
	return a

# Idle — suave rebote vertical (respiración)
func _real_idle_anim() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 1.6
	var base_y: float = -0.9
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.4,  Vector3(0.0, base_y - 0.04, 0.0))
	a.track_insert_key(tp, 0.8,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 1.2,  Vector3(0.0, base_y - 0.02, 0.0))
	a.track_insert_key(tp, 1.6,  Vector3(0.0, base_y,        0.0))
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,  Vector3(0.0,  0.0, 0.0))
	a.track_insert_key(tr, 0.8,  Vector3(0.0,  2.0, 1.0))
	a.track_insert_key(tr, 1.6,  Vector3(0.0,  0.0, 0.0))
	return a

# Walk — balanceo lateral suave
func _real_walk_anim() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 0.7
	var base_y: float = -0.9
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,   Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.175, Vector3(0.0, base_y - 0.03, 0.0))
	a.track_insert_key(tp, 0.35,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.525, Vector3(0.0, base_y - 0.03, 0.0))
	a.track_insert_key(tp, 0.7,   Vector3(0.0, base_y,        0.0))
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,   Vector3(0.0, 0.0,  3.0))
	a.track_insert_key(tr, 0.35,  Vector3(0.0, 0.0, -3.0))
	a.track_insert_key(tr, 0.7,   Vector3(0.0, 0.0,  3.0))
	return a

# Run — inclinación hacia adelante + rebote rápido
func _real_run_anim() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 0.4
	var base_y: float = -0.9
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.1,  Vector3(0.0, base_y - 0.05, 0.0))
	a.track_insert_key(tp, 0.2,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.3,  Vector3(0.0, base_y - 0.05, 0.0))
	a.track_insert_key(tp, 0.4,  Vector3(0.0, base_y,        0.0))
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,  Vector3(-12.0, 0.0, 0.0))
	a.track_insert_key(tr, 0.2,  Vector3(-15.0, 0.0, 0.0))
	a.track_insert_key(tr, 0.4,  Vector3(-12.0, 0.0, 0.0))
	return a

# Jump — salta: estira el cuerpo hacia arriba
func _real_jump_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.3
	var base_y: float = -0.9
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.15, Vector3(0.0, base_y + 0.08, 0.0))
	a.track_insert_key(tp, 0.3,  Vector3(0.0, base_y,        0.0))
	var ts := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ts, "Humanoid/ModelRoot:scale")
	a.track_insert_key(ts, 0.0,  Vector3(1.15, 1.15, 1.15))
	a.track_insert_key(ts, 0.15, Vector3(1.05, 1.25, 1.05))
	a.track_insert_key(ts, 0.3,  Vector3(1.15, 1.15, 1.15))
	return a

# Fall — inclinación hacia atrás en caída
func _real_fall_anim() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 0.5
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,  Vector3(10.0, 0.0, 0.0))
	a.track_insert_key(tr, 0.25, Vector3(12.0, 0.0, 0.0))
	a.track_insert_key(tr, 0.5,  Vector3(10.0, 0.0, 0.0))
	return a

# Hit — sacudida brusca al recibir daño
func _real_hit_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.35
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,   Vector3(0.0,  0.0,  0.0))
	a.track_insert_key(tr, 0.05,  Vector3(-20.0, 0.0, 15.0))
	a.track_insert_key(tr, 0.15,  Vector3(10.0,  0.0, -8.0))
	a.track_insert_key(tr, 0.25,  Vector3(-5.0,  0.0,  4.0))
	a.track_insert_key(tr, 0.35,  Vector3(0.0,   0.0,  0.0))
	return a

# Attack — giro ofensivo hacia el frente
func _real_attack_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.4
	var base_y: float = -0.9
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,  Vector3(0.0,  0.0,  0.0))
	a.track_insert_key(tr, 0.1,  Vector3(-5.0, 0.0, -8.0))
	a.track_insert_key(tr, 0.25, Vector3(5.0,  0.0, 12.0))
	a.track_insert_key(tr, 0.4,  Vector3(0.0,  0.0,  0.0))
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.1,  Vector3(0.1, base_y - 0.05, 0.0))
	a.track_insert_key(tp, 0.4,  Vector3(0.0, base_y,        0.0))
	return a

# Shield — agachado / encogido
func _real_shield_anim() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 0.3
	var base_y: float = -0.9
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,  Vector3(0.0, base_y - 0.15, 0.0))
	a.track_insert_key(tp, 0.15, Vector3(0.0, base_y - 0.18, 0.0))
	a.track_insert_key(tp, 0.3,  Vector3(0.0, base_y - 0.15, 0.0))
	var ts := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ts, "Humanoid/ModelRoot:scale")
	a.track_insert_key(ts, 0.0, Vector3(1.15, 0.95, 1.15))
	a.track_insert_key(ts, 0.3, Vector3(1.15, 0.95, 1.15))
	return a

# Brake — frenada con inclinación hacia atrás
func _real_brake_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.25
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(tr, 0.0,  Vector3(-12.0, 0.0, 0.0))
	a.track_insert_key(tr, 0.1,  Vector3(18.0,  0.0, 0.0))
	a.track_insert_key(tr, 0.25, Vector3(0.0,   0.0, 0.0))
	return a

# ─────────────────────────────────────────────────────────────

func _create_reset_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.001

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))

	var h_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_pos, "Humanoid/TorsoMesh/HeadMesh:position")
	anim.track_insert_key(h_pos, 0.0, Vector3(0, 0.55, 0))

	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(0, 0, 0))

	var la_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_pos, "Humanoid/TorsoMesh/LeftArmMesh:position")
	anim.track_insert_key(la_pos, 0.0, Vector3(-0.35, 0, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(0, 0, 0))

	var ra_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_pos, "Humanoid/TorsoMesh/RightArmMesh:position")
	anim.track_insert_key(ra_pos, 0.0, Vector3(0.35, 0, 0))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(0, 0, 0))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var ll_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_rot, "Humanoid/LeftLegMesh:rotation_degrees")
	anim.track_insert_key(ll_rot, 0.0, Vector3(0, 0, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	var rl_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_rot, "Humanoid/RightLegMesh:rotation_degrees")
	anim.track_insert_key(rl_rot, 0.0, Vector3(0, 0, 0))

	return anim

# 1. JoJo Menacing Idle Stance (resetea todas las posiciones para evitar extremidades trabadas)
func _create_idle_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 1.0

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-25, 15, 12))
	anim.track_insert_key(t_rot, 0.5, Vector3(-20, 10, 8))
	anim.track_insert_key(t_rot, 1.0, Vector3(-25, 15, 12))

	var h_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_pos, "Humanoid/TorsoMesh/HeadMesh:position")
	anim.track_insert_key(h_pos, 0.0, Vector3(0, 0.55, 0))

	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(20, -15, -10))
	anim.track_insert_key(h_rot, 0.5, Vector3(15, -10, -5))
	anim.track_insert_key(h_rot, 1.0, Vector3(20, -15, -10))

	var la_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_pos, "Humanoid/TorsoMesh/LeftArmMesh:position")
	anim.track_insert_key(la_pos, 0.0, Vector3(-0.35, 0, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-90, 35, 60))
	anim.track_insert_key(la_rot, 0.5, Vector3(-85, 30, 55))
	anim.track_insert_key(la_rot, 1.0, Vector3(-90, 35, 60))

	var ra_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_pos, "Humanoid/TorsoMesh/RightArmMesh:position")
	anim.track_insert_key(ra_pos, 0.0, Vector3(0.35, 0, 0))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(45, -30, -35))
	anim.track_insert_key(ra_rot, 0.5, Vector3(40, -25, -30))
	anim.track_insert_key(ra_rot, 1.0, Vector3(45, -30, -35))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 2. Wide Putin / Giga-Chad Walkmeme
func _create_walk_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.6

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(10, 0, 25))
	anim.track_insert_key(t_rot, 0.3, Vector3(10, 0, -25))
	anim.track_insert_key(t_rot, 0.6, Vector3(10, 0, 25))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.30, -0.50, 0.45))
	anim.track_insert_key(ll_pos, 0.3, Vector3(-0.30, -0.50, -0.45))
	anim.track_insert_key(ll_pos, 0.6, Vector3(-0.30, -0.50, 0.45))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.30, -0.50, -0.45))
	anim.track_insert_key(rl_pos, 0.3, Vector3(0.30, -0.50, 0.45))
	anim.track_insert_key(rl_pos, 0.6, Vector3(0.30, -0.50, -0.45))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-75, 0, 45))
	anim.track_insert_key(la_rot, 0.3, Vector3(75, 0, 45))
	anim.track_insert_key(la_rot, 0.6, Vector3(-75, 0, 45))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(75, 0, -45))
	anim.track_insert_key(ra_rot, 0.3, Vector3(-75, 0, -45))
	anim.track_insert_key(ra_rot, 0.6, Vector3(75, 0, -45))

	return anim

# 3. Naruto Run / DBZ Sprint
func _create_run_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.3

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(60, 0, 0))
	anim.track_insert_key(t_rot, 0.15, Vector3(55, 0, 0))
	anim.track_insert_key(t_rot, 0.3, Vector3(60, 0, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(160, 0, 0))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(160, 0, 0))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.40, 0.60))
	anim.track_insert_key(ll_pos, 0.15, Vector3(-0.18, -0.40, -0.60))
	anim.track_insert_key(ll_pos, 0.3, Vector3(-0.18, -0.40, 0.60))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.40, -0.60))
	anim.track_insert_key(rl_pos, 0.15, Vector3(0.18, -0.40, 0.60))
	anim.track_insert_key(rl_pos, 0.3, Vector3(0.18, -0.40, -0.60))

	return anim

# 4. MUGEN Dramatic Anime Brake Slide
func _create_run_brake_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.25

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-55, 0, 0))
	anim.track_insert_key(t_rot, 0.25, Vector3(0, 0, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-90, 0, 0))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(60, -45, -45))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 5. JoJo Spin Turn (WRYYYY)
func _create_pivot_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.18

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-30, 0, 0))
	anim.track_insert_key(t_rot, 0.09, Vector3(-30, 180, 0))
	anim.track_insert_key(t_rot, 0.18, Vector3(0, 360, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-90, 45, 90))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(-90, -45, -90))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 6. Boss Crouch / Evil Mastermind Squat
func _create_squat_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.5

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.30, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-15, 10, 0))

	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(30, -10, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-100, 35, 45))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(50, -30, -30))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.25, -0.60, 0.15))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.25, -0.60, 0.15))

	return anim

# 7. Super Saiyan Charge (Pre-Salto)
func _create_jump_squat_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.05

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.20, 0))
	anim.track_insert_key(t_pos, 0.05, Vector3(0, 0.10, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(45, 45, 45))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(45, -45, -45))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 8. Shoryuken / Super Saiyan Rocket Ascension Jump
func _create_jump_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.4

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	# Puño derecho al cielo Shoryuken
	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(-180, 0, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(45, 0, 30))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-25, 15, 0))

	# Rodilla voladora levantada
	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.30, 0.35))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.60, -0.15))

	return anim

# 9. DIO / Sephiroth T-Pose Heavenly Descent Fall
func _create_fall_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.4

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))

	# Brazos abiertos en T-Pose amenazante
	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(0, 0, 90))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(0, 0, -90))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 10. DIO Missile Fast Fall Dive
func _create_fast_fall_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.2

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(80, 0, 0))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(160, 0, 0))

	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(160, 0, 0))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 11. ORA ORA / Falcon Punch Attack
func _create_attack_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.35

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-20, -60, 0))
	anim.track_insert_key(t_rot, 0.1, Vector3(10, 60, 0))
	anim.track_insert_key(t_rot, 0.35, Vector3(0, 0, 0))

	var la_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_pos, "Humanoid/TorsoMesh/LeftArmMesh:position")
	anim.track_insert_key(la_pos, 0.0, Vector3(-0.35, 0.15, -0.2))
	anim.track_insert_key(la_pos, 0.1, Vector3(-0.1, 0.2, 0.85))
	anim.track_insert_key(la_pos, 0.35, Vector3(-0.35, 0.15, 0.15))

	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-35, 45, 0))
	anim.track_insert_key(la_rot, 0.1, Vector3(-90, 0, 0))
	anim.track_insert_key(la_rot, 0.35, Vector3(-35, 15, 25))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 12. Hit Knockback Reaction
func _create_hit_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.3

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-60, 0, -30))
	anim.track_insert_key(t_rot, 0.3, Vector3(0, 0, 0))

	var h_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_pos, "Humanoid/TorsoMesh/HeadMesh:position")
	anim.track_insert_key(h_pos, 0.0, Vector3(0, 0.55, -0.4))
	anim.track_insert_key(h_pos, 0.3, Vector3(0, 0.55, 0))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 13. DIO Iconic Back-Turned Menacing Flex (JoJo Shield Pose)
func _create_shield_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.2

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	# Torso girado de espaldas (-135 grados) mostrando la espalda
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(15, -135, -10))

	# Cabeza girada sobre el hombro mirando hacia atrás al rival
	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(-10, 120, 15))

	# Brazo izquierdo flexionado frente al pecho
	var la_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(la_rot, "Humanoid/TorsoMesh/LeftArmMesh:rotation_degrees")
	anim.track_insert_key(la_rot, 0.0, Vector3(-110, 45, 50))

	# Brazo derecho extendido sobre la cintura
	var ra_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ra_rot, "Humanoid/TorsoMesh/RightArmMesh:rotation_degrees")
	anim.track_insert_key(ra_rot, 0.0, Vector3(50, -45, -30))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.25, -0.55, 0.15))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.25, -0.55, -0.15))

	return anim

# 14. Sonic Spinball Tumble Roll
func _create_roll_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.4

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.2, Vector3(360, 0, 0))
	anim.track_insert_key(t_rot, 0.4, Vector3(720, 0, 0))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim

# 15. Ultra Instinct Limbo Spotdodge
func _create_spotdodge_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.35

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.15, Vector3(-65, 0, 0))
	anim.track_insert_key(t_rot, 0.35, Vector3(0, 0, 0))

	var ll_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ll_pos, "Humanoid/LeftLegMesh:position")
	anim.track_insert_key(ll_pos, 0.0, Vector3(-0.18, -0.55, 0))

	var rl_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rl_pos, "Humanoid/RightLegMesh:position")
	anim.track_insert_key(rl_pos, 0.0, Vector3(0.18, -0.55, 0))

	return anim
