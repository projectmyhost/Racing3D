@tool
extends SceneTree

func _init():
	print("=== STEP 1: APPLYING DAYTIME HOMESCREEN WITH REAL 3D HOUSES ===")

	# 1. Create daytime environment resource: res://assets/materials/environments/env_daytime.tres
	var env = Environment.new()
	env.resource_name = "EnvDaytime"
	env.background_mode = Environment.BG_SKY

	var psky = ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.24, 0.50, 0.86)
	psky.sky_horizon_color = Color(0.68, 0.80, 0.92)
	psky.ground_bottom_color = Color(0.22, 0.32, 0.22)
	psky.ground_horizon_color = Color(0.65, 0.75, 0.82)
	psky.sun_angle_max = 30.0

	var sky = Sky.new()
	sky.sky_material = psky
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.70, 0.78, 0.90)
	env.ambient_light_sky_contribution = 0.65

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0

	env.glow_enabled = true
	env.glow_intensity = 0.20
	env.glow_strength = 0.80
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.25

	env.fog_enabled = true
	env.fog_light_color = Color(0.74, 0.82, 0.94)
	env.fog_density = 0.0004
	env.fog_aerial_perspective = 0.30

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.15

	ResourceSaver.save(env, "res://assets/materials/environments/env_daytime.tres")
	print("SUCCESS: Saved res://assets/materials/environments/env_daytime.tres")

	# 2. Build ShowcaseStage with real 3D houses
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"

	# Ground Plane (Clean asphalt & surrounding base)
	var mat_road = StandardMaterial3D.new()
	mat_road.resource_name = "RoadAsphaltDay"
	if ResourceLoader.exists("res://assets/models/roads/Road1_B_premium.png"):
		mat_road.albedo_texture = load("res://assets/models/roads/Road1_B_premium.png")
	elif ResourceLoader.exists("res://assets/models/roads/Road1_B_dotted_white.png"):
		mat_road.albedo_texture = load("res://assets/models/roads/Road1_B_dotted_white.png")
	mat_road.roughness = 0.45
	mat_road.metallic = 0.05
	mat_road.cull_mode = BaseMaterial3D.CULL_BACK
	if ResourceLoader.exists("res://assets/textures/environments/tex_ref_asphalt_normal.png"):
		mat_road.normal_enabled = true
		mat_road.normal_texture = load("res://assets/textures/environments/tex_ref_asphalt_normal.png")
		mat_road.normal_scale = 0.30

	# Ground grass terrain around road
	var ground = MeshInstance3D.new()
	ground.name = "GroundBase"
	var gm = PlaneMesh.new()
	gm.size = Vector2(160, 160)
	ground.mesh = gm
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.35, 0.65, 0.38) # Clean bright lowpoly grass
	g_mat.roughness = 0.85
	ground.material_override = g_mat
	ground.position.y = -0.02
	stage.add_child(ground)
	ground.owner = stage

	# Modular Road Tiles (5 tiles: Z from -24 to +24)
	var road_group = Node3D.new()
	road_group.name = "ModularRoadSlice"
	stage.add_child(road_group)
	road_group.owner = stage

	var p_road = load("res://assets/models/roads/Road1.glb") as PackedScene
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

	# Street Lamps on Right Sidewalk
	var p_lamp = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var lamp_z = [-16.0, 4.0, 24.0]
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

	# Trees along Sidewalk
	var p_tree = load("res://assets/models/roads/Tree3.glb") as PackedScene
	var tree_z = [-18.0, 14.0, 28.0]
	for idx in range(tree_z.size()):
		var tz = tree_z[idx]
		var tree = p_tree.instantiate()
		tree.name = "ModularTree_" + str(idx)
		tree.position = Vector3(6.8, 0.0, tz)
		tree.scale = Vector3(1.2, 1.2, 1.2)
		stage.add_child(tree)
		tree.owner = stage
		for c in tree.get_children():
			c.owner = stage

	# REAL 3D HOUSES ON RIGHT SIDE (X = 10.5m)
	var right_house_models = [
		{"name": "Building1_Large", "mesh": "Building1_Large.obj", "z": -14.0, "scale": 1.8, "rot_y": 0.0},
		{"name": "House1", "mesh": "House1.obj", "z": -2.0, "scale": 2.2, "rot_y": -90.0},
		{"name": "Building2_Large", "mesh": "Building2_Large.obj", "z": 10.0, "scale": 1.7, "rot_y": 0.0},
		{"name": "House2", "mesh": "House2.obj", "z": 22.0, "scale": 2.2, "rot_y": -90.0}
	]
	for h_data in right_house_models:
		var m_path = "res://assets/models/buildings/OBJ/" + h_data["mesh"]
		var m_res = load(m_path) as Mesh
		if m_res:
			var mi = MeshInstance3D.new()
			mi.name = h_data["name"]
			mi.mesh = m_res
			var s = h_data["scale"]
			mi.scale = Vector3(s, s, s)
			mi.position = Vector3(10.5, 0.0, h_data["z"])
			mi.rotation_degrees = Vector3(0.0, h_data["rot_y"], 0.0)
			stage.add_child(mi)
			mi.owner = stage

	# REAL 3D HOUSES ON LEFT SIDE (X = -11.5m)
	var left_house_models = [
		{"name": "Building3_Big", "mesh": "Building3_Big.obj", "z": -12.0, "scale": 1.8, "rot_y": 180.0},
		{"name": "Building4", "mesh": "Building4.obj", "z": 4.0, "scale": 1.8, "rot_y": 180.0},
		{"name": "Building1_Small", "mesh": "Building1_Small.obj", "z": 18.0, "scale": 2.0, "rot_y": 180.0}
	]
	for h_data in left_house_models:
		var m_path = "res://assets/models/buildings/OBJ/" + h_data["mesh"]
		var m_res = load(m_path) as Mesh
		if m_res:
			var mi = MeshInstance3D.new()
			mi.name = h_data["name"]
			mi.mesh = m_res
			var s = h_data["scale"]
			mi.scale = Vector3(s, s, s)
			mi.position = Vector3(-11.5, 0.0, h_data["z"])
			mi.rotation_degrees = Vector3(0.0, h_data["rot_y"], 0.0)
			stage.add_child(mi)
			mi.owner = stage

	# Prominent "RACING GAME" Billboard in the center-left background
	var mat_metal = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	var mat_bb = load("res://assets/materials/environments/mat_ref_billboard_art.tres")
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

	# Save showcase_stage.tscn cleanly
	var packed_stage = PackedScene.new()
	packed_stage.pack(stage)
	ResourceSaver.save(packed_stage, "res://scenes/environment/showcase_stage.tscn")
	print("SUCCESS: Saved res://scenes/environment/showcase_stage.tscn")
	stage.free()

	# 3. Update ShowcaseCar smooth lighting in scripts/vehicle/showcase_car.gd
	# We will also ensure home_screen.tscn has:
	# - WorldEnvironment pointing to env_daytime.tres
	# - SunLight positioned high for daytime
	# - FillLight for soft sky reflections
	# - ShowcaseCar facing front-side towards camera: position (2.2, 0.20, 0.2), rotation (0, -32, 0)
	# - CameraRig with orbit_target at (1.1, 0.85, 0.1), default_distance 7.4, default_yaw -12.0, default_pitch 4.5

	# Update home_screen.tscn directly via text replacement or PackedScene
	var home_tscn_content = """[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/core/home_screen.gd" id="1_g2bms"]
[ext_resource type="Environment" path="res://assets/materials/environments/env_daytime.tres" id="2_daytime"]
[ext_resource type="PackedScene" path="res://scenes/environment/showcase_stage.tscn" id="2_stage"]
[ext_resource type="PackedScene" path="res://scenes/vehicles/showcase_car.tscn" id="3_u5cqg"]
[ext_resource type="Script" path="res://scripts/vehicle/showcase_car.gd" id="4_8pt4f"]
[ext_resource type="Script" path="res://scripts/camera/showcase_camera_rig.gd" id="5_k4g45"]
[ext_resource type="PackedScene" path="res://scenes/ui/home_screen_ui.tscn" id="6_lojms"]
[ext_resource type="Theme" path="res://assets/ui/theme_racing.tres" id="7_sxanw"]
[ext_resource type="Script" path="res://scripts/ui/home_screen_ui.gd" id="8_oilt6"]

[node name="HomeScreen" type="Node3D" unique_id=356084580]
script = ExtResource("1_g2bms")

[node name="WorldEnvironment" type="WorldEnvironment" parent="." unique_id=1630742592]
environment = ExtResource("2_daytime")

[node name="SunLight" type="DirectionalLight3D" parent="." unique_id=9554307]
transform = Transform3D(0.8528685, 0.3830222, -0.354605, 0, 0.6794412, 0.7337315, 0.5221226, -0.6257797, 0.5794719, -12, 20, 15)
light_color = Color(1, 0.97, 0.91, 1)
light_energy = 1.35
shadow_enabled = true
shadow_bias = 0.02
directional_shadow_max_distance = 80.0

[node name="FillCool" type="DirectionalLight3D" parent="." unique_id=243656010]
transform = Transform3D(-0.7071068, 0.3535534, -0.6123724, 0, 0.8660254, 0.5, 0.7071068, 0.3535534, -0.6123724, 12, 14, -10)
light_color = Color(0.60, 0.70, 0.88, 1)
light_energy = 0.45

[node name="Stage" type="Node3D" parent="." unique_id=1937996115 instance=ExtResource("2_stage")]

[node name="ShowcaseCar" type="Node3D" parent="." unique_id=266877679 instance=ExtResource("3_u5cqg")]
transform = Transform3D(0.8480481, 0, -0.52991926, 0, 1, 0, 0.52991926, 0, 0.8480481, 2.2, 0.2, 0.2)
script = ExtResource("4_8pt4f")

[node name="CameraRig" type="Node3D" parent="." unique_id=830269515]
script = ExtResource("5_k4g45")
orbit_target = Vector3(1.1, 0.85, 0.1)
default_distance = 7.4
default_yaw_deg = -12.0
default_pitch_deg = 4.5

[node name="ShowcaseCamera" type="Camera3D" parent="CameraRig" unique_id=1127729622]
current = true
fov = 32.0
near = 0.1
far = 500.0

[node name="UILayer" type="CanvasLayer" parent="." unique_id=429291509]
layer = 20

[node name="HomeScreenUI" type="Control" parent="UILayer" unique_id=1511958146 instance=ExtResource("6_lojms")]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme = ExtResource("7_sxanw")
script = ExtResource("8_oilt6")
"""
	var f = FileAccess.open("res://scenes/main/home_screen.tscn", FileAccess.WRITE)
	if f:
		f.store_string(home_tscn_content)
		f.close()
		print("SUCCESS: Overwritten res://scenes/main/home_screen.tscn with clean daytime setup")

	quit(0)

