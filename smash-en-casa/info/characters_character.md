# Explicación de `characters/character.gd`

## Resumen
Controlador principal de personaje 2.5D (`CharacterBody3D`). Gestiona la carga de `CharacterData`, entradas, estado de porcentaje %, colisión de Hitbox/Hurtbox, física de escudos de *Super Smash Bros. Ultimate*, física de empuje terrestre (Pushboxes / Dash Cross-Through / Roll Cross-Through), física de desvío de superficies de escenario (ECB Head Sliding), recepción de golpes, física de movimiento según fórmulas de Smash Ultimate, efectos de desorientación (*Daze Stars*) y el efecto pasivo **JoJo Menacing Aura** (`ゴゴゴゴ`) para John Placeholder en estado `IdleState`.

## Explicación Línea por Línea
```gdscript
class_name Character
extends CharacterBody3D

func _ready() -> void:
	collision_layer = 2 # Capa de Jugadores
	collision_mask = 1  # Colisiona solo con el Escenario / Entorno (Capa 1)
```
- Configura las máscaras de colisión del motor 3D de Godot para que las mallas de los jugadores colisionen con el escenario/suelos (Capa 1) pero no bloqueen físicamente a otros jugadores en `move_and_slide()`. toda la física entre personajes es gestionada por `_handle_ecb_and_pushbox_collisions()`.

```gdscript
func update_menacing_aura(delta: float) -> void:
```
- Instancia y actualiza los sprites 3D (`Sprite3D`) con la textura `jojo_menacing.png` cuando **John Placeholder** permanece en reposo (`IdleState`). Aplica animación de flotación sinusoidal y pulso en tono morado anime alrededor del personaje.

```gdscript
func _handle_ecb_and_pushbox_collisions(delta: float) -> void:
```
- **Pushbox Ground Collisions (Walking Pushback vs Cross-Through)**:
  - En estados terrestres de caminata o reposo (`WalkState`, `IdleState`, `SquatState`, `RunBrakeState`, `PivotState`, etc.), la colisión de Pushbox es **sólida**, empujando al rival y restringiendo las posiciones (`global_position.x`) para impedir atravesarse.
  - Únicamente en estados de impulso o evasión (`DashState`, `RunState`, `RollState`), se habilita el *Cross-Through* permitiendo pasar a la espalda del oponente.
- **ECB Head Sliding**: Si dos personajes se solapan verticalmente (un jugador salta o cae sobre la cabeza del otro), el motor aplica una fuerza de repulsión lateral instantánea (`push_side * 14.0 * delta`) impidiendo matemáticamente pararse sobre la cabeza del rival.

## Comunicación e Interacciones
- **Comunica con**: `CharacterController`, `InputManager`, `KnockbackCalculator`, `AudioManager`, `StateMachine`, `Hitbox`, `Hurtbox`, `HUD`, `Events`.
