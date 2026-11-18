@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Crop profile card including tier badge
	var prof = img.get_region(Rect2i(35, 30, 505, 180))
	prof.save_png("assets/ui/textures/profile_card_1080p.png")
	print("Saved profile_card_1080p.png")
	quit(0)

