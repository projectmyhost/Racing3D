@tool
extends SceneTree

func _init():
	print("Regenerating building textures with warm architectural ambient...")
	
	# 1. Left HQ Building Facade Texture
	var w = 1024
	var h = 1024
	var albedo_l = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emission_l = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	albedo_l.fill(Color(0.12, 0.13, 0.15, 1.0)) # Dark architectural slate composite
	emission_l.fill(Color(0, 0, 0, 1.0))
	
	var floors_l = [
		{"y0": 80, "y1": 220},
		{"y0": 290, "y1": 430},
		{"y0": 500, "y1": 640},
		{"y0": 720, "y1": 890}
	]
	
	for fl in floors_l:
		var y0 = fl["y0"]
		var y1 = fl["y1"]
		for y in range(y0, y1):
			for x in range(w):
				var in_mullion = (x % 56 < 6)
				if in_mullion:
					albedo_l.set_pixel(x, y, Color(0.07, 0.07, 0.08, 1.0))
				else:
					# Warm golden office glow (not blown out)
					var room_id = int(x / 56) + int(y / 120) * 19
					var is_lit = (room_id % 7 != 2) # ~85% lit
					if is_lit:
						var glow_var = 0.75 + sin(float(x) * 0.08) * 0.15
						var warm_gold = Color(0.95, 0.72, 0.35, 1.0) * glow_var
						# Lower edge desk silhouette
						if y > y1 - 22 and (x % 56 > 12 and x % 56 < 44):
							warm_gold = warm_gold * 0.35
						albedo_l.set_pixel(x, y, warm_gold * 0.6)
						emission_l.set_pixel(x, y, warm_gold * 0.9)
					else:
						albedo_l.set_pixel(x, y, Color(0.04, 0.05, 0.08, 1.0))
						
	albedo_l.save_png("assets/textures/environments/tex_ref_building_left_albedo.png")
	emission_l.save_png("assets/textures/environments/tex_ref_building_left_emission.png")
	
	# 2. Right Commercial Tower Facade Texture
	var albedo_r = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emission_r = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	albedo_r.fill(Color(0.14, 0.15, 0.17, 1.0))
	emission_r.fill(Color(0, 0, 0, 1.0))
	
	# Lower 2 floors: Double-height glass curtain wall lobby (y: 600..960)
	for y in range(600, 960):
		for x in range(w):
			var is_col = (x % 210 < 22)
			if is_col:
				albedo_r.set_pixel(x, y, Color(0.20, 0.21, 0.24, 1.0))
			else:
				var in_glass_frame = (x % 52 < 4) or (y % 180 < 6)
				if in_glass_frame:
					albedo_r.set_pixel(x, y, Color(0.08, 0.08, 0.10, 1.0))
				else:
					# Warm interior illumination
					var lobby_col = Color(0.96, 0.82, 0.52, 1.0)
					var falloff = 1.0 - float(y - 600) / 400.0 * 0.35
					var final_c = lobby_col * falloff
					albedo_r.set_pixel(x, y, final_c * 0.6)
					emission_r.set_pixel(x, y, final_c * 1.0)
					
	# Upper office floors (y: 60..560)
	for y in range(60, 560):
		var in_slab = (y % 125 < 18)
		for x in range(w):
			if in_slab or (x % 105 < 10):
				albedo_r.set_pixel(x, y, Color(0.18, 0.19, 0.22, 1.0))
			else:
				var upper_col = Color(0.92, 0.78, 0.48, 1.0)
				albedo_r.set_pixel(x, y, upper_col * 0.5)
				emission_r.set_pixel(x, y, upper_col * 0.8)
				
	albedo_r.save_png("assets/textures/environments/tex_ref_building_right_albedo.png")
	emission_r.save_png("assets/textures/environments/tex_ref_building_right_emission.png")
	
	print("Textures updated successfully!")
	quit(0)

