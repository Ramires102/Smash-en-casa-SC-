class_name GasterBlasterProjectile
extends Projectile

@onready var laser_mesh: MeshInstance3D = get_node_or_null("Visual3D/LaserBeam")
@onready var skull_mesh: Node3D = get_node_or_null("Visual3D/SkullContainer")
@onready var laser_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var _charge_timer: float = 0.22
var _beam_fired: bool = false
var _blast_duration: float = 0.45
var _blast_elapsed: float = 0.0

func _ready() -> void:
	super._ready()
	# Durante la carga, el rayo está inactivo
	if laser_shape:
		laser_shape.disabled = true
	if laser_mesh:
		laser_mesh.visible = false
	
	var sfx: AudioStream = preload("res://assets/audio/sfx/undertale_gaster.wav")
	if AudioManager and sfx:
		AudioManager.play_sfx(sfx, 1.0)
	
	# El Blaster se ancla y apunta en la dirección de lanzamiento
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_time_frozen:
		return

	if _charge_timer > 0.0:
		_charge_timer -= delta
		if skull_mesh:
			# Vibración de carga
			skull_mesh.position.y += randf_range(-0.03, 0.03)
		if _charge_timer <= 0.0:
			_fire_laser()
		return

	# Fase del disparo
	if _beam_fired:
		_blast_elapsed += delta
		if laser_mesh:
			# Pulso del haz de energía
			var pulse: float = 1.0 + sin(_blast_elapsed * 40.0) * 0.15
			laser_mesh.scale.y = pulse
			laser_mesh.scale.z = pulse
			
		if _blast_elapsed >= _blast_duration:
			queue_free()

func _fire_laser() -> void:
	_beam_fired = true
	if laser_shape:
		laser_shape.disabled = false
	if laser_mesh:
		laser_mesh.visible = true
	Events.camera_shake_requested.emit(8.5)
	
	# Recalcular colisiones inmediatas para golpear a los rivales dentro del haz
	_check_immediate_overlaps()

func _sync_visual() -> void:
	if visual_3d:
		visual_3d.position = Vector3(
			global_position.x / Constants.UNIT_SIZE,
			-global_position.y / Constants.UNIT_SIZE,
			0.0
		)
		visual_3d.rotation.z = -rotation
