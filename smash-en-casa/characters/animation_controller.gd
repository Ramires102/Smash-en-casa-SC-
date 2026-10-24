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

var _gogeta_bones: Dictionary = {}
var _sans_bindings: Dictionary = {}
var _sans_hand_bone_attach: BoneAttachment3D = null
var _cur_pose: Dictionary = {}
var _tgt_pose: Dictionary = {}
var _combat_vfx: ProceduralCombatVfx = ProceduralCombatVfx.new()

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
	"Crouch": "Squat",
	"DoubleJump": "Jump"
}

func _ready() -> void:
	if model_root == null:
		_character = get_parent()
		_cur_pose = ProceduralPoseLibrary.create_default_pose()
		_tgt_pose = ProceduralPoseLibrary.create_default_pose()
		_refresh_active_player()

func setup(data: CharacterData = null) -> void:
	_character = get_parent()
	_cur_pose = ProceduralPoseLibrary.create_default_pose()
	_tgt_pose = ProceduralPoseLibrary.create_default_pose()
	_pose_initialized = false

	if not animation_player and _character and _character.has_node("AnimationPlayer"):
		animation_player = _character.get_node("AnimationPlayer")
	if data and data.animation_library and animation_player:
		if animation_player.has_animation_library(""):
			animation_player.remove_animation_library("")
		animation_player.add_animation_library("", data.animation_library)
	_refresh_active_player()

	_initialize_procedural_or_legacy(data)
	call_deferred("_initialize_procedural_or_legacy", data)

func _initialize_procedural_or_legacy(data: CharacterData) -> void:
	if _character == null:
		return
	model_root = _character.get_node_or_null("Humanoid/ModelRoot") as Node3D
	if model_root == null:
		model_root = _character.find_child("ModelRoot", true, false) as Node3D

	skeleton = _find_best_skeleton(model_root) if model_root != null else _find_best_skeleton(_character)

	var char_id: String = ""
	if data != null:
		if "character_name" in data:
			char_id = str(data.character_name).to_lower()
		elif "display_name" in data:
			char_id = str(data.display_name).to_lower()

	is_gogeta = false
	is_sans = false

	if char_id.contains("gogeta") or (skeleton != null and skeleton.find_bone("Sash") != -1):
		is_gogeta = true
		_gogeta_bones = ProceduralRigSolver.init_gogeta_rig(skeleton)
		ProceduralMovesetFactory.inject_gogeta_moveset(_character)
	elif char_id.contains("sans") or (skeleton != null and (skeleton.find_bone("Spine_1") != -1 or skeleton.find_bone("Spine 1") != -1 or skeleton.find_bone("UpperarmR") != -1 or skeleton.find_bone("Upperarm.R") != -1)):
		is_sans = true
		_setup_sans_rig_data()
		ProceduralMovesetFactory.inject_sans_moveset(_character)

	if is_gogeta or is_sans:
		_refresh_active_player()
		stop()
		vfx_group = _combat_vfx.build_nodes(_character)
		_update_procedural_rig(0.016)
	else:
		_refresh_active_player()
		if data and data.animation_library and animation_player:
			if animation_player.has_animation_library(""):
				animation_player.remove_animation_library("")
			animation_player.add_animation_library("", data.animation_library)
		if _character and _character.has_node("StateMachine"):
			var fsm = _character.get_node("StateMachine")
			if fsm and fsm.current_state:
				play_animation(fsm.current_state.name)

func _setup_sans_rig_data() -> void:
	var info: Dictionary = ProceduralRigSolver.init_sans_rig(skeleton, model_root, _sans_hand_bone_attach)
	_sans_bindings = info["sans_bindings"]
	_sans_hand_bone_attach = info["sans_hand_bone_attach"]
	_combat_vfx.gb_bindings = info["gb_bindings"]
	_combat_vfx.gb_armature = info["gb_armature"]
	_combat_vfx.gb_skeleton = info["gb_skeleton"]
	_combat_vfx.gb_mesh = info["gb_mesh"]
	_combat_vfx.sans_bone_mesh = info["sans_bone_mesh"]
	_combat_vfx.sans_hand_bone_mesh = info["sans_hand_bone_mesh"]

func setup_preview_on_model(preview_model_root: Node3D, char_name_str: String = "") -> void:
	_character = null
	model_root = preview_model_root
	_cur_pose = ProceduralPoseLibrary.create_default_pose()
	_tgt_pose = ProceduralPoseLibrary.create_default_pose()
	_pose_initialized = false
	skeleton = _find_best_skeleton(model_root)
	var cid: String = char_name_str.to_lower()
	is_gogeta = false
	is_sans = false
	if cid.contains("gogeta") or (skeleton != null and skeleton.find_bone("Sash") != -1):
		is_gogeta = true
		_gogeta_bones = ProceduralRigSolver.init_gogeta_rig(skeleton)
	elif cid.contains("sans") or (skeleton != null and (skeleton.find_bone("Spine_1") != -1 or skeleton.find_bone("Spine 1") != -1 or skeleton.find_bone("UpperarmR") != -1 or skeleton.find_bone("Upperarm.R") != -1)):
		is_sans = true
		_setup_sans_rig_data()
	if is_gogeta or is_sans:
		_refresh_active_player()
		stop()
		active_state_name = "Idle"
		_update_procedural_rig(0.0)

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
	elif anim_name in ["Jump", "JumpSquat", "DoubleJump"]:
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
		_combat_vfx.hide_all()

	if is_gogeta or is_sans:
		return

	if not _active_player:
		_refresh_active_player()
	if not _active_player:
		return

	var resolved_name: String = _resolve_animation_name(anim_name)
	var clip_to_play: String = _find_clip_in_player(_active_player, resolved_name)
	if clip_to_play == "" and resolved_name != anim_name:
		clip_to_play = _find_clip_in_player(_active_player, anim_name)
	if clip_to_play == "" and animation_player and animation_player != _active_player:
		clip_to_play = _find_clip_in_player(animation_player, resolved_name)
		if clip_to_play != "":
			animation_player.play(clip_to_play, blend_time, custom_speed)
			return
	if clip_to_play != "":
		_active_player.play(clip_to_play, blend_time, custom_speed)

func play_attack_animation(anim_name: String, target_duration: float = 0.0, atk_data: AttackData = null) -> void:
	_current_animation_name = anim_name
	active_state_name = "Attack"
	state_elapsed = 0.0
	attack_frame = 1
	attack_phase = "startup"
	if atk_data != null:
		active_attack = atk_data
	if is_gogeta or is_sans:
		return
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
			attack_phase = "startup" if attack_frame <= s else ("active" if attack_frame <= s + a else "recovery")
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

	ProceduralPoseLibrary.compute_target_pose(
		_tgt_pose, state_elapsed, is_gogeta, is_sans,
		active_state_name, is_sliding_knockdown, is_double_jumping,
		active_attack, attack_frame, attack_phase, _character
	)

	var is_attacking: bool = (active_state_name == "Attack" and active_attack != null)
	var is_turn_kick: bool = is_attacking and active_attack.pose_style == "down_special_turn_kick"
	var damp_lambda: float = 19.0 if is_turn_kick else (26.0 if is_attacking else 18.0)

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
		ProceduralRigSolver.apply_gogeta_pose(skeleton, _gogeta_bones, _cur_pose, state_elapsed, active_state_name)
	elif is_sans:
		ProceduralRigSolver.apply_sans_pose(skeleton, _sans_bindings, model_root, _character, _cur_pose, active_state_name, active_attack, attack_phase)

	_combat_vfx.update_vfx(state_elapsed, is_gogeta, is_sans, active_state_name, active_attack, attack_frame, attack_phase)

func _find_best_skeleton(root_node: Node) -> Skeleton3D:
	if root_node == null:
		return null
	var skeletons: Array[Skeleton3D] = []
	_collect_skeletons(root_node, skeletons)
	for sk in skeletons:
		if sk.find_bone("Spine") != -1 or sk.find_bone("Pelvis") != -1 or sk.find_bone("Hips") != -1:
			return sk
	return skeletons[0] if not skeletons.is_empty() else null

func _collect_skeletons(node: Node, out_list: Array[Skeleton3D]) -> void:
	if node is Skeleton3D:
		out_list.append(node as Skeleton3D)
	for child in node.get_children():
		_collect_skeletons(child, out_list)

func _refresh_active_player() -> void:
	if _character:
		var m_root: Node = _character.get_node_or_null("Humanoid/ModelRoot")
		if m_root:
			var found: AnimationPlayer = _find_animation_player(m_root)
			if found:
				_active_player = found
				return
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
	var base: String = String(ANIMATION_ALIASES[raw_name]) if ANIMATION_ALIASES.has(raw_name) else raw_name
	var facing: float = _character.get_facing_direction() if (_character and _character.has_method("get_facing_direction")) else 1.0
	if facing < 0.0:
		var left_candidate: String = base + "_Left"
		if _active_player and _find_clip_in_player(_active_player, left_candidate) != "":
			return left_candidate
	return base

func _find_clip_in_player(player: AnimationPlayer, target_name: String) -> String:
	if not player:
		return ""
	if player.has_animation(target_name):
		return target_name
	var target_lower: String = target_name.to_lower()
	var anim_list: PackedStringArray = player.get_animation_list()
	for full_name in anim_list:
		var bare_name: String = full_name.get_slice("/", full_name.get_slice_count("/") - 1) if "/" in full_name else full_name
		if bare_name.to_lower() == target_lower:
			return full_name
	for full_name in anim_list:
		var lower: String = full_name.to_lower()
		if lower.ends_with("/" + target_lower) or lower.ends_with("-" + target_lower) or lower.ends_with("|" + target_lower) or lower.ends_with("_" + target_lower):
			return full_name
	return ""
