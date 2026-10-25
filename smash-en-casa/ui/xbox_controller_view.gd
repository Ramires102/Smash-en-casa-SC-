class_name XboxControllerView
extends Control

# Estado en vivo del control para resaltado interactivo
var controller_connected: bool = true
var stick_vector: Vector2 = Vector2.ZERO
var deadzone: float = 0.15
var stick_range: float = 0.95

# Estado de botones presionados (0.0 a 1.0)
var active_slots: Dictionary = {}
# Slot actualmente en modo escucha o bajo el cursor
var highlighted_slot: String = ""
var listening_slot: String = ""
var _pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(310, 230)

func _process(delta: float) -> void:
	_pulse_time += delta * 5.0
	queue_redraw()

func _get_slot_highlight(slot_name: String) -> float:
	var val: float = float(active_slots.get(slot_name, 0.0))
	if listening_slot == slot_name:
		return 0.65 + 0.35 * abs(sin(_pulse_time))
	if highlighted_slot == slot_name:
		return maxf(val, 0.55)
	return clampf(val, 0.0, 1.0)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var cx: float = w * 0.5
	var cy: float = h * 0.44
	var s: float = minf(w / 380.0, h / 275.0)

	var body_col: Color = Color(0.84, 0.85, 0.87, 1.0) if controller_connected else Color(0.42, 0.44, 0.47, 0.75)
	var grip_shade_col: Color = Color(0.75, 0.77, 0.80, 1.0) if controller_connected else Color(0.36, 0.38, 0.41, 0.75)
	var outline_col: Color = Color(0.11, 0.12, 0.14, 1.0)
	var dark_part_col: Color = Color(0.28, 0.30, 0.33, 1.0)
	var mid_part_col: Color = Color(0.42, 0.45, 0.49, 1.0)
	var active_green: Color = Color(0.15, 0.92, 0.38, 1.0)
	var listen_cyan: Color = Color(0.24, 0.68, 0.95, 1.0)

	# 1. Badges flotantes LT y RT (como ZL y ZR en Yuzu)
	_draw_trigger_badge(
		Vector2(cx - 142.0 * s, cy - 68.0 * s),
		Vector2(36.0 * s, 22.0 * s),
		"LT",
		_get_slot_highlight("btn_lt"),
		listening_slot == "btn_lt",
		s
	)
	_draw_trigger_badge(
		Vector2(cx + 142.0 * s, cy - 68.0 * s),
		Vector2(36.0 * s, 22.0 * s),
		"RT",
		_get_slot_highlight("btn_rt"),
		listening_slot == "btn_rt",
		s
	)

	# 2. Bumpers Superiores LB y RB
	_draw_bumper(
		Vector2(cx - 66.0 * s, cy - 72.0 * s),
		Vector2(62.0 * s, 18.0 * s),
		-0.14,
		"LB",
		_get_slot_highlight("btn_lb"),
		listening_slot == "btn_lb",
		s
	)
	_draw_bumper(
		Vector2(cx + 66.0 * s, cy - 72.0 * s),
		Vector2(62.0 * s, 18.0 * s),
		0.14,
		"RB",
		_get_slot_highlight("btn_rb"),
		listening_slot == "btn_rb",
		s
	)

	# 3. Silueta del Control de Xbox (Cuerpo ergonómico y agarres)
	var body_pts: PackedVector2Array = _build_xbox_body_polygon(Vector2(cx, cy), s)
	var outline_pts: PackedVector2Array = _build_xbox_body_polygon(Vector2(cx, cy), s * 1.022)
	draw_colored_polygon(outline_pts, outline_col)
	draw_colored_polygon(body_pts, body_col)
	draw_polyline(body_pts + PackedVector2Array([body_pts[0]]), outline_col, 2.2 * s, true)

	# Líneas de contorno interno de los agarres de Xbox
	var left_seam := PackedVector2Array([
		Vector2(cx - 104.0 * s, cy - 42.0 * s),
		Vector2(cx - 88.0 * s, cy + 2.0 * s),
		Vector2(cx - 72.0 * s, cy + 44.0 * s)
	])
	var right_seam := PackedVector2Array([
		Vector2(cx + 104.0 * s, cy - 42.0 * s),
		Vector2(cx + 88.0 * s, cy + 2.0 * s),
		Vector2(cx + 72.0 * s, cy + 44.0 * s)
	])
	draw_polyline(left_seam, grip_shade_col, 1.6 * s, true)
	draw_polyline(right_seam, grip_shade_col, 1.6 * s, true)

	# 4. Botón Guía Xbox (Nexus) en la parte superior central
	var guide_pos := Vector2(cx, cy - 46.0 * s)
	draw_circle(guide_pos, 11.5 * s, outline_col)
	draw_circle(guide_pos, 9.8 * s, Color(0.92, 0.94, 0.96) if controller_connected else Color(0.45, 0.47, 0.5))
	# X del logo Xbox
	draw_line(guide_pos + Vector2(-5.0 * s, -5.0 * s), guide_pos + Vector2(5.0 * s, 5.0 * s), outline_col, 2.0 * s, true)
	draw_line(guide_pos + Vector2(5.0 * s, -5.0 * s), guide_pos + Vector2(-5.0 * s, 5.0 * s), outline_col, 2.0 * s, true)

	# 5. Botón Start / Menu (Pausa) y botón View decorativo
	var view_pos := Vector2(cx - 22.0 * s, cy - 22.0 * s)
	draw_circle(view_pos, 6.2 * s, outline_col)
	draw_circle(view_pos, 5.0 * s, dark_part_col)

	var start_pos := Vector2(cx + 22.0 * s, cy - 22.0 * s)
	var start_hl: float = _get_slot_highlight("btn_start")
	var start_col: Color = dark_part_col.lerp(listen_cyan if listening_slot == "btn_start" else active_green, start_hl)
	draw_circle(start_pos, 8.2 * s, outline_col)
	draw_circle(start_pos, 6.8 * s, start_col)
	# Icono de 3 líneas (Menu de Xbox)
	for i in range(-1, 2):
		var ly: float = start_pos.y + float(i) * 2.4 * s
		draw_line(Vector2(start_pos.x - 3.2 * s, ly), Vector2(start_pos.x + 3.2 * s, ly), Color.WHITE, 1.2 * s)

	# 6. Stick Analógico Izquierdo (Posición Superior Izquierda — Xbox Layout)
	var lstick_base := Vector2(cx - 64.0 * s, cy - 20.0 * s)
	var lstick_hl: float = maxf(
		maxf(_get_slot_highlight("stick_up"), _get_slot_highlight("stick_down")),
		maxf(_get_slot_highlight("stick_left"), _get_slot_highlight("stick_right"))
	)
	var is_stick_listening: bool = listening_slot in ["stick_up", "stick_down", "stick_left", "stick_right"]
	draw_circle(lstick_base, 22.5 * s, outline_col)
	draw_circle(lstick_base, 20.5 * s, dark_part_col)
	draw_arc(lstick_base, 18.0 * s, 0.0, TAU, 32, mid_part_col, 1.5 * s, true)

	var stick_offset := Vector2(stick_vector.x, -stick_vector.y) * 7.5 * s
	var cap_pos := lstick_base + stick_offset
	var cap_col: Color = mid_part_col.lerp(listen_cyan if is_stick_listening else active_green, lstick_hl * 0.85)
	draw_circle(cap_pos, 15.0 * s, outline_col)
	draw_circle(cap_pos, 13.2 * s, cap_col)
	draw_arc(cap_pos, 9.5 * s, 0.0, TAU, 24, dark_part_col, 1.6 * s, true)

	# 7. Cruceta D-Pad (Posición Inferior Izquierda — Xbox Layout)
	var dpad_center := Vector2(cx - 34.0 * s, cy + 22.0 * s)
	_draw_xbox_dpad(dpad_center, s, active_green, listen_cyan)

	# 8. Stick Analógico Derecho (Decorativo para silueta fiel de Xbox)
	var rstick_base := Vector2(cx + 34.0 * s, cy + 22.0 * s)
	draw_circle(rstick_base, 20.0 * s, outline_col)
	draw_circle(rstick_base, 18.0 * s, dark_part_col)
	draw_circle(rstick_base, 12.0 * s, mid_part_col)
	draw_arc(rstick_base, 8.5 * s, 0.0, TAU, 24, dark_part_col, 1.4 * s, true)

	# 9. Botones Frontales Xbox (Y arriba, X izquierda, B derecha, A abajo)
	var face_center := Vector2(cx + 66.0 * s, cy - 20.0 * s)
	var btn_dist: float = 19.5 * s
	_draw_face_button(face_center + Vector2(0, -btn_dist), "Y", "btn_y", Color(0.95, 0.78, 0.15), s)
	_draw_face_button(face_center + Vector2(-btn_dist, 0), "X", "btn_x", Color(0.22, 0.62, 0.96), s)
	_draw_face_button(face_center + Vector2(btn_dist, 0), "B", "btn_b", Color(0.92, 0.26, 0.24), s)
	_draw_face_button(face_center + Vector2(0, btn_dist), "A", "btn_a", Color(0.20, 0.84, 0.38), s)

	# 10. Visualizador Circular del Stick en Tiempo Real (Debajo del control, igual que en Yuzu)
	var viz_center := Vector2(cx, cy + 92.0 * s)
	var viz_radius: float = 32.0 * s
	_draw_stick_visualizer(viz_center, viz_radius, s)

func _build_xbox_body_polygon(center: Vector2, s: float) -> PackedVector2Array:
	var half_pts: Array[Vector2] = [
		Vector2(0.0, -64.0),
		Vector2(28.0, -64.0),
		Vector2(55.0, -69.0),
		Vector2(82.0, -66.0),
		Vector2(102.0, -54.0),
		Vector2(114.0, -34.0),
		Vector2(122.0, -4.0),
		Vector2(126.0, 30.0),
		Vector2(124.0, 62.0),
		Vector2(116.0, 84.0),
		Vector2(102.0, 94.0),
		Vector2(86.0, 90.0),
		Vector2(74.0, 72.0),
		Vector2(62.0, 48.0),
		Vector2(42.0, 44.0),
		Vector2(0.0, 44.0)
	]
	var pts := PackedVector2Array()
	for p in half_pts:
		pts.append(center + p * s)
	for i in range(half_pts.size() - 2, 0, -1):
		var p: Vector2 = half_pts[i]
		pts.append(center + Vector2(-p.x, p.y) * s)
	return pts

func _draw_trigger_badge(pos: Vector2, bsize: Vector2, label: String, hl: float, is_listening: bool, s: float) -> void:
	var rect := Rect2(pos - bsize * 0.5, bsize)
	var base_col := Color(0.38, 0.40, 0.44, 1.0)
	var active_col := Color(0.24, 0.68, 0.95, 1.0) if is_listening else Color(0.18, 0.88, 0.38, 1.0)
	var fill_col := base_col.lerp(active_col, hl)

	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_col
	sb.border_color = Color(0.12, 0.13, 0.15, 1.0)
	sb.set_border_width_all(int(maxf(1.0, 1.5 * s)))
	sb.set_corner_radius_all(int(5.0 * s))
	draw_style_box(sb, rect)

	var font: Font = ThemeDB.fallback_font
	var fsize: int = maxi(9, int(11.0 * s))
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.72),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		fsize,
		Color(0.95, 0.96, 0.98)
	)

func _draw_bumper(pos: Vector2, bsize: Vector2, _angle: float, _label: String, hl: float, is_listening: bool, s: float) -> void:
	var rect := Rect2(pos - bsize * 0.5, bsize)
	var base_col := Color(0.42, 0.45, 0.49, 1.0)
	var active_col := Color(0.24, 0.68, 0.95, 1.0) if is_listening else Color(0.18, 0.88, 0.38, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = base_col.lerp(active_col, hl)
	sb.border_color = Color(0.11, 0.12, 0.14, 1.0)
	sb.set_border_width_all(int(maxf(1.0, 1.8 * s)))
	sb.corner_radius_top_left = int(8.0 * s)
	sb.corner_radius_top_right = int(8.0 * s)
	draw_style_box(sb, rect)

func _draw_xbox_dpad(center: Vector2, s: float, active_col: Color, listen_col: Color) -> void:
	var outline_col := Color(0.11, 0.12, 0.14, 1.0)
	var dish_col := Color(0.22, 0.24, 0.27, 1.0)
	var base_arm_col := Color(0.38, 0.41, 0.45, 1.0)

	# Plato cóncavo de la cruceta Xbox
	draw_circle(center, 21.0 * s, outline_col)
	draw_circle(center, 19.5 * s, dish_col)

	var arm_w: float = 10.5 * s
	var arm_l: float = 16.5 * s

	# Centro
	draw_rect(Rect2(center - Vector2(arm_w * 0.5, arm_w * 0.5), Vector2(arm_w, arm_w)), base_arm_col)

	# Arriba
	var up_hl: float = _get_slot_highlight("dpad_up")
	var up_c: Color = base_arm_col.lerp(listen_col if listening_slot == "dpad_up" else active_col, up_hl)
	var up_rect := Rect2(center.x - arm_w * 0.5, center.y - arm_l, arm_w, arm_l - arm_w * 0.4)
	draw_rect(up_rect, up_c)
	draw_rect(up_rect, outline_col, false, 1.4 * s)

	# Abajo
	var down_hl: float = _get_slot_highlight("dpad_down")
	var down_c: Color = base_arm_col.lerp(listen_col if listening_slot == "dpad_down" else active_col, down_hl)
	var down_rect := Rect2(center.x - arm_w * 0.5, center.y + arm_w * 0.4, arm_w, arm_l - arm_w * 0.4)
	draw_rect(down_rect, down_c)
	draw_rect(down_rect, outline_col, false, 1.4 * s)

	# Izquierda
	var left_hl: float = _get_slot_highlight("dpad_left")
	var left_c: Color = base_arm_col.lerp(listen_col if listening_slot == "dpad_left" else active_col, left_hl)
	var left_rect := Rect2(center.x - arm_l, center.y - arm_w * 0.5, arm_l - arm_w * 0.4, arm_w)
	draw_rect(left_rect, left_c)
	draw_rect(left_rect, outline_col, false, 1.4 * s)

	# Derecha
	var right_hl: float = _get_slot_highlight("dpad_right")
	var right_c: Color = base_arm_col.lerp(listen_col if listening_slot == "dpad_right" else active_col, right_hl)
	var right_rect := Rect2(center.x + arm_w * 0.4, center.y - arm_w * 0.5, arm_l - arm_w * 0.4, arm_w)
	draw_rect(right_rect, right_c)
	draw_rect(right_rect, outline_col, false, 1.4 * s)

func _draw_face_button(pos: Vector2, letter: String, slot_name: String, xbox_color: Color, s: float) -> void:
	var hl: float = _get_slot_highlight(slot_name)
	var is_listening: bool = (listening_slot == slot_name)
	var outline_col := Color(0.11, 0.12, 0.14, 1.0)
	var base_col := Color(0.32, 0.34, 0.38, 1.0)
	var target_col: Color = Color(0.24, 0.68, 0.95, 1.0) if is_listening else xbox_color
	var fill_col: Color = base_col.lerp(target_col, hl)

	var r: float = 10.2 * s
	draw_circle(pos, r + 1.4 * s, outline_col)
	draw_circle(pos, r, fill_col)

	var font: Font = ThemeDB.fallback_font
	var fsize: int = maxi(10, int(12.5 * s))
	var letter_col: Color = Color.WHITE if hl > 0.35 else xbox_color.lightened(0.25)
	draw_string(
		font,
		Vector2(pos.x - r, pos.y + fsize * 0.36),
		letter,
		HORIZONTAL_ALIGNMENT_CENTER,
		r * 2.0,
		fsize,
		letter_col
	)

func _draw_stick_visualizer(center: Vector2, radius: float, s: float) -> void:
	# Fondo circular oscuro estilo Yuzu
	draw_circle(center, radius, Color(0.14, 0.15, 0.17, 0.95))
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.32, 0.35, 0.39, 0.9), 1.2 * s, true)

	# Líneas de cruz central
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.24, 0.26, 0.29, 0.7), 1.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.24, 0.26, 0.29, 0.7), 1.0)

	# Anillo de Zona Muerta (Deadzone)
	var dz_r: float = clampf(deadzone, 0.0, 0.5) * radius
	if dz_r > 1.0:
		draw_circle(center, dz_r, Color(0.85, 0.25, 0.25, 0.16))
		draw_arc(center, dz_r, 0.0, TAU, 28, Color(0.85, 0.32, 0.32, 0.65), 1.1 * s, true)

	# Punto de posición actual del Stick Analógico
	var dot_pos := center + Vector2(stick_vector.x, -stick_vector.y) * (radius - 3.0 * s)
	if stick_vector.length_squared() > 0.002:
		draw_line(center, dot_pos, Color(0.18, 0.85, 0.45, 0.55), 1.4 * s, true)
	draw_circle(dot_pos, 3.2 * s, Color(0.15, 0.95, 0.45, 1.0))
