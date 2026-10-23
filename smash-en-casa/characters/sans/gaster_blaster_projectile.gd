class_name GasterBlasterProjectile
extends Projectile

@onready var laser_mesh: MeshInstance3D = get_node_or_null("Visual3D/LaserBeam")
@onready var skull_container: Node3D = get_node_or_null("Visual3D/SkullContainer")
@onready var cranium_mesh: MeshInstance3D = get_node_or_null("Visual3D/SkullContainer/CraniumMesh")
@onready var jaw_pivot: Node3D = get_node_or_null("Visual3D/SkullContainer/JawPivot")
@onready var charge_core: MeshInstance3D = get_node_or_null("Visual3D/SkullContainer/ChargeCore")
@onready var laser_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var _charge_time_total: float = 0.28
var _charge_timer: float = 0.28
var _beam_fired: bool = false
var _blast_duration: float = 0.45
var _blast_elapsed: float = 0.0
var _base_skull_pos: Vector3 = Vector3.ZERO
var _exit_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Durante la carga previa, el láser y las colisiones están estrictamente APAGADOS
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
		skull_container.scale = Vector3(0.2, 0.2, 0.2)
	
	# Sonido de carga/invocación
	var sfx: AudioStream = preload("res://assets/audio/sfx/undertale_gaster.wav")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and sfx:
		audio_mgr.play_sfx(sfx, 1.0)
	
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_time_frozen:
		return

	# --- FASE 1: APARICIÓN Y APERTURA DE MANDÍBULA (CARGA) ---
	if not _beam_fired:
		_charge_timer -= delta
		var charge_progress: float = clampf(1.0 - (_charge_timer / _charge_time_total), 0.0, 1.0)
		
		# 1. Pop-in de escala inicial rápida
		if skull_container:
			var enter_t: float = clampf(charge_progress * 3.5, 0.0, 1.0)
			var cur_scale: float = ease(enter_t, 0.3)
			skull_container.scale = Vector3(cur_scale, cur_scale, cur_scale)
			
			# Temblor de acumulación de poder
			skull_container.position = _base_skull_pos + Vector3(
				randf_range(-0.025, 0.025) * charge_progress,
				randf_range(-0.035, 0.035) * charge_progress,
				0.0
			)

		# 2. Animación de apertura de fauces
		var mouth_open_t: float = ease(charge_progress, -2.0)
		if jaw_pivot:
			jaw_pivot.rotation_degrees.z = -38.0 * mouth_open_t
		if cranium_mesh:
			cranium_mesh.rotation_degrees.z = 14.0 * mouth_open_t

		# 3. Núcleo de energía condensándose en la boca
		if charge_core:
			var core_pulse: float = mouth_open_t * (1.0 + sin(charge_progress * 35.0) * 0.25)
			charge_core.scale = Vector3(core_pulse, core_pulse, core_pulse)

		# 4. Al completar la carga -> ¡DISPARAR EL LÁSER!
		if _charge_timer <= 0.0:
			_fire_laser()
		return

	# --- FASE 2: DISPARO ACTIVO CON RETROCESO ---
	if _beam_fired and _blast_elapsed < _blast_duration:
		_blast_elapsed += delta
		
		# Pulso y vibración del haz
		if laser_mesh:
			var pulse: float = 1.0 + sin(_blast_elapsed * 45.0) * 0.18
			laser_mesh.scale.y = pulse
			laser_mesh.scale.z = pulse
			
		# Retroceso brusco del cráneo hacia atrás
		if skull_container:
			var recoil: float = -0.22 * exp(-_blast_elapsed * 7.0)
			skull_container.position.x = _base_skull_pos.x + recoil

		# Mantener las fauces bien abiertas durante el rayo
		if jaw_pivot:
			jaw_pivot.rotation_degrees.z = -40.0 + sin(_blast_elapsed * 30.0) * 2.0
		if cranium_mesh:
			cranium_mesh.rotation_degrees.z = 15.0 - sin(_blast_elapsed * 30.0) * 1.5
			
		if _blast_elapsed >= _blast_duration:
			_finish_blast()
		return

	# --- FASE 3: CIERRE DE BOCA Y DESAPARICIÓN ---
	if _exit_timer > 0.0:
		_exit_timer -= delta
		var exit_progress: float = 1.0 - (_exit_timer / 0.12)
		if jaw_pivot:
			jaw_pivot.rotation_degrees.z = lerpf(-40.0, 0.0, exit_progress)
		if cranium_mesh:
			cranium_mesh.rotation_degrees.z = lerpf(15.0, 0.0, exit_progress)
		if skull_container:
			var s: float = maxf(0.0, 1.0 - exit_progress)
			skull_container.scale = Vector3(s, s, s)
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
		
	var ev = get_node_or_null("/root/Events")
	if ev and ev.has_signal("camera_shake_requested"):
		ev.camera_shake_requested.emit(9.5)
	
	_check_immediate_overlaps()

func _finish_blast() -> void:
	if laser_mesh:
		laser_mesh.visible = false
	if laser_shape:
		laser_shape.disabled = true
	monitoring = false
	_exit_timer = 0.12

func _sync_visual() -> void:
	if visual_3d:
		visual_3d.position = Vector3(
			global_position.x / Constants.UNIT_SIZE,
			-global_position.y / Constants.UNIT_SIZE,
			0.0
		)
		visual_3d.rotation.z = -rotation
