@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/reference/home_screen_reference.png")
	if img != null:
		print("Loaded reference image: ", img.get_size())
		var w = img.get_width()
		var h = img.get_height()
		var scale_x = float(w) / 1920.0
		var scale_y = float(h) / 1080.0
		var crop_x = int(64.0 * scale_x)
		var crop_y = int(41.0 * scale_y)
		var crop_w = int(114.0 * scale_x)
		var crop_h = int(114.0 * scale_y)
		var avatar_rect = Rect2i(crop_x, crop_y, crop_w, crop_h)
		var avatar_img = img.get_region(avatar_rect)
		avatar_img.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		avatar_img.save_png("assets/ui/textures/tex_ui_avatar_default.png")
		print("Saved assets/ui/textures/tex_ui_avatar_default.png successfully")
	else:
		print("Failed to load reference image")
	quit()
