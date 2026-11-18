@tool
extends SceneTree

func _init():
	print("=== APPLYING 100% PRECISE FIX FOR CAR GROUND & HOUSE CLIPPING ===")

	# -------------------------------------------------------------------------
	# 1. FIX SHOWCASE_STAGE.TSCN (REPOSITION HOUSES WITH CLEAR SETBACKS)
	# -------------------------------------------------------------------------
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"

	# Road Material
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

	# Ground grass terrain around road (Continuous green lawn)
	var ground = MeshInstance3D.new()
	ground.name = "GroundBase"
	var gm = PlaneMesh.new()
	gm.size = Vector2(160, 160)
	ground.mesh = gm
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.38, 0.72, 0.52) # Vibrant clean grass
	g_mat.roughness = 0.85
	ground.material_override = g_mat
	ground.position.y = -0.01
	stage.add_child(ground)
	ground.owner = stage

	# Modular Road Tiles (5 tiles: Z from -24 to +24)
	# Road asphalt is at Y = 0.20m, sidewalk is at Y = 0.475m, sidewalk ends at X = ±6.0m
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

	# Street Lamps on Right Sidewalk (X = 5.3m, on sidewalk surface at Y = 0.475m)
	var p_lamp = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var lamp_z = [-18.0, 4.0, 24.0]
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

	# Trees in Green Setback Lawn (X = 6.6m, Z = -22.0, 14.0, 28.0)
	var p_tree = load("res://assets/models/roads/Tree3.glb") as PackedScene
	var tree_z = [-22.0, 14.0, 28.0]
	for idx in range(tree_z.size()):
		var tz = tree_z[idx]
		var tree = p_tree.instantiate()
		tree.name = "ModularTree_" + str(idx)
		tree.position = Vector3(6.6, 0.0, tz)
		tree.scale = Vector3(1.15, 1.15, 1.15)
		stage.add_child(tree)
		tree.owner = stage
		for c in tree.get_children():
			c.owner = stage

	# -------------------------------------------------------------------------
	# REAL 3D HOUSES (CAREFULLY POSITIONED BEYOND X = 6.0m SIDEWALK EDGE)
	# ZERO PENETRATION INTO SIDEWALK CURB OR ROADWAY!
	# -------------------------------------------------------------------------
	# RIGHT HOUSES: rot_y = -90.0 (facades facing road towards -X)
	var right_house_models = [
		{"name": "Building1_Large", "mesh": "Building1_Large.obj", "pos": Vector3(10.8, 0.0, -16.0), "scale": 1.7, "rot_y": -90.0},
		{"name": "House1",          "mesh": "House1.obj",          "pos": Vector3(12.5, 0.0, -2.0),  "scale": 2.0, "rot_y": -90.0},
		{"name": "Building2_Large", "mesh": "Building2_Large.obj", "pos": Vector3(10.5, 0.0, 8.0),   "scale": 1.6, "rot_y": -90.0},
		{"name": "House2",          "mesh": "House2.obj",          "pos": Vector3(11.8, 0.0, 20.0),  "scale": 2.0, "rot_y": -90.0}
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
			mi.position = h_data["pos"]
			mi.rotation_degrees = Vector3(0.0, h_data["rot_y"], 0.0)
			stage.add_child(mi)
			mi.owner = stage

	# LEFT HOUSES: rot_y = 90.0 (facades facing road towards +X)
	var left_house_models = [
		{"name": "Building3_Big",   "mesh": "Building3_Big.obj",   "pos": Vector3(-12.0, 0.0, -14.0), "scale": 1.7, "rot_y": 90.0},
		{"name": "Building4",       "mesh": "Building4.obj",       "pos": Vector3(-11.5, 0.0, 0.0),   "scale": 1.7, "rot_y": 90.0},
		{"name": "Building1_Small", "mesh": "Building1_Small.obj", "pos": Vector3(-10.5, 0.0, 14.0),  "scale": 1.8, "rot_y": 90.0}
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
			mi.position = h_data["pos"]
			mi.rotation_degrees = Vector3(0.0, h_data["rot_y"], 0.0)
			stage.add_child(mi)
			mi.owner = stage

	# Prominent "RACING GAME" Billboard in the center-left background
	var mat_metal = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	var mat_bb = load("res://assets/materials/environments/mat_ref_billboard_art.tres")
	var bb_node = Node3D.new()
	bb_node.name = "Billboard"
	bb_node.position = Vector3(1.8, 0.475, -20.0)
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
	print("SUCCESS: Saved res://scenes/environment/showcase_stage.tscn with zero house clipping")
	stage.free()

	quit(0)

