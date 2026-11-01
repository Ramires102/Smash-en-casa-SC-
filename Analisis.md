# Guía de Estudio y Análisis de Arquitectura — Smash en Casa

**Materia:** Programación 4  
**Autores:** Rodrigo Espinoza Squef y Pablo Chiavetta Chavez  
**Motor:** Godot Engine 4.7 (GDScript tipado estáticamente)

---

## 1. ¿Qué es este proyecto y cómo está construido?

**Smash en Casa** es un videojuego de peleas de plataformas (*Platform Fighter* al estilo *Super Smash Bros.*) para **2 a 4 jugadores en simultáneo**.

En lugar de derrotar al rival vaciando una barra de vida fija, cada golpe aumenta el **porcentaje de daño acumulado (`0%` a `999%`)** del oponente. Cuanto mayor es ese porcentaje, más lejos sale disparado el personaje (*Knockback*) hasta cruzar los límites del escenario (*Blast Zones*) y perder una vida (*Stock*).

### Características Técnicas Destacadas
- **Motor Híbrido 2.5D**: Física 2D exacta a 60 FPS combinada con escenarios, iluminación, esqueletos y modelos 3D en tiempo real.
- **Arquitectura Orientada a Datos (*Data-Driven*)**: Los 6 personajes comparten una única clase `Character`; sus estadísticas, modelos y ataques se inyectan mediante recursos `.tres`.
- **Soporte Multijugador (hasta 4 controles)**: Configurador interactivo inspirado en el emulador *Yuzu* con vista previa vectorial de un mando de Xbox, zona muerta configurable y perfiles guardados en JSON.
- **Tabla de Clasificación (*Leaderboard*)**: Registro persistente de victorias, derrotas, porcentaje de victoria (*Win Rate*) y personaje favorito asociado a cada perfil de jugador.

---

## 2. Patrones de Diseño Aplicados (Clave para la Presentación)

En una defensa de **Programación 4**, explicar **qué patrones de diseño se usaron y qué problema resuelven** demuestra dominio de ingeniería de software:

### 2.1 Patrón Singleton (Autoloads de Godot) — `core/`
- **Dónde está**: [`Events`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/events.gd), [`GameManager`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/game_manager.gd), [`InputManager`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/input_manager.gd), [`AudioManager`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/audio_manager.gd) y [`ProfileManager`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/profile_manager.gd).
- **Por qué se usó**: Cuando Godot cambia de escena (por ejemplo, de `character_select.tscn` a `battle.tscn`), todos los nodos de la escena anterior se destruyen. Los *Autoloads* viven en la raíz del árbol y conservan quiénes están jugando, sus controles, la música y el ranking.
- **Buena práctica aplicada**: **No abusamos del Singleton**. El árbitro de la pelea (`BattleManager`) y la cámara (`CameraController`) **no** son Autoloads porque solo tienen sentido dentro del combate.

### 2.2 Patrón Observer (Señales y EventBus) — `core/events.gd`
- **Dónde está**: Señales locales (`percentage_changed` en `Character`, `hit_landed` en `Hitbox`) y bus global `Events` (`player_ko_event`, `special_meter_changed`, `camera_shake_requested`, `time_stop_activated`).
- **Por qué se usó**: Evita el acoplamiento fuerte ("código espagueti"). Por ejemplo, cuando un personaje recibe daño, **no busca al nodo `HUD`**. Simplemente emite una señal diciendo *"mi porcentaje cambió"* y el `HUD` actualiza el texto con una animación. Si mañana quitamos el `HUD`, el personaje sigue funcionando sin romperse.

### 2.3 Patrón State (Máquina de Estados Finita / FSM) — `characters/state_machine/`
- **Dónde está**: [`StateMachine`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/state_machine.gd) y las 15 subclases de [`State`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/state.gd) (`IdleState`, `RunState`, `JumpSquatState`, `JumpState`, `FallState`, `AttackState`, `HitState`, `ShieldState`, `RollState`, `SpotDodgeState`, `AirDodgeState`, `DazeState`, `LedgeState`, `LedgeGetupState`, `DeathState`).
- **Por qué se usó**: En un juego de pelea un personaje no puede correr mientras está bloqueando o atacar mientras está aturdido (`HitState`). En vez de tener un archivo gigante lleno de `if is_jumping and not is_shielding and not is_hit:`, cada estado es **una clase pequeña e independiente** con cuatro métodos claros: `enter()`, `exit()`, `update()` y `physics_update()`.

### 2.4 Patrón Facade + Composición sobre Herencia — `characters/character.gd`
- **Dónde está**: [`Character`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/character.gd) actúa como **Fachada** coordinando componentes especializados:
  - [`CharacterController`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/character_controller.gd): Física 2D (velocidad, saltos, gravedad, *fast-fall*).
  - [`CharacterStats`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/character_stats.gd): Peso y porcentaje de daño (`%`).
  - [`AttackController`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/attack_controller.gd): Decide qué ataque sale según la dirección de la palanca.
  - [`ShieldController`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/shield_controller.gd): Vida del escudo, drenaje, *Parry* (5 frames) y rotura.
  - [`VisualController`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/visual_controller.gd): Traduce las coordenadas 2D a metros 3D y rota suavemente el modelo.
  - [`AnimationController`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/animation_controller.gd) (apoyado por `ProceduralPoseSolver`, `ProceduralMovesetBuilder` y `CombatVfxController`).
- **Por qué se usó**: Cumple el **Principio de Responsabilidad Única (SRP)**. Si hay que ajustar cómo se regenera el escudo, solo abrimos `shield_controller.gd` (~180 líneas) sin tocar las animaciones ni el movimiento.

### 2.5 Diseño Orientado a Datos (*Data-Driven Design*) — `resources/`
- **Dónde está**: [`CharacterData`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/resources/character_data.gd) -> [`MoveSet`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/resources/moveset.gd) -> [`AttackData`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/resources/attack_data.gd) -> [`HitboxData`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/combat/hitbox_data.gd).
- **Por qué se usó**: Separa **datos** de **lógica**. Para agregar un personaje nuevo basta con crear un archivo `.tres` en el Inspector de Godot asignándole su peso, velocidad, modelo `.glb` y sus ataques, sin duplicar escenas ni código.

### 2.6 Constructores Modulares de UI y Escenas 3D (*Builder Helpers*) — `ui/`
- **Dónde está**: [`UIThemeUtils`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/ui/ui_theme_utils.gd), [`SettingsPanelsBuilder`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/ui/settings_panels_builder.gd) y [`CharacterSelect3DBuilder`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/ui/character_select_3d_builder.gd).
- **Por qué se usó**: Mantiene los controladores de interfaz (`CharacterSelect` y `ControlsConfig`) enfocados en la interacción del usuario, delegando la construcción pesada de mallas 3D, cámaras de retrato (`SubViewport`), estilos visuales y audio procedural a clases auxiliares limpias.

---

## 3. Orden Recomendado para Estudiar el Código (De Cero a Experto)

Si quieres estudiar el código paso a paso sin abrumarte, léelo en este orden exacto:

1. **Base compartida (`shared/`)**:
   - Empieza por [`constants.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/shared/constants.gd) y [`utils.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/shared/utils.gd). Verás cómo `PIXEL_TO_METER = 0.01` convierte `100 px` 2D en `1 metro` 3D.
2. **Recursos de datos (`resources/`)**:
   - Lee [`character_data.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/resources/character_data.gd), [`moveset.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/resources/moveset.gd) y [`attack_data.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/resources/attack_data.gd). Son clases cortísimas de puras variables `@export`.
3. **Física y Colisiones de Combate (`physics/` y `combat/`)**:
   - Lee [`knockback_calculator.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/physics/knockback_calculator.gd) (la fórmula matemática de lanzamiento) y luego el par [`hitbox.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/combat/hitbox.gd) + [`hurtbox.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/combat/hurtbox.gd).
4. **Sistemas Globales (`core/` y `systems/`)**:
   - Revisa [`game_manager.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/game_manager.gd), [`profile_manager.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/profile_manager.gd), [`player_input.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/player_input.gd), [`input_buffer.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/systems/input_buffer.gd) e [`input_manager.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/core/input_manager.gd).
5. **El Luchador y su Máquina de Estados (`characters/`)**:
   - Lee [`character.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/character.gd) para ver cómo une todo, luego [`state_machine.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/state_machine.gd) y estados clave como [`idle_state.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/idle_state.gd), [`jumpsquat_state.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/jumpsquat_state.gd), [`attack_state.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/attack_state.gd) y [`hit_state.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/characters/state_machine/hit_state.gd).
6. **Árbitro de Partida e Interfaz (`battle/` y `ui/`)**:
   - Lee [`battle.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/battle/battle.gd) y [`battle_manager.gd`](file:///home/RodriFumo/Documentos/programacion%204/Smash-en-casa-SC-/smash-en-casa/battle/battle_manager.gd), y finalmente las pantallas de `ui/` (`hud.gd`, `character_select.gd`, `controls_config.gd`, `leaderboard.gd`).

---

## 4. Explicación Paso a Paso de Casos Reales

### Caso A: ¿Qué ocurre exactamente cuando el Jugador 1 golpea al Jugador 2?
1. **Lectura y Buffer**: En `Character._physics_process()`, el Jugador 1 consulta `InputManager.capture_player_input(1)` y guarda la pulsación de ataque en su `InputBuffer` (válida por 8 frames).
2. **Transición a `AttackState`**: `IdleState` detecta `has_attack_buffered()`, pide el recurso `AttackData` a `AttackController` y cambia la máquina de estados a `AttackState`.
3. **Fases del Ataque (60 FPS)**:
   - *Startup*: Corre la anticipación de la animación; la `Hitbox` aún está apagada.
   - *Active*: En el frame exacto configurado en `HitboxData`, `AttackState` llama a `hitbox.activate_sub_hitbox(...)` generando un `swing_id` único.
   - *Recovery*: La `Hitbox` se apaga y el atacante queda vulnerable hasta su *FAF* (*First Actionable Frame*).
4. **Colisión Física 2D**: La `Hitbox` (`Area2D`) del Jugador 1 entra en contacto con la `Hurtbox` (`Area2D`) del Jugador 2.
5. **Cálculo e Impacto**:
   - `Hitbox` anota al objetivo en su diccionario `hit_targets_by_group[swing_id]` para **no volver a golpearlo en los siguientes frames del mismo ataque**.
   - Se calcula el nuevo porcentaje con `DamageCalculator` y el vector de vuelo con `KnockbackCalculator` (considerando daño acumulado, peso del rival e inclinación de palanca *DI*).
   - Todo se empaqueta en un objeto `ImpactData` y se entrega a `Character.on_impact_received()`.
6. **Reacción del Defensor y Feedback**:
   - Si el Jugador 2 tenía el escudo activo, `ShieldController` absorbe el golpe (o activa *Parry* si llevaba `<= 5 frames` cubriéndose).
   - Si no cubría, ambos entran brevemente en *Hitlag* (pausa de impacto que da peso al golpe), el Jugador 2 pasa a `HitState` con la velocidad de *Knockback*, la cámara tiembla y el `HUD` rebota actualizando su porcentaje.

### Caso B: ¿Cómo se conectan los Controles Estilo Yuzu con la Leaderboard?
1. En `ControlsConfig`, cada uno de los 4 puertos (`Player 1`..`Player 4`) puede elegir o crear un **Perfil** (ej. `"Rodrigo"`, `"Pablo"`). `InputManager` guarda sus botones y zona muerta en `user://controls_v2.json`.
2. Al iniciar una pelea desde `CharacterSelect`, `GameManager.start_match_multi()` guarda tanto el `CharacterData` como el nombre de perfil activo de cada jugador.
3. Cuando `BattleManager` declara un ganador, llama a `GameManager.end_match(winner_id)`, quien invoca `ProfileManager.record_match_result()`.
4. `ProfileManager` suma `+1 Victoria` al perfil ganador, `+1 Derrota` a los demás perfiles participantes (ignorando el perfil genérico `"Default"` si no fue personalizado o registrándolo según corresponda), recalcula el *Win Rate %* y el personaje más jugado, y persiste todo en `user://leaderboard.json`.

---

## 5. Preguntas Frecuentes de Examen / Defensa Oral

### 1. *"¿Por qué hicieron la física en 2D si el juego se ve en 3D?"*
> Porque en un *Platform Fighter* como *Smash Bros.* toda la jugabilidad ocurre estrictamente sobre los ejes X e Y. Usar `CharacterBody2D` y `Area2D` elimina errores de colisión en el eje Z, simplifica las matemáticas de ángulos de lanzamiento y hace que las cajas de golpe (*Hitboxes*) sean 100% predecibles a 60 FPS, mientras `VisualController` proyecta esa posición exacta al mundo 3D.

### 2. *"¿Qué tendrían que tocar si hoy les pido agregar un séptimo personaje?"*
> No necesitamos crear ninguna clase nueva de personaje ni modificar `character.gd`. Solo creamos sus recursos `.tres`: un `MoveSet` con sus `AttackData`, y un `CharacterData` apuntando a su modelo `.glb`, peso y velocidades, y lo añadimos al arreglo del roster en `CharacterSelect`.

### 3. *"¿Cómo evitan que una espada activa durante 6 frames le pegue 6 veces seguidas al rival?"*
> Cada vez que comienza un ataque, `Hitbox.next_swing_id()` genera un identificador entero único para ese golpe (`swing_id`). `Hitbox` guarda un diccionario `hit_targets_by_group` con los rivales que ya recibieron daño en ese `swing_id`, ignorándolos hasta que inicie un ataque distinto (o salvo que el ataque sea explícitamente multi-golpe).

### 4. *"¿Para qué sirve la clase `InputBuffer`?"*
> Sin un buffer, si el jugador presiona *Salto* o *Ataque* 2 frames antes de terminar de aterrizar o de recuperarse de otro golpe, el juego ignoraría el botón y se sentiría tosco. `InputBuffer` recuerda las acciones durante **8 frames (~133 ms)** y las consume apenas el personaje vuelve a estar libre.

### 5. *"¿Cómo logran mecánicas especiales únicas como el Time Stop de Sakuya o la Seda de Hornet sin romper el diseño general?"*
> Mediante señales desacopladas en `Events`: cuando Sakuya activa *"El Mundo"*, emite `Events.time_stop_activated(player_id, duration)`. `BattleManager` y `TimeStopOverlay` escuchan esa señal y congelan temporalmente a los demás luchadores aplicando el filtro visual invertido, sin que Sakuya tenga referencias directas al resto de jugadores ni a la UI.
