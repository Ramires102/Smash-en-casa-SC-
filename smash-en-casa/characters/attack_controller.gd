class_name AttackController
extends Node

signal attack_executed(attack_data: AttackData)
signal attack_ended

@export var hitbox: Hitbox
var current_moveset: MoveSet
var is_attacking: bool = false

func setup(data: CharacterData) -> void:
	if data:
		current_moveset = data.moveset

func get_attack_data_for_input(player_input: PlayerInput, is_on_floor: bool, facing_direction: float = 1.0) -> AttackData:
	if not current_moveset or not player_input:
		return null

	if player_input.special_pressed:
		if player_input.movement.y > 0.3 and current_moveset.special_up != null:
			return current_moveset.special_up
		elif player_input.movement.y < -0.3 and current_moveset.special_down != null:
			return current_moveset.special_down
		elif abs(player_input.movement.x) > 0.2 and current_moveset.special_side != null:
			return current_moveset.special_side
		return current_moveset.special_neutral

	if not is_on_floor:
		if player_input.movement.y > 0.3 and current_moveset.up_air != null:
			return current_moveset.up_air
		elif player_input.movement.y < -0.3 and current_moveset.down_air != null:
			return current_moveset.down_air
		elif abs(player_input.movement.x) > 0.2:
			var move_dir: float = sign(player_input.movement.x)
			if move_dir == facing_direction and current_moveset.forward_air != null:
				return current_moveset.forward_air
			elif move_dir != facing_direction and current_moveset.back_air != null:
				return current_moveset.back_air
		return current_moveset.neutral_air

	if player_input.is_dash:
		if abs(player_input.movement.x) > 0.3 and current_moveset.forward_smash != null:
			return current_moveset.forward_smash
		elif player_input.movement.y > 0.3 and current_moveset.up_smash != null:
			return current_moveset.up_smash
		elif player_input.movement.y < -0.3 and current_moveset.down_smash != null:
			return current_moveset.down_smash

	if player_input.movement.y > 0.3:
		return current_moveset.up_tilt if current_moveset.up_tilt != null else current_moveset.neutral_attack
	elif player_input.movement.y < -0.3:
		return current_moveset.down_tilt if current_moveset.down_tilt != null else current_moveset.neutral_attack
	elif abs(player_input.movement.x) > 0.2:
		return current_moveset.side_tilt if current_moveset.side_tilt != null else current_moveset.neutral_attack

	return current_moveset.neutral_attack

func start_attack(attack_data: AttackData, _attacker: Node2D) -> void:
	if not attack_data:
		return
	is_attacking = true
	attack_executed.emit(attack_data)

func enable_hitbox(attack_data: AttackData, attacker: Node2D) -> void:
	if hitbox and attack_data:
		hitbox.activate(attack_data, attacker)

func disable_hitbox() -> void:
	if hitbox:
		hitbox.deactivate()
	is_attacking = false
	attack_ended.emit()

func try_handle_parry_counter(character: Character, impact: ImpactData) -> bool:
	if character == null or impact == null or character.state_machine == null:
		return false
	var st: Node = character.state_machine.current_state
	if st == null or st.name.to_lower() != "attack":
		return false
	if not ("current_attack_data" in st) or st.current_attack_data == null or not st.current_attack_data.is_parry_stance:
		return false
	if not ("frame_cursor" in st) or not ("active_end_frame" in st) or st.frame_cursor > st.active_end_frame:
		return false

	var attacker_node: Node2D = impact.attacker as Node2D if is_instance_valid(impact.attacker) else null
	var counter_atk: AttackData = st.current_attack_data.auto_followup_on_hit
	if attacker_node != null:
		var enemy_facing: float = attacker_node.get_facing_direction() if attacker_node.has_method("get_facing_direction") else 1.0
		if attacker_node.has_method("deactivate_hitbox"):
			attacker_node.deactivate_hitbox()
		if "_self_hitlag_remaining" in attacker_node:
			attacker_node._self_hitlag_remaining = 0
		character.global_position.x = attacker_node.global_position.x - enemy_facing * 0.92 * Constants.UNIT_SIZE
		character.global_position.y = attacker_node.global_position.y
		character.velocity = Vector2.ZERO
		character.set_facing_direction(enemy_facing)
		attacker_node.velocity = Vector2.ZERO
		if "state_machine" in attacker_node and attacker_node.state_machine:
			attacker_node.state_machine.transition_to("Hit", {
				"knockback": Vector2(enemy_facing * 0.5 * Constants.UNIT_SIZE, 0.5 * Constants.UNIT_SIZE),
				"hitstun_frames": 44,
				"hitlag_frames": 6,
				"knockback_scalar": 1.0,
				"hdecay": 0.0,
				"vdecay": 0.0,
				"sliding_knockdown": false,
				"impact": null
			})
	Events.camera_shake_requested.emit(6.0)
	if counter_atk != null:
		character.state_machine.transition_to("Attack", {"attack_data": counter_atk, "hit_defender": attacker_node})
	return true

func apply_enter_mechanics(character: Character, atk: AttackData, hit_defender: Node2D) -> bool:
	var started_in_air: bool = not character.is_on_floor()
	var anim_name: String = atk.animation_name if atk.animation_name != "" else "Attack"

	if anim_name == "SpecialUp":
		character.can_up_special = false
	elif atk.is_time_stop:
		character.consume_special_down_charge()

	if atk.flip_facing_on_start:
		var new_dir: float = -character.get_facing_direction()
		character.set_facing_direction(new_dir, true)
		if is_instance_valid(hit_defender):
			hit_defender.global_position.x = character.global_position.x + new_dir * 0.96 * Constants.UNIT_SIZE
			hit_defender.global_position.y = minf(hit_defender.global_position.y, character.global_position.y - 0.44 * Constants.UNIT_SIZE)
			hit_defender.velocity = Vector2(0.0, -1.8 * Constants.UNIT_SIZE)
			if hit_defender.has_method("set_facing_direction"):
				hit_defender.set_facing_direction(-new_dir)
	else:
		var enter_input: Vector2 = character.get_input_vector()
		if absf(enter_input.x) > 0.25 and (not atk.is_aerial or anim_name.begins_with("Special")):
			character.update_facing_direction(enter_input.x)

	if atk.pose_style == "up_special_followup_punch":
		var target_opp: Node2D = hit_defender if is_instance_valid(hit_defender) else find_opponent(character)
		if is_instance_valid(target_opp):
			var facing: float = character.get_facing_direction()
			target_opp.global_position = Vector2(
				character.global_position.x + facing * 0.88 * Constants.UNIT_SIZE,
				character.global_position.y - 0.06 * Constants.UNIT_SIZE
			)
			target_opp.velocity = Vector2(0.0, -2.2 * Constants.UNIT_SIZE)
		character.velocity = Vector2(character.get_facing_direction() * 1.8 * Constants.UNIT_SIZE, -2.6 * Constants.UNIT_SIZE)

	if atk.snap_in_front_of_opponent:
		var opp: Node2D = find_opponent(character)
		if is_instance_valid(opp):
			var dx: float = opp.global_position.x - character.global_position.x
			var dir_to_opp: float = (1.0 if dx >= 0.0 else -1.0) if absf(dx) > 2.0 else character.get_facing_direction()
			character.set_facing_direction(dir_to_opp)
			character.global_position.x = opp.global_position.x - dir_to_opp * 1.12 * Constants.UNIT_SIZE
			character.global_position.y = minf(character.global_position.y, opp.global_position.y - 0.42 * Constants.UNIT_SIZE)
			character.velocity = Vector2(0.0, -1.5 * Constants.UNIT_SIZE)
			started_in_air = true

	if atk.is_divekick:
		character.is_fast_falling = false
		if character.is_on_floor():
			character.global_position.y -= 2.0
			character.velocity.y = -8.5 * Constants.UNIT_SIZE
			character.velocity.x = character.get_facing_direction() * 1.5 * Constants.UNIT_SIZE
			started_in_air = true
		else:
			character.velocity.x *= 0.25
			character.velocity.y = minf(0.0, character.velocity.y * 0.15)

	return started_in_air

func apply_hit_confirm_mechanics(character: Character, atk: AttackData, hit_defender: Node2D, frame_cursor: int, active_end_frame: int) -> Dictionary:
	var result := {"is_vaulting_behind": false, "clear_defender": false}
	if character == null or atk == null or not is_instance_valid(hit_defender):
		return result
	var facing: float = character.get_facing_direction()

	if atk.vault_behind_on_hit:
		result["is_vaulting_behind"] = true
		character.global_position.y -= 2.0
		character.velocity.x = facing * 9.2 * Constants.UNIT_SIZE
		character.velocity.y = -7.8 * Constants.UNIT_SIZE
		override_defender_pending_kb(hit_defender, Vector2(facing * 1.5 * Constants.UNIT_SIZE, -6.4 * Constants.UNIT_SIZE))

	if atk.drag_defender_on_hit:
		character._self_hitlag_remaining = mini(character._self_hitlag_remaining, 2)
		set_defender_hitlag_and_hitstun(hit_defender, 2, maxi(26, (active_end_frame - frame_cursor) + 18))
		override_defender_pending_kb(hit_defender, Vector2(character.velocity.x, minf(character.velocity.y, -8.5 * Constants.UNIT_SIZE)))

	if atk.toss_behind_on_hit:
		hit_defender.global_position.x = character.global_position.x + facing * 0.78 * Constants.UNIT_SIZE
		hit_defender.global_position.y = minf(hit_defender.global_position.y, character.global_position.y - 0.24 * Constants.UNIT_SIZE)
		character._self_hitlag_remaining = 9
		set_defender_hitlag_and_hitstun(hit_defender, 9, 46)
		override_defender_pending_kb(hit_defender, Vector2(-facing * 2.2 * Constants.UNIT_SIZE, -6.8 * Constants.UNIT_SIZE))

	if atk.sliding_knockdown:
		character._self_hitlag_remaining = 8
		set_defender_hitlag_and_hitstun(hit_defender, 8, 38)
		override_defender_pending_kb(hit_defender, Vector2(facing * 13.2 * Constants.UNIT_SIZE, -0.3 * Constants.UNIT_SIZE))
		_set_defender_sliding_knockdown(hit_defender, true)

	if atk.telekinesis_grab_on_hit:
		character.dragged_defender = hit_defender
		hit_defender.global_position.x = character.global_position.x + facing * 1.65 * Constants.UNIT_SIZE
		hit_defender.global_position.y = character.global_position.y - 0.58 * Constants.UNIT_SIZE
		hit_defender.velocity = Vector2.ZERO
		character._self_hitlag_remaining = 4
		set_defender_hitlag_and_hitstun(hit_defender, 4, 195)
		override_defender_pending_kb(hit_defender, Vector2(0.0, -0.5 * Constants.UNIT_SIZE))
		character.telekinesis_throw_dir = Vector2(facing, 0.0)

	if atk.is_telekinesis_throw:
		var dir: Vector2 = character.telekinesis_throw_dir
		dir = Vector2(facing, 0.0) if dir.length_squared() < 0.01 else dir.normalized()
		var def_pct: float = hit_defender.damage_percentage if "damage_percentage" in hit_defender else 0.0
		var launch_speed: float = (15.8 + def_pct * 0.14) * Constants.UNIT_SIZE
		var launch_vel := Vector2(dir.x * launch_speed, -dir.y * launch_speed)
		character._self_hitlag_remaining = 7
		set_defender_hitlag_and_hitstun(hit_defender, 7, 42)
		override_defender_pending_kb(hit_defender, launch_vel)
		hit_defender.velocity = launch_vel
		_set_defender_sliding_knockdown(hit_defender, dir.y < -0.55)
		result["clear_defender"] = true

	if atk.is_parry_counter_impale:
		character.dragged_defender = hit_defender
		hit_defender.global_position.x = character.global_position.x + facing * 0.92 * Constants.UNIT_SIZE
		hit_defender.global_position.y = character.global_position.y - 0.28 * Constants.UNIT_SIZE
		var def_pct2: float = hit_defender.damage_percentage if "damage_percentage" in hit_defender else 0.0
		var kb_mag: float = (16.4 + def_pct2 * 0.16) * Constants.UNIT_SIZE
		var rad: float = deg_to_rad(36.0)
		character._self_hitlag_remaining = 4
		set_defender_hitlag_and_hitstun(hit_defender, 14, 48)
		override_defender_pending_kb(hit_defender, Vector2(cos(rad) * kb_mag * facing, -sin(rad) * kb_mag))

	return result

func process_capture_mechanics(character: Character, atk: AttackData, hit_defender: Node2D, frame_cursor: int, startup_end_frame: int, active_end_frame: int) -> void:
	if character == null or atk == null or not is_instance_valid(hit_defender):
		return
	var facing: float = character.get_facing_direction()

	if atk.drag_defender_on_hit and frame_cursor <= active_end_frame:
		var target_pos := Vector2(character.global_position.x + facing * 0.78 * Constants.UNIT_SIZE, character.global_position.y - 0.10 * Constants.UNIT_SIZE)
		hit_defender.global_position = hit_defender.global_position.lerp(target_pos, 0.5)
		hit_defender.velocity = character.velocity
		override_defender_pending_kb(hit_defender, character.velocity)

	if atk.toss_behind_on_hit and frame_cursor <= active_end_frame:
		var active_len: int = maxi(1, active_end_frame - startup_end_frame)
		var active_progress: float = clampf(float(frame_cursor - startup_end_frame) / float(active_len), 0.0, 1.0)
		var arc_t: float = smoothstep(0.32, 1.0, active_progress)
		var local_offset_x: float = lerpf(0.78, -0.98, arc_t) * facing * Constants.UNIT_SIZE
		var arc_height: float = (0.26 + sin(arc_t * PI) * 0.62 + arc_t * 0.20) * Constants.UNIT_SIZE
		var target_vec := Vector2(character.global_position.x + local_offset_x, character.global_position.y - arc_height)
		hit_defender.global_position = hit_defender.global_position.lerp(target_vec, 0.55)
		hit_defender.velocity = Vector2(-facing * 1.2 * Constants.UNIT_SIZE, -2.0 * Constants.UNIT_SIZE)
		override_defender_pending_kb(hit_defender, hit_defender.velocity)

	if atk.flip_facing_on_start and frame_cursor <= startup_end_frame:
		var target_vec := Vector2(character.global_position.x + facing * 0.96 * Constants.UNIT_SIZE, character.global_position.y - 0.44 * Constants.UNIT_SIZE)
		hit_defender.global_position = hit_defender.global_position.lerp(target_vec, 0.45)
		hit_defender.velocity = Vector2(0.0, -1.4 * Constants.UNIT_SIZE)
		override_defender_pending_kb(hit_defender, hit_defender.velocity)

	if (atk.telekinesis_grab_on_hit and frame_cursor <= active_end_frame) or atk.is_telekinesis_hold or (atk.is_telekinesis_throw and frame_cursor <= startup_end_frame):
		var hover_bob: float = sin(float(frame_cursor) * 0.22) * 0.06 * Constants.UNIT_SIZE
		var hold_target := Vector2(character.global_position.x + facing * 1.65 * Constants.UNIT_SIZE, character.global_position.y - 0.58 * Constants.UNIT_SIZE - hover_bob)
		hit_defender.global_position = hit_defender.global_position.lerp(hold_target, 0.52)
		hit_defender.velocity = Vector2.ZERO
		set_defender_hitlag_and_hitstun(hit_defender, 0, 30)
		override_defender_pending_kb(hit_defender, Vector2(0.0, -0.5 * Constants.UNIT_SIZE))

	if atk.is_parry_counter_impale and frame_cursor <= startup_end_frame + 13:
		var impale_lift: float = clampf(float(frame_cursor - startup_end_frame) / 6.0, 0.0, 1.0)
		var impale_target := Vector2(character.global_position.x + facing * 0.92 * Constants.UNIT_SIZE, character.global_position.y - (0.34 * impale_lift) * Constants.UNIT_SIZE)
		hit_defender.global_position = hit_defender.global_position.lerp(impale_target, 0.65)
		hit_defender.velocity = Vector2(facing * 2.5 * Constants.UNIT_SIZE, -3.5 * Constants.UNIT_SIZE)
		set_defender_hitlag_and_hitstun(hit_defender, 2, 38)
		override_defender_pending_kb(hit_defender, Vector2(facing * 13.5 * Constants.UNIT_SIZE, -9.8 * Constants.UNIT_SIZE))

func spawn_projectiles(character: Character, atk: AttackData) -> void:
	if not character or not atk:
		return
	var proj_scene: PackedScene = atk.projectile_scene if atk.projectile_scene != null else preload("res://combat/projectile.tscn")
	var facing: float = character.get_facing_direction()
	var spawn_pos: Vector2 = character.global_position + Vector2(atk.projectile_offset.x * Constants.UNIT_SIZE * facing, -atk.projectile_offset.y * Constants.UNIT_SIZE)
	var spread: Array[float] = atk.projectile_spread_angles if not atk.projectile_spread_angles.is_empty() else [0.0]
	var parent_tree: Node = character.get_parent() if character.get_parent() else character
	var aerial_offset: float = atk.aerial_projectile_angle_offset if not character.is_on_floor() else 0.0
	for angle_offset_deg in spread:
		var proj_inst: Node = proj_scene.instantiate()
		parent_tree.add_child(proj_inst)
		if proj_inst is Projectile:
			proj_inst.global_position = spawn_pos
			var base_angle_rad: float = 0.0 if facing > 0.0 else PI
			var angle_rad: float = base_angle_rad + deg_to_rad((angle_offset_deg + aerial_offset) * facing)
			proj_inst.setup(atk, character, Vector2(cos(angle_rad), sin(angle_rad)), atk.projectile_speed, atk.projectile_lifetime)

static func set_defender_hitlag_and_hitstun(defender: Node2D, hitlag_f: int, hitstun_f: int) -> void:
	if is_instance_valid(defender) and "state_machine" in defender and defender.state_machine and defender.state_machine.current_state:
		var st: Node = defender.state_machine.current_state
		if "_hitlag_remaining" in st:
			st._hitlag_remaining = hitlag_f
		if "_hitstun_remaining" in st:
			st._hitstun_remaining = maxi(st._hitstun_remaining, hitstun_f)

static func override_defender_pending_kb(defender: Node2D, new_kb: Vector2) -> void:
	if is_instance_valid(defender) and "state_machine" in defender and defender.state_machine and defender.state_machine.current_state:
		var st: Node = defender.state_machine.current_state
		if "_pending_knockback" in st:
			st._pending_knockback = new_kb

static func _set_defender_sliding_knockdown(defender: Node2D, enabled: bool) -> void:
	if is_instance_valid(defender) and "state_machine" in defender and defender.state_machine and defender.state_machine.current_state:
		var st: Node = defender.state_machine.current_state
		if "_is_sliding_knockdown" in st:
			st._is_sliding_knockdown = enabled

static func find_opponent(character: Node) -> Node2D:
	if character == null or character.get_parent() == null:
		return null
	for child in character.get_parent().get_children():
		if child != character and child is CharacterBody2D:
			return child as Node2D
	return null
