class_name AnimationController
extends Node

## AnimationPlayer asignado desde el inspector (o detectado automáticamente)
@export var animation_player: AnimationPlayer

var _character: Node = null
var _active_player: AnimationPlayer = null
var _current_animation_name: String = ""
var _current_speed: float = 1.0

# Aliases de compatibilidad para nombres estándar de estados
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

func _ready() -> void:
	_character = get_parent()
	_refresh_active_player()

func setup(data: CharacterData = null) -> void:
	_character = get_parent()
	if not animation_player and _character and _character.has_node("AnimationPlayer"):
		animation_player = _character.get_node("AnimationPlayer")
	if data and data.animation_library and animation_player:
		if animation_player.has_animation_library(""):
			animation_player.remove_animation_library("")
		animation_player.add_animation_library("", data.animation_library)
	_refresh_active_player()
	
	# Si la máquina de estados ya tiene un estado inicial, reproducirlo
	if _character and _character.has_node("StateMachine"):
		var fsm = _character.get_node("StateMachine")
		if fsm and fsm.current_state:
			play_animation(fsm.current_state.name)

func set_paused(paused: bool) -> void:
	if _active_player:
		_active_player.speed_scale = 0.0 if paused else 1.0
	if animation_player and animation_player != _active_player:
		animation_player.speed_scale = 0.0 if paused else 1.0


## Busca y actualiza la referencia al AnimationPlayer activo
func _refresh_active_player() -> void:
	# 1. Si hay un modelo 3D instanciado con su propio AnimationPlayer, tiene prioridad
	if _character:
		var model_root: Node = _character.get_node_or_null("Humanoid/ModelRoot")
		if model_root:
			var found: AnimationPlayer = _find_animation_player(model_root)
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

## Reproduce una animación por nombre con tiempo de mezcla (blend) y velocidad opcionales
func play_animation(anim_name: String, custom_speed: float = 1.0, blend_time: float = 0.15) -> void:
	_current_animation_name = anim_name
	_current_speed = custom_speed
	
	if not _active_player:
		_refresh_active_player()
	if not _active_player:
		return

	var resolved_name: String = _resolve_animation_name(anim_name)
	var clip_to_play: String = _find_clip_in_player(_active_player, resolved_name)
	
	# Si no se encontró la versión direccional, probar con el nombre base
	if clip_to_play == "" and resolved_name != anim_name:
		clip_to_play = _find_clip_in_player(_active_player, anim_name)
	
	# Fallback alternativo en el AnimationPlayer raíz si el del modelo no la tiene
	if clip_to_play == "" and animation_player and animation_player != _active_player:
		clip_to_play = _find_clip_in_player(animation_player, resolved_name)
		if clip_to_play != "":
			animation_player.play(clip_to_play, blend_time, custom_speed)
			return

	if clip_to_play != "":
		_active_player.play(clip_to_play, blend_time, custom_speed)

## Reproduce una animación de ataque escalando su velocidad para calzar con la duración del hitbox
func play_attack_animation(anim_name: String, target_duration: float = 0.0) -> void:
	var speed: float = 1.0
	if target_duration > 0.0:
		var clip_len: float = get_animation_length(anim_name)
		if clip_len > 0.0:
			speed = clamp(clip_len / target_duration, 0.5, 4.0)
	# Transición instantánea (0.02s / ~1 frame) para que las poses de combate sean ultra-marcadas y claras
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

func stop() -> void:
	if _active_player and _active_player.is_playing():
		_active_player.stop()
	if animation_player and animation_player.is_playing():
		animation_player.stop()

func on_facing_direction_changed(_dir: float) -> void:
	if _current_animation_name != "":
		var base_name: String = _current_animation_name.replace("_Left", "")
		if base_name in ["Idle", "Walk", "Run", "Dash"]:
			play_animation(base_name, _current_speed)

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
			
	# 2. Búsqueda por terminación / sufijo (ej: "Sakuya_Armature|walk", "rig - idle")
	for full_name in anim_list:
		var lower: String = full_name.to_lower()
		if lower.ends_with("/" + target_lower) or lower.ends_with("-" + target_lower) or lower.ends_with("|" + target_lower) or lower.ends_with("_" + target_lower):
			return full_name
			
	# 3. Fallback a nombres en español para modelos GLB con animaciones en español (ej: "salto", "caida", "ataque")
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
	if SPANISH_FALLBACKS.has(target_lower):
		var es_target: String = SPANISH_FALLBACKS[target_lower]
		for full_name in anim_list:
			var bare_name: String = full_name.get_slice("/", full_name.get_slice_count("/") - 1) if "/" in full_name else full_name
			var lower: String = full_name.to_lower()
			if bare_name.to_lower() == es_target or lower.ends_with("-" + es_target) or lower.ends_with("/" + es_target) or lower.ends_with("|" + es_target) or lower.ends_with("_" + es_target):
				return full_name
			
	return ""
