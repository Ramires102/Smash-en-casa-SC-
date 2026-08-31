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
@export var landing_lag_frames: int = 0 ## 0 = usar fallback dinámico basado en recovery restante

# ── Propiedades de Splash N Dash (Hitboxes.gd) ──
## Angle Flipper: controla la dirección de lanzamiento (0-7). Ver Hitboxes.gd:217-284
@export_range(0, 7) var angle_flipper: int = 0
## Modificador de hitlag: multiplica/divide el freeze de impacto. Ver Hitboxes.gd:90-93
@export var hitlag_modifier: float = 1.0
## Tipo de ataque: "normal", "slash", "explode", "Flip", "none". Ver Hitboxes.gd:157-176
@export var attack_type: String = "normal"

# Configuración espacial de Hitbox estándar
@export var hitbox_offset: Vector3 = Vector3(0.8, 0.0, 0.0)
@export var hitbox_radius: float = 0.6

# Configuración de combos (Jab 1 -> Jab 2 -> Jab 3)
@export var combo_next: AttackData = null
@export var combo_window_frames: int = 14

# Movilidad y recuperación del atacante (Up-B Recovery, lunge forward, etc.)
@export var self_impulse: Vector3 = Vector3.ZERO
@export var self_impulse_frame: int = 0
@export var disable_gravity_during_active: bool = false

# Soporte para ataques multi-hitbox / sweetspots
@export var sub_hitboxes: Array[HitboxData] = []

# Proyectiles y Habilidades Especiales (Knives, Cards, Time Stop)
@export_group("Projectile / Special")
@export var spawns_projectile: bool = false
@export var projectile_scene: PackedScene = null
@export var projectile_speed: float = 18.0
@export var projectile_count: int = 1
@export var projectile_spread_angles: Array[float] = [0.0]
@export var aerial_projectile_angle_offset: float = 0.0
@export var projectile_spawn_frame: int = 4
@export var projectile_offset: Vector3 = Vector3(0.8, 0.2, 0.0)
@export var projectile_lifetime: float = 2.5
@export var is_time_stop: bool = false
@export var time_stop_duration_sec: float = 2.0
@export var time_stop_frame: int = 6
