"""
Blender Python script to prepare and export a rigged/animated 3D character to GLB for Godot 4.
Usage inside Blender:
    blender scene.blend --background --python export_character_glb.py -- output.glb
"""
import bpy
import sys

def clean_and_export_glb(output_path: str):
    # Ensure in object mode
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')

    # Apply transforms to non-armature meshes
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH' and obj.parent is None:
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Export to GLB with all animations and armature data
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        export_apply=True,
        export_materials='EXPORT',
        export_yup=True,
        export_animations=True,
        export_morph=True,
        export_skins=True,
        export_normals=True,
        export_def_bones=True
    )
    print(f"[Export] Character successfully exported to {output_path}")

if __name__ == "__main__":
    args = sys.argv
    if "--" in args:
        output_file = args[args.index("--") + 1]
    else:
        output_file = "character_export.glb"
    clean_and_export_glb(output_file)
