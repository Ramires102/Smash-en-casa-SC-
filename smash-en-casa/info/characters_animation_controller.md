# Explicación de `characters/animation_controller.gd` (Articulación de Codos y Poses)

## Resumen
`AnimationController` genera dinámicamente en tiempo de ejecución pistas de animación articuladas en el `AnimationPlayer` de Godot para extremidades con codos y rodillas dobladas (`LeftUpperArm` $\rightarrow$ `LeftForearm`, `RightUpperArm` $\rightarrow$ `RightForearm`, etc.).

## Articulación de la Pose DIO (Idle)
- En el estado `Idle`, los brazos superiores (`UpperArm`) se orientan hacia fuera y hacia atrás, mientras que los antebrazos (`Forearm`) se flexionan a **100° en el codo** hacia la cintura.
- Al atacar (`Attack`), el antebrazo se extiende rápidamente en el codo para dar el puñetazo antes de recuperar la flexión.

## Comunicación e Interacciones
- **Gobernado por**: `StateMachine.gd` (reproduce la animación correspondiente al cambiar de estado).
