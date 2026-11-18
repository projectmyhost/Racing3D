@tool
extends SceneTree

func _init():
	_run()

func _run() -> void:
	var packed = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	var track = packed.instantiate() as RaceTrack3D
	get_root().add_child(track)
	
	# Set orbit to 180 degrees away from vehicle heading (viewing front of car)
	track._cam_world_yaw = 0.0
	track._cam_pitch = deg_to_rad(12.0)
	track._cam_distance = 6.2
	track._is_manual_mode = true
	
	for i in range(15):
		track._update_chase_camera(1.0 / 60.0)
		await process_frame
		
	var viewport = get_root()
	var img = viewport.get_texture().get_image()
	if img:
		img.save_png("docs/validation/race_camera_rotated_180.png")
		print("Screenshot saved to docs/validation/race_camera_rotated_180.png")
	quit(0)
