# ==============================================================================
# ImpactData — Paquete de Datos de un Impacto Confirmado (DTO)
# ==============================================================================
# Cuando una Hitbox o un Proyectil toca una Hurtbox enemiga, se construye una
# instancia de ImpactData con todos los resultados matemáticos ya resueltos
# (daño, vector de empuje, hitstun y hitlag) y viaja por todo el pipeline:
#   Hitbox / Projectile -> Hurtbox -> Character (Escudo o Daño).
# ==============================================================================
class_name ImpactData
extends RefCounted

#region Identidad de Atacante y Defensor
var swing_id: int = -1
var attacker: Node = null
var attacker_id: int = -1
var target: Node = null
var target_id: int = -1
var attacker_facing: float = 1.0
#endregion

#region Datos del Golpe y Resultados Físicos
var attack_data: AttackData = null
var attack_name: String = ""
var damage: float = 0.0
var target_percent_after: float = 0.0

var knockback_vector: Vector2 = Vector2.ZERO
var knockback_magnitude: float = 0.0
var hdecay: float = 0.0
var vdecay: float = 0.0
var hitstun_frames: int = 0
var hitlag_frames: int = 0
#endregion

#region Fábrica Compartida (Hitbox y Proyectiles)
## Construye y calcula un ImpactData completo a partir de los datos del ataque y del objetivo.
static func create_from_attack(
	p_swing_id: int,
	p_attacker: Node2D,
	p_target: Node2D,
	p_attack_data: AttackData,
	p_damage: float,
	p_attack_name: String,
	p_facing: float,
	p_sweetspot: HitboxData = null
) -> ImpactData:
	var impact := ImpactData.new()
	impact.swing_id = p_swing_id
	impact.attacker = p_attacker
	impact.target = p_target
	impact.attacker_id = p_attacker.player_id if (p_attacker and "player_id" in p_attacker) else -1
	impact.target_id = p_target.player_id if (p_target and "player_id" in p_target) else -1
	impact.attacker_facing = p_facing
	impact.attack_data = p_attack_data
	impact.attack_name = p_attack_name
	impact.damage = p_damage

	var current_percent: float = p_target.damage_percentage if (p_target and "damage_percentage" in p_target) else 0.0
	impact.target_percent_after = DamageCalculator.apply_damage(current_percent, p_damage)

	var target_weight: float = p_target.weight if (p_target and "weight" in p_target) else 100.0
	var target_in_air: bool = not p_target.is_on_floor() if (p_target and p_target.has_method("is_on_floor")) else true

	var kb_base: float = p_sweetspot.base_knockback if p_sweetspot else (p_attack_data.base_knockback if p_attack_data else 15.0)
	var kb_scaling: float = p_sweetspot.knockback_scaling if p_sweetspot else (p_attack_data.knockback_scaling if p_attack_data else 100.0)
	var angle_deg: float = p_sweetspot.angle_degrees if p_sweetspot else (p_attack_data.angle_degrees if p_attack_data else 45.0)
	var hitlag_mod: float = p_attack_data.hitlag_modifier if p_attack_data else 1.0

	var result: Dictionary = KnockbackCalculator.calculate_full_knockback(
		impact.target_percent_after,
		p_damage,
		target_weight,
		kb_base,
		kb_scaling,
		angle_deg,
		hitlag_mod,
		p_facing,
		target_in_air
	)

	impact.knockback_magnitude = result.kb
	impact.knockback_vector = Vector2(result.vx, result.vy)
	impact.hdecay = result.hdecay
	impact.vdecay = result.vdecay
	impact.hitstun_frames = result.hitstun
	impact.hitlag_frames = result.hitlag
	return impact
#endregion
