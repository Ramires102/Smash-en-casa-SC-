class_name ScreenShake
extends Node

@export var camera: Camera3D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var rng := RandomNumberGenerator.new()

func _process(delta: float) -> void:
	if shake_intensity > 0.0 and camera:
		camera.h_offset = rng.randf_range(-shake_intensity, shake_intensity)
		camera.v_offset = rng.randf_range(-shake_intensity, shake_intensity)
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
	elif camera:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

func trigger_shake(intensity: float = 0.5) -> void:
	shake_intensity = intensity
