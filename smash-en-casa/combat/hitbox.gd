class_name Hitbox
extends Area3D

signal hit_registered(hurtbox: Hurtbox, attack_data: AttackData)

@export var attack_data: AttackData
var owner_character: Node3D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false

func activate(data: AttackData, attacker: Node3D) -> void:
	attack_data = data
	owner_character = attacker
	monitoring = true

func deactivate() -> void:
	monitoring = false

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox and area.owner_character != owner_character:
		hit_registered.emit(area, attack_data)
		area.take_hit(attack_data, owner_character)
