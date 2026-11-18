@tool
extends SceneTree

func _init() -> void:
	print("--- BUILDING CITY RACE TRACK SCENE ---")
	var scene_path = "res://scenes/race/RaceTrack3D.tscn"
	var packed = load(scene_path) as PackedScene
	if not packed:
		print("FAIL: cannot load RaceTrack3D.tscn")
		quit(1)
		return
		
	var root = packed.instantiate()
	get_root().add_child(root)
	
	# 1. Remove old modular track geometry nodes
	var old_nodes = [
		"GroundTerrain",
		"SandRunoff",
		"TrackTiles",
		"ElevatedOverpassBridge",
		"PitBuildingGrandstand",
		"StartFinishGantry",
		"StripedRacingArch",
		"RoundaboutPlaza",
		"TracksideProps",
		"CityMap"
	]
	for n_name in old_nodes:
		var n = root.get_node_or_null(n_name)
		if n:
			root.remove_child(n)
			n.free()
			print("Removed legacy node: ", n_name)
			
	# Remove old TrackColliders if present
	var old_col = root.get_node_or_null("TrackColliders")
	if old_col:
		root.remove_child(old_col)
		old_col.free()
		
	# 2. Instantiate and attach CityMap (Untitled.glb)
	var city_glb_path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var city_packed = load(city_glb_path) as PackedScene
	if not city_packed:
		print("FAIL: cannot load Untitled.glb")
		quit(1)
		return
		
	var city_map = city_packed.instantiate()
	city_map.name = "CityMap"
	city_map.scale = Vector3(100.0, 100.0, 100.0)
	root.add_child(city_map)
	city_map.owner = root
	
	# Wait two frames for global transforms to settle
	await process_frame
	await process_frame
	
	# 3. Extract road & ramp collision faces from city meshes
	print("Extracting all drivable surfaces, roads, ramps, and overpasses...")
	var mesh_instances: Array = []
	collect_meshes(city_map, mesh_instances)
	
	var all_road_faces: PackedVector3Array = PackedVector3Array()
	var road_mesh_count = 0
	
	for mi in mesh_instances:
		var mname = mi.name.to_lower()
		var pname = mi.get_parent().name.to_lower()
		
		# Skip non-solid distant sky backdrops and animated chevrons
		if "backdrop" in pname or "backdrop" in mname or "chevron" in pname:
			continue
		# Skip tree and shrub foliage leaves
		if "mdl_009" in pname or "mdl_010" in pname:
			continue
			
		# Include all city structural units (streets, ramps, flyovers, sidewalks, bases)
		if not (pname.begins_with("unit_") and "sub_" in mname):
			continue
			
		if mi.mesh:
			var faces = mi.mesh.get_faces()
			var gt = mi.global_transform
			for v in faces:
				all_road_faces.append(gt * v)
			road_mesh_count += 1
				
	print("Extracted ", road_mesh_count, " solid meshes with ", all_road_faces.size() / 3, " triangles.")
	
	# 4. Create TrackColliders StaticBody3D
	var track_body = StaticBody3D.new()
	track_body.name = "TrackColliders"
	track_body.collision_layer = 1
	track_body.collision_mask = 2
	root.add_child(track_body)
	track_body.owner = root
	
	var road_shape = ConcavePolygonShape3D.new()
	road_shape.set_faces(all_road_faces)
	road_shape.backface_collision = false
	
	var road_col = CollisionShape3D.new()
	road_col.name = "RoadSurfacesCollision"
	road_col.shape = road_shape
	track_body.add_child(road_col)
	road_col.owner = root
	
	# Safety ground floor slab under entire lower city grid at Y = 5.85
	var lower_ground = CollisionShape3D.new()
	lower_ground.name = "LowerCityFloorGround"
	var s_ground = BoxShape3D.new()
	s_ground.size = Vector3(2200.0, 2.0, 2200.0)
	lower_ground.shape = s_ground
	lower_ground.position = Vector3(0.0, 4.85, -240.0)
	track_body.add_child(lower_ground)
	lower_ground.owner = root
	
	# Outer safety boundary walls around the 1.4km x 1.2km city
	var bound_wall_north = CollisionShape3D.new()
	bound_wall_north.name = "BoundaryNorth"
	var s_ns = BoxShape3D.new()
	s_ns.size = Vector3(1800.0, 120.0, 20.0)
	bound_wall_north.shape = s_ns
	bound_wall_north.position = Vector3(0.0, 40.0, -800.0)
	track_body.add_child(bound_wall_north)
	bound_wall_north.owner = root
	
	var bound_wall_south = CollisionShape3D.new()
	bound_wall_south.name = "BoundarySouth"
	bound_wall_south.shape = s_ns
	bound_wall_south.position = Vector3(0.0, 40.0, 320.0)
	track_body.add_child(bound_wall_south)
	bound_wall_south.owner = root
	
	var bound_wall_west = CollisionShape3D.new()
	bound_wall_west.name = "BoundaryWest"
	var s_ew = BoxShape3D.new()
	s_ew.size = Vector3(20.0, 120.0, 1400.0)
	bound_wall_west.shape = s_ew
	bound_wall_west.position = Vector3(-800.0, 40.0, -240.0)
	track_body.add_child(bound_wall_west)
	bound_wall_west.owner = root
	
	var bound_wall_east = CollisionShape3D.new()
	bound_wall_east.name = "BoundaryEast"
	bound_wall_east.shape = s_ew
	bound_wall_east.position = Vector3(800.0, 40.0, -240.0)
	track_body.add_child(bound_wall_east)
	bound_wall_east.owner = root
	
	# Bottom catch net (Y = -2.0)
	var bottom_net = CollisionShape3D.new()
	bottom_net.name = "BottomSafetyNet"
	var s_bottom = BoxShape3D.new()
	s_bottom.size = Vector3(1800.0, 4.0, 1400.0)
	bottom_net.shape = s_bottom
	bottom_net.position = Vector3(0.0, -2.0, -240.0)
	track_body.add_child(bottom_net)
	bottom_net.owner = root
	
	# 5. Position RaceCar3D on the boulevard matching the user reference photo
	var car = root.get_node_or_null("RaceCar3D") as CharacterBody3D
	if car:
		car.position = Vector3(-30.0, 36.35, 146.0)
		car.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		car.collision_layer = 2
		car.collision_mask = 1
		print("Positioned RaceCar3D at: ", car.position, " rot=", car.rotation_degrees)
		
	# 6. Position ChaseCamera behind the car
	var cam = root.get_node_or_null("ChaseCamera") as Camera3D
	if cam:
		cam.position = Vector3(-37.0, 39.2, 146.0)
		cam.rotation_degrees = Vector3(-12.0, 90.0, 0.0)
		cam.fov = 60.0
		cam.far = 800.0
		print("Positioned ChaseCamera at: ", cam.position)
		
	# 7. Configure Checkpoints
	var checkpoints_node = root.get_node_or_null("Checkpoints")
	if checkpoints_node:
		var chk_positions = [
			Vector3(-30.0, 38.0, 146.0), # Start / Finish line
			Vector3(120.0, 38.0, 146.0), # Avenue straight end
			Vector3(80.0, 10.0, -380.0), # Lower city center
			Vector3(-100.0, 38.0, 146.0) # West boulevard return
		]
		for i in range(chk_positions.size()):
			var chk = checkpoints_node.get_node_or_null("Checkpoint_" + str(i)) as Area3D
			if chk:
				chk.position = chk_positions[i]
				var shape_node = chk.get_node_or_null("Shape") as CollisionShape3D
				if shape_node:
					var b_shape = BoxShape3D.new()
					b_shape.size = Vector3(32.0, 14.0, 32.0)
					shape_node.shape = b_shape
					
	# 8. Configure Lighting & Environment
	var env_node = root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node:
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.70, 0.76, 0.84)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.52, 0.58, 0.68)
		env.ambient_light_energy = 0.55
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 0.95
		env_node.environment = env
		
	var sun = root.get_node_or_null("SunLight") as DirectionalLight3D
	if sun:
		sun.rotation_degrees = Vector3(-45.0, 50.0, 0.0)
		sun.light_color = Color(1.0, 0.96, 0.90)
		sun.light_energy = 0.95
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 200.0
		sun.shadow_bias = 0.03
		
	var fill = root.get_node_or_null("FillLight") as DirectionalLight3D
	if fill:
		fill.rotation_degrees = Vector3(45.0, -130.0, 0.0)
		fill.light_color = Color(0.48, 0.54, 0.65)
		fill.light_energy = 0.35
		
	# 9. Pack and save the scene
	var new_packed = PackedScene.new()
	var pack_res = new_packed.pack(root)
	if pack_res == OK:
		ResourceSaver.save(new_packed, scene_path)
		print("SUCCESS: Saved new City Race Track to ", scene_path)
	else:
		print("FAIL: pack error ", pack_res)
		
	root.free()
	quit(0)

func collect_meshes(node: Node, list: Array) -> void:
	if node is MeshInstance3D:
		list.append(node)
	for c in node.get_children():
		collect_meshes(c, list)
