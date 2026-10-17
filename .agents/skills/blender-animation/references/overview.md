# Animation — Pro Knowledge Overview

**Domain**: 09 — Keyframes, F-curves, NLA, drivers, shape keys  

## The animation systems

| System | What it animates | Use for |
|--------|-----------------|---------|
| **Keyframe animation** | Any property | Primary transforms (object/bone motion, camera, light intensity) |
| **F-curves** | Interpolation between keyframes | Easing, smooth motion, fine-tuning |
| **NLA (Non-Linear Animation)** | Action clips, layers | Reusable animations, blending moves |
| **Drivers** | Property = expression of another | Mechanical relations, corrective shapes |
| **Shape keys** | Mesh deformation targets | Facial expressions, morphing, blend shapes |

---

## Armature Pose Keyframing

```python
import bpy

armature = bpy.data.objects['GEO-Armature']
bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='POSE')

# Pose a bone
bone = armature.pose.bones['UpperArm.R']
bone.rotation_mode = 'XYZ'
bone.rotation_euler = (0.5, 0.2, -0.3)
bone.keyframe_insert(data_path='rotation_euler', frame=10)
```

## Interpolation modes
| Mode | Behavior | Use |
|------|----------|-----|
| **Bezier** (default) | Smooth S-curve | Organic motion |
| **Linear** | Constant velocity | Mechanical motion, fast transitions |
| **Constant** | Step (no interpolation) | Freeze frame, hitlag pose holds |
| **Bounce, Elastic, Back** | Overshoots | Cartoon, impact reactions |
