class_name AttackData
extends Resource

@export var attack_name: String = "Neutral Attack"
@export var damage: float = 8.0
@export var base_knockback: float = 15.0
@export var knockback_scaling: float = 1.0
@export var angle_degrees: float = 45.0
@export var startup_frames: int = 4
@export var active_frames: int = 6
@export var recovery_frames: int = 10
@export var animation_name: String = "AttackNeutral"
@export var hit_sfx: AudioStream
@export var bonus_shield_damage: float = 0.0
@export var is_aerial: bool = false
