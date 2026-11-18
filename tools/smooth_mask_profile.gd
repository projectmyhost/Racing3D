@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("assets/ui/textures/profile_card_1080p.png")
	if not img: quit(1)
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	for y in range(h):
		for x in range(w):
			var d_min = 999.0
			
			# 1. Circle avatar
			var dx = x - 69.0
			var dy = y - 71.0
			var d_circle = sqrt(dx*dx + dy*dy) - 67.5
			d_min = min(d_min, d_circle)
			
			# 2. Main pill
			var d_pill = -999.0
			if x >= 65 and x <= 495 and y >= 25 and y <= 138:
				# rounded right cap
				if x > 480:
					var rx = x - 480.0
					var ry = abs(y - 81.5) - (56.5 - 15.0)
					if ry > 0:
						d_pill = sqrt(rx*rx + ry*ry) - 15.0
					else:
						d_pill = rx - 15.0
				else:
					d_pill = -1.0
				d_min = min(d_min, d_pill)
				
			# 3. Category tab
			if x >= 122 and x <= 315 and y >= 14 and y <= 26:
				d_min = min(d_min, -1.0)
				
			# 4. Checkered tab
			if x >= 365 and x <= 492 and y >= 6 and y <= 35:
				var slant_x = 475.0 + (35 - y) * 0.45
				if x <= slant_x:
					d_min = min(d_min, -1.0)
					
			# 5. Tier badge
			if x >= 115 and x <= 344 and y >= 136 and y <= 176:
				var slant_rx = 344.0 - (y - 136) * 0.35
				if x <= slant_rx:
					d_min = min(d_min, -1.0)
					
			var alpha = clamp(1.0 - (d_min + 0.5), 0.0, 1.0)
			var col = img.get_pixel(x, y)
			col.a *= alpha
			img.set_pixel(x, y, col)

	img.save_png("assets/ui/textures/profile_card_clean_alpha.png")
	print("Saved anti-aliased profile_card_clean_alpha.png")
	quit(0)

