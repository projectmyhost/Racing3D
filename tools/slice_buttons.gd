@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Slices for left buttons
	var b_play = img.get_region(Rect2i(80, 272, 485, 96))
	b_play.save_png("assets/ui/textures/btn_play_ref.png")

	var b_settings = img.get_region(Rect2i(90, 393, 438, 70))
	b_settings.save_png("assets/ui/textures/btn_settings_ref.png")

	var b_garage = img.get_region(Rect2i(90, 468, 438, 70))
	b_garage.save_png("assets/ui/textures/btn_garage_ref.png")

	var b_tuning = img.get_region(Rect2i(90, 543, 438, 70))
	b_tuning.save_png("assets/ui/textures/btn_tuning_ref.png")

	var b_paint = img.get_region(Rect2i(90, 618, 438, 70))
	b_paint.save_png("assets/ui/textures/btn_paint_ref.png")

	var b_profile = img.get_region(Rect2i(90, 693, 438, 70))
	b_profile.save_png("assets/ui/textures/btn_profile_ref.png")

	print("Saved individual button slices")
	quit(0)

