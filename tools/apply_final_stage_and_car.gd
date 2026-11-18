@tool
extends SceneTree

func _init():
	print("--- APPLYING FINAL HOMESCREEN STAGE & CAR SETUP ---")
	
	# -------------------------------------------------------------------------
	# 1. BUILD FINAL SHOWCASE STAGE
	# -------------------------------------------------------------------------
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"

	# Load Materials
	var mat_asphalt = load("res://assets/materials/environments/mat_ref_asphalt_wet.tres")
	var mat_bb = load("res://assets/materials/environments/mat_ref_billboard_art.tres")
	var mat_b_left = load("res://assets/materials/environments/mat_ref_building_left.tres")
	var mat_b_right = load("res://assets/materials/environments/mat_ref_building_right.tres")
	var mat_grate = load("res://assets/materials/environments/mat_ref_drainage_grate.tres")
	var mat_banner = load("res://assets/materials/environments/mat_ref_racing_banner.tres")
	var mat_palm_leaf = load("res://assets/materials/environments/mat_ref_palm_leaf.tres")
	var mat_metal = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	var mat_concrete = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	var mat_palm_trunk = load("res://assets/materials/environments/mat_env_palm_trunk.tres")

	# Base ground plane (Wet asphalt ground)
	var road = MeshInstance3D.new()
	road.name = "WetAsphaltRoad"
	var road_mesh = PlaneMesh.new()
	road_mesh.size = Vector2(100, 100)
	road.mesh = road_mesh
	road.material_override = mat_asphalt
	road.position = Vector3(0, -0.01, 10)
	stage.add_child(road)
	road.owner = stage

	# =========================================================================
	# 2. MODULAR ROAD SLICE (From [FREE] Modular Roads - Base.zip)
	# =========================================================================
	var road_chain = Node3D.new()
	road_chain.name = "ModularRoadSlice"
	road_chain.position = Vector3(0.0, 0.0, 10.0)
	road_chain.rotation_degrees = Vector3(0, 24.0, 0)
	stage.add_child(road_chain)
	road_chain.owner = stage

	var road1_scene = load("res://assets/models/roads/Road1.glb") as PackedScene
	var lamp_scene = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var tree_scene = load("res://assets/models/roads/Tree3.glb") as PackedScene
	var barrier_scene = load("res://assets/models/roads/road_barrier_1.glb") as PackedScene
	var cone_scene = load("res://assets/models/roads/hazzard_cone_1.glb") as PackedScene

	var mat_road = StandardMaterial3D.new()
	var tex_road = load("res://assets/models/roads/Road1_B_dotted_white.png") as Texture2D
	mat_road.albedo_texture = tex_road
	mat_road.roughness = 0.42
	mat_road.metallic = 0.08

	# Place 3 modular Road1 tiles along the road slice (Z: -12, 0, 12)
	for i in range(-1, 2):
		if road1_scene:
			var r_tile = road1_scene.instantiate()
			r_tile.name = "Road1_Tile_" + str(i + 1)
			# Asphalt surface at y = 0.20, so position at -0.19 puts asphalt at y = 0.01
			r_tile.position = Vector3(0, -0.19, float(i) * 12.0)
			road_chain.add_child(r_tile)
			r_tile.owner = stage
			for c in r_tile.get_children():
				c.owner = stage
				if c is MeshInstance3D:
					c.material_override = mat_road

	# Modular street lamps along right curb (X ~ 5.8)
	for i in range(2):
		if lamp_scene:
			var lamp = lamp_scene.instantiate()
			lamp.name = "ModularLamp_" + str(i)
			lamp.position = Vector3(5.8, 0.28, float(i) * 16.0 - 4.0)
			lamp.rotation_degrees = Vector3(0, 180.0, 0)
			road_chain.add_child(lamp)
			lamp.owner = stage
			for c in lamp.get_children():
				c.owner = stage
				
			var lamp_glow = OmniLight3D.new()
			lamp_glow.name = "LampLight_" + str(i)
			lamp_glow.position = Vector3(5.4, 5.8, float(i) * 16.0 - 4.0)
			lamp_glow.light_color = Color(1.0, 0.88, 0.65)
			lamp_glow.light_energy = 1.6
			lamp_glow.omni_range = 14.0
			lamp_glow.omni_attenuation = 1.3
			road_chain.add_child(lamp_glow)
			lamp_glow.owner = stage

	# Modular trees along sidewalk (X ~ 9.0)
	for i in range(2):
		if tree_scene:
			var tree = tree_scene.instantiate()
			tree.name = "ModularTree_" + str(i)
			tree.position = Vector3(9.2, 0.28, float(i) * 20.0 - 6.0)
			tree.scale = Vector3(1.1, 1.1, 1.1)
			road_chain.add_child(tree)
			tree.owner = stage
			for c in tree.get_children():
				c.owner = stage

	# Modular road barriers
	for i in range(4):
		if barrier_scene:
			var bar = barrier_scene.instantiate()
			bar.name = "RoadBarrier_" + str(i)
			bar.position = Vector3(5.4, 0.28, -6.0 + float(i) * 2.2)
			road_chain.add_child(bar)
			bar.owner = stage
			for c in bar.get_children():
				c.owner = stage

	# Hazard cones near curb
	for i in range(3):
		if cone_scene:
			var cone = cone_scene.instantiate()
			cone.name = "HazardCone_" + str(i)
			cone.position = Vector3(4.8 + float(i) * 0.3, 0.01, 6.0 + float(i) * 1.5)
			road_chain.add_child(cone)
			cone.owner = stage
			for c in cone.get_children():
				c.owner = stage

	# =========================================================================
	# 3. ROAD MARKINGS & COMPATIBILITY SUITE
	# =========================================================================
	var markings = Node3D.new()
	markings.name = "Markings"
	stage.add_child(markings)
	markings.owner = stage

	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.97, 0.97, 0.98, 0.98)
	mat_white.roughness = 0.32

	var main_line = MeshInstance3D.new()
	main_line.name = "MainWhiteLaneLine"
	var ml_mesh = BoxMesh.new()
	ml_mesh.size = Vector3(0.24, 0.005, 80.0)
	main_line.mesh = ml_mesh
	main_line.material_override = mat_white
	main_line.position = Vector3(-0.45, 0.003, 10.0)
	main_line.rotation_degrees = Vector3(0, 24.0, 0)
	main_line.visible = false # Handled cleanly by modular Road1 tiles
	markings.add_child(main_line)
	main_line.owner = stage

	var drain = MeshInstance3D.new()
	drain.name = "LinearSlotDrain"
	var dg_mesh = BoxMesh.new()
	dg_mesh.size = Vector3(0.40, 0.006, 80.0)
	drain.mesh = dg_mesh
	drain.material_override = mat_grate
	drain.position = Vector3(4.9, 0.005, 10.0)
	drain.rotation_degrees = Vector3(0, 24.0, 0)
	markings.add_child(drain)
	drain.owner = stage

	# Right Sidewalk Curb
	var curb_root = Node3D.new()
	curb_root.name = "RightSidewalkCurb"
	curb_root.position = Vector3(5.6, 0, 10.0)
	curb_root.rotation_degrees = Vector3(0, 24.0, 0)
	stage.add_child(curb_root)
	curb_root.owner = stage

	var curb_mesh = BoxMesh.new()
	curb_mesh.size = Vector3(0.26, 0.14, 80.0)
	var curb_inst = MeshInstance3D.new()
	curb_inst.name = "CurbEdge"
	curb_inst.mesh = curb_mesh
	curb_inst.material_override = mat_concrete
	curb_inst.position = Vector3(0.13, 0.07, 0)
	curb_root.add_child(curb_inst)
	curb_inst.owner = stage

	var sw_mesh = BoxMesh.new()
	sw_mesh.size = Vector3(18.0, 0.12, 80.0)
	var sw_inst = MeshInstance3D.new()
	sw_inst.name = "SidewalkPavement"
	sw_inst.mesh = sw_mesh
	sw_inst.material_override = mat_concrete
	sw_inst.position = Vector3(9.2, 0.06, 0)
	curb_root.add_child(sw_inst)
	sw_inst.owner = stage

	# Center dashed lines
	var dashes_root = Node3D.new()
	dashes_root.name = "CenterDashedLines"
	markings.add_child(dashes_root)
	dashes_root.owner = stage
	for i in range(12):
		var dash = MeshInstance3D.new()
		dash.name = "Dash_" + str(i)
		var d_mesh = BoxMesh.new()
		d_mesh.size = Vector3(0.18, 0.004, 2.0)
		dash.mesh = d_mesh
		dash.material_override = mat_white
		dash.position = Vector3(-12.0 + float(i)*0.8, -0.05, float(i)*5.0)
		dashes_root.add_child(dash)
		dash.owner = stage

	var border_l = MeshInstance3D.new()
	border_l.name = "LeftWhiteBorder"
	border_l.mesh = ml_mesh
	border_l.material_override = mat_white
	border_l.position = Vector3(-14.0, -0.05, 10.0)
	markings.add_child(border_l)
	border_l.owner = stage

	var border_r = MeshInstance3D.new()
	border_r.name = "RightWhiteBorder"
	border_r.mesh = ml_mesh
	border_r.material_override = mat_white
	border_r.position = Vector3(16.0, -0.05, 10.0)
	markings.add_child(border_r)
	border_r.owner = stage

	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.98, 0.78, 0.12, 1.0)
	var yellow_l = MeshInstance3D.new()
	yellow_l.name = "LeftYellowLine"
	yellow_l.mesh = ml_mesh
	yellow_l.material_override = mat_yellow
	yellow_l.position = Vector3(-14.5, -0.05, 10.0)
	markings.add_child(yellow_l)
	yellow_l.owner = stage

	var yellow_r = MeshInstance3D.new()
	yellow_r.name = "RightYellowLine"
	yellow_r.mesh = ml_mesh
	yellow_r.material_override = mat_yellow
	yellow_r.position = Vector3(16.5, -0.05, 10.0)
	markings.add_child(yellow_r)
	yellow_r.owner = stage

	var grid_slots = Node3D.new()
	grid_slots.name = "StartingGridBoxes"
	markings.add_child(grid_slots)
	grid_slots.owner = stage

	var kerbs = Node3D.new()
	kerbs.name = "ApexKerbs"
	markings.add_child(kerbs)
	kerbs.owner = stage
	for k in range(12):
		var kerb_part = MeshInstance3D.new()
		kerb_part.name = "Kerb_" + str(k)
		var kp_mesh = BoxMesh.new()
		kp_mesh.size = Vector3(0.5, 0.02, 0.8)
		kerb_part.mesh = kp_mesh
		kerb_part.position = Vector3(-15.0, -0.05, -5.0 + float(k)*1.0)
		kerbs.add_child(kerb_part)
		kerb_part.owner = stage

	var skids = Node3D.new()
	skids.name = "TireSkidmarks"
	markings.add_child(skids)
	skids.owner = stage
	for s in range(4):
		var skid = MeshInstance3D.new()
		skid.name = "Skid_" + str(s)
		var sk_mesh = BoxMesh.new()
		sk_mesh.size = Vector3(0.28, 0.002, 6.0)
		skid.mesh = sk_mesh
		skid.position = Vector3(-12.0, -0.05, float(s)*3.0)
		skids.add_child(skid)
		skid.owner = stage

	# =========================================================================
	# 4. ILLUMINATED BILLBOARD ("RACING GAME")
	# =========================================================================
	var bb_root = Node3D.new()
	bb_root.name = "Billboard"
	bb_root.position = Vector3(6.2, 0, 8.2)
	bb_root.rotation_degrees = Vector3(0, 24.0, 0)
	stage.add_child(bb_root)
	bb_root.owner = stage

	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.24
	pole_mesh.bottom_radius = 0.30
	pole_mesh.height = 7.8

	var pole_l = MeshInstance3D.new()
	pole_l.name = "PoleLeft"
	pole_l.mesh = pole_mesh
	pole_l.material_override = mat_metal
	pole_l.position = Vector3(-2.8, 3.9, 0)
	bb_root.add_child(pole_l)
	pole_l.owner = stage

	var pole_r = MeshInstance3D.new()
	pole_r.name = "PoleRight"
	pole_r.mesh = pole_mesh
	pole_r.material_override = mat_metal
	pole_r.position = Vector3(4.0, 3.9, 0)
	bb_root.add_child(pole_r)
	pole_r.owner = stage

	var bb_face = MeshInstance3D.new()
	bb_face.name = "BillboardFace"
	var face_mesh = QuadMesh.new()
	face_mesh.size = Vector2(11.4, 4.6)
	bb_face.mesh = face_mesh
	bb_face.material_override = mat_bb
	bb_face.position = Vector3(0.6, 5.25, -0.10)
	bb_face.rotation_degrees = Vector3(0, 180.0, 0)
	bb_root.add_child(bb_face)
	bb_face.owner = stage

	var bb_frame = MeshInstance3D.new()
	bb_frame.name = "FrameBacking"
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(11.6, 4.8, 0.22)
	bb_frame.mesh = frame_mesh
	bb_frame.material_override = mat_metal
	bb_frame.position = Vector3(0.6, 5.25, 0.08)
	bb_root.add_child(bb_frame)
	bb_frame.owner = stage

	var catwalk = MeshInstance3D.new()
	catwalk.name = "Catwalk"
	var cw_mesh = BoxMesh.new()
	cw_mesh.size = Vector3(11.8, 0.10, 0.70)
	catwalk.mesh = cw_mesh
	catwalk.material_override = mat_metal
	catwalk.position = Vector3(0.6, 2.95, -0.32)
	bb_root.add_child(catwalk)
	catwalk.owner = stage

	# =========================================================================
	# 5. PALM TREE
	# =========================================================================
	var palm_root = Node3D.new()
	palm_root.name = "HeroPalmTree"
	palm_root.position = Vector3(8.5, 0, 7.2)
	stage.add_child(palm_root)
	palm_root.owner = stage

	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.15
	t_mesh.bottom_radius = 0.26
	t_mesh.height = 4.8
	trunk.mesh = t_mesh
	trunk.material_override = mat_palm_trunk
	trunk.position = Vector3(0, 2.4, 0)
	trunk.rotation_degrees = Vector3(0, 0, -4.5)
	palm_root.add_child(trunk)
	trunk.owner = stage

	var crown = Node3D.new()
	crown.name = "FrondsCrown"
	crown.position = Vector3(0.20, 4.7, 0)
	palm_root.add_child(crown)
	crown.owner = stage

	var frond_mesh = QuadMesh.new()
	frond_mesh.size = Vector2(1.6, 3.4)
	for i in range(10):
		var ang = float(i) * 36.0
		var frond = MeshInstance3D.new()
		frond.name = "Frond_" + str(i)
		frond.mesh = frond_mesh
		frond.material_override = mat_palm_leaf
		frond.rotation_degrees = Vector3(-35.0, ang, 0)
		frond.position = Vector3(0, 0.2, 0)
		crown.add_child(frond)
		frond.owner = stage

	# =========================================================================
	# 6. ARCHITECTURAL SHOWROOM BUILDINGS
	# =========================================================================
	var pit_mesh = QuadMesh.new()
	pit_mesh.size = Vector2(28.0, 11.5)
	var b_pit = MeshInstance3D.new()
	b_pit.name = "RoadsidePitShowroom"
	b_pit.mesh = pit_mesh
	b_pit.material_override = mat_b_left
	b_pit.position = Vector3(-1.8, 5.75, 14.8)
	b_pit.rotation_degrees = Vector3(0, 180.0 + 24.0, 0)
	stage.add_child(b_pit)
	b_pit.owner = stage

	var tower_mesh = QuadMesh.new()
	tower_mesh.size = Vector2(34.0, 20.0)
	var b_tower = MeshInstance3D.new()
	b_tower.name = "RoadsideRaceTower"
	b_tower.mesh = tower_mesh
	b_tower.material_override = mat_b_right
	b_tower.position = Vector3(18.2, 10.0, 19.5)
	b_tower.rotation_degrees = Vector3(0, 180.0 + 24.0, 0)
	stage.add_child(b_tower)
	b_tower.owner = stage

	# Save showcase stage
	var packed_stage = PackedScene.new()
	packed_stage.pack(stage)
	ResourceSaver.save(packed_stage, "res://scenes/environment/showcase_stage.tscn")
	print("SUCCESS: Saved res://scenes/environment/showcase_stage.tscn")
	stage.free()

	# -------------------------------------------------------------------------
	# 2. UPDATE HOME_SCREEN.TSCN (ShowcaseCar position & lighting balance)
	# -------------------------------------------------------------------------
	var home_packed = load("res://scenes/main/home_screen.tscn") as PackedScene
	var home = home_packed.instantiate()

	var car: ShowcaseCar = home.get_node("ShowcaseCar")
	car.transform.basis = Basis(Vector3(-0.46947, 0, -0.88295), Vector3(0, 1, 0), Vector3(0.88295, 0, -0.46947))
	car.position = Vector3(1.35, 0.19, 0.65)
	car.current_paint_color = Color(0.92, 0.18, 0.12, 1.0) # Radiant Racing Red

	# Lighting enhancement
	var fill = home.get_node_or_null("FillCool") as DirectionalLight3D
	if fill:
		fill.light_energy = 0.75 # Soft fill to highlight car contours

	var packed_home = PackedScene.new()
	packed_home.pack(home)
	ResourceSaver.save(packed_home, "res://scenes/main/home_screen.tscn")
	print("SUCCESS: Saved res://scenes/main/home_screen.tscn with tuned pose & lighting")
	home.free()

	quit(0)

