# Explicación de los Estados Activos de la FSM (`characters/state_machine/`)

## Resumen
Cada estado hereda de `State` (`state.gd`) y encapsula una única conducta del luchador siguiendo el **Patrón State**. De este modo se evitan condicionales gigantes (`if/elif`) en `Character` y cada transición queda aislada y fácil de estudiar.

---

## Catálogo de Estados Activos

### 1. Suelo y Movimiento
- **`IdleState` (`idle_state.gd`)**: Reposo en tierra; aplica tracción de frenado y escucha intenciones de carrera, salto, ataque o escudo.
- **`RunState` (`run_state.gd`)**: Carrera horizontal a `run_speed`, permitiendo ataques en carrera, salto o escudo instantáneo.
- **`JumpSquatState` (`jumpsquat_state.gd`)**: Pre-salto universal de **3 frames** (`0.05 s`) que distingue entre *Short Hop* (soltar botón antes de despegar) y *Full Hop* (mantener botón).

### 2. Aire y Recuperación en Borde
- **`JumpState` (`jump_state.gd`)**: Ascenso aéreo inicial o doble salto (`air_jumps`), con control horizontal aéreo (*air drift*).
- **`FallState` (`fall_state.gd`)**: Caída libre con soporte para caída rápida (*Fast-Fall*), ataques aéreos, esquiva aérea y agarre de bordes.
- **`LedgeState` (`ledge_state.gd`)**: Colgado de un `LedgePoint` con invulnerabilidad temporal y opciones de subida, salto o soltarse.
- **`LedgeGetupState` (`ledge_getup_state.gd`)**: Subida invulnerable desde el borde hacia la plataforma.

### 3. Ofensiva y Daño
- **`AttackState` (`attack_state.gd`)**: Ejecuta las tres fases de cualquier `AttackData` (*Startup* → *Active* → *Recovery*), soportando cancelación temprana (*FAF / IASA*) y *Landing Lag* en ataques aéreos.
- **`HitState` (`hit_state.gd`)**: Aturdimiento por golpe (*Hitstun*), aplicando el vector de *Knockback* e influencia direccional (*DI*).
- **`DeathState` (`death_state.gd`)**: Cruce de *Blast Zone* (KO), tiempo de espera y reaparición con invulnerabilidad temporal.

### 4. Defensa y Esquivas
- **`ShieldState` (`shield_state.gd`)**: Burbuja de escudo 3D que drena energía con el tiempo y los golpes, soporta *Parry* al soltar justo a tiempo y opciones *Out of Shield* (Salto, Roll, SpotDodge).
- **`RollState` (`roll_state.gd`)**: Rodada lateral en el suelo con ventana de invulnerabilidad y cruce de *Pushbox*.
- **`SpotDodgeState` (`spotdodge_state.gd`)**: Esquiva rápida en el propio lugar con frames invulnerables.
- **`AirDodgeState` (`air_dodge_state.gd`)**: Esquiva direccional o neutra en el aire (1 uso hasta tocar suelo o borde).
- **`DazeState` (`daze_state.gd`)**: Aturdimiento prolongado tras romperse el escudo (*Shield Break*), reducible machacando botones (*mashing*).
