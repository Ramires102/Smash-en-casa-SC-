---
name: 3d-character-posing-animation
description: >-
  Expert workflow for 3D character modeling, skeletal rigging, keyframe posing,
  and fighting game combat animation. Covers standard humanoid armature bone hierarchies,
  fighting game pose anatomy (Anticipation, Active/Impact, Recovery, Hitstun, Hitlag, Shield),
  Blender Python pose scripting, GLB/glTF animation library export, and Godot 4 AnimationPlayer integration.
  Use whenever creating 3D models, posing characters, designing attack/movement animations,
  or setting up character animation pipelines.
---

# 3D Character Posing & Animation Workflow

This skill provides the comprehensive guide and toolset for modeling, posing, animating, and exporting 3D characters for fighting games, with direct integration for Godot 4 and Blender.

---

## 1. Humanoid Skeletal Structure & Standard Bone Naming

To ensure maximum compatibility between Blender, Godot 4, and web viewers (Three.js), use standard humanoid bone naming conventions:

```
                  [Head]
                    │
                 [Neck]
                    │
         ┌───────[Chest]───────┐
         │          │          │
   [Shoulder.L]  [Spine]  [Shoulder.R]
         │          │          │
   [UpperArm.L]  [Hips]   [UpperArm.R]
         │       ┌──┴──┐       │
   [LowerArm.L]  │     │  [LowerArm.R]
         │   [UpperLeg.L] [UpperLeg.R] │
      [Hand.L]   │     │    [Hand.R]
             [LowerLeg.L] [LowerLeg.R]
                 │     │
              [Foot.L] [Foot.R]
```

---

## 2. Fighting Game Pose & Animation Anatomy

Fighting game animations must communicate instantly through strong silhouettes and clear timing phases.

### A. Attack Animations (The 3 Core Phases)
1. **Startup / Anticipation (Frames 1 – N):**
   - The windup or coil before the strike.
   - Character pulls weight back, compresses limbs (squash), and focuses energy.
2. **Active / Impact (Frame N+1):**
   - The extreme extension (stretch) where the hitbox is active.
   - Broad line of action, exaggerated silhouette visible clearly from side-view (2.5D camera).
   - Character holds the impact pose during hitlag (Constant/Hold interpolation).
3. **Recovery / Follow-Through (Frames N+2 – End):**
   - Deceleration and return to neutral stance.
   - Momentum carries hair, loose clothing, and secondary limbs forward.

### B. Standard Fighting Game Action Set

| Action State | Key Pose Characteristics | Timing / Interpolation |
| :--- | :--- | :--- |
| **Idle** | Relaxed combat stance, rhythmic breathing, subtle weight shift on knees/hips. | Loop (1.2s – 1.8s), Bezier |
| **Walk** | Grounded step cycle, slight forward chest lean (5°), natural arm swing. | Loop (0.6s – 0.8s), Bezier |
| **Run / Dash** | Aggressive forward tilt (15°–25°), wide strides, lowered center of mass. | Fast loop (0.3s – 0.4s), Bezier |
| **RunBrake** | Backward torso lean (15°), heels dug in, arms stabilizing backward. | One-shot (0.2s – 0.25s), Ease Out |
| **JumpSquat** | Heavy knee compression (Squat down 10–15cm), arms tucked down. | Fast prep (3–5 frames, ~0.06s) |
| **Jump (Ascent)** | Extended torso, legs trailing downward/tucked, head tilted up. | Linear/Ease Out |
| **Fall / FastFall** | Arms out for balance, legs dangling slightly forward, torso upright or tilted down. | Loop (0.4s – 0.5s), Bezier |
| **Squat / Crouch** | Low posture, knees bent outward, hands close to body for low profile. | Hold / Loop, quick transition |
| **Shield / Guard** | Braced pose, arms crossed or defensive bubble posture, feet anchored. | Hold / Subtle pulse |
| **Spotdodge** | Backward evasion on Z-axis, torso twists away from attack plane. | One-shot (0.3s – 0.35s) |
| **Roll** | Forward/backward tuck and spin, low trajectory. | One-shot (0.35s – 0.4s) |
| **Hit / Hitstun** | Sharp torso snap backward (-20°), head snaps back, arms splayed outward. | Instant snap (Frame 1), Ease Out settle |
| **Daze / Broken** | Wobbling unsteadiness, head rolling, knees knocking, sluggish sway. | Slow loop (0.8s – 1.0s) |
| **Ledge Grab** | Arms extended up holding edge, body suspended vertically, legs hanging. | Loop (subtle breathing sway) |

---

## 3. Blender Python Pose & Animation Automation

### Script: Creating a Named Action Pose on an Armature

```python
import bpy
import math

def set_bone_pose_euler(armature_obj, bone_name, rot_degrees, loc=(0,0,0)):
    """Sets the transform of a specific pose bone in Blender."""
    bpy.context.view_layer.objects.active = armature_obj
    bpy.ops.object.mode_set(mode='POSE')
    
    if bone_name not in armature_obj.pose.bones:
        print(f"[Warning] Bone {bone_name} not found in {armature_obj.name}")
        return
        
    pbone = armature_obj.pose.bones[bone_name]
    pbone.rotation_mode = 'XYZ'
    pbone.rotation_euler = tuple(math.radians(deg) for deg in rot_degrees)
    if loc != (0,0,0):
        pbone.location = loc

def create_attack_jab_action(armature_obj, action_name="AttackNeutral"):
    """Generates a complete 3-phase Jab strike animation."""
    if not armature_obj.animation_data:
        armature_obj.animation_data_create()
        
    action = bpy.data.actions.new(name=action_name)
    armature_obj.animation_data.action = action
    
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 24  # 24 frames at 60fps = 0.4s
    
    # 1. Startup (Frame 4): Coil back
    scene.frame_set(4)
    set_bone_pose_euler(armature_obj, "Chest", (0, 10, -10))
    set_bone_pose_euler(armature_obj, "UpperArm.R", (-20, 10, 45))
    set_bone_pose_euler(armature_obj, "LowerArm.R", (0, 0, 90))
    for b in ["Chest", "UpperArm.R", "LowerArm.R"]:
        armature_obj.pose.bones[b].keyframe_insert("rotation_euler", frame=4)
        
    # 2. Active Strike (Frame 8): Full punch extension
    scene.frame_set(8)
    set_bone_pose_euler(armature_obj, "Chest", (5, -15, 15))
    set_bone_pose_euler(armature_obj, "UpperArm.R", (85, -10, -10))
    set_bone_pose_euler(armature_obj, "LowerArm.R", (0, 0, 5))
    for b in ["Chest", "UpperArm.R", "LowerArm.R"]:
        armature_obj.pose.bones[b].keyframe_insert("rotation_euler", frame=8)
        
    # 3. Recovery (Frame 24): Return to neutral
    scene.frame_set(24)
    set_bone_pose_euler(armature_obj, "Chest", (0, 0, 0))
    set_bone_pose_euler(armature_obj, "UpperArm.R", (0, 0, 0))
    set_bone_pose_euler(armature_obj, "LowerArm.R", (0, 0, 0))
    for b in ["Chest", "UpperArm.R", "LowerArm.R"]:
        armature_obj.pose.bones[b].keyframe_insert("rotation_euler", frame=24)
        
    print(f"Action '{action_name}' generated successfully.")
```

---

## 4. Godot 4 Integration Pipeline

### A. Animation Name Suffix Convention
In Godot 4, the `AnimationController` (`smash-en-casa/characters/animation_controller.gd`) resolves animations by mapping combat states to GLB clip names or fallback procedural tracks:

- State `Idle` $\rightarrow$ GLB clip `*idle*` or `*miyabiaction*`
- State `Walk` $\rightarrow$ GLB clip `*walk*`
- State `Run` $\rightarrow$ GLB clip `*run*`
- State `Attack` / `AttackNeutral` $\rightarrow$ GLB clip `*ataque*`
- State `SpecialUp` $\rightarrow$ GLB clip `*especial arriba*`
- State `SpecialDown` $\rightarrow$ GLB clip `*especial abajo (parry)*`

### B. Procedural Pose Animation in GDScript
When a 3D model lacks a specific internal clip, procedural animations can be generated at runtime on `ModelRoot` or `Skeleton3D`:

```gdscript
func create_custom_pose_animation(anim_name: String, length: float) -> Animation:
    var anim := Animation.new()
    anim.length = length
    
    # Position Track
    var pos_track = anim.add_track(Animation.TYPE_VALUE)
    anim.track_set_path(pos_track, "Humanoid/ModelRoot:position")
    anim.track_insert_key(pos_track, 0.0, Vector3(0.0, -0.9, 0.0))
    anim.track_insert_key(pos_track, length * 0.5, Vector3(0.0, -1.05, 0.0))
    anim.track_insert_key(pos_track, length, Vector3(0.0, -0.9, 0.0))
    
    # Rotation Track
    var rot_track = anim.add_track(Animation.TYPE_VALUE)
    anim.track_set_path(rot_track, "Humanoid/ModelRoot:rotation_degrees")
    anim.track_insert_key(rot_track, 0.0, Vector3(0.0, 0.0, 0.0))
    anim.track_insert_key(rot_track, length * 0.5, Vector3(10.0, 0.0, 0.0))
    anim.track_insert_key(rot_track, length, Vector3(0.0, 0.0, 0.0))
    
    return anim
```

---

## 5. Web 3D Pose Preview Tool (`sakuya_animator.html`)

For rapid visual verification of poses and bone rotation values without starting the full game engine:
1. Open `smash-en-casa/sakuya_animator.html` in your browser.
2. Load any GLB model (`sakuya.glb`, `RobotExpressive.glb`, `john placeholder.gltf`).
3. Manipulate bones, test animations, and copy exact Euler rotation angles for Godot/Blender scripts.
