class_name Pushbox
extends Area3D

## Componente de colisión y separación suave entre luchadores estilo Super Smash Bros.
## Evita solapamientos, atravesamientos físicos y montajes glitchy entre personajes.

@export var owner_character: CharacterBody3D
@export var push_radius: float = 0.52
@export var push_force: float = 14.0 # Velocidad de separación suave (m/s)
@export var debug_draw_pushbox: bool = true

var _debug_mesh_instance: MeshInstance3D = null

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent() as CharacterBody3D
	if debug_draw_pushbox:
		_setup_debug_visualizer()

func _setup_debug_visualizer() -> void:
	if _debug_mesh_instance == null:
		_debug_mesh_instance = MeshInstance3D.new()
		_debug_mesh_instance.name = "DebugPushboxMesh"
		var capsule := CapsuleMesh.new()
		capsule.radius = push_radius
		capsule.height = 1.8
		_debug_mesh_instance.mesh = capsule
		
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.3, 0.4, 1.0, 0.25) # Azul semi-transparente
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_debug_mesh_instance.material_override = mat
		add_child(_debug_mesh_instance)

func _physics_process(delta: float) -> void:
	if owner_character == null or not owner_character.visible:
		return
		
	for area in get_overlapping_areas():
		if area is Pushbox and area != self:
			_resolve_push(area, delta)

func _resolve_push(other_pushbox: Pushbox, delta: float) -> void:
	var other_char: CharacterBody3D = other_pushbox.owner_character
	if other_char == null or not other_char.visible:
		return
		
	var self_pos: Vector3 = owner_character.global_position
	var other_pos: Vector3 = other_char.global_position
	
	# Verificar si están en un rango vertical que deba empujar (~1.8m de altura)
	var dy: float = absf(self_pos.y - other_pos.y)
	if dy > 1.75:
		return
		
	var dx: float = self_pos.x - other_pos.x
	var total_radius: float = push_radius + other_pushbox.push_radius
	var dist_x: float = absf(dx)
	
	if dist_x < total_radius:
		var overlap: float = total_radius - dist_x
		var push_dir: float = 1.0
		
		if dist_x > 0.01:
			push_dir = signf(dx)
		else:
			# Si están exactamente en el mismo punto X, desempatar por ID del jugador
			var self_id: int = owner_character.get("player_id") if "player_id" in owner_character else 1
			push_dir = 1.0 if self_id == 1 else -1.0
			
		# Separación suave sin jittering
		var separation_step: float = (overlap * 0.5) * minf(push_force * delta, 1.0)
		owner_character.global_position.x += push_dir * separation_step
