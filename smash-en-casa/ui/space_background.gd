class_name SpaceBackground
extends Control

class Star:
	var pos: Vector2
	var size: float
	var base_alpha: float
	var twinkle_speed: float
	var color: Color
	func _init(p: Vector2, s: float, a: float, sp: float, c: Color) -> void:
		pos = p; size = s; base_alpha = a; twinkle_speed = sp; color = c

class CosmicDust:
	var pos: Vector2
	var speed: Vector2
	var size: float
	var alpha: float
	var color: Color
	func _init(p: Vector2, sp: Vector2, s: float, a: float, c: Color) -> void:
		pos = p; speed = sp; size = s; alpha = a; color = c

class ShootingStar:
	var start_pos: Vector2
	var pos: Vector2
	var dir: Vector2
	var speed: float
	var length: float
	var active: bool = false
	var timer: float = 0.0
	var alpha: float = 1.0

# ── Estado del Fondo Espacial ─────────────────────────────────
var _time: float = 0.0
var _stars: Array = []
var _dust: Array = []
var _shooting_stars: Array = []
var _next_shooting_star_timer: float = 2.0

const STAR_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0),       # Blanco
	Color(0.7, 0.9, 1.0),       # Cían Estelar
	Color(1.0, 0.9, 0.7),       # Dorado Pálido
	Color(0.85, 0.75, 1.0),     # Lavanda
]

const NEBULA_COLORS: Array[Color] = [
	Color(0.25, 0.05, 0.40, 0.25), # Púrpura Nebulosa
	Color(0.05, 0.15, 0.45, 0.20), # Azul Profundo
	Color(0.40, 0.08, 0.30, 0.18), # Magenta Cósmico
]

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = MOUSE_FILTER_IGNORE
	_init_space()

func _init_space() -> void:
	var screen_w: float = get_viewport_rect().size.x
	var screen_h: float = get_viewport_rect().size.y
	if screen_w <= 0: screen_w = 1280.0
	if screen_h <= 0: screen_h = 720.0

	# 1. Generar 140 Estrellas centellantes
	_stars.clear()
	for i in range(140):
		var p := Vector2(randf() * screen_w, randf() * screen_h)
		var s := randf_range(1.0, 3.2)
		var a := randf_range(0.3, 0.9)
		var sp := randf_range(2.0, 6.0)
		var c := STAR_COLORS[randi() % STAR_COLORS.size()]
		_stars.append(Star.new(p, s, a, sp, c))

	# 2. Generar 35 Partículas de Polvo Cósmico
	_dust.clear()
	for i in range(35):
		var p := Vector2(randf() * screen_w, randf() * screen_h)
		var sp := Vector2(randf_range(-8.0, 8.0), randf_range(-15.0, -35.0))
		var s := randf_range(1.5, 4.0)
		var a := randf_range(0.2, 0.6)
		var c := STAR_COLORS[randi() % STAR_COLORS.size()]
		_dust.append(CosmicDust.new(p, sp, s, a, c))

	# 3. Preparar Estrellas Fugaces
	_shooting_stars.clear()

func _process(delta: float) -> void:
	_time += delta
	var screen_w: float = get_viewport_rect().size.x
	var screen_h: float = get_viewport_rect().size.y
	if screen_w <= 0: screen_w = 1280.0
	if screen_h <= 0: screen_h = 720.0

	# Actualizar Polvo Cósmico (Movimiento continuo flotante)
	for d in _dust:
		d.pos += d.speed * delta
		if d.pos.y < -10.0:
			d.pos.y = screen_h + 10.0
			d.pos.x = randf() * screen_w
		if d.pos.x < -10.0: d.pos.x = screen_w + 10.0
		elif d.pos.x > screen_w + 10.0: d.pos.x = -10.0

	# Spawnear Estrellas Fugaces periódicamente
	_next_shooting_star_timer -= delta
	if _next_shooting_star_timer <= 0.0:
		_next_shooting_star_timer = randf_range(2.5, 5.5)
		var start_p := Vector2(randf_range(0.0, screen_w * 0.8), randf_range(0.0, screen_h * 0.4))
		var angle := randf_range(0.4, 0.8) # Dirección diagonal hacia abajo-derecha
		var dir := Vector2(cos(angle), sin(angle))
		var st := ShootingStar.new()
		st.start_pos = start_p
		st.pos = start_p
		st.dir = dir
		st.speed = randf_range(800.0, 1400.0)
		st.length = randf_range(80.0, 160.0)
		st.active = true
		st.alpha = 1.0
		_shooting_stars.append(st)

	# Actualizar Estrellas Fugaces
	var idx := _shooting_stars.size() - 1
	while idx >= 0:
		var st: ShootingStar = _shooting_stars[idx]
		if st.active:
			st.pos += st.dir * st.speed * delta
			st.alpha -= delta * 1.8
			if st.alpha <= 0.0 or st.pos.x > screen_w + 200.0 or st.pos.y > screen_h + 200.0:
				_shooting_stars.remove_at(idx)
		idx -= 1

	queue_redraw()

func _draw() -> void:
	var screen_w: float = size.x if size.x > 0 else 1280.0
	var screen_h: float = size.y if size.y > 0 else 720.0

	# ── 1. Fondo Oscuro Abismal Gradiente ────────────────────
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.08))

	# ── 2. Nubes de Nebulosa Cósmica Suave ───────────────────
	var center := size * 0.5
	var neb1_pos := center + Vector2(cos(_time * 0.2) * 120.0, sin(_time * 0.15) * 80.0)
	var neb2_pos := center + Vector2(sin(_time * 0.25) * -160.0, cos(_time * 0.18) * -100.0)
	
	draw_circle(neb1_pos, 280.0, NEBULA_COLORS[0])
	draw_circle(neb2_pos, 240.0, NEBULA_COLORS[1])
	draw_circle(center, 320.0, NEBULA_COLORS[2])

	# ── 3. Estrellas Centellantes (Twinkling Starfield) ──────
	for st in _stars:
		var twinkle: float = (sin(_time * st.twinkle_speed + st.pos.x) + 1.0) * 0.5
		var alpha: float = clampf(st.base_alpha * (0.4 + twinkle * 0.6), 0.1, 1.0)
		var col: Color = st.color
		col.a = alpha
		draw_circle(st.pos, st.size, col)
		
		# Cruz de brillo estelar en estrellas más grandes
		if st.size > 2.2 and twinkle > 0.7:
			var cross_col := col
			cross_col.a = (twinkle - 0.7) * 0.8
			draw_line(st.pos - Vector2(4, 0), st.pos + Vector2(4, 0), cross_col, 1.0)
			draw_line(st.pos - Vector2(0, 4), st.pos + Vector2(0, 4), cross_col, 1.0)

	# ── 4. Polvo Cósmico Flotante ────────────────────────────
	for d in _dust:
		var d_col: Color = d.color
		d_col.a = d.alpha * (0.6 + sin(_time * 2.0 + d.pos.y) * 0.4)
		draw_circle(d.pos, d.size, d_col)

	# ── 5. Estrellas Fugaces (Cometas con Estela) ─────────────
	for st: ShootingStar in _shooting_stars:
		if st.active:
			var tail_end := st.pos - st.dir * st.length
			var col_head := Color(1.0, 1.0, 1.0, st.alpha)
			var col_tail := Color(0.3, 0.7, 1.0, 0.0)
			
			draw_line(st.pos, tail_end, Color(0.4, 0.8, 1.0, st.alpha * 0.7), 2.5, true)
			draw_line(st.pos, st.pos - st.dir * (st.length * 0.4), col_head, 1.5, true)
			draw_circle(st.pos, 3.0, col_head)
