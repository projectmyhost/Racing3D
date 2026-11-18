@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Pure car graphic without header text and without NIGHT SPEEDRUN text
	# x from 1538 to 1878 (w=340)
	# y from 252 to 374 (h=122)
	var pure_car = img.get_region(Rect2i(1538, 252, 340, 122))
	pure_car.save_png("assets/ui/textures/event_speedrun_art.png")

	# Pure season pass car without text
	# x from 1660 to 1788 (w=128), y from 932 to 1008 (h=76)
	var pass_car = img.get_region(Rect2i(1660, 932, 128, 76))
	pass_car.save_png("assets/ui/textures/season_pass_car_art.png")

	# Bell icon from notifications
	var bell = img.get_region(Rect2i(1596, 100, 24, 24))
	bell.save_png("assets/ui/icons/ico_bell.png")

	# Mail envelope icon
	var mail_ico = img.get_region(Rect2i(380, 960, 48, 40))
	mail_ico.save_png("assets/ui/icons/ico_envelope.png")

	print("Saved clean art slices")
	quit(0)

