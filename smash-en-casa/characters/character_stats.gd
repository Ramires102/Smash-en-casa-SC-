class_name CharacterStats
extends Node

signal percentage_changed(new_percentage: float)

@export var max_percentage: float = 999.0
@export var default_weight: float = 100.0

var damage_percentage: float = 0.0
var weight: float = 100.0

func setup(data: CharacterData) -> void:
	if data:
		weight = data.weight
	damage_percentage = 0.0
	percentage_changed.emit(damage_percentage)

func add_damage(amount: float) -> float:
	damage_percentage = DamageCalculator.apply_damage(damage_percentage, amount)
	percentage_changed.emit(damage_percentage)
	return damage_percentage


func reset() -> void:
	damage_percentage = 0.0
	percentage_changed.emit(damage_percentage)
