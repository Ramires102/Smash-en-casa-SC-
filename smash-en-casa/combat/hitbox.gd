class_name Hitbox
extends Area2D

signal hit_confirmed(impact: ImpactData)
signal hitbox_clanked(other_hitbox: Hitbox)

@export var attack_data: AttackData
@export var debug_draw_hitbox: bool = false

var owner_character: Node2D = null
var hit_hurtboxes: Array[Hurtbox] = []

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

func _physics_process(_delta: float) -> void:
	if monitoring and attack_data != null:
		_update_hitbox_transform()
		_check_immediate_overlaps()

func _setup_debug_visualizer() -> void:
	if owner_character and owner_character.has_node("Humanoid"):
		var humanoid: Node = owner_character.get_node("Humanoid")
		_debug_mesh_instance = humanoid.get_node_or_null("DebugHitboxMesh") as MeshInstance3D
		if _debug_mesh_instance:
			_debug_mesh_instance.visible = false

		_sub_debug_meshes.clear()
		var idx: int = 0
		while humanoid.has_node("DebugSweetspotMesh_%d" % idx):
			var sm: MeshInstance3D = humanoid.get_node("DebugSweetspotMesh_%d" % idx) as MeshInstance3D
			if sm:
				sm.visible = false
				_sub_debug_meshes.append(sm)
			idx += 1

func reset_hit_registry() -> void:
	hit_hurtboxes.clear()
	_next_swing_id += 1
	current_swing_id = _next_swing_id
	call_deferred("_check_immediate_overlaps")

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
	var sub_count: int = attack_data.sub_hitboxes.size() if attack_data else 0
	for i in range(_sub_debug_meshes.size()):
		_sub_debug_meshes[i].visible = debug_draw_hitbox and (i < sub_count)
	call_deferred("_check_immediate_overlaps")

func _get_hitbox_color(atk: AttackData) -> Color:
	if atk == null:
		return Color(1.0, 0.22, 0.28, 0.35)
	if atk.is_time_stop:
		return Color(0.1, 0.85, 1.0, 0.40)
	if atk.angle_degrees > 250.0 and atk.angle_degrees < 290.0:
		return Color(1.0, 0.45, 0.05, 0.42)
	if atk.damage >= 14.0:
		return Color(1.0, 0.15, 0.25, 0.40)
	if atk.damage >= 8.0:
		return Color(1.0, 0.32, 0.22, 0.35)
	return Color(1.0, 0.45, 0.32, 0.30)

func _update_hitbox_transform() -> void:
	if attack_data == null:
		return
	var facing: float = 1.0
	if owner_character and owner_character.has_method("get_facing_direction"):
		facing = owner_character.get_facing_direction()

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

	if _debug_mesh_instance and debug_draw_hitbox:
		var z_off: float = attack_data.hitbox_offset.z if (attack_data.hitbox_offset is Vector3) else 0.0
		_debug_mesh_instance.position = Vector3(
			attack_data.hitbox_offset.x * facing,
			attack_data.hitbox_offset.y,
			z_off
		)
		var sphere: SphereMesh = _debug_mesh_instance.mesh as SphereMesh
		if sphere:
			sphere.radius = attack_data.hitbox_radius
			sphere.height = attack_data.hitbox_radius * 2.0
		var target_color: Color = _get_hitbox_color(attack_data)
		var mat: StandardMaterial3D = _debug_mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = target_color

	_update_sub_hitbox_visuals(facing)

func _update_sub_hitbox_visuals(facing: float) -> void:
	if not debug_draw_hitbox:
		return
	var sub_count: int = attack_data.sub_hitboxes.size() if attack_data else 0
	for i in range(_sub_debug_meshes.size()):
		if i < sub_count:
			var hb: HitboxData = attack_data.sub_hitboxes[i]
			var mesh_inst: MeshInstance3D = _sub_debug_meshes[i]
			mesh_inst.position = Vector3(hb.offset.x * facing, hb.offset.y, hb.offset.z)
			var sph: SphereMesh = mesh_inst.mesh as SphereMesh
			if sph:
				sph.radius = hb.radius
				sph.height = hb.radius * 2.0
			var sub_color: Color = Color(1.0, 0.82, 0.12, 0.45)
			if hb.priority <= 0 or hb.damage < (attack_data.damage if attack_data else 10.0):
				sub_color = Color(0.85, 0.28, 0.95, 0.32)
			var sub_mat: StandardMaterial3D = mesh_inst.material_override as StandardMaterial3D
			if sub_mat:
				sub_mat.albedo_color = sub_color
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
	if target_owner and "state_machine" in target_owner and target_owner.state_machine and target_owner.state_machine.current_state:
		if target_owner.state_machine.current_state.name.to_lower() == "shield":
			attacker_mult *= 0.80
	return maxi(2, int(round(float(impact.hitlag_frames) * attacker_mult)))

func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return

	# Detección de Clank (solo ataques terrestres clankean entre sí, como en Smash)
	if area is Hitbox and area != self and area.monitoring:
		var other_owner: Node2D = area.owner_character
		if other_owner != owner_character:
			var self_grounded: bool = owner_character.is_on_floor() if (owner_character and owner_character.has_method("is_on_floor")) else true
			var other_grounded: bool = other_owner.is_on_floor() if (other_owner and other_owner.has_method("is_on_floor")) else true
			if self_grounded and other_grounded:
				_check_clank(area)
		return

	# Detección de Impacto en Hurtbox
	if area is Hurtbox and area not in hit_hurtboxes:
		var target_owner: Node2D = area.owner_character
		if target_owner == null:
			target_owner = area.get_parent()
		if target_owner != owner_character:
			hit_hurtboxes.append(area)

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
	if absf(my_dmg - other_dmg) < 9.0:
		hitbox_clanked.emit(other_hitbox)
		other_hitbox.hitbox_clanked.emit(self)
		deactivate()
		other_hitbox.deactivate()

func _build_impact(hurtbox: Hurtbox, target_owner: Node2D) -> ImpactData:
	var impact := ImpactData.new()

	impact.swing_id = current_swing_id
	impact.attacker = owner_character
	impact.target = target_owner
	if owner_character and "player_id" in owner_character:
		impact.attacker_id = owner_character.player_id
	if target_owner and "player_id" in target_owner:
		impact.target_id = target_owner.player_id

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
		facing = signf(target_owner.global_position.x - owner_character.global_position.x)
		if is_zero_approx(facing):
			facing = 1.0
	impact.attacker_facing = facing

	var current_percent: float = 0.0
	if target_owner and "damage_percentage" in target_owner:
		current_percent = target_owner.damage_percentage
	impact.target_percent_after = DamageCalculator.apply_damage(current_percent, impact.damage)

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

	# Pasamos angle_deg puro: KnockbackCalculator se encarga de reflejar según facing
	var result: Dictionary = KnockbackCalculator.calculate_full_knockback(
		impact.target_percent_after,
		impact.damage,
		target_weight,
		kb_base,
		kb_scaling,
		angle_deg,
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

	var best_in_range: HitboxData = null
	var best_priority: int = -999999
	var min_dist: float = INF

	var closest_fallback: HitboxData = null
	var closest_fallback_dist: float = INF

	var facing: float = owner_character.get_facing_direction() if (owner_character and owner_character.has_method("get_facing_direction")) else 1.0
	var origin_2d: Vector2 = Vector2(global_position.x, global_position.y)
	var hurtbox_padding_px: float = 16.0 # Margen del radio de la hurtbox del defensor

	for hb in attack_data.sub_hitboxes:
		if hb == null:
			continue
		var world_pos: Vector2 = origin_2d + Vector2(hb.offset.x * Constants.UNIT_SIZE * facing, -hb.offset.y * Constants.UNIT_SIZE)
		var dist: float = world_pos.distance_to(target_pos)
		var max_reach_px: float = hb.radius * Constants.UNIT_SIZE + hurtbox_padding_px

		# Guardar fallback más cercano por si el borde de la hitbox principal tocó primero
		if dist < closest_fallback_dist:
			closest_fallback_dist = dist
			closest_fallback = hb

		# Solo evaluar prioridad si la hurtbox realmente está dentro del radio de esta sub-hitbox
		if dist <= max_reach_px:
			if hb.priority > best_priority or (hb.priority == best_priority and dist < min_dist):
				best_priority = hb.priority
				min_dist = dist
				best_in_range = hb

	return best_in_range if best_in_range != null else closest_fallback
