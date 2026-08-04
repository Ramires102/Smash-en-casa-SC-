class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer

func _ready() -> void:
	if animation_player:
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
	anim.track_insert_key(h_pos, 0.0, Vector3(0, 0.52, 0))

	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(0, 0, 0))

	# Brazos articulados con codo
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(0, 0, 0))

	var lfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lfa_rot, "Humanoid/TorsoMesh/LeftUpperArm/LeftForearm:rotation_degrees")
	anim.track_insert_key(lfa_rot, 0.0, Vector3(0, 0, 0))

	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(0, 0, 0))

	var rfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rfa_rot, "Humanoid/TorsoMesh/RightUpperArm/RightForearm:rotation_degrees")
	anim.track_insert_key(rfa_rot, 0.0, Vector3(0, 0, 0))

	# Piernas articuladas con rodilla
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.0, Vector3(0, 0, 0))

	var lll_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lll_rot, "Humanoid/LeftUpperLeg/LeftLowerLeg:rotation_degrees")
	anim.track_insert_key(lll_rot, 0.0, Vector3(0, 0, 0))

	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(0, 0, 0))

	var rll_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rll_rot, "Humanoid/RightUpperLeg/RightLowerLeg:rotation_degrees")
	anim.track_insert_key(rll_rot, 0.0, Vector3(0, 0, 0))

	return anim

# 1. JoJo Menacing Idle Stance (Manos a la cintura estilo DIO con CODOS flexionados a 90°)
func _create_idle_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 1.0

	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-20, 15, 10))
	anim.track_insert_key(t_rot, 0.5, Vector3(-15, 10, 6))
	anim.track_insert_key(t_rot, 1.0, Vector3(-20, 15, 10))

	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(20, -15, -8))
	anim.track_insert_key(h_rot, 0.5, Vector3(15, -10, -4))
	anim.track_insert_key(h_rot, 1.0, Vector3(20, -15, -8))

	# Brazo Izquierdo (Hombro hacia fuera y codo flexionado hacia la cintura)
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-35, 45, -40))
	anim.track_insert_key(lua_rot, 0.5, Vector3(-30, 40, -35))
	anim.track_insert_key(lua_rot, 1.0, Vector3(-35, 45, -40))

	var lfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lfa_rot, "Humanoid/TorsoMesh/LeftUpperArm/LeftForearm:rotation_degrees")
	anim.track_insert_key(lfa_rot, 0.0, Vector3(-105, 20, 15)) # Flexión pronunciada de codo
	anim.track_insert_key(lfa_rot, 0.5, Vector3(-95, 15, 10))
	anim.track_insert_key(lfa_rot, 1.0, Vector3(-105, 20, 15))

	# Brazo Derecho (Hombro hacia fuera y codo flexionado hacia la cintura)
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(35, -45, 40))
	anim.track_insert_key(rua_rot, 0.5, Vector3(30, -40, 35))
	anim.track_insert_key(rua_rot, 1.0, Vector3(35, -45, 40))

	var rfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rfa_rot, "Humanoid/TorsoMesh/RightUpperArm/RightForearm:rotation_degrees")
	anim.track_insert_key(rfa_rot, 0.0, Vector3(-105, -20, -15)) # Flexión pronunciada de codo
	anim.track_insert_key(rfa_rot, 0.5, Vector3(-95, -15, -10))
	anim.track_insert_key(rfa_rot, 1.0, Vector3(-105, -20, -15))

	return anim

# 2. Walk Animation
func _create_walk_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.6

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(10, 0, 15))
	anim.track_insert_key(t_rot, 0.3, Vector3(10, 0, -15))
	anim.track_insert_key(t_rot, 0.6, Vector3(10, 0, 15))

	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.0, Vector3(35, 0, 0))
	anim.track_insert_key(lul_rot, 0.3, Vector3(-35, 0, 0))
	anim.track_insert_key(lul_rot, 0.6, Vector3(35, 0, 0))

	var lll_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lll_rot, "Humanoid/LeftUpperLeg/LeftLowerLeg:rotation_degrees")
	anim.track_insert_key(lll_rot, 0.0, Vector3(20, 0, 0))
	anim.track_insert_key(lll_rot, 0.3, Vector3(45, 0, 0))
	anim.track_insert_key(lll_rot, 0.6, Vector3(20, 0, 0))

	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(-35, 0, 0))
	anim.track_insert_key(rul_rot, 0.3, Vector3(35, 0, 0))
	anim.track_insert_key(rul_rot, 0.6, Vector3(-35, 0, 0))

	var rll_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rll_rot, "Humanoid/RightUpperLeg/RightLowerLeg:rotation_degrees")
	anim.track_insert_key(rll_rot, 0.0, Vector3(45, 0, 0))
	anim.track_insert_key(rll_rot, 0.3, Vector3(20, 0, 0))
	anim.track_insert_key(rll_rot, 0.6, Vector3(45, 0, 0))

	return anim

# 3. Run Animation (Naruto / Sonic Run)
func _create_run_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.4

	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(35, 0, 0))

	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-70, 0, 0))

	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-70, 0, 0))

	return anim

func _create_run_brake_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.25
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-25, 0, 0))
	return anim

func _create_pivot_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.2
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 90, 0))
	return anim

func _create_squat_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.1
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.25, 0))
	return anim

func _create_jump_squat_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.08
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.3, 0))
	return anim

func _create_jump_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.3
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-140, 0, 0))
	return anim

func _create_fall_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.3
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(40, 0, 0))
	return anim

func _create_fast_fall_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.2
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.15, 0))
	return anim

func _create_attack_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.35
	# Puñetazo extendiendo el brazo con codo
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-90, 0, 0))
	anim.track_insert_key(rua_rot, 0.15, Vector3(90, 0, 0))
	anim.track_insert_key(rua_rot, 0.35, Vector3(0, 0, 0))

	var rfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rfa_rot, "Humanoid/TorsoMesh/RightUpperArm/RightForearm:rotation_degrees")
	anim.track_insert_key(rfa_rot, 0.0, Vector3(-90, 0, 0)) # Codo doblado para cargar el golpe
	anim.track_insert_key(rfa_rot, 0.15, Vector3(0, 0, 0))   # Codo estirado en el impacto
	anim.track_insert_key(rfa_rot, 0.35, Vector3(0, 0, 0))
	return anim

func _create_hit_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.4
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-45, 0, 0))
	anim.track_insert_key(t_rot, 0.4, Vector3(0, 0, 0))
	return anim

func _create_shield_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.2
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-90, 45, 0))
	var lfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lfa_rot, "Humanoid/TorsoMesh/LeftUpperArm/LeftForearm:rotation_degrees")
	anim.track_insert_key(lfa_rot, 0.0, Vector3(-90, 0, 0))
	return anim

func _create_roll_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.4
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.4, Vector3(360, 0, 0))
	return anim

func _create_spotdodge_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.3
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0, -0.4))
	anim.track_insert_key(t_pos, 0.3, Vector3(0, 0.05, 0))
	return anim
