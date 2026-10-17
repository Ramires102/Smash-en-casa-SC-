---
name: platform-fighter-combat-feel
description: >-
  Expert architectural principles, formulas, and tuning standards for designing and implementing
  an ultra-fluid, responsive platform fighter combat system in Godot 4. Covers input buffering
  (hold-buffering), FAF/IASA animation cancellation, asymmetric hitlag/hitstop, momentum inheritance,
  dynamic landing lag & auto-cancel windows, out-of-shield (OOS) options, jumpsquat cancels,
  and directional influence (DI / SDI) inspired by open-source engines (Splash N Dash, Castagne, Godot-Smash-Engine).
---

# Master Guide: Fluid Combat System for Platform Fighters (Godot 4)

This skill documents the core systems, mathematical foundations, and state machine patterns required to make a platform fighter feel snappy, fluid, and responsive (Smash Bros. Melee/Ultimate, Rivals of Aether, Splash N Dash), specifically adapted for **Godot 4**.

---

## 1. Core Architecture & Determinism (60 Hz Frame-Cursor)

### 1.1 Integer Frame Cursors vs Float Timers
Never drive fighting game action windows with accumulated floating-point timers (`timer += delta`). Minor float rounding errors lead to 1-frame discrepancies in hitboxes, early cancels, or eaten inputs.

* **Configuration**: Set `Engine.physics_ticks_per_second = 60` in `project.godot`.
* **State Execution**: Each combat state maintains a discrete integer counter:
  ```gdscript
  var frame_cursor: int = 0

  func physics_update(delta: float) -> void:
      if character.is_self_hitlag_active():
          return  # Freeze during hitlag
      frame_cursor += 1
      _process_windows()
  ```

---

## 2. Input Responsiveness & Buffering

### 2.1 The Two Layers of Buffering
1. **Window Buffer (80 - 130 ms / 5 - 8 frames)**:
   Catches inputs pressed just before a state becomes actionable.
2. **Hold Buffer (Sustained Button)**:
   If the player holds down `Attack`, `Jump`, or `Shield` during the final 4-6 frames of an un-interruptible state (e.g., landing lag, hitstun, or recovery), the action executes on **Frame 1** of actionability.

### 2.2 Priority-Based Consumption
When multiple inputs are buffered simultaneously, evaluate by strict priority:
```
1. Special + Direction (Recovery / Anti-air)
2. Smash Attack / Strong
3. Normal Attack / Tilt
4. Jump / Short Hop
5. Shield / Dodge
```

---

## 3. Interruptibility: FAF / IASA (*First Actionable Frame*)

The biggest culprit behind "sluggish" or "clunky" combat is forcing the player to wait for the visual animation to conclude before accepting input.

* **Definition**:
  * `total_frames`: The full visual animation length (e.g., 28 frames).
  * `active_end_frame`: When the hitbox disappears (e.g., frame 14).
  * `faf_frame` (IASA): The first frame the player can interrupt the remaining recovery (e.g., frame 20).
* **Implementation in AttackState**:
  ```gdscript
  # During recovery phase:
  if frame_cursor >= current_attack_data.faf_frame and current_attack_data.faf_frame > 0:
      if character.is_jump_pressed():
          state_machine.transition_to("JumpSquat")
          return
      if character.is_shield_pressed():
          state_machine.transition_to("Shield")
          return
      var input_vec := character.get_input_vector()
      if absf(input_vec.x) > 0.1 and character.is_on_floor():
          state_machine.transition_to("Run" if absf(input_vec.x) > 0.7 else "Walk")
          return
  ```

---

## 4. Aerial Combat: Momentum, Auto-Cancels & Landing Lag

### 4.1 Horizontal Momentum Inheritance
Never zero out horizontal speed when attacking or jumping in the air.
```gdscript
# When transitioning from ground to air:
var jump_forward_speed: float = character.velocity.x * character.controller.jump_momentum_factor
# In air attacks:
character.controller.apply_air_drift(input_vec.x, delta)
```

### 4.2 Auto-Cancel Windows vs Aerial Landing Lag
Aerial attacks have 3 possible landing outcomes:
1. **Empty Landing Lag** (3-4 frames): Player touches ground with no aerial active.
2. **Heavy Landing Lag** (12-22 frames): Player touches ground during active frames or early recovery.
3. **Auto-Cancel Landing** (3-4 frames): Player touches ground during early startup (before hitbox) or late recovery (past `autocancel_after_frame`).

```gdscript
func _check_aerial_landing() -> void:
    if not character.is_on_floor():
        return
    
    var is_autocancel: bool = false
    if current_attack_data.autocancel_before > 0 and frame_cursor <= current_attack_data.autocancel_before:
        is_autocancel = true
    elif current_attack_data.autocancel_after > 0 and frame_cursor >= current_attack_data.autocancel_after:
        is_autocancel = true
        
    var lag_frames: int = Constants.NORMAL_LANDING_LAG if is_autocancel else current_attack_data.landing_lag_frames
    _cancel_attack_into_landing_lag(lag_frames)
```

### 4.3 Fast Fall Acceleration
Tapping Down (`input_vec.y > 0.65`) at the apex of a jump or during falling:
* Sets vertical velocity to `fast_fall_speed` (e.g. 1.5x - 1.8x max fall speed).
* Remains active until hitting the ground or jumping, drastically accelerating approach speed.

---

## 5. Game Feel: Hitstop (Hitlag) & Directional Influence (DI/SDI)

### 5.1 Hitlag Scaling Formula
```gdscript
# Hitlag frames based on raw damage
static func calculate_hitlag(damage: float, modifier: float = 1.0) -> int:
    return int(floor(((floor(damage) * 0.65) + 6.0) / modifier))
```

### 5.2 Asymmetric Hitlag
* **Attacker**: Recovers 1 frame earlier on normal hits.
* **Defender**: Vibrates visually with micro-offsets (`randf_range(-2.0, 2.0)`), allowing SDI inputs.

### 5.3 SDI (Smash Directional Influence) during Hitlag
Each directional flick of the stick during hitlag shifts the defender's position:
```gdscript
func process_sdi_input(stick_vector: Vector2) -> void:
    if stick_vector.length() > 0.7:
        character.global_position += stick_vector.normalized() * SDI_PIXEL_STEP
```

### 5.4 Trajectory DI at Launch
On the final frame of hitlag, apply perpendicular DI to the knockback vector (up to ±18°):
```gdscript
var angle_deg := rad_to_deg(initial_kb.angle())
var di_angle_offset := clampf(input_stick.cross(initial_kb.normalized()) * 18.0, -18.0, 18.0)
var final_angle_rad := deg_to_rad(angle_deg + di_angle_offset)
var final_kb := Vector2.from_angle(final_angle_rad) * initial_kb.length()
```

---

## 6. Defensive Fluidity & Out-of-Shield (OOS)

Shielding must not trap the player into a sluggish defense.
1. **Instant Shield Release to Jump**: Pressing `Jump` in `ShieldState` skips `shield_drop` (15 frames) and enters `JumpSquatState` on **Frame 1**.
2. **Jumpsquat Cancels**: During the 3 frames of `JumpSquatState`, allow immediate cancellation into:
   * **Up-Smash**: `Input: Attack + Up`
   * **Up-Special (Up-B)**: `Input: Special + Up`
   * **Grab**: `Input: Attack` while shielding.

---

## 7. Hitbox & Knockback Decoupling

Keep data and logic cleanly separated:
* **`AttackData` (Resource)**: Stores stats (damage, base KB, scaling, angle, startup, active, recovery, FAF, landing lag, autocancel).
* **`Hitbox` (Node2D/Area2D)**: Detects collision with `Hurtbox` and forwards `AttackData` to `KnockbackCalculator`.
* **`KnockbackCalculator` (Static RefCounted)**: Computes pure mathematical vectors, Sakurai angle resolution, and per-component decay (`hdecay`, `vdecay`).
* **`Character` / `HitState`**: Receives resulting velocity and hitstun frames.
