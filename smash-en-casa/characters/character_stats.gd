# ==============================================================================
# CharacterStats — Estadísticas de Combate del Luchador
# ==============================================================================
# Almacena el peso (que determina qué tan lejos vuela al recibir knockback) y el
# porcentaje de daño acumulado (0% a 999%) al estilo Super Smash Bros.
# ==============================================================================
class_name CharacterStats
extends Node

var damage_percentage: float = 0.0
var weight: float = 100.0

func setup(data: CharacterData) -> void:
	if data:
		weight = data.weight
	damage_percentage = 0.0

func add_damage(amount: float) -> float:
	damage_percentage = DamageCalculator.apply_damage(damage_percentage, amount)
	return damage_percentage

func reset() -> void:
	damage_percentage = 0.0
