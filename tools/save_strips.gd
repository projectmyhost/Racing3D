@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Full bottom bar strip: y from 850 to 1080
	var bot_strip = img.get_region(Rect2i(0, 850, 1920, 230))
	bot_strip.save_png("assets/ui/textures/bottom_full_strip.png")

	# Right full strip: x from 1450 to 1920, y from 150 to 1080
	var right_strip = img.get_region(Rect2i(1450, 150, 470, 930))
	right_strip.save_png("assets/ui/textures/right_full_strip.png")

	print("Saved full strips")
	quit(0)

