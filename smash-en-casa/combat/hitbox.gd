class_name Hitbox
extends Area2D

signal hit_confirmed(impact: ImpactData)
signal hitbox_clanked(other_hitbox: Hitbox)

@export var attack_data: AttackData
@export var debug_draw_hitbox: bool = true

var owner_character: Node2D = null
var hit_hurtboxes: Array[Hurtbox] = []

## Contador monotónico global para IDs de swing únicos.
static var _next_swing_id: int = 0
var current_swing_id: int = -1

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
var _debug_mesh_instance: MeshInstance3D = null
var _sub_debug_meshes: Array[MeshInstance3D] = []

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
		_debug_mesh_instance.material_override = _create_debug_material(Color(1.0, 0.22, 0.28, 0.35))
		_attach_debug_node(_debug_mesh_instance)
		_debug_mesh_instance.visible = false

func _attach_debug_node(node: Node3D) -> void:
	if owner_character and owner_character.has_node("Humanoid"):
		owner_character.get_node("Humanoid").add_child(node)
	else:
		add_child(node)

func _create_debug_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.render_priority = 10
	return mat

func activate(data: AttackData, attacker: Node2D) -> void:
	attack_data = data
	owner_character = attacker if attacker != null else get_parent()
	hit_hurtboxes.clear()
	_next_swing_id += 1
	current_swing_id = _next_swing_id
	
	_update_hitbox_transform()
	
	monitoring = true
	if _debug_mesh_instance and debug_draw_hitbox:
		_debug_mesh_instance.visible = true
	for sub_m in _sub_debug_meshes:
		sub_m.visible = true
		
	call_deferred("_check_immediate_overlaps")

func _get_hitbox_color(atk: AttackData) -> Color:
	if atk == null:
		return Color(1.0, 0.22, 0.28, 0.35)
	if atk.is_time_stop:
		return Color(0.1, 0.85, 1.0, 0.40) # Cyan Eléctrico
	if atk.angle_degrees > 250.0 and atk.angle_degrees < 290.0:
		return Color(1.0, 0.45, 0.05, 0.42) # Naranja Spike
	if atk.damage >= 14.0:
		return Color(1.0, 0.15, 0.25, 0.40) # Rojo Carmesí Fuerte
	if atk.damage >= 8.0:
		return Color(1.0, 0.32, 0.22, 0.35) # Coral Medio
	return Color(1.0, 0.45, 0.32, 0.30) # Coral Suave

func _update_hitbox_transform() -> void:
	if attack_data == null:
		return
		
	var facing: float = 1.0
	if owner_character and owner_character.has_method("get_facing_direction"):
		facing = owner_character.get_facing_direction()
	
	# Convertir offset a píxeles 2D (UNIT_SIZE = 28 px/m)
	var offset_x: float = attack_data.hitbox_offset.x * Constants.UNIT_SIZE * facing
	var offset_y: float = -attack_data.hitbox_offset.y * Constants.UNIT_SIZE
	var pos: Vector2 = Vector2(offset_x, offset_y)
	var radius_px: float = attack_data.hitbox_radius * Constants.UNIT_SIZE
	
	if collision_shape:
		collision_shape.position = pos
		if collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = radius_px
		elif collision_shape.shape is RectangleShape2D:
			(collision_shape.shape as RectangleShape2D).size = Vector2(radius_px * 2.0, radius_px * 2.0)

	# Actualizar esfera 3D principal
	if _debug_mesh_instance and debug_draw_hitbox:
		_debug_mesh_instance.position = Vector3(
			attack_data.hitbox_offset.x * facing,
			attack_data.hitbox_offset.y,
			0.0
		)
		var sphere := SphereMesh.new()
		sphere.radius = attack_data.hitbox_radius
		sphere.height = attack_data.hitbox_radius * 2.0
		_debug_mesh_instance.mesh = sphere
		_debug_mesh_instance.material_override = _create_debug_material(_get_hitbox_color(attack_data))

	# Actualizar esferas 3D de sub-hitboxes (Sweetspots / Sourspots)
	_update_sub_hitbox_visuals(facing)

func _update_sub_hitbox_visuals(facing: float) -> void:
	if not debug_draw_hitbox:
		return
		
	var sub_count: int = attack_data.sub_hitboxes.size() if attack_data else 0
	
	# Asegurar que tenemos suficientes nodos de malla para cada sub-hitbox
	while _sub_debug_meshes.size() < sub_count:
		var new_mesh := MeshInstance3D.new()
		new_mesh.name = "DebugSweetspotMesh_%d" % _sub_debug_meshes.size()
		_attach_debug_node(new_mesh)
		_sub_debug_meshes.append(new_mesh)
		
	for i in range(_sub_debug_meshes.size()):
		if i < sub_count:
			var hb: HitboxData = attack_data.sub_hitboxes[i]
			var mesh_inst: MeshInstance3D = _sub_debug_meshes[i]
			mesh_inst.position = Vector3(hb.offset.x * facing, hb.offset.y, hb.offset.z)
			
			var sph := SphereMesh.new()
			sph.radius = hb.radius
			sph.height = hb.radius * 2.0
			mesh_inst.mesh = sph
			
			# Color según prioridad y daño (Dorado para Sweetspot / Púrpura para Sourspot)
			var sub_color: Color = Color(1.0, 0.82, 0.12, 0.45) # Dorado Sweetspot
			if hb.priority <= 0 or hb.damage < (attack_data.damage if attack_data else 10.0):
				sub_color = Color(0.85, 0.28, 0.95, 0.32) # Violeta Sourspot
			mesh_inst.material_override = _create_debug_material(sub_color)
			mesh_inst.visible = monitoring
		else:
			_sub_debug_meshes[i].visible = false

func _check_immediate_overlaps() -> void:
	if monitoring:
		for area in get_overlapping_areas():
			_on_area_entered(area)

func deactivate() -> void:
	monitoring = false
	hit_hurtboxes.clear()
	if _debug_mesh_instance:
		_debug_mesh_instance.visible = false
	for sub_m in _sub_debug_meshes:
		sub_m.visible = false

func _compute_attacker_hitlag_frames(impact: ImpactData, target_owner: Node2D) -> int:
	if impact == null:
		return 1

	var strength_ratio: float = clampf(impact.knockback_magnitude / Constants.ATTACKER_HITLAG_KB_REFERENCE, 0.0, 1.0)
	var attacker_mult: float = lerpf(Constants.ATTACKER_HITLAG_MIN_MULT, Constants.ATTACKER_HITLAG_MAX_MULT, strength_ratio)

	# Bloqueos deben sentirse más "secos" para el atacante que un hit limpio.
	if target_owner and "state_machine" in target_owner and target_owner.state_machine and target_owner.state_machine.current_state:
		if target_owner.state_machine.current_state.name.to_lower() == "shield":
			attacker_mult *= 0.82

	return maxi(1, int(ceil(float(impact.hitlag_frames) * attacker_mult)))

func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return
		
	# ── Detección de Clank (Choque de Hitboxes de dos luchadores) ──
	if area is Hitbox and area != self and area.monitoring:
		var other_owner: Node2D = area.owner_character
		if other_owner != owner_character:
			_check_clank(area)
		return
		
	# ── Detección de Impacto en Hurtbox ──
	if area is Hurtbox and area not in hit_hurtboxes:
		var target_owner: Node2D = area.owner_character
		if target_owner == null:
			target_owner = area.get_parent()
		
		if target_owner != owner_character:
			hit_hurtboxes.append(area)
			
			# Manejar ataques tipo "Flip" (voltear al rival)
			if attack_data and attack_data.attack_type == "Flip":
				_apply_flip_effect(target_owner)
				return
			
			var impact := _build_impact(area, target_owner)
			if owner_character and owner_character.has_method("apply_self_hitlag"):
				var attacker_hitlag: int = _compute_attacker_hitlag_frames(impact, target_owner)
				owner_character.apply_self_hitlag(attacker_hitlag)
			hit_confirmed.emit(impact)
			area.receive_impact(impact)

func _apply_flip_effect(target_owner: Node2D) -> void:
	if target_owner == null:
		return
	if target_owner.has_method("get_facing_direction"):
		var target_dir: float = target_owner.get_facing_direction()
		if target_owner.has_method("set_facing_direction"):
			target_owner.set_facing_direction(-target_dir)
	target_owner.velocity.x = target_owner.velocity.x * -1.0
	if target_owner and "stats" in target_owner and target_owner.stats:
		target_owner.stats.add_damage(attack_data.damage if attack_data else 0.0)

func _check_clank(other_hitbox: Hitbox) -> void:
	var my_dmg: float = attack_data.damage if attack_data else 0.0
	var other_dmg: float = other_hitbox.attack_data.damage if other_hitbox.attack_data else 0.0
	
	# En Smash, si la diferencia de daño es menor a 9%, ambos ataques rebotan (Clank)
	if absf(my_dmg - other_dmg) < 9.0:
		hitbox_clanked.emit(other_hitbox)
		deactivate()

## Construye el ImpactData canónico evaluando sweetspots si existen.
func _build_impact(hurtbox: Hurtbox, target_owner: Node2D) -> ImpactData:
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
	
	# ── Calcular knockback ──
	var target_weight: float = 100.0
	if target_owner and "weight" in target_owner:
		target_weight = target_owner.weight
	
	var kb_base: float = selected_sweetspot.base_knockback if selected_sweetspot else (attack_data.base_knockback if attack_data else 15.0)
	var kb_scaling: float = selected_sweetspot.knockback_scaling if selected_sweetspot else (attack_data.knockback_scaling if attack_data else 100.0)
	var angle_deg: float = selected_sweetspot.angle_degrees if selected_sweetspot else (attack_data.angle_degrees if attack_data else 45.0)
	var flipper: int = attack_data.angle_flipper if attack_data else 0
	var hitlag_mod: float = attack_data.hitlag_modifier if attack_data else 1.0
	var atk_type: String = attack_data.attack_type if attack_data else "normal"
	
	var target_in_air: bool = true
	if target_owner and target_owner.has_method("is_on_floor"):
		target_in_air = not target_owner.is_on_floor()
	
	var attacker_pos: Vector2 = Vector2(owner_character.global_position.x, owner_character.global_position.y) if owner_character else Vector2.ZERO
	var target_pos_2d: Vector2 = Vector2(target_owner.global_position.x, target_owner.global_position.y) if target_owner else Vector2.ZERO
	var hitbox_world_pos: Vector2 = Vector2(global_position.x, global_position.y)
	if collision_shape:
		hitbox_world_pos = Vector2(collision_shape.global_position.x, collision_shape.global_position.y)
	
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
		attacker_pos,
		target_pos_2d,
		hitbox_world_pos,
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
	
	return impact

func _evaluate_best_sweetspot(target_pos: Vector2) -> HitboxData:
	if attack_data == null or attack_data.sub_hitboxes.is_empty():
		return null
		
	var best_hitbox: HitboxData = null
	var best_priority: int = -999
	var min_dist: float = 99999.0
	var facing: float = owner_character.get_facing_direction() if (owner_character and owner_character.has_method("get_facing_direction")) else 1.0
	
	for hb in attack_data.sub_hitboxes:
		var origin_2d: Vector2 = Vector2(global_position.x, global_position.y)
		var world_pos: Vector2 = origin_2d + Vector2(hb.offset.x * Constants.UNIT_SIZE * facing, -hb.offset.y * Constants.UNIT_SIZE)
		var dist: float = world_pos.distance_to(target_pos)
		
		if hb.priority > best_priority or (hb.priority == best_priority and dist < min_dist):
			best_priority = hb.priority
			min_dist = dist
			best_hitbox = hb
			
	return best_hitbox
