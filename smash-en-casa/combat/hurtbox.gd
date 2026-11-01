# ==============================================================================
# Hurtbox — Caja de Vulnerabilidad del Luchador (Capa 4)
# ==============================================================================
# Recibe impactos de Hitbox o Projectile y filtra si el golpe debe aplicarse
# según el estado defensivo actual del personaje:
#   - NORMAL: recibe daño y knockback normalmente.
#   - INTANGIBLE / INVULNERABLE: ignora por completo el ataque (esquives, respawn).
#   - SUPER_ARMOR: recibe el porcentaje de daño pero no sufre empuje ni aturdimiento.
# ==============================================================================
class_name Hurtbox
extends Area2D

enum HurtboxState {
	NORMAL,
	INTANGIBLE,
	INVULNERABLE,
	SUPER_ARMOR
}

signal impact_received(impact: ImpactData)

@export var owner_character: Node2D
@export var current_state: HurtboxState = HurtboxState.NORMAL
@export var debug_draw_hurtbox: bool = false

## Historial de swing_ids recibidos para impedir que un mismo golpe pegue dos veces.
var _received_swing_ids: Array[int] = []
var _debug_mesh_instance: MeshInstance3D = null

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent() as Node2D
	_setup_debug_visualizer()

func set_state(new_state: HurtboxState) -> void:
	current_state = new_state
	_update_debug_color()

func receive_impact(impact: ImpactData) -> void:
	if current_state == HurtboxState.INTANGIBLE or current_state == HurtboxState.INVULNERABLE:
		return

	if impact.swing_id in _received_swing_ids:
		return
	_received_swing_ids.append(impact.swing_id)

	if current_state == HurtboxState.SUPER_ARMOR:
		impact.knockback_vector = Vector2.ZERO
		impact.hitstun_frames = 0

	if owner_character and owner_character.has_method("on_impact_received"):
		owner_character.on_impact_received(impact)
	impact_received.emit(impact)

func clear_received_swings() -> void:
	_received_swing_ids.clear()

func _setup_debug_visualizer() -> void:
	if owner_character and owner_character.has_node("Humanoid/DebugHurtboxMesh"):
		_debug_mesh_instance = owner_character.get_node("Humanoid/DebugHurtboxMesh") as MeshInstance3D
		if _debug_mesh_instance:
			_debug_mesh_instance.visible = debug_draw_hurtbox
			_update_debug_color()

func _update_debug_color() -> void:
	if not (_debug_mesh_instance and _debug_mesh_instance.material_override is StandardMaterial3D):
		return
	var mat: StandardMaterial3D = _debug_mesh_instance.material_override as StandardMaterial3D
	match current_state:
		HurtboxState.NORMAL:
			mat.albedo_color = Color(0.18, 0.95, 0.42, 0.20)
		HurtboxState.INTANGIBLE:
			mat.albedo_color = Color(0.15, 0.80, 1.0, 0.28)
		HurtboxState.INVULNERABLE:
			mat.albedo_color = Color(1.0, 0.85, 0.18, 0.32)
		HurtboxState.SUPER_ARMOR:
			mat.albedo_color = Color(1.0, 0.55, 0.10, 0.30)
