class_name TesseractDisplay
extends Control

# ── Inner classes tipadas para rendering ──────────────────────
class Particle:
	var angle: float
	var dist: float
	var speed: float
	var size: float
	var alpha: float

	func _init(a: float, d: float, s: float, sz: float, al: float) -> void:
		angle = a; dist = d; speed = s; size = sz; alpha = al

class NodeTarget:
	var pos: Vector2
	var radius: float = 26.0
	var hit: bool = false

	func _init(p: Vector2) -> void:
		pos = p

class ShieldBullet:
	var pos: Vector2
	var dir: Vector2
	var speed: float = 220.0
	var spawn_delay: float = 0.0
	var active: bool = false
	var blocked: bool = false
	var missed: bool = false

	func _init(start_p: Vector2, target_p: Vector2, delay: float, spd: float) -> void:
		pos = start_p
		dir = (target_p - start_p).normalized()
		spawn_delay = delay
		speed = spd

# ── Configuración visual ──────────────────────────────────────
var target_outer_color: Color   = Color(0.55, 0.55, 0.55)
var target_inner_color: Color   = Color(0.80, 0.80, 0.80)
var current_outer_color: Color  = Color(0.55, 0.55, 0.55)
var current_inner_color: Color  = Color(0.80, 0.80, 0.80)
var base_size: float = 105.0

const ROULETTE_OUTER: Array[Color] = [
	Color(0.55, 0.55, 0.55), # Gris   (Común)
	Color(0.10, 0.80, 0.20), # Verde  (Raro)
	Color(0.10, 0.40, 1.00), # Azul   (Super Raro)
	Color(0.60, 0.10, 0.90), # Morado (Épico)
	Color(1.00, 0.75, 0.00), # Dorado (Legendario)
]
const ROULETTE_INNER: Array[Color] = [
	Color(0.80, 0.80, 0.80),
	Color(0.50, 1.00, 0.60),
	Color(0.50, 0.80, 1.00),
	Color(0.85, 0.50, 1.00),
	Color(1.00, 0.95, 0.50),
]

# ── Estado del Tesseracto ─────────────────────────────────────
var _time: float          = 0.0
var _angle_xw: float      = 0.0
var _angle_yw: float      = 0.0
var _angle_zw: float      = 0.0
var _zoom: float           = 0.0
var _spin_speed: float     = 1.0
var _active: bool          = false
var _settled: bool         = false
var _settled_time: float   = 0.0
var _locked_in: bool       = false
var _exploding: bool       = false
var _flash: float          = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _particles: Array = []
var _bursts: Array[Dictionary] = []

# ── Sistema de 3 Mini-Juegos Interactivos (15s total) ────────
enum Stage { SLICE, BALANCE, SHIELD, COMPLETE }
var current_stage := Stage.SLICE

# Fase 1 (0s-4s): Corte 4D (Ninja Slice con Mouse Motion)
var stage1_nodes: Array = []
var stage1_cleared: bool = false
var _slice_trail: Array[Vector2] = []

# Fase 2 (4s-8s): Sincronización de Frecuencia (Hold Gauge)
var stage2_freq: float = 0.2
var stage2_target_min: float = 0.40
var stage2_target_max: float = 0.75
var stage2_in_zone_time: float = 0.0
var stage2_is_holding: bool = false
var stage2_cleared: bool = false

# Fase 3 (8s-12s): Escudo Deflector 360° (Shield Deflect Missiles)
var stage3_shield_angle: float = 0.0
var stage3_bullets: Array = []
var stage3_blocked_count: int = 0
var stage3_processed_count: int = 0
var stage3_cleared: bool = false

# Puntuación global del mini-juego
var luck_score: float = 0.0 # 0.0 -> 1.0
var _luck_bonus: int = 0
var status_msg: String = ""

signal animation_finished
signal lock_in_triggered
signal luck_bonus_applied(bonus_tiers: int)

# ── API Pública ───────────────────────────────────────────────
func start(p_outer: Color, p_inner: Color) -> void:
	target_outer_color  = p_outer
	target_inner_color  = p_inner
	current_outer_color = ROULETTE_OUTER[0]
	current_inner_color = ROULETTE_INNER[0]
	
	_time           = 0.0
	_zoom           = 0.0
	_spin_speed     = 1.0
	_active         = true
	_settled        = false
	_settled_time   = 0.0
	_locked_in      = false
	_exploding      = false
	_flash          = 0.0
	_shake_offset   = Vector2.ZERO
	_bursts.clear()
	_slice_trail.clear()

	# Reiniciar Mini-Juegos
	current_stage         = Stage.SLICE
	luck_score            = 0.0
	_luck_bonus           = 0
	stage1_cleared        = false
	stage2_cleared        = false
	stage3_cleared        = false
	stage2_freq           = 0.2
	stage2_in_zone_time   = 0.0
	stage2_is_holding     = false
	stage3_shield_angle   = 0.0
	stage3_blocked_count  = 0
	stage3_processed_count = 0
	status_msg            = "¡FASE 1: DESLIZÁ EL MOUSE Y CORTÁ LOS 4 NODOS!"

	_init_particles()
	_init_stage1_nodes()
	_init_stage3_bullets()
	mouse_filter = MOUSE_FILTER_STOP
	set_process(true)
	show()

func stop() -> void:
	_active  = false
	_settled = false
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(false)
	hide()

func skip_to_final() -> void:
	if not _active:
		return
	_time = 12.0
	current_stage = Stage.COMPLETE
	if not _locked_in:
		_locked_in = true
		lock_in_triggered.emit()
		if _luck_bonus > 0:
			luck_bonus_applied.emit(_luck_bonus)
	mouse_filter = MOUSE_FILTER_IGNORE
	current_outer_color = target_outer_color
	current_inner_color = target_inner_color

func _ready() -> void:
	set_process(false)
	hide()
	custom_minimum_size = Vector2(340, 340)
	mouse_filter = MOUSE_FILTER_IGNORE

func _init_particles() -> void:
	_particles.clear()
	for i in range(35):
		_particles.append(Particle.new(
			randf() * TAU,
			randf_range(80.0, 220.0),
			randf_range(1.5, 3.5),
			randf_range(2.0, 5.0),
			randf_range(0.3, 0.9)
		))

func _init_stage1_nodes() -> void:
	stage1_nodes.clear()
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(170, 170)
	var angles := [ -0.75 * PI, -0.25 * PI, 0.25 * PI, 0.75 * PI ]
	for a in angles:
		var n_pos := center + Vector2(cos(a), sin(a)) * 120.0
		stage1_nodes.append(NodeTarget.new(n_pos))

func _init_stage3_bullets() -> void:
	stage3_bullets.clear()
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(170, 170)
	
	# 4 misiles desde direcciones cardinales a diferentes tiempos (0.8s, 1.6s, 2.4s, 3.2s)
	var origins := [
		center + Vector2(-220, -140),
		center + Vector2(220, 140),
		center + Vector2(-160, 200),
		center + Vector2(180, -180)
	]
	var delays := [ 0.5, 1.3, 2.1, 2.9 ]
	for idx in range(4):
		stage3_bullets.append(ShieldBullet.new(origins[idx], center, delays[idx], 230.0))

# ── Interacción de Mini-Juegos ────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if not _active or _locked_in:
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_slice_trail.append(mm.position)
		if _slice_trail.size() > 10:
			_slice_trail.remove_at(0)

		# Apuntar el escudo 360° hacia la posición del mouse
		var center := size * 0.5
		stage3_shield_angle = (mm.position - center).angle()

		# FASE 1: Ninja Slice con mouse motion
		if current_stage == Stage.SLICE and not stage1_cleared:
			for n in stage1_nodes:
				if not n.hit and mm.position.distance_to(n.pos) <= n.radius + 10.0:
					n.hit = true
					_spin_speed += 1.8
					_shake_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
					_bursts.append({ "pos": n.pos, "radius": 8.0, "alpha": 1.0, "col": Color(0.2, 0.9, 1.0) })
					_check_stage1_completion()
					break

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# FASE 2: Balance de Frecuencia (Hold Mouse Button)
		if current_stage == Stage.BALANCE:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				stage2_is_holding = mb.pressed

func _check_stage1_completion() -> void:
	var hits := 0
	for n in stage1_nodes:
		if n.hit: hits += 1
	
	if hits >= 4:
		stage1_cleared = true
		luck_score += 0.30
		current_stage = Stage.BALANCE
		status_msg = "¡FASE 2: MANTENÉ EL CLICK DENTRO DE LA ZONA VERDE!"
	else:
		status_msg = "¡CORTE 4D (%d/4 NODOS)!" % hits

func _evaluate_bonus() -> void:
	if luck_score >= 0.60:
		_luck_bonus = 1
		status_msg = "¡DEFENSA PERFECTA! 🔥 RAREZA MEJORADA"
	else:
		status_msg = "¡SECUENCIA DE PODER COMPLETADA!"

# ── Loop Principal (15s total) ────────────────────────────────
func _process(delta: float) -> void:
	if _settled:
		_process_settled(delta)
		return
	if not _active:
		return

	_time += delta

	# Re-posicionar si el layout no estaba listo al inicio
	var c := size * 0.5
	if c != Vector2.ZERO and c != Vector2(170, 170):
		if stage1_nodes.size() > 0 and stage1_nodes[0].pos.x == 170:
			var angles := [ -0.75 * PI, -0.25 * PI, 0.25 * PI, 0.75 * PI ]
			for idx in range(4):
				stage1_nodes[idx].pos = c + Vector2(cos(angles[idx]), sin(angles[idx])) * 120.0

	# ── Control de Fases por Tiempo Límite ─────────────────────
	if _time >= 4.0 and current_stage == Stage.SLICE:
		current_stage = Stage.BALANCE
		status_msg = "¡FASE 2: MANTENÉ EL CLICK DENTRO DE LA ZONA VERDE!"
	elif _time >= 8.0 and current_stage == Stage.BALANCE:
		current_stage = Stage.SHIELD
		status_msg = "¡FASE 3: GIRÁ EL ESCUDO Y BLOQUEÁ LOS 4 RAYOS!"
	elif _time >= 12.0 and current_stage == Stage.SHIELD:
		current_stage = Stage.COMPLETE
		_evaluate_bonus()

	# ── 1. Color Roulette / Lock-In ───────────────────────────
	if _time < 11.5:
		var step_idx: int = int(_time / 0.3) % ROULETTE_OUTER.size()
		current_outer_color = current_outer_color.lerp(ROULETTE_OUTER[step_idx], delta * 10.0)
		current_inner_color = current_inner_color.lerp(ROULETTE_INNER[step_idx], delta * 10.0)
		_spin_speed = maxf(1.0 + (_time * 0.3), _spin_speed - delta * 2.0)
	elif _time < 12.2:
		current_outer_color = current_outer_color.lerp(target_outer_color, delta * 10.0)
		current_inner_color = current_inner_color.lerp(target_inner_color, delta * 10.0)
		_spin_speed = 3.0
		if not _locked_in:
			_locked_in = true
			lock_in_triggered.emit()
			if _luck_bonus > 0:
				luck_bonus_applied.emit(_luck_bonus)
			mouse_filter = MOUSE_FILTER_IGNORE
	else:
		current_outer_color = target_outer_color
		current_inner_color = target_inner_color
		var progress: float = clampf((_time - 12.2) / 2.3, 0.0, 1.0)
		_spin_speed = lerp(3.0, 12.0, progress * progress)

	# ── 2. Rotación 4D y Zoom ─────────────────────────────────
	_angle_xw += delta * 0.8 * _spin_speed
	_angle_yw += delta * 0.5 * _spin_speed
	_angle_zw += delta * 0.3 * _spin_speed

	if _time < 2.0:
		_zoom = _time / 2.0
	else:
		var pulse_freq: float = 4.0 if _locked_in else 2.0
		var pulse_amp: float  = 0.08 if _locked_in else 0.04
		_zoom = 1.0 + sin(_time * pulse_freq) * pulse_amp

	# ── 3. Lógica específica de Mini-Juegos ────────────────────
	if current_stage == Stage.BALANCE and not stage2_cleared:
		if stage2_is_holding:
			stage2_freq = minf(1.0, stage2_freq + delta * 0.75)
		else:
			stage2_freq = maxf(0.0, stage2_freq - delta * 0.60)

		if stage2_freq >= stage2_target_min and stage2_freq <= stage2_target_max:
			stage2_in_zone_time += delta
			if stage2_in_zone_time >= 2.0:
				stage2_cleared = true
				luck_score += 0.35
				current_stage = Stage.SHIELD
				status_msg = "¡FASE 3: GIRÁ EL ESCUDO Y BLOQUEÁ LOS 4 RAYOS!"
		status_msg = "¡BALANCEÁ LA FRECUENCIA! (%.1fs / 2.0s)" % stage2_in_zone_time

	elif current_stage == Stage.SHIELD and not stage3_cleared:
		var stage3_time: float = _time - 8.0
		var center := size * 0.5
		if center == Vector2.ZERO: center = Vector2(170, 170)

		# Procesar misiles de Fase 3
		for b in stage3_bullets:
			if not b.active and stage3_time >= b.spawn_delay and not b.blocked and not b.missed:
				b.active = true

			if b.active:
				b.pos += b.dir * b.speed * delta
				var dist_to_center: float = b.pos.distance_to(center)

				# ¿Llegó a la zona del escudo? (Radio 110 px)
				if dist_to_center <= 110.0:
					b.active = false
					var incoming_angle: float = (b.pos - center).angle()
					var diff: float = abs(angle_difference(incoming_angle, stage3_shield_angle))

					# Si la diferencia de ángulo es menor a 0.6 rad (~35°), se bloquea
					if diff <= 0.65:
						b.blocked = true
						stage3_blocked_count += 1
						luck_score += 0.09 # +9% por cada misil bloqueado (+36% total)
						_spin_speed += 2.0
						_shake_offset = Vector2(randf_range(-9, 9), randf_range(-9, 9))
						_bursts.append({ "pos": b.pos, "radius": 16.0, "alpha": 1.0, "col": Color(0.2, 0.8, 1.0) })
					else:
						b.missed = true
						_shake_offset = Vector2(randf_range(-4, 4), randf_range(-4, 4))
					
					stage3_processed_count += 1
					if stage3_processed_count >= 4:
						stage3_cleared = true
						current_stage = Stage.COMPLETE
						_evaluate_bonus()

		if not stage3_cleared:
			status_msg = "¡ESCUDO 360°! BLOQUEADOS (%d/4)" % stage3_blocked_count

	# ── 4. Screen Shake & Partículas ───────────────────────────
	if _time >= 12.0:
		var shake: float = lerp(1.5, 14.0, clampf((_time - 12.0) / 2.5, 0.0, 1.0))
		_shake_offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	elif _shake_offset != Vector2.ZERO:
		_shake_offset = _shake_offset.move_toward(Vector2.ZERO, delta * 40.0)

	for p in _particles:
		p.angle += delta * p.speed * (_spin_speed * 0.5)
		if _time >= 12.0:
			p.dist = move_toward(p.dist, 20.0, delta * 70.0)
		else:
			p.dist = wrapf(p.dist - delta * 20.0, 60.0, 220.0)

	# Actualizar bursts
	var i := _bursts.size() - 1
	while i >= 0:
		var b: Dictionary = _bursts[i]
		b["radius"] = b["radius"] + delta * 130.0
		b["alpha"]  = b["alpha"] - delta * 2.8
		if b["alpha"] <= 0.0:
			_bursts.remove_at(i)
		i -= 1

	# ── 5. Explosión final (14.5s -> 15.0s) ───────────────────
	if _time >= 14.5 and not _exploding:
		_exploding = true

	if _exploding:
		_flash = minf(1.0, (_time - 14.5) / 0.5)
		if _time >= 15.0:
			_active  = false
			_settled = true
			_settled_time = 0.0
			_flash   = 0.0
			_shake_offset = Vector2.ZERO
			_particles.clear()
			current_outer_color = target_outer_color
			current_inner_color = target_inner_color
			animation_finished.emit()
			return

	queue_redraw()

# ── Loop asentado ─────────────────────────────────────────────
func _process_settled(delta: float) -> void:
	_settled_time += delta
	_angle_xw += delta * 0.35
	_angle_yw += delta * 0.22
	_angle_zw += delta * 0.14
	_zoom = 1.0 + sin(_settled_time * 1.8) * 0.03
	queue_redraw()

# ── Dibujo ────────────────────────────────────────────────────
func _draw() -> void:
	var center: Vector2 = (size * 0.5) + _shake_offset
	var s: float = base_size * _zoom

	# ── Mode Asentado (Final) ──
	if _settled:
		var verts_o: Array[Vector2] = _project_tesseract(s,        _angle_xw,       _angle_yw,       _angle_zw)
		var verts_i: Array[Vector2] = _project_tesseract(s * 0.42, _angle_xw + 0.6, _angle_yw + 0.4, _angle_zw + 0.2)
		var aura: Color = target_outer_color
		aura.a = 0.15 + sin(_settled_time * 2.5) * 0.06
		draw_circle(center, s * 1.5, aura)
		
		var glow_o: Color = target_outer_color
		glow_o.a = 0.30
		var glow_i: Color = target_inner_color
		glow_i.a = 0.40
		_draw_tesseract_edges(verts_o, center, glow_o, 8.0)
		_draw_tesseract_edges(verts_i, center, glow_i, 5.5)
		
		var mid_o: Color = target_outer_color
		mid_o.a = 0.65
		var mid_i: Color = target_inner_color
		mid_i.a = 0.70
		_draw_tesseract_edges(verts_o, center, mid_o, 4.0)
		_draw_tesseract_edges(verts_i, center, mid_i, 3.0)
		
		_draw_tesseract_edges(verts_o, center, target_outer_color, 2.5)
		_draw_tesseract_edges(verts_i, center, target_inner_color, 2.0)
		return

	# ── UI del Mini-Juego Activo ──
	if _active and not _locked_in:
		_draw_minigame_ui(center)

	# Slice trail (Ninja Slice)
	if _slice_trail.size() > 1:
		for k in range(1, _slice_trail.size()):
			var p1: Vector2 = _slice_trail[k-1]
			var p2: Vector2 = _slice_trail[k]
			var a: float = float(k) / _slice_trail.size()
			draw_line(p1, p2, Color(0.2, 0.9, 1.0, a * 0.7), 4.0, true)

	# Bursts de click / impacto
	for b: Dictionary in _bursts:
		var bc: Color = b["col"]; bc.a = b["alpha"]
		draw_arc(b["pos"], b["radius"], 0.0, TAU, 24, bc, 3.0, true)

	if _time >= 11.5:
		var bg_alpha: float = clampf((_time - 11.5) / 3.0, 0.0, 0.35)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, bg_alpha))

	# ── Render Partículas ──
	for p in _particles:
		var p_pos: Vector2 = center + Vector2(cos(p.angle), sin(p.angle)) * p.dist
		var p_col: Color   = current_inner_color
		p_col.a = p.alpha * (1.0 - _flash)
		draw_circle(p_pos, p.size, p_col)
		var halo_col: Color = current_outer_color; halo_col.a = p.alpha * 0.4 * (1.0 - _flash)
		draw_arc(p_pos, p.size + 2.5, 0.0, TAU, 12, halo_col, 1.2, true)

	var aura_col: Color = current_outer_color; aura_col.a = 0.12 + sin(_time * 3.0) * 0.05
	draw_circle(center, s * 1.4, aura_col)

	# ── Render Tesseracto 4D ──
	var verts_outer: Array[Vector2] = _project_tesseract(s,        _angle_xw,       _angle_yw,       _angle_zw)
	var verts_inner: Array[Vector2] = _project_tesseract(s * 0.42, _angle_xw + 0.6, _angle_yw + 0.4, _angle_zw + 0.2)

	var col_outer: Color = current_outer_color.lerp(Color.WHITE, _flash * 0.9)
	var col_inner: Color = current_inner_color.lerp(Color.WHITE, _flash * 0.9)

	var glow_o: Color = col_outer; glow_o.a = 0.30
	var glow_i: Color = col_inner; glow_i.a = 0.40
	_draw_tesseract_edges(verts_outer, center, glow_o, 9.0)
	_draw_tesseract_edges(verts_inner, center, glow_i, 6.0)

	var mid_o: Color = col_outer; mid_o.a = 0.60
	var mid_i: Color = col_inner; mid_i.a = 0.65
	_draw_tesseract_edges(verts_outer, center, mid_o, 4.5)
	_draw_tesseract_edges(verts_inner, center, mid_i, 3.5)

	_draw_tesseract_edges(verts_outer, center, col_outer, 2.5)
	_draw_tesseract_edges(verts_inner, center, col_inner, 2.0)

	# Shockwave / Flash final
	if _flash > 0.0:
		var shock_r: float  = _flash * 300.0
		var fade: float     = 1.0 - _flash
		var sc: Color = col_outer; sc.a = fade
		draw_arc(center, shock_r, 0.0, TAU, 64, sc, 10.0, true)
		var sc2: Color = col_inner; sc2.a = fade * 0.7
		draw_arc(center, shock_r * 0.6, 0.0, TAU, 48, sc2, 6.0, true)
		draw_circle(center, shock_r * 0.5, Color(1.0, 1.0, 1.0, fade * 0.55))

# ── Renderizado de UI de los Mini-Juegos ──────────────────────
func _draw_minigame_ui(center: Vector2) -> void:
	# Barra de Suerte Global
	var bar_w: float = 230.0
	var bar_h: float = 14.0
	var bar_pos := Vector2(center.x - bar_w * 0.5, 14.0)
	
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.1, 0.1, 0.1, 0.8), true)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.4, 0.4, 0.4, 0.6), false, 1.5)
	
	if luck_score > 0.0:
		var fill_w: float = bar_w * minf(1.0, luck_score)
		var fill_col := Color(0.2, 0.8, 1.0).lerp(Color(1.0, 0.8, 0.0), luck_score)
		draw_rect(Rect2(bar_pos, Vector2(fill_w, bar_h)), fill_col, true)
		draw_rect(Rect2(bar_pos, Vector2(fill_w, bar_h)), Color.WHITE * Color(1,1,1,0.5), false, 1.0)

	# FASE 1: Ninja Slice Nodes
	if current_stage == Stage.SLICE:
		for n in stage1_nodes:
			if not n.hit:
				var pulse: float = sin(_time * 6.0) * 3.0
				var r: float = float(n.radius) + pulse
				draw_circle(n.pos, r + 4.0, Color(0.1, 0.8, 1.0, 0.25))
				draw_circle(n.pos, r, Color(0.2, 0.9, 1.0, 0.6))
				draw_arc(n.pos, r, 0, TAU, 32, Color.WHITE, 2.0, true)
				draw_circle(n.pos, 4.0, Color.WHITE)

	# FASE 2: Frequency Balance Meter
	elif current_stage == Stage.BALANCE:
		var b_width: float = 200.0
		var b_height: float = 18.0
		var b_rect := Rect2(center.x - b_width*0.5, center.y + 110.0, b_width, b_height)
		
		draw_rect(b_rect, Color(0.08, 0.08, 0.12, 0.9), true)
		draw_rect(b_rect, Color(0.4, 0.4, 0.5), false, 2.0)

		var zone_x: float = b_rect.position.x + b_width * stage2_target_min
		var zone_w: float = b_width * (stage2_target_max - stage2_target_min)
		draw_rect(Rect2(zone_x, b_rect.position.y, zone_w, b_height), Color(0.1, 0.9, 0.3, 0.4), true)
		draw_rect(Rect2(zone_x, b_rect.position.y, zone_w, b_height), Color(0.2, 1.0, 0.4, 0.9), false, 1.5)

		var ind_x: float = b_rect.position.x + b_width * stage2_freq
		draw_line(Vector2(ind_x, b_rect.position.y - 4.0), Vector2(ind_x, b_rect.position.y + b_height + 4.0), Color.WHITE, 3.0)
		draw_circle(Vector2(ind_x, b_rect.position.y + b_height * 0.5), 6.0, Color(1.0, 0.8, 0.1))

	# FASE 3: Escudo Deflector 360° (Shield Deflect)
	elif current_stage == Stage.SHIELD:
		# Dibujar el Escudo Arco del Jugador (sigue la dirección del ratón)
		var shield_r: float = 110.0
		var s_start: float = stage3_shield_angle - 0.33 * PI
		var s_end: float   = stage3_shield_angle + 0.33 * PI
		
		# Aura neón del escudo
		draw_arc(center, shield_r, s_start, s_end, 32, Color(0.2, 0.8, 1.0, 0.4), 10.0, true)
		draw_arc(center, shield_r, s_start, s_end, 32, Color.WHITE, 4.0, true)

		# Dibujar los 4 Misiles de Energía volando hacia el centro
		for b in stage3_bullets:
			if b.active:
				draw_circle(b.pos, 8.0, Color(1.0, 0.3, 0.2))
				draw_circle(b.pos, 4.0, Color.WHITE)
				# Estela de disparo
				draw_line(b.pos, b.pos - b.dir * 25.0, Color(1.0, 0.4, 0.1, 0.7), 3.0, true)

# Proyección perspectiva 4D -> 3D -> 2D
func _project_tesseract(s: float, axw: float, ayw: float, azw: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in range(16):
		var x: float = 1.0 if (i & 1) else -1.0
		var y: float = 1.0 if (i & 2) else -1.0
		var z: float = 1.0 if (i & 4) else -1.0
		var w: float = 1.0 if (i & 8) else -1.0

		var nx: float = x * cos(axw) - w * sin(axw)
		var nw: float = x * sin(axw) + w * cos(axw)
		x = nx; w = nw

		var ny: float = y * cos(ayw) - w * sin(ayw)
		nw = y * sin(ayw) + w * cos(ayw)
		y = ny; w = nw

		var nz: float = z * cos(azw) - w * sin(azw)
		w = z * sin(azw) + w * cos(azw)
		z = nz

		var d: float = 2.6 - w
		result.append(Vector2(x / d, y / d) * s)

	return result

func _draw_tesseract_edges(verts: Array[Vector2], offset: Vector2, col: Color, width: float) -> void:
	for i in range(16):
		for j in range(i + 1, 16):
			if _popcount(i ^ j) == 1:
				draw_line(verts[i] + offset, verts[j] + offset, col, width, true)

func _popcount(n: int) -> int:
	var c := 0
	while n > 0:
		c += n & 1
		n >>= 1
	return c
