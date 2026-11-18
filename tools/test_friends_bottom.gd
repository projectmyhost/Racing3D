@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	var full_fr = img.get_region(Rect2i(1530, 570, 360, 310))
	full_fr.save_png("assets/ui/textures/friends_card_test_long.png")
	print("Saved test long")
	quit(0)

