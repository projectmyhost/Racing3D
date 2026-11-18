@tool
extends SceneTree

# Generates enhanced high-contrast premium road texture based on Atomic Realm UV layout

func _init():
	print("--- GENERATING HIGH-CONTRAST PREMIUM ROAD TEXTURE ---")
	var orig = Image.load_from_file("res://assets/models/roads/Road1_B_dotted_white.png")
	if not orig:
		print("ERROR: Could not load original texture")
		quit(1)
		return

	var w = orig.get_width()
	var h = orig.get_height()
	var new_img = Image.create(w, h, false, Image.FORMAT_RGBA8)

	for y in range(h):
		for x in range(w):
			var c = orig.get_pixel(x, y)
			var r = c.r
			var g = c.g
			var b = c.b
			var a = c.a

			if a < 0.1:
				new_img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			# Detect yellow line (high red & green, low blue)
			var is_yellow = (r > 0.7 and g > 0.5 and b < 0.25)
			
			# Detect white lines / dashes (high brightness relative to surroundings)
			var is_white_dash = (r > 0.6 and g > 0.6 and b > 0.6)
			
			# Detect curbs / sidewalks (outside the road boundaries: x < 75 or x > 435)
			var is_curb = (x < 75 or x > 435)

			var out_col: Color
			if is_yellow:
				out_col = Color(1.0, 0.78, 0.10, 1.0) # Vibrant traffic yellow
			elif is_white_dash:
				out_col = Color(0.97, 0.97, 0.98, 1.0) # Bright crisp white markings
			elif is_curb:
				# Clean concrete curb
				var concrete_val = 0.58 + (randf() - 0.5) * 0.04
				out_col = Color(concrete_val, concrete_val * 0.98, concrete_val * 0.95, 1.0)
			else:
				# Dark rich asphalt surface with subtle grain
				var grain = (randf() - 0.5) * 0.025
				var dark_val = 0.16 + grain
				out_col = Color(dark_val, dark_val * 1.02, dark_val * 1.05, 1.0)

			new_img.set_pixel(x, y, out_col)

	new_img.save_png("res://assets/models/roads/Road1_B_premium.png")
	print("SUCCESS: Generated res://assets/models/roads/Road1_B_premium.png")
	quit(0)

