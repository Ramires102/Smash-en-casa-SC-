---
name: blender-export
description: Export Blender scenes to glTF/GLB (Godot / Web / 3D game engines), FBX, and OBJ. Includes per-format settings, embed textures, bone skins, animation actions / NLA tracks, and Godot 4 compatibility validation. Use whenever exporting 3D models or character animations.
when_to_use: Exporting rigged characters, animations, and stage props to GLB/glTF for Godot or web viewers.
allowed-tools: Read Bash mcp__blender__execute_blender_code mcp__blender__get_scene_info mcp__blender__get_object_info
---

# Blender Export for Godot 4 & Web

## Standard glTF / GLB Export for Character Models & Animations

```python
import bpy

bpy.ops.export_scene.gltf(
    filepath='assets/models/character.glb',
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
```
