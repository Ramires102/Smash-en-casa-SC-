class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer

var _character: Node = null
var _active_player: AnimationPlayer = null
var _current_animation_name: String = "Idle"
var _current_speed: float = 1.0

var model_root: Node3D = null
var skeleton: Skeleton3D = null
var vfx_group: Node3D = null

var is_gogeta: bool = false
var is_sans: bool = false
var active_state_name: String = "Idle"
var state_elapsed: float = 0.0
var active_attack: AttackData = null
var attack_frame: int = 0
var attack_phase: String = "none"
var is_sliding_knockdown: bool = false
var is_double_jumping: bool = false
var _pose_initialized: bool = false

# Aliases de compatibilidad para nombres estándar de estados (sistema legacy)
const ANIMATION_ALIASES: Dictionary = {
	"AttackJab1": "AttackNeutral",
	"AttackJab2": "AttackNeutral2",
	"AttackJab3": "AttackNeutral3",
	"AttackSideTilt": "AttackSide",
	"AttackUpTilt": "AttackUp",
	"AttackDownTilt": "AttackDown",
	"AttackNair": "NeutralAir",
	"AttackUair": "UpAir",
	"AttackDair": "DownAir",
	"AttackAir": "NeutralAir",
	"AttackAirUp": "UpAir",
	"AttackAirDown": "DownAir",
	"AttackFair": "ForwardAir",
	"AttackBair": "BackAir",
	"AttackSpecial": "SpecialNeutral",
	"AttackSpecialNeutral": "SpecialNeutral",
	"AttackSpecialSide": "SpecialSide",
	"AttackSpecialUp": "SpecialUp",
	"AttackSpecialDown": "SpecialDown",
	"Special": "SpecialNeutral",
	"Grab": "AttackNeutral",
	"Crouch": "Squat"
}

# Fallback a nombres en español para modelos GLB con animaciones en español
const SPANISH_FALLBACKS: Dictionary = {
	"jump": "salto",
	"fall": "caida",
	"fastfall": "caida",
	"squat": "agachado",
	"attack": "ataque",
	"attackneutral": "ataque",
	"attackdown": "ataque agachado",
	"downtilt": "ataque agachado",
	"neutralair": "salto ataque",
	"attackair": "salto ataque",
	"upair": "salto ataque arriba",
	"attackairup": "salto ataque arriba",
	"downair": "salto ataque abajo",
	"attackairdown": "salto ataque abajo",
	"special": "especial",
	"specialneutral": "especial",
	"specialup": "especial arriba",
	"specialdown": "especial abajo (parry)",
	"death": "salida del personaje",
}

# Índices de huesos de Gogeta y bindings de cuaterniones de Sans
var _gogeta_bones: Dictionary = {}
var _sans_bindings: Dictionary = {}

# Pose anatómica de 24-DOF (idéntica a FighterPose en animation_controller.ts)
var _cur_pose: Dictionary = {}
var _tgt_pose: Dictionary = {}

# Nodos 3D de VFX de combate
var _slash_arc_mesh: MeshInstance3D
var _beam_group: Node3D
var _bone_pillar_group: Node3D
var _stardust_orb_mesh: MeshInstance3D
var _charge_ring_mesh: MeshInstance3D
var _spiral_vortex_group: Node3D
var _ki_knee_cone_group: Node3D
var _somersault_vortex_group: Node3D
var _elbow_slash_beam_group: Node3D
var _kick_crescent_arc_group: Node3D
var _divekick_vfx_group: Node3D

func _ready() -> void:
	_character = get_parent()
	_cur_pose = _create_default_pose()
	_tgt_pose = _create_default_pose()

func setup(data: CharacterData = null) -> void:
	_character = get_parent()
	_cur_pose = _create_default_pose()
	_tgt_pose = _create_default_pose()
	_pose_initialized = false
	call_deferred("_initialize_procedural_or_legacy", data)

func _initialize_procedural_or_legacy(data: CharacterData) -> void:
	if _character == null:
		return
	model_root = _character.get_node_or_null("Humanoid/ModelRoot") as Node3D
	if model_root == null:
		model_root = _character.find_child("ModelRoot", true, false) as Node3D

	skeleton = null
	if model_root != null:
		skeleton = model_root.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		skeleton = _character.find_child("Skeleton3D", true, false) as Skeleton3D

	var char_id: String = ""
	if data != null:
		if "character_name" in data:
			char_id = str(data.character_name).to_lower()
		elif "display_name" in data:
			char_id = str(data.display_name).to_lower()

	is_gogeta = false
	is_sans = false

	if skeleton != null:
		if char_id.contains("gogeta") or skeleton.find_bone("Sash") != -1:
			is_gogeta = true
			_init_gogeta_rig()
			_inject_gogeta_moveset()
		elif char_id.contains("sans") or skeleton.find_bone("Spine_1") != -1 or skeleton.find_bone("UpperarmR") != -1:
			is_sans = true
			_init_sans_rig()
			_inject_sans_moveset()

	if is_gogeta or is_sans:
		_refresh_active_player()
		stop()
		_build_combat_vfx_nodes()
		_update_procedural_rig(0.016)
	else:
		_refresh_active_player()
		if data and data.animation_library and animation_player:
			if animation_player.has_animation_library(""):
				animation_player.remove_animation_library("")
			animation_player.add_animation_library("", data.animation_library)
		# Si la máquina de estados ya tiene un estado activo, reproducirlo
		# (compatibilidad con modelos GLB que traen sus propios clips)
		if _character and _character.has_node("StateMachine"):
			var fsm: Node = _character.get_node("StateMachine")
			if fsm and fsm.get("current_state"):
				play_animation(str(fsm.current_state.name))

func _init_gogeta_rig() -> void:
	_gogeta_bones.clear()
	if skeleton == null:
		return
	for b_name in ["Pelvis", "Spine", "Head", "ShoulderR", "ElbowR", "ShoulderL", "ElbowL", "HipR", "KneeR", "HipL", "KneeL", "Sash"]:
		_gogeta_bones[b_name] = skeleton.find_bone(b_name)

func _init_sans_rig() -> void:
	_sans_bindings.clear()
	if skeleton == null or model_root == null:
		return
	# Ocultar mallas extra del FBX de Sans para que solo quede la malla del cuerpo ("sans")
	_hide_extra_sans_meshes(model_root)

	var skel_to_model_quat: Quaternion = (model_root.global_transform.basis.inverse() * skeleton.global_transform.basis).get_rotation_quaternion().normalized()
	for idx in range(skeleton.get_bone_count()):
		var b_name: String = skeleton.get_bone_name(idx)
		var local_rest_quat: Quaternion = skeleton.get_bone_rest(idx).basis.get_rotation_quaternion().normalized()
		var bone_skel_rest_quat: Quaternion = skeleton.get_bone_global_rest(idx).basis.get_rotation_quaternion().normalized()
		var char_rest_quat: Quaternion = (skel_to_model_quat * bone_skel_rest_quat).normalized()
		_sans_bindings[b_name] = {
			"idx": idx,
			"local_rest": local_rest_quat,
			"char_rest": char_rest_quat,
			"inv_char_rest": char_rest_quat.inverse()
		}

func _hide_extra_sans_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.name.to_lower() != "sans":
			child.visible = false
		_hide_extra_sans_meshes(child)

func _create_default_pose() -> Dictionary:
	return {
		"pelvisOffsetY": 0.0, "pelvisOffsetZ": 0.0,
		"pelvisPitch": 0.0, "pelvisYaw": 0.0, "pelvisRoll": 0.0,
		"spinePitch": 0.0, "spineYaw": 0.0, "spineRoll": 0.0,
		"headPitch": 0.0, "headYaw": 0.0, "headRoll": 0.0,
		"armDownR": 1.12, "armFwdR": 0.35, "armCrossR": 0.35, "armRollR": -0.45, "elbowBendR": 1.25,
		"armDownL": 1.12, "armFwdL": 0.35, "armCrossL": 0.35, "armRollL": -0.45, "elbowBendL": 1.25,
		"hipPitchR": 0.0, "hipSplayR": 0.0, "kneeBendR": 0.0,
		"hipPitchL": 0.0, "hipSplayL": 0.0, "kneeBendL": 0.0
	}

func set_paused(paused: bool) -> void:
	if is_gogeta or is_sans:
		return
	if _active_player:
		_active_player.speed_scale = 0.0 if paused else 1.0
	if animation_player and animation_player != _active_player:
		animation_player.speed_scale = 0.0 if paused else 1.0

func stop() -> void:
	if _active_player and _active_player.is_playing():
		_active_player.stop()
	if animation_player and animation_player.is_playing():
		animation_player.stop()

func on_facing_direction_changed(_dir: float) -> void:
	if is_gogeta or is_sans:
		return
	if _current_animation_name != "":
		var base_name: String = _current_animation_name.replace("_Left", "")
		if base_name in ["Idle", "Walk", "Run", "Dash"]:
			play_animation(base_name, _current_speed)

func play_animation(anim_name: String, custom_speed: float = 1.0, blend_time: float = 0.03) -> void:
	_current_animation_name = anim_name
	_current_speed = custom_speed
	state_elapsed = 0.0
	if anim_name in ["Run", "Dash", "Walk"]:
		active_state_name = "Run"
	elif anim_name in ["Jump", "JumpSquat"]:
		active_state_name = "Jump"
	elif anim_name in ["Fall", "Tumble", "AirDodge"]:
		active_state_name = "Fall"
	elif anim_name in ["Hit", "Daze"]:
		active_state_name = "Hit"
	elif anim_name == "Death":
		active_state_name = "Death"
	else:
		active_state_name = "Idle"

	if active_state_name != "Attack":
		active_attack = null
		attack_phase = "none"
		_hide_all_combat_vfx()

	# Modo legacy: reproducir el clip real en el AnimationPlayer interno del modelo
	if not is_gogeta and not is_sans:
		if not _active_player:
			_refresh_active_player()
		if _active_player == null:
			return
		var resolved_name: String = _resolve_animation_name(anim_name)
		var clip_to_play: String = _find_clip_in_player(_active_player, resolved_name)
		# Si no se encontró la versión direccional, probar con el nombre base
		if clip_to_play == "" and resolved_name != anim_name:
			clip_to_play = _find_clip_in_player(_active_player, anim_name)
		# Fallback alternativo en el AnimationPlayer raíz si el del modelo no la tiene
		if clip_to_play == "" and animation_player and animation_player != _active_player:
			var root_clip: String = _find_clip_in_player(animation_player, resolved_name)
			if root_clip != "":
				animation_player.play(root_clip, blend_time, custom_speed)
				return
		if clip_to_play != "":
			var low_clip: String = clip_to_play.to_lower()
			if _active_player.has_animation(clip_to_play):
				var a_res: Animation = _active_player.get_animation(clip_to_play)
				if a_res and a_res.loop_mode == Animation.LOOP_NONE:
					if low_clip.contains("idle") or low_clip.contains("walk") or low_clip.contains("run") or low_clip.contains("buzzsaw"):
						a_res.loop_mode = Animation.LOOP_LINEAR
			_active_player.play(clip_to_play, blend_time, custom_speed)

func play_attack_animation(anim_name: String, target_duration: float = 0.0, atk_data: AttackData = null) -> void:
	_current_animation_name = anim_name
	active_state_name = "Attack"
	state_elapsed = 0.0
	attack_frame = 1
	attack_phase = "startup"
	if atk_data != null:
		active_attack = atk_data

	# Modo legacy: escalar la velocidad del clip para calzar con la duración del hitbox
	if not is_gogeta and not is_sans:
		var speed: float = 1.0
		if target_duration > 0.0:
			var clip_len: float = get_animation_length(anim_name)
			if clip_len > 0.0:
				speed = clampf(clip_len / target_duration, 0.5, 4.0)
		play_animation(anim_name, speed, 0.02)

func get_animation_length(anim_name: String) -> float:
	if not _active_player:
		_refresh_active_player()
	if not _active_player:
		return 0.0

	var clip_name: String = _find_clip_in_player(_active_player, anim_name)
	if clip_name != "" and _active_player.has_animation(clip_name):
		return _active_player.get_animation(clip_name).length

	if animation_player and animation_player != _active_player:
		clip_name = _find_clip_in_player(animation_player, anim_name)
		if clip_name != "" and animation_player.has_animation(clip_name):
			return animation_player.get_animation(clip_name).length

	return 0.0

func update_attack_frame(frame: int, phase: String, atk_data: AttackData = null) -> void:
	attack_frame = frame
	attack_phase = phase
	if atk_data != null:
		active_attack = atk_data

func _physics_process(delta: float) -> void:
	if not is_gogeta and not is_sans:
		return
	if _character and _character.has_method("is_self_hitlag_active") and _character.is_self_hitlag_active():
		return
	_sync_state_from_character()
	_update_procedural_rig(delta)

func _sync_state_from_character() -> void:
	if _character == null or not ("state_machine" in _character) or _character.state_machine == null:
		return
	var st: Node = _character.state_machine.current_state
	if st == null:
		return
	var st_name: String = st.name
	if st_name == "Attack":
		active_state_name = "Attack"
		if "current_attack_data" in st and st.current_attack_data != null:
			active_attack = st.current_attack_data
		if "frame_cursor" in st:
			attack_frame = maxi(1, st.frame_cursor)
			var s: int = active_attack.startup_frames if active_attack else 5
			var a: int = active_attack.active_frames if active_attack else 5
			if attack_frame <= s:
				attack_phase = "startup"
			elif attack_frame <= s + a:
				attack_phase = "active"
			else:
				attack_phase = "recovery"
	elif st_name in ["Run", "Dash", "Walk"]:
		active_state_name = "Run"
	elif st_name in ["Jump", "JumpSquat"]:
		active_state_name = "Jump"
	elif st_name in ["Fall", "Tumble", "AirDodge"]:
		active_state_name = "Fall"
	elif st_name in ["Hit", "Daze"]:
		active_state_name = "Hit"
	elif st_name == "Death":
		active_state_name = "Death"
	else:
		active_state_name = "Idle"

func _update_procedural_rig(dt: float) -> void:
	var safe_dt: float = minf(dt, 0.05)
	state_elapsed += safe_dt

	_compute_target_pose(state_elapsed)

	var is_attacking: bool = (active_state_name == "Attack" and active_attack != null)
	var is_turn_kick: bool = is_attacking and active_attack.pose_style == "down_special_turn_kick"
	var damp_lambda: float = 19.0 if is_turn_kick else (26.0 if is_attacking else 18.0)

	# Evitar que giros de 360°/720° se desenrollen al revés al volver a reposo
	if absf(_tgt_pose["pelvisPitch"]) < PI and absf(_cur_pose["pelvisPitch"]) >= PI:
		_cur_pose["pelvisPitch"] = wrapf(_cur_pose["pelvisPitch"], -PI, PI)
	if absf(_tgt_pose["pelvisYaw"]) < PI and absf(_cur_pose["pelvisYaw"]) >= PI:
		_cur_pose["pelvisYaw"] = wrapf(_cur_pose["pelvisYaw"], -PI, PI)

	if not _pose_initialized or safe_dt <= 0.0:
		for k in _tgt_pose.keys():
			_cur_pose[k] = _tgt_pose[k]
		_pose_initialized = true
	else:
		for k in _tgt_pose.keys():
			_cur_pose[k] = CharacterController.damp(_cur_pose[k], _tgt_pose[k], damp_lambda, safe_dt)

	if is_gogeta:
		_apply_gogeta_pose(_cur_pose, state_elapsed)
	elif is_sans:
		_apply_sans_pose(_cur_pose)

	_update_combat_vfx(state_elapsed)

# ============================================================================
# SÍNTESIS DE POSE UNIFICADA (GOGETA SSJ & SANS) 1:1 CON ANIMATION_CONTROLLER.TS
# ============================================================================
func _compute_target_pose(t: float) -> void:
	var p := _tgt_pose
	var breath_speed: float = 2.6 if is_gogeta else 2.1
	var breath_freq: float = breath_speed * 1.25
	var breath: float = sin(t * breath_freq)
	var breath2: float = cos(t * breath_freq * 2.0)

	p["pelvisOffsetY"] = -0.05 if is_gogeta else 0.0
	p["pelvisOffsetZ"] = 0.0
	p["pelvisPitch"] = 0.08 if is_gogeta else 0.0
	p["pelvisYaw"] = 0.42 if is_gogeta else 0.12
	p["pelvisRoll"] = 0.0
	p["spinePitch"] = 0.14 if is_gogeta else -0.03
	p["spineYaw"] = -0.18 if is_gogeta else -0.04
	p["spineRoll"] = 0.0
	p["headPitch"] = 0.06 if is_gogeta else 0.02
	p["headYaw"] = -0.24 if is_gogeta else -0.08
	p["headRoll"] = 0.0

	if is_gogeta:
		p["armDownR"] = 0.88; p["armFwdR"] = 0.78; p["armCrossR"] = 0.34; p["armRollR"] = -0.62; p["elbowBendR"] = 1.48
		p["armDownL"] = 1.06; p["armFwdL"] = 0.16; p["armCrossL"] = 0.52; p["armRollL"] = -0.55; p["elbowBendL"] = 1.58
		p["hipPitchR"] = 0.36; p["hipSplayR"] = -0.05; p["kneeBendR"] = 0.48
		p["hipPitchL"] = -0.22; p["hipSplayL"] = -0.05; p["kneeBendL"] = 0.32
	else:
		p["armDownR"] = 1.18; p["armFwdR"] = 0.18; p["armCrossR"] = 0.42; p["armRollR"] = -0.45; p["elbowBendR"] = 1.22
		p["armDownL"] = 1.18; p["armFwdL"] = 0.18; p["armCrossL"] = 0.42; p["armRollL"] = -0.45; p["elbowBendL"] = 1.22
		p["hipPitchR"] = 0.08; p["hipSplayR"] = 0.0; p["kneeBendR"] = 0.16
		p["hipPitchL"] = -0.04; p["hipSplayL"] = 0.0; p["kneeBendL"] = 0.14

	if active_state_name == "Hit" or active_state_name == "Death":
		if is_sliding_knockdown:
			p["pelvisOffsetY"] = -0.52; p["pelvisPitch"] = -1.22; p["pelvisYaw"] = 0.22
			p["spinePitch"] = -0.18; p["headPitch"] = -0.42; p["headYaw"] = 0.28
			p["armDownR"] = 0.68; p["armFwdR"] = -0.32; p["armCrossR"] = -0.12; p["elbowBendR"] = 0.58
			p["armDownL"] = 0.88; p["armFwdL"] = 0.22; p["armCrossL"] = 0.38; p["elbowBendL"] = 1.12
			p["hipPitchR"] = 0.52; p["kneeBendR"] = 0.68; p["hipPitchL"] = 0.26; p["kneeBendL"] = 0.48
			return
		var shake: float = sin(t * 42.0) * 0.06
		p["pelvisOffsetY"] = -0.04; p["pelvisPitch"] = -0.22; p["pelvisYaw"] = shake
		p["spinePitch"] = -0.32; p["headPitch"] = -0.35
		p["armDownR"] = 0.65; p["armFwdR"] = -0.35; p["armCrossR"] = -0.15; p["elbowBendR"] = 0.45
		p["armDownL"] = 0.65; p["armFwdL"] = -0.35; p["armCrossL"] = -0.15; p["elbowBendL"] = 0.45
		p["hipPitchR"] = 0.35; p["kneeBendR"] = 0.55; p["hipPitchL"] = 0.22; p["kneeBendL"] = 0.45
		return

	if active_state_name == "Jump":
		p["pelvisOffsetY"] = 0.06; p["pelvisYaw"] = 0.08; p["spinePitch"] = 0.12; p["headPitch"] = -0.12
		p["armDownR"] = 0.78; p["armFwdR"] = 0.25; p["armCrossR"] = 0.20; p["elbowBendR"] = 1.15
		p["armDownL"] = 0.78; p["armFwdL"] = 0.25; p["armCrossL"] = 0.20; p["elbowBendL"] = 1.15
		p["hipPitchR"] = 0.72; p["kneeBendR"] = 0.95; p["hipPitchL"] = 0.28; p["kneeBendL"] = 0.45
		if is_double_jumping:
			p["pelvisPitch"] = minf(PI * 2.0, t * 13.5)
			p["hipPitchL"] = 0.75; p["kneeBendL"] = 1.05
		return

	if active_state_name == "Fall":
		var sway: float = sin(t * 6.0) * 0.06
		p["pelvisYaw"] = 0.1; p["spinePitch"] = 0.14; p["headPitch"] = 0.15
		p["armDownR"] = 0.68 + sway; p["armFwdR"] = 0.15; p["armCrossR"] = 0.12; p["elbowBendR"] = 0.92
		p["armDownL"] = 0.68 - sway; p["armFwdL"] = 0.15; p["armCrossL"] = 0.12; p["elbowBendL"] = 0.92
		p["hipPitchR"] = 0.38; p["kneeBendR"] = 0.62; p["hipPitchL"] = 0.12; p["kneeBendL"] = 0.35
		return

	if active_state_name == "Run":
		if is_gogeta:
			var hw: float = sin(t * 7.5)
			var hw2: float = cos(t * 7.5)
			p["pelvisOffsetY"] = 0.18 + hw * 0.038; p["pelvisOffsetZ"] = 0.08
			p["pelvisPitch"] = 0.42 + hw * 0.03; p["pelvisYaw"] = 0.16; p["pelvisRoll"] = hw2 * 0.03
			p["spinePitch"] = 0.22 + hw * 0.025; p["spineYaw"] = -0.10
			p["headPitch"] = -0.48 - hw * 0.03; p["headYaw"] = -0.06
			p["hipPitchR"] = 0.68 + hw * 0.06; p["hipSplayR"] = -0.08; p["kneeBendR"] = 1.12 + hw * 0.08
			p["hipPitchL"] = -0.34 - hw * 0.05; p["hipSplayL"] = -0.08; p["kneeBendL"] = 0.36 + hw2 * 0.05
			p["armDownR"] = 0.96 + hw * 0.04; p["armFwdR"] = -0.28 + hw * 0.05; p["armCrossR"] = 0.18; p["armRollR"] = -0.35; p["elbowBendR"] = 0.88 + hw2 * 0.05
			p["armDownL"] = 0.92 - hw * 0.04; p["armFwdL"] = 0.32 + hw2 * 0.05; p["armCrossL"] = 0.38; p["armRollL"] = -0.48; p["elbowBendL"] = 1.32 - hw * 0.05
			return
		# Ciclo de carrera atlética de 4 articulaciones de Sans (animation_controller.ts)
		var phase: float = t * 11.5
		var sin_p: float = sin(phase)
		var cos_p: float = cos(phase)
		p["pelvisOffsetY"] = (absf(cos_p) - 0.35) * 0.07
		p["pelvisPitch"] = 0.08
		p["pelvisYaw"] = -sin_p * 0.18
		p["pelvisRoll"] = cos_p * 0.04
		p["spinePitch"] = 0.22 * 0.65
		p["spineYaw"] = sin_p * 0.24
		p["headPitch"] = -p["spinePitch"] * 0.55
		p["headYaw"] = -sin_p * 0.08
		p["hipPitchR"] = sin_p * 0.78 + 0.08
		p["kneeBendR"] = maxf(0.08, (-cos_p * 0.5 + 0.5) * 0.95)
		p["hipSplayR"] = 0.0
		p["hipPitchL"] = -sin_p * 0.78 + 0.08
		p["kneeBendL"] = maxf(0.08, (cos_p * 0.5 + 0.5) * 0.95)
		p["hipSplayL"] = 0.0
		p["armDownR"] = 1.12; p["armFwdR"] = -sin_p * 0.72 + 0.18; p["armCrossR"] = 0.22; p["elbowBendR"] = 1.35 + (-sin_p * 0.2)
		p["armDownL"] = 1.12; p["armFwdL"] = sin_p * 0.72 + 0.18; p["armCrossL"] = 0.22; p["elbowBendL"] = 1.35 + (sin_p * 0.2)
		return

	if active_state_name == "Attack" and active_attack != null:
		_compute_attack_pose(active_attack, p)
		return

	# Idle breathing
	var bounce: float = breath * 0.024
	p["pelvisOffsetY"] += bounce
	p["spinePitch"] += breath * 0.032
	p["headPitch"] -= breath * 0.025
	var knee_flex: float = maxf(0.0, -breath) * 0.065
	p["hipPitchR"] += knee_flex * 0.65
	p["kneeBendR"] += knee_flex
	p["hipPitchL"] += knee_flex * 0.55
	p["kneeBendL"] += knee_flex * 0.85
	p["armDownR"] += breath * 0.035
	p["armFwdR"] += breath * 0.04
	p["armDownL"] += breath * 0.03
	p["elbowBendR"] += breath2 * 0.035
	p["elbowBendL"] -= breath2 * 0.035

func _compute_attack_pose(atk: AttackData, p: Dictionary) -> void:
	var f: float = float(attack_frame)
	var s: float = float(maxi(1, atk.startup_frames))
	var a: float = float(maxi(1, atk.active_frames))
	var r: float = float(maxi(1, atk.recovery_frames))

	var is_startup: bool = (attack_phase == "startup")
	var is_active: bool = (attack_phase == "active")

	var startup_t: float = _smoothstep(0.0, 1.0, minf(1.0, f / s))
	var active_t: float = _smoothstep(0.0, 1.0, minf(1.0, (f - s) / a))
	var recovery_t: float = _smoothstep(0.0, 1.0, minf(1.0, (f - s - a) / r))

	var strike: float = (-0.35 * startup_t) if is_startup else (1.0 if is_active else (1.0 - recovery_t))
	var extend: float = maxf(0.0, strike)
	var coil: float = maxf(0.0, -strike)

	match atk.pose_style:
		"jab_double_strike":
			if is_startup:
				p["pelvisYaw"] = -0.25 * startup_t; p["spineYaw"] = -0.22 * startup_t
				p["armDownL"] = 1.05; p["armFwdL"] = 0.45 + 0.35 * startup_t; p["elbowBendL"] = 1.35 * (1.0 - 0.3 * startup_t)
				p["armDownR"] = 1.05; p["armFwdR"] = 0.58; p["armCrossR"] = 0.52; p["elbowBendR"] = 1.52
				p["hipPitchL"] = 0.35 * startup_t; p["kneeBendL"] = 0.45 * startup_t
			elif is_active:
				var second_hit_start: int = atk.second_hit_frame if atk.second_hit_frame > 0 else int(s + ceil(a * 0.5))
				if attack_frame < second_hit_start:
					p["pelvisYaw"] = -0.38; p["spineYaw"] = -0.34; p["spinePitch"] = 0.16; p["headYaw"] = 0.52; p["pelvisOffsetZ"] = 0.06
					p["armDownL"] = 1.15; p["armFwdL"] = 1.28; p["armCrossL"] = 0.18; p["armRollL"] = -0.35; p["elbowBendL"] = 0.12
					p["armDownR"] = 1.05; p["armFwdR"] = 0.62; p["armCrossR"] = 0.58; p["armRollR"] = -0.58; p["elbowBendR"] = 1.58
					p["hipPitchL"] = 0.42; p["kneeBendL"] = 0.52; p["hipPitchR"] = -0.32; p["kneeBendR"] = 0.22
				else:
					p["pelvisYaw"] = 0.58; p["spineYaw"] = 0.52; p["spinePitch"] = 0.24; p["headYaw"] = -0.68; p["pelvisOffsetZ"] = 0.12
					p["armDownR"] = 1.16; p["armFwdR"] = 1.44; p["armCrossR"] = 0.22; p["armRollR"] = -0.35; p["elbowBendR"] = 0.08
					p["armDownL"] = 0.72; p["armFwdL"] = -0.48; p["armCrossL"] = -0.18; p["elbowBendL"] = 1.38
					p["hipPitchL"] = 0.46; p["kneeBendL"] = 0.56; p["hipPitchR"] = -0.38; p["kneeBendR"] = 0.18
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisYaw"] = 0.58 * w + 0.42 * (1.0 - w); p["spineYaw"] = 0.52 * w - 0.18 * (1.0 - w); p["spinePitch"] = 0.24 * w + 0.14 * (1.0 - w)
				p["armDownR"] = 1.16 * w + 0.88 * (1.0 - w); p["armFwdR"] = 1.44 * w + 0.78 * (1.0 - w); p["elbowBendR"] = 0.08 * w + 1.48 * (1.0 - w)

		"jab_gut_upper":
			p["pelvisOffsetY"] = -0.06 * (coil + extend)
			p["hipPitchL"] = 0.44 * (coil + extend) + 0.15 * (1.0 - extend - coil); p["kneeBendL"] = 0.54 * (coil + extend) + 0.25 * (1.0 - extend - coil)
			p["hipPitchR"] = -0.34 * (coil + extend) + 0.20 * (1.0 - extend - coil); p["kneeBendR"] = 0.26
			p["armDownR"] = 1.12; p["armFwdR"] = 0.28; p["armCrossR"] = 0.42; p["armRollR"] = -0.52; p["elbowBendR"] = 1.48
			if is_startup:
				p["pelvisYaw"] = 0.28 * startup_t; p["spinePitch"] = 0.18 * startup_t
				p["armDownL"] = 1.26; p["armFwdL"] = -0.18 * startup_t; p["armCrossL"] = 0.15; p["elbowBendL"] = 1.32
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var rise: float = _smoothstep(0.0, 0.7, active_t) if is_active else 1.0
				p["pelvisYaw"] = -0.28 * w + 0.42 * (1.0 - w); p["spineYaw"] = -0.32 * w - 0.18 * (1.0 - w)
				p["spinePitch"] = -0.08 * w + 0.14 * (1.0 - w); p["headYaw"] = 0.45 * w - 0.24 * (1.0 - w)
				p["armDownL"] = (1.18 - 0.36 * rise) * w + 1.06 * (1.0 - w); p["armFwdL"] = (0.72 + 0.50 * rise) * w + 0.16 * (1.0 - w)
				p["armCrossL"] = 0.28 * w + 0.52 * (1.0 - w); p["armRollL"] = -0.65 * w - 0.55 * (1.0 - w); p["elbowBendL"] = 1.38 * w + 1.58 * (1.0 - w)

		"jab_axe_vault":
			if is_startup:
				p["pelvisOffsetY"] = 0.14 * startup_t; p["pelvisYaw"] = 0.08; p["spinePitch"] = -0.28 * startup_t; p["headPitch"] = 0.18 * startup_t
				p["armDownR"] = 0.88 - 0.58 * startup_t; p["armDownL"] = 0.88 - 0.58 * startup_t
				p["armFwdR"] = 0.78 + 0.96 * startup_t; p["armFwdL"] = 0.78 + 0.96 * startup_t
				p["armCrossR"] = 0.52 * startup_t; p["armCrossL"] = 0.52 * startup_t; p["elbowBendR"] = 1.12; p["elbowBendL"] = 1.12
				p["hipPitchL"] = 0.88 * startup_t; p["kneeBendL"] = 1.18 * startup_t; p["hipPitchR"] = -0.28 * startup_t; p["kneeBendR"] = 0.35 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = 0.18; p["pelvisPitch"] = 0.34; p["pelvisYaw"] = 0.0; p["spinePitch"] = 0.52; p["headPitch"] = 0.24
				p["armDownR"] = 1.24; p["armDownL"] = 1.24; p["armFwdR"] = 0.88; p["armFwdL"] = 0.88
				p["armCrossR"] = 0.54; p["armCrossL"] = 0.54; p["elbowBendR"] = 0.22; p["elbowBendL"] = 0.22
				p["hipPitchR"] = 0.82; p["kneeBendR"] = 1.12; p["hipSplayR"] = 0.22
				p["hipPitchL"] = 0.82; p["kneeBendL"] = 1.12; p["hipSplayL"] = 0.22
			else:
				var flip_t: float = _smoothstep(0.0, 0.88, recovery_t)
				var tuck: float = 1.0 - _smoothstep(0.75, 1.0, recovery_t)
				p["pelvisOffsetY"] = sin(flip_t * PI) * 0.28; p["pelvisPitch"] = flip_t * PI * 2.0; p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.45 * tuck; p["headPitch"] = 0.35 * tuck
				p["armDownR"] = 1.05; p["armDownL"] = 1.05; p["armFwdR"] = 0.65 * tuck + 0.78 * (1.0 - tuck); p["armFwdL"] = 0.65 * tuck + 0.16 * (1.0 - tuck)
				p["armCrossR"] = 0.48; p["armCrossL"] = 0.48; p["elbowBendR"] = 1.52; p["elbowBendL"] = 1.52
				p["hipPitchR"] = 1.15 * tuck + 0.36 * (1.0 - tuck); p["kneeBendR"] = 1.45 * tuck + 0.48 * (1.0 - tuck)
				p["hipPitchL"] = 1.15 * tuck - 0.22 * (1.0 - tuck); p["kneeBendL"] = 1.45 * tuck + 0.32 * (1.0 - tuck)

		"rekka_knee_dash":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = 0.14 * w - 0.05 * (1.0 - w); p["pelvisOffsetZ"] = 0.15 * w
			p["pelvisPitch"] = 0.34 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = 0.22 * w + 0.42 * (1.0 - w)
			p["spinePitch"] = 0.26 * w + 0.14 * (1.0 - w); p["spineYaw"] = 0.18 * w - 0.18 * (1.0 - w)
			p["headPitch"] = -0.34 * w + 0.06 * (1.0 - w); p["headYaw"] = -0.30 * w - 0.24 * (1.0 - w)
			p["hipPitchR"] = 1.32 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 1.58 * w + 0.48 * (1.0 - w); p["hipSplayR"] = -0.04
			p["hipPitchL"] = -0.46 * w - 0.22 * (1.0 - w); p["kneeBendL"] = 1.18 * w + 0.32 * (1.0 - w); p["hipSplayL"] = -0.04
			p["armDownR"] = 0.38 * w + 0.88 * (1.0 - w); p["armFwdR"] = -0.65 * w + 0.78 * (1.0 - w); p["armCrossR"] = -0.15 * w + 0.34 * (1.0 - w); p["armRollR"] = -0.35; p["elbowBendR"] = 0.62 * w + 1.48 * (1.0 - w)
			p["armDownL"] = 1.12 * w + 1.06 * (1.0 - w); p["armFwdL"] = 0.32 * w + 0.16 * (1.0 - w); p["armCrossL"] = 0.48 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.48 * w + 1.58 * (1.0 - w)

		"rekka_knee_rising":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = 0.20 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = -0.24 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = -0.26 * w + 0.42 * (1.0 - w)
			p["spinePitch"] = 0.18 * w + 0.14 * (1.0 - w); p["spineYaw"] = -0.18 * w - 0.18 * (1.0 - w)
			p["headPitch"] = -0.22 * w + 0.06 * (1.0 - w); p["headYaw"] = 0.28 * w - 0.24 * (1.0 - w)
			p["hipPitchL"] = 1.52 * w - 0.22 * (1.0 - w); p["kneeBendL"] = 1.56 * w + 0.32 * (1.0 - w); p["hipSplayL"] = -0.05
			p["hipPitchR"] = -0.38 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 0.16 * w + 0.48 * (1.0 - w); p["hipSplayR"] = -0.05
			p["armDownR"] = 0.84 * w + 0.88 * (1.0 - w); p["armFwdR"] = -0.38 * w + 0.78 * (1.0 - w); p["armCrossR"] = 0.24 * w + 0.34 * (1.0 - w); p["elbowBendR"] = 1.32 * w + 1.48 * (1.0 - w)
			p["armDownL"] = 0.86 * w + 1.06 * (1.0 - w); p["armFwdL"] = -0.32 * w + 0.16 * (1.0 - w); p["armCrossL"] = 0.28 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.35 * w + 1.58 * (1.0 - w)

		"rekka_axe_kick":
			if is_startup:
				p["pelvisOffsetY"] = 0.22 * startup_t; p["pelvisPitch"] = -0.24 * startup_t; p["pelvisYaw"] = 0.32 * startup_t
				p["spinePitch"] = -0.18 * startup_t; p["headPitch"] = 0.16 * startup_t
				p["hipPitchR"] = 0.36 + 1.42 * startup_t; p["kneeBendR"] = 0.48 * (1.0 - startup_t) + 0.05 * startup_t; p["hipSplayR"] = 0.10 * startup_t
				p["hipPitchL"] = 0.32 * startup_t; p["kneeBendL"] = 1.28 * startup_t
				p["armDownR"] = 0.88 - 0.52 * startup_t; p["armFwdR"] = 0.78 + 0.62 * startup_t; p["armCrossR"] = 0.38; p["elbowBendR"] = 1.25
				p["armDownL"] = 1.18; p["armFwdL"] = -0.32 * startup_t; p["elbowBendL"] = 0.42
			elif is_active:
				var slash_p: float = _smoothstep(0.0, 0.85, active_t)
				p["pelvisOffsetY"] = 0.18 * (1.0 - slash_p * 0.5); p["pelvisPitch"] = -0.18 + 0.38 * slash_p; p["pelvisYaw"] = 0.36
				p["spinePitch"] = 0.26 * slash_p; p["spineYaw"] = 0.24; p["headPitch"] = 0.18; p["headYaw"] = -0.28
				p["hipPitchR"] = 1.78 - 0.96 * slash_p; p["kneeBendR"] = 0.05; p["hipSplayR"] = 0.08
				p["hipPitchL"] = 0.28; p["kneeBendL"] = 1.35; p["hipSplayL"] = 0.12
				p["armDownR"] = 0.36; p["armFwdR"] = 1.38; p["armCrossR"] = 0.38; p["elbowBendR"] = 1.22
				p["armDownL"] = 1.22; p["armFwdL"] = -0.38; p["armCrossL"] = -0.12; p["elbowBendL"] = 0.35
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = 0.08 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = 0.20 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = 0.36 * w + 0.42 * (1.0 - w)
				p["spinePitch"] = 0.26 * w + 0.14 * (1.0 - w); p["hipPitchR"] = 0.82 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 0.05 * w + 0.48 * (1.0 - w)

		"jab_combo":
			p["pelvisYaw"] = -0.35 * coil + 0.45 * extend
			p["spineYaw"] = -0.28 * coil + 0.42 * extend
			p["spinePitch"] = -0.08 * coil + 0.22 * extend
			p["pelvisOffsetZ"] = 0.08 * extend
			p["armDownR"] = 1.12 - 0.18 * extend
			p["armFwdR"] = -0.35 * coil + 1.38 * extend + 0.35 * (1.0 - extend - coil)
			p["armCrossR"] = 0.25 * extend
			p["elbowBendR"] = 1.45 * coil + 0.12 * extend + 1.25 * (1.0 - extend - coil)
			p["armDownL"] = 1.15; p["armFwdL"] = 0.25 - 0.35 * extend; p["elbowBendL"] = 1.5
			p["hipPitchR"] = 0.32 * extend; p["kneeBendR"] = 0.42 * extend; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.15

		"side_roundhouse":
			if is_sans:
				p["pelvisYaw"] = -0.2 * coil + 0.35 * extend; p["spinePitch"] = -0.18 * extend
				p["armDownR"] = 0.85; p["armFwdR"] = 1.05 * extend + 0.4 * coil; p["armCrossR"] = 0.3; p["elbowBendR"] = 0.95 - 0.5 * extend
				p["armDownL"] = 0.92; p["armFwdL"] = 0.85 * extend + 0.35 * coil; p["armCrossL"] = 0.45; p["elbowBendL"] = 1.15
			else:
				p["pelvisYaw"] = -0.45 * coil + 0.65 * extend; p["pelvisRoll"] = 0.28 * extend; p["spinePitch"] = -0.24 * extend; p["spineYaw"] = 0.35 * extend
				p["hipPitchR"] = -0.35 * coil + 1.35 * extend; p["hipSplayR"] = 0.35 * extend; p["kneeBendR"] = 0.95 * coil + 0.08 * extend
				p["hipPitchL"] = -0.15 * extend; p["kneeBendL"] = 0.25; p["armDownR"] = 0.85; p["armFwdR"] = -0.25 * extend; p["elbowBendR"] = 0.85

		"uppercut_rising":
			p["pelvisOffsetY"] = -0.12 * coil + 0.16 * extend
			p["pelvisYaw"] = -0.35 * coil + 0.48 * extend
			p["spinePitch"] = 0.25 * coil - 0.28 * extend; p["spineYaw"] = 0.42 * extend; p["headPitch"] = -0.32 * extend
			p["armDownR"] = 1.25 * coil + 0.35 * extend + 1.08 * (1.0 - extend - coil)
			p["armFwdR"] = -0.25 * coil + 1.75 * extend; p["armCrossR"] = 0.22 * extend
			p["elbowBendR"] = 1.45 * coil + 0.35 * extend + 1.2 * (1.0 - extend - coil)
			p["hipPitchR"] = 0.45 * coil + 0.55 * extend; p["kneeBendR"] = 0.65 * coil + 0.72 * extend
			p["hipPitchL"] = 0.45 * coil - 0.15 * extend; p["kneeBendL"] = 0.65 * coil + 0.15 * extend

		"spiral_kick_low":
			if is_startup:
				p["pelvisOffsetY"] = -0.22 * startup_t; p["pelvisPitch"] = -PI * 0.48 * startup_t; p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.0; p["spineYaw"] = 0.0; p["headPitch"] = 0.0; p["headYaw"] = 0.0
				p["armDownR"] = 0.88 - 2.23 * startup_t; p["armDownL"] = 1.06 - 2.41 * startup_t
				p["armFwdR"] = 0.78 * (1.0 - startup_t); p["armFwdL"] = 0.16 * (1.0 - startup_t)
				p["armCrossR"] = 0.34 * (1.0 - startup_t) + 0.08 * startup_t; p["armCrossL"] = 0.52 * (1.0 - startup_t) + 0.08 * startup_t
				p["elbowBendR"] = 1.48 * (1.0 - startup_t) + 0.08 * startup_t; p["elbowBendL"] = 1.58 * (1.0 - startup_t) + 0.08 * startup_t
				p["hipPitchR"] = 0.36 * (1.0 - startup_t); p["kneeBendR"] = 0.48 * (1.0 - startup_t); p["hipSplayR"] = -0.22 * startup_t
				p["hipPitchL"] = -0.22 * (1.0 - startup_t); p["kneeBendL"] = 0.32 * (1.0 - startup_t); p["hipSplayL"] = -0.22 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = -0.26; p["pelvisOffsetZ"] = 0.18; p["pelvisPitch"] = -PI * 0.48; p["pelvisYaw"] = active_t * PI * 4.0
				p["pelvisRoll"] = 0.0; p["spinePitch"] = 0.0; p["spineYaw"] = 0.0; p["headPitch"] = 0.0; p["headYaw"] = 0.0
				p["armDownR"] = -1.35; p["armDownL"] = -1.35; p["armFwdR"] = 0.0; p["armFwdL"] = 0.0
				p["armCrossR"] = 0.08; p["armCrossL"] = 0.08; p["armRollR"] = 0.0; p["armRollL"] = 0.0; p["elbowBendR"] = 0.08; p["elbowBendL"] = 0.08
				p["hipPitchR"] = 0.0; p["kneeBendR"] = 0.0; p["hipSplayR"] = -0.22; p["hipPitchL"] = 0.0; p["kneeBendL"] = 0.0; p["hipSplayL"] = -0.22
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.26 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = -PI * 0.48 * w + 0.08 * (1.0 - w)

		"low_sweep":
			p["pelvisOffsetY"] = -0.18 * (coil + extend); p["pelvisPitch"] = 0.22 * extend
			p["pelvisYaw"] = -0.3 * coil + 0.55 * extend; p["spinePitch"] = 0.25 * extend
			p["hipPitchR"] = -0.25 * coil + 1.12 * extend; p["hipSplayR"] = 0.25 * extend; p["kneeBendR"] = 0.75 * coil + 0.08 * extend
			p["hipPitchL"] = 0.65 * (coil + extend); p["kneeBendL"] = 1.15 * (coil + extend)
			p["armDownR"] = 0.95; p["armFwdR"] = -0.35 * extend; p["armDownL"] = 0.85; p["armFwdL"] = 0.65 * extend

		"nair_spin":
			var spin_angle: float = (-0.3 * startup_t) if is_startup else ((active_t * PI * 2.0) if is_active else ((1.0 - recovery_t) * 0.4))
			p["pelvisYaw"] = spin_angle; p["armDownR"] = 0.55; p["armDownL"] = 0.55; p["elbowBendR"] = 0.45; p["elbowBendL"] = 0.45
			p["hipPitchR"] = 0.68 * extend; p["kneeBendR"] = 0.18; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.65

		"fair_cleave", "dair_meteor":
			var is_dair: bool = (atk.pose_style == "dair_meteor")
			p["spinePitch"] = -0.32 * coil + (0.52 if is_dair else 0.35) * extend
			p["headPitch"] = -0.25 * coil + 0.28 * extend
			p["armDownR"] = 0.45 * coil + (1.25 if is_dair else 0.95) * extend + 1.0 * (1.0 - extend - coil)
			p["armDownL"] = p["armDownR"]
			p["armFwdR"] = 1.65 * coil + (0.65 if is_dair else 1.15) * extend
			p["armFwdL"] = p["armFwdR"]
			p["armCrossR"] = 0.45 * (coil + extend); p["armCrossL"] = 0.45 * (coil + extend)
			p["elbowBendR"] = 0.55 * coil + 0.22 * extend + 1.1 * (1.0 - extend - coil); p["elbowBendL"] = p["elbowBendR"]
			p["hipPitchR"] = 0.55 * extend; p["kneeBendR"] = 0.85 * extend; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.45 * extend

		"fair_downward_punch":
			if is_startup:
				p["pelvisPitch"] = -0.15 * startup_t; p["pelvisYaw"] = -0.38 * startup_t; p["spinePitch"] = -0.22 * startup_t; p["spineYaw"] = -0.28 * startup_t
				p["headPitch"] = 0.22 * startup_t; p["headYaw"] = 0.18 * startup_t
				p["armDownR"] = 0.55 + 0.15 * startup_t; p["armFwdR"] = -0.55 * startup_t; p["armCrossR"] = -0.12 * startup_t; p["elbowBendR"] = 1.62 * startup_t + 0.45 * (1.0 - startup_t)
				p["armDownL"] = 0.85; p["armFwdL"] = 0.65 * startup_t; p["armCrossL"] = 0.18 * startup_t; p["elbowBendL"] = 0.72
				p["hipPitchR"] = 0.35 * startup_t; p["kneeBendR"] = 0.75 * startup_t; p["hipPitchL"] = -0.25 * startup_t; p["kneeBendL"] = 0.45 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = 0.04; p["pelvisPitch"] = 0.38; p["pelvisYaw"] = 0.42; p["pelvisRoll"] = -0.06
				p["spinePitch"] = 0.46; p["spineYaw"] = 0.35; p["headPitch"] = 0.38; p["headYaw"] = -0.15
				p["armDownR"] = 1.05; p["armFwdR"] = 1.25; p["armCrossR"] = 0.18; p["armRollR"] = -0.38; p["elbowBendR"] = 0.06
				p["armDownL"] = 1.15; p["armFwdL"] = -0.32; p["armCrossL"] = 0.22; p["elbowBendL"] = 1.45
				p["hipPitchR"] = 0.48; p["kneeBendR"] = 0.65; p["hipPitchL"] = -0.42; p["kneeBendL"] = 0.38
			else:
				var rt: float = recovery_t
				p["pelvisPitch"] = 0.38 * (1.0 - rt); p["pelvisYaw"] = 0.42 * (1.0 - rt); p["spinePitch"] = 0.46 * (1.0 - rt)
				p["armDownR"] = 1.05 * (1.0 - rt) + 0.85 * rt; p["armFwdR"] = 1.25 * (1.0 - rt) + 0.35 * rt; p["elbowBendR"] = 0.06 * (1.0 - rt) + 1.15 * rt

		"divekick_down_air":
			if is_startup:
				p["pelvisOffsetY"] = 0.08 * startup_t; p["pelvisPitch"] = 0.28 * startup_t; p["spinePitch"] = 0.22 * startup_t; p["headPitch"] = 0.18 * startup_t
				p["hipPitchR"] = -0.12 * startup_t; p["kneeBendR"] = 0.58 * startup_t; p["hipPitchL"] = 0.95 * startup_t; p["kneeBendL"] = 1.25 * startup_t
				p["armDownR"] = 0.85 - 1.35 * startup_t; p["armFwdR"] = 0.45 * startup_t; p["armCrossR"] = 0.18; p["elbowBendR"] = 1.38
				p["armDownL"] = 1.12; p["armFwdL"] = 0.25; p["armCrossL"] = 0.58; p["elbowBendL"] = 1.48
			elif is_active:
				p["pelvisOffsetY"] = 0.14; p["pelvisPitch"] = 0.62; p["pelvisYaw"] = 0.18; p["pelvisRoll"] = 0.04
				p["spinePitch"] = 0.38; p["spineYaw"] = 0.12; p["headPitch"] = 0.36; p["headYaw"] = -0.16
				p["hipPitchR"] = 0.92; p["kneeBendR"] = 0.03; p["hipSplayR"] = 0.04
				p["hipPitchL"] = 1.52; p["kneeBendL"] = 1.64; p["hipSplayL"] = -0.06
				p["armDownR"] = -0.58; p["armFwdR"] = 0.72; p["armCrossR"] = 0.24; p["armRollR"] = -0.42; p["elbowBendR"] = 1.48
				p["armDownL"] = 1.14; p["armFwdL"] = 0.34; p["armCrossL"] = 0.68; p["armRollL"] = -0.32; p["elbowBendL"] = 1.55
			else:
				p["pelvisOffsetY"] = -0.32 * (1.0 - recovery_t); p["pelvisPitch"] = 0.42 * (1.0 - recovery_t); p["spinePitch"] = 0.36 * (1.0 - recovery_t)
				p["hipPitchR"] = 1.15 * (1.0 - recovery_t); p["kneeBendR"] = 1.35 * (1.0 - recovery_t); p["hipPitchL"] = 0.92 * (1.0 - recovery_t); p["kneeBendL"] = 1.25 * (1.0 - recovery_t)

		"bair_backkick":
			p["pelvisYaw"] = 0.35 * coil - 0.85 * extend; p["spinePitch"] = 0.28 * extend; p["headYaw"] = -0.65 * extend
			p["hipPitchL"] = 0.45 * coil - 1.05 * extend; p["kneeBendL"] = 0.85 * coil + 0.08 * extend
			p["hipPitchR"] = 0.35 * extend; p["kneeBendR"] = 0.55 * extend
			p["armDownR"] = 0.78; p["armFwdR"] = 0.55 * extend; p["armDownL"] = 0.78; p["armFwdL"] = -0.45 * extend

		"uair_flipkick":
			p["pelvisPitch"] = 0.25 * coil - 0.65 * extend; p["spinePitch"] = -0.25 * extend
			p["hipPitchR"] = -0.35 * coil + 1.55 * extend; p["kneeBendR"] = 0.85 * coil + 0.10 * extend
			p["hipPitchL"] = -0.35 * extend; p["kneeBendL"] = 0.75 * extend; p["armDownR"] = 0.65; p["armDownL"] = 0.65

		"beam_charge_thrust":
			if is_startup:
				p["pelvisYaw"] = -0.48 * startup_t; p["spineYaw"] = -0.35 * startup_t; p["spinePitch"] = 0.14 * startup_t; p["pelvisOffsetY"] = -0.06 * startup_t
				p["armDownR"] = 1.15; p["armFwdR"] = -0.28 * startup_t; p["armCrossR"] = -0.25 * startup_t; p["elbowBendR"] = 1.25
				p["armDownL"] = 1.10; p["armFwdL"] = 0.25 * startup_t; p["armCrossL"] = 0.75 * startup_t; p["elbowBendL"] = 1.35
				p["hipPitchR"] = -0.18 * startup_t; p["kneeBendR"] = 0.35 * startup_t; p["hipPitchL"] = 0.28 * startup_t; p["kneeBendL"] = 0.42 * startup_t
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisYaw"] = 0.12 * w; p["spineYaw"] = 0.08 * w; p["spinePitch"] = 0.24 * w; p["pelvisOffsetZ"] = 0.10 * w
				p["armDownR"] = 1.12; p["armFwdR"] = 1.38 * w + 0.35 * (1.0 - w); p["armCrossR"] = 0.42 * w + 0.35 * (1.0 - w); p["elbowBendR"] = 0.14 * w + 1.25 * (1.0 - w)
				p["armDownL"] = 1.12; p["armFwdL"] = 1.38 * w + 0.35 * (1.0 - w); p["armCrossL"] = 0.42 * w + 0.35 * (1.0 - w); p["elbowBendL"] = 0.14 * w + 1.25 * (1.0 - w)
				p["hipPitchR"] = 0.35 * w; p["kneeBendR"] = 0.48 * w; p["hipPitchL"] = -0.28 * w; p["kneeBendL"] = 0.18 * w

		"lunge_burst":
			p["pelvisPitch"] = 0.18 * extend; p["pelvisYaw"] = -0.35 * coil + 0.45 * extend; p["spinePitch"] = 0.28 * extend; p["spineYaw"] = 0.32 * extend
			p["armDownR"] = 1.05; p["armFwdR"] = -0.4 * coil + 1.42 * extend; p["armCrossR"] = 0.28 * extend; p["elbowBendR"] = 1.35 * coil + 0.15 * extend
			p["armDownL"] = 0.95; p["armFwdL"] = -0.35 * extend; p["elbowBendL"] = 0.95
			p["hipPitchR"] = 0.65 * extend; p["kneeBendR"] = 0.75 * extend; p["hipPitchL"] = -0.45 * extend; p["kneeBendL"] = 0.20

		"up_somersault_vortex":
			if is_startup:
				p["pelvisOffsetY"] = -0.14 * startup_t; p["pelvisPitch"] = 0.28 * startup_t; p["pelvisYaw"] = 0.15 * (1.0 - startup_t)
				p["spinePitch"] = 0.36 * startup_t; p["headPitch"] = 0.22 * startup_t
				p["hipPitchR"] = 0.36 + 1.12 * startup_t; p["kneeBendR"] = 0.48 + 1.18 * startup_t; p["hipSplayR"] = -0.15 * startup_t
				p["hipPitchL"] = -0.22 + 1.70 * startup_t; p["kneeBendL"] = 0.32 + 1.34 * startup_t; p["hipSplayL"] = -0.15 * startup_t
				p["armDownR"] = 1.08; p["armFwdR"] = 0.52 * startup_t; p["armCrossR"] = 0.22; p["elbowBendR"] = 1.48
				p["armDownL"] = 1.08; p["armFwdL"] = 0.52 * startup_t; p["armCrossL"] = 0.22; p["elbowBendL"] = 1.48
			elif is_active:
				p["pelvisOffsetY"] = 0.16; p["pelvisPitch"] = active_t * PI * 2.0; p["pelvisYaw"] = 0.08
				p["spinePitch"] = 0.54; p["headPitch"] = 0.26; p["headYaw"] = -0.08
				p["hipPitchR"] = 1.54; p["kneeBendR"] = 1.66; p["hipSplayR"] = -0.18
				p["hipPitchL"] = 1.54; p["kneeBendL"] = 1.66; p["hipSplayL"] = -0.18
				p["armDownR"] = 1.08; p["armFwdR"] = 0.52; p["armCrossR"] = 0.22; p["armRollR"] = -0.48; p["elbowBendR"] = 1.48
				p["armDownL"] = 1.08; p["armFwdL"] = 0.52; p["armCrossL"] = 0.22; p["armRollL"] = -0.48; p["elbowBendL"] = 1.48
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = 0.16 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = 0.12 * w + 0.08 * (1.0 - w)

		"up_special_followup_punch":
			if is_startup:
				p["pelvisOffsetY"] = 0.14; p["pelvisYaw"] = -0.54 * startup_t; p["spineYaw"] = -0.46 * startup_t; p["spinePitch"] = -0.12 * startup_t; p["headYaw"] = 0.52 * startup_t
				p["armDownR"] = 1.04; p["armFwdR"] = -0.58 * startup_t; p["armCrossR"] = -0.22 * startup_t; p["elbowBendR"] = 1.52
				p["armDownL"] = 1.02; p["armFwdL"] = 1.15 * startup_t; p["armCrossL"] = 0.25; p["elbowBendL"] = 0.35
				p["hipPitchL"] = 0.72 * startup_t; p["kneeBendL"] = 1.12 * startup_t; p["hipPitchR"] = -0.35 * startup_t; p["kneeBendR"] = 0.45
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisOffsetY"] = 0.14 * w - 0.05 * (1.0 - w); p["pelvisOffsetZ"] = 0.16 * w
				p["pelvisYaw"] = 0.64 * w + 0.42 * (1.0 - w); p["spineYaw"] = 0.58 * w - 0.18 * (1.0 - w); p["spinePitch"] = 0.28 * w + 0.14 * (1.0 - w); p["headYaw"] = -0.72 * w - 0.24 * (1.0 - w)
				p["armDownR"] = 1.12 * w + 0.88 * (1.0 - w); p["armFwdR"] = 1.48 * w + 0.78 * (1.0 - w); p["armCrossR"] = 0.24 * w + 0.34 * (1.0 - w); p["armRollR"] = -0.35; p["elbowBendR"] = 0.06 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 0.78 * w + 1.06 * (1.0 - w); p["armFwdL"] = -0.52 * w + 0.16 * (1.0 - w); p["armCrossL"] = -0.18 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.42 * w + 1.58 * (1.0 - w)

		"down_special_elbow_lift":
			if is_startup:
				p["pelvisOffsetY"] = -0.18 * startup_t; p["pelvisOffsetZ"] = 0.12 * startup_t; p["pelvisYaw"] = 0.42 + 0.44 * startup_t
				p["spineYaw"] = -0.18 + 0.56 * startup_t; p["spinePitch"] = 0.14 + 0.12 * startup_t; p["headYaw"] = -0.24 - 0.38 * startup_t
				p["hipPitchR"] = 0.36 + 0.36 * startup_t; p["kneeBendR"] = 0.48 + 0.48 * startup_t; p["hipPitchL"] = -0.22 - 0.36 * startup_t; p["kneeBendL"] = 0.24
				p["armDownR"] = 0.88 - 0.44 * startup_t; p["armFwdR"] = 0.78 + 0.64 * startup_t; p["armCrossR"] = 0.34 + 0.06 * startup_t; p["elbowBendR"] = 1.48 + 0.22 * startup_t
				p["armDownL"] = 1.05; p["armFwdL"] = 0.16 - 0.62 * startup_t; p["armCrossL"] = 0.52 - 0.74 * startup_t; p["elbowBendL"] = 1.48
			elif is_active:
				var lift_t: float = _smoothstep(0.58, 1.0, active_t)
				p["pelvisOffsetY"] = -0.18 + 0.08 * lift_t; p["pelvisOffsetZ"] = 0.18 - 0.06 * lift_t
				p["pelvisYaw"] = 0.86 - 0.24 * lift_t; p["spineYaw"] = 0.38 - 0.16 * lift_t; p["spinePitch"] = 0.26 - 0.12 * lift_t; p["spineRoll"] = 0.14 * (1.0 - lift_t)
				p["headYaw"] = -0.62 + 0.22 * lift_t; p["headPitch"] = -0.14
				p["hipPitchR"] = 0.72 - 0.14 * lift_t; p["kneeBendR"] = 0.96 - 0.12 * lift_t; p["hipSplayR"] = -0.12
				p["hipPitchL"] = -0.58 + 0.25 * lift_t; p["kneeBendL"] = 0.22 + 0.28 * lift_t; p["hipSplayL"] = -0.12
				p["armDownR"] = 0.44 - 0.14 * lift_t; p["armFwdR"] = 1.42 + 0.12 * lift_t; p["armCrossR"] = 0.40 - 0.18 * lift_t; p["armRollR"] = 0.32; p["elbowBendR"] = 1.70 - 0.15 * lift_t
				p["armDownL"] = 1.05; p["armFwdL"] = -0.46 + 0.22 * lift_t; p["armCrossL"] = -0.22 + 0.18 * lift_t; p["elbowBendL"] = 1.48
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.10 * w - 0.05 * (1.0 - w); p["pelvisYaw"] = 0.62 * w + 0.42 * (1.0 - w)

		"down_special_turn_kick":
			if is_startup:
				var turn_ease: float = _smoothstep(0.0, 1.0, startup_t)
				var knee_chamber: float = sin(startup_t * PI * 0.75)
				p["pelvisOffsetY"] = -0.08 * (1.0 - turn_ease) - 0.06 * turn_ease; p["pelvisOffsetZ"] = 0.12 * turn_ease
				p["pelvisPitch"] = -0.38 * turn_ease; p["pelvisYaw"] = 0.76 * turn_ease; p["pelvisRoll"] = -0.52 * turn_ease
				p["spinePitch"] = -0.28 * turn_ease; p["spineYaw"] = 0.36 * turn_ease; p["spineRoll"] = -0.38 * turn_ease
				p["headPitch"] = 0.22 * turn_ease; p["headYaw"] = -0.48 * turn_ease
				p["hipPitchL"] = 1.38 * turn_ease; p["kneeBendL"] = 1.15 * knee_chamber * (1.0 - 0.65 * turn_ease) + 0.12 * turn_ease; p["hipSplayL"] = 0.38 * turn_ease
				p["hipPitchR"] = 0.58; p["kneeBendR"] = 0.84 + 0.42 * turn_ease; p["hipSplayR"] = -0.20 * turn_ease
				p["armDownR"] = 0.32 * (1.0 - turn_ease) + 0.72 * turn_ease; p["armFwdR"] = 1.35 * (1.0 - turn_ease) - 0.28 * turn_ease; p["armCrossR"] = 0.22 * (1.0 - turn_ease) - 0.52 * turn_ease; p["elbowBendR"] = 1.55 * (1.0 - turn_ease) + 0.22 * turn_ease
				p["armDownL"] = 1.02 * (1.0 - turn_ease) + 0.82 * turn_ease; p["armFwdL"] = -0.24 * (1.0 - turn_ease) + 0.95 * turn_ease; p["armCrossL"] = 0.38 * turn_ease; p["elbowBendL"] = 1.45 * (1.0 - turn_ease) + 1.18 * turn_ease
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisOffsetY"] = -0.06 * w - 0.05 * (1.0 - w); p["pelvisOffsetZ"] = 0.14 * w
				p["pelvisPitch"] = -0.38 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = 0.76 * w + 0.42 * (1.0 - w); p["pelvisRoll"] = -0.52 * w
				p["spinePitch"] = -0.28 * w + 0.14 * (1.0 - w); p["spineYaw"] = 0.36 * w - 0.18 * (1.0 - w); p["spineRoll"] = -0.38 * w
				p["headPitch"] = 0.22 * w + 0.06 * (1.0 - w); p["headYaw"] = -0.48 * w - 0.24 * (1.0 - w)
				p["hipPitchL"] = 1.52 * w - 0.22 * (1.0 - w); p["kneeBendL"] = 0.06 * w + 0.32 * (1.0 - w); p["hipSplayL"] = 0.42 * w - 0.05 * (1.0 - w)
				p["hipPitchR"] = 0.58 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 1.26 * w + 0.48 * (1.0 - w); p["hipSplayR"] = -0.22 * w - 0.05 * (1.0 - w)
				p["armDownR"] = 0.72 * w + 0.88 * (1.0 - w); p["armFwdR"] = -0.28 * w + 0.78 * (1.0 - w); p["armCrossR"] = -0.52 * w + 0.34 * (1.0 - w); p["elbowBendR"] = 0.22 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 0.82 * w + 1.06 * (1.0 - w); p["armFwdL"] = 0.95 * w + 0.16 * (1.0 - w); p["armCrossL"] = 0.38 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.18 * w + 1.58 * (1.0 - w)

		"warp_ascend":
			p["pelvisOffsetY"] = -0.10 * coil + 0.14 * extend; p["spinePitch"] = -0.15 * extend
			p["armDownR"] = 1.05 * coil + 0.45 * extend; p["armFwdR"] = 0.95 * coil + 1.65 * extend; p["armCrossR"] = 0.55 * coil + 0.15 * extend; p["elbowBendR"] = 1.65 * coil + 0.25 * extend
			p["armDownL"] = 0.85; p["armFwdL"] = 0.45 * extend; p["elbowBendL"] = 1.05
			p["hipPitchR"] = 0.55 * extend; p["kneeBendR"] = 0.85 * extend; p["hipPitchL"] = 0.20 * extend; p["kneeBendL"] = 0.35 * extend

		"counter_stance", _:
			p["pelvisOffsetY"] = -0.08 * (coil + extend); p["spinePitch"] = -0.15 * coil + 0.22 * extend
			p["armDownR"] = 0.75 * coil + 0.95 * extend + 1.1 * (1.0 - extend - coil); p["armDownL"] = p["armDownR"]
			p["armFwdR"] = 1.35 * coil + 0.85 * extend; p["armFwdL"] = p["armFwdR"]
			p["armCrossR"] = 0.55 * coil - 0.25 * extend; p["armCrossL"] = p["armCrossR"]
			p["elbowBendR"] = 1.25 * coil + 0.35 * extend + 1.2 * (1.0 - extend - coil); p["elbowBendL"] = p["elbowBendR"]
			p["hipPitchR"] = 0.28 * extend; p["kneeBendR"] = 0.42 * extend; p["hipPitchL"] = 0.22 * extend; p["kneeBendL"] = 0.38 * extend

# ============================================================================
# SOLVER DE 12 HUESOS DE GOGETA SSJ
# ============================================================================
func _apply_gogeta_pose(p: Dictionary, t: float) -> void:
	if skeleton == null:
		return
	var b_pelvis: int = _gogeta_bones.get("Pelvis", -1)
	if b_pelvis != -1:
		skeleton.set_bone_pose_position(b_pelvis, Vector3(0.0, 0.90 + float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"])))
		skeleton.set_bone_pose_rotation(b_pelvis, _quat_euler_xyz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))
	var b_spine: int = _gogeta_bones.get("Spine", -1)
	if b_spine != -1:
		skeleton.set_bone_pose_rotation(b_spine, _quat_euler_yxz(p["spinePitch"], p["spineYaw"], p["spineRoll"]))
	var b_head: int = _gogeta_bones.get("Head", -1)
	if b_head != -1:
		skeleton.set_bone_pose_rotation(b_head, _quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))
	var b_sh_r: int = _gogeta_bones.get("ShoulderR", -1)
	if b_sh_r != -1:
		skeleton.set_bone_pose_rotation(b_sh_r, _build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	var b_el_r: int = _gogeta_bones.get("ElbowR", -1)
	if b_el_r != -1:
		skeleton.set_bone_pose_rotation(b_el_r, Quaternion(Vector3.UP, float(p["elbowBendR"])))
	var b_sh_l: int = _gogeta_bones.get("ShoulderL", -1)
	if b_sh_l != -1:
		skeleton.set_bone_pose_rotation(b_sh_l, _build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	var b_el_l: int = _gogeta_bones.get("ElbowL", -1)
	if b_el_l != -1:
		skeleton.set_bone_pose_rotation(b_el_l, Quaternion(Vector3.UP, -float(p["elbowBendL"])))
	var b_hip_r: int = _gogeta_bones.get("HipR", -1)
	if b_hip_r != -1:
		skeleton.set_bone_pose_rotation(b_hip_r, _quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	var b_knee_r: int = _gogeta_bones.get("KneeR", -1)
	if b_knee_r != -1:
		skeleton.set_bone_pose_rotation(b_knee_r, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))
	var b_hip_l: int = _gogeta_bones.get("HipL", -1)
	if b_hip_l != -1:
		skeleton.set_bone_pose_rotation(b_hip_l, _quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	var b_knee_l: int = _gogeta_bones.get("KneeL", -1)
	if b_knee_l != -1:
		skeleton.set_bone_pose_rotation(b_knee_l, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))
	var b_sash: int = _gogeta_bones.get("Sash", -1)
	if b_sash != -1:
		var is_hover_dash: bool = (active_state_name == "Run")
		var sash_wave_z: float = (sin(t * 11.5) * 0.14 + 0.12) if is_hover_dash else (sin(t * 5.2) * 0.08 + 0.06)
		var sash_pitch: float = (0.42 + cos(t * 11.0) * 0.10) if is_hover_dash else (-float(p["hipPitchR"]) * 0.55 + cos(t * 4.5) * 0.06)
		skeleton.set_bone_pose_rotation(b_sash, _quat_euler_xyz(sash_pitch, 0.0, -sash_wave_z))

# ============================================================================
# SOLVER ESQUELÉTICO EN ESPACIO DE PERSONAJE DE SANS (APPLY_SANS_POSE)
# ============================================================================
func _set_sans_bone_char_quat(bone_name: String, q_char: Quaternion) -> void:
	if not _sans_bindings.has(bone_name) or skeleton == null:
		return
	var bd: Dictionary = _sans_bindings[bone_name]
	var local_delta: Quaternion = bd["inv_char_rest"] * q_char * bd["char_rest"]
	skeleton.set_bone_pose_rotation(bd["idx"], (bd["local_rest"] * local_delta).normalized())

func _apply_sans_pose(p: Dictionary) -> void:
	if skeleton == null:
		return
	for b_name in _sans_bindings.keys():
		var bd: Dictionary = _sans_bindings[b_name]
		skeleton.set_bone_pose_rotation(bd["idx"], bd["local_rest"])

	_set_sans_bone_char_quat("Root", _quat_euler_yxz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))
	var q_spine := _quat_euler_yxz(float(p["spinePitch"]) * 0.5, float(p["spineYaw"]) * 0.5, float(p["spineRoll"]) * 0.5)
	_set_sans_bone_char_quat("Spine", q_spine)
	_set_sans_bone_char_quat("Spine_1", q_spine)
	_set_sans_bone_char_quat("Head", _quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))

	_set_sans_bone_char_quat("UpperarmR", _build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	_set_sans_bone_char_quat("ForearmR", Quaternion(Vector3.UP, float(p["elbowBendR"])))

	_set_sans_bone_char_quat("UpperarmL", _build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	_set_sans_bone_char_quat("ForearmL", Quaternion(Vector3.UP, -float(p["elbowBendL"])))

	_set_sans_bone_char_quat("ThighR", _quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	_set_sans_bone_char_quat("CalfR", Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))
	_set_sans_bone_char_quat("FootR", Quaternion(Vector3.RIGHT, (float(p["hipPitchR"]) - float(p["kneeBendR"])) * 0.45))

	_set_sans_bone_char_quat("ThighL", _quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	_set_sans_bone_char_quat("CalfL", Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))
	_set_sans_bone_char_quat("FootL", Quaternion(Vector3.RIGHT, (float(p["hipPitchL"]) - float(p["kneeBendL"])) * 0.45))

	if model_root != null and _character and "character_data" in _character and _character.character_data:
		var base_off: Vector3 = _character.character_data.model_offset
		model_root.position = base_off + Vector3(0.0, float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"]))

# ============================================================================
# 11 VFX 3D DE COMBATE (GOGETA + SANS)
# ============================================================================
func _build_combat_vfx_nodes() -> void:
	if _character == null:
		return
	var humanoid: Node3D = _character.get_node_or_null("Humanoid") as Node3D
	if humanoid == null:
		return
	var old_vfx: Node = humanoid.get_node_or_null("CombatVfxGroup")
	if old_vfx:
		old_vfx.queue_free()

	vfx_group = Node3D.new()
	vfx_group.name = "CombatVfxGroup"
	humanoid.add_child(vfx_group)

	_slash_arc_mesh = _create_torus_mesh(0.68, 0.08, Color(0.98, 0.75, 0.14, 0.88))
	_charge_ring_mesh = _create_torus_mesh(0.45, 0.025, Color(0.98, 0.75, 0.14, 0.75))
	_stardust_orb_mesh = _create_sphere_mesh(0.65, Color(0.98, 0.75, 0.14, 0.82))
	_beam_group = _create_beam_group()
	_bone_pillar_group = _create_bone_pillar_group()
	_spiral_vortex_group = _create_spiral_vortex_group()
	_ki_knee_cone_group = _create_ki_knee_cone_group()
	_somersault_vortex_group = _create_somersault_vortex_group()
	_elbow_slash_beam_group = _create_elbow_slash_beam_group()
	_kick_crescent_arc_group = _create_kick_crescent_arc_group()
	_divekick_vfx_group = _create_divekick_vfx_group()

	for node in [
		_slash_arc_mesh, _charge_ring_mesh, _stardust_orb_mesh, _beam_group, _bone_pillar_group,
		_spiral_vortex_group, _ki_knee_cone_group, _somersault_vortex_group,
		_elbow_slash_beam_group, _kick_crescent_arc_group, _divekick_vfx_group
	]:
		node.visible = false
		vfx_group.add_child(node)

func _hide_all_combat_vfx() -> void:
	if vfx_group == null:
		return
	for child in vfx_group.get_children():
		if child is Node3D:
			child.visible = false

func _update_combat_vfx(elapsed: float) -> void:
	if vfx_group == null:
		return
	_hide_all_combat_vfx()

	if is_gogeta and active_state_name == "Run":
		_charge_ring_mesh.visible = true
		_charge_ring_mesh.position = Vector3(0.0, 0.95, -0.22)
		var pulse: float = 0.65 + sin(elapsed * 18.0) * 0.12
		_charge_ring_mesh.scale = Vector3.ONE * pulse
		_charge_ring_mesh.rotation = Vector3(0.35, 0.0, elapsed * 12.0)
		return

	if active_state_name != "Attack" or active_attack == null:
		return

	if active_attack.vfx_type == "" or active_attack.vfx_type == "none":
		return

	var off_x: float = active_attack.hitbox_offset.x
	var off_y: float = active_attack.hitbox_offset.y
	var rad: float = active_attack.hitbox_radius if active_attack.hitbox_radius > 0.0 else 0.75

	if attack_phase == "startup":
		_charge_ring_mesh.visible = true
		_charge_ring_mesh.position = Vector3(0.0, off_y, 0.25)
		var s: float = 0.35 + sin(elapsed * 25.0) * 0.12
		_charge_ring_mesh.scale = Vector3.ONE * s
		_charge_ring_mesh.rotation = Vector3(0.0, 0.0, elapsed * 10.0)
		return

	if attack_phase != "active":
		return

	match active_attack.vfx_type:
		"spiral_vortex":
			_spiral_vortex_group.visible = true
			_spiral_vortex_group.position = Vector3(0.0, 0.68, 0.12)
			_spiral_vortex_group.rotation = Vector3(0.0, 0.0, elapsed * 32.0)
		"somersault_vortex_blue":
			_somersault_vortex_group.visible = true
			_somersault_vortex_group.position = Vector3(0.0, 1.08, 0.08)
			_somersault_vortex_group.rotation = Vector3(0.0, PI * 0.5, -elapsed * 26.0)
			_somersault_vortex_group.scale = Vector3.ONE * (1.0 + sin(elapsed * 38.0) * 0.06)
		"diagonal_elbow_slash_blue":
			_elbow_slash_beam_group.visible = true
			_elbow_slash_beam_group.position = Vector3(-0.08, 0.96, 0.16)
			_elbow_slash_beam_group.rotation = Vector3(-0.82, 0.0, 0.10)
			var p: float = 1.0 + sin(elapsed * 36.0) * 0.12
			_elbow_slash_beam_group.scale = Vector3(p, 1.05, p)
		"crescent_kick_arc_blue":
			_kick_crescent_arc_group.visible = true
			_kick_crescent_arc_group.position = Vector3(0.0, 1.18, 0.24)
			_kick_crescent_arc_group.rotation = Vector3(0.12, PI * 0.5, 0.35 - elapsed * 6.5)
			var p: float = 1.0 + sin(elapsed * 30.0) * 0.06
			_kick_crescent_arc_group.scale = Vector3(p, p, 1.15)
		"ki_divekick_trail":
			_divekick_vfx_group.visible = true
			_divekick_vfx_group.position = Vector3(-0.16, 0.32, 0.52)
			_divekick_vfx_group.rotation = Vector3(0.72, 0.0, -0.06)
			var p: float = 1.0 + sin(elapsed * 38.0) * 0.08
			_divekick_vfx_group.scale = Vector3(p, p, 1.18)
		"ki_knee_cone":
			_ki_knee_cone_group.visible = true
			_ki_knee_cone_group.position = Vector3(0.0, 1.12, 0.55)
			_ki_knee_cone_group.rotation = Vector3(0.0, 0.0, elapsed * 26.0)
			var p: float = 1.0 + sin(elapsed * 40.0) * 0.10
			_ki_knee_cone_group.scale = Vector3(p, p, 1.15)
		"ki_knee_rising":
			_ki_knee_cone_group.visible = true
			_ki_knee_cone_group.position = Vector3(0.0, 1.38, 0.42)
			_ki_knee_cone_group.rotation = Vector3(-0.85, 0.0, elapsed * 28.0)
			var p: float = 1.0 + sin(elapsed * 42.0) * 0.12
			_ki_knee_cone_group.scale = Vector3(p, p, 1.25)
		"axe_crescent_blue":
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.22, 0.74, 0.97, 0.90))
			_slash_arc_mesh.position = Vector3(0.0, 1.25, 0.78)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -0.35 - elapsed * 14.0)
			_slash_arc_mesh.scale = Vector3(1.48, 1.48, 1.85)
		"downward_punch_arc":
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.90))
			_slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.85)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -1.05 - elapsed * 6.0)
			_slash_arc_mesh.scale = Vector3(rad * 1.35, rad * 1.35, rad * 1.45)
		"ki_beam", "gaster_beam":
			_beam_group.visible = true
			_beam_group.position = Vector3(0.0, off_y, 0.65)
			_beam_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
			var p: float = 1.0 + sin(elapsed * 45.0) * 0.18
			_beam_group.scale = Vector3(1.0, p, p)
		"bone_spike":
			_bone_pillar_group.visible = true
			_bone_pillar_group.position = Vector3(0.0, maxf(0.2, off_y - 0.35), off_x)
			_bone_pillar_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
		"stardust_orb", "gravity_slam", "teleport_burst":
			_stardust_orb_mesh.visible = true
			_stardust_orb_mesh.position = Vector3(0.0, off_y, off_x)
			_stardust_orb_mesh.scale = Vector3.ONE * (rad * (0.85 + sin(elapsed * 30.0) * 0.15))
			_set_mesh_color(_stardust_orb_mesh, Color(0.15, 0.39, 0.92, 0.82) if active_attack.vfx_type == "gravity_slam" else Color(0.98, 0.75, 0.14, 0.82))
		_:
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.88) if active_attack.vfx_type == "slash_gold" else Color(0.22, 0.74, 0.97, 0.88))
			_slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.75)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, deg_to_rad(active_attack.angle_degrees - 45.0) + elapsed * 8.0)
			_slash_arc_mesh.scale = Vector3.ONE * (rad * 1.15)

# ============================================================================
# INYECCIÓN AUTOMÁTICA 1:1 DE MOVESETS DE GOGETA_DATA.TS Y SANS_DATA.TS
# ============================================================================
func _inject_gogeta_moveset() -> void:
	if _character == null or not ("character_data" in _character) or _character.character_data == null:
		return
	var moveset = _character.character_data.moveset
	if moveset == null:
		return

	var jab3 := _make_atk("gogeta_jab_3", "Jab 3: Doble Mazo y Voltereta (3/3)", "AttackNeutral3", "jab_axe_vault", "slash_gold", 11.5, 8.2, 0.15, 42.0, 8, 7, 16, Vector2(1.05, 1.05), 0.78, Vector2(5.4, 5.8), 2)
	jab3.vault_behind_on_hit = true
	var jab2 := _make_atk("gogeta_jab_2", "Jab 2: Golpe al Estómago (2/3)", "AttackNeutral2", "jab_gut_upper", "slash_gold", 6.5, 2.8, 0.03, 68.0, 5, 7, 11, Vector2(0.98, 1.32), 0.72, Vector2(3.2, 0.0), 3)
	jab2.combo_next = jab3
	var jab1 := _make_atk("gogeta_jab_1", "Jab 1: Dos Golpes Rápidos (1/3)", "AttackNeutral", "jab_double_strike", "slash_gold", 3.5, 2.2, 0.02, 25.0, 3, 9, 10, Vector2(0.98, 1.18), 0.68, Vector2(2.4, 0.0), 2)
	jab1.second_hit_frame = 8
	jab1.combo_next = jab2

	var side_tilt := _make_atk("gogeta_side_tilt", "Fusion Spin Kick", "AttackSide", "side_roundhouse", "slash_gold", 11.0, 7.2, 0.14, 32.0, 8, 6, 14, Vector2(1.2, 1.15), 0.72, Vector2(4.5, 0.0), 6)
	var up_tilt := _make_atk("gogeta_up_tilt", "Rising Dragon Upper", "AttackUp", "uppercut_rising", "slash_gold", 9.5, 6.8, 0.13, 84.0, 6, 7, 12, Vector2(0.45, 1.95), 0.75, Vector2.ZERO, 0)
	var down_tilt := _make_atk("gogeta_down_tilt", "Patada Voladora en Espiral", "AttackDown", "spiral_kick_low", "spiral_vortex", 9.5, 6.4, 0.12, 62.0, 6, 11, 12, Vector2(1.15, 0.62), 0.76, Vector2(8.8, 1.4), 4)

	var nair := _make_atk("gogeta_nair", "Aura Vortex Spin", "NeutralAir", "nair_spin", "slash_gold", 9.0, 5.8, 0.11, 45.0, 5, 10, 9, Vector2(0.0, 1.15), 1.05, Vector2.ZERO, 0, true)
	var fair := _make_atk("gogeta_fair", "Forward Air: Puño Descendente", "ForwardAir", "fair_downward_punch", "downward_punch_arc", 12.0, 7.8, 0.15, 295.0, 7, 6, 12, Vector2(1.18, 0.88), 0.84, Vector2(2.2, 0.6), 2, true)
	var bair := _make_atk("gogeta_bair", "Reverse Heel Thrust", "BackAir", "bair_backkick", "slash_gold", 14.0, 8.2, 0.17, 148.0, 9, 5, 14, Vector2(-1.15, 1.15), 0.74, Vector2.ZERO, 0, true)
	var uair := _make_atk("gogeta_uair", "Somersault Flash Kick", "UpAir", "uair_flipkick", "slash_gold", 11.5, 7.0, 0.14, 88.0, 7, 7, 11, Vector2(0.15, 2.1), 0.80, Vector2.ZERO, 0, true)
	var dair := _make_atk("gogeta_dair", "Down Air: Meteor Divekick", "DownAir", "divekick_down_air", "ki_divekick_trail", 13.5, 8.4, 0.16, 295.0, 7, 24, 11, Vector2(0.96, 0.18), 0.95, Vector2.ZERO, 0, true)
	dair.is_divekick = true
	dair.landing_lag_frames = 9
	dair.sliding_knockdown = true

	var neutral_sp := _make_atk("gogeta_neutral_special", "Big Bang Kamehameha", "SpecialNeutral", "beam_charge_thrust", "ki_beam", 16.5, 9.0, 0.18, 30.0, 12, 10, 16, Vector2(1.95, 1.25), 1.15, Vector2.ZERO, 0)
	var rekka3 := _make_atk("gogeta_side_special_3", "Rekka 3: Patada de Hacha (3/3)", "SpecialSide3", "rekka_axe_kick", "", 13.5, 8.8, 0.16, 285.0, 7, 7, 15, Vector2(1.08, 1.15), 0.92, Vector2(2.2, -8.5), 7)
	rekka3.snap_in_front_of_opponent = true
	var rekka2 := _make_atk("gogeta_side_special_2", "Rekka 2: Rodillazo en Salto (2/3)", "SpecialSide2", "rekka_knee_rising", "", 8.5, 5.2, 0.06, 76.0, 5, 9, 13, Vector2(0.95, 1.48), 0.84, Vector2(4.8, 11.2), 2)
	rekka2.combo_next = rekka3
	var rekka1 := _make_atk("gogeta_side_special_1", "Rekka 1: Rodillazo Volador (1/3)", "SpecialSide", "rekka_knee_dash", "", 7.5, 3.6, 0.04, 38.0, 6, 9, 13, Vector2(1.18, 1.12), 0.86, Vector2(11.4, 1.2), 2)
	rekka1.combo_next = rekka2

	var up_sp_punch := _make_atk("gogeta_up_special_punch", "Up Special: Piña Explosiva (Remate)", "SpecialUp2", "up_special_followup_punch", "slash_gold", 10.5, 9.2, 0.17, 36.0, 5, 6, 14, Vector2(1.05, 1.25), 0.96, Vector2(2.6, 2.4), 1)
	var up_sp := _make_atk("gogeta_up_special", "Up Special: Voltereta en Diagonal", "SpecialUp", "up_somersault_vortex", "somersault_vortex_blue", 5.5, 3.4, 0.03, 68.0, 5, 12, 13, Vector2(0.35, 1.12), 1.12, Vector2(6.4, 13.5), 3)
	up_sp.second_hit_frame = 11
	up_sp.drag_defender_on_hit = true
	up_sp.auto_followup_on_hit = up_sp_punch

	var down_sp_kick := _make_atk("gogeta_down_special_kick", "Down Special (2/2): Giro y Patada", "SpecialDown2", "down_special_turn_kick", "", 11.5, 9.8, 0.19, 28.0, 13, 16, 18, Vector2(1.25, 1.22), 1.12, Vector2(2.4, 2.2), 4)
	down_sp_kick.flip_facing_on_start = true
	var down_sp_elbow := _make_atk("gogeta_down_special", "Down Special (1/2): Codazo Cambia-Lado", "SpecialDown", "down_special_elbow_lift", "", 6.0, 3.2, 0.02, 115.0, 9, 18, 12, Vector2(1.08, 1.15), 1.05, Vector2(7.8, 0.0), 2)
	down_sp_elbow.toss_behind_on_hit = true
	down_sp_elbow.auto_followup_on_hit = down_sp_kick
	down_sp_elbow.auto_followup_always = true
	down_sp_elbow.combo_next = down_sp_kick

	_assign_moveset_slots(moveset, jab1, side_tilt, up_tilt, down_tilt, nair, fair, bair, uair, dair, neutral_sp, rekka1, up_sp, down_sp_elbow)

func _inject_sans_moveset() -> void:
	if _character == null or not ("character_data" in _character) or _character.character_data == null:
		return
	var moveset = _character.character_data.moveset
	if moveset == null:
		return

	var jab := _make_atk("sans_jab", "Bone Pop Jab", "AttackNeutral", "jab_combo", "bone_spike", 5.5, 4.2, 0.08, 40.0, 4, 6, 9, Vector2(0.95, 1.0), 0.62, Vector2.ZERO, 0)
	var side_tilt := _make_atk("sans_side_tilt", "Trombone Slide Riff", "AttackSide", "side_roundhouse", "trombone_wave", 10.5, 6.8, 0.13, 34.0, 7, 7, 12, Vector2(1.25, 1.05), 0.78, Vector2.ZERO, 0)
	var up_tilt := _make_atk("sans_up_tilt", "Ceiling Bone Pillar", "AttackUp", "uppercut_rising", "bone_spike", 9.0, 6.5, 0.13, 86.0, 6, 7, 11, Vector2(0.35, 1.85), 0.76, Vector2.ZERO, 0)
	var down_tilt := _make_atk("sans_down_tilt", "Floor Bone Trap", "AttackDown", "low_sweep", "bone_spike", 8.5, 5.8, 0.12, 76.0, 5, 6, 11, Vector2(1.15, 0.4), 0.70, Vector2.ZERO, 0)

	var nair := _make_atk("sans_nair", "Spinning Bone Orbit", "NeutralAir", "nair_spin", "slash_blue", 8.5, 5.6, 0.11, 45.0, 5, 10, 9, Vector2(0.0, 0.95), 1.05, Vector2.ZERO, 0, true)
	var fair := _make_atk("sans_fair", "Blue Bone Swing", "ForwardAir", "fair_cleave", "slash_blue", 11.5, 7.2, 0.14, 36.0, 7, 6, 12, Vector2(1.15, 1.0), 0.76, Vector2.ZERO, 0, true)
	var bair := _make_atk("sans_bair", "Shortcut Back Thrust", "BackAir", "bair_backkick", "slash_blue", 13.0, 8.0, 0.16, 145.0, 8, 5, 13, Vector2(-1.1, 0.98), 0.74, Vector2.ZERO, 0, true)
	var uair := _make_atk("sans_uair", "Upward Bone Arc", "UpAir", "uair_flipkick", "bone_spike", 10.5, 6.8, 0.14, 88.0, 6, 7, 11, Vector2(0.1, 1.9), 0.78, Vector2.ZERO, 0, true)
	var dair := _make_atk("sans_dair", "Gravity Dunk Spike", "DownAir", "dair_meteor", "gravity_slam", 13.0, 7.8, 0.16, 270.0, 10, 6, 15, Vector2(0.15, 0.15), 0.78, Vector2.ZERO, 0, true)

	var neutral_sp := _make_atk("sans_neutral_special", "Gaster Blaster Beam", "SpecialNeutral", "beam_charge_thrust", "gaster_beam", 17.5, 9.2, 0.19, 28.0, 11, 10, 15, Vector2(2.05, 1.1), 1.18, Vector2.ZERO, 0)
	var side_sp := _make_atk("sans_side_special", "Trombone Shockwave Dash", "SpecialSide", "lunge_burst", "trombone_wave", 13.5, 8.2, 0.16, 40.0, 8, 8, 14, Vector2(1.4, 1.0), 0.92, Vector2(9.8, 1.5), 7)
	var up_sp := _make_atk("sans_up_special", "Shortcut Warp Recovery", "SpecialUp", "warp_ascend", "teleport_burst", 10.0, 6.8, 0.13, 80.0, 5, 9, 13, Vector2(0.0, 1.35), 0.92, Vector2(2.5, 14.5), 4)
	var down_sp := _make_atk("sans_down_special", "Blue Soul Telekinesis Slam", "SpecialDown", "counter_stance", "gravity_slam", 14.5, 8.6, 0.17, 65.0, 7, 9, 15, Vector2(0.0, 0.95), 1.32, Vector2.ZERO, 0)

	_assign_moveset_slots(moveset, jab, side_tilt, up_tilt, down_tilt, nair, fair, bair, uair, dair, neutral_sp, side_sp, up_sp, down_sp)

func _assign_moveset_slots(
	moveset: Resource,
	jab: AttackData, s_tilt: AttackData, u_tilt: AttackData, d_tilt: AttackData,
	nair: AttackData, fair: AttackData, bair: AttackData, uair: AttackData, dair: AttackData,
	n_sp: AttackData, s_sp: AttackData, u_sp: AttackData, d_sp: AttackData
) -> void:
	_set_slot_if_exists(moveset, ["neutral_attack", "neutral"], jab)
	_set_slot_if_exists(moveset, ["side_tilt", "forward_tilt", "forward_smash"], s_tilt)
	_set_slot_if_exists(moveset, ["up_tilt", "up_smash"], u_tilt)
	_set_slot_if_exists(moveset, ["down_tilt", "down_smash"], d_tilt)
	_set_slot_if_exists(moveset, ["neutral_air"], nair)
	_set_slot_if_exists(moveset, ["forward_air"], fair)
	_set_slot_if_exists(moveset, ["back_air"], bair)
	_set_slot_if_exists(moveset, ["up_air"], uair)
	_set_slot_if_exists(moveset, ["down_air"], dair)
	_set_slot_if_exists(moveset, ["special_neutral", "neutral_special"], n_sp)
	_set_slot_if_exists(moveset, ["special_side", "side_special"], s_sp)
	_set_slot_if_exists(moveset, ["special_up", "up_special"], u_sp)
	_set_slot_if_exists(moveset, ["special_down", "down_special"], d_sp)
	if _character and "attack_controller" in _character and _character.attack_controller:
		_character.attack_controller.current_moveset = moveset

func _set_slot_if_exists(moveset: Resource, prop_names: Array[String], atk: AttackData) -> void:
	for p_name in prop_names:
		if p_name in moveset:
			moveset.set(p_name, atk)

func _make_atk(
	id_str: String, disp: String, anim: String, style: String, vfx: String,
	dmg: float, bkb: float, kbg: float, ang: float,
	s_f: int, a_f: int, r_f: int,
	hb_off: Vector2, hb_rad: float,
	imp: Vector2, imp_frame: int, aerial: bool = false
) -> AttackData:
	var a := AttackData.new()
	a.id = id_str
	a.attack_name = disp
	a.display_name = disp
	a.animation_name = anim
	a.pose_style = style
	a.vfx_type = vfx
	a.damage = dmg
	a.base_knockback = bkb
	a.knockback_scaling = kbg
	a.angle_degrees = ang
	a.startup_frames = s_f
	a.active_frames = a_f
	a.recovery_frames = r_f
	a.hitbox_offset = hb_off
	a.hitbox_radius = hb_rad
	a.hitbox_size = Vector2(hb_rad * 2.0, hb_rad * 2.0)
	a.self_impulse = imp
	a.self_impulse_frame = imp_frame
	a.is_aerial = aerial
	a.spawns_projectile = false
	a.is_time_stop = false
	a.divekick_speed = Vector2(13.5 * Constants.UNIT_SIZE, 20.0 * Constants.UNIT_SIZE)
	return a

# ============================================================================
# HELPERS MATEMÁTICOS Y CONSTRUCTORES DE VFX 3D
# ============================================================================
static func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t: float = clampf((x - edge0) / maxf(0.0001, edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _quat_euler_xyz(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion(Vector3.RIGHT, rx) * Quaternion(Vector3.UP, ry) * Quaternion(Vector3.BACK, rz)

static func _quat_euler_yxz(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion(Vector3.UP, ry) * Quaternion(Vector3.RIGHT, rx) * Quaternion(Vector3.BACK, rz)

static func _build_shoulder_char_quat(side_sign: float, arm_down: float, arm_fwd: float, arm_cross: float, arm_roll: float) -> Quaternion:
	var q1 := Quaternion(Vector3.RIGHT, arm_roll)
	var q2 := Quaternion(Vector3.BACK, -side_sign * arm_down)
	var q3 := Quaternion(Vector3.RIGHT, -arm_fwd)
	var q4 := Quaternion(Vector3.UP, -side_sign * arm_cross)
	return q4 * q3 * q2 * q1

func _refresh_active_player() -> void:
	# 1. Si hay un modelo 3D instanciado con su propio AnimationPlayer, tiene prioridad
	if _character:
		var model_root_node: Node = _character.get_node_or_null("Humanoid/ModelRoot")
		if model_root_node:
			var found: AnimationPlayer = _find_animation_player(model_root_node)
			if found:
				_active_player = found
				return
		# 2. Si no, buscar en Humanoid o en el Character
		if not animation_player and _character.has_node("AnimationPlayer"):
			animation_player = _character.get_node("AnimationPlayer")
	_active_player = animation_player

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null

func _resolve_animation_name(raw_name: String) -> String:
	var base: String = raw_name
	if ANIMATION_ALIASES.has(base):
		base = String(ANIMATION_ALIASES[base])

	var facing: float = 1.0
	if _character and _character.has_method("get_facing_direction"):
		facing = _character.get_facing_direction()

	if facing < 0.0:
		var left_candidate: String = base + "_Left"
		if _active_player and _find_clip_in_player(_active_player, left_candidate) != "":
			return left_candidate

	return base

## Busca un clip en el AnimationPlayer soportando bibliotecas ("lib/anim") y sufijos de importación
func _find_clip_in_player(player: AnimationPlayer, target_name: String) -> String:
	if not player:
		return ""
	if player.has_animation(target_name):
		return target_name

	var target_lower: String = target_name.to_lower()
	var anim_list: PackedStringArray = player.get_animation_list()

	# 1. Búsqueda exacta case-insensitive o nombre desnudo
	for full_name in anim_list:
		var bare_name: String = full_name.get_slice("/", full_name.get_slice_count("/") - 1) if "/" in full_name else full_name
		if bare_name.to_lower() == target_lower:
			return full_name

	# 2. Búsqueda por terminación / sufijo (ej: "RIG - MiyabiAction-ataque")
	for full_name in anim_list:
		var lower: String = full_name.to_lower()
		if lower.ends_with("/" + target_lower) or lower.ends_with("-" + target_lower) or lower.ends_with("|" + target_lower) or lower.ends_with("_" + target_lower):
			return full_name

	# 3. Fallback a nombres en español (ej: "RIG - MiyabiAction-salto")
	if SPANISH_FALLBACKS.has(target_lower):
		var es_target: String = SPANISH_FALLBACKS[target_lower]
		for full_name in anim_list:
			var bare_name: String = full_name.get_slice("/", full_name.get_slice_count("/") - 1) if "/" in full_name else full_name
			var lower: String = full_name.to_lower()
			if bare_name.to_lower() == es_target or lower.ends_with("-" + es_target) or lower.ends_with("/" + es_target) or lower.ends_with("|" + es_target) or lower.ends_with("_" + es_target):
				return full_name

	return ""

func _make_unshaded_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	return m

func _set_mesh_color(mi: MeshInstance3D, col: Color) -> void:
	if mi and mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).albedo_color = col

func _create_torus_mesh(outer_r: float, thickness: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.01, outer_r - thickness)
	torus.outer_radius = outer_r + thickness
	mi.mesh = torus
	mi.rotation.x = PI * 0.5
	mi.material_override = _make_unshaded_mat(col)
	return mi

func _create_sphere_mesh(rad: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = rad
	sp.height = rad * 2.0
	mi.mesh = sp
	mi.material_override = _make_unshaded_mat(col)
	return mi

func _create_cyl_mesh(top_r: float, bot_r: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = h
	mi.mesh = cyl
	mi.material_override = _make_unshaded_mat(col)
	return mi

func _create_beam_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_sphere_mesh(0.42, Color(0.95, 0.98, 1.0, 0.95)))
	var cyl := _create_cyl_mesh(0.28, 0.36, 2.6, Color(0.22, 0.74, 0.97, 0.88))
	cyl.rotation.z = -PI * 0.5
	cyl.position.x = 1.35
	grp.add_child(cyl)
	return grp

func _create_bone_pillar_group() -> Node3D:
	var grp := Node3D.new()
	var col := Color(0.95, 0.98, 1.0, 0.95)
	for i in [-1, 0, 1]:
		var single := Node3D.new()
		single.add_child(_create_cyl_mesh(0.06, 0.06, 0.85, col))
		var knob_l := _create_sphere_mesh(0.09, col)
		knob_l.position = Vector3(-0.05, 0.42, 0.0)
		var knob_r := _create_sphere_mesh(0.09, col)
		knob_r.position = Vector3(0.05, 0.42, 0.0)
		single.add_child(knob_l)
		single.add_child(knob_r)
		single.position = Vector3(float(i) * 0.26, 0.35, 0.0)
		single.rotation.z = float(i) * -0.15
		grp.add_child(single)
	return grp

func _create_spiral_vortex_group() -> Node3D:
	var grp := Node3D.new()
	var z_list := [-0.58, 0.0, 0.58]
	var r_list := [0.56, 0.68, 0.52]
	for i in range(3):
		var ring := _create_torus_mesh(r_list[i], 0.028, Color(0.97, 0.98, 1.0, 0.82) if i == 1 else Color(0.99, 0.90, 0.54, 0.65))
		ring.position = Vector3(0.0, 0.0, z_list[i])
		grp.add_child(ring)
	return grp

func _create_ki_knee_cone_group() -> Node3D:
	var grp := Node3D.new()
	var outer_cone := _create_cyl_mesh(0.02, 0.62, 1.65, Color(0.22, 0.74, 0.97, 0.52))
	outer_cone.rotation.x = PI * 0.5
	grp.add_child(outer_cone)
	var inner_cone := _create_cyl_mesh(0.01, 0.38, 1.45, Color(0.88, 0.95, 1.0, 0.78))
	inner_cone.rotation.x = PI * 0.5
	inner_cone.position.z = 0.12
	grp.add_child(inner_cone)
	var ring := _create_torus_mesh(0.46, 0.032, Color(0.49, 0.83, 0.99, 0.88))
	ring.position.z = 0.35
	grp.add_child(ring)
	return grp

func _create_somersault_vortex_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_torus_mesh(0.96, 0.068, Color(0.15, 0.39, 0.92, 0.88)))
	var b2 := _create_torus_mesh(0.92, 0.052, Color(0.22, 0.74, 0.97, 0.84))
	b2.position.z = 0.04
	grp.add_child(b2)
	var w1 := _create_torus_mesh(0.76, 0.024, Color(0.97, 0.98, 1.0, 0.82))
	w1.position.z = -0.05
	grp.add_child(w1)
	return grp

func _create_elbow_slash_beam_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_cyl_mesh(0.22, 0.28, 2.45, Color(0.15, 0.39, 0.92, 0.72)))
	grp.add_child(_create_cyl_mesh(0.13, 0.18, 2.52, Color(0.22, 0.74, 0.97, 0.88)))
	grp.add_child(_create_cyl_mesh(0.06, 0.09, 2.58, Color(1.0, 1.0, 1.0, 0.98)))
	var flash := _create_sphere_mesh(0.28, Color(1.0, 1.0, 1.0, 0.95))
	flash.position = Vector3(0.0, 1.15, 0.0)
	grp.add_child(flash)
	return grp

func _create_kick_crescent_arc_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_torus_mesh(1.32, 0.14, Color(0.11, 0.31, 0.85, 0.82)))
	var mid := _create_torus_mesh(1.30, 0.09, Color(0.22, 0.74, 0.97, 0.90))
	mid.position.z = 0.02
	grp.add_child(mid)
	var core := _create_torus_mesh(1.28, 0.045, Color(1.0, 1.0, 1.0, 0.96))
	core.position.z = 0.04
	grp.add_child(core)
	return grp

func _create_divekick_vfx_group() -> Node3D:
	var grp := Node3D.new()
	var outer_cone := _create_cyl_mesh(0.02, 0.52, 2.35, Color(0.22, 0.74, 0.97, 0.65))
	outer_cone.rotation.x = PI * 0.5
	grp.add_child(outer_cone)
	var inner_cone := _create_cyl_mesh(0.01, 0.32, 2.15, Color(1.0, 1.0, 1.0, 0.92))
	inner_cone.rotation.x = PI * 0.5
	inner_cone.position.z = 0.15
	grp.add_child(inner_cone)
	var tip_ring := _create_torus_mesh(0.48, 0.038, Color(0.49, 0.83, 0.99, 0.92))
	tip_ring.position.z = 1.12
	grp.add_child(tip_ring)
	return grp
