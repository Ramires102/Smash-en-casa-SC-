class_name Projectile
extends Area2D

signal hit_confirmed(impact: ImpactData)

@export var speed: float = 650.0  ## Velocidad en px/s (SND standard)
@export var lifetime: float = 2.5
@export var is_silver_knife: bool = true

var velocity: Vector2 = Vector2.ZERO
var attack_data: AttackData
var owner_character: Node2D = null
var current_swing_id: int = -1
var hit_hurtboxes: Array[Hurtbox] = []
var is_time_frozen: bool = false
var original_velocity: Vector2 = Vector2.ZERO
var _spawn_clear_timer: float = 0.06
var _time_alive: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var visual_3d: Node3D = get_node_or_null("Visual3D")

func _ready() -> void:
	collision_layer = 8 # Hitbox layer
	collision_mask = 4  # Hurtbox layer
	monitoring = true
	area_entered.connect(_on_area_entered)
	_sync_visual()


	Events.time_stop_started.connect(_on_time_stop_started)
	Events.time_stop_ended.connect(_on_time_stop_ended)

	if Events.is_time_stopped:
		_spawn_clear_timer = 0.05
	else:
		_spawn_clear_timer = -1.0

	call_deferred("_check_immediate_overlaps")

func _exit_tree() -> void:
	if Events.time_stop_started.is_connected(_on_time_stop_started):
		Events.time_stop_started.disconnect(_on_time_stop_started)
	if Events.time_stop_ended.is_connected(_on_time_stop_ended):
		Events.time_stop_ended.disconnect(_on_time_stop_ended)

func setup(data: AttackData, attacker: Node2D, direction: Vector2, custom_speed: float, max_lifetime: float) -> void:
	attack_data = data
	owner_character = attacker
	_spawn_position = global_position
	speed = (custom_speed * Constants.UNIT_SIZE) if custom_speed > 0.0 else 650.0
	lifetime = max_lifetime if max_lifetime > 0.0 else 2.5
	original_velocity = direction.normalized() * speed
	velocity = original_velocity
	current_swing_id = Hitbox._next_swing_id + 1
	Hitbox._next_swing_id += 1
	
	if direction.length_squared() > 0.001:
		rotation = atan2(direction.y, direction.x)
	_sync_visual()

func _on_time_stop_started(_duration: float, _instigator: Node) -> void:
	is_time_frozen = true
	velocity = Vector2.ZERO

func _on_time_stop_ended() -> void:
	is_time_frozen = false
	velocity = original_velocity

func _process(_delta: float) -> void:
	_sync_visual()

func _sync_visual() -> void:
	if visual_3d:
		visual_3d.position = Vector3(
			global_position.x / Constants.UNIT_SIZE,
			-global_position.y / Constants.UNIT_SIZE,
			0.0
		)
		visual_3d.rotation.z = -rotation

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

func _check_immediate_overlaps() -> void:
	if monitoring:
		for area in get_overlapping_areas():
			_on_area_entered(area)

func _on_area_entered(area: Area2D) -> void:
	if not monitoring or is_time_frozen:
		return
		
	if area is Hurtbox and area not in hit_hurtboxes:
		var target_owner: Node2D = area.owner_character
		if target_owner == null:
			target_owner = area.get_parent()
			
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
	elif dist_meters <= attack_data.mid_range_max_meters:
		return attack_data.mid_range_damage
	return attack_data.far_range_damage

func _process_projectile_hit(hurtbox: Hurtbox, target_owner: Node2D) -> void:
	var impact := ImpactData.new()
	impact.swing_id = current_swing_id
	impact.attacker = owner_character
	impact.target = target_owner
	
	if owner_character and "player_id" in owner_character:
		impact.attacker_id = owner_character.player_id
	if target_owner and "player_id" in target_owner:
		impact.target_id = target_owner.player_id
		
	impact.damage = _evaluate_projectile_damage()
	impact.attack_name = attack_data.attack_name if attack_data else "Silver Knife"
	impact.attack_data = attack_data
	impact.hit_position = global_position
	
	var facing: float = sign(velocity.x) if abs(velocity.x) > 0.01 else 1.0
	impact.attacker_facing = facing
	
	var current_percent: float = 0.0
	if target_owner and "damage_percentage" in target_owner:
		current_percent = target_owner.damage_percentage
	impact.target_percent_after = DamageCalculator.apply_damage(current_percent, impact.damage)
	
	var target_weight: float = 100.0
	if target_owner and "weight" in target_owner:
		target_weight = target_owner.weight
		
	var kb_base: float = attack_data.base_knockback if attack_data else 16.0
	var kb_scaling: float = attack_data.knockback_scaling if attack_data else 80.0
	var angle_deg: float = attack_data.angle_degrees if attack_data else 45.0
	var flipper: int = attack_data.angle_flipper if attack_data else 0
	var hitlag_mod: float = attack_data.hitlag_modifier if attack_data else 1.0
	var atk_type: String = attack_data.attack_type if attack_data else "normal"
	
	var target_in_air: bool = true
	if target_owner and target_owner.has_method("is_on_floor"):
		target_in_air = not target_owner.is_on_floor()
		
	var final_angle: float = angle_deg
	if facing < 0.0:
		final_angle = -angle_deg + 180.0
		
	var result: Dictionary = KnockbackCalculator.calculate_full_knockback(
		impact.target_percent_after,
		impact.damage,
		target_weight,
		kb_base,
		kb_scaling,
		final_angle,
		flipper,
		hitlag_mod,
		facing,
		global_position,
		target_owner.global_position if target_owner else global_position,
		global_position,
		target_in_air
	)
	
	impact.knockback_magnitude = result.kb
	impact.knockback_vector = Vector2(result.vx, result.vy)
	impact.hdecay = result.hdecay
	impact.vdecay = result.vdecay
	impact.angle_flipper = flipper
	impact.attack_type = atk_type
	impact.hitlag_modifier = hitlag_mod
	impact.hitstun_frames = result.hitstun
	impact.hitlag_frames = result.hitlag
	
	hit_confirmed.emit(impact)
	hurtbox.receive_impact(impact)
