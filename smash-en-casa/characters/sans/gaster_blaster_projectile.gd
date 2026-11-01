# ==============================================================================
# GasterBlasterProjectile — Cráneo Láser Estacionario (Sans Neutral Special)
# ==============================================================================
# Opera en tres fases cronometradas:
#   1. Carga (0.28s): aparece con pop-in, abre la mandíbula y condensa energía.
#   2. Disparo (0.45s): activa el haz láser y su colisión 2D con retroceso visual.
#   3. Salida (0.12s): cierra las fauces, se encoge y se libera de memoria.
# ==============================================================================
class_name GasterBlasterProjectile
extends Projectile

const GASTER_SFX: AudioStream = preload("res://assets/audio/sfx/undertale_gaster.wav")
const CHARGE_DURATION_SEC: float = 0.28
const BLAST_DURATION_SEC: float = 0.45
const EXIT_DURATION_SEC: float = 0.12

@onready var laser_mesh: MeshInstance3D = get_node_or_null("Visual3D/LaserBeam")
@onready var skull_container: Node3D = get_node_or_null("Visual3D/SkullContainer")
@onready var cranium_mesh: MeshInstance3D = get_node_or_null("Visual3D/SkullContainer/CraniumMesh")
@onready var jaw_pivot: Node3D = get_node_or_null("Visual3D/SkullContainer/JawPivot")
@onready var charge_core: MeshInstance3D = get_node_or_null("Visual3D/SkullContainer/ChargeCore")
@onready var laser_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var _charge_timer: float = CHARGE_DURATION_SEC
var _beam_fired: bool = false
var _blast_elapsed: float = 0.0
var _base_skull_pos: Vector3 = Vector3.ZERO
var _exit_timer: float = 0.0

#region Inicialización
func _ready() -> void:
	super._ready()
	if laser_shape:
		laser_shape.disabled = true
	monitoring = false

	if laser_mesh:
		laser_mesh.visible = false
	if charge_core:
		charge_core.visible = true
		charge_core.scale = Vector3.ZERO
	if skull_container:
		_base_skull_pos = skull_container.position
		skull_container.visible = true
		skull_container.scale = Vector3.ONE * 0.2

	if GASTER_SFX:
		AudioManager.play_sfx(GASTER_SFX, 1.0)
	velocity = Vector2.ZERO
#endregion

#region Máquina de Fases (Carga -> Disparo -> Salida)
func _physics_process(delta: float) -> void:
	if is_time_frozen:
		return

	if not _beam_fired:
		_update_charge_phase(delta)
	elif _blast_elapsed < BLAST_DURATION_SEC:
		_update_blast_phase(delta)
	elif _exit_timer > 0.0:
		_update_exit_phase(delta)

func _update_charge_phase(delta: float) -> void:
	_charge_timer -= delta
	var charge_progress: float = clampf(1.0 - (_charge_timer / CHARGE_DURATION_SEC), 0.0, 1.0)

	if skull_container:
		var enter_t: float = clampf(charge_progress * 3.5, 0.0, 1.0)
		skull_container.scale = Vector3.ONE * ease(enter_t, 0.3)
		skull_container.position = _base_skull_pos + Vector3(
			randf_range(-0.025, 0.025) * charge_progress,
			randf_range(-0.035, 0.035) * charge_progress,
			0.0
		)

	var mouth_open_t: float = ease(charge_progress, -2.0)
	if jaw_pivot:
		jaw_pivot.rotation_degrees.z = -38.0 * mouth_open_t
	if cranium_mesh:
		cranium_mesh.rotation_degrees.z = 14.0 * mouth_open_t
	if charge_core:
		var core_pulse: float = mouth_open_t * (1.0 + sin(charge_progress * 35.0) * 0.25)
		charge_core.scale = Vector3.ONE * core_pulse

	if _charge_timer <= 0.0:
		_fire_laser()

func _update_blast_phase(delta: float) -> void:
	_blast_elapsed += delta
	if laser_mesh:
		var pulse: float = 1.0 + sin(_blast_elapsed * 45.0) * 0.18
		laser_mesh.scale.y = pulse
		laser_mesh.scale.z = pulse

	if skull_container:
		var recoil: float = -0.22 * exp(-_blast_elapsed * 7.0)
		skull_container.position.x = _base_skull_pos.x + recoil

	if jaw_pivot:
		jaw_pivot.rotation_degrees.z = -40.0 + sin(_blast_elapsed * 30.0) * 2.0
	if cranium_mesh:
		cranium_mesh.rotation_degrees.z = 15.0 - sin(_blast_elapsed * 30.0) * 1.5

	if _blast_elapsed >= BLAST_DURATION_SEC:
		_finish_blast()

func _update_exit_phase(delta: float) -> void:
	_exit_timer -= delta
	var exit_progress: float = 1.0 - (_exit_timer / EXIT_DURATION_SEC)
	if jaw_pivot:
		jaw_pivot.rotation_degrees.z = lerpf(-40.0, 0.0, exit_progress)
	if cranium_mesh:
		cranium_mesh.rotation_degrees.z = lerpf(15.0, 0.0, exit_progress)
	if skull_container:
		skull_container.scale = Vector3.ONE * maxf(0.0, 1.0 - exit_progress)
	if _exit_timer <= 0.0:
		queue_free()

func _fire_laser() -> void:
	_beam_fired = true
	monitoring = true
	if laser_shape:
		laser_shape.disabled = false
	if laser_mesh:
		laser_mesh.visible = true
	if charge_core:
		charge_core.visible = false

	Events.camera_shake_requested.emit(9.5)
	_check_immediate_overlaps()

func _finish_blast() -> void:
	if laser_mesh:
		laser_mesh.visible = false
	if laser_shape:
		laser_shape.disabled = true
	monitoring = false
	_exit_timer = EXIT_DURATION_SEC

func _sync_visual() -> void:
	if visual_3d:
		visual_3d.position = Utils.pos_2d_to_3d(global_position)
		visual_3d.rotation.z = -rotation
#endregion
