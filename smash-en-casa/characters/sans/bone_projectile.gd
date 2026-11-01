# ==============================================================================
# BoneProjectile — Hueso Giratorio (Sans Side Special)
# ==============================================================================
# Proyectil lineal que rota su malla 3D continuamente mientras viaja y reproduce
# el efecto de sonido clásico al ser invocado.
# ==============================================================================
class_name BoneProjectile
extends Projectile

const BONE_SFX: AudioStream = preload("res://assets/audio/sfx/undertale_bone.wav")

@export var rotation_speed: float = 16.0
@onready var bone_spinner: Node3D = get_node_or_null("Visual3D/BoneSpinner")

func _ready() -> void:
	super._ready()
	if BONE_SFX:
		AudioManager.play_sfx(BONE_SFX, randf_range(0.95, 1.1))

func _process(delta: float) -> void:
	super._process(delta)
	if bone_spinner and not is_time_frozen:
		bone_spinner.rotate_z(rotation_speed * delta)
