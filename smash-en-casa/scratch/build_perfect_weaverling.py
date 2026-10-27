import bpy
import math
from mathutils import Vector, Euler

# 1. Reset
bpy.ops.wm.read_factory_settings(use_empty=True)

# 2. Import original weaverling.glb
bpy.ops.import_scene.gltf(filepath="characters/hornet/weaverling.glb")

# 3. Create distinct Silksong materials
def get_or_create_mat(name, albedo, metallic=0.0, roughness=0.35, emission=None, emission_strength=1.0):
    mat = bpy.data.materials.get(name)
    if not mat:
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = albedo
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission:
            bsdf.inputs["Emission Color"].default_value = emission
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat

mat_body = get_or_create_mat("Weaver_Body", (0.05, 0.05, 0.07, 1.0), roughness=0.3)
mat_eyes = get_or_create_mat("Weaver_Eyes", (1.0, 1.0, 1.0, 1.0), roughness=0.1, emission=(1.0, 1.0, 1.0, 1.0), emission_strength=2.0)
mat_band = get_or_create_mat("Weaver_Band", (0.82, 0.08, 0.16, 1.0), roughness=0.4)
mat_trim = get_or_create_mat("Weaver_Trim", (0.92, 0.90, 0.85, 1.0), roughness=0.3)
mat_tentacles = get_or_create_mat("Weaver_Tentacles", (0.03, 0.03, 0.04, 1.0), roughness=0.25)

# 4. Assign materials to specific meshes
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH':
        continue
    obj.data.materials.clear()
    name = obj.name
    if "Eye" in name and "Lens" in name:
        obj.data.materials.append(mat_eyes)
    elif "Band_Border" in name or "Band_Wave" in name:
        obj.data.materials.append(mat_trim)
    elif "Band" in name:
        obj.data.materials.append(mat_band)
    elif "Tentacle" in name:
        obj.data.materials.append(mat_tentacles)
    else:
        # Head, arms, ears, rims, sockets
        obj.data.materials.append(mat_body)

# 5. Join all parts into a clean single mesh object so it's performant and has 1 transform
bpy.ops.object.select_all(action='DESELECT')
mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
for obj in mesh_objs:
    obj.select_set(True)
active_obj = bpy.data.objects.get("Weaver_Head") if bpy.data.objects.get("Weaver_Head") else mesh_objs[0]
bpy.context.view_layer.objects.active = active_obj
bpy.ops.object.join()

weaver = bpy.context.view_layer.objects.active
weaver.name = "Weaverling"

# 6. Apply transforms, center origin
bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
weaver.location = (0, 0, 0)

# 7. Rotate so eyes point along +X (forward in 2D combat)
# In Blender, eyes were at +Y. Rotating -90 deg around Z turns +Y into +X!
weaver.rotation_euler = Euler((0, 0, -math.pi * 0.5), 'XYZ')
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

# 8. Scale to canonical size: approx 0.35m total height
target_scale = 0.09
weaver.scale = (target_scale, target_scale, target_scale)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

# 9. Export to characters/hornet/weaverling.glb
bpy.ops.export_scene.gltf(
    filepath="characters/hornet/weaverling.glb",
    export_format='GLB',
    use_selection=True,
    export_materials='EXPORT',
    export_apply=True
)

print("Exported perfect weaverling.glb successfully!")
print("Final dimensions:", weaver.dimensions)
