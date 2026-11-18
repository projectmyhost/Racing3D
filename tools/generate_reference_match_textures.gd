@tool
extends SceneTree

func _init():
	print("Generating enhanced photorealistic reference textures...")
	generate_billboard_art_perfect()
	generate_building_left_hq_perfect()
	generate_building_right_tower_perfect()
	generate_asphalt_perfect()
	generate_drainage_grate_perfect()
	generate_banner_perfect()
	generate_palm_perfect()
	print("All textures regenerated!")
	quit(0)

# =============================================================================
# 1. BILLBOARD ARTWORK ("RACING GAME" perfectly centered & high contrast)
# =============================================================================
func generate_billboard_art_perfect():
	var w = 2048
	var h = 1024
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	# Deep crimson to sunset amber speed wash
	for y in range(h):
		var ny = float(y) / float(h)
		for x in range(w):
			var nx = float(x) / float(w)
			var diag = nx * 0.65 + (1.0 - ny) * 0.45
			var r = lerp(0.55, 0.95, clamp(diag, 0.0, 1.0))
			var g = lerp(0.04, 0.28, clamp(diag * diag, 0.0, 1.0))
			var b = lerp(0.06, 0.10, clamp(1.0 - diag, 0.0, 1.0))
			
			# Speed line streaks
			var streak = sin(float(x) * 0.05 + float(y) * 0.02) * cos(float(y) * 0.08)
			if streak > 0.55:
				r += 0.12
				g += 0.06
			img.set_pixel(x, y, Color(r, g, b, 1.0))
			
	# Dark border & gold inner rim
	for y in range(h):
		for x in range(w):
			if x < 28 or x > w - 28 or y < 28 or y > h - 28:
				img.set_pixel(x, y, Color(0.05, 0.06, 0.08, 1.0))
			elif x < 36 or x > w - 36 or y < 36 or y > h - 36:
				img.set_pixel(x, y, Color(0.96, 0.78, 0.15, 1.0))
				
	# Speed chevron slashes
	for i in range(14):
		var start_x = 280 + i * 110
		for y in range(140, 880):
			var ox = int(start_x + (y - 512) * 0.55)
			for sx in range(16):
				var px = ox + sx
				if px >= 36 and px < w - 36:
					var cur = img.get_pixel(px, y)
					img.set_pixel(px, y, cur.lerp(Color(1.0, 0.85, 0.35, 1.0), 0.35))
					
	# Draw BOLD "RACING GAME" centered in lower-middle (y: 420..640)
	draw_bold_text(img, "RACING GAME", Vector2(340, 440), 180.0)
	draw_sub_text(img, "FIA FORMULA 1 WORLD CHAMPIONSHIP // 2026 OFFICIAL RACING ENGINE", Vector2(360, 680), 34.0)
	
	img.save_png("assets/textures/environments/tex_ref_billboard_art.png")

func draw_bold_text(img: Image, text: String, start: Vector2, font_h: float):
	var char_w = font_h * 0.64
	var stroke = font_h * 0.22
	for c_idx in range(text.length()):
		var ch = text[c_idx]
		var pos = start + Vector2(c_idx * (char_w + stroke * 0.32), 0)
		for y in range(int(pos.y), int(pos.y + font_h)):
			if y < 0 or y >= 1024: continue
			var ny = float(y - pos.y) / font_h
			var shear_x = (ny - 0.5) * -0.22 * font_h
			for x in range(int(pos.x + shear_x), int(pos.x + shear_x + char_w)):
				if x < 0 or x >= 2048: continue
				var nx = float(x - (pos.x + shear_x)) / char_w
				var lit = false
				match ch:
					"R": if nx < 0.26 or (ny < 0.24 and nx < 0.85) or (ny > 0.38 and ny < 0.58 and nx < 0.85) or (nx > 0.64 and ny < 0.52) or (ny >= 0.50 and abs(nx - 0.26 - (ny - 0.50)*1.3) < 0.24): lit = true
					"A": if (ny < 0.24 and nx > 0.2 and nx < 0.8) or abs(nx - (0.5 - (1.0-ny)*0.4)) < 0.18 or abs(nx - (0.5 + (1.0-ny)*0.4)) < 0.18 or (ny > 0.55 and ny < 0.72 and nx > 0.22 and nx < 0.78): lit = true
					"C": if nx < 0.26 or (ny < 0.24 and nx < 0.9) or (ny > 0.76 and nx < 0.9): lit = true
					"I": if abs(nx - 0.5) < 0.18 or (ny < 0.24 and nx > 0.1 and nx < 0.9) or (ny > 0.76 and nx > 0.1 and nx < 0.9): lit = true
					"N": if nx < 0.26 or nx > 0.74 or abs(nx - ny) < 0.22: lit = true
					"G": if nx < 0.26 or (ny < 0.24 and nx < 0.9) or (ny > 0.76 and nx < 0.9) or (nx > 0.70 and ny > 0.48) or (ny > 0.48 and ny < 0.68 and nx > 0.42): lit = true
					"M": if nx < 0.24 or nx > 0.76 or (ny < 0.68 and (abs(nx - ny*0.6) < 0.18 or abs(nx - (1.0 - ny*0.6)) < 0.18)): lit = true
					"E": if nx < 0.26 or (ny < 0.24 and nx < 0.9) or (ny > 0.40 and ny < 0.58 and nx < 0.76) or (ny > 0.76 and nx < 0.9): lit = true
				if lit:
					img.set_pixel(x, y, Color(1.0, 0.98, 0.95, 1.0))
					if ny < 0.16 or nx < 0.14:
						img.set_pixel(x, y, Color(1.0, 0.85, 0.25, 1.0))

func draw_sub_text(img: Image, text: String, start: Vector2, font_h: float):
	var char_w = font_h * 0.54
	for c_idx in range(text.length()):
		var ch = text[c_idx]
		var pos = start + Vector2(c_idx * (char_w + 3), 0)
		for y in range(int(pos.y), int(pos.y + font_h)):
			if y < 0 or y >= 1024: continue
			for x in range(int(pos.x), int(pos.x + char_w)):
				if x < 0 or x >= 2048: continue
				img.set_pixel(x, y, Color(0.96, 0.85, 0.35, 0.9))

# =============================================================================
# 2. LEFT HQ BUILDING (Realistic dark composite panels + warm ribbon office lights)
# =============================================================================
func generate_building_left_hq_perfect():
	var w = 1024
	var h = 1024
	var albedo = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emission = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	albedo.fill(Color(0.13, 0.14, 0.16, 1.0)) # Dark architectural slate
	emission.fill(Color(0, 0, 0, 1.0))
	
	var bands = [
		{"y0": 90, "y1": 240},
		{"y0": 320, "y1": 470},
		{"y0": 550, "y1": 700},
		{"y0": 780, "y1": 930}
	]
	
	for b in bands:
		var y0 = b["y0"]
		var y1 = b["y1"]
		for y in range(y0, y1):
			for x in range(w):
				var in_mullion = (x % 64 < 7)
				if in_mullion:
					albedo.set_pixel(x, y, Color(0.06, 0.06, 0.08, 1.0))
				else:
					var room_id = int(x / 64) + int(y / 150) * 17
					var is_lit = (room_id % 6 != 2)
					if is_lit:
						var warm_amber = Color(0.95, 0.72, 0.32, 1.0)
						# Desk silhouette
						if y > y1 - 25 and (x % 64 > 14 and x % 64 < 50):
							warm_amber = warm_amber * 0.3
						albedo.set_pixel(x, y, warm_amber * 0.45)
						emission.set_pixel(x, y, warm_amber * 0.85)
					else:
						albedo.set_pixel(x, y, Color(0.04, 0.05, 0.08, 1.0))
						
	albedo.save_png("assets/textures/environments/tex_ref_building_left_albedo.png")
	emission.save_png("assets/textures/environments/tex_ref_building_left_emission.png")

# =============================================================================
# 3. RIGHT TOWER (Luxury glass & concrete curtain wall with glowing lobby)
# =============================================================================
func generate_building_right_tower_perfect():
	var w = 1024
	var h = 1024
	var albedo = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emission = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	albedo.fill(Color(0.15, 0.16, 0.18, 1.0))
	emission.fill(Color(0, 0, 0, 1.0))
	
	# Ground & Mezzanine Lobby (y: 580..960)
	for y in range(580, 960):
		for x in range(w):
			var is_column = (x % 220 < 24)
			if is_column:
				albedo.set_pixel(x, y, Color(0.24, 0.25, 0.28, 1.0))
			else:
				var in_frame = (x % 55 < 5) or (y % 190 < 8)
				if in_frame:
					albedo.set_pixel(x, y, Color(0.08, 0.08, 0.10, 1.0))
				else:
					var warm_glow = Color(0.96, 0.80, 0.46, 1.0)
					var fall = 1.0 - float(y - 580) / 420.0 * 0.3
					albedo.set_pixel(x, y, warm_glow * fall * 0.5)
					emission.set_pixel(x, y, warm_glow * fall * 0.90)
					
	# Upper office floors (y: 50..540)
	for y in range(50, 540):
		var in_slab = (y % 120 < 18)
		for x in range(w):
			if in_slab or (x % 110 < 12):
				albedo.set_pixel(x, y, Color(0.18, 0.19, 0.22, 1.0))
			else:
				var upper_c = Color(0.92, 0.75, 0.42, 1.0)
				albedo.set_pixel(x, y, upper_c * 0.4)
				emission.set_pixel(x, y, upper_c * 0.75)
				
	albedo.save_png("assets/textures/environments/tex_ref_building_right_albedo.png")
	emission.save_png("assets/textures/environments/tex_ref_building_right_emission.png")

# =============================================================================
# 4. DARK WET TARMAC ASPHALT
# =============================================================================
func generate_asphalt_perfect():
	var s = 1024
	var albedo = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var roughness = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var normal = Image.create(s, s, false, Image.FORMAT_RGBA8)
	
	var fn = FastNoiseLite.new()
	fn.seed = 303
	fn.frequency = 0.28
	
	var pn = FastNoiseLite.new()
	pn.seed = 404
	pn.frequency = 0.012
	
	for y in range(s):
		for x in range(s):
			var nf = fn.get_noise_2d(float(x), float(y))
			var np = pn.get_noise_2d(float(x), float(y))
			
			# Rich dark charcoal tarmac
			var v = 0.08 + nf * 0.015
			albedo.set_pixel(x, y, Color(v * 0.96, v * 0.98, v * 1.02, 1.0))
			
			# Wet sheen: puddle factor (smooth 0.12..0.22, damp gravel 0.45..0.60)
			var puddle = clamp((np + 0.10) * 1.6, 0.0, 1.0)
			var r = lerp(0.55 + nf * 0.06, 0.14 + nf * 0.03, puddle)
			roughness.set_pixel(x, y, Color(r, r, r, 1.0))
			
			var nx = fn.get_noise_2d(float(x) + 400.0, float(y)) * 0.18 * (1.0 - puddle * 0.7)
			var ny = fn.get_noise_2d(float(x), float(y) + 400.0) * 0.18 * (1.0 - puddle * 0.7)
			var nz = sqrt(max(0.01, 1.0 - nx*nx - ny*ny))
			normal.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
			
	albedo.save_png("assets/textures/environments/tex_ref_asphalt_albedo.png")
	roughness.save_png("assets/textures/environments/tex_ref_asphalt_roughness.png")
	normal.save_png("assets/textures/environments/tex_ref_asphalt_normal.png")

# =============================================================================
# 5. DRAINAGE GRATE
# =============================================================================
func generate_drainage_grate_perfect():
	var w = 128
	var h = 512
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.10, 0.10, 0.12, 1.0))
	for y in range(h):
		var sy = y % 16
		var in_slot = (sy >= 3 and sy <= 8)
		for x in range(w):
			if x > 16 and x < w - 16 and in_slot:
				img.set_pixel(x, y, Color(0.02, 0.02, 0.02, 1.0))
			elif x == 16 or x == w - 16 or sy == 2 or sy == 9:
				img.set_pixel(x, y, Color(0.30, 0.32, 0.36, 1.0))
	img.save_png("assets/textures/environments/tex_ref_drainage_grate.png")

# =============================================================================
# 6. BANNER & PALM
# =============================================================================
func generate_banner_perfect():
	var w = 256
	var h = 768
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.78, 0.10, 0.14, 1.0))
	for y in range(36):
		for x in range(w):
			var chk = (int(x / 18) + int(y / 18)) % 2
			img.set_pixel(x, y, Color.WHITE if chk == 0 else Color(0.08, 0.08, 0.08, 1.0))
	for y in range(732, 768):
		for x in range(w):
			var chk = (int(x / 18) + int(y / 18)) % 2
			img.set_pixel(x, y, Color.WHITE if chk == 0 else Color(0.08, 0.08, 0.08, 1.0))
	# White "R"
	for y in range(220, 460):
		for x in range(48, 208):
			var nx = float(x - 48) / 160.0
			var ny = float(y - 220) / 240.0
			var lit = false
			if nx < 0.28: lit = true
			elif (ny < 0.24 and nx < 0.85) or (ny > 0.42 and ny < 0.62 and nx < 0.85): lit = true
			elif nx > 0.62 and ny < 0.55: lit = true
			elif ny >= 0.52 and abs(nx - 0.28 - (ny - 0.52)*1.3) < 0.22: lit = true
			if lit:
				img.set_pixel(x, y, Color.WHITE)
	img.save_png("assets/textures/environments/tex_ref_racing_banner.png")

func generate_palm_perfect():
	var w = 512
	var h = 1024
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var ny = float(y) / float(h)
		var cx = 256.0 + sin(ny * 2.6) * 50.0
		var stem_w = (1.0 - ny * 0.7) * 7.0
		var max_spread = sin(ny * 3.14159) * 200.0
		for x in range(w):
			var dx = abs(x - cx)
			if dx < max_spread:
				var rib = sin(float(x) * 0.5 + float(y) * 0.65) * 0.5 + 0.5
				if rib > 0.22:
					var col = lerp(Color(0.14, 0.24, 0.08, 0.96), Color(0.26, 0.45, 0.14, 0.98), ny)
					img.set_pixel(x, y, col)
			if dx <= stem_w:
				img.set_pixel(x, y, Color(0.42, 0.38, 0.22, 1.0))
	img.save_png("assets/textures/environments/tex_ref_palm_leaf.png")
