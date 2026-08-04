class_name Hitbox
extends Area3D

signal hit_registered(hurtbox: Hurtbox, attack_data: AttackData)

@export var attack_data: AttackData
var owner_character: Node3D = null
var hit_hurtboxes: Array[Hurtbox] = []

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent()
	area_entered.connect(_on_area_entered)
	monitoring = false

func activate(data: AttackData, attacker: Node3D) -> void:
	attack_data = data
	owner_character = attacker if attacker != null else get_parent()
	hit_hurtboxes.clear()
	monitoring = true
	call_deferred("_check_immediate_overlaps")

func _check_immediate_overlaps() -> void:
	if monitoring:
		for area in get_overlapping_areas():
			_on_area_entered(area)

func deactivate() -> void:
	monitoring = false
	hit_hurtboxes.clear()

func _on_area_entered(area: Area3D) -> void:
	if not monitoring:
		return
	if area is Hurtbox and area not in hit_hurtboxes:
		var target_owner: Node3D = area.owner_character
		if target_owner == null:
			target_owner = area.get_parent()
			
		if target_owner != owner_character:
			hit_hurtboxes.append(area)
			hit_registered.emit(area, attack_data)
			area.take_hit(attack_data, owner_character)
