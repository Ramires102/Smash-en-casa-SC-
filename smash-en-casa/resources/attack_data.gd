# ==============================================================================
# AttackData — Recurso de Datos de un Movimiento de Combate
# ==============================================================================
# Diseño orientado a datos (Data-Driven Design): cada golpe del juego es un
# archivo .tres de este tipo (o una instancia generada en MoveSet) que describe
# sus frames (Startup, Active, Recovery), daño, knockback, geometría de hitbox,
# impulsos, encadenamiento de combos y proyectiles, sin escribir un script nuevo
# por cada ataque.
# ==============================================================================
class_name AttackData
extends Resource

#region Identidad y Presentación
@export var id: String = ""
@export var attack_name: String = ""
@export var display_name: String = ""
@export var animation_name: String = "Attack"
@export var pose_style: String = "jab_combo"
@export var vfx_type: String = "slash_gold"
@export var attack_type: String = "normal"
@export var is_special_attack: bool = false
## Costo de Seda para movimientos especiales de Hornet (0 para el resto del elenco).
@export var silk_cost: int = 0
#endregion

#region Frame Data (Base 60 FPS)
@export_group("Frame Data (60 FPS)")
@export var startup_frames: int = 5     ## Frames de preparación antes de activar la Hitbox
@export var active_frames: int = 5      ## Frames durante los cuales la Hitbox puede golpear
@export var recovery_frames: int = 10   ## Frames de enfriamiento tras apagar la Hitbox
@export var faf_frame: int = 0          ## First Actionable Frame: permite cancelar recuperación temprano (IASA)
@export var second_hit_frame: int = 0   ## Si > 0, limpia la lista de golpeados en este frame para golpes dobles
@export var landing_lag_frames: int = 0 ## Pausa al aterrizar en mitad de un ataque aéreo
@export var autocancel_before: int = 0  ## Si aterriza antes de este frame, no sufre Landing Lag extra
@export var autocancel_after: int = 0   ## Si aterriza después de este frame, no sufre Landing Lag extra
#endregion

#region Daño, Knockback y Sonido
@export_group("Damage & Knockback")
@export var damage: float = 8.0
@export var base_knockback: float = 5.0
@export var knockback_scaling: float = 0.12
@export var angle_degrees: float = 45.0
## Alias serializado en algunos recursos .tres para leer/escribir angle_degrees.
@export var knockback_angle: float = 45.0:
	get:
		return angle_degrees
	set(val):
		angle_degrees = val
@export var angle_flipper: int = 0
@export var hitlag_modifier: float = 1.0
## Alias serializado en algunos recursos .tres para leer/escribir hitlag_modifier.
@export var hitlag_multiplier: float = 1.0:
	get:
		return hitlag_modifier
	set(val):
		hitlag_modifier = val
@export var bonus_shield_damage: float = 0.0
@export var hit_sfx: AudioStream = null
#endregion

#region Geometría de Colisión (Hitbox)
@export_group("Hitbox Geometry")
@export var hitbox_offset: Variant = Vector2(1.0, 1.0)
@export var hitbox_size: Vector2 = Vector2(1.4, 1.4)
@export var hitbox_radius: float = 0.72
@export var is_aerial: bool = false
## Sub-cajas opcionales para distinguir Sweetspot (punta fuerte) y Sourspot (base débil).
@export var sub_hitboxes: Array[HitboxData] = []
#endregion

#region Movimiento y Mecánicas Especiales de Impacto
@export_group("Movement & Special Mechanics")
@export var self_impulse: Variant = Vector2.ZERO
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
#endregion

#region Combos y Seguimientos Automáticos
@export_group("Combos & Follow-ups")
@export var combo_next: AttackData = null
@export var combo_window_frames: int = 35
@export var auto_followup_on_hit: AttackData = null
@export var auto_followup_always: bool = false
#endregion

#region Proyectiles y Detención del Tiempo
@export_group("Projectiles & Time Stop")
@export var spawns_projectile: bool = false
@export var projectile_scene: PackedScene = null
@export var projectile_spawn_frame: int = 0
@export var projectile_offset: Variant = Vector2(1.2, 1.1)
@export var projectile_speed: float = 650.0
@export var projectile_lifetime: float = 1.6
@export var projectile_spread_angles: Array[float] = []
@export var aerial_projectile_angle_offset: float = 0.0
@export var use_distance_damage_falloff: bool = false
@export var close_range_max_meters: float = 2.5
@export var close_range_damage: float = 8.0
@export var mid_range_max_meters: float = 5.0
@export var mid_range_damage: float = 6.0
@export var far_range_damage: float = 4.0
@export var is_time_stop: bool = false
@export var time_stop_frame: int = 0
@export var time_stop_duration_sec: float = 1.5
#endregion
