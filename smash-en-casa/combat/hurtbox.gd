class_name Hurtbox
extends Area2D

enum HurtboxState {
	NORMAL,        ## Recibe daño y knockback normal
	INTANGIBLE,    ## Los ataques lo atraviesan completamente (Rolls, Spotdodges)
	INVULNERABLE,  ## No recibe daño ni knockback (Respawn, Star KO)
	SUPER_ARMOR    ## Recibe daño pero ignora el knockback
}

signal impact_received(impact: ImpactData)

@export var owner_character: Node2D
@export var current_state: HurtboxState = HurtboxState.NORMAL
@export var debug_draw_hurtbox: bool = false

## IDs de swing ya recibidos para prevenir multi-hit accidental del mismo swing.
var _received_swing_ids: Array[int] = []
var _debug_mesh_instance: MeshInstance3D = null

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent()
	_setup_debug_visualizer()

func _setup_debug_visualizer() -> void:
	if owner_character and owner_character.has_node("Humanoid/DebugHurtboxMesh"):
		_debug_mesh_instance = owner_character.get_node("Humanoid/DebugHurtboxMesh") as MeshInstance3D
		if _debug_mesh_instance:
			_debug_mesh_instance.visible = debug_draw_hurtbox
			_update_debug_color()


## Cambia el estado de vulnerabilidad de la Hurtbox
func set_state(new_state: HurtboxState) -> void:
	current_state = new_state
	_update_debug_color()

func _update_debug_color() -> void:
	if _debug_mesh_instance and _debug_mesh_instance.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = _debug_mesh_instance.material_override as StandardMaterial3D
		match current_state:
			HurtboxState.NORMAL:
				mat.albedo_color = Color(0.18, 0.95, 0.42, 0.20) # Verde Esmeralda
			HurtboxState.INTANGIBLE:
				mat.albedo_color = Color(0.15, 0.80, 1.0, 0.28) # Azul Cyan
			HurtboxState.INVULNERABLE:
				mat.albedo_color = Color(1.0, 0.85, 0.18, 0.32) # Dorado Solar
			HurtboxState.SUPER_ARMOR:
				mat.albedo_color = Color(1.0, 0.55, 0.1, 0.30) # Naranja

## Recibe un impacto canónico. Ignora duplicados o si la Hurtbox es intangible/invulnerable.
func receive_impact(impact: ImpactData) -> void:
	# Si el personaje está intangible o invulnerable, el ataque no conecta
	if current_state == HurtboxState.INTANGIBLE or current_state == HurtboxState.INVULNERABLE:
		return
		
	if impact.swing_id in _received_swing_ids:
		return  # Ya recibimos este swing, ignorar duplicado
	_received_swing_ids.append(impact.swing_id)
	
	if current_state == HurtboxState.SUPER_ARMOR:
		# En Super Armor recibe daño pero knockback se anula a 0
		impact.knockback_vector = Vector2.ZERO
		impact.hitstun_frames = 0
	
	if owner_character and owner_character.has_method("on_impact_received"):
		owner_character.on_impact_received(impact)
	impact_received.emit(impact)


## Limpia el historial de swings recibidos (llamar al respawnear o cambiar de estado).
func clear_received_swings() -> void:
	_received_swing_ids.clear()
