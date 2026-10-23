extends Node

func _ready():
	print("Starting portrait generation from 2D anime artworks...")
	_process_all_portraits()
	print("All 2D portraits generated successfully!")
	get_tree().quit()

func _process_all_portraits():
	var base_dir = "C:/Users/Ram_102Gb/.gemini/antigravity/brain/44197bcc-bae2-4262-954c-19b11d5da622/"
	
	var list = [
		{
			"id": "lego_batman",
			"file": base_dir + "lego_batman_fighterz_clean_portrait_1792423296107.jpg",
			"crop": Rect2i(40, 180, 944, 640),
			"accent": Color(0.95, 0.82, 0.15)
		},

		{
			"id": "sakuya",
			"file": base_dir + "sakuya_art_1792433505548.jpg",
			"crop": Rect2i(40, 60, 944, 640),
			"accent": Color(0.45, 0.75, 1.0)
		},
		{
			"id": "gogeta",
			"file": base_dir + "gogeta_portrait_1792433414696.jpg",
			"crop": Rect2i(40, 70, 944, 640),
			"accent": Color(0.25, 0.65, 1.0)
		},

		{
			"id": "john",
			"file": base_dir + "john_art_1792423363278.jpg",
			"crop": Rect2i(38, 160, 820, 556),
			"accent": Color(0.4, 0.85, 0.95)
		}
	]
	
	for item in list:
		_process_character_card(item)
		
	_process_random_card()

func _process_character_card(item: Dictionary):
	var src_img = Image.load_from_file(item["file"])
	if not src_img:
		printerr("Failed to load: ", item["file"])
		return
		
	var crop_rect: Rect2i = item["crop"]
	var cropped = Image.create(crop_rect.size.x, crop_rect.size.y, false, src_img.get_format())
	cropped.blit_rect(src_img, crop_rect, Vector2i.ZERO)
	
	cropped.resize(280, 190, Image.INTERPOLATE_LANCZOS)
	var card_img = _apply_dbfz_frame(cropped, item["accent"])
	
	var out_path = "res://ui/character_select/portraits/" + item["id"] + ".png"
	var global_path = ProjectSettings.globalize_path(out_path)
	var err = card_img.save_png(global_path)
	print("Saved [", item["id"], "] -> ", global_path, " (err: ", err, ")")

func _process_random_card():
	var w = 280
	var h = 190
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var gold = Color(1.0, 0.85, 0.25)
	
	# Dark textured carbon background matching DBFZ ? box
	for y in range(h):
		for x in range(w):
			var norm = float(y) / float(h)
			var c = Color(0.12, 0.11, 0.09).lerp(Color(0.22, 0.18, 0.10), norm)
			if (x + y) % 8 < 2:
				c = c.lightened(0.04)
			img.set_pixel(x, y, c)
			
	# Render bold glowing question mark '?'
	var cx = w * 0.5
	var cy = h * 0.45
	for y in range(int(cy - 48), int(cy + 48)):
		for x in range(int(cx - 36), int(cx + 36)):
			var dx = x - cx
			var dy = y - cy
			# Upper curved hook
			var dist_arc = abs(Vector2(dx, dy + 14).length() - 22)
			var in_arc = dist_arc < 7 and (dy + 14 < 10 or dx > 0)
			# Vertical stroke
			var in_stroke = abs(dx + 2) < 6 and dy >= 5 and dy <= 20
			# Bottom dot
			var in_dot = Vector2(dx, dy - 32).length() < 7
			
			if in_arc or in_stroke or in_dot:
				img.set_pixel(x, y, gold)
			elif dist_arc < 12 or (abs(dx + 2) < 10 and dy >= 3 and dy <= 22) or Vector2(dx, dy - 32).length() < 11:
				var cur = img.get_pixel(x, y)
				img.set_pixel(x, y, cur.lerp(gold, 0.55))
				
	var card_img = _apply_dbfz_frame(img, gold)
	var out_path = "res://ui/character_select/portraits/random.png"
	var global_path = ProjectSettings.globalize_path(out_path)
	var err = card_img.save_png(global_path)
	print("Saved [random] -> ", global_path, " (err: ", err, ")")

func _apply_dbfz_frame(src: Image, accent: Color) -> Image:
	var w = src.get_width()
	var h = src.get_height()
	src.convert(Image.FORMAT_RGBA8)
	var out = Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(0, 0, w, h), Vector2i.ZERO)
	
	var corner_cut = 14
	var gold_outer = Color(0.88, 0.72, 0.22, 1.0)
	var gold_inner = Color(1.0, 0.94, 0.55, 1.0)
	var dark_rim = Color(0.20, 0.15, 0.05, 1.0)
	
	# DBFZ Chamfered Gold Border
	for y in range(h):
		for x in range(w):
			var top_left = (x + y) < corner_cut
			var top_right = ((w - 1 - x) + y) < corner_cut
			var bot_left = (x + (h - 1 - y)) < corner_cut
			var bot_right = ((w - 1 - x) + (h - 1 - y)) < corner_cut
			
			# Transparent outside corner chamfers
			if top_left or top_right or bot_left or bot_right:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
				
			var corner_diag = (x + y) == corner_cut or ((w - 1 - x) + y) == corner_cut or (x + (h - 1 - y)) == corner_cut or ((w - 1 - x) + (h - 1 - y)) == corner_cut
			var corner_diag_in = (x + y) == corner_cut + 2 or ((w - 1 - x) + y) == corner_cut + 2 or (x + (h - 1 - y)) == corner_cut + 2 or ((w - 1 - x) + (h - 1 - y)) == corner_cut + 2
			
			var dx = mini(x, w - 1 - x)
			var dy = mini(y, h - 1 - y)
			var d = mini(dx, dy)
			
			if corner_diag:
				out.set_pixel(x, y, dark_rim)
			elif corner_diag_in:
				out.set_pixel(x, y, gold_inner)
			elif d == 0:
				out.set_pixel(x, y, dark_rim)
			elif d in [1, 2]:
				out.set_pixel(x, y, gold_outer)
			elif d in [3, 4]:
				out.set_pixel(x, y, gold_inner)
			elif d == 5:
				out.set_pixel(x, y, dark_rim)
			elif d in [6, 7]:
				var c = out.get_pixel(x, y)
				out.set_pixel(x, y, c.lerp(accent, 0.5))
				
	# Subtle bottom dark gradient strip for text readability
	var banner_h = 32
	for y in range(h - banner_h - 4, h - 4):
		for x in range(4, w - 4):
			var norm = float(y - (h - banner_h - 4)) / float(banner_h)
			var alpha = lerp(0.0, 0.72, norm)
			var cur_c = out.get_pixel(x, y)
			if cur_c.a > 0.05:
				var shade = Color(0.02, 0.03, 0.06, 1.0)
				out.set_pixel(x, y, cur_c.lerp(shade, alpha))
				
	return out
