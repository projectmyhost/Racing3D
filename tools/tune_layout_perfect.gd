@tool
extends SceneTree

func _init():
	print("--- TUNING LAYOUT TEST 5: BALANCED EXPOSURE & RIGHT-HALF CAR CENTERING ---")
	var root_3d = Node3D.new()
	root.add_child(root_3d)

	# 1. World Environment
	var env = load("res://assets/materials/environments/env_sunset.tres") as Environment
	if env and env.sky and env.sky.sky_material is ShaderMaterial:
		var sm = env.sky.sky_material as ShaderMaterial
		sm.set_shader_parameter("sun_dir", Vector3(-0.95, 0.05, -0.30))
		sm.set_shader_parameter("color_horizon", Color(1.0, 0.46, 0.15))
		sm.set_shader_parameter("color_pink", Color(0.68, 0.22, 0.38))
		sm.set_shader_parameter("color_mid", Color(0.22, 0.15, 0.34))
		sm.set_shader_parameter("color_zenith", Color(0.07, 0.07, 0.18))
		sm.set_shader_parameter("color_sun_glow", Color(1.0, 0.58, 0.20))
	
	var we = WorldEnvironment.new()
	we.environment = env
	root_3d.add_child(we)

	# 2. Lighting
	var sun = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.position = Vector3(-18.0, 10.0, -14.0)
	sun.look_at_from_position(Vector3(-18.0, 10.0, -14.0), Vector3(3.0, 0.5, 0.0))
	sun.light_color = Color(1.0, 0.68, 0.40)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.shadow_bias = 0.02
	sun.directional_shadow_max_distance = 60.0
	root_3d.add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.name = "FillCool"
	fill.position = Vector3(14.0, 15.0, 10.0)
	fill.look_at_from_position(Vector3(14.0, 15.0, 10.0), Vector3(0.0, 0.0, 0.0))
	fill.light_color = Color(0.35, 0.42, 0.65)
	fill.light_energy = 0.55
	root_3d.add_child(fill)

	# 3. Stage
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"
	root_3d.add_child(stage)

	var p_road = load("res://assets/models/roads/Road1.glb") as PackedScene
	var p_lamp = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var p_tree = load("res://assets/models/roads/Tree3.glb") as PackedScene

	var img_road = Image.load_from_file("res://assets/models/roads/Road1_B_premium.png")
	var tex_road = ImageTexture.create_from_image(img_road)
	var mat_road = StandardMaterial3D.new()
	mat_road.albedo_texture = tex_road
	mat_road.roughness = 0.36
	mat_road.metallic = 0.06
	mat_road.cull_mode = BaseMaterial3D.CULL_BACK
	if ResourceLoader.exists("res://assets/textures/environments/tex_ref_asphalt_normal.png"):
		mat_road.normal_enabled = true
		mat_road.normal_texture = load("res://assets/textures/environments/tex_ref_asphalt_normal.png")
		mat_road.normal_scale = 0.35

	var mat_metal = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	var mat_bb = load("res://assets/materials/environments/mat_ref_billboard_art.tres")
	var mat_b_right = load("res://assets/materials/environments/mat_ref_building_right.tres")
	var mat_b_left = load("res://assets/materials/environments/mat_ref_building_left.tres")

	var road_group = Node3D.new()
	road_group.name = "ModularRoadSlice"
	stage.add_child(road_group)

	for i in range(5):
		var z_pos = -24.0 + float(i) * 12.0
		var r_tile = p_road.instantiate()
		r_tile.name = "Road1_Tile_" + str(i)
		r_tile.position = Vector3(0.0, 0.0, z_pos)
		road_group.add_child(r_tile)
		for c in r_tile.get_children():
			if c is MeshInstance3D:
				c.material_override = mat_road

	# Street Lamps on Right Sidewalk (X = 5.3m)
	var lamp_z = [-14.0, 2.0, 18.0]
	for idx in range(lamp_z.size()):
		var lz = lamp_z[idx]
		var lamp = p_lamp.instantiate()
		lamp.name = "Lamp_" + str(idx)
		lamp.position = Vector3(5.3, 0.475, lz)
		lamp.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		stage.add_child(lamp)

		var lamp_light = OmniLight3D.new()
		lamp_light.name = "LampLight_" + str(idx)
		lamp_light.position = Vector3(4.5, 5.5, lz)
		lamp_light.light_color = Color(1.0, 0.88, 0.65)
		lamp_light.light_energy = 2.4
		lamp_light.omni_range = 14.0
		stage.add_child(lamp_light)

	# Trees along Right Sidewalk Lawn (X = 7.0m)
	var tree_z = [-18.0, 14.0, 26.0]
	for idx in range(tree_z.size()):
		var tz = tree_z[idx]
		var tree = p_tree.instantiate()
		tree.name = "Tree_" + str(idx)
		tree.position = Vector3(7.0, 0.0, tz)
		tree.scale = Vector3(1.15, 1.15, 1.15)
		stage.add_child(tree)

	# Modern Architecture Showroom & Towers
	var showroom = MeshInstance3D.new()
	showroom.name = "ModernShowroom"
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(10.0, 24.0, 52.0)
	showroom.mesh = s_mesh
	showroom.material_override = mat_b_right
	showroom.position = Vector3(12.8, 12.0, 0.0)
	stage.add_child(showroom)

	var left_bldg = MeshInstance3D.new()
	left_bldg.name = "LeftBuilding"
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(10.0, 20.0, 52.0)
	left_bldg.mesh = l_mesh
	left_bldg.material_override = mat_b_left
	left_bldg.position = Vector3(-13.5, 10.0, 0.0)
	stage.add_child(left_bldg)

	# Elevated "RACING GAME" Billboard: positioned at X = 1.6, Z = -16.0
	var bb_node = Node3D.new()
	bb_node.name = "Billboard"
	bb_node.position = Vector3(1.6, 0.475, -16.0)
	stage.add_child(bb_node)

	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.22
	pole_mesh.bottom_radius = 0.28
	pole_mesh.height = 10.2
	for p_idx in range(2):
		var pole = MeshInstance3D.new()
		pole.mesh = pole_mesh
		pole.material_override = mat_metal
		pole.position = Vector3(-3.4 if p_idx == 0 else 3.4, 5.1, 0.0)
		bb_node.add_child(pole)

	var bb_face = MeshInstance3D.new()
	bb_face.name = "BillboardFace"
	var qm = QuadMesh.new()
	qm.size = Vector2(9.8, 4.2)
	bb_face.mesh = qm
	bb_face.material_override = mat_bb
	bb_face.position = Vector3(0.0, 7.3, 0.10)
	bb_node.add_child(bb_face)

	var bb_frame = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(10.0, 4.4, 0.18)
	bb_frame.mesh = bm
	bb_frame.material_override = mat_metal
	bb_frame.position = Vector3(0.0, 7.3, 0.0)
	bb_node.add_child(bb_frame)

	var bb_spot = SpotLight3D.new()
	bb_spot.position = Vector3(0.0, 10.0, 3.2)
	bb_spot.look_at_from_position(Vector3(0.0, 10.0, 3.2), Vector3(0.0, 7.3, 0.0))
	bb_spot.light_color = Color(1.0, 0.95, 0.85)
	bb_spot.light_energy = 3.0
	bb_spot.spot_range = 10.0
	bb_spot.spot_angle = 55.0
	bb_node.add_child(bb_spot)

	# 4. Showcase Car (Ferrari 458 Italia)
	# Positioned at X = 2.7, Y = 0.20, Z = -0.3
	# Angle: 146 deg
	var p_car = load("res://scenes/vehicles/showcase_car.tscn") as PackedScene
	var car_node = p_car.instantiate() as ShowcaseCar
	car_node.name = "ShowcaseCar"
	car_node.position = Vector3(2.7, 0.20, -0.3)
	car_node.rotation_degrees = Vector3(0.0, 146.0, 0.0)
	root_3d.add_child(car_node)

	await create_timer(0.1).timeout

	car_node.load_car_model("italia")
	if car_node.car_mesh:
		var aabb = car_node.car_mesh.get_aabb()
		car_node.visual_root.position.y = -aabb.position.y
		
		# Crimson taillight glow with saturated red (no white blowout)
		var red_light_mat = StandardMaterial3D.new()
		red_light_mat.resource_name = "CarLightsRed"
		red_light_mat.albedo_color = Color(0.95, 0.04, 0.02)
		red_light_mat.emission_enabled = true
		red_light_mat.emission = Color(1.0, 0.06, 0.02)
		red_light_mat.emission_energy_multiplier = 1.8
		car_node.car_mesh.set_surface_override_material(1, red_light_mat)

	# Taillight Road Reflection Glow
	var taillight_glow = OmniLight3D.new()
	taillight_glow.name = "TaillightRoadGlow"
	taillight_glow.position = Vector3(0.0, 0.35, -2.6)
	taillight_glow.light_color = Color(1.0, 0.12, 0.06)
	taillight_glow.light_energy = 2.4
	taillight_glow.omni_range = 5.5
	taillight_glow.omni_attenuation = 1.3
	car_node.add_child(taillight_glow)

	# 5. Camera View: Pointed towards X = 1.1, Y = 0.95, Z = -0.3 from (0.0, 1.35, 7.5)
	# This places the car in the open right-center half (45% to 75% screen width),
	# completely CLEAR of the navigation buttons on the left (0% to 30%)!
	var cam = Camera3D.new()
	cam.name = "ShowcaseCamera"
	cam.fov = 32.0
	cam.near = 0.1
	cam.far = 500.0
	cam.current = true
	cam.position = Vector3(0.0, 1.35, 7.5)
	cam.look_at_from_position(Vector3(0.0, 1.35, 7.5), Vector3(1.1, 0.95, -0.3))
	root_3d.add_child(cam)

	# 6. UI Layer
	var p_ui = load("res://scenes/ui/home_screen_ui.tscn") as PackedScene
	var ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 20
	root_3d.add_child(ui_canvas)
	var ui = p_ui.instantiate()
	ui.set_script(load("res://scripts/ui/home_screen_ui.gd"))
	ui_canvas.add_child(ui)

	await create_timer(0.4).timeout
	var vp = root.get_viewport()
	var img = vp.get_texture().get_image()
	if img:
		img.save_png("docs/validation/layout_test_5.png")
		print("SUCCESS: Saved docs/validation/layout_test_5.png")
	quit(0)
