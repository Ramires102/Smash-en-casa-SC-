# ==============================================================================
# AnimationController — Coordinador de Animaciones 3D y Efectos de Combate
# ==============================================================================
# Unifica dos modos de animación bajo la misma interfaz para todos los luchadores:
#   1. Modo AnimationPlayer (Sakuya, Hornet, Lego Batman, Miyabi, John):
#      Busca y reproduce clips de AnimationLibrary o embebidos en el archivo GLB.
#   2. Modo Procedural (Gogeta SSJ y Sans):
#      Delega el cálculo articular de Skeleton3D a ProceduralPoseSolver y los
#      efectos visuales 3D a CombatVfxController.
# ==============================================================================
class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer

var _character: Node = null
var _active_player: AnimationPlayer = null
var _current_animation_name: String = "Idle"
var _current_speed: float = 1.0

var model_root: Node3D = null
var skeleton: Skeleton3D = null

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
var _cur_pose: Dictionary = {}
var _tgt_pose: Dictionary = {}
var _vfx_controller: CombatVfxController = CombatVfxController.new()

#region Diccionarios de Resolución de Nombres de Animación
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

## Traducción para modelos GLB importados cuyos clips están nombrados en español (ej. Miyabi).
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
	"death": "salida del personaje"
}
#endregion

#region Inicialización
func _ready() -> void:
	_character = get_parent()
	_cur_pose = ProceduralPoseSolver.create_default_pose()
	_tgt_pose = ProceduralPoseSolver.create_default_pose()

func setup(data: CharacterData = null) -> void:
	_character = get_parent()
	_cur_pose = ProceduralPoseSolver.create_default_pose()
	_tgt_pose = ProceduralPoseSolver.create_default_pose()
	_pose_initialized = false
	call_deferred("_initialize_animation_mode", data)

func _initialize_animation_mode(data: CharacterData) -> void:
	if _character == null:
		return
	model_root = _character.get_node_or_null("Humanoid/ModelRoot") as Node3D
	if model_root == null:
		model_root = _character.find_child("ModelRoot", true, false) as Node3D

	skeleton = model_root.find_child("Skeleton3D", true, false) as Skeleton3D if model_root else null
	if skeleton == null:
		skeleton = _character.find_child("Skeleton3D", true, false) as Skeleton3D

	var char_id: String = data.character_name.to_lower() if data != null else ""
	is_gogeta = false
	is_sans = false

	if skeleton != null:
		if char_id.contains("gogeta") or skeleton.find_bone("Sash") != -1:
			is_gogeta = true
			_gogeta_bones = ProceduralPoseSolver.init_gogeta_bones(skeleton)
			ProceduralMovesetBuilder.inject_gogeta_moveset(_character)
		elif char_id.contains("sans") or skeleton.find_bone("Spine_1") != -1 or skeleton.find_bone("UpperarmR") != -1:
			is_sans = true
			_sans_bindings = ProceduralPoseSolver.init_sans_bindings(skeleton, model_root)
			ProceduralMovesetBuilder.inject_sans_moveset(_character)

	_refresh_active_player()
	_vfx_controller.build_for_character(_character)

	if is_gogeta or is_sans:
		stop()
		_update_procedural_rig(0.016)
	else:
		if data and data.animation_library and animation_player:
			if animation_player.has_animation_library(""):
				animation_player.remove_animation_library("")
			animation_player.add_animation_library("", data.animation_library)
		if _character.has_node("StateMachine"):
			var fsm: Node = _character.get_node("StateMachine")
			if fsm and fsm.get("current_state"):
				play_animation(str(fsm.current_state.name))
#endregion

#region API Pública de Reproducción
func set_paused(paused: bool) -> void:
	if is_gogeta or is_sans:
		return
	var scale_val: float = 0.0 if paused else 1.0
	if _active_player:
		_active_player.speed_scale = scale_val
	if animation_player and animation_player != _active_player:
		animation_player.speed_scale = scale_val

func stop() -> void:
	if _active_player and _active_player.is_playing():
		_active_player.stop()
	if animation_player and animation_player.is_playing():
		animation_player.stop()

func on_facing_direction_changed(_dir: float) -> void:
	if is_gogeta or is_sans or _current_animation_name.is_empty():
		return
	var base_name: String = _current_animation_name.replace("_Left", "")
	if base_name in ["Idle", "Walk", "Run", "Dash"]:
		play_animation(base_name, _current_speed)

func play_animation(anim_name: String, custom_speed: float = 1.0, blend_time: float = 0.03) -> void:
	_current_animation_name = anim_name
	_current_speed = custom_speed
	state_elapsed = 0.0
	active_state_name = _classify_state_category(anim_name)

	if active_state_name != "Attack":
		active_attack = null
		attack_phase = "none"
		_vfx_controller.hide_all()

	if is_gogeta or is_sans:
		return

	if not _active_player:
		_refresh_active_player()
	if _active_player == null:
		return

	var resolved_name: String = _resolve_animation_name(anim_name)
	var clip_to_play: String = _find_clip_in_player(_active_player, resolved_name)
	if clip_to_play.is_empty() and resolved_name != anim_name:
		clip_to_play = _find_clip_in_player(_active_player, anim_name)

	if clip_to_play.is_empty() and animation_player and animation_player != _active_player:
		var root_clip: String = _find_clip_in_player(animation_player, resolved_name)
		if not root_clip.is_empty():
			animation_player.play(root_clip, blend_time, custom_speed)
			return

	if not clip_to_play.is_empty():
		_ensure_locomotion_loop(_active_player, clip_to_play)
		_active_player.play(clip_to_play, blend_time, custom_speed)

func play_attack_animation(anim_name: String, target_duration: float = 0.0, atk_data: AttackData = null) -> void:
	_current_animation_name = anim_name
	active_state_name = "Attack"
	state_elapsed = 0.0
	attack_frame = 1
	attack_phase = "startup"
	if atk_data != null:
		active_attack = atk_data

	if not is_gogeta and not is_sans:
		var speed: float = 1.0
		if target_duration > 0.0:
			var clip_len: float = get_animation_length(anim_name)
			if clip_len > 0.0:
				speed = clampf(clip_len / target_duration, 0.5, 4.0)
		play_animation(anim_name, speed, 0.02)

func update_attack_frame(frame: int, phase: String, atk_data: AttackData = null) -> void:
	attack_frame = frame
	attack_phase = phase
	if atk_data != null:
		active_attack = atk_data

func get_animation_length(anim_name: String) -> float:
	if not _active_player:
		_refresh_active_player()
	if not _active_player:
		return 0.0

	var clip_name: String = _find_clip_in_player(_active_player, anim_name)
	if not clip_name.is_empty() and _active_player.has_animation(clip_name):
		return _active_player.get_animation(clip_name).length

	if animation_player and animation_player != _active_player:
		clip_name = _find_clip_in_player(animation_player, anim_name)
		if not clip_name.is_empty() and animation_player.has_animation(clip_name):
			return animation_player.get_animation(clip_name).length
	return 0.0
#endregion

#region Actualización Física por Frame (Única Pasada)
func _physics_process(delta: float) -> void:
	if _character and _character.has_method("is_self_hitlag_active") and _character.is_self_hitlag_active():
		return

	state_elapsed += delta
	if is_gogeta or is_sans:
		_sync_state_from_character()
		_update_procedural_rig(delta)

	_vfx_controller.update(state_elapsed, is_gogeta, active_state_name, active_attack, attack_phase)

func _sync_state_from_character() -> void:
	if _character == null or not ("state_machine" in _character) or _character.state_machine == null:
		return
	var st: Node = _character.state_machine.current_state
	if st == null:
		return

	if st.name == "Attack":
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
	else:
		active_state_name = _classify_state_category(str(st.name))

func _classify_state_category(raw_state: String) -> String:
	if raw_state in ["Run", "Dash", "Walk"]:
		return "Run"
	if raw_state in ["Jump", "JumpSquat"]:
		return "Jump"
	if raw_state in ["Fall", "Tumble", "AirDodge"]:
		return "Fall"
	if raw_state in ["Hit", "Daze"]:
		return "Hit"
	if raw_state == "Death":
		return "Death"
	return "Idle"

func _update_procedural_rig(dt: float) -> void:
	var safe_dt: float = minf(dt, 0.05)
	ProceduralPoseSolver.compute_target_pose(
		_tgt_pose, state_elapsed, is_gogeta, is_sans,
		active_state_name, is_sliding_knockdown, is_double_jumping,
		active_attack, attack_frame, attack_phase
	)

	var is_attacking: bool = (active_state_name == "Attack" and active_attack != null)
	var is_turn_kick: bool = is_attacking and active_attack.pose_style == "down_special_turn_kick"
	var damp_lambda: float = 19.0 if is_turn_kick else (26.0 if is_attacking else 18.0)

	if absf(float(_tgt_pose["pelvisPitch"])) < PI and absf(float(_cur_pose["pelvisPitch"])) >= PI:
		_cur_pose["pelvisPitch"] = wrapf(float(_cur_pose["pelvisPitch"]), -PI, PI)
	if absf(float(_tgt_pose["pelvisYaw"])) < PI and absf(float(_cur_pose["pelvisYaw"])) >= PI:
		_cur_pose["pelvisYaw"] = wrapf(float(_cur_pose["pelvisYaw"]), -PI, PI)

	if not _pose_initialized or safe_dt <= 0.0:
		for k in _tgt_pose.keys():
			_cur_pose[k] = _tgt_pose[k]
		_pose_initialized = true
	else:
		for k in _tgt_pose.keys():
			_cur_pose[k] = CharacterController.damp(float(_cur_pose[k]), float(_tgt_pose[k]), damp_lambda, safe_dt)

	if is_gogeta:
		ProceduralPoseSolver.apply_gogeta_pose(skeleton, _gogeta_bones, _cur_pose, state_elapsed, active_state_name == "Run")
	elif is_sans:
		var base_off: Vector3 = _character.character_data.model_offset if (_character and "character_data" in _character and _character.character_data) else Vector3(0.0, -0.9, 0.0)
		ProceduralPoseSolver.apply_sans_pose(skeleton, _sans_bindings, model_root, base_off, _cur_pose)
#endregion

#region Búsqueda de Clips en AnimationPlayer
func _refresh_active_player() -> void:
	if _character:
		var model_root_node: Node = _character.get_node_or_null("Humanoid/ModelRoot")
		if model_root_node:
			var found: AnimationPlayer = _find_animation_player(model_root_node)
			if found:
				_active_player = found
				return
		if not animation_player and _character.has_node("AnimationPlayer"):
			animation_player = _character.get_node("AnimationPlayer") as AnimationPlayer
	_active_player = animation_player

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null

func _ensure_locomotion_loop(player: AnimationPlayer, clip_name: String) -> void:
	if not player.has_animation(clip_name):
		return
	var a_res: Animation = player.get_animation(clip_name)
	var low_clip: String = clip_name.to_lower()
	if a_res and a_res.loop_mode == Animation.LOOP_NONE:
		if low_clip.contains("idle") or low_clip.contains("walk") or low_clip.contains("run") or low_clip.contains("buzzsaw"):
			a_res.loop_mode = Animation.LOOP_LINEAR

func _resolve_animation_name(raw_name: String) -> String:
	var base: String = String(ANIMATION_ALIASES.get(raw_name, raw_name))
	var facing: float = _character.get_facing_direction() if (_character and _character.has_method("get_facing_direction")) else 1.0
	if facing < 0.0:
		var left_candidate: String = base + "_Left"
		if _active_player and not _find_clip_in_player(_active_player, left_candidate).is_empty():
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

	if SPANISH_FALLBACKS.has(target_lower):
		var es_target: String = SPANISH_FALLBACKS[target_lower]
		for full_name in anim_list:
			var bare_name: String = full_name.get_slice("/", full_name.get_slice_count("/") - 1) if "/" in full_name else full_name
			var lower: String = full_name.to_lower()
			if bare_name.to_lower() == es_target or lower.ends_with("-" + es_target) or lower.ends_with("/" + es_target) or lower.ends_with("|" + es_target) or lower.ends_with("_" + es_target):
				return full_name

	return ""
#endregion
