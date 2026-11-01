# ==============================================================================
# ProceduralMovesetBuilder — Definición de MoveSets Procedurales (Gogeta y Sans)
# ==============================================================================
# Construye e inyecta los movimientos completos de Gogeta SSJ (combos Jab 1-2-3,
# Rekka 1-2-3, Divekick meteor, Up-B con seguimiento y Down-B cambia-lado) y
# Sans directamente en su MoveSet al inicializar el personaje.
# ==============================================================================
class_name ProceduralMovesetBuilder
extends RefCounted

static func inject_gogeta_moveset(character: Node) -> void:
	var moveset: MoveSet = _get_character_moveset(character)
	if moveset == null:
		return

	var jab3 := _make_atk("gogeta_jab_3", "Jab 3: Doble Mazo y Voltereta (3/3)", "AttackNeutral3", "jab_axe_vault", "slash_gold", 11.5, 8.2, 0.15, 42.0, 8, 7, 16, Vector2(1.05, 1.05), 0.78, Vector2(5.4, 5.8), 2)
	jab3.vault_behind_on_hit = true
	var jab2 := _make_atk("gogeta_jab_2", "Jab 2: Golpe al Estómago (2/3)", "AttackNeutral2", "jab_gut_upper", "slash_gold", 6.5, 2.8, 0.03, 68.0, 5, 7, 11, Vector2(0.98, 1.32), 0.72, Vector2(3.2, 0.0), 3)
	jab2.combo_next = jab3
	var jab1 := _make_atk("gogeta_jab_1", "Jab 1: Dos Golpes Rápidos (1/3)", "AttackNeutral", "jab_double_strike", "slash_gold", 3.5, 2.2, 0.02, 25.0, 3, 9, 10, Vector2(0.98, 1.18), 0.68, Vector2(2.4, 0.0), 2)
	jab1.second_hit_frame = 8
	jab1.combo_next = jab2

	var side_tilt := _make_atk("gogeta_side_tilt", "Fusion Spin Kick", "AttackSide", "side_roundhouse", "slash_gold", 11.0, 7.2, 0.14, 32.0, 8, 6, 14, Vector2(1.2, 1.15), 0.72, Vector2(4.5, 0.0), 6)
	var up_tilt := _make_atk("gogeta_up_tilt", "Rising Dragon Upper", "AttackUp", "uppercut_rising", "slash_gold", 9.5, 6.8, 0.13, 84.0, 6, 7, 12, Vector2(0.45, 1.95), 0.75, Vector2.ZERO, 0)
	var down_tilt := _make_atk("gogeta_down_tilt", "Patada Voladora en Espiral", "AttackDown", "spiral_kick_low", "spiral_vortex", 9.5, 6.4, 0.12, 62.0, 6, 11, 12, Vector2(1.15, 0.62), 0.76, Vector2(8.8, 1.4), 4)

	var nair := _make_atk("gogeta_nair", "Aura Vortex Spin", "NeutralAir", "nair_spin", "slash_gold", 9.0, 5.8, 0.11, 45.0, 5, 10, 9, Vector2(0.0, 1.15), 1.05, Vector2.ZERO, 0, true)
	var fair := _make_atk("gogeta_fair", "Forward Air: Puño Descendente", "ForwardAir", "fair_downward_punch", "downward_punch_arc", 12.0, 7.8, 0.15, 295.0, 7, 6, 12, Vector2(1.18, 0.88), 0.84, Vector2(2.2, 0.6), 2, true)
	var bair := _make_atk("gogeta_bair", "Reverse Heel Thrust", "BackAir", "bair_backkick", "slash_gold", 14.0, 8.2, 0.17, 148.0, 9, 5, 14, Vector2(-1.15, 1.15), 0.74, Vector2.ZERO, 0, true)
	var uair := _make_atk("gogeta_uair", "Somersault Flash Kick", "UpAir", "uair_flipkick", "slash_gold", 11.5, 7.0, 0.14, 88.0, 7, 7, 11, Vector2(0.15, 2.1), 0.80, Vector2.ZERO, 0, true)
	var dair := _make_atk("gogeta_dair", "Down Air: Meteor Divekick", "DownAir", "divekick_down_air", "ki_divekick_trail", 13.5, 8.4, 0.16, 295.0, 7, 24, 11, Vector2(0.96, 0.18), 0.95, Vector2.ZERO, 0, true)
	dair.is_divekick = true
	dair.landing_lag_frames = 9
	dair.sliding_knockdown = true

	var neutral_sp := _make_atk("gogeta_neutral_special", "Big Bang Kamehameha", "SpecialNeutral", "beam_charge_thrust", "ki_beam", 16.5, 9.0, 0.18, 30.0, 12, 10, 16, Vector2(1.95, 1.25), 1.15, Vector2.ZERO, 0)
	var rekka3 := _make_atk("gogeta_side_special_3", "Rekka 3: Patada de Hacha (3/3)", "SpecialSide3", "rekka_axe_kick", "", 13.5, 8.8, 0.16, 285.0, 7, 7, 15, Vector2(1.08, 1.15), 0.92, Vector2(2.2, -8.5), 7)
	rekka3.snap_in_front_of_opponent = true
	var rekka2 := _make_atk("gogeta_side_special_2", "Rekka 2: Rodillazo en Salto (2/3)", "SpecialSide2", "rekka_knee_rising", "", 8.5, 5.2, 0.06, 76.0, 5, 9, 13, Vector2(0.95, 1.48), 0.84, Vector2(4.8, 11.2), 2)
	rekka2.combo_next = rekka3
	var rekka1 := _make_atk("gogeta_side_special_1", "Rekka 1: Rodillazo Volador (1/3)", "SpecialSide", "rekka_knee_dash", "", 7.5, 3.6, 0.04, 38.0, 6, 9, 13, Vector2(1.18, 1.12), 0.86, Vector2(11.4, 1.2), 2)
	rekka1.combo_next = rekka2

	var up_sp_punch := _make_atk("gogeta_up_special_punch", "Up Special: Piña Explosiva (Remate)", "SpecialUp2", "up_special_followup_punch", "slash_gold", 10.5, 9.2, 0.17, 36.0, 5, 6, 14, Vector2(1.05, 1.25), 0.96, Vector2(2.6, 2.4), 1)
	var up_sp := _make_atk("gogeta_up_special", "Up Special: Voltereta en Diagonal", "SpecialUp", "up_somersault_vortex", "somersault_vortex_blue", 5.5, 3.4, 0.03, 68.0, 5, 12, 13, Vector2(0.35, 1.12), 1.12, Vector2(6.4, 13.5), 3)
	up_sp.second_hit_frame = 11
	up_sp.drag_defender_on_hit = true
	up_sp.auto_followup_on_hit = up_sp_punch

	var down_sp_kick := _make_atk("gogeta_down_special_kick", "Down Special (2/2): Giro y Patada", "SpecialDown2", "down_special_turn_kick", "", 11.5, 9.8, 0.19, 28.0, 13, 16, 18, Vector2(1.25, 1.22), 1.12, Vector2(2.4, 2.2), 4)
	down_sp_kick.flip_facing_on_start = true
	var down_sp_elbow := _make_atk("gogeta_down_special", "Down Special (1/2): Codazo Cambia-Lado", "SpecialDown", "down_special_elbow_lift", "", 6.0, 3.2, 0.02, 115.0, 9, 18, 12, Vector2(1.08, 1.15), 1.05, Vector2(7.8, 0.0), 2)
	down_sp_elbow.toss_behind_on_hit = true
	down_sp_elbow.auto_followup_on_hit = down_sp_kick
	down_sp_elbow.auto_followup_always = true
	down_sp_elbow.combo_next = down_sp_kick

	_assign_slots(character, moveset, jab1, side_tilt, up_tilt, down_tilt, nair, fair, bair, uair, dair, neutral_sp, rekka1, up_sp, down_sp_elbow)

static func inject_sans_moveset(character: Node) -> void:
	var moveset: MoveSet = _get_character_moveset(character)
	if moveset == null:
		return

	var jab := _make_atk("sans_jab", "Bone Pop Jab", "AttackNeutral", "jab_combo", "bone_spike", 5.5, 4.2, 0.08, 40.0, 4, 6, 9, Vector2(0.95, 1.0), 0.62, Vector2.ZERO, 0)
	var side_tilt := _make_atk("sans_side_tilt", "Trombone Slide Riff", "AttackSide", "side_roundhouse", "trombone_wave", 10.5, 6.8, 0.13, 34.0, 7, 7, 12, Vector2(1.25, 1.05), 0.78, Vector2.ZERO, 0)
	var up_tilt := _make_atk("sans_up_tilt", "Ceiling Bone Pillar", "AttackUp", "uppercut_rising", "bone_spike", 9.0, 6.5, 0.13, 86.0, 6, 7, 11, Vector2(0.35, 1.85), 0.76, Vector2.ZERO, 0)
	var down_tilt := _make_atk("sans_down_tilt", "Floor Bone Trap", "AttackDown", "low_sweep", "bone_spike", 8.5, 5.8, 0.12, 76.0, 5, 6, 11, Vector2(1.15, 0.4), 0.70, Vector2.ZERO, 0)

	var nair := _make_atk("sans_nair", "Spinning Bone Orbit", "NeutralAir", "nair_spin", "slash_blue", 8.5, 5.6, 0.11, 45.0, 5, 10, 9, Vector2(0.0, 0.95), 1.05, Vector2.ZERO, 0, true)
	var fair := _make_atk("sans_fair", "Blue Bone Swing", "ForwardAir", "fair_cleave", "slash_blue", 11.5, 7.2, 0.14, 36.0, 7, 6, 12, Vector2(1.15, 1.0), 0.76, Vector2.ZERO, 0, true)
	var bair := _make_atk("sans_bair", "Shortcut Back Thrust", "BackAir", "bair_backkick", "slash_blue", 13.0, 8.0, 0.16, 145.0, 8, 5, 13, Vector2(-1.1, 0.98), 0.74, Vector2.ZERO, 0, true)
	var uair := _make_atk("sans_uair", "Upward Bone Arc", "UpAir", "uair_flipkick", "bone_spike", 10.5, 6.8, 0.14, 88.0, 6, 7, 11, Vector2(0.1, 1.9), 0.78, Vector2.ZERO, 0, true)
	var dair := _make_atk("sans_dair", "Gravity Dunk Spike", "DownAir", "dair_meteor", "gravity_slam", 13.0, 7.8, 0.16, 270.0, 10, 6, 15, Vector2(0.15, 0.15), 0.78, Vector2.ZERO, 0, true)

	var neutral_sp := _make_atk("sans_neutral_special", "Gaster Blaster Beam", "SpecialNeutral", "beam_charge_thrust", "gaster_beam", 17.5, 9.2, 0.19, 28.0, 11, 10, 15, Vector2(2.05, 1.1), 1.18, Vector2.ZERO, 0)
	var side_sp := _make_atk("sans_side_special", "Trombone Shockwave Dash", "SpecialSide", "lunge_burst", "trombone_wave", 13.5, 8.2, 0.16, 40.0, 8, 8, 14, Vector2(1.4, 1.0), 0.92, Vector2(9.8, 1.5), 7)
	var up_sp := _make_atk("sans_up_special", "Shortcut Warp Recovery", "SpecialUp", "warp_ascend", "teleport_burst", 10.0, 6.8, 0.13, 80.0, 5, 9, 13, Vector2(0.0, 1.35), 0.92, Vector2(2.5, 14.5), 4)
	var down_sp := _make_atk("sans_down_special", "Blue Soul Telekinesis Slam", "SpecialDown", "counter_stance", "gravity_slam", 14.5, 8.6, 0.17, 65.0, 7, 9, 15, Vector2(0.0, 0.95), 1.32, Vector2.ZERO, 0)

	_assign_slots(character, moveset, jab, side_tilt, up_tilt, down_tilt, nair, fair, bair, uair, dair, neutral_sp, side_sp, up_sp, down_sp)

static func _get_character_moveset(character: Node) -> MoveSet:
	if character == null or not ("character_data" in character) or character.character_data == null:
		return null
	return character.character_data.moveset

static func _assign_slots(
	character: Node,
	moveset: MoveSet,
	jab: AttackData, s_tilt: AttackData, u_tilt: AttackData, d_tilt: AttackData,
	nair: AttackData, fair: AttackData, bair: AttackData, uair: AttackData, dair: AttackData,
	n_sp: AttackData, s_sp: AttackData, u_sp: AttackData, d_sp: AttackData
) -> void:
	moveset.neutral_attack = jab
	moveset.side_tilt = s_tilt
	moveset.forward_smash = s_tilt
	moveset.up_tilt = u_tilt
	moveset.up_smash = u_tilt
	moveset.down_tilt = d_tilt
	moveset.down_smash = d_tilt
	moveset.neutral_air = nair
	moveset.forward_air = fair
	moveset.back_air = bair
	moveset.up_air = uair
	moveset.down_air = dair
	moveset.special_neutral = n_sp
	moveset.special_side = s_sp
	moveset.special_up = u_sp
	moveset.special_down = d_sp

	if character and "attack_controller" in character and character.attack_controller:
		character.attack_controller.current_moveset = moveset

static func _make_atk(
	id_str: String, disp: String, anim: String, style: String, vfx: String,
	dmg: float, bkb: float, kbg: float, ang: float,
	s_f: int, a_f: int, r_f: int,
	hb_off: Vector2, hb_rad: float,
	imp: Vector2, imp_frame: int, aerial: bool = false
) -> AttackData:
	var a := AttackData.new()
	a.id = id_str
	a.attack_name = disp
	a.display_name = disp
	a.animation_name = anim
	a.pose_style = style
	a.vfx_type = vfx
	a.damage = dmg
	a.base_knockback = bkb
	a.knockback_scaling = kbg
	a.angle_degrees = ang
	a.startup_frames = s_f
	a.active_frames = a_f
	a.recovery_frames = r_f
	a.hitbox_offset = hb_off
	a.hitbox_radius = hb_rad
	a.hitbox_size = Vector2(hb_rad * 2.0, hb_rad * 2.0)
	a.self_impulse = imp
	a.self_impulse_frame = imp_frame
	a.is_aerial = aerial
	a.divekick_speed = Vector2(13.5 * Constants.UNIT_SIZE, 20.0 * Constants.UNIT_SIZE)
	return a

