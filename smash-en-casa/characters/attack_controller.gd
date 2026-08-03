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

func get_attack_data_for_input(player_id: int, input_vec: Vector2, is_on_floor: bool) -> AttackData:
	if not current_moveset:
		return null
		
	if InputManager.is_special_pressed(player_id):
		return current_moveset.special_neutral
	elif not is_on_floor:
		return current_moveset.neutral_air
	elif abs(input_vec.x) > 0.1:
		return current_moveset.side_tilt
	elif input_vec.y > 0.1:
		return current_moveset.up_tilt
	elif input_vec.y < -0.1:
		return current_moveset.down_tilt
	return current_moveset.neutral_attack

func start_attack(attack_data: AttackData, attacker: Node3D) -> void:
	if not attack_data:
		return
	is_attacking = true
	attack_executed.emit(attack_data)

func enable_hitbox(attack_data: AttackData, attacker: Node3D) -> void:
	if hitbox and attack_data:
		hitbox.activate(attack_data, attacker)

func disable_hitbox() -> void:
	if hitbox:
		hitbox.deactivate()
	is_attacking = false
	attack_ended.emit()
