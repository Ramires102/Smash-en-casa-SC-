class_name TimeStopOverlay
extends CanvasLayer

@export var overlay_rect: ColorRect
var _material: ShaderMaterial
var _tween: Tween
var _current_instigator: Node = null

var sfx_activate: AudioStream = preload("res://assets/audio/sfx/time_stop_activate.wav")
var sfx_resume: AudioStream = preload("res://assets/audio/sfx/time_stop_resume.wav")

func _ready() -> void:
	layer = 15
	if overlay_rect == null:
		overlay_rect = $ColorRect
		
	if overlay_rect and overlay_rect.material is ShaderMaterial:
		_material = overlay_rect.material as ShaderMaterial
		_reset_shader()
		
	Events.time_stop_started.connect(_on_time_stop_started)
	Events.time_stop_ended.connect(_on_time_stop_ended)

func _exit_tree() -> void:
	if Events.time_stop_started.is_connected(_on_time_stop_started):
		Events.time_stop_started.disconnect(_on_time_stop_started)
	if Events.time_stop_ended.is_connected(_on_time_stop_ended):
		Events.time_stop_ended.disconnect(_on_time_stop_ended)

func _reset_shader() -> void:
	if _material:
		_material.set_shader_parameter("shockwave_radius", 0.0)
		_material.set_shader_parameter("grayscale_mix", 0.0)
		_material.set_shader_parameter("chromatic_aberration", 0.0)
		_material.set_shader_parameter("flash_intensity", 0.0)
		_material.set_shader_parameter("shockwave_center", Vector2(0.5, 0.5))

func _on_time_stop_started(_duration: float, instigator: Node) -> void:
	_current_instigator = instigator
	AudioManager.play_sfx(sfx_activate)

	if not _material:
		return
		
	if _tween and _tween.is_valid():
		_tween.kill()
		
	var center_uv := Vector2(0.5, 0.5)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera and instigator and is_instance_valid(instigator):
		var inst_3d_pos := Vector3.ZERO
		if instigator is Character and instigator.visual_root_3d:
			inst_3d_pos = instigator.visual_root_3d.global_position
		elif "global_position" in instigator:
			if instigator.global_position is Vector2:
				inst_3d_pos = Vector3(instigator.global_position.x / Constants.UNIT_SIZE, -instigator.global_position.y / Constants.UNIT_SIZE, 0.0)
			elif instigator.global_position is Vector3:
				inst_3d_pos = instigator.global_position
		var screen_pos = camera.unproject_position(inst_3d_pos)
		var viewport_size = get_viewport().get_visible_rect().size
		if viewport_size.x > 0 and viewport_size.y > 0:
			center_uv = screen_pos / viewport_size
			
	_material.set_shader_parameter("shockwave_center", center_uv)
	_material.set_shader_parameter("shockwave_radius", 0.0)
	_material.set_shader_parameter("chromatic_aberration", 0.035)
	_material.set_shader_parameter("flash_intensity", 0.6)
	_material.set_shader_parameter("grayscale_mix", 0.0)
	
	_tween = create_tween().set_parallel(true)
	# 1. Expansión rápida de la onda de choque y aberración
	_tween.tween_property(_material, "shader_parameter/shockwave_radius", 1.8, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_material, "shader_parameter/chromatic_aberration", 0.005, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Desvanecer destello inicial e instaurar escala de grises
	_tween.tween_property(_material, "shader_parameter/flash_intensity", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_material, "shader_parameter/grayscale_mix", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _on_time_stop_ended() -> void:
	AudioManager.play_sfx(sfx_resume)

	if not _material:
		return
		
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_material.set_shader_parameter("flash_intensity", 0.75)
	
	_tween = create_tween().set_parallel(true)
	# Destello blanco de descongelación y retorno inmediato de colores
	_tween.tween_property(_material, "shader_parameter/flash_intensity", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_material, "shader_parameter/grayscale_mix", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_material, "shader_parameter/shockwave_radius", 0.0, 0.1)
	_tween.tween_property(_material, "shader_parameter/chromatic_aberration", 0.0, 0.1)
