@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Left buttons strip: x from 0 to 600, y from 270 to 860
	var left_strip = img.get_region(Rect2i(0, 270, 600, 590))
	left_strip.save_png("assets/ui/textures/left_buttons_strip.png")

	print("Saved left buttons strip")
	quit(0)

