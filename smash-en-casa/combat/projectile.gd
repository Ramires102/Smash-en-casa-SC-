# ==============================================================================
# Projectile — Clase Base para Proyectiles Híbridos 2D/3D
# ==============================================================================
# Se mueve y colisiona en 2D (Area2D en capa 8 -> máscara 4) mientras sincroniza
# su nodo hijo "Visual3D" en el espacio 3D.
# Soporta congelamiento automático durante el Time Stop de Sakuya y caída de daño
# según la distancia recorrida (Damage Falloff).
# Subclases especializadas: BoneProjectile, GasterBlasterProjectile,
# SpikeBallProjectile y WeaverlingProjectile.
# ==============================================================================
class_name Projectile
extends Area2D

signal hit_confirmed(impact: ImpactData)

@export var speed: float = 650.0
@export var lifetime: float = 2.5
## Propiedad conservada por compatibilidad con escenas .tscn de proyectiles heredados.
@export var is_silver_knife: bool = true

var velocity: Vector2 = Vector2.ZERO
var original_velocity: Vector2 = Vector2.ZERO
var attack_data: AttackData
var owner_character: Node2D = null
var current_swing_id: int = -1
var hit_hurtboxes: Array[Hurtbox] = []
var is_time_frozen: bool = false

var _spawn_clear_timer: float = -1.0
var _time_alive: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var visual_3d: Node3D = get_node_or_null("Visual3D")

func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	monitoring = true
	area_entered.connect(_on_area_entered)
	_sync_visual()

	Events.time_stop_started.connect(_on_time_stop_started)
	Events.time_stop_ended.connect(_on_time_stop_ended)

	# Si nace durante Time Stop, avanza un instante para despegar de la mano antes de congelarse
	_spawn_clear_timer = 0.05 if Events.is_time_stopped else -1.0
	call_deferred("_check_immediate_overlaps")

func _exit_tree() -> void:
	if Events.time_stop_started.is_connected(_on_time_stop_started):
		Events.time_stop_started.disconnect(_on_time_stop_started)
	if Events.time_stop_ended.is_connected(_on_time_stop_ended):
		Events.time_stop_ended.disconnect(_on_time_stop_ended)

## Inicializa dirección, velocidad, tiempo de vida y swing_id tras instanciar la escena.
func setup(data: AttackData, attacker: Node2D, direction: Vector2, custom_speed: float, max_lifetime: float) -> void:
	attack_data = data
	owner_character = attacker
	_spawn_position = global_position
	speed = (custom_speed * Constants.UNIT_SIZE) if custom_speed > 0.0 else 650.0
	lifetime = max_lifetime if max_lifetime > 0.0 else 2.5
	original_velocity = direction.normalized() * speed
	velocity = original_velocity
	current_swing_id = Hitbox.next_swing_id()

	if direction.length_squared() > 0.001:
		rotation = atan2(direction.y, direction.x)
	_sync_visual()

func _process(_delta: float) -> void:
	_sync_visual()

func _physics_process(delta: float) -> void:
	if _spawn_clear_timer > 0.0:
		_spawn_clear_timer -= delta
		if _spawn_clear_timer <= 0.0 and Events.is_time_stopped:
			is_time_frozen = true
			velocity = Vector2.ZERO

	if is_time_frozen:
		return

	global_position += velocity * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _sync_visual() -> void:
	if visual_3d:
		visual_3d.position = Utils.pos_2d_to_3d(global_position)
		visual_3d.rotation.z = -rotation

func _on_time_stop_started(_duration: float, _instigator: Node) -> void:
	is_time_frozen = true
	velocity = Vector2.ZERO

func _on_time_stop_ended() -> void:
	is_time_frozen = false
	velocity = original_velocity

func _check_immediate_overlaps() -> void:
	if monitoring:
		for area in get_overlapping_areas():
			_on_area_entered(area)

func _on_area_entered(area: Area2D) -> void:
	if not monitoring or is_time_frozen:
		return

	if area is Hurtbox and area not in hit_hurtboxes:
		var target_owner: Node2D = area.owner_character if area.owner_character != null else (area.get_parent() as Node2D)
		if target_owner != owner_character:
			hit_hurtboxes.append(area)
			_process_projectile_hit(area, target_owner)
			queue_free()

func _evaluate_projectile_damage() -> float:
	if attack_data == null:
		return 3.0
	if not attack_data.use_distance_damage_falloff:
		return attack_data.damage
	var dist_meters: float = _spawn_position.distance_to(global_position) / Constants.UNIT_SIZE
	if dist_meters <= attack_data.close_range_max_meters:
		return attack_data.close_range_damage
	if dist_meters <= attack_data.mid_range_max_meters:
		return attack_data.mid_range_damage
	return attack_data.far_range_damage

func _process_projectile_hit(hurtbox: Hurtbox, target_owner: Node2D) -> void:
	var facing: float = signf(velocity.x) if absf(velocity.x) > 0.01 else 1.0
	var atk_name: String = attack_data.attack_name if attack_data else "Projectile"
	var impact: ImpactData = ImpactData.create_from_attack(
		current_swing_id,
		owner_character,
		target_owner,
		attack_data,
		_evaluate_projectile_damage(),
		atk_name,
		facing
	)
	hit_confirmed.emit(impact)
	hurtbox.receive_impact(impact)
