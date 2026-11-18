@tool
extends SceneTree

var _frame: int = 0

func _init():
	print("--- CAPTURING RACE ARENA 3D SCREENSHOTS ---")
	change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")

func _process(delta: float) -> bool:
	_frame += 1
	var race = root.get_node_or_null("RaceTrack3D")
	if not race:
		return false

	if _frame == 25:
		# Capture 1: In-game driver chase camera view
		var vp = root.get_viewport()
		if vp:
			var img = vp.get_texture().get_image()
			if img:
				img.save_png("docs/validation/race_track_arena_chase.png")
				print("SUCCESS: Saved docs/validation/race_track_arena_chase.png")

		# Switch to Aerial Arena Showcase Camera (isometric view matching media_1794492512238_7db41990)
		var aerial_cam = Camera3D.new()
		aerial_cam.name = "ShowcaseAerialCam"
		aerial_cam.current = true
		aerial_cam.fov = 45.0
		aerial_cam.position = Vector3(-45.0, 52.0, -35.0)
		aerial_cam.look_at_from_position(Vector3(-45.0, 52.0, -35.0), Vector3(28.0, 2.0, 36.0))
		race.add_child(aerial_cam)

	elif _frame == 35:
		var vp = root.get_viewport()
		if vp:
			var img = vp.get_texture().get_image()
			if img:
				img.save_png("docs/validation/race_track_arena_aerial.png")
				print("SUCCESS: Saved docs/validation/race_track_arena_aerial.png")
		quit(0)
		return true

	return false

