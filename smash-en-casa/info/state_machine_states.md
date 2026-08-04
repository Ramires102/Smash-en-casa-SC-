# Explicación de los Estados de la FSM (`characters/state_machine/`)

## Resumen
Cada estado individual hereda de `State` ([state.gd](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/state.gd)) y encapsula una conducta específica mapeada a la arquitectura **ACMD Action States** de *Super Smash Bros. Ultimate*.

---

## 1. `state_machine.gd` (Mapeo ACMD Action States)
Mapea alias nativos mediante el diccionario `ACMD_ALIASES`:
- `WAIT` $\to$ `IdleState`
- `WALK` $\to$ `WalkState`
- `DASH` $\to$ `DashState`
- `RUN` $\to$ `RunState`
- `RUN_BRAKE` $\to$ `RunBrakeState`
- `PIVOT` $\to$ `PivotState`
- `SQUAT` $\to$ `SquatState`
- `JUMP_SQUAT` $\to$ `JumpSquatState`
- `JUMP_F` / `JUMP_B` / `JUMP_AERIAL` $\to$ `JumpState`
- `FALL` / `FAST_FALL` / `FALL_SPECIAL` $\to$ `FallState`
- `GUARD_ON` / `GUARD` / `GUARD_OFF` / `GUARD_DAMAGE` $\to$ `ShieldState`
- `ESCAPE_F` / `ESCAPE_B` $\to$ `RollState`
- `ESCAPE_N` $\to$ `SpotDodgeState`
- `DAMAGE_FLY` / `DAMAGE_FALL` / `STOP_SCE` $\to$ `HitState`
- `DAZE` $\to$ `DazeState`

---

## 2. `walk_state.gd` (`WALK`)
- Caminar a velocidad de caminata `walk_speed`. Mantiene colisiones sólidas de *Pushbox* (Walking Pushback).

---

## 3. `dash_state.gd` (`DASH`)
- Impulso ininterrumpido inicial a velocidad de Dash `initial_dash_speed` durante 0.15s al hacer doble tap en una dirección.

---

## 4. `run_state.gd` (`RUN`)
- Carrera sostenida a velocidad de movimiento `run_speed`. Permite *Pushbox Cross-Through*.

---

## 5. `run_brake_state.gd` (`RUN_BRAKE`)
- Animación y desaceleración progresiva con fricción/tracción al soltar la palanca durante una carrera.

---

## 6. `pivot_state.gd` (`PIVOT`)
- Giro de orientación y frenado de inercia (~6 frames) al cambiar de dirección abruptamente durante una carrera. Al concluir el giro, si se mantiene la nueva dirección, reanuda automáticamente la carrera (`RunState`) sin requerir un nuevo doble toque.

---

## 7. `squat_state.gd` (`SQUAT`)
- Estado agachado al mantener la palanca hacia Abajo en el suelo.

---

## 8. `jumpsquat_state.gd` (`JUMP_SQUAT`)
- Fase de pre-salto universal de **3 frames** ($0.05\text{s}$) al pulsar el botón de salto en el suelo. Determina si el salto es *Short Hop* ($0.75\times$) o *Full Hop* ($1.0\times$).

---

## 9. `idle_state.gd` (`WAIT`)
- Estado de reposo.

---

## 10. `jump_state.gd` (`JUMP_F` / `JUMP_B`)
- Elevación vertical.

---

## 11. `fall_state.gd` (`FALL` / `FAST_FALL`)
- Caída libre y caída rápida (*Fast Fall*).

---

## 12. `shield_state.gd` (`GUARD_ON` / `GUARD` / `GUARD_OFF`)
- Escudo 3D con drenaje, OOS (JumpSquat, RollState, SpotDodgeState), Shield Drop Lag (11f) y Parry (5f).

---

## 13. `roll_state.gd` (`ESCAPE_F` / `ESCAPE_B`)
- Rodada con invulnerabilidad, Pushbox Cross-Through y giro automático hacia la espalda del rival.

---

## 14. `spotdodge_state.gd` (`ESCAPE_N`)
- Esquivo en el sitio.

---

## 15. `daze_state.gd` (`DAZE`)
- Aturdimiento por Shield Break con aturdimiento dinámico 4-10s, button mashing, estrellitas amarillas y parpadeo rojo.
