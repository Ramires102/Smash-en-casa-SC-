---
name: blender-modeling
description: Create and edit 3D meshes in Blender — primitives, hard-surface modeling, mesh operators, modifier stacks (Bevel, Subdivision, Boolean, Mirror, Array, Solidify), bmesh-level edits, character blockouts, and armature rigging prep. Use whenever the user asks to "make/model/create/build a 3D object", "shape/sculpt this", "add a cube/sphere/cylinder/etc.", "extrude/inset/bevel this face", "add a modifier", or any geometry-creation request.
when_to_use: Any geometry creation, mesh edit, character blockout, or modifier stack work in Blender.
allowed-tools: Read Bash mcp__blender__execute_blender_code mcp__blender__get_scene_info mcp__blender__get_object_info
---

# Blender Modeling

Create geometry in Blender via natural language and Blender Python.

## Decision tree

```
What kind of geometry?
├── Hard-surface (weapons, stage props, shields, projectiles)
│   → Cube primitive + Bevel + SubSurf modifier stack
│
├── Character / Humanoid block-out
│   → Skin modifier + Armature / primitive limbs blockout
│   → Mirror modifier for symmetric bodies
│
├── Holes / cuts in existing geometry
│   → Boolean modifier (DIFFERENCE)
│
└── Quick block-out from primitives
    → Multiple primitive_*_add calls
```

## Essential Rules

- Always prefix meshes with `GEO-` or clean semantic names (e.g. `GEO-Character_Head`, `GEO-Sword`).
- Orient character models facing -Y (Forward) and Z (Up) so they export correctly into Godot.
- Apply transforms (`bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)`) before parenting to armatures.
