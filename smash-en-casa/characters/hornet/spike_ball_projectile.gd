class_name SpikeBallProjectile
extends Projectile

const GRAVITY_PULL: float = 980.0
const BOUNCE_RESTITUTION: float = 0.55
var bounces_left: int = 2

func _physics_process(delta: float) -> void:
	if is_time_frozen:
		return
	
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
		return
	
	# Apply gravity to simulate heavy spiked shot-put
	velocity.y += GRAVITY_PULL * delta
	global_position += velocity * delta
	
	# Rotate ball
	if visual_3d:
		visual_3d.rotation.z += 8.0 * delta * sign(velocity.x if velocity.x != 0 else 1.0)
	
	# Check ground bounce
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 16.0), 1) # Layer 1 is Stage Collision
	var result = space_state.intersect_ray(query)
	if result and velocity.y > 0.0 and bounces_left > 0:
		velocity.y = -velocity.y * BOUNCE_RESTITUTION
		velocity.x *= 0.8
		bounces_left -= 1
		Events.camera_shake_requested.emit(4.0)

func setup(data: AttackData, attacker: Node2D, direction: Vector2, custom_speed: float, max_lifetime: float) -> void:
	super.setup(data, attacker, direction, custom_speed, max_lifetime)
	# Initial arc launch
	var launch_vx: float = direction.x * 480.0
	var launch_vy: float = -380.0
	velocity = Vector2(launch_vx, launch_vy)
	original_velocity = velocity
