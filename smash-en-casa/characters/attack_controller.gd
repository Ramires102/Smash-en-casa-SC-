# ==============================================================================
# AttackController — Selector de Ataques y Control de Hitbox
# ==============================================================================
# Traduce la entrada actual del jugador (stick direccional + botón normal o
# especial + estado en suelo/aire) en el recurso AttackData correspondiente del
# MoveSet del personaje, y delega la activación de la Hitbox 2D.
# ==============================================================================
class_name AttackController
extends Node

@export var hitbox: Hitbox
var current_moveset: MoveSet

func setup(data: CharacterData) -> void:
	if data:
		current_moveset = data.moveset

## Selecciona el ataque adecuado según el contexto (Especial -> Aéreo -> Smash -> Tilt -> Jab).
func get_attack_data_for_input(player_input: PlayerInput, is_on_floor: bool, facing_direction: float = 1.0) -> AttackData:
	if not current_moveset or not player_input:
		return null

	# 1. Ataques Especiales (Botón B / Especial)
	if player_input.special_pressed:
		if player_input.movement.y > 0.3 and current_moveset.special_up != null:
			return current_moveset.special_up
		if player_input.movement.y < -0.3 and current_moveset.special_down != null:
			return current_moveset.special_down
		if absf(player_input.movement.x) > 0.2 and current_moveset.special_side != null:
			return current_moveset.special_side
		return current_moveset.special_neutral

	# 2. Ataques Aéreos (en el aire: Uair, Dair, Fair, Bair, Nair)
	if not is_on_floor:
		if player_input.movement.y > 0.3 and current_moveset.up_air != null:
			return current_moveset.up_air
		if player_input.movement.y < -0.3 and current_moveset.down_air != null:
			return current_moveset.down_air
		if absf(player_input.movement.x) > 0.2:
			var move_dir: float = signf(player_input.movement.x)
			if move_dir == facing_direction and current_moveset.forward_air != null:
				return current_moveset.forward_air
			if move_dir != facing_direction and current_moveset.back_air != null:
				return current_moveset.back_air
		return current_moveset.neutral_air

	# 3. Ataques Smash Terrestres (intención brusca de dash + botón de ataque)
	if player_input.is_dash:
		if absf(player_input.movement.x) > 0.3 and current_moveset.forward_smash != null:
			return current_moveset.forward_smash
		if player_input.movement.y > 0.3 and current_moveset.up_smash != null:
			return current_moveset.up_smash
		if player_input.movement.y < -0.3 and current_moveset.down_smash != null:
			return current_moveset.down_smash

	# 4. Ataques Tilt Terrestres y Jab Neutral
	if player_input.movement.y > 0.3:
		return current_moveset.up_tilt if current_moveset.up_tilt != null else current_moveset.neutral_attack
	if player_input.movement.y < -0.3:
		return current_moveset.down_tilt if current_moveset.down_tilt != null else current_moveset.neutral_attack
	if absf(player_input.movement.x) > 0.2:
		return current_moveset.side_tilt if current_moveset.side_tilt != null else current_moveset.neutral_attack

	return current_moveset.neutral_attack

func enable_hitbox(attack_data: AttackData, attacker: Node2D) -> void:
	if hitbox and attack_data:
		hitbox.activate(attack_data, attacker)

func disable_hitbox() -> void:
	if hitbox:
		hitbox.deactivate()
