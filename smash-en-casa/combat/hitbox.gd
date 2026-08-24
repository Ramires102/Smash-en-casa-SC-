class_name Hitbox
extends Area3D

signal hit_confirmed(impact: ImpactData)
signal hitbox_clanked(other_hitbox: Hitbox)

@export var attack_data: AttackData
@export var debug_draw_hitbox: bool = true

var owner_character: Node3D = null
var hit_hurtboxes: Array[Hurtbox] = []

## Contador monotónico global para IDs de swing únicos.
static var _next_swing_id: int = 0
var current_swing_id: int = -1

@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
var _debug_mesh_instance: MeshInstance3D = null

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent()
	area_entered.connect(_on_area_entered)
	monitoring = false
	_setup_debug_visualizer()

func _setup_debug_visualizer() -> void:
	if not debug_draw_hitbox:
		return
	if _debug_mesh_instance == null:
		_debug_mesh_instance = MeshInstance3D.new()
		_debug_mesh_instance.name = "DebugHitboxMesh"
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1.0, 0.15, 0.15, 0.6) # Rojo brillante semi-transparente
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_debug_mesh_instance.material_override = mat
		add_child(_debug_mesh_instance)
		_debug_mesh_instance.visible = false

func activate(data: AttackData, attacker: Node3D) -> void:
	attack_data = data
	owner_character = attacker if attacker != null else get_parent()
	hit_hurtboxes.clear()
	_next_swing_id += 1
	current_swing_id = _next_swing_id
	
	_update_hitbox_transform()
	
	monitoring = true
	if _debug_mesh_instance and debug_draw_hitbox:
		_debug_mesh_instance.visible = true
		
	call_deferred("_check_immediate_overlaps")

func _update_hitbox_transform() -> void:
	if attack_data == null:
		return
		
	var facing: float = 1.0
	if owner_character and owner_character.has_method("get_facing_direction"):
		facing = owner_character.get_facing_direction()
	
	var offset: Vector3 = attack_data.hitbox_offset
	var pos: Vector3 = Vector3(offset.x * facing, offset.y, 0.0)
	
	if collision_shape:
		collision_shape.position = pos
		
		# Ajustar tamaño de la forma si aplica
		if collision_shape.shape is BoxShape3D:
			var s: float = attack_data.hitbox_radius * 2.0
			(collision_shape.shape as BoxShape3D).size = Vector3(s, s, s)
		elif collision_shape.shape is SphereShape3D:
			(collision_shape.shape as SphereShape3D).radius = attack_data.hitbox_radius
			
	if _debug_mesh_instance and debug_draw_hitbox:
		_debug_mesh_instance.position = pos
		var sphere := SphereMesh.new()
		sphere.radius = attack_data.hitbox_radius
		sphere.height = attack_data.hitbox_radius * 2.0
		_debug_mesh_instance.mesh = sphere

func _check_immediate_overlaps() -> void:
	if monitoring:
		for area in get_overlapping_areas():
			_on_area_entered(area)

func deactivate() -> void:
	monitoring = false
	hit_hurtboxes.clear()
	if _debug_mesh_instance:
		_debug_mesh_instance.visible = false

func _on_area_entered(area: Area3D) -> void:
	if not monitoring:
		return
		
	# ── Detección de Clank (Choque de Hitboxes de dos luchadores) ──
	if area is Hitbox and area != self and area.monitoring:
		var other_owner: Node3D = area.owner_character
		if other_owner != owner_character:
			_check_clank(area)
		return
		
	# ── Detección de Impacto en Hurtbox ──
	if area is Hurtbox and area not in hit_hurtboxes:
		var target_owner: Node3D = area.owner_character
		if target_owner == null:
			target_owner = area.get_parent()
		
		if target_owner != owner_character:
			hit_hurtboxes.append(area)
			var impact := _build_impact(area, target_owner)
			hit_confirmed.emit(impact)
			area.receive_impact(impact)

func _check_clank(other_hitbox: Hitbox) -> void:
	var my_dmg: float = attack_data.damage if attack_data else 0.0
	var other_dmg: float = other_hitbox.attack_data.damage if other_hitbox.attack_data else 0.0
	
	# En Smash, si la diferencia de daño es menor a 9%, ambos ataques rebotan (Clank)
	if absf(my_dmg - other_dmg) < 9.0:
		hitbox_clanked.emit(other_hitbox)
		deactivate()

## Construye el ImpactData canónico evaluando sweetspots si existen.
func _build_impact(hurtbox: Hurtbox, target_owner: Node3D) -> ImpactData:
	var impact := ImpactData.new()
	
	# ── Identidad ──
	impact.swing_id = current_swing_id
	impact.attacker = owner_character
	impact.target = target_owner
	
	if owner_character and "player_id" in owner_character:
		impact.attacker_id = owner_character.player_id
	if target_owner and "player_id" in target_owner:
		impact.target_id = target_owner.player_id
	
	# ── Evaluar Sweetspot / Sourspot ──
	var selected_sweetspot: HitboxData = _evaluate_best_sweetspot(hurtbox.global_position)
	
	if selected_sweetspot:
		impact.damage = selected_sweetspot.damage
		impact.attack_name = "%s (%s)" % [attack_data.attack_name, selected_sweetspot.name]
	else:
		impact.damage = attack_data.damage if attack_data else 0.0
		impact.attack_name = attack_data.attack_name if attack_data else "Unknown"
		
	impact.attack_data = attack_data
	impact.hit_position = hurtbox.global_position
	
	var facing: float = 1.0
	if owner_character and owner_character.has_method("get_facing_direction"):
		facing = owner_character.get_facing_direction()
	elif owner_character:
		facing = sign(target_owner.global_position.x - owner_character.global_position.x)
		if facing == 0.0:
			facing = 1.0
	impact.attacker_facing = facing
	
	# ── Calcular daño resultante ──
	var current_percent: float = 0.0
	if target_owner and "damage_percentage" in target_owner:
		current_percent = target_owner.damage_percentage
	impact.target_percent_after = DamageCalculator.apply_damage(current_percent, impact.damage)
	
	# ── Calcular knockback y Trajectory DI ──
	var target_weight: float = 100.0
	if target_owner and "weight" in target_owner:
		target_weight = target_owner.weight
	
	var kb_base: float = selected_sweetspot.base_knockback if selected_sweetspot else (attack_data.base_knockback if attack_data else 15.0)
	var kb_scaling: float = selected_sweetspot.knockback_scaling if selected_sweetspot else (attack_data.knockback_scaling if attack_data else 1.0)
	var angle_deg: float = selected_sweetspot.angle_degrees if selected_sweetspot else (attack_data.angle_degrees if attack_data else 45.0)
	
	var di_vec: Vector2 = Vector2.ZERO
	if target_owner and target_owner.has_method("get_input_vector"):
		di_vec = target_owner.get_input_vector()
	
	impact.knockback_magnitude = KnockbackCalculator.calculate_knockback_magnitude(
		impact.target_percent_after,
		impact.damage,
		target_weight,
		kb_base,
		kb_scaling
	)
	
	impact.knockback_vector = KnockbackCalculator.calculate_knockback_vector(
		impact.target_percent_after,
		impact.damage,
		target_weight,
		kb_base,
		kb_scaling,
		angle_deg,
		facing,
		di_vec
	)
	
	# ── Calcular hitstun y hitlag ──
	impact.hitstun_frames = DamageCalculator.calculate_hitstun_frames(impact.knockback_magnitude)
	impact.hitlag_frames = DamageCalculator.calculate_hitlag_frames(impact.damage)
	
	return impact

func _evaluate_best_sweetspot(target_pos: Vector3) -> HitboxData:
	if attack_data == null or attack_data.sub_hitboxes.is_empty():
		return null
		
	var best_hitbox: HitboxData = null
	var best_priority: int = -999
	var min_dist: float = 99999.0
	var facing: float = owner_character.get_facing_direction() if (owner_character and owner_character.has_method("get_facing_direction")) else 1.0
	
	for hb in attack_data.sub_hitboxes:
		var world_pos: Vector3 = global_position + Vector3(hb.offset.x * facing, hb.offset.y, hb.offset.z)
		var dist: float = world_pos.distance_to(target_pos)
		
		if hb.priority > best_priority or (hb.priority == best_priority and dist < min_dist):
			best_priority = hb.priority
			min_dist = dist
			best_hitbox = hb
			
	return best_hitbox
