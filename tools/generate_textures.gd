@tool
extends SceneTree

func _init():
	print("Starting enhanced realistic texture generation...")
	generate_badge()
	generate_paint_detail()
	generate_window_atlas()
	generate_building_facades()
	generate_billboard_art()
	generate_palm_leaf()
	generate_asphalt_textures()
	print("All enhanced textures generated successfully!")
	quit()

func generate_badge():
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center = Vector2(128, 128)
	for y in range(256):
		for x in range(256):
			var pos = Vector2(x, y)
			# Outer shield / hexagon
			var dx = abs(pos.x - 128)
			var dy = abs(pos.y - 128)
			if dx < 90 and dy < 60 and (dx * 0.7 + dy * 0.9) < 95:
				# Border
				var edge = (dx * 0.7 + dy * 0.9)
				if edge > 85 or dx > 82 or dy > 52:
					img.set_pixel(x, y, Color(0.9, 0.9, 0.95, 1.0)) # Chrome rim
				else:
					# Dark metallic background
					img.set_pixel(x, y, Color(0.1, 0.1, 0.12, 1.0))
					
			# Geometric "SR" monogram in center
			# S: left side
			var is_s = false
			if x >= 65 and x <= 115 and y >= 90 and y <= 165:
				if (y >= 90 and y <= 104) or (y >= 122 and y <= 134) or (y >= 152 and y <= 165):
					is_s = true
				elif (y < 128 and x >= 65 and x <= 78) or (y > 128 and x >= 102 and x <= 115):
					is_s = true
			# R: right side
			var is_r = false
			if x >= 135 and x <= 190 and y >= 90 and y <= 165:
				if x >= 135 and x <= 149:
					is_r = true
				elif (y >= 90 and y <= 104) or (y >= 122 and y <= 134):
					if x <= 180: is_r = true
				elif x >= 170 and x <= 185 and y >= 95 and y <= 128:
					is_r = true
				elif y > 130 and abs((x - 145) - (y - 130) * 1.1) < 10:
					is_r = true
			
			if is_s or is_r:
				img.set_pixel(x, y, Color(0.95, 0.2, 0.2, 1.0)) # Red racing monogram
	img.save_png("assets/textures/vehicles/tex_veh_showcase_badge.png")

func generate_paint_detail():
	# Micro flake / orange peel normal map
	var img = Image.create(512, 512, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.08
	for y in range(512):
		for x in range(512):
			var nx = noise.get_noise_2d(float(x), float(y)) * 0.15
			var ny = noise.get_noise_2d(float(x) + 500.0, float(y) + 500.0) * 0.15
			var nz = sqrt(max(0.0, 1.0 - nx*nx - ny*ny))
			var col = Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0)
			img.set_pixel(x, y, col)
	img.save_png("assets/textures/vehicles/tex_veh_paint_detail_01.png")

func generate_window_atlas():
	var img = Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.07, 0.12, 1.0)) # Dark skyscraper glass
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337
	
	# Create several building window grids across the atlas
	var win_w = 6
	var win_h = 10
	var gap_x = 4
	var gap_y = 6
	
	for col_idx in range(0, 2048, 30):
		for row_idx in range(50, 1000, 20):
			if rng.randf() < 0.42: # 42% of windows are lit
				var brightness = rng.randf_range(0.5, 1.0)
				# Warm amber or golden white
				var warm_tint = rng.randf_range(0.7, 1.0)
				var win_col = Color(1.0 * brightness, (0.85 * warm_tint) * brightness, (0.6 * warm_tint) * brightness, 1.0)
				for wy in range(win_h):
					for wx in range(win_w):
						if col_idx + wx < 2048 and row_idx + wy < 1024:
							img.set_pixel(col_idx + wx, row_idx + wy, win_col)
	img.save_png("assets/textures/environments/tex_env_windows_atlas_2k.png")

func generate_billboard_art():
	# 2048x1024: Billboard featuring "Racing Game" in motorsport bold typography
	var img = Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
	# Dark sunset carbon/slate background with gradient
	for y in range(1024):
		var ny = float(y) / 1024.0
		for x in range(2048):
			var nx = float(x) / 2048.0
			var v = sin(float(x) * 0.015) * 0.02
			# Carbon weave pattern
			var weave = ((int(x / 4) + int(y / 4)) % 2) * 0.018
			var bg_col = Color(0.10 + v + weave + ny * 0.06, 0.08 + v * 0.4 + weave, 0.12 + v * 0.6 + weave, 1.0)
			img.set_pixel(x, y, bg_col)
			
	# Red & gold dynamic speed slashes
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(16):
		var slash_x = rng.randf_range(200, 1900)
		var slash_w = rng.randf_range(35, 120)
		var is_gold = (i % 3 == 0)
		for y in range(1024):
			var sx = slash_x + (y - 512) * 0.65
			for ox in range(-int(slash_w * 0.5), int(slash_w * 0.5)):
				var px = int(sx + ox)
				if px >= 0 and px < 2048:
					var dist = float(abs(ox)) / (slash_w * 0.5)
					if dist < 1.0:
						var a = (1.0 - dist * dist) * 0.8
						var cur = img.get_pixel(px, y)
						var slash_col = Color(0.95, 0.72, 0.12, 1.0) if is_gold else Color(0.88, 0.12, 0.18, 1.0)
						img.set_pixel(px, y, cur.lerp(slash_col, a))

	# Prominently render "RACING" and "GAME"
	draw_bold_word(img, "RACING", Vector2(300, 260), 280.0, -0.22, Color(1.0, 0.98, 0.92, 1.0))
	draw_bold_word(img, "GAME", Vector2(480, 580), 300.0, -0.22, Color(1.0, 0.80, 0.18, 1.0))
	
	# Top & Bottom Championship border banners
	for y in range(0, 50):
		for x in range(2048):
			var check = (int(x / 40) + int(y / 25)) % 2
			var c_col = Color(0.95, 0.8, 0.15, 1.0) if check == 0 else Color(0.12, 0.12, 0.14, 1.0)
			img.set_pixel(x, y, c_col)
	for y in range(974, 1024):
		for x in range(2048):
			var check = (int(x / 40) + int(y / 25)) % 2
			var c_col = Color(0.95, 0.8, 0.15, 1.0) if check == 0 else Color(0.12, 0.12, 0.14, 1.0)
			img.set_pixel(x, y, c_col)
	
	img.save_png("assets/textures/environments/tex_env_billboard_art_01.png")

func draw_bold_word(img: Image, text: String, start_pos: Vector2, font_size: float, shear: float, col: Color = Color.WHITE):
	var char_w = font_size * 0.68
	var stroke = font_size * 0.18
	for c_idx in range(text.length()):
		var ch = text[c_idx]
		var c_pos = start_pos + Vector2(c_idx * (char_w + stroke * 0.4), 0)
		draw_char(img, ch, c_pos, char_w, font_size, stroke, shear, col)

func draw_char(img: Image, ch: String, pos: Vector2, w: float, h: float, stroke: float, shear: float, font_col: Color = Color.WHITE):
	var min_y = int(pos.y)
	var max_y = int(pos.y + h)
	for y in range(min_y, max_y):
		if y < 0 or y >= 1024: continue
		var ny = float(y - pos.y) / h # 0..1
		var ox = (ny - 0.5) * shear * h
		var px_start = int(pos.x + ox)
		var px_end = int(pos.x + ox + w)
		
		for x in range(px_start - int(stroke), px_end + int(stroke)):
			if x < 0 or x >= 2048: continue
			var nx = float(x - (pos.x + ox)) / w # 0..1
			var is_lit = false
			match ch:
				"R":
					if nx >= 0.0 and nx <= stroke/w: is_lit = true
					elif (ny >= 0.0 and ny <= stroke/h) or (ny >= 0.45 and ny <= (0.45 + stroke/h)):
						if nx <= 0.85: is_lit = true
					elif nx >= (0.85 - stroke/w) and nx <= 0.95 and ny <= 0.5: is_lit = true
					elif ny > 0.48 and abs((nx - 0.15) - (ny - 0.48) * 1.5) <= stroke/w: is_lit = true
				"A":
					if ny >= 0.0 and ny <= stroke/h and nx >= 0.2 and nx <= 0.8: is_lit = true
					elif abs(nx - (0.5 - (1.0-ny)*0.45)) <= stroke/w * 0.8: is_lit = true
					elif abs(nx - (0.5 + (1.0-ny)*0.45)) <= stroke/w * 0.8: is_lit = true
					elif ny >= 0.55 and ny <= (0.55 + stroke/h) and nx >= 0.25 and nx <= 0.75: is_lit = true
				"C":
					if nx >= 0.0 and nx <= stroke/w: is_lit = true
					elif (ny >= 0.0 and ny <= stroke/h) or (ny >= (1.0 - stroke/h) and ny <= 1.0):
						if nx <= 0.95: is_lit = true
					elif nx >= (0.95 - stroke/w) and (ny <= 0.25 or ny >= 0.75): is_lit = true
				"I":
					if nx >= (0.5 - stroke/w*0.5) and nx <= (0.5 + stroke/w*0.5): is_lit = true
					elif (ny >= 0.0 and ny <= stroke/h) or (ny >= (1.0 - stroke/h) and ny <= 1.0):
						if nx >= 0.1 and nx <= 0.9: is_lit = true
				"N":
					if nx >= 0.0 and nx <= stroke/w: is_lit = true
					elif nx >= (1.0 - stroke/w) and nx <= 1.0: is_lit = true
					elif abs(nx - ny) <= stroke/w * 0.75: is_lit = true
				"G":
					if nx >= 0.0 and nx <= stroke/w: is_lit = true
					elif (ny >= 0.0 and ny <= stroke/h) or (ny >= (1.0 - stroke/h) and ny <= 1.0):
						if nx <= 0.95: is_lit = true
					elif nx >= (0.95 - stroke/w) and (ny <= 0.25 or ny >= 0.5): is_lit = true
					elif ny >= 0.5 and ny <= (0.5 + stroke/h) and nx >= 0.5 and nx <= 0.95: is_lit = true
				"M":
					if nx >= 0.0 and nx <= stroke/w: is_lit = true
					elif nx >= (1.0 - stroke/w) and nx <= 1.0: is_lit = true
					elif ny <= 0.65 and abs(nx - ny * 0.75) <= stroke/w * 0.7: is_lit = true
					elif ny <= 0.65 and abs(nx - (1.0 - ny * 0.75)) <= stroke/w * 0.7: is_lit = true
				"E":
					if nx >= 0.0 and nx <= stroke/w: is_lit = true
					elif (ny >= 0.0 and ny <= stroke/h) or (ny >= 0.45 and ny <= (0.45 + stroke/h)) or (ny >= (1.0 - stroke/h) and ny <= 1.0):
						if nx <= 0.9: is_lit = true
			
			if is_lit:
				var noise_val = sin(float(x)*0.3) * cos(float(y)*0.4)
				var alpha = clamp(0.92 + noise_val * 0.12, 0.0, 1.0)
				var pixel_col = font_col
				pixel_col.a = alpha
				img.set_pixel(x, y, pixel_col)
			
			if is_lit:
				# Brush texture grunge
				var noise_val = sin(float(x)*0.3) * cos(float(y)*0.4)
				var alpha = clamp(0.9 + noise_val * 0.15, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 0.98, 0.96, alpha))

func generate_palm_leaf():
	var img = Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Central arching rachis/stem
	for y in range(1024):
		var ny = float(y) / 1024.0
		var stem_x = 512.0 + sin(ny * 2.5) * 140.0
		# Leaflets branching out
		for angle_sign in [-1.0, 1.0]:
			var leaflet_len = sin(ny * 3.14159) * 280.0
			for d in range(int(leaflet_len)):
				var lx = stem_x + angle_sign * d * cos(0.35)
				var ly = y + d * sin(0.35) * 0.5
				if lx >= 0 and lx < 1024 and ly >= 0 and ly < 1024:
					var leaf_col = Color(0.18, 0.29, 0.17, 1.0)
					if d < 15:
						leaf_col = Color(0.28, 0.38, 0.22, 1.0) # Stem tint
					img.set_pixel(int(lx), int(ly), leaf_col)
	img.save_png("assets/textures/environments/tex_env_palm_leaf_1k.png")

func generate_building_facades():
	# 1. Commercial Motorsport Headquarters & Showroom Facade (2048x1024)
	var img1 = Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
	img1.fill(Color(0.12, 0.13, 0.16, 1.0)) # Dark architectural concrete
	
	# Horizontal floor dividers
	for floor_y in [180, 360, 540, 720]:
		for fy in range(floor_y - 8, floor_y + 8):
			for x in range(2048):
				img1.set_pixel(x, fy, Color(0.24, 0.26, 0.32, 1.0))
				
	# Vertical structural columns every 256 px
	for col_x in range(0, 2048, 256):
		for cx in range(col_x - 12, col_x + 12):
			for y in range(1024):
				var px = posmod(cx, 2048)
				img1.set_pixel(px, y, Color(0.20, 0.22, 0.27, 1.0))

	# Upper floor illuminated office & penthouse windows
	var rng = RandomNumberGenerator.new()
	rng.seed = 2026
	for col_x in range(0, 2048, 256):
		for floor_idx in range(4):
			var wy_start = floor_idx * 180 + 35
			var wy_end = floor_idx * 180 + 155
			for win_x in range(col_x + 25, col_x + 230, 48):
				var is_lit = rng.randf() < 0.65
				var brightness = rng.randf_range(0.6, 1.0)
				var win_col = Color(1.0 * brightness, 0.88 * brightness, 0.65 * brightness, 1.0) if is_lit else Color(0.08, 0.09, 0.12, 1.0)
				for y in range(wy_start, wy_end):
					for x in range(win_x, win_x + 36):
						if x < 2048:
							# Window border/mullion
							if x == win_x or x == win_x + 35 or y == wy_start or y == wy_end - 1 or y == int(wy_start + (wy_end - wy_start) * 0.5):
								img1.set_pixel(x, y, Color(0.05, 0.05, 0.07, 1.0))
							else:
								img1.set_pixel(x, y, win_col)

	# Ground Floor Motorsport Showroom (y: 720 to 1024)
	# Large glass showroom display bays with warm spotlights
	for bay_x in range(30, 2000, 320):
		for y in range(760, 1000):
			for x in range(bay_x, bay_x + 270):
				if x < 2048:
					if x == bay_x or x == bay_x + 269 or y == 760 or y == 999:
						img1.set_pixel(x, y, Color(0.9, 0.75, 0.15, 1.0)) # Gold metal framing
					else:
						# Showroom interior gradient
						var ny = float(y - 760) / 240.0
						img1.set_pixel(x, y, Color(0.18 + (1.0 - ny) * 0.45, 0.20 + (1.0 - ny) * 0.45, 0.28 + (1.0 - ny) * 0.5, 1.0))

	# Neon Signage band along 725-755: "APEX MOTORSPORT • PIT SHOWROOM"
	for y in range(725, 755):
		for x in range(2048):
			img1.set_pixel(x, y, Color(0.85, 0.12, 0.18, 1.0)) # Glowing red racing fascia
			
	# Top roof cyan glowing trim
	for y in range(0, 15):
		for x in range(2048):
			img1.set_pixel(x, y, Color(0.1, 0.8, 1.0, 1.0))

	img1.save_png("assets/textures/environments/tex_env_building_facade_01.png")

	# 2. Modern City High-Rise Facade (1024x1024)
	var img2 = Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img2.fill(Color(0.10, 0.11, 0.14, 1.0))
	for y in range(1024):
		for x in range(1024):
			# Window grid
			var wx = x % 48
			var wy = y % 64
			if wx < 36 and wy < 50 and y > 60 and y < 900:
				var grid_id = int(x / 48) * 100 + int(y / 64)
				var lit = (posmod(grid_id * 17, 100) < 55)
				if lit:
					img2.set_pixel(x, y, Color(0.95, 0.82, 0.55, 1.0))
				else:
					img2.set_pixel(x, y, Color(0.06, 0.07, 0.09, 1.0))
			elif wx >= 36 or wy >= 50:
				# Concrete mullion
				img2.set_pixel(x, y, Color(0.22, 0.24, 0.28, 1.0))
				
	# Storefront ground floor (900-1024)
	for y in range(900, 1024):
		for x in range(1024):
			if y < 930:
				img2.set_pixel(x, y, Color(0.95, 0.72, 0.12, 1.0)) # Amber fascia
			else:
				img2.set_pixel(x, y, Color(0.12, 0.15, 0.20, 1.0))
	img2.save_png("assets/textures/environments/tex_env_building_facade_02.png")

func generate_asphalt_textures():
	var size = 1024
	var albedo_img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rough_img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var normal_img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var noise = FastNoiseLite.new()
	noise.seed = 77
	noise.frequency = 0.04
	
	var puddle_noise = FastNoiseLite.new()
	puddle_noise.seed = 101
	puddle_noise.frequency = 0.008
	
	for y in range(size):
		# Dashed center line periodicity: 72 px on, 56 px off
		var is_center_dash = (y % 128) < 72
		# Red/White curb stripe periodicity: 48 px red, 48 px white
		var is_curb_red = (y % 96) < 48
		
		# Skidding tire track curve
		var skid_offset = sin(float(y) * 0.01) * 35.0
		
		for x in range(size):
			var n = noise.get_noise_2d(float(x), float(y)) * 0.06
			var p = puddle_noise.get_noise_2d(float(x), float(y))
			var is_puddle = p > 0.2
			
			# Rich asphalt base (#1E1F24)
			var base_r = 0.13 + n
			var base_g = 0.13 + n
			var base_b = 0.15 + n
			var r_val = 0.38
			
			if is_puddle:
				var puddle_depth = clamp((p - 0.2) * 4.0, 0.0, 1.0)
				r_val = lerp(0.38, 0.04, puddle_depth)
				base_r *= 0.75
				base_g *= 0.75
				base_b *= 0.82

			var col = Color(base_r, base_g, base_b, 1.0)
			
			# 1. White Dashed Center Line (x: 504 to 520)
			if x >= 504 and x <= 520 and is_center_dash:
				col = Color(0.96, 0.96, 0.98, 1.0)
				r_val = 0.32
			
			# 2. Solid White Outer Lane Boundaries (x: 190-204 and x: 820-834)
			elif (x >= 190 and x <= 204) or (x >= 820 and x <= 834):
				col = Color(0.96, 0.96, 0.98, 1.0)
				r_val = 0.32
				
			# 3. Yellow Shoulder Safety Lines (x: 120-132 and x: 892-904)
			elif (x >= 120 and x <= 132) or (x >= 892 and x <= 904):
				col = Color(1.0, 0.78, 0.12, 1.0)
				r_val = 0.35
				
			# 4. Motorsport Apex Kerbs (Left: x < 75, Right: x > 949)
			elif x < 75 or x > 949:
				col = Color(0.85, 0.12, 0.16, 1.0) if is_curb_red else Color(0.95, 0.95, 0.95, 1.0)
				r_val = 0.30
				
			# 5. Tire Rubber Skid Marks (heavy racing brake tracks)
			var track1_dist = abs(x - (360 + skid_offset))
			var track2_dist = abs(x - (640 + skid_offset))
			if (track1_dist < 14.0 or track2_dist < 14.0) and not is_puddle:
				var skid_intensity = clamp(1.0 - min(track1_dist, track2_dist) / 14.0, 0.0, 1.0) * 0.7
				col = col.lerp(Color(0.04, 0.04, 0.05, 1.0), skid_intensity)
				r_val = lerp(r_val, 0.22, skid_intensity)
				
			albedo_img.set_pixel(x, y, col)
			rough_img.set_pixel(x, y, Color(r_val, r_val, r_val, 1.0))
			
			# Normal
			var nx = noise.get_noise_2d(float(x) + 200, float(y)) * (0.05 if is_puddle else 0.18)
			var ny = noise.get_noise_2d(float(x), float(y) + 200) * (0.05 if is_puddle else 0.18)
			var nz = sqrt(max(0.0, 1.0 - nx*nx - ny*ny))
			normal_img.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0))
			
	albedo_img.save_png("assets/textures/environments/tex_env_asphalt_wet_albedo.png")
	rough_img.save_png("assets/textures/environments/tex_env_asphalt_wet_roughness.png")
	normal_img.save_png("assets/textures/environments/tex_env_asphalt_wet_normal.png")
