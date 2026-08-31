@tool
class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer

# Referencia al personaje padre para detectar si tiene modelo real
var _character: Node = null
var _has_real_model: bool = false
var _placeholder_profile_name: String = ""

# ── Sistema de Animaciones GLB ────────────────────────────────
var _glb_anim_player: AnimationPlayer = null

# Mapeo: nombre del estado del juego → nombre de la animación dentro del GLB
var _anim_map: Dictionary = {}

const LEGACY_ANIMATION_ALIASES: Dictionary = {
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
	"AttackFair": "NeutralAir",
	"AttackBair": "NeutralAir",
	"ForwardAir": "NeutralAir",
	"BackAir": "NeutralAir",
	"AttackSpecial": "SpecialNeutral",
	"AttackSpecialNeutral": "SpecialNeutral",
	"AttackSpecialSide": "SpecialSide",
	"AttackSpecialUp": "SpecialUp",
	"AttackSpecialDown": "SpecialDown",
	"Special": "SpecialNeutral",
	"Grab": "AttackNeutral"
}

func _ready() -> void:
	_character = get_parent()
	if not animation_player and _character and _character.has_node("AnimationPlayer"):
		animation_player = _character.get_node("AnimationPlayer")
	_resolve_placeholder_profile()
	
	if animation_player:
		_has_real_model = _character != null and _character.has_node("Humanoid/ModelRoot")
		if _has_real_model:
			_setup_glb_animations()
		else:
			_setup_placeholder_animations()

func setup(data: CharacterData) -> void:
	_character = get_parent()
	if not animation_player and _character and _character.has_node("AnimationPlayer"):
		animation_player = _character.get_node("AnimationPlayer")
	if not animation_player:
		return
	_resolve_placeholder_profile(data)
		
	_has_real_model = data != null and data.model_scene != null
	if _has_real_model:
		if _character and _character.has_node("Humanoid/ModelRoot"):
			_setup_glb_animations()
		else:
			call_deferred("_deferred_setup_glb")
	else:
		_setup_placeholder_animations()
		if _character and _character.has_node("StateMachine"):
			var fsm = _character.get_node("StateMachine")
			if fsm and fsm.current_state:
				play_animation(fsm.current_state.name)

func _resolve_placeholder_profile(data: CharacterData = null) -> void:
	if data != null and data.character_name != "":
		_placeholder_profile_name = data.character_name.strip_edges().to_lower()
		return

	_placeholder_profile_name = ""
	if _character and "character_data" in _character and _character.character_data != null:
		var candidate: String = str(_character.character_data.character_name)
		if candidate != "":
			_placeholder_profile_name = candidate.strip_edges().to_lower()

func _is_sakuya_placeholder_profile() -> bool:
	return _placeholder_profile_name.find("sakuya") != -1

func _deferred_setup_glb() -> void:
	if _character and _character.has_node("Humanoid/ModelRoot"):
		_setup_glb_animations()

func _resolve_animation_alias(anim_name: String) -> String:
	if LEGACY_ANIMATION_ALIASES.has(anim_name):
		return String(LEGACY_ANIMATION_ALIASES[anim_name])
	return anim_name

func play_animation(anim_name: String, custom_speed: float = 1.0) -> void:
	anim_name = _resolve_animation_alias(anim_name)

	# 1. Si la animación mapeada pertenece al AnimationPlayer del GLB
	if _glb_anim_player and anim_name in _anim_map:
		var glb_name: String = _anim_map[anim_name]
		if _glb_anim_player.has_animation(glb_name):
			if animation_player and animation_player.is_playing():
				animation_player.stop()
			_glb_anim_player.play(glb_name, -1, custom_speed)
			return

	# 2. Si la animación está en el AnimationPlayer del Character (procedurales: Run, Walk, etc.)
	if animation_player and animation_player.has_animation(anim_name):
		# Para estados de locomoción (Run, Walk, Dash), mantener Idle del GLB para que el cuerpo posea naturalidad
		if _glb_anim_player and "Idle" in _anim_map:
			if anim_name in ["Run", "Walk", "Dash", "Pivot", "RunBrake"]:
				_glb_anim_player.play(_anim_map["Idle"])
			else:
				_glb_anim_player.stop()
		animation_player.play(anim_name, -1, custom_speed)
		return

	# 3. Direct match en el GLB Player por nombre literal
	if _glb_anim_player and _glb_anim_player.has_animation(anim_name):
		if animation_player and animation_player.is_playing():
			animation_player.stop()
		_glb_anim_player.play(anim_name, -1, custom_speed)
		return

	# 4. Fallback directo en AnimationPlayer
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name, -1, custom_speed)

func play_attack_animation(anim_name: String, target_duration: float = 0.0) -> void:
	var speed: float = 1.0
	if target_duration > 0.0:
		var clip_len: float = _get_animation_length(anim_name)
		if clip_len > 0.0:
			speed = clamp(clip_len / target_duration, 0.8, 3.5)
	play_animation(anim_name, speed)

func _get_animation_length(anim_name: String) -> float:
	if _glb_anim_player and anim_name in _anim_map:
		var glb_name: String = _anim_map[anim_name]
		if _glb_anim_player.has_animation(glb_name):
			return _glb_anim_player.get_animation(glb_name).length
	if _glb_anim_player and _glb_anim_player.has_animation(anim_name):
		return _glb_anim_player.get_animation(anim_name).length
	if animation_player and animation_player.has_animation(anim_name):
		return animation_player.get_animation(anim_name).length
	return 0.0

func stop() -> void:
	if _glb_anim_player:
		_glb_anim_player.stop()
	if animation_player:
		animation_player.stop()

# ─────────────────────────────────────────────────────────────
# SISTEMA GLB: Conecta con el AnimationPlayer del GLB,
# mapea exactamente todas las animaciones con sus sufijos,
# y genera procedurales para los estados faltantes.
# ─────────────────────────────────────────────────────────────
func _setup_glb_animations() -> void:
	var model_root: Node = _character.get_node("Humanoid/ModelRoot")
	_glb_anim_player = _find_animation_player(model_root)

	if not _glb_anim_player:
		_setup_real_model_animations()
		return

	# Lista de todas las animaciones importadas en el GLB
	var available_anims: PackedStringArray = []
	for lib_name in _glb_anim_player.get_animation_library_list():
		var lib: AnimationLibrary = _glb_anim_player.get_animation_library(lib_name)
		for a_name in lib.get_animation_list():
			var full_name: String = (lib_name + "/" + a_name) if lib_name != "" else a_name
			available_anims.append(full_name)

	print("[AnimController] GLB animations found (", available_anims.size(), "): ", available_anims)

	# Mapeo exacto por sufijo para evitar falsos positivos
	var exact_suffix_map: Dictionary = {
		"Idle": "idle",
		"Fall": "caida",
		"FastFall": "caida",
		"Attack": "ataque",
		"AttackDown": "ataque agachado",
		"AttackAir": "salto ataque",
		"AttackAirDown": "salto ataque abajo",
		"AttackAirUp": "salto ataque arriba",
		"Special": "especial",
		"SpecialUp": "especial arriba",
		"SpecialDown": "especial abajo (parry)",
		"Grab": "grab",
		"Jump": "salto",
		"Squat": "agachado",
		"Death": "salida del personaje",
	}

	for state_name: String in exact_suffix_map:
		var target_suffix: String = exact_suffix_map[state_name].to_lower()
		for anim_full_name: String in available_anims:
			var anim_lower: String = anim_full_name.to_lower()
			if anim_lower.ends_with("-" + target_suffix) or anim_lower.ends_with("/" + target_suffix) or anim_lower == target_suffix:
				_anim_map[state_name] = anim_full_name
				break

	# Fallback para Idle si no existe el sufijo "-idle"
	if not "Idle" in _anim_map:
		for anim_full_name: String in available_anims:
			var anim_lower: String = anim_full_name.to_lower()
			if anim_lower.ends_with("miyabiaction") or anim_lower == "rig - miyabiaction":
				_anim_map["Idle"] = anim_full_name
				break

	# Alias de ataques para compatibilidad de estados
	if "Attack" in _anim_map:
		_anim_map["AttackNeutral"] = _anim_map["Attack"]
	if "AttackAir" in _anim_map:
		_anim_map["NeutralAir"] = _anim_map["AttackAir"]
	if "Special" in _anim_map:
		_anim_map["SpecialNeutral"] = _anim_map["Special"]

	# Añadir procedurales para estados sin animación GLB (Run, Walk, Fall, Hit, Shield, etc.)
	_add_procedural_fallbacks()

	print("[AnimController] Final Animation Map:")
	for k: String in _anim_map:
		print("  ", k, " → ", _anim_map[k])

func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null

# ── Animaciones procedurales sobre el nodo ModelRoot ─────────
func _add_procedural_fallbacks() -> void:
	var lib: AnimationLibrary
	if animation_player.has_animation_library(""):
		lib = animation_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)

	var base_y: float = -0.9

	# ── Run (Carrera estilo anime veloz: inclinación hacia el frente + rebote dinámico) ──
	if "Run" not in _anim_map:
		var run := Animation.new()
		run.loop_mode = Animation.LOOP_LINEAR
		run.length = 0.35
		var rp := run.add_track(Animation.TYPE_VALUE)
		run.track_set_path(rp, "Humanoid/ModelRoot:position")
		run.track_insert_key(rp, 0.0,    Vector3(0.0, base_y,        0.0))
		run.track_insert_key(rp, 0.09,   Vector3(0.0, base_y - 0.06, 0.0))
		run.track_insert_key(rp, 0.175,  Vector3(0.0, base_y,        0.0))
		run.track_insert_key(rp, 0.26,   Vector3(0.0, base_y - 0.06, 0.0))
		run.track_insert_key(rp, 0.35,   Vector3(0.0, base_y,        0.0))
		var rr := run.add_track(Animation.TYPE_VALUE)
		run.track_set_path(rr, "Humanoid/ModelRoot:rotation_degrees")
		run.track_insert_key(rr, 0.0,    Vector3(-18.0, 0.0,  3.0))
		run.track_insert_key(rr, 0.175,  Vector3(-22.0, 0.0, -3.0))
		run.track_insert_key(rr, 0.35,   Vector3(-18.0, 0.0,  3.0))
		if not lib.has_animation("Run"):
			lib.add_animation("Run", run)
		_anim_map["Run"] = "Run"

	# ── Walk ──
	if "Walk" not in _anim_map:
		var walk := Animation.new()
		walk.loop_mode = Animation.LOOP_LINEAR
		walk.length = 0.6
		var wp := walk.add_track(Animation.TYPE_VALUE)
		walk.track_set_path(wp, "Humanoid/ModelRoot:position")
		walk.track_insert_key(wp, 0.0,  Vector3(0.0, base_y,        0.0))
		walk.track_insert_key(wp, 0.15, Vector3(0.0, base_y - 0.03, 0.0))
		walk.track_insert_key(wp, 0.3,  Vector3(0.0, base_y,        0.0))
		walk.track_insert_key(wp, 0.45, Vector3(0.0, base_y - 0.03, 0.0))
		walk.track_insert_key(wp, 0.6,  Vector3(0.0, base_y,        0.0))
		var wr := walk.add_track(Animation.TYPE_VALUE)
		walk.track_set_path(wr, "Humanoid/ModelRoot:rotation_degrees")
		walk.track_insert_key(wr, 0.0,  Vector3(-5.0, 0.0,  4.0))
		walk.track_insert_key(wr, 0.3,  Vector3(-5.0, 0.0, -4.0))
		walk.track_insert_key(wr, 0.6,  Vector3(-5.0, 0.0,  4.0))
		if not lib.has_animation("Walk"):
			lib.add_animation("Walk", walk)
		_anim_map["Walk"] = "Walk"

	# ── Dash ──
	if "Dash" not in _anim_map:
		_anim_map["Dash"] = _anim_map.get("Run", "Run")

	# ── Fall ──
	if "Fall" not in _anim_map:
		var fall := Animation.new()
		fall.loop_mode = Animation.LOOP_LINEAR
		fall.length = 0.5
		var fr := fall.add_track(Animation.TYPE_VALUE)
		fall.track_set_path(fr, "Humanoid/ModelRoot:rotation_degrees")
		fall.track_insert_key(fr, 0.0,  Vector3(10.0, 0.0, 0.0))
		fall.track_insert_key(fr, 0.25, Vector3(14.0, 0.0, 0.0))
		fall.track_insert_key(fr, 0.5,  Vector3(10.0, 0.0, 0.0))
		if not lib.has_animation("Fall"):
			lib.add_animation("Fall", fall)
		_anim_map["Fall"] = "Fall"

	# ── FastFall ──
	if "FastFall" not in _anim_map:
		_anim_map["FastFall"] = _anim_map.get("Fall", "Fall")

	# ── Hit ──
	if "Hit" not in _anim_map:
		var hit := Animation.new()
		hit.length = 0.35
		var hr := hit.add_track(Animation.TYPE_VALUE)
		hit.track_set_path(hr, "Humanoid/ModelRoot:rotation_degrees")
		hit.track_insert_key(hr, 0.0,   Vector3(0.0,   0.0,  0.0))
		hit.track_insert_key(hr, 0.05,  Vector3(-25.0, 0.0, 18.0))
		hit.track_insert_key(hr, 0.15,  Vector3(12.0,  0.0, -10.0))
		hit.track_insert_key(hr, 0.25,  Vector3(-5.0,  0.0,  5.0))
		hit.track_insert_key(hr, 0.35,  Vector3(0.0,   0.0,  0.0))
		if not lib.has_animation("Hit"):
			lib.add_animation("Hit", hit)
		_anim_map["Hit"] = "Hit"

	# ── Shield ──
	if "Shield" not in _anim_map:
		if "SpecialDown" in _anim_map:
			_anim_map["Shield"] = _anim_map["SpecialDown"]
		else:
			var sh := Animation.new()
			sh.loop_mode = Animation.LOOP_LINEAR
			sh.length = 0.3
			var sp := sh.add_track(Animation.TYPE_VALUE)
			sh.track_set_path(sp, "Humanoid/ModelRoot:position")
			sh.track_insert_key(sp, 0.0,  Vector3(0.0, base_y - 0.15, 0.0))
			sh.track_insert_key(sp, 0.15, Vector3(0.0, base_y - 0.18, 0.0))
			sh.track_insert_key(sp, 0.3,  Vector3(0.0, base_y - 0.15, 0.0))
			var ss := sh.add_track(Animation.TYPE_VALUE)
			sh.track_set_path(ss, "Humanoid/ModelRoot:scale")
			sh.track_insert_key(ss, 0.0, Vector3(1.15, 0.95, 1.15))
			if not lib.has_animation("Shield"):
				lib.add_animation("Shield", sh)
			_anim_map["Shield"] = "Shield"

	# ── RunBrake ──
	if "RunBrake" not in _anim_map:
		var brake := Animation.new()
		brake.length = 0.25
		var br := brake.add_track(Animation.TYPE_VALUE)
		brake.track_set_path(br, "Humanoid/ModelRoot:rotation_degrees")
		brake.track_insert_key(br, 0.0,  Vector3(-15.0, 0.0, 0.0))
		brake.track_insert_key(br, 0.1,  Vector3(20.0,  0.0, 0.0))
		brake.track_insert_key(br, 0.25, Vector3(0.0,   0.0, 0.0))
		if not lib.has_animation("RunBrake"):
			lib.add_animation("RunBrake", brake)
		_anim_map["RunBrake"] = "RunBrake"

	# ── Pivot ──
	if "Pivot" not in _anim_map:
		var pivot := Animation.new()
		pivot.length = 0.14
		var pvr := pivot.add_track(Animation.TYPE_VALUE)
		pivot.track_set_path(pvr, "Humanoid/ModelRoot:rotation_degrees")
		pivot.track_insert_key(pvr, 0.0,  Vector3(0.0, 45.0, 0.0))
		pivot.track_insert_key(pvr, 0.14, Vector3(0.0, 0.0,  0.0))
		if not lib.has_animation("Pivot"):
			lib.add_animation("Pivot", pivot)
		_anim_map["Pivot"] = "Pivot"

	# ── JumpSquat ──
	if "JumpSquat" not in _anim_map:
		if "Squat" in _anim_map:
			_anim_map["JumpSquat"] = _anim_map["Squat"]
		else:
			var js := Animation.new()
			js.length = 0.05
			var jsp := js.add_track(Animation.TYPE_VALUE)
			js.track_set_path(jsp, "Humanoid/ModelRoot:position")
			js.track_insert_key(jsp, 0.0, Vector3(0.0, base_y - 0.12, 0.0))
			if not lib.has_animation("JumpSquat"):
				lib.add_animation("JumpSquat", js)
			_anim_map["JumpSquat"] = "JumpSquat"

	# ── Roll ──
	if "Roll" not in _anim_map:
		var roll := Animation.new()
		roll.length = 0.4
		var rlr := roll.add_track(Animation.TYPE_VALUE)
		roll.track_set_path(rlr, "Humanoid/ModelRoot:rotation_degrees")
		roll.track_insert_key(rlr, 0.0, Vector3(0.0,   0.0, 0.0))
		roll.track_insert_key(rlr, 0.4, Vector3(360.0, 0.0, 0.0))
		if not lib.has_animation("Roll"):
			lib.add_animation("Roll", roll)
		_anim_map["Roll"] = "Roll"

	# ── Spotdodge ──
	if "Spotdodge" not in _anim_map:
		var sd := Animation.new()
		sd.length = 0.35
		var sdp := sd.add_track(Animation.TYPE_VALUE)
		sd.track_set_path(sdp, "Humanoid/ModelRoot:position")
		sd.track_insert_key(sdp, 0.0,  Vector3(0.0, base_y,       -0.3))
		sd.track_insert_key(sdp, 0.18, Vector3(0.0, base_y - 0.1,  0.0))
		sd.track_insert_key(sdp, 0.35, Vector3(0.0, base_y,        0.0))
		if not lib.has_animation("Spotdodge"):
			lib.add_animation("Spotdodge", sd)
		_anim_map["Spotdodge"] = "Spotdodge"

	# ── Daze ──
	if "Daze" not in _anim_map:
		var daze := Animation.new()
		daze.loop_mode = Animation.LOOP_LINEAR
		daze.length = 0.8
		var dr := daze.add_track(Animation.TYPE_VALUE)
		daze.track_set_path(dr, "Humanoid/ModelRoot:rotation_degrees")
		daze.track_insert_key(dr, 0.0,  Vector3(0.0, 0.0,  8.0))
		daze.track_insert_key(dr, 0.4,  Vector3(0.0, 0.0, -8.0))
		daze.track_insert_key(dr, 0.8,  Vector3(0.0, 0.0,  8.0))
		if not lib.has_animation("Daze"):
			lib.add_animation("Daze", daze)
		_anim_map["Daze"] = "Daze"

	# ── Ledge (Colgado del borde) ──
	if "Ledge" not in _anim_map:
		var ledge_anim := Animation.new()
		ledge_anim.loop_mode = Animation.LOOP_LINEAR
		ledge_anim.length = 0.8
		var lp := ledge_anim.add_track(Animation.TYPE_VALUE)
		ledge_anim.track_set_path(lp, "Humanoid/ModelRoot:position")
		ledge_anim.track_insert_key(lp, 0.0,  Vector3(0.0, base_y - 0.22, 0.0))
		ledge_anim.track_insert_key(lp, 0.4,  Vector3(0.0, base_y - 0.26, 0.0))
		ledge_anim.track_insert_key(lp, 0.8,  Vector3(0.0, base_y - 0.22, 0.0))
		var lr := ledge_anim.add_track(Animation.TYPE_VALUE)
		ledge_anim.track_set_path(lr, "Humanoid/ModelRoot:rotation_degrees")
		ledge_anim.track_insert_key(lr, 0.0,  Vector3(8.0, 0.0, 0.0))
		ledge_anim.track_insert_key(lr, 0.4,  Vector3(4.0, 0.0, 0.0))
		ledge_anim.track_insert_key(lr, 0.8,  Vector3(8.0, 0.0, 0.0))
		if not lib.has_animation("Ledge"):
			lib.add_animation("Ledge", ledge_anim)
		_anim_map["Ledge"] = "Ledge"

	# ── LedgeGetup (Subida del borde) ──
	if "LedgeGetup" not in _anim_map:
		var getup_anim := Animation.new()
		getup_anim.length = 0.32
		var gp := getup_anim.add_track(Animation.TYPE_VALUE)
		getup_anim.track_set_path(gp, "Humanoid/ModelRoot:position")
		getup_anim.track_insert_key(gp, 0.0,   Vector3(0.0, base_y - 0.22, 0.0))
		getup_anim.track_insert_key(gp, 0.16,  Vector3(0.0, base_y + 0.15, 0.0))
		getup_anim.track_insert_key(gp, 0.32,  Vector3(0.0, base_y,        0.0))
		var gr := getup_anim.add_track(Animation.TYPE_VALUE)
		getup_anim.track_set_path(gr, "Humanoid/ModelRoot:rotation_degrees")
		getup_anim.track_insert_key(gr, 0.0,   Vector3(-15.0, 0.0, 0.0))
		getup_anim.track_insert_key(gr, 0.32,  Vector3(0.0,   0.0, 0.0))
		if not lib.has_animation("LedgeGetup"):
			lib.add_animation("LedgeGetup", getup_anim)
		_anim_map["LedgeGetup"] = "LedgeGetup"

	# ── AirDodge (Esquive en el aire) ──
	if "AirDodge" not in _anim_map:
		var ad_anim := Animation.new()
		ad_anim.length = 0.45
		var adr := ad_anim.add_track(Animation.TYPE_VALUE)
		ad_anim.track_set_path(adr, "Humanoid/ModelRoot:rotation_degrees")
		ad_anim.track_insert_key(adr, 0.0,   Vector3(0.0,   0.0, 0.0))
		ad_anim.track_insert_key(adr, 0.22,  Vector3(180.0, 0.0, 0.0))
		ad_anim.track_insert_key(adr, 0.45,  Vector3(360.0, 0.0, 0.0))
		var ads := ad_anim.add_track(Animation.TYPE_VALUE)
		ad_anim.track_set_path(ads, "Humanoid/ModelRoot:scale")
		ad_anim.track_insert_key(ads, 0.0,   Vector3(1.15, 1.15, 1.15))
		ad_anim.track_insert_key(ads, 0.22,  Vector3(0.9, 0.9, 0.9))
		ad_anim.track_insert_key(ads, 0.45,  Vector3(1.15, 1.15, 1.15))
		if not lib.has_animation("AirDodge"):
			lib.add_animation("AirDodge", ad_anim)
		_anim_map["AirDodge"] = "AirDodge"

	# ── RESET ──
	var reset := Animation.new()
	reset.length = 0.001
	var rtp := reset.add_track(Animation.TYPE_VALUE)
	reset.track_set_path(rtp, "Humanoid/ModelRoot:position")
	reset.track_insert_key(rtp, 0.0, Vector3(0.0, base_y, 0.0))
	var rtr := reset.add_track(Animation.TYPE_VALUE)
	reset.track_set_path(rtr, "Humanoid/ModelRoot:rotation_degrees")
	reset.track_insert_key(rtr, 0.0, Vector3(0, 0, 0))
	var rts := reset.add_track(Animation.TYPE_VALUE)
	reset.track_set_path(rts, "Humanoid/ModelRoot:scale")
	reset.track_insert_key(rts, 0.0, Vector3(1.15, 1.15, 1.15))
	if not lib.has_animation("RESET"):
		lib.add_animation("RESET", reset)

# ─────────────────────────────────────────────────────────────
# FALLBACK: Para modelos sin AnimationPlayer interno
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
	if not lib.has_animation("Ledge"):   lib.add_animation("Ledge",   _real_idle_anim())
	if not lib.has_animation("LedgeGetup"): lib.add_animation("LedgeGetup", _real_jump_anim())
	if not lib.has_animation("AirDodge"): lib.add_animation("AirDodge", _real_jump_anim())
	if not lib.has_animation("RESET"):   lib.add_animation("RESET",   _real_reset_anim())

func _real_reset_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.001
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0, Vector3(0.0, -0.9, 0.0))
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0, Vector3(0, 0, 0))
	return a

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
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,  Vector3(0.0,  0.0, 0.0))
	a.track_insert_key(track_rot, 0.8,  Vector3(0.0,  2.0, 1.0))
	a.track_insert_key(track_rot, 1.6,  Vector3(0.0,  0.0, 0.0))
	return a

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
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,   Vector3(0.0, 0.0,  3.0))
	a.track_insert_key(track_rot, 0.35,  Vector3(0.0, 0.0, -3.0))
	a.track_insert_key(track_rot, 0.7,   Vector3(0.0, 0.0,  3.0))
	return a

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
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,  Vector3(-12.0, 0.0, 0.0))
	a.track_insert_key(track_rot, 0.2,  Vector3(-15.0, 0.0, 0.0))
	a.track_insert_key(track_rot, 0.4,  Vector3(-12.0, 0.0, 0.0))
	return a

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

func _real_fall_anim() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 0.5
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,  Vector3(10.0, 0.0, 0.0))
	a.track_insert_key(track_rot, 0.25, Vector3(12.0, 0.0, 0.0))
	a.track_insert_key(track_rot, 0.5,  Vector3(10.0, 0.0, 0.0))
	return a

func _real_hit_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.35
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,   Vector3(0.0,  0.0,  0.0))
	a.track_insert_key(track_rot, 0.05,  Vector3(-20.0, 0.0, 15.0))
	a.track_insert_key(track_rot, 0.15,  Vector3(10.0,  0.0, -8.0))
	a.track_insert_key(track_rot, 0.25,  Vector3(-5.0,  0.0,  4.0))
	a.track_insert_key(track_rot, 0.35,  Vector3(0.0,   0.0,  0.0))
	return a

func _real_attack_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.4
	var base_y: float = -0.9
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,  Vector3(0.0,  0.0,  0.0))
	a.track_insert_key(track_rot, 0.1,  Vector3(-5.0, 0.0, -8.0))
	a.track_insert_key(track_rot, 0.25, Vector3(5.0,  0.0, 12.0))
	a.track_insert_key(track_rot, 0.4,  Vector3(0.0,  0.0,  0.0))
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, "Humanoid/ModelRoot:position")
	a.track_insert_key(tp, 0.0,  Vector3(0.0, base_y,        0.0))
	a.track_insert_key(tp, 0.1,  Vector3(0.1, base_y - 0.05, 0.0))
	a.track_insert_key(tp, 0.4,  Vector3(0.0, base_y,        0.0))
	return a

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

func _real_brake_anim() -> Animation:
	var a := Animation.new()
	a.length = 0.25
	var track_rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track_rot, "Humanoid/ModelRoot:rotation_degrees")
	a.track_insert_key(track_rot, 0.0,  Vector3(-12.0, 0.0, 0.0))
	a.track_insert_key(track_rot, 0.1,  Vector3(18.0,  0.0, 0.0))
	a.track_insert_key(track_rot, 0.25, Vector3(0.0,   0.0, 0.0))
	return a

# ─────────────────────────────────────────────────────────────
# PLACEHOLDER: Animaciones procedurales para cubos/maniquí
# ─────────────────────────────────────────────────────────────
func _setup_placeholder_animations() -> void:
	_resolve_placeholder_profile()
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")

	var lib := AnimationLibrary.new()
	animation_player.add_animation_library("", lib)

	var use_sakuya_profile: bool = _is_sakuya_placeholder_profile()

	lib.add_animation("RESET", _create_reset_animation())
	lib.add_animation("Idle", _create_sakuya_idle_animation() if use_sakuya_profile else _create_idle_animation())
	lib.add_animation("Walk", _create_sakuya_walk_animation() if use_sakuya_profile else _create_walk_animation())
	lib.add_animation("Run", _create_sakuya_run_animation() if use_sakuya_profile else _create_run_animation())
	lib.add_animation("RunBrake", _create_run_brake_animation())
	lib.add_animation("Pivot", _create_pivot_animation())
	lib.add_animation("Squat", _create_squat_animation())
	lib.add_animation("JumpSquat", _create_jump_squat_animation())
	lib.add_animation("Jump", _create_jump_animation())
	lib.add_animation("Fall", _create_fall_animation())
	lib.add_animation("FastFall", _create_fast_fall_animation())
	lib.add_animation("Attack", _create_attack_animation())
	lib.add_animation("AttackNeutral", _create_sakuya_attack_neutral_animation() if use_sakuya_profile else _create_attack_neutral_animation())
	lib.add_animation("AttackNeutral2", _create_sakuya_attack_neutral2_animation() if use_sakuya_profile else _create_attack_neutral2_animation())
	lib.add_animation("AttackNeutral3", _create_sakuya_attack_neutral3_animation() if use_sakuya_profile else _create_attack_neutral3_animation())
	lib.add_animation("AttackSide", _create_sakuya_attack_side_animation() if use_sakuya_profile else _create_attack_side_animation())
	lib.add_animation("AttackUp", _create_sakuya_attack_up_animation() if use_sakuya_profile else _create_attack_up_animation())
	lib.add_animation("AttackDown", _create_sakuya_attack_down_animation() if use_sakuya_profile else _create_attack_down_animation())
	lib.add_animation("NeutralAir", _create_sakuya_neutral_air_animation() if use_sakuya_profile else _create_neutral_air_animation())
	lib.add_animation("UpAir", _create_sakuya_up_air_animation() if use_sakuya_profile else _create_up_air_animation())
	lib.add_animation("DownAir", _create_sakuya_down_air_animation() if use_sakuya_profile else _create_down_air_animation())
	lib.add_animation("SpecialNeutral", _create_sakuya_special_neutral_animation() if use_sakuya_profile else _create_special_neutral_animation())
	lib.add_animation("SpecialSide", _create_sakuya_special_side_animation() if use_sakuya_profile else _create_special_side_animation())
	lib.add_animation("SpecialUp", _create_sakuya_special_up_animation() if use_sakuya_profile else _create_special_up_animation())
	lib.add_animation("SpecialDown", _create_sakuya_special_down_animation() if use_sakuya_profile else _create_special_down_animation())
	lib.add_animation("AirDodge", _create_air_dodge_animation())
	lib.add_animation("Ledge", _create_ledge_animation())
	lib.add_animation("LedgeGetup", _create_ledge_getup_animation())
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

func _create_idle_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 1.2
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.6, Vector3(0, 0.08, 0))
	anim.track_insert_key(t_pos, 1.2, Vector3(0, 0.05, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(-18, 22, 12))
	anim.track_insert_key(t_rot, 0.6, Vector3(-14, 18, 8))
	anim.track_insert_key(t_rot, 1.2, Vector3(-18, 22, 12))
	var h_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(h_rot, "Humanoid/TorsoMesh/HeadMesh:rotation_degrees")
	anim.track_insert_key(h_rot, 0.0, Vector3(18, -20, -10))
	anim.track_insert_key(h_rot, 0.6, Vector3(14, -16, -6))
	anim.track_insert_key(h_rot, 1.2, Vector3(18, -20, -10))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-40, 55, -45))
	anim.track_insert_key(lua_rot, 0.6, Vector3(-35, 50, -40))
	anim.track_insert_key(lua_rot, 1.2, Vector3(-40, 55, -45))
	var lfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lfa_rot, "Humanoid/TorsoMesh/LeftUpperArm/LeftForearm:rotation_degrees")
	anim.track_insert_key(lfa_rot, 0.0, Vector3(-110, 25, 20))
	anim.track_insert_key(lfa_rot, 0.6, Vector3(-100, 20, 15))
	anim.track_insert_key(lfa_rot, 1.2, Vector3(-110, 25, 20))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-80, -35, 25))
	anim.track_insert_key(rua_rot, 0.6, Vector3(-75, -30, 20))
	anim.track_insert_key(rua_rot, 1.2, Vector3(-80, -35, 25))
	var rfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rfa_rot, "Humanoid/TorsoMesh/RightUpperArm/RightForearm:rotation_degrees")
	anim.track_insert_key(rfa_rot, 0.0, Vector3(-90, 0, 0))
	anim.track_insert_key(rfa_rot, 0.6, Vector3(-80, 0, 0))
	anim.track_insert_key(rfa_rot, 1.2, Vector3(-90, 0, 0))
	return anim

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
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-90, 0, 0))
	anim.track_insert_key(rua_rot, 0.15, Vector3(90, 0, 0))
	anim.track_insert_key(rua_rot, 0.35, Vector3(0, 0, 0))
	var rfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rfa_rot, "Humanoid/TorsoMesh/RightUpperArm/RightForearm:rotation_degrees")
	anim.track_insert_key(rfa_rot, 0.0, Vector3(-90, 0, 0))
	anim.track_insert_key(rfa_rot, 0.15, Vector3(0, 0, 0))
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

func _create_attack_neutral_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.25
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(lua_rot, 0.08, Vector3(-85, 20, 10))
	anim.track_insert_key(lua_rot, 0.25, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.08, Vector3(-5, -15, 0))
	anim.track_insert_key(t_rot, 0.25, Vector3(0, 0, 0))
	return anim

func _create_attack_neutral2_animation() -> Animation:
	# ORA ORA FLURRY: Ráfaga rápida de puñetazos alternados estilo MUGEN/JoJo
	var anim := Animation.new()
	anim.length = 0.28
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(lua_rot, 0.05, Vector3(-95, 15, 0))
	anim.track_insert_key(lua_rot, 0.12, Vector3(10, 0, 0))
	anim.track_insert_key(lua_rot, 0.19, Vector3(-100, 15, 0))
	anim.track_insert_key(lua_rot, 0.28, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.07, Vector3(15, 0, 0))
	anim.track_insert_key(rua_rot, 0.14, Vector3(-105, -15, 0))
	anim.track_insert_key(rua_rot, 0.21, Vector3(10, 0, 0))
	anim.track_insert_key(rua_rot, 0.28, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.07, Vector3(-5, -15, 0))
	anim.track_insert_key(t_rot, 0.14, Vector3(-5, 15, 0))
	anim.track_insert_key(t_rot, 0.21, Vector3(-5, -15, 0))
	anim.track_insert_key(t_rot, 0.28, Vector3(0, 0, 0))
	return anim

func _create_attack_neutral3_animation() -> Animation:
	# KONO JOHN DA! Finisher: Gancho ascendente demoledor con torso inclinado
	var anim := Animation.new()
	anim.length = 0.38
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(30, -20, 0))
	anim.track_insert_key(rua_rot, 0.10, Vector3(45, -30, 0))
	anim.track_insert_key(rua_rot, 0.18, Vector3(-160, -10, 0))
	anim.track_insert_key(rua_rot, 0.38, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.10, Vector3(0, -0.05, 0))
	anim.track_insert_key(t_pos, 0.18, Vector3(0, 0.22, 0))
	anim.track_insert_key(t_pos, 0.38, Vector3(0, 0.05, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.10, Vector3(-10, -20, 0))
	anim.track_insert_key(t_rot, 0.18, Vector3(25, 15, 0))
	anim.track_insert_key(t_rot, 0.38, Vector3(0, 0, 0))
	return anim

func _create_attack_side_animation() -> Animation:
	# Menacing Palm Strike: Estocada frontal con desplazamiento y palma extendida
	var anim := Animation.new()
	anim.length = 0.35
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.08, Vector3(-95, -10, 0))
	anim.track_insert_key(rua_rot, 0.35, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.10, Vector3(0.2, 0.02, 0))
	anim.track_insert_key(t_pos, 0.35, Vector3(0, 0.05, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.10, Vector3(20, 0, 0))
	anim.track_insert_key(t_rot, 0.35, Vector3(0, 0, 0))
	return anim

func _create_attack_up_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.32
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(rul_rot, 0.10, Vector3(-120, 0, 0))
	anim.track_insert_key(rul_rot, 0.32, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.10, Vector3(-25, 0, 0))
	anim.track_insert_key(t_rot, 0.32, Vector3(0, 0, 0))
	return anim

func _create_attack_down_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.30
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.08, Vector3(0.15, -0.22, 0))
	anim.track_insert_key(t_pos, 0.30, Vector3(0, 0.05, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(rul_rot, 0.08, Vector3(-65, 30, 0))
	anim.track_insert_key(rul_rot, 0.30, Vector3(0, 0, 0))
	return anim

func _create_neutral_air_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.35
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.175, Vector3(0, 180, 0))
	anim.track_insert_key(t_rot, 0.35, Vector3(0, 360, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(0, 0, -50))
	anim.track_insert_key(lua_rot, 0.35, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(0, 0, 50))
	anim.track_insert_key(rua_rot, 0.35, Vector3(0, 0, 0))
	return anim

func _create_up_air_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.32
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.16, Vector3(-180, 0, 0))
	anim.track_insert_key(t_rot, 0.32, Vector3(-360, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.12, Vector3(-160, 0, 0))
	anim.track_insert_key(rua_rot, 0.32, Vector3(0, 0, 0))
	return anim

func _create_down_air_animation() -> Animation:
	# ROAD ROLLER Stomp: Pausa dramática en el aire y caída en picada destructiva
	var anim := Animation.new()
	anim.length = 0.42
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.00, Vector3(-45, 0, 0))
	anim.track_insert_key(lul_rot, 0.15, Vector3(25, 0, 0))
	anim.track_insert_key(lul_rot, 0.42, Vector3(0, 0, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.00, Vector3(-45, 0, 0))
	anim.track_insert_key(rul_rot, 0.15, Vector3(25, 0, 0))
	anim.track_insert_key(rul_rot, 0.42, Vector3(0, 0, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(-150, 20, 0))
	anim.track_insert_key(lua_rot, 0.15, Vector3(-130, 0, 0))
	anim.track_insert_key(lua_rot, 0.42, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(-150, -20, 0))
	anim.track_insert_key(rua_rot, 0.15, Vector3(-130, 0, 0))
	anim.track_insert_key(rua_rot, 0.42, Vector3(0, 0, 0))
	return anim

func _create_special_neutral_animation() -> Animation:
	# ZA PLACEHOLDER: Carga congelada en pose amenazante y descarga de poder
	var anim := Animation.new()
	anim.length = 0.50
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.18, Vector3(60, -50, 0))
	anim.track_insert_key(rua_rot, 0.26, Vector3(-105, 0, 0))
	anim.track_insert_key(rua_rot, 0.50, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.18, Vector3(-15, -45, 0))
	anim.track_insert_key(t_rot, 0.26, Vector3(30, 35, 0))
	anim.track_insert_key(t_rot, 0.50, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.18, Vector3(-0.1, 0.02, 0))
	anim.track_insert_key(t_pos, 0.26, Vector3(0.3, 0.05, 0))
	anim.track_insert_key(t_pos, 0.50, Vector3(0, 0.05, 0))
	return anim

func _create_special_up_animation() -> Animation:
	# Star Ascension: Super Uppercut giratorio ascendente hacia las estrellas
	var anim := Animation.new()
	anim.length = 0.48
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(20, 0, 0))
	anim.track_insert_key(rua_rot, 0.08, Vector3(-175, 0, 0))
	anim.track_insert_key(rua_rot, 0.48, Vector3(-90, 0, 0))
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(lul_rot, 0.08, Vector3(-70, 0, 0))
	anim.track_insert_key(lul_rot, 0.48, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.15, Vector3(0, 180, 0))
	anim.track_insert_key(t_rot, 0.30, Vector3(0, 360, 0))
	anim.track_insert_key(t_rot, 0.48, Vector3(0, 360, 0))
	return anim

func _create_special_down_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.45
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(lul_rot, 0.12, Vector3(-45, 0, 0))
	anim.track_insert_key(lul_rot, 0.45, Vector3(0, 0, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(rul_rot, 0.12, Vector3(-45, 0, 0))
	anim.track_insert_key(rul_rot, 0.45, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.12, Vector3(0, 0.25, 0))
	anim.track_insert_key(t_pos, 0.45, Vector3(0, -0.15, 0))
	return anim

func _create_air_dodge_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.45
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.22, Vector3(180, 0, 0))
	anim.track_insert_key(t_rot, 0.45, Vector3(360, 0, 0))
	return anim

func _create_ledge_animation() -> Animation:
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.8
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-165, 0, 0))
	anim.track_insert_key(lua_rot, 0.8, Vector3(-165, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-165, 0, 0))
	anim.track_insert_key(rua_rot, 0.8, Vector3(-165, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.1, 0))
	anim.track_insert_key(t_pos, 0.4, Vector3(0, -0.15, 0))
	anim.track_insert_key(t_pos, 0.8, Vector3(0, -0.1, 0))
	return anim

func _create_ledge_getup_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.32
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-165, 0, 0))
	anim.track_insert_key(lua_rot, 0.16, Vector3(-75, 0, 0))
	anim.track_insert_key(lua_rot, 0.32, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-165, 0, 0))
	anim.track_insert_key(rua_rot, 0.16, Vector3(-75, 0, 0))
	anim.track_insert_key(rua_rot, 0.32, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, -0.1, 0))
	anim.track_insert_key(t_pos, 0.16, Vector3(0, 0.2, 0))
	anim.track_insert_key(t_pos, 0.32, Vector3(0, 0.05, 0))
	return anim

func _create_special_side_animation() -> Animation:
	# Menacing Lunge Dash: Embestida veloz hacia el frente
	var anim := Animation.new()
	anim.length = 0.38
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.10, Vector3(35, 0, 0))
	anim.track_insert_key(t_rot, 0.38, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.10, Vector3(0.25, -0.05, 0))
	anim.track_insert_key(t_pos, 0.38, Vector3(0, 0.05, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(lua_rot, 0.10, Vector3(-105, 10, 0))
	anim.track_insert_key(lua_rot, 0.38, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.10, Vector3(-115, -10, 0))
	anim.track_insert_key(rua_rot, 0.38, Vector3(0, 0, 0))
	return anim

func _create_sakuya_attack_neutral_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.24
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(-18, -8, 10))
	anim.track_insert_key(rua_rot, 0.07, Vector3(-120, -28, 0))
	anim.track_insert_key(rua_rot, 0.24, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.07, Vector3(-4, -22, 0))
	anim.track_insert_key(t_rot, 0.24, Vector3(0, 0, 0))
	return anim

func _create_sakuya_attack_neutral2_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.30
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(-12, 0, 0))
	anim.track_insert_key(lua_rot, 0.08, Vector3(-110, 24, 0))
	anim.track_insert_key(lua_rot, 0.17, Vector3(6, 0, 0))
	anim.track_insert_key(lua_rot, 0.30, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.10, Vector3(-95, -22, 0))
	anim.track_insert_key(rua_rot, 0.22, Vector3(8, 0, 0))
	anim.track_insert_key(rua_rot, 0.30, Vector3(0, 0, 0))
	return anim

func _create_sakuya_attack_neutral3_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.40
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(20, -15, 0))
	anim.track_insert_key(rua_rot, 0.14, Vector3(-145, -10, 0))
	anim.track_insert_key(rua_rot, 0.40, Vector3(0, 0, 0))
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.14, Vector3(0.22, 0.10, 0))
	anim.track_insert_key(t_pos, 0.40, Vector3(0, 0.05, 0))
	return anim

func _create_sakuya_attack_side_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.34
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.09, Vector3(-120, -18, 0))
	anim.track_insert_key(rua_rot, 0.34, Vector3(0, 0, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(lua_rot, 0.09, Vector3(-40, 18, 0))
	anim.track_insert_key(lua_rot, 0.34, Vector3(0, 0, 0))
	return anim

func _create_sakuya_attack_up_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.32
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(-10, 0, 0))
	anim.track_insert_key(lua_rot, 0.11, Vector3(-165, 8, 0))
	anim.track_insert_key(lua_rot, 0.32, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.11, Vector3(-30, 6, 0))
	anim.track_insert_key(t_rot, 0.32, Vector3(0, 0, 0))
	return anim

func _create_sakuya_attack_down_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.31
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.08, Vector3(0.18, -0.18, 0))
	anim.track_insert_key(t_pos, 0.31, Vector3(0, 0.05, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rul_rot, 0.08, Vector3(-78, 26, 0))
	anim.track_insert_key(rul_rot, 0.31, Vector3(0, 0, 0))
	return anim

func _create_sakuya_neutral_air_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.34
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.17, Vector3(0, 155, 0))
	anim.track_insert_key(t_rot, 0.34, Vector3(0, 310, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(-80, -20, 0))
	anim.track_insert_key(rua_rot, 0.34, Vector3(0, 0, 0))
	return anim

func _create_sakuya_up_air_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.30
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(-20, 0, 0))
	anim.track_insert_key(lua_rot, 0.12, Vector3(-175, 10, 0))
	anim.track_insert_key(lua_rot, 0.30, Vector3(0, 0, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.12, Vector3(-155, 0, 0))
	anim.track_insert_key(t_rot, 0.30, Vector3(-320, 0, 0))
	return anim

func _create_sakuya_down_air_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.44
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.00, Vector3(-40, 0, 0))
	anim.track_insert_key(lul_rot, 0.15, Vector3(35, 0, 0))
	anim.track_insert_key(lul_rot, 0.44, Vector3(0, 0, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.00, Vector3(-40, 0, 0))
	anim.track_insert_key(rul_rot, 0.15, Vector3(35, 0, 0))
	anim.track_insert_key(rul_rot, 0.44, Vector3(0, 0, 0))
	return anim

func _create_sakuya_special_neutral_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.46
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.16, Vector3(-65, -42, 0))
	anim.track_insert_key(rua_rot, 0.46, Vector3(0, 0, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(lua_rot, 0.16, Vector3(-58, 38, 0))
	anim.track_insert_key(lua_rot, 0.46, Vector3(0, 0, 0))
	return anim

func _create_sakuya_special_side_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.44
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.12, Vector3(0.12, 0.02, 0))
	anim.track_insert_key(t_pos, 0.44, Vector3(0, 0.05, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.12, Vector3(-120, -16, 0))
	anim.track_insert_key(rua_rot, 0.44, Vector3(0, 0, 0))
	return anim

func _create_sakuya_special_up_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.50
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 0.18, Vector3(-12, 150, 0))
	anim.track_insert_key(t_rot, 0.33, Vector3(-12, 300, 0))
	anim.track_insert_key(t_rot, 0.50, Vector3(0, 360, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(10, -15, 0))
	anim.track_insert_key(rua_rot, 0.10, Vector3(-170, -8, 0))
	anim.track_insert_key(rua_rot, 0.50, Vector3(-90, 0, 0))
	return anim

func _create_sakuya_special_down_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.58
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.00, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.20, Vector3(0, 0.12, 0))
	anim.track_insert_key(t_pos, 0.58, Vector3(0, 0.05, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(lua_rot, 0.20, Vector3(-95, 28, 0))
	anim.track_insert_key(lua_rot, 0.58, Vector3(0, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.00, Vector3(0, 0, 0))
	anim.track_insert_key(rua_rot, 0.20, Vector3(-95, -28, 0))
	anim.track_insert_key(rua_rot, 0.58, Vector3(0, 0, 0))
	return anim

func _create_sakuya_idle_animation() -> Animation:
	# Elegant Maid Stance: Postura erguida y elegante con manos reposando al frente
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 1.4
	var t_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pos, "Humanoid/TorsoMesh:position")
	anim.track_insert_key(t_pos, 0.0, Vector3(0, 0.05, 0))
	anim.track_insert_key(t_pos, 0.7, Vector3(0, 0.07, 0))
	anim.track_insert_key(t_pos, 1.4, Vector3(0, 0.05, 0))
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(2, 0, 0))
	anim.track_insert_key(t_rot, 0.7, Vector3(0, 0, 0))
	anim.track_insert_key(t_rot, 1.4, Vector3(2, 0, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(-35, 25, 0))
	anim.track_insert_key(lua_rot, 0.7, Vector3(-30, 20, 0))
	anim.track_insert_key(lua_rot, 1.4, Vector3(-35, 25, 0))
	var lfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lfa_rot, "Humanoid/TorsoMesh/LeftUpperArm/LeftForearm:rotation_degrees")
	anim.track_insert_key(lfa_rot, 0.0, Vector3(-80, 0, 0))
	anim.track_insert_key(lfa_rot, 0.7, Vector3(-75, 0, 0))
	anim.track_insert_key(lfa_rot, 1.4, Vector3(-80, 0, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(-35, -25, 0))
	anim.track_insert_key(rua_rot, 0.7, Vector3(-30, -20, 0))
	anim.track_insert_key(rua_rot, 1.4, Vector3(-35, -25, 0))
	var rfa_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rfa_rot, "Humanoid/TorsoMesh/RightUpperArm/RightForearm:rotation_degrees")
	anim.track_insert_key(rfa_rot, 0.0, Vector3(-80, 0, 0))
	anim.track_insert_key(rfa_rot, 0.7, Vector3(-75, 0, 0))
	anim.track_insert_key(rfa_rot, 1.4, Vector3(-80, 0, 0))
	return anim

func _create_sakuya_walk_animation() -> Animation:
	# Graceful Maid Walk
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.6
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(4, 0, 4))
	anim.track_insert_key(t_rot, 0.3, Vector3(4, 0, -4))
	anim.track_insert_key(t_rot, 0.6, Vector3(4, 0, 4))
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.0, Vector3(25, 0, 0))
	anim.track_insert_key(lul_rot, 0.3, Vector3(-25, 0, 0))
	anim.track_insert_key(lul_rot, 0.6, Vector3(25, 0, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(-25, 0, 0))
	anim.track_insert_key(rul_rot, 0.3, Vector3(25, 0, 0))
	anim.track_insert_key(rul_rot, 0.6, Vector3(-25, 0, 0))
	return anim

func _create_sakuya_run_animation() -> Animation:
	# Swift Maid Dash
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.36
	var t_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_rot, "Humanoid/TorsoMesh:rotation_degrees")
	anim.track_insert_key(t_rot, 0.0, Vector3(20, 0, 0))
	var lua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lua_rot, "Humanoid/TorsoMesh/LeftUpperArm:rotation_degrees")
	anim.track_insert_key(lua_rot, 0.0, Vector3(30, 15, 0))
	var rua_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rua_rot, "Humanoid/TorsoMesh/RightUpperArm:rotation_degrees")
	anim.track_insert_key(rua_rot, 0.0, Vector3(30, -15, 0))
	var lul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lul_rot, "Humanoid/LeftUpperLeg:rotation_degrees")
	anim.track_insert_key(lul_rot, 0.0, Vector3(45, 0, 0))
	anim.track_insert_key(lul_rot, 0.18, Vector3(-45, 0, 0))
	anim.track_insert_key(lul_rot, 0.36, Vector3(45, 0, 0))
	var rul_rot := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rul_rot, "Humanoid/RightUpperLeg:rotation_degrees")
	anim.track_insert_key(rul_rot, 0.0, Vector3(-45, 0, 0))
	anim.track_insert_key(rul_rot, 0.18, Vector3(45, 0, 0))
	anim.track_insert_key(rul_rot, 0.36, Vector3(-45, 0, 0))
	return anim
