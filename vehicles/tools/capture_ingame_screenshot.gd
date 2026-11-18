extends SceneTree

func _init() -> void:
	print("Capturing McLaren side 3/4 on track...")
	var track_scene = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	if not track_scene:
		quit(1)
		return
		
	var instance = track_scene.instantiate()
	root.add_child(instance)
	
	var car = instance.get_node_or_null("RaceCar3D") as VehiclePhysicsCore
	if car:
		car.initialize_vehicle("mclaren")
	
	for i in range(60):
		await process_frame
		
	# Now set manual camera view after scene is settled
	instance._is_manual_mode = true
	instance._cam_world_yaw = car.rotation.y + deg_to_rad(65.0)
	instance._cam_pitch = deg_to_rad(9.0)
	instance._cam_distance = 4.6
	
	for i in range(20):
		instance._is_manual_mode = true
		await process_frame
		
	var vp = root.get_viewport()
	if vp:
		var tex = vp.get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				var save_path = "C:/Users/Pongo/.gemini/antigravity/brain/76ccbfc7-b30c-4ef0-a3b2-1bd96c0179a5/mclaren_side_grounded_verified.png"
				img.save_png(save_path)
				print("Saved McLaren 3/4 screenshot to: ", save_path)
	quit(0)
