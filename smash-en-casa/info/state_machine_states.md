# Explicación de los Estados de la FSM (`characters/state_machine/`)

## Resumen
Cada estado individual hereda de `State` ([state.gd](file:///c:/Users/IK/Documents/programacion%204%20juego/smash-en-casa/characters/state_machine/state.gd)) y encapsula una conducta específica.

---

## 1. `state.gd` (Clase Base)
Define la interfaz virtual para todos los estados: `enter()`, `exit()`, `update()`, `physics_update()`.

---

## 2. `idle_state.gd`
- Reproduce la animación `"Idle"`. Transiciona a `"Run"`, `"Jump"`, `"Fall"`, `"Attack"` o `"Shield"`.

---

## 3. `run_state.gd`
- Aplica velocidad horizontal (`velocity.x = input_x * move_speed`) y orienta la mirada del personaje. Transiciona a `"Idle"`, `"Jump"`, `"Fall"`, `"Attack"` o `"Shield"`.

---

## 4. `jump_state.gd`
- Aplica impulso vertical instantáneo (`velocity.y = jump_velocity`). Al llegar al ápex (`velocity.y <= 0`) transiciona a `"Fall"`.

---

## 5. `fall_state.gd`
- Al tocar el suelo (`is_on_floor()`) regresa a `"Idle"` o `"Run"`.

---

## 6. `attack_state.gd`
- Obtiene el `AttackData` de `AttackController`, activa la `Hitbox` ofensiva e inicia el ataque. Al terminar la ventana activa/recuperación regresa a `"Idle"` o `"Fall"`.

---

## 7. `hit_state.gd`
- Recibe el vector de retroceso (`knockback`), aplica la velocidad de lanzamiento y el tiempo de aturdimiento (`stun_timer`) proporcional al daño recibido.

---

## 8. `death_state.gd`
- Oculta el nodo y congela el movimiento durante el respawn.

---

## 9. `shield_state.gd`
- Activa la burbuja semi-transparente de escudo 3D (`ShieldMesh`). Se mantiene mientras se mantenga presionada la tecla de escudo (**L** para P1, **V** para P2). Al soltarla regresa a `"Idle"` o `"Fall"`.
