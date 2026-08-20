Sí. Ahora que ya definimos que quieren **Godot 4 + 2.5D real con nodos 3D + arquitectura data-driven + FSM**, yo cerraría la arquitectura de una vez y dejaría de agregar sistemas por agregar. El objetivo tiene que ser: **limpia, defendible ante el profesor y suficientemente simple para terminarla en dos meses**.

## 1. Arquitectura general
La dividiría en **7 módulos**:

```
smash-en-casa/
│
├── core/
├── characters/
├── resources/
├── combat/
├── battle/
├── systems/
├── ui/
│
├── shared/
├── assets/
└── scenes/
```
La idea conceptual:

```
                    ┌──────────────────┐
                    │   GameManager    │
                    └────────┬─────────┘
                             │
             ┌───────────────┼────────────────┐
             │               │                │
             ▼               ▼                ▼
        Character        BattleManager       UI
             │               │
       ┌─────┴─────┐         │
       ▼           ▼         ▼
    StateMachine  Combat    Stage
                     │
               ┌─────┴─────┐
               ▼           ▼
            Hitbox       Hurtbox
```
Y los datos están separados de todo eso:

```
CharacterData
      │
      ▼
   MoveSet
      │
      ▼
 AttackData
```

---

# 2. Estructura definitiva
Yo dejaría el proyecto así:

```
smash-en-casa/
│
├── core/
│   ├── game_manager.gd
│   ├── audio_manager.gd
│   └── input_manager.gd
│
├── characters/
│   ├── character.tscn
│   ├── character.gd
│   ├── animation_controller.gd
│   │
│   └── state_machine/
│       ├── state_machine.gd
│       ├── state.gd
│       ├── idle_state.gd
│       ├── run_state.gd
│       ├── jump_state.gd
│       ├── fall_state.gd
│       ├── attack_state.gd
│       ├── hit_state.gd
│       └── death_state.gd
│
├── resources/
│   ├── character_data.gd
│   ├── moveset.gd
│   ├── attack_data.gd
│   │
│   └── instances/
│       ├── miyabi_data.tres
│       ├── gogeta_data.tres
│       └── sakuya_data.tres
│
├── combat/
│   ├── hitbox.gd
│   ├── hurtbox.gd
│   └── damage_calculator.gd
│
├── physics/
│   └── knockback_calculator.gd
│
├── battle/
│   ├── battle.tscn
│   ├── battle.gd
│   ├── battle_manager.gd
│   ├── spawn_manager.gd
│   ├── stage.tscn
│   └── stage.gd
│
├── systems/
│   ├── camera_controller.gd
│   ├── input_buffer.gd
│   └── screen_shake.gd
│
├── ui/
│   ├── main_menu.tscn
│   ├── main_menu.gd
│   ├── character_select.tscn
│   ├── character_select.gd
│   ├── hud.tscn
│   ├── hud.gd
│   ├── pause.tscn
│   ├── pause.gd
│   ├── victory.tscn
│   ├── victory.gd
│   ├── gacha.tscn
│   └── gacha.gd
│
├── shared/
│   ├── constants.gd
│   ├── utils.gd
│   └── helpers.gd
│
├── assets/
│   ├── characters/
│   │   ├── miyabi/
│   │   ├── gogeta/
│   │   └── sakuya/
│   │
│   ├── stages/
│   ├── audio/
│   ├── vfx/
│   └── ui/
│
└── scenes/
    └── main.tscn
```
Hay una diferencia importante con lo que tenían antes:

**`resources/` contiene datos. `assets/` contiene archivos artísticos. `characters/` contiene comportamiento.**

No mezclamos las tres cosas.

---

# 3. ¿Qué es realmente un personaje?
Esta es probablemente la decisión arquitectónica más importante.

Un personaje **no es `Miyabi.gd`**.

Un personaje es:

```
CharacterBody3D
       +
CharacterData
       +
Assets
```
Por ejemplo:

```
CharacterBody3D
│
├── Model
├── Skeleton3D
├── AnimationPlayer / AnimationTree
├── CollisionShape3D
├── Hurtbox
├── Hitboxes
└── StateMachine
```
Y aparte:

```
MiyabiData.tres
│
├── Stats
├── MoveSet
├── Model
├── Icon
└── Animation configuration
```
Cuando el jugador selecciona Miyabi:

```
CharacterSelect
      │
      │ selecciona
      ▼
MiyabiData.tres
      │
      ▼
Character
      │
      ▼
configure(data)
```
El mismo `Character` sirve para Gogeta y Sakuya.

---

# 4. CharacterData
Yo lo haría aproximadamente así conceptualmente:

```
CharacterData
│
├── character_name
├── display_name
├── weight
├── movement_speed
├── acceleration
├── jump_force
├── air_speed
├── icon
├── model_scene
└── moveset
```
Y **no pondría toda la lógica ahí**.

Es solamente configuración.

Por eso es un `Resource`.

---

# 5. MoveSet
Después:

```
MoveSet
│
├── neutral
├── side_tilt
├── up_tilt
├── down_tilt
│
├── neutral_air
├── forward_air
├── back_air
├── up_air
├── down_air
│
├── neutral_special
├── side_special
├── up_special
└── down_special
```
Cada entrada apunta a un:

```
AttackData
```
Así:

```
MiyabiData
     │
     └── MiyabiMoveSet
              │
              ├── Jab
              ├── SideTilt
              ├── UpTilt
              └── ...
```

---

# 6. AttackData
Este recurso representa **qué es un ataque**, no ejecuta el ataque.

Por ejemplo:

```
AttackData
│
├── damage
├── base_knockback
├── knockback_growth
├── angle
│
├── startup_frames
├── active_frames
├── recovery_frames
│
├── animation
├── hitbox_configuration
└── vfx
```
Entonces:

```
AttackData
     │
     ▼
AttackState
     │
     ├── reproduce animación
     ├── activa hitbox
     ├── espera frames
     └── termina ataque
```
Esto es importante:

**AttackData = datos.**

**AttackState = comportamiento.**

No los mezcles.

---

# 7. FSM
La FSM controla **qué está haciendo actualmente el personaje**.

```
                    ┌───────┐
                    │ Idle  │
                    └───┬───┘
                        │
               movimiento
                        ▼
                    ┌───────┐
                    │  Run  │
                    └───────┘

Idle ── salto ──► Jump ──► Fall

Idle ── ataque ─► Attack

cualquier estado ── golpe ─► Hit

Hit ── knockback ─► Fall

vidas = 0 ────────► Death
```
Pero hay algo importante:

**la FSM no debería calcular el daño.**

La FSM dice:

> Estoy en `AttackState`.
Combat dice:

> Esa hitbox golpeó a esta hurtbox.
Battle dice:

> Este jugador perdió una vida.
Tres responsabilidades distintas.

---

# 8. Combat
Acá está el sistema de pelea.

```
Hitbox
    │
    │ detecta
    ▼
Hurtbox
    │
    ▼
DamageCalculator
    │
    ├── aumenta %
    │
    ▼
KnockbackCalculator
    │
    ▼
Character.velocity
```
Eso significa que el flujo de un golpe sería:

```
Jugador A
   │
   ▼
AttackState
   │
   ▼
Hitbox activa
   │
   ▼
Jugador B Hurtbox
   │
   ▼
DamageCalculator
   │
   ▼
+ daño %
   │
   ▼
KnockbackCalculator
   │
   ▼
Jugador B recibe velocidad
```
Muy limpio.

---

# 9. BattleManager
Este es **el árbitro**.

No debería estar dentro del personaje.

Controla:

```
BattleManager
│
├── P1 stocks
├── P2 stocks
├── timer
├── KOs
├── respawns
└── winner
```
Ejemplo:

```
Player cae fuera del Stage
          │
          ▼
       Stage
          │
          ▼
   BattleManager
          │
       -1 stock
          │
    ┌─────┴─────┐
    │           │
stocks > 0    stocks = 0
    │           │
    ▼           ▼
 Respawn     Game Over
```
El personaje no necesita saber quién ganó.

---

# 10. Stage
El escenario también debe ser independiente.

```
Stage
│
├── Platforms
├── StaticBody3D
├── CollisionShape3D
│
├── SpawnPoints
│
└── BlastZones
    ├── Top
    ├── Bottom
    ├── Left
    └── Right
```
El Stage define **el espacio donde ocurre la batalla**.

BattleManager define **las reglas de la batalla**.

---

# 11. Cámara
La cámara no debería depender directamente de Player1.

Debe recibir:

```
Player1 position
Player2 position
```
y calcular:

```
center = (P1 + P2) / 2
distance = P1.distance_to(P2)
```
Después:

```
Camera
    │
    ├── posición
    └── zoom / FOV
```
Así funciona independientemente de qué personajes estén peleando.

---

# 12. Input
Acá también hay que evitar una trampa.

No hagan:

```
if Input.is_key_pressed(KEY_A):
    player.move_left()
```
dentro de `Character.gd`.

El input debería convertirse en una abstracción.

```
InputManager
      │
      ▼
PlayerInput
      │
      ├── move
      ├── jump
      ├── attack
      └── special
```
Entonces el personaje recibe una intención:

```
"quiero moverme a la izquierda"
```
y no necesita saber si vino de:

- teclado,
- joystick,
- otro dispositivo.

---

# 13. Input Buffer
El `InputBuffer` debería estar entre Input y el personaje.

```
InputManager
      │
      ▼
InputBuffer
      │
      ▼
Character
```
Ejemplo:

```
Frame 100 → Attack
Frame 101 → Jump
Frame 102 → Attack
```
El buffer conserva entradas durante unos frames para que el juego sea más tolerante.

Eso les va a ayudar muchísimo con la sensación del combate.

---

# 14. Signals
Acá es donde realmente desacoplamos.

Por ejemplo:

```
Hurtbox
   │
   └── hit_received
             │
             ▼
       DamageCalculator
```
Y:

```
Character
   │
   └── percentage_changed
             │
             ▼
            HUD
```
Mientras:

```
Character
   │
   └── fell_out_of_bounds
             │
             ▼
       BattleManager
```
El HUD **no busca al Character y le pregunta constantemente cuánto daño tiene**.

El personaje avisa:

> "Mi porcentaje cambió."
Y el HUD responde.

---

# 15. Autoloads
No conviertan todo en singleton.

Solo pondría:

```
GameManager
AudioManager
InputManager
```
como Autoload.

Y quizá un `EventBus` si realmente lo necesitan.

No:

```
BattleManager = Autoload
CharacterManager = Autoload
CombatManager = Autoload
CameraManager = Autoload
StageManager = Autoload
...
```
Eso terminaría creando un sistema global completamente acoplado.

---

# 16. El flujo completo
Ahora viene lo importante.

## Menú

```
main.tscn
   │
   ▼
MainMenu
   │
   ▼
CharacterSelect
```

---

## Selección

```
CharacterSelect
      │
      ├── P1 → MiyabiData
      └── P2 → GogetaData
             │
             ▼
         GameManager
```
GameManager conserva esas referencias mientras se cambia de escena.

---

## Batalla

```
Battle.tscn
│
├── BattleManager
├── Stage
├── SpawnManager
├── CameraController
├── Player1
├── Player2
└── HUD
```
Los jugadores reciben:

```
P1 → MiyabiData
P2 → GogetaData
```

---

## Golpe

```
P1 AttackState
      ↓
Hitbox
      ↓
P2 Hurtbox
      ↓
DamageCalculator
      ↓
P2 percentage += damage
      ↓
KnockbackCalculator
      ↓
P2 velocity = knockback
      ↓
P2 HitState
      ↓
HUD actualiza %
```

---

## KO

```
P2
 ↓
BlastZone
 ↓
BattleManager
 ↓
P2 stocks -= 1
 ↓
¿stocks > 0?
 ├── Sí → SpawnManager
 └── No → Victory
```

---

# 17. ¿Y el Gacha?
No lo metería dentro de `core`.

Cuando llegue el momento, haría:

```
gacha/
├── gacha_manager.gd
├── gacha_data.gd
└── rewards/
```
Pero **no lo implementaría ahora**.

Primero:

> combate → personajes → escenario → victoria.
Después:

> gacha.
Si hacen el gacha antes de tener un combate funcional, están optimizando la parte equivocada del proyecto.

---

# 18. Assets
Esta separación también es importante.

```
assets/
├── characters/
│   ├── miyabi/
│   │   ├── model/
│   │   ├── textures/
│   │   ├── animations/
│   │   ├── vfx/
│   │   └── audio/
│   │
│   ├── gogeta/
│   └── sakuya/
│
├── stages/
├── audio/
├── vfx/
└── ui/
```
**No metan `.gltf`, `.dds`, sonidos, etc. dentro de `resources/`.**

`resources/` = definición lógica.

`assets/` = contenido.

---

# 19. Cómo deberían trabajar los dos
Esto es muy importante porque son dos personas.

Yo dividiría el trabajo **por subsistemas**, no "vos hacé a Miyabi y yo Gogeta".

### Vos
Como tenés más afinidad con arquitectura/backend/RE:

```
Core
Resources
FSM
Combat
Physics
Battle
Input
```

### Tu compañero

```
Character models
Animations
VFX
Stage
UI
Character Select
```
Y ambos integran.

Eso evita que uno termine esperando al otro.

---

# 20. Orden real de desarrollo
Y acá haría un cambio respecto a su plan original.

**No desarrollen todos los archivos de la arquitectura antes de tener un personaje.**

Construyan verticalmente.

### Fase 1 — Prototipo

```
CharacterBody3D
      +
movimiento
      +
salto
      +
Stage
      +
Camera
```
Hasta poder correr y saltar.

---

### Fase 2 — Primer golpe

```
Hitbox
+
Hurtbox
+
Damage
+
Knockback
```
Ahora dos cubos pueden pegarse.

**Si esto funciona, ya tienen el corazón del juego.**

---

### Fase 3 — FSM
Meter:

```
Idle
Run
Jump
Fall
Attack
Hit
Death
```

---

### Fase 4 — Data Driven
Reemplazan las configuraciones hardcodeadas:

```
if character == "Miyabi"
```
por:

```
CharacterData
```

---

### Fase 5 — Primer personaje real
Ahora sí:

```
Miyabi
```
con modelo + animaciones.

---

### Fase 6 — Segundo y tercero
Ahí el sistema debería permitir que simplemente hagan:

```
GogetaData.tres
SakuyaData.tres
```
y agreguen sus assets.

---

### Fase 7 — UI

```
Character Select
HUD
Victory
Pause
```

---

### Fase 8 — Gacha
Último.

---

# 21. Y el criterio más importante
Yo pondría una regla para ustedes:

> **Si una abstracción no resuelve un problema actual, no la agregamos.**
Por ejemplo, no necesitan ahora:

- ReplaySystem ❌
- NetworkManager ❌
- ComboManager ❌
- ParticleManager ❌
- SaveManager complejo ❌
- EventBus gigantesco ❌
En cambio:

- `CharacterData` ✅
- `MoveSet` ✅
- `AttackData` ✅
- FSM ✅
- Hitbox/Hurtbox ✅
- `BattleManager` ✅
- `KnockbackCalculator` ✅
- `InputBuffer` ✅
sí resuelven problemas reales del juego.

---

## En una frase, la arquitectura
Si el profesor les pregunta **"¿cómo está diseñado el juego?"**, conceptualmente deberían poder dibujar esto:

```
                 ┌───────────────┐
                 │  GameManager  │
                 └───────┬───────┘
                         │
                selección/configuración
                         │
                         ▼
                  ┌─────────────┐
                  │   Battle    │
                  └──────┬──────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
      Character       BattleManager    Stage
          │
     ┌────┴─────┐
     ▼          ▼
   FSM       Animation
     │
     ▼
   Combat
     │
 ┌───┴────┐
 ▼        ▼
Hitbox  Hurtbox
     │
     ▼
 Damage + Knockback

             DATA
              │
       ┌──────┴──────┐
       ▼             ▼
 CharacterData    AttackData
       │
    MoveSet
```
Y eso es una arquitectura **coherente, escalable y, sobre todo, implementable en dos meses**.

La clave es que **`CharacterData` representa qué es un personaje, `Character` representa una instancia viva de ese personaje, `AttackData` representa qué es un ataque, la FSM decide qué está haciendo el personaje, Combat resuelve las interacciones físicas y `BattleManager` decide qué significa eso para la partida**. Esa separación es el núcleo de todo el proyecto.
