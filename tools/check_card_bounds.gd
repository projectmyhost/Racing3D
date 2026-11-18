@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Full event card: let's try y from 200 to 520 (h=320)
	var ev = img.get_region(Rect2i(1528, 200, 360, 320))
	ev.save_png("assets/ui/textures/event_card_full.png")

	# Full friends card: let's try y from 525 to 810 (h=285)
	var fr = img.get_region(Rect2i(1528, 525, 360, 285))
	fr.save_png("assets/ui/textures/friends_card_full.png")

	print("Saved full card slices")
	quit(0)

