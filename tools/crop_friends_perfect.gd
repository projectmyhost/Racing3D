@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Friends card: y from 573 to 853 (h=280), x from 1530 to 1890 (w=360)
	var full_fr = img.get_region(Rect2i(1530, 573, 360, 280))
	full_fr.save_png("assets/ui/textures/friends_card_perfect.png")
	print("Saved friends perfect v2")
	quit(0)
