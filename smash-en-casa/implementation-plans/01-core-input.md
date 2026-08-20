# Plan 01 - Core + Input

## Objetivo

Garantizar base estable de ejecucion: estado global de partida, audio e input abstraido por jugador.

## Alcance

- Incluye:
- GameManager con seleccion P1/P2 y reglas base de partida.
- InputManager con acciones por jugador (move/jump/attack/special/shield).
- AudioManager basico para BGM/SFX esenciales.

- No incluye:
- Logica de combate dentro de InputManager.
- Managers globales nuevos fuera de GameManager/AudioManager/InputManager.

## Dependencias

- project.godot con autoloads minimos.
- Escenas de menu y character select enlazadas.

## Tareas

- [ ] Revisar y normalizar acciones de input p1/p2.
- [ ] Definir estructura PlayerInput consumible por Character.
- [ ] Conectar CharacterSelect -> GameManager (guardar CharacterData de P1/P2).
- [ ] Verificar transicion de escena hacia battle con datos persistidos.

## Entregables

- Flujo menu -> select -> battle sin perdida de seleccion.
- Input consistente en teclado/joystick para ambos jugadores.

## Criterio de terminado

- Character no lee teclas directas para acciones de gameplay.
- Todo input llega como intencion (move/jump/attack/special/shield).
