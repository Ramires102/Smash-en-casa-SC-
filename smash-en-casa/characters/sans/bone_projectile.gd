class_name BoneProjectile
extends Projectile

@export var rotation_speed: float = 16.0
@onready var bone_spinner: Node3D = get_node_or_null("Visual3D/BoneSpinner")

func _ready() -> void:
	super._ready()
	var sfx: AudioStream = preload("res://assets/audio/sfx/undertale_bone.wav")
	if AudioManager and sfx:
		AudioManager.play_sfx(sfx, randf_range(0.95, 1.1))

func _process(delta: float) -> void:
	super._process(delta)
	if bone_spinner and not is_time_frozen:
		bone_spinner.rotate_z(rotation_speed * delta)
