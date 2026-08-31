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
		
	# ── Ataques Especiales (Special) ──
	if player_input.special_pressed:
		if player_input.movement.y > 0.3 and current_moveset.special_up != null:
			return current_moveset.special_up
		elif player_input.movement.y < -0.3 and current_moveset.special_down != null:
			return current_moveset.special_down
		elif abs(player_input.movement.x) > 0.2 and current_moveset.special_side != null:
			return current_moveset.special_side
		return current_moveset.special_neutral
		
	# ── Ataques Aéreos (Aerials) ──
	elif not is_on_floor:
		if player_input.movement.y > 0.3 and current_moveset.up_air != null:
			return current_moveset.up_air
		elif player_input.movement.y < -0.3 and current_moveset.down_air != null:
			return current_moveset.down_air
		elif abs(player_input.movement.x) > 0.2:
			# Determinar Forward Air vs Back Air según la orientación del personaje
			var move_dir: float = sign(player_input.movement.x)
			if move_dir == facing_direction:
				if current_moveset.forward_air != null:
					return current_moveset.forward_air
			else:
				if current_moveset.back_air != null:
					return current_moveset.back_air
		return current_moveset.neutral_air
		
	# ── Ataques Terrestres (Ground Tilts & Smashes) ──
	else:
		# Smash attacks si hay dash/smash intent
		if player_input.is_dash:
			if abs(player_input.movement.x) > 0.3 and current_moveset.forward_smash != null:
				return current_moveset.forward_smash
			elif player_input.movement.y > 0.3 and current_moveset.up_smash != null:
				return current_moveset.up_smash
			elif player_input.movement.y < -0.3 and current_moveset.down_smash != null:
				return current_moveset.down_smash

		# Tilts estándar
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
