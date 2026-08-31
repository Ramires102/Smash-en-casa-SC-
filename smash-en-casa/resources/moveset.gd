class_name MoveSet
extends Resource

@export_group("Ground Attacks")
@export var neutral_attack: AttackData
@export var side_tilt: AttackData
@export var up_tilt: AttackData
@export var down_tilt: AttackData

@export_group("Smash Attacks")
@export var forward_smash: AttackData
@export var up_smash: AttackData
@export var down_smash: AttackData

@export_group("Aerial Attacks")
@export var neutral_air: AttackData
@export var forward_air: AttackData
@export var back_air: AttackData
@export var up_air: AttackData
@export var down_air: AttackData

@export_group("Special Attacks")
@export var special_neutral: AttackData
@export var special_side: AttackData
@export var special_up: AttackData
@export var special_down: AttackData

@export_group("Grabs")
@export var grab_attack: AttackData
