extends SceneTree

var _frames: int = 0

func _init():
	print("Capturing in-game screenshot...")
	change_scene_to_file("res://scenes/main/home_screen.tscn")

func _process(delta: float) -> bool:
	_frames += 1
	if _frames > 30:
		var vp = root.get_viewport()
		if vp:
			var tex = vp.get_texture()
			if tex:
				var img = tex.get_image()
				if img:
					img.save_png("docs/validation/current_render.png")
					print("Saved screenshot to docs/validation/current_render.png (size: ", img.get_width(), "x", img.get_height(), ")")
		quit(0)
		return true
	return false

