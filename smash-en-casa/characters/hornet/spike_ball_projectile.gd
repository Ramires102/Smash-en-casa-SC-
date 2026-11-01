# ==============================================================================
# SpikeBallProjectile — Trampa con Púas Parabólica (Hornet Neutral Special)
# ==============================================================================
# Proyectil pesado afectado por gravedad que rebota hasta 2 veces contra el
# suelo del escenario (capa de colisión 1) antes de desaparecer.
# ==============================================================================
class_name SpikeBallProjectile
extends Projectile

const GRAVITY_PULL: float = 980.0
const BOUNCE_RESTITUTION: float = 0.55
const STAGE_COLLISION_MASK: int = 1

var bounces_left: int = 2

func setup(data: AttackData, attacker: Node2D, direction: Vector2, custom_speed: float, max_lifetime: float) -> void:
	super.setup(data, attacker, direction, custom_speed, max_lifetime)
	velocity = Vector2(direction.x * 480.0, -380.0)
	original_velocity = velocity

func _physics_process(delta: float) -> void:
	if is_time_frozen:
		return

	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
		return

	velocity.y += GRAVITY_PULL * delta
	global_position += velocity * delta

	if visual_3d:
		var spin_dir: float = signf(velocity.x) if velocity.x != 0.0 else 1.0
		visual_3d.rotation.z += 8.0 * delta * spin_dir

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(0.0, 16.0),
		STAGE_COLLISION_MASK
	)
	var hit_result: Dictionary = space_state.intersect_ray(query)
	if not hit_result.is_empty() and velocity.y > 0.0 and bounces_left > 0:
		velocity.y = -velocity.y * BOUNCE_RESTITUTION
		velocity.x *= 0.8
		bounces_left -= 1
		Events.camera_shake_requested.emit(4.0)
