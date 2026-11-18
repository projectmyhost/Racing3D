@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Top right header strip: x from 1350 to 1920, y from 0 to 180
	var tr_strip = img.get_region(Rect2i(1350, 0, 570, 180))
	tr_strip.save_png("assets/ui/textures/top_right_strip.png")

	# Top left profile strip: x from 0 to 580, y from 0 to 240
	var tl_strip = img.get_region(Rect2i(0, 0, 580, 240))
	tl_strip.save_png("assets/ui/textures/top_left_strip.png")

	print("Saved top strips")
	quit(0)

