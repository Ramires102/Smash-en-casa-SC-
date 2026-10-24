class_name AttackData
extends Resource

@export var id: String = ""
@export var attack_name: String = "Neutral Attack"
@export var display_name: String = ""
@export var animation_name: String = "AttackNeutral"
@export var pose_style: String = "jab_combo"
@export var vfx_type: String = "slash_gold"
@export var attack_type: String = "normal"
@export var is_special_attack: bool = false

@export_group("Frame Data (60 FPS)")
@export var startup_frames: int = 4
@export var active_frames: int = 6
@export var recovery_frames: int = 10
@export var faf_frame: int = 0
@export var second_hit_frame: int = 0
@export var landing_lag_frames: int = 0
@export var autocancel_before: int = 0
@export var autocancel_after: int = 0

@export_group("Damage & Knockback")
@export var damage: float = 8.0
@export var base_knockback: float = 5.0
@export var knockback_scaling: float = 0.12
@export var angle_degrees: float = 45.0
@export var knockback_angle: float = 45.0:
	get:
		return angle_degrees
	set(val):
		angle_degrees = val
@export_range(0, 7) var angle_flipper: int = 0
@export var hitlag_modifier: float = 1.0
@export var hitlag_multiplier: float = 1.0:
	get:
		return hitlag_modifier
	set(val):
		hitlag_modifier = val
@export var bonus_shield_damage: float = 0.0
@export var hit_sfx: AudioStream = null

@export_group("Hitbox Geometry")
@export var hitbox_offset: Vector3 = Vector3(0.8, 0.0, 0.0)
@export var hitbox_size: Vector2 = Vector2(1.4, 1.4)
@export var hitbox_radius: float = 0.6
@export var is_aerial: bool = false
@export var sub_hitboxes: Array[HitboxData] = []

@export_group("Movement & Special Mechanics")
@export var self_impulse: Vector3 = Vector3.ZERO
@export var self_impulse_frame: int = 0
@export var disable_gravity_during_active: bool = false
@export var is_divekick: bool = false
@export var divekick_speed: Vector2 = Vector2(378.0, 560.0)

@export var vault_behind_on_hit: bool = false
@export var snap_in_front_of_opponent: bool = false
@export var drag_defender_on_hit: bool = false
@export var toss_behind_on_hit: bool = false
@export var flip_facing_on_start: bool = false
@export var sliding_knockdown: bool = false
@export var telekinesis_grab_on_hit: bool = false
@export var is_telekinesis_hold: bool = false
@export var is_telekinesis_throw: bool = false
@export var is_parry_stance: bool = false
@export var is_parry_counter_impale: bool = false

@export_group("Combos & Follow-ups")
@export var combo_next: AttackData = null
@export var combo_window_frames: int = 35
@export var auto_followup_on_hit: AttackData = null
@export var auto_followup_always: bool = false

@export_group("Projectiles & Time Stop")
@export var spawns_projectile: bool = false
@export var projectile_scene: PackedScene = null
@export var projectile_count: int = 1
@export var projectile_spawn_frame: int = 4
@export var projectile_offset: Vector3 = Vector3(0.8, 0.2, 0.0)
@export var projectile_speed: float = 18.0
@export var projectile_lifetime: float = 2.5
@export var projectile_spread_angles: Array[float] = [0.0]
@export var aerial_projectile_angle_offset: float = 0.0
@export var use_distance_damage_falloff: bool = false
@export var close_range_max_meters: float = 3.2
@export var close_range_damage: float = 3.0
@export var mid_range_max_meters: float = 7.5
@export var mid_range_damage: float = 2.0
@export var far_range_damage: float = 1.3
@export var is_time_stop: bool = false
@export var time_stop_frame: int = 6
@export var time_stop_duration_sec: float = 2.0
