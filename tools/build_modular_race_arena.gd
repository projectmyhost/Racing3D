@tool
extends SceneTree

func _init():
	print("=== STEP 2: BUILDING FULL 3D RACING ARENA ENVIRONMENT ===")
	
	var root_scene = Node3D.new()
	root_scene.name = "RaceTrack3D"
	var track_script = load("res://scripts/race/RaceTrack3D.gd")
	root_scene.set_script(track_script)

	# 1. Daytime Environment & Lighting (Matching Atomic Realm Showcase)
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = load("res://assets/materials/environments/env_daytime.tres") as Environment
	if not env:
		env = Environment.new()
		env.background_mode = Environment.BG_SKY
	env_node.environment = env
	root_scene.add_child(env_node)
	env_node.owner = root_scene

	var sun = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.position = Vector3(50.0, 60.0, 40.0)
	sun.look_at_from_position(Vector3(50.0, 60.0, 40.0), Vector3(30.0, 0.0, 36.0))
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.directional_shadow_max_distance = 150.0
	root_scene.add_child(sun)
	sun.owner = root_scene

	var fill = DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.position = Vector3(-40.0, 40.0, -30.0)
	fill.look_at_from_position(Vector3(-40.0, 40.0, -30.0), Vector3(30.0, 0.0, 36.0))
	fill.light_color = Color(0.60, 0.70, 0.88)
	fill.light_energy = 0.45
	root_scene.add_child(fill)
	fill.owner = root_scene

	# 2. CONTINUOUS GREEN GROUND TERRAIN (ZERO VOID HOLES!)
	var ground = MeshInstance3D.new()
	ground.name = "GroundTerrain"
	var g_mesh = PlaneMesh.new()
	g_mesh.size = Vector2(400, 400)
	ground.mesh = g_mesh
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.38, 0.72, 0.52) # Vibrant Atomic Realm Grass
	g_mat.roughness = 0.85
	ground.material_override = g_mat
	ground.position = Vector3(30.0, -0.01, 36.0)
	root_scene.add_child(ground)
	ground.owner = root_scene

	# Sand / Dirt runoff patch near Turn 1
	var runoff = MeshInstance3D.new()
	runoff.name = "SandRunoff"
	var ro_mesh = PlaneMesh.new()
	ro_mesh.size = Vector2(36.0, 24.0)
	runoff.mesh = ro_mesh
	var ro_mat = StandardMaterial3D.new()
	ro_mat.albedo_color = Color(0.86, 0.76, 0.52)
	ro_mat.roughness = 0.9
	runoff.material_override = ro_mat
	runoff.position = Vector3(-8.0, 0.01, 76.0)
	root_scene.add_child(runoff)
	runoff.owner = root_scene

	# 3. MODULAR ROAD ASSETS
	var road1_p = load("res://assets/models/roads/Road1.glb") as PackedScene
	var corner_p = load("res://assets/models/roads/Road10_90angle_Corner.glb") as PackedScene
	var road2_t_p = load("res://assets/models/roads/Road2_T.glb") as PackedScene
	var road2_x_p = load("res://assets/models/roads/Road2_X.glb") as PackedScene
	var lamp_p = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var tree_p = load("res://assets/models/roads/Tree3.glb") as PackedScene
	var tree4_p = load("res://assets/models/roads/Tree4.glb") as PackedScene
	var barrier_p = load("res://assets/models/roads/road_barrier_1.glb") as PackedScene
	var cone_p = load("res://assets/models/roads/hazzard_cone_1.glb") as PackedScene
	var barrel_p = load("res://assets/models/roads/traffic_barell_1.glb") as PackedScene
	var gantry_p = load("res://assets/models/roads/traffic_light_1.glb") as PackedScene

	# Road material
	var mat_road = StandardMaterial3D.new()
	var tex_road = load("res://assets/models/roads/Road1_B_dotted_white.png") as Texture2D
	mat_road.albedo_texture = tex_road
	mat_road.roughness = 0.42
	mat_road.metallic = 0.08
	mat_road.cull_mode = BaseMaterial3D.CULL_BACK

	var track_container = Node3D.new()
	track_container.name = "TrackTiles"
	root_scene.add_child(track_container)
	track_container.owner = root_scene

	# -------------------------------------------------------------------------
	# CIRCUIT TRACK TILES (12m GRID)
	# -------------------------------------------------------------------------
	# Outer circuit loop:
	# West Straight (X = 0, Z = 1..5)
	# Turn 1 at (0, 6)
	# North Straight (Z = 6, X = 1..4)
	# Turn 2 at (5, 6)
	# East Straight (X = 5, Z = 5..1)
	# Turn 3 at (5, 0)
	# South Straight (Z = 0, X = 4..1)
	# Turn 4 at (0, 0)
	var circuit_tiles = [
		# Start/Finish Straight (along Z, heading +Z)
		{"x": 0, "z": 1, "type": "road1", "rot": 0.0},
		{"x": 0, "z": 2, "type": "road1", "rot": 0.0},
		{"x": 0, "z": 3, "type": "road1", "rot": 0.0},
		{"x": 0, "z": 4, "type": "road1", "rot": 0.0}, # Overpass crosses above here!
		{"x": 0, "z": 5, "type": "road1", "rot": 0.0}, # Striped Arch is here!
		# Turn 1 (+Z to +X)
		{"x": 0, "z": 6, "type": "corner", "rot": 0.0},
		# North Straight (along X, heading +X)
		{"x": 1, "z": 6, "type": "road1", "rot": 90.0},
		{"x": 2, "z": 6, "type": "road1", "rot": 90.0},
		{"x": 3, "z": 6, "type": "road1", "rot": 90.0},
		{"x": 4, "z": 6, "type": "road1", "rot": 90.0},
		# Turn 2 (+X to -Z)
		{"x": 5, "z": 6, "type": "corner", "rot": 90.0},
		# East Straight (along Z, heading -Z)
		{"x": 5, "z": 5, "type": "road1", "rot": 180.0},
		{"x": 5, "z": 4, "type": "road1", "rot": 180.0},
		{"x": 5, "z": 3, "type": "road1", "rot": 180.0},
		{"x": 5, "z": 2, "type": "road1", "rot": 180.0},
		{"x": 5, "z": 1, "type": "road1", "rot": 180.0},
		# Turn 3 (-Z to -X)
		{"x": 5, "z": 0, "type": "corner", "rot": 180.0},
		# South Straight (along X, heading -X)
		{"x": 4, "z": 0, "type": "road1", "rot": 270.0},
		{"x": 3, "z": 0, "type": "road1", "rot": 270.0},
		{"x": 2, "z": 0, "type": "road1", "rot": 270.0},
		{"x": 1, "z": 0, "type": "road1", "rot": 270.0},
		# Turn 4 (-X to +Z)
		{"x": 0, "z": 0, "type": "corner", "rot": 270.0},

		# Inner Plaza Connections (T-Junctions and Crossroad)
		{"x": 2, "z": 2, "type": "road1", "rot": 0.0},
		{"x": 2, "z": 3, "type": "road2_x", "rot": 0.0},
		{"x": 2, "z": 4, "type": "road1", "rot": 0.0},
		{"x": 3, "z": 3, "type": "road1", "rot": 90.0}
	]

	for i in range(circuit_tiles.size()):
		var t_data = circuit_tiles[i]
		var gx = t_data["x"]
		var gz = t_data["z"]
		var pos = Vector3(float(gx) * 12.0, 0.0, float(gz) * 12.0)
		var rot_y = t_data["rot"]
		
		var tile_inst: Node3D = null
		match t_data["type"]:
			"road1":
				if road1_p: tile_inst = road1_p.instantiate()
			"corner":
				if corner_p: tile_inst = corner_p.instantiate()
			"road2_t":
				if road2_t_p: tile_inst = road2_t_p.instantiate()
			"road2_x":
				if road2_x_p: tile_inst = road2_x_p.instantiate()
				
		if tile_inst:
			tile_inst.name = "Tile_%d_%s" % [i, t_data["type"]]
			tile_inst.position = pos
			tile_inst.rotation_degrees = Vector3(0.0, rot_y, 0.0)
			track_container.add_child(tile_inst)
			tile_inst.owner = root_scene
			for c in tile_inst.get_children():
				c.owner = root_scene
				if c is MeshInstance3D:
					c.material_override = mat_road

	# -------------------------------------------------------------------------
	# 4. ELEVATED HIGHWAY OVERPASS (FLYOVER BRIDGE AT Y = 4.5m)
	# (As shown prominently in user reference photo media_1794492512238_7db41990)
	# -------------------------------------------------------------------------
	var overpass_group = Node3D.new()
	overpass_group.name = "ElevatedOverpassBridge"
	root_scene.add_child(overpass_group)
	overpass_group.owner = root_scene

	var mat_pillar = StandardMaterial3D.new()
	mat_pillar.albedo_color = Color(0.72, 0.74, 0.76) # Clean smooth concrete pillar
	mat_pillar.roughness = 0.5
	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.55
	pillar_mesh.bottom_radius = 0.65
	pillar_mesh.height = 4.5

	# Elevated bridge deck tiles (4 tiles spanning across X = -12m to +36m at Z = 48m, Y = 4.5m)
	for b_idx in range(5):
		var bx = -12.0 + float(b_idx) * 12.0
		var bridge_tile = road1_p.instantiate()
		bridge_tile.name = "BridgeTile_" + str(b_idx)
		bridge_tile.position = Vector3(bx, 4.5, 48.0)
		bridge_tile.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		overpass_group.add_child(bridge_tile)
		bridge_tile.owner = root_scene
		for c in bridge_tile.get_children():
			c.owner = root_scene
			if c is MeshInstance3D:
				c.material_override = mat_road

		# Support pillars underneath
		if b_idx > 0 and b_idx < 4:
			for p_side in [-4.8, 4.8]:
				var pil = MeshInstance3D.new()
				pil.name = "Pillar_%d_%d" % [b_idx, 0 if p_side < 0 else 1]
				pil.mesh = pillar_mesh
				pil.material_override = mat_pillar
				pil.position = Vector3(bx, 2.25, 48.0 + p_side)
				overpass_group.add_child(pil)
				pil.owner = root_scene

		# Bridge guardrails
		if barrier_p:
			for bar_i in range(5):
				var b_pos_x = bx - 5.0 + float(bar_i) * 2.4
				var bar_top = barrier_p.instantiate()
				bar_top.position = Vector3(b_pos_x, 4.98, 48.0 - 5.2)
				bar_top.rotation_degrees = Vector3(0.0, 90.0, 0.0)
				overpass_group.add_child(bar_top)
				bar_top.owner = root_scene
				for c in bar_top.get_children(): c.owner = root_scene

				var bar_bot = barrier_p.instantiate()
				bar_bot.position = Vector3(b_pos_x, 4.98, 48.0 + 5.2)
				bar_bot.rotation_degrees = Vector3(0.0, -90.0, 0.0)
				overpass_group.add_child(bar_bot)
				bar_bot.owner = root_scene
				for c in bar_bot.get_children(): c.owner = root_scene

	# Overpass Incline Ramps (leading down to ground)
	var ramp_mesh = BoxMesh.new()
	ramp_mesh.size = Vector3(14.0, 0.35, 11.6)
	var ramp_l = MeshInstance3D.new()
	ramp_l.name = "InclineRampWest"
	ramp_l.mesh = ramp_mesh
	ramp_l.material_override = mat_road
	ramp_l.position = Vector3(-25.0, 2.25, 48.0)
	ramp_l.rotation_degrees = Vector3(0.0, 0.0, 18.0)
	overpass_group.add_child(ramp_l)
	ramp_l.owner = root_scene

	var ramp_r = MeshInstance3D.new()
	ramp_r.name = "InclineRampEast"
	ramp_r.mesh = ramp_mesh
	ramp_r.material_override = mat_road
	ramp_r.position = Vector3(49.0, 2.25, 48.0)
	ramp_r.rotation_degrees = Vector3(0.0, 0.0, -18.0)
	overpass_group.add_child(ramp_r)
	ramp_r.owner = root_scene

	# -------------------------------------------------------------------------
	# 5. PIT BUILDING / GRANDSTAND SHOWROOM FACILITY
	# (Beside Start/Finish straight at X = 8.8m, Z = 24m)
	# -------------------------------------------------------------------------
	var pit_group = Node3D.new()
	pit_group.name = "PitBuildingGrandstand"
	root_scene.add_child(pit_group)
	pit_group.owner = root_scene

	# Lower Paddock Garage (Red walls with white trim)
	var mat_pit_red = StandardMaterial3D.new()
	mat_pit_red.albedo_color = Color(0.82, 0.18, 0.14)
	mat_pit_red.roughness = 0.4
	var mat_pit_white = StandardMaterial3D.new()
	mat_pit_white.albedo_color = Color(0.95, 0.95, 0.96)
	mat_pit_white.roughness = 0.3
	var mat_roof_cyan = StandardMaterial3D.new()
	mat_roof_cyan.albedo_color = Color(0.18, 0.45, 0.58) # Tiered curved cyan roof from reference
	mat_roof_cyan.roughness = 0.35

	var lower_base = MeshInstance3D.new()
	lower_base.name = "GarageLowerBase"
	var bm_lower = BoxMesh.new()
	bm_lower.size = Vector3(6.5, 3.8, 32.0)
	lower_base.mesh = bm_lower
	lower_base.material_override = mat_pit_red
	lower_base.position = Vector3(9.2, 1.9, 24.0)
	pit_group.add_child(lower_base)
	lower_base.owner = root_scene

	# Upper Grandstand Viewing Lounge
	var upper_lounge = MeshInstance3D.new()
	upper_lounge.name = "GrandstandUpperLounge"
	var bm_upper = BoxMesh.new()
	bm_upper.size = Vector3(6.2, 2.4, 30.0)
	upper_lounge.mesh = bm_upper
	upper_lounge.material_override = mat_pit_white
	upper_lounge.position = Vector3(9.2, 5.0, 24.0)
	pit_group.add_child(upper_lounge)
	upper_lounge.owner = root_scene

	# Tiered Sloped Cyan Roof
	var grand_roof = MeshInstance3D.new()
	grand_roof.name = "GrandstandCyanRoof"
	var bm_roof = BoxMesh.new()
	bm_roof.size = Vector3(7.4, 0.45, 33.0)
	grand_roof.mesh = bm_roof
	grand_roof.material_override = mat_roof_cyan
	grand_roof.position = Vector3(9.0, 6.4, 24.0)
	grand_roof.rotation_degrees = Vector3(0.0, 0.0, -8.0)
	pit_group.add_child(grand_roof)
	grand_roof.owner = root_scene

	# Pit Bays (4 open bays along front face)
	var mat_bay_dark = StandardMaterial3D.new()
	mat_bay_dark.albedo_color = Color(0.12, 0.12, 0.14)
	for bay_i in range(4):
		var bay = MeshInstance3D.new()
		bay.name = "PitBay_" + str(bay_i)
		var bay_mesh = BoxMesh.new()
		bay_mesh.size = Vector3(0.2, 2.6, 5.2)
		bay.mesh = bay_mesh
		bay.material_override = mat_bay_dark
		bay.position = Vector3(5.9, 1.3, 14.0 + float(bay_i) * 6.8)
		pit_group.add_child(bay)
		bay.owner = root_scene

	# Add real 3D building models behind pit (Town background)
	var b1_mesh = load("res://assets/models/buildings/OBJ/Building1_Large.obj") as Mesh
	if b1_mesh:
		var b1 = MeshInstance3D.new()
		b1.name = "BackdropBuilding1"
		b1.mesh = b1_mesh
		b1.scale = Vector3(1.8, 1.8, 1.8)
		b1.position = Vector3(18.0, 0.0, 10.0)
		pit_group.add_child(b1)
		b1.owner = root_scene

	var b2_mesh = load("res://assets/models/buildings/OBJ/Building2_Large.obj") as Mesh
	if b2_mesh:
		var b2 = MeshInstance3D.new()
		b2.name = "BackdropBuilding2"
		b2.mesh = b2_mesh
		b2.scale = Vector3(1.7, 1.7, 1.7)
		b2.position = Vector3(18.0, 0.0, 38.0)
		pit_group.add_child(b2)
		b2.owner = root_scene

	# -------------------------------------------------------------------------
	# 6. START / FINISH GANTRY & CHECKERED LINE
	# (At X = 0, Z = 14m)
	# -------------------------------------------------------------------------
	var gantry_group = Node3D.new()
	gantry_group.name = "StartFinishGantry"
	root_scene.add_child(gantry_group)
	gantry_group.owner = root_scene

	var mat_gantry_green = StandardMaterial3D.new()
	mat_gantry_green.albedo_color = Color(0.12, 0.42, 0.35) # Atomic Realm Racing Green
	mat_gantry_green.roughness = 0.35
	var mat_light_red = StandardMaterial3D.new()
	mat_light_red.albedo_color = Color(1.0, 0.1, 0.1)
	mat_light_red.emission_enabled = true
	mat_light_red.emission = Color(1.0, 0.1, 0.1)
	mat_light_red.emission_energy_multiplier = 3.0

	# Left & Right Gantry Towers
	var tower_mesh = BoxMesh.new()
	tower_mesh.size = Vector3(0.6, 6.8, 0.6)
	var tower_l = MeshInstance3D.new()
	tower_l.name = "GantryTowerL"
	tower_l.mesh = tower_mesh
	tower_l.material_override = mat_gantry_green
	tower_l.position = Vector3(-5.5, 3.4, 14.0)
	gantry_group.add_child(tower_l)
	tower_l.owner = root_scene

	var tower_r = MeshInstance3D.new()
	tower_r.name = "GantryTowerR"
	tower_r.mesh = tower_mesh
	tower_r.material_override = mat_gantry_green
	tower_r.position = Vector3(5.5, 3.4, 14.0)
	gantry_group.add_child(tower_r)
	tower_r.owner = root_scene

	# Overhead Crossbeam Truss
	var truss_mesh = BoxMesh.new()
	truss_mesh.size = Vector3(11.6, 1.4, 0.8)
	var truss = MeshInstance3D.new()
	truss.name = "GantryTruss"
	truss.mesh = truss_mesh
	truss.material_override = mat_gantry_green
	truss.position = Vector3(0.0, 6.2, 14.0)
	gantry_group.add_child(truss)
	truss.owner = root_scene

	# Start Light Pods
	for l_idx in range(5):
		var pod = MeshInstance3D.new()
		pod.name = "StartLight_" + str(l_idx)
		var pod_mesh = CylinderMesh.new()
		pod_mesh.top_radius = 0.22
		pod_mesh.bottom_radius = 0.22
		pod_mesh.height = 0.3
		pod.mesh = pod_mesh
		pod.material_override = mat_light_red
		pod.position = Vector3(-2.0 + float(l_idx) * 1.0, 5.8, 14.4)
		pod.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		gantry_group.add_child(pod)
		pod.owner = root_scene

	# Checkered Finish Line Decal Mesh on the road
	var finish_line = MeshInstance3D.new()
	finish_line.name = "CheckeredFinishLine"
	var fl_mesh = PlaneMesh.new()
	fl_mesh.size = Vector2(9.2, 1.8)
	finish_line.mesh = fl_mesh
	var mat_checkered = StandardMaterial3D.new()
	mat_checkered.albedo_color = Color(0.98, 0.98, 0.98)
	mat_checkered.roughness = 0.3
	finish_line.material_override = mat_checkered
	finish_line.position = Vector3(0.0, 0.21, 14.0)
	gantry_group.add_child(finish_line)
	finish_line.owner = root_scene

	# -------------------------------------------------------------------------
	# 7. STRIPED INFLATABLE RACING ARCH (At X = 0, Z = 60m)
	# (Orange/White curved striped arch from reference photo)
	# -------------------------------------------------------------------------
	var arch_group = Node3D.new()
	arch_group.name = "StripedRacingArch"
	root_scene.add_child(arch_group)
	arch_group.owner = root_scene

	var mat_arch_orange = StandardMaterial3D.new()
	mat_arch_orange.albedo_color = Color(0.96, 0.42, 0.15)
	mat_arch_orange.roughness = 0.35
	var mat_arch_white = StandardMaterial3D.new()
	mat_arch_white.albedo_color = Color(0.96, 0.96, 0.98)
	mat_arch_white.roughness = 0.35

	for seg in range(12):
		var ang = PI * float(seg) / 11.0 # 0 to PI semi-circle
		var ax = -cos(ang) * 5.8
		var ay = sin(ang) * 5.6 + 0.2
		var seg_mesh = CylinderMesh.new()
		seg_mesh.top_radius = 0.65
		seg_mesh.bottom_radius = 0.65
		seg_mesh.height = 1.3
		var seg_inst = MeshInstance3D.new()
		seg_inst.name = "ArchSeg_" + str(seg)
		seg_inst.mesh = seg_mesh
		seg_inst.material_override = mat_arch_orange if seg % 2 == 0 else mat_arch_white
		seg_inst.position = Vector3(ax, ay, 60.0)
		seg_inst.rotation_degrees = Vector3(0.0, 0.0, rad_to_deg(ang) - 90.0)
		arch_group.add_child(seg_inst)
		seg_inst.owner = root_scene

	# -------------------------------------------------------------------------
	# 8. ROUNDABOUT / INNER PLAZA (At X = 30m, Z = 36m)
	# -------------------------------------------------------------------------
	var roundabout_group = Node3D.new()
	roundabout_group.name = "RoundaboutPlaza"
	root_scene.add_child(roundabout_group)
	roundabout_group.owner = root_scene

	# Green Center Island Lawn
	var island = MeshInstance3D.new()
	island.name = "RoundaboutIsland"
	var isl_mesh = CylinderMesh.new()
	isl_mesh.top_radius = 4.2
	isl_mesh.bottom_radius = 4.6
	isl_mesh.height = 0.48
	island.mesh = isl_mesh
	island.material_override = g_mat
	island.position = Vector3(30.0, 0.24, 36.0)
	roundabout_group.add_child(island)
	island.owner = root_scene

	# Center Pine Tree in Roundabout
	if tree_p:
		var c_tree = tree_p.instantiate()
		c_tree.name = "CenterRoundaboutTree"
		c_tree.position = Vector3(30.0, 0.48, 36.0)
		c_tree.scale = Vector3(1.4, 1.4, 1.4)
		roundabout_group.add_child(c_tree)
		c_tree.owner = root_scene
		for c in c_tree.get_children(): c.owner = root_scene

	# Traffic Barrels around roundabout island
	if barrel_p:
		for bar_idx in range(6):
			var b_ang = float(bar_idx) * (TAU / 6.0)
			var bx = 30.0 + cos(b_ang) * 5.2
			var bz = 36.0 + sin(b_ang) * 5.2
			var bar = barrel_p.instantiate()
			bar.name = "TrafficBarrel_" + str(bar_idx)
			bar.position = Vector3(bx, 0.22, bz)
			roundabout_group.add_child(bar)
			bar.owner = root_scene
			for c in bar.get_children(): c.owner = root_scene

	# -------------------------------------------------------------------------
	# 9. TRACKSIDE FURNITURE (Trees, Street Lamps, Corner Apex Kerbs)
	# -------------------------------------------------------------------------
	var props_group = Node3D.new()
	props_group.name = "TracksideProps"
	root_scene.add_child(props_group)
	props_group.owner = root_scene

	# Trees along grassy fields
	var tree_coords = [
		Vector3(-8.0, 0.0, 4.0),
		Vector3(-9.0, 0.0, 20.0),
		Vector3(-8.5, 0.0, 36.0),
		Vector3(14.0, 0.0, 68.0),
		Vector3(26.0, 0.0, 70.0),
		Vector3(42.0, 0.0, 68.0),
		Vector3(68.0, 0.0, 50.0),
		Vector3(68.0, 0.0, 30.0),
		Vector3(68.0, 0.0, 10.0),
		Vector3(45.0, 0.0, -8.0),
		Vector3(25.0, 0.0, -8.0),
		Vector3(8.0, 0.0, -8.0),
		Vector3(18.0, 0.0, 20.0),
		Vector3(42.0, 0.0, 22.0)
	]
	for t_i in range(tree_coords.size()):
		var t_pos = tree_coords[t_i]
		var tree_res = tree_p if t_i % 2 == 0 else tree4_p
		if tree_res:
			var tree = tree_res.instantiate()
			tree.name = "FieldTree_" + str(t_i)
			tree.position = t_pos
			var s = 1.1 + (t_i % 3) * 0.15
			tree.scale = Vector3(s, s, s)
			props_group.add_child(tree)
			tree.owner = root_scene
			for c in tree.get_children(): c.owner = root_scene

	# Street Lamps along track corners
	if lamp_p:
		var lamp_coords = [
			Vector3(-5.4, 0.475, 4.0),
			Vector3(-5.4, 0.475, 28.0),
			Vector3(4.0, 0.475, 77.4),
			Vector3(32.0, 0.475, 77.4),
			Vector3(65.4, 0.475, 52.0),
			Vector3(65.4, 0.475, 18.0),
			Vector3(48.0, 0.475, -5.4),
			Vector3(16.0, 0.475, -5.4)
		]
		for l_i in range(lamp_coords.size()):
			var lamp = lamp_p.instantiate()
			lamp.name = "TrackLamp_" + str(l_i)
			lamp.position = lamp_coords[l_i]
			props_group.add_child(lamp)
			lamp.owner = root_scene
			for c in lamp.get_children(): c.owner = root_scene

	# Corner Apex Kerbs (Red and white alternating rumble strips)
	var mat_kerb_red = StandardMaterial3D.new()
	mat_kerb_red.albedo_color = Color(0.92, 0.15, 0.12)
	var mat_kerb_white = StandardMaterial3D.new()
	mat_kerb_white.albedo_color = Color(0.96, 0.96, 0.98)
	var kerb_corners = [
		{"cx": 0.0, "cz": 72.0, "dx": 1.0, "dz": -1.0}, # Turn 1
		{"cx": 60.0, "cz": 72.0, "dx": -1.0, "dz": -1.0}, # Turn 2
		{"cx": 60.0, "cz": 0.0, "dx": -1.0, "dz": 1.0}, # Turn 3
		{"cx": 0.0, "cz": 0.0, "dx": 1.0, "dz": 1.0} # Turn 4
	]
	var kerb_part_mesh = BoxMesh.new()
	kerb_part_mesh.size = Vector3(0.6, 0.08, 1.2)
	for kc in kerb_corners:
		for k_i in range(8):
			var kp = MeshInstance3D.new()
			kp.name = "ApexKerb_%d_%d" % [int(kc["cx"]), k_i]
			kp.mesh = kerb_part_mesh
			kp.material_override = mat_kerb_red if k_i % 2 == 0 else mat_kerb_white
			kp.position = Vector3(kc["cx"] + float(k_i) * kc["dx"] * 1.1, 0.22, kc["cz"] + float(k_i) * kc["dz"] * 1.1)
			props_group.add_child(kp)
			kp.owner = root_scene

	# Hazard Cones near Pit Entrance
	if cone_p:
		for c_i in range(4):
			var cone = cone_p.instantiate()
			cone.name = "PitHazardCone_" + str(c_i)
			cone.position = Vector3(5.2, 0.22, 10.0 + float(c_i) * 1.8)
			props_group.add_child(cone)
			cone.owner = root_scene
			for c in cone.get_children(): c.owner = root_scene

	# -------------------------------------------------------------------------
	# 10. CHECKPOINTS & LAP TIMING SYSTEM
	# -------------------------------------------------------------------------
	var checkpoints_group = Node3D.new()
	checkpoints_group.name = "Checkpoints"
	root_scene.add_child(checkpoints_group)
	checkpoints_group.owner = root_scene

	var chk_positions = [
		Vector3(0.0, 1.5, 14.0),  # Checkpoint 0: Start/Finish
		Vector3(30.0, 1.5, 72.0), # Checkpoint 1: North Straight
		Vector3(60.0, 1.5, 36.0), # Checkpoint 2: East Straight
		Vector3(24.0, 1.5, 0.0)   # Checkpoint 3: South Straight
	]
	var chk_box = BoxShape3D.new()
	chk_box.size = Vector3(16.0, 5.0, 6.0)

	for chk_i in range(chk_positions.size()):
		var chk_area = Area3D.new()
		chk_area.name = "Checkpoint_" + str(chk_i)
		chk_area.position = chk_positions[chk_i]
		if chk_i == 1 or chk_i == 3:
			chk_area.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		chk_area.collision_layer = 0
		chk_area.collision_mask = 2 # Vehicle layer
		checkpoints_group.add_child(chk_area)
		chk_area.owner = root_scene
		
		var col = CollisionShape3D.new()
		col.name = "Shape"
		col.shape = chk_box
		chk_area.add_child(col)
		col.owner = root_scene

	# -------------------------------------------------------------------------
	# 11. PLAYABLE RACE CAR (CharacterBody3D)
	# -------------------------------------------------------------------------
	var car = CharacterBody3D.new()
	car.name = "RaceCar3D"
	var car_script = load("res://scripts/race/RaceCar3D.gd")
	car.set_script(car_script)
	car.collision_layer = 2
	car.collision_mask = 1
	# Position at starting grid behind start line, facing +Z
	car.position = Vector3(0.0, 0.22, 6.0)
	car.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	root_scene.add_child(car)
	car.owner = root_scene
	
	var car_col = CollisionShape3D.new()
	car_col.name = "CarCollision"
	var car_box = BoxShape3D.new()
	car_box.size = Vector3(2.2, 1.1, 4.4)
	car_col.shape = car_box
	car_col.position.y = 0.55
	car.add_child(car_col)
	car_col.owner = root_scene

	# -------------------------------------------------------------------------
	# 12. CHASE CAMERA (Smooth 3rd-Person Follow Camera)
	# -------------------------------------------------------------------------
	var cam = Camera3D.new()
	cam.name = "ChaseCamera"
	cam.current = true
	cam.fov = 55.0
	cam.near = 0.1
	cam.far = 450.0
	cam.position = Vector3(0.0, 3.4, -1.2)
	cam.look_at_from_position(Vector3(0.0, 3.4, -1.2), Vector3(0.0, 1.1, 6.0))
	root_scene.add_child(cam)
	cam.owner = root_scene

	# -------------------------------------------------------------------------
	# 13. IN-GAME RACING HUD (Lap counter, Speedometer, Timer, Clean Minimal)
	# -------------------------------------------------------------------------
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	root_scene.add_child(hud)
	hud.owner = root_scene

	var hud_root = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.layout_mode = 3
	hud_root.anchors_preset = Control.PRESET_FULL_RECT
	hud.add_child(hud_root)
	hud_root.owner = root_scene

	# Top Lap and Time Panel
	var top_panel = PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.layout_mode = 1
	top_panel.anchors_preset = Control.PRESET_TOP_WIDE
	top_panel.offset_left = 40.0
	top_panel.offset_top = 20.0
	top_panel.offset_right = -40.0
	top_panel.offset_bottom = 80.0
	hud_root.add_child(top_panel)
	top_panel.owner = root_scene

	var hbox = HBoxContainer.new()
	hbox.layout_mode = 1
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	top_panel.add_child(hbox)
	hbox.owner = root_scene

	var back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.unique_name_in_owner = true
	back_btn.text = "< EXIT RACE"
	back_btn.custom_minimum_size = Vector2(140, 48)
	hbox.add_child(back_btn)
	back_btn.owner = root_scene

	var lap_lbl = Label.new()
	lap_lbl.name = "LapLabel"
	lap_lbl.unique_name_in_owner = true
	lap_lbl.text = "LAP 1 / 3"
	lap_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(lap_lbl)
	lap_lbl.owner = root_scene

	var time_lbl = Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.unique_name_in_owner = true
	time_lbl.text = "00:00.000"
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(time_lbl)
	time_lbl.owner = root_scene

	var best_lbl = Label.new()
	best_lbl.name = "BestLabel"
	best_lbl.unique_name_in_owner = true
	best_lbl.text = "BEST: --:--.---"
	best_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(best_lbl)
	best_lbl.owner = root_scene

	# Bottom Speedometer
	var speed_box = VBoxContainer.new()
	speed_box.name = "Speedometer"
	speed_box.layout_mode = 1
	speed_box.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	speed_box.offset_left = -260.0
	speed_box.offset_top = -120.0
	speed_box.offset_right = -40.0
	speed_box.offset_bottom = -30.0
	hud_root.add_child(speed_box)
	speed_box.owner = root_scene

	var speed_lbl = Label.new()
	speed_lbl.name = "SpeedLabel"
	speed_lbl.unique_name_in_owner = true
	speed_lbl.text = "0 KM/H"
	speed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_box.add_child(speed_lbl)
	speed_lbl.owner = root_scene

	var speed_bar = ProgressBar.new()
	speed_bar.name = "SpeedBar"
	speed_bar.unique_name_in_owner = true
	speed_bar.max_value = 260.0
	speed_bar.show_percentage = false
	speed_bar.custom_minimum_size = Vector2(220, 16)
	speed_box.add_child(speed_bar)
	speed_bar.owner = root_scene

	# Finish Panel (hidden until finish)
	var finish_panel = PanelContainer.new()
	finish_panel.name = "FinishPanel"
	finish_panel.unique_name_in_owner = true
	finish_panel.visible = false
	finish_panel.layout_mode = 1
	finish_panel.anchors_preset = Control.PRESET_CENTER
	finish_panel.offset_left = -220.0
	finish_panel.offset_top = -140.0
	finish_panel.offset_right = 220.0
	finish_panel.offset_bottom = 140.0
	hud_root.add_child(finish_panel)
	finish_panel.owner = root_scene

	var f_vbox = VBoxContainer.new()
	finish_panel.add_child(f_vbox)
	f_vbox.owner = root_scene

	var f_title = Label.new()
	f_title.name = "FinishTitle"
	f_title.unique_name_in_owner = true
	f_title.text = "RACE COMPLETED!"
	f_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_vbox.add_child(f_title)
	f_title.owner = root_scene

	var f_stats = Label.new()
	f_stats.name = "FinishStats"
	f_stats.unique_name_in_owner = true
	f_stats.text = "Total Time: 00:00.000\nBest Lap: 00:00.000"
	f_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_vbox.add_child(f_stats)
	f_stats.owner = root_scene

	var f_btn = Button.new()
	f_btn.name = "FinishHomeBtn"
	f_btn.unique_name_in_owner = true
	f_btn.text = "RETURN TO MENU"
	f_vbox.add_child(f_btn)
	f_btn.owner = root_scene

	# Save packed scene
	var packed_track = PackedScene.new()
	packed_track.pack(root_scene)
	ResourceSaver.save(packed_track, "res://scenes/race/RaceTrack3D.tscn")
	print("SUCCESS: Saved res://scenes/race/RaceTrack3D.tscn")
	root_scene.free()
	
	quit(0)
