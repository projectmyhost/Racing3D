extends SceneTree

func _init():
	var t = Transform3D().rotated(Vector3.UP, deg_to_rad(-115.0))
	t.origin = Vector3(0.55, 0.0, 0.25)
	print("EXACT_TRANSFORM: ", t)
	quit(0)
