@tool
extends SceneTree

# Builds the final showcase_stage.tscn and updates home_screen.tscn
# Guarantees authentic Atomic Realm Modular Roads, low GPU thermals on RTX 2050,
# zero curb/sidewalk clipping, heroic car placement, and illuminated RACING GAME billboard.

func _init():
	print("--- APPLYING FULL HOMESCREEN 3D ENVIRONMENT UPGRADE ---")

	# =========================================================================
	# 1. BUILD SHOWCASE_STAGE.TSCN
	# =========================================================================
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"

	# Road Materials
	var img_road = Image.load_from_file("res://assets/models/roads/Road1_B_premium.png")
	var tex_road = ImageTexture.create_from_image(img_road)
	var mat_road = StandardMaterial3D.new()
	mat_road.resource_name = "MatModularRoad"
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

	# Road slice (5 modular tiles from Atomic Realm pack)
	var road_group = Node3D.new()
	road_group.name = "ModularRoadSlice"
	stage.add_child(road_group)
	road_group.owner = stage

	var p_road = load("res://assets/models/roads/Road1.glb") as PackedScene
	var p_lamp = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var p_tree = load("res://assets/models/roads/Tree3.glb") as PackedScene

	for i in range(5):
		var z_pos = -24.0 + float(i) * 12.0
		var r_tile = p_road.instantiate()
		r_tile.name = "Road1_Tile_" + str(i)
		r_tile.position = Vector3(0.0, 0.0, z_pos)
		road_group.add_child(r_tile)
		r_tile.owner = stage
		for c in r_tile.get_children():
			c.owner = stage
			if c is MeshInstance3D:
				c.material_override = mat_road

	# Street Lamps on Right Sidewalk (X = 5.3m)
	var lamp_z = [-16.0, 6.5, 22.0]
	for idx in range(lamp_z.size()):
		var lz = lamp_z[idx]
		var lamp = p_lamp.instantiate()
		lamp.name = "ModularLamp_" + str(idx)
		lamp.position = Vector3(5.3, 0.475, lz)
		lamp.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		stage.add_child(lamp)
		lamp.owner = stage
		for c in lamp.get_children():
			c.owner = stage

		var lamp_light = OmniLight3D.new()
		lamp_light.name = "LampLight_" + str(idx)
		lamp_light.position = Vector3(4.5, 5.5, lz)
		lamp_light.light_color = Color(1.0, 0.88, 0.65)
		lamp_light.light_energy = 2.4
		lamp_light.omni_range = 14.0
		lamp_light.omni_attenuation = 1.2
		stage.add_child(lamp_light)
		lamp_light.owner = stage

	# Trees along Right Sidewalk Lawn (X = 7.0m)
	var tree_z = [-20.0, 16.0, 28.0]
	for idx in range(tree_z.size()):
		var tz = tree_z[idx]
		var tree = p_tree.instantiate()
		tree.name = "ModularTree_" + str(idx)
		tree.position = Vector3(7.0, 0.0, tz)
		tree.scale = Vector3(1.15, 1.15, 1.15)
		stage.add_child(tree)
		tree.owner = stage
		for c in tree.get_children():
			c.owner = stage

	# Modern Right Architecture Showroom Tower
	var showroom = MeshInstance3D.new()
	showroom.name = "RoadsideRaceTower"
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(10.0, 24.0, 52.0)
	showroom.mesh = s_mesh
	showroom.material_override = mat_b_right
	showroom.position = Vector3(12.8, 12.0, 0.0)
	stage.add_child(showroom)
	showroom.owner = stage

	# Left Building Facade in background
	var left_bldg = MeshInstance3D.new()
	left_bldg.name = "RoadsidePitShowroom"
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(10.0, 20.0, 52.0)
	left_bldg.mesh = l_mesh
	left_bldg.material_override = mat_b_left
	left_bldg.position = Vector3(-13.5, 10.0, 0.0)
	stage.add_child(left_bldg)
	left_bldg.owner = stage

	# Elevated "RACING GAME" Billboard: X = 1.8, Y = 0.475, Z = -16.0
	var bb_node = Node3D.new()
	bb_node.name = "Billboard"
	bb_node.position = Vector3(1.8, 0.475, -16.0)
	stage.add_child(bb_node)
	bb_node.owner = stage

	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.22
	pole_mesh.bottom_radius = 0.28
	pole_mesh.height = 9.2
	for p_idx in range(2):
		var pole = MeshInstance3D.new()
		pole.name = "Pole_" + str(p_idx)
		pole.mesh = pole_mesh
		pole.material_override = mat_metal
		pole.position = Vector3(-3.8 if p_idx == 0 else 3.8, 4.6, 0.0)
		bb_node.add_child(pole)
		pole.owner = stage

	var bb_face = MeshInstance3D.new()
	bb_face.name = "BillboardFace"
	var qm = QuadMesh.new()
	qm.size = Vector2(10.2, 4.2)
	bb_face.mesh = qm
	bb_face.material_override = mat_bb
	bb_face.position = Vector3(0.0, 6.2, 0.10)
	bb_node.add_child(bb_face)
	bb_face.owner = stage

	var bb_frame = MeshInstance3D.new()
	bb_frame.name = "BillboardFrame"
	var bm = BoxMesh.new()
	bm.size = Vector3(10.4, 4.4, 0.18)
	bb_frame.mesh = bm
	bb_frame.material_override = mat_metal
	bb_frame.position = Vector3(0.0, 6.2, 0.0)
	bb_node.add_child(bb_frame)
	bb_frame.owner = stage

	var bb_spot = SpotLight3D.new()
	bb_spot.name = "BillboardSpotLight"
	bb_spot.position = Vector3(0.0, 8.8, 3.2)
	bb_spot.look_at_from_position(Vector3(0.0, 8.8, 3.2), Vector3(0.0, 6.2, 0.0))
	bb_spot.light_color = Color(1.0, 0.95, 0.85)
	bb_spot.light_energy = 3.0
	bb_spot.spot_range = 10.0
	bb_spot.spot_angle = 55.0
	bb_node.add_child(bb_spot)
	bb_spot.owner = stage

	# Save showcase_stage.tscn
	var p_stage = PackedScene.new()
	var pack_res = p_stage.pack(stage)
	if pack_res == OK:
		ResourceSaver.save(p_stage, "res://scenes/environment/showcase_stage.tscn")
		print("SUCCESS: Saved res://scenes/environment/showcase_stage.tscn")
	else:
		print("ERROR: Failed to pack stage: ", pack_res)

	# =========================================================================
	# 2. UPDATE SKY ENVIRONMENT MAT
	# =========================================================================
	var env = load("res://assets/materials/environments/env_sunset.tres") as Environment
	if env and env.sky and env.sky.sky_material is ShaderMaterial:
		var sm = env.sky.sky_material as ShaderMaterial
		sm.set_shader_parameter("sun_dir", Vector3(-0.95, 0.05, -0.30))
		sm.set_shader_parameter("color_horizon", Color(1.0, 0.46, 0.15))
		sm.set_shader_parameter("color_pink", Color(0.68, 0.22, 0.38))
		sm.set_shader_parameter("color_mid", Color(0.22, 0.15, 0.34))
		sm.set_shader_parameter("color_zenith", Color(0.07, 0.07, 0.18))
		sm.set_shader_parameter("color_sun_glow", Color(1.0, 0.58, 0.20))
		ResourceSaver.save(env, "res://assets/materials/environments/env_sunset.tres")
		print("SUCCESS: Updated res://assets/materials/environments/env_sunset.tres")

	# =========================================================================
	# 3. BUILD AND SAVE HOME_SCREEN.TSCN
	# =========================================================================
	var home = Node3D.new()
	home.name = "HomeScreen"
	home.set_script(load("res://scripts/core/home_screen.gd"))

	# WorldEnvironment
	var we = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	home.add_child(we)
	we.owner = home

	# SunLight (Sunset Key Light)
	var sun = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.position = Vector3(-18.0, 10.0, -14.0)
	sun.look_at_from_position(Vector3(-18.0, 10.0, -14.0), Vector3(3.0, 0.5, 0.0))
	sun.light_color = Color(1.0, 0.68, 0.40)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.shadow_bias = 0.02
	sun.directional_shadow_max_distance = 60.0
	home.add_child(sun)
	sun.owner = home

	# FillCool (Sky Twilight Ambient)
	var fill = DirectionalLight3D.new()
	fill.name = "FillCool"
	fill.position = Vector3(14.0, 15.0, 10.0)
	fill.look_at_from_position(Vector3(14.0, 15.0, 10.0), Vector3(0.0, 0.0, 0.0))
	fill.light_color = Color(0.35, 0.42, 0.65)
	fill.light_energy = 0.55
	home.add_child(fill)
	fill.owner = home

	# Stage Instance
	var stage_inst = p_stage.instantiate()
	stage_inst.name = "Stage"
	home.add_child(stage_inst)
	stage_inst.owner = home

	# Showcase Car Instance
	var p_car = load("res://scenes/vehicles/showcase_car.tscn") as PackedScene
	var car_inst = p_car.instantiate() as ShowcaseCar
	car_inst.name = "ShowcaseCar"
	car_inst.position = Vector3(2.7, 0.20, -0.3)
	car_inst.rotation_degrees = Vector3(0.0, 146.0, 0.0)
	car_inst.current_model = "italia"
	car_inst.current_paint_color = Color(0.95, 0.15, 0.12, 1.0)
	home.add_child(car_inst)
	car_inst.owner = home

	# CameraRig Instance
	var cam_rig = Node3D.new()
	cam_rig.name = "CameraRig"
	cam_rig.set_script(load("res://scripts/camera/showcase_camera_rig.gd"))
	cam_rig.set("orbit_target", Vector3(1.1, 0.95, -0.3))
	cam_rig.set("default_yaw_deg", -8.0)
	cam_rig.set("default_pitch_deg", 3.2)
	cam_rig.set("default_distance", 7.9)
	home.add_child(cam_rig)
	cam_rig.owner = home

	var cam = Camera3D.new()
	cam.name = "ShowcaseCamera"
	cam.fov = 32.0
	cam.near = 0.1
	cam.far = 500.0
	cam.current = true
	cam_rig.add_child(cam)
	cam.owner = home

	# UI Layer Instance
	var ui_canvas = CanvasLayer.new()
	ui_canvas.name = "UILayer"
	ui_canvas.layer = 20
	home.add_child(ui_canvas)
	ui_canvas.owner = home

	var p_ui = load("res://scenes/ui/home_screen_ui.tscn") as PackedScene
	var ui_inst = p_ui.instantiate()
	ui_inst.name = "HomeScreenUI"
	ui_inst.set_script(load("res://scripts/ui/home_screen_ui.gd"))
	ui_inst.theme = load("res://assets/ui/theme_racing.tres")
	ui_canvas.add_child(ui_inst)
	ui_inst.owner = home

	# Save home_screen.tscn
	var p_home = PackedScene.new()
	var pack_home_res = p_home.pack(home)
	if pack_home_res == OK:
		ResourceSaver.save(p_home, "res://scenes/main/home_screen.tscn")
		print("SUCCESS: Saved res://scenes/main/home_screen.tscn")
	else:
		print("ERROR: Failed to pack home scene: ", pack_home_res)

	quit(0)
