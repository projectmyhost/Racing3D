@tool
extends SceneTree

func _init():
	print("--- GENERATING PERFECT PIXEL-ACCURATE MOTORSPORT TEXTURES V5 ---")
	generate_billboard_art()
	generate_racing_banner()
	print("Textures updated!")
	quit(0)

const GLYPHS_7X9 = {
	"R": [
		"1111110",
		"1000001",
		"1000001",
		"1111110",
		"1000100",
		"1000010",
		"1000001",
		"1000001",
		"1000001"
	],
	"A": [
		"0011100",
		"0100010",
		"1000001",
		"1000001",
		"1111111",
		"1000001",
		"1000001",
		"1000001",
		"1000001"
	],
	"C": [
		"0111110",
		"1000001",
		"1000000",
		"1000000",
		"1000000",
		"1000000",
		"1000000",
		"1000001",
		"0111110"
	],
	"I": [
		"1111111",
		"0001000",
		"0001000",
		"0001000",
		"0001000",
		"0001000",
		"0001000",
		"0001000",
		"1111111"
	],
	"N": [
		"1000001",
		"1100001",
		"1010001",
		"1001001",
		"1000101",
		"1000011",
		"1000001",
		"1000001",
		"1000001"
	],
	"G": [
		"0111110",
		"1000001",
		"1000000",
		"1000000",
		"1001111",
		"1000001",
		"1000001",
		"1000001",
		"0111110"
	],
	"M": [
		"1000001",
		"1100011",
		"1010101",
		"1001001",
		"1000001",
		"1000001",
		"1000001",
		"1000001",
		"1000001"
	],
	"E": [
		"1111111",
		"1000000",
		"1000000",
		"1111110",
		"1000000",
		"1000000",
		"1000000",
		"1000000",
		"1111111"
	]
}

func generate_billboard_art():
	var w = 2048
	var h = 1024
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	for y in range(h):
		var ny = float(y) / float(h)
		for x in range(w):
			var nx = float(x) / float(w)
			var col = Color(0.12, 0.01, 0.02, 1.0).lerp(Color(0.85, 0.12, 0.08, 1.0), ny * 0.7 + nx * 0.3)
			var slant = int(x + y * 0.65) % 120
			if slant < 22:
				col = col.lerp(Color(1.0, 0.32, 0.10, 1.0), 0.40)
			if y < 80:
				col = col.lerp(Color(1.0, 0.60, 0.18, 1.0), 1.0 - float(y)/80.0)
			img.set_pixel(x, y, col)
			
	# Border frame
	for x in range(w):
		for y in range(24):
			img.set_pixel(x, y, Color(1.0, 0.85, 0.30, 1.0))
			img.set_pixel(x, h - 1 - y, Color(0.95, 0.20, 0.15, 1.0))
	for y in range(h):
		for x in range(24):
			img.set_pixel(x, y, Color(1.0, 0.85, 0.30, 1.0))
			img.set_pixel(w - 1 - x, y, Color(1.0, 0.85, 0.30, 1.0))

	# Shift text to start at x = 740 to clear profile card and center perfectly above the car!
	render_grid_text(img, "RACING GAME", Vector2(740, 680), 80.0, 145.0)
	draw_sub_text(img, "FIA FORMULA 1 WORLD CHAMPIONSHIP // 2026 OFFICIAL RACING ENGINE", Vector2(760, 880), 32.0)
	
	img.save_png("assets/textures/environments/tex_ref_billboard_art.png")
	
	# Also update material directly with ImageTexture to bypass importer cache!
	var mat_bb = load("res://assets/materials/environments/mat_ref_billboard_art.tres") as StandardMaterial3D
	if mat_bb:
		var tex = ImageTexture.create_from_image(img)
		mat_bb.albedo_texture = tex
		mat_bb.emission_texture = tex
		mat_bb.emission_enabled = true
		mat_bb.emission_energy_multiplier = 1.25
		mat_bb.cull_mode = BaseMaterial3D.CULL_DISABLED
		ResourceSaver.save(mat_bb, "res://assets/materials/environments/mat_ref_billboard_art.tres")
		print("mat_ref_billboard_art.tres updated directly with ImageTexture!")

func render_grid_text(img: Image, text: String, start: Vector2, glyph_w: float, glyph_h: float):
	var spacing = 18.0
	var word_space = 45.0
	var cur_x = start.x
	
	for i in range(text.length()):
		var ch = text[i]
		if ch == " ":
			cur_x += word_space
			continue
			
		if GLYPHS_7X9.has(ch):
			var grid: Array = GLYPHS_7X9[ch]
			for gy in range(9):
				var row: String = grid[gy]
				var y_start = start.y + float(gy) * (glyph_h / 9.0)
				var y_end = start.y + float(gy + 1) * (glyph_h / 9.0)
				
				for gx in range(7):
					if row[gx] == "1":
						var x_start = cur_x + float(gx) * (glyph_w / 7.0)
						var x_end = cur_x + float(gx + 1) * (glyph_w / 7.0)
						
						for y in range(int(y_start), int(y_end)):
							if y < 0 or y >= 1024: continue
							var ny = float(y - start.y) / glyph_h
							var shear = (ny - 0.5) * -0.22 * glyph_h
							for x in range(int(x_start + shear), int(x_end + shear)):
								if x < 0 or x >= 2048: continue
								if ny < 0.22:
									img.set_pixel(x, y, Color(1.0, 0.88, 0.32, 1.0))
								else:
									img.set_pixel(x, y, Color(1.0, 0.98, 0.96, 1.0))
									
		cur_x += glyph_w + spacing

func draw_sub_text(img: Image, text: String, start: Vector2, font_h: float):
	var char_w = font_h * 0.55
	for c_idx in range(text.length()):
		var ch = text[c_idx]
		var pos = start + Vector2(c_idx * (char_w + 3), 0)
		for y in range(int(pos.y), int(pos.y + font_h)):
			if y < 0 or y >= 1024: continue
			for x in range(int(pos.x), int(pos.x + char_w)):
				if x < 0 or x >= 2048: continue
				img.set_pixel(x, y, Color(1.0, 0.88, 0.40, 0.95))

func generate_racing_banner():
	var w = 512
	var h = 1024
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	for y in range(h):
		var ny = float(y) / float(h)
		for x in range(w):
			var col = Color(0.82, 0.06, 0.10, 1.0).lerp(Color(0.48, 0.02, 0.05, 1.0), ny)
			if abs(x - 256) < 30:
				col = col.lerp(Color(1.0, 0.25, 0.25, 1.0), 0.3)
			img.set_pixel(x, y, col)
			
	# Draw prominent white "R" motorsport logo in upper-middle (y: 180..420)
	var rx = 160
	var ry = 180
	var rw = 190
	var rh = 240
	for y in range(ry, ry + rh):
		var ny = float(y - ry) / float(rh)
		for x in range(rx, rx + rw):
			var nx = float(x - rx) / float(rw)
			var in_r = false
			if nx < 0.28: in_r = true
			elif ny < 0.25 and nx < 0.88: in_r = true
			elif ny > 0.38 and ny < 0.58 and nx < 0.88: in_r = true
			elif nx > 0.65 and ny < 0.52: in_r = true
			elif ny >= 0.52 and abs(nx - 0.28 - (ny - 0.52)*1.35) < 0.25: in_r = true
			if in_r:
				img.set_pixel(x, y, Color(0.98, 0.98, 0.99, 1.0))
				
	for y in range(920, 1024):
		for x in range(w):
			var check = (int(x / 32) + int(y / 26)) % 2 == 0
			if check:
				img.set_pixel(x, y, Color(0.95, 0.95, 0.95, 1.0))
			else:
				img.set_pixel(x, y, Color(0.08, 0.08, 0.08, 1.0))
				
	img.save_png("assets/textures/environments/tex_ref_racing_banner.png")
	
	var mat_banner = load("res://assets/materials/environments/mat_ref_racing_banner.tres") as StandardMaterial3D
	if mat_banner:
		var tex = ImageTexture.create_from_image(img)
		mat_banner.albedo_texture = tex
		mat_banner.cull_mode = BaseMaterial3D.CULL_DISABLED
		ResourceSaver.save(mat_banner, "res://assets/materials/environments/mat_ref_racing_banner.tres")
		print("mat_ref_racing_banner.tres updated directly with ImageTexture!")
