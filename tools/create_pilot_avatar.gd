@tool
extends SceneTree

# Generates a stylized racing pilot helmet / badge avatar for the profile card

func _init():
	print("--- GENERATING RACING PILOT AVATAR ---")
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Dark racing navy/carbon background
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x - size/2, y - size/2).length()
			# Subtle carbon fiber diagonal pattern
			var pattern = 1.0 if ((x + y) % 8 < 4) else 0.94
			var bg_val = 0.08 * pattern
			var col = Color(bg_val * 0.9, bg_val, bg_val * 1.3, 1.0)
			
			# Outer gold circular ring badge
			if dist > 115.0 and dist <= 124.0:
				var gold_t = (float(x) + float(y)) / float(size * 2)
				col = Color(0.98, 0.78 + gold_t * 0.15, 0.15, 1.0)
			elif dist > 124.0:
				col = Color(0, 0, 0, 0)
			
			img.set_pixel(x, y, col)

	# Draw stylized Racing Helmet silhouette
	for y in range(50, 200):
		for x in range(60, 196):
			var cx = float(x - 128)
			var cy = float(y - 120)
			
			# Main helmet outer dome
			var dome = (cx * cx) / (55.0 * 55.0) + (cy * cy) / (52.0 * 52.0)
			if dome <= 1.0:
				# Red Bull dark racing blue body
				var helmet_col = Color(0.12, 0.16, 0.28, 1.0)
				
				# Crimson racing stripes on top
				if abs(cx) < 14.0 and cy < 0.0:
					helmet_col = Color(0.92, 0.15, 0.15, 1.0)
				elif abs(cx) < 18.0 and cy < 0.0:
					helmet_col = Color(1.0, 0.82, 0.12, 1.0)

				# Visor area (glossy gold-tinted aerodynamic visor)
				var visor_dome = (cx * cx) / (46.0 * 46.0) + ((cy - 6.0) * (cy - 6.0)) / (22.0 * 22.0)
				if visor_dome <= 1.0 and cy > -10.0 and cy < 24.0:
					# Gradient reflection on visor
					var visor_t = (float(y) - 110.0) / 34.0
					helmet_col = Color(0.18 + visor_t * 0.4, 0.15 + visor_t * 0.35, 0.08, 1.0)
					if abs(cy - 2.0) < 3.0:
						# Bright specular reflection glint on visor
						helmet_col = Color(1.0, 0.92, 0.70, 1.0)
					if cy > 18.0:
						helmet_col = Color(0.85, 0.70, 0.15, 1.0) # Visor lower edge strip

				# Chin bar aero vents
				if cy > 32.0 and cy < 46.0:
					if abs(cx) < 28.0 and (int(cx) % 10 < 5):
						helmet_col = Color(0.04, 0.05, 0.08, 1.0)

				img.set_pixel(x, y, helmet_col)

	img.save_png("res://assets/ui/icons/avatar_pilot_racing.png")
	print("SUCCESS: Saved res://assets/ui/icons/avatar_pilot_racing.png")
	quit(0)

