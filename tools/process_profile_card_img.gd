@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("assets/ui/profile_card_ref.jpg")
	if not img:
		quit(1)
		return
		
	# Convert to RGBA8
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Key out black background around the card
	# Sample border pixels (0,0) is black
	for y in range(h):
		for x in range(w):
			var c = img.get_pixel(x, y)
			# If very dark (near black), set alpha to 0.0
			var lum = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.04 and c.b < 0.08:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif lum < 0.12 and c.b < 0.15:
				var a = clampf((lum - 0.04) / 0.08, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
				
	img.save_png("assets/ui/profile_card_bg.png")
	print("Saved assets/ui/profile_card_bg.png with transparency!")
	quit(0)

