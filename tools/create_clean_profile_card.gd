@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("assets/ui/profile_card_ref.jpg")
	if not img:
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Key out black background around the card
	for y in range(h):
		for x in range(w):
			var c = img.get_pixel(x, y)
			var lum = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.04 and c.b < 0.08:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif lum < 0.12 and c.b < 0.15:
				var a = clampf((lum - 0.04) / 0.08, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))

	# Patch entire middle info area (X: 250 to 680, Y: 40 to 215) with rich navy blue gradient
	for y in range(40, 215):
		var t = float(y - 40) / (215.0 - 40.0)
		var bg_c = Color(0.10, 0.22, 0.52).lerp(Color(0.04, 0.10, 0.30), t)
		for x in range(250, 680):
			img.set_pixel(x, y, bg_c)

	# Patch Level badge number inside the yellow pill (X: 780 to 960, Y: 105 to 185)
	for y in range(105, 185):
		var t = float(y - 105) / (185.0 - 105.0)
		var badge_c = Color(0.99, 0.74, 0.14).lerp(Color(0.94, 0.57, 0.05), t)
		for x in range(780, 960):
			img.set_pixel(x, y, badge_c)
			
	# Patch XP bar slot (X: 228 to 595, Y: 226 to 268) with dark navy slot color
	for y in range(226, 268):
		var t = float(y - 226) / (268.0 - 226.0)
		var slot_c = Color(0.06, 0.09, 0.20).lerp(Color(0.04, 0.06, 0.15), t)
		for x in range(228, 595):
			img.set_pixel(x, y, slot_c)

	# Patch XP text area (X: 730 to 980, Y: 225 to 268) with card navy background
	for y in range(225, 268):
		for x in range(730, 980):
			img.set_pixel(x, y, Color(0.06, 0.11, 0.28))

	img.save_png("assets/ui/profile_card_bg_clean.png")
	print("Saved clean assets/ui/profile_card_bg_clean.png!")
	quit(0)
