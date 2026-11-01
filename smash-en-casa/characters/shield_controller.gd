# ==============================================================================
# ShieldController — Sistema de Escudo, Bloqueo y Ruptura (Shield Break)
# ==============================================================================
# Controla la burbuja de escudo 3D del luchador: desgaste gradual al mantenerlo
# activo, absorción de impactos (shieldstun + empuje) y transición a aturdimiento
# ("Daze") si su salud llega a cero.
# ==============================================================================
class_name ShieldController
extends Node

const MAX_SHIELD_HP: float = 50.0
const SHIELD_BREAK_RESPAWN_HP: float = 30.0
const SHIELD_DRAIN_RATE: float = 8.0

@export var character: Character = null

var shield_health: float = MAX_SHIELD_HP

func _ready() -> void:
	if character == null and get_parent() is Character:
		character = get_parent() as Character

func setup(char_node: Character) -> void:
	character = char_node

#region Desgaste, Ruptura y Escalado Visual
func drain(delta: float) -> void:
	shield_health = maxf(0.0, shield_health - SHIELD_DRAIN_RATE * delta)
	update_shield_scale()
	if shield_health <= 0.0:
		break_shield()

func break_shield() -> void:
	shield_health = 0.0
	update_shield_scale()
	if character and character.state_machine:
		character.state_machine.transition_to("Daze")

func restore_after_break() -> void:
	shield_health = SHIELD_BREAK_RESPAWN_HP
	update_shield_scale()

func update_shield_scale() -> void:
	var shield_mesh: Node3D = _get_shield_mesh()
	if shield_mesh:
		var scale_ratio: float = clampf(shield_health / MAX_SHIELD_HP, 0.2, 1.0)
		shield_mesh.scale = Vector3.ONE * scale_ratio

func set_shield_visible(is_vis: bool) -> void:
	var shield_mesh: Node3D = _get_shield_mesh()
	if shield_mesh:
		shield_mesh.visible = is_vis
		if is_vis:
			update_shield_scale()

func _get_shield_mesh() -> Node3D:
	if character == null:
		return null
	if character.visual_controller:
		return character.visual_controller.get_shield_mesh()
	if character.visual_root_3d and character.visual_root_3d.has_node("ShieldMesh"):
		return character.visual_root_3d.get_node("ShieldMesh") as Node3D
	return null
#endregion

#region Absorción de Golpes en Escudo (Shieldstun y Pushback)
func handle_shield_impact(impact: ImpactData) -> bool:
	if impact == null or character == null or not _is_character_in_shield_state():
		return false

	var bonus_shield_damage: float = impact.attack_data.bonus_shield_damage if impact.attack_data else 0.0
	var shield_damage: float = maxf(0.0, impact.damage + bonus_shield_damage)

	shield_health = maxf(0.0, shield_health - shield_damage)
	update_shield_scale()

	if impact.attack_data and impact.attack_data.hit_sfx:
		AudioManager.play_sfx(impact.attack_data.hit_sfx, 0.85)

	if shield_health <= 0.0:
		Events.camera_shake_requested.emit(8.5)
		break_shield()
		return true

	var shieldstun_frames: int = maxi(
		2,
		int(floor((shield_damage * Constants.SHIELD_STUN_DAMAGE_MULT) + Constants.SHIELD_STUN_BASE_FRAMES))
	)
	if character.state_machine and character.state_machine.current_state and character.state_machine.current_state.has_method("apply_shieldstun"):
		character.state_machine.current_state.call("apply_shieldstun", float(shieldstun_frames) / 60.0)

	apply_shield_pushback(impact)
	return true

func apply_shield_pushback(impact: ImpactData) -> void:
	if impact == null or character == null:
		return

	var away_dir: float = -impact.attacker_facing
	if impact.attacker and "global_position" in impact.attacker:
		away_dir = signf(character.global_position.x - impact.attacker.global_position.x)
	if absf(away_dir) < 0.01:
		away_dir = 1.0

	var push_speed: float = clampf(
		Constants.SHIELD_PUSHBACK_BASE + (impact.knockback_magnitude * Constants.SHIELD_PUSHBACK_KB_MULT),
		Constants.SHIELD_PUSHBACK_BASE,
		Constants.SHIELD_PUSHBACK_MAX
	)
	character.velocity.x = away_dir * push_speed

	if impact.attacker is Character:
		var attacker_character: Character = impact.attacker as Character
		attacker_character.velocity.x = -away_dir * push_speed * Constants.SHIELD_ATTACKER_PUSHBACK_MULT

func _is_character_in_shield_state() -> bool:
	if character == null or character.state_machine == null or character.state_machine.current_state == null:
		return false
	return character.state_machine.current_state.name.to_lower() == "shield"

func reset() -> void:
	shield_health = MAX_SHIELD_HP
	set_shield_visible(false)
	update_shield_scale()
#endregion
