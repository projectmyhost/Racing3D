extends SceneTree

var _timer: float = 0.0
var _captured: bool = false

func _init():
	change_scene_to_file("res://scenes/main/home_screen.tscn")

func _process(delta: float) -> bool:
	_timer += delta
	if _timer >= 1.5 and not _captured:
		_captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		if img and not img.is_empty():
			img.save_png("docs/validation/current_homescreen.png")
			print("SUCCESS: Saved docs/validation/current_homescreen.png")
		else:
			print("ERROR: Image was null or empty")
		quit(0)
		return true
	return false

