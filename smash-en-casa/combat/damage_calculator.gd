# ==============================================================================
# DamageCalculator — Cálculo de Acumulación de Porcentaje (%)
# ==============================================================================
# Suma el daño de un ataque al porcentaje acumulado del defensor respetando el
# límite máximo definido en Constants.MAX_PERCENTAGE (999%).
# ==============================================================================
class_name DamageCalculator
extends RefCounted

static func apply_damage(current_percentage: float, damage: float) -> float:
	return clampf(current_percentage + damage, 0.0, Constants.MAX_PERCENTAGE)
