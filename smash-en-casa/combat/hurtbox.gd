class_name Hurtbox
extends Area3D

signal hit_received(attack_data: AttackData, attacker: Node3D)

@export var owner_character: Node3D

func take_hit(attack_data: AttackData, attacker: Node3D) -> void:
	if owner_character and owner_character.has_method("on_hit_received"):
		owner_character.on_hit_received(attack_data, attacker)
	hit_received.emit(attack_data, attacker)
