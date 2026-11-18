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
			var inside = false
			# Circle avatar on left
			var dx = x - 70.0
			var dy = y - 72.0
			if dx * dx + dy * dy <= 67.0 * 67.0:
				inside = true
			# Main pill body
			if x >= 70 and x <= 495 and y >= 26 and y <= 140:
				inside = true
			# Top category tab
			if x >= 115 and x <= 315 and y >= 14 and y <= 28:
				inside = true
			# Top right checkered tab
			if x >= 370 and x <= 495 and y >= 6 and y <= 35:
				# Slanted right edge
				if x - (35 - y) * 0.5 <= 495:
					inside = true
			# Amateur tier badge hanging at bottom
			if x >= 115 and x <= 345 and y >= 138 and y <= 178:
				inside = true

			if not inside:
				# Smooth falloff for anti-aliasing near border
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png("assets/ui/textures/profile_card_clean_alpha.png")
	print("Saved profile_card_clean_alpha.png")
	quit(0)

