@tool
extends SceneTree

func _init():
	var vp = SubViewport.new()
	vp.size = Vector2i(800, 480)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	
	var car_scene = load("res://assets/models/cars/car_porsche_mission_x.tscn")
	if not car_scene:
		print("Failed to load car scene")
		quit(1)
		return
	var car = car_scene.instantiate()
	vp.add_child(car)
	
	# Center car and rotate to 3/4 front-left angle matching reference
	car.position = Vector3(0, 0, 0)
	car.rotation_degrees = Vector3(0, 150, 0)
	
	var cam = Camera3D.new()
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(4.2, 1.6, 5.2), Vector3(0, 0.45, 0))
	cam.fov = 32.0
	
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 45, 0)
	light.light_energy = 1.4
	vp.add_child(light)
	
	var fill_light = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(20, -135, 0)
	fill_light.light_energy = 0.6
	vp.add_child(fill_light)
	
	for i in range(15):
		await process_frame
		
	var img = vp.get_texture().get_image()
	img.save_png("res://assets/ui/textures/season_pass_mission_x.png")
	print("Saved season pass car render to assets/ui/textures/season_pass_mission_x.png")
	quit(0)
