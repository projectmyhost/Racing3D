@tool
extends SceneTree

func _init():
	var root_3d = Node3D.new()
	root.add_child(root_3d)
	
	var env = WorldEnvironment.new()
	var env_res = Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.15, 0.18, 0.22)
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.9, 0.9, 0.95)
	env_res.ambient_light_energy = 1.2
	env.environment = env_res
	root_3d.add_child(env)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 45, 0)
	sun.light_energy = 1.8
	root_3d.add_child(sun)
	
	var p_road = load("res://assets/models/roads/Road1.glb") as PackedScene
	
	var texs = [
		"Road1_B_dotted_white.png",
		"Road1_B_white.png",
		"Road1_Road1_B.png"
	]
	
	for i in range(texs.size()):
		var r_inst = p_road.instantiate()
		r_inst.position = Vector3(float(i) * 14.0 - 14.0, 0, 0)
		var m: MeshInstance3D = r_inst.get_child(0)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = load("res://assets/models/roads/" + texs[i])
		mat.roughness = 0.5
		mat.metallic = 0.0
		m.material_override = mat
		root_3d.add_child(r_inst)
		
	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 16.0, 14.0)
	cam.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
	root_3d.add_child(cam)
	cam.current = true
	
	await create_timer(0.4).timeout
	var vp = root.get_viewport()
	var img = vp.get_texture().get_image()
	if img:
		img.save_png("tools/compare_road_textures.png")
		print("SUCCESS: Saved tools/compare_road_textures.png")
	quit(0)

