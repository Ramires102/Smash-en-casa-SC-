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

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
var visual_3d: Node3D = null

func _ready() -> void:
	collision_layer = 8 # Hitbox layer
	collision_mask = 4  # Hurtbox layer
	monitoring = true
	area_entered.connect(_on_area_entered)
	if collision_shape == null:
		_build_default_collision()

	_build_default_knife_visual()

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

func _process_projectile_hit(hurtbox: Hurtbox, target_owner: Node2D) -> void:
	var impact := ImpactData.new()
	impact.swing_id = current_swing_id
	impact.attacker = owner_character
	impact.target = target_owner
	
	if owner_character and "player_id" in owner_character:
		impact.attacker_id = owner_character.player_id
	if target_owner and "player_id" in target_owner:
		impact.target_id = target_owner.player_id
		
	impact.damage = attack_data.damage if attack_data else 6.0
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

func _build_default_collision() -> void:
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	collision_shape.shape = circle
	add_child(collision_shape)

func _build_default_knife_visual() -> void:
	if visual_3d != null:
		return
		
	visual_3d = Node3D.new()
	visual_3d.name = "Visual3D"
	
	# Hoja del cuchillo plateada brillante
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.65, 0.08, 0.02)
	blade.mesh = blade_mesh
	var mat_blade := StandardMaterial3D.new()
	mat_blade.albedo_color = Color(0.95, 0.98, 1.0)
	mat_blade.metallic = 0.95
	mat_blade.roughness = 0.1
	mat_blade.emission_enabled = true
	mat_blade.emission = Color(0.7, 0.85, 1.0)
	mat_blade.emission_energy_multiplier = 0.5
	blade.material_override = mat_blade
	blade.position = Vector3(0.2, 0.0, 0.0)
	visual_3d.add_child(blade)
	
	# Mango del cuchillo
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.24, 0.05, 0.03)
	handle.mesh = handle_mesh
	var mat_handle := StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.3, 0.18, 0.1)
	handle.material_override = mat_handle
	handle.position = Vector3(-0.24, 0.0, 0.0)
	visual_3d.add_child(handle)
	
	# Guardia dorada
	var guard := MeshInstance3D.new()
	guard.name = "Guard"
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.04, 0.16, 0.04)
	guard.mesh = guard_mesh
	var mat_guard := StandardMaterial3D.new()
	mat_guard.albedo_color = Color(1.0, 0.82, 0.25)
	mat_guard.metallic = 0.9
	guard.material_override = mat_guard
	guard.position = Vector3(-0.12, 0.0, 0.0)
	visual_3d.add_child(guard)
	
	add_child(visual_3d)
	_sync_visual()
