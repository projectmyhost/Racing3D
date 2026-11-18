extends SceneTree

var _timer: float = 0.0
var _captured: bool = false

func _init():
	print("Starting Home Screen Capture...")
	change_scene_to_file("res://scenes/main/home_screen.tscn")

func _process(delta: float) -> bool:
	_timer += delta
	if _timer >= 1.5 and not _captured:
		_captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		if img and not img.is_empty():
			if img.get_size() != Vector2i(1920, 1080):
				img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
			img.save_png("docs/validation/home_rb22_latest.png")
			print("Saved docs/validation/home_rb22_latest.png successfully!")
		quit(0)
		return true
	return false
