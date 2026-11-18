@tool
extends SceneTree

# Apply perfect collision architecture to scenes/race/RaceTrack3D.tscn

func _init() -> void:
	execute_fix.call_deferred()

func execute_fix() -> void:
	print("--- APPLYING PERFECT COLLISION SYSTEM TO RACETRACK3D ---")
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	if not p:
		print("FAIL: cannot load ", path)
		quit(1)
		return
		
	var root = p.instantiate()
	get_root().add_child(root)
	
	# Wait two frames for global transforms to settle accurately
	await process_frame
	await process_frame
	
	var city_map = root.get_node_or_null("CityMap") as Node3D
	if not city_map:
		print("FAIL: CityMap not found")
		root.free()
		quit(1)
		return
		
	var track_body = root.get_node_or_null("TrackColliders") as StaticBody3D
	if not track_body:
		track_body = StaticBody3D.new()
		track_body.name = "TrackColliders"
		track_body.collision_layer = 1
		track_body.collision_mask = 2
		root.add_child(track_body)
		track_body.owner = root
		
	# 1. Clean up old or orphan colliders in TrackColliders
	var to_remove: Array[Node] = []
	for c in track_body.get_children():
		var cname = c.name
		if cname == "LowerCityFloorGround" or cname == "PropsCollision" or cname == "PillarsAndPolesCollision":
			to_remove.append(c)
	for c in to_remove:
		track_body.remove_child(c)
		c.free()
		
	print("Removed orphan/legacy colliders")
	
	# 2. Extract meshes by category
	var all_city_meshes: Array[MeshInstance3D] = []
	collect_meshes(city_map, all_city_meshes)
	print("Total city meshes: ", all_city_meshes.size())
	
	var road_faces: PackedVector3Array = PackedVector3Array()
	var prop_faces: PackedVector3Array = PackedVector3Array()
	var pole_faces: PackedVector3Array = PackedVector3Array()
	
	var road_count = 0
	var prop_count = 0
	var pole_count = 0
	
	for mi in all_city_meshes:
		var pname = mi.get_parent().name.to_lower()
		var mname = mi.name.to_lower()
		
		# Skip non-solid sky backdrops and animated mid-air chevrons
		if "backdrop" in pname or "backdrop" in mname or "chevron" in pname:
			continue
		# Skip tree foliage/leaves so branches do not act as brick walls
		if "mdl_009" in pname or "mdl_010" in pname:
			continue
			
		var gt = mi.global_transform
		if not mi.mesh:
			continue
			
		var faces = mi.mesh.get_faces()
		
		# Road surfaces, curbs, flyovers, bridges, building structures
		if pname.begins_with("unit_") and "sub_" in mname:
			for v in faces:
				road_faces.append(gt * v)
			road_count += 1
		# Props: chairs, tables, kiosks, phone booths, vending machines, benches, AC units
		elif pname.begins_with("prop_"):
			for v in faces:
				prop_faces.append(gt * v)
			prop_count += 1
		# Instanced poles and pillars: street lamps, overpass pillars, bollards
		elif pname.begins_with("unit_") and "inst_" in mname:
			for v in faces:
				pole_faces.append(gt * v)
			pole_count += 1
			
	print("Extracted road/structure meshes: %d (%d triangles)" % [road_count, road_faces.size() / 3])
	print("Extracted prop meshes: %d (%d triangles)" % [prop_count, prop_faces.size() / 3])
	print("Extracted pole/pillar meshes: %d (%d triangles)" % [pole_count, pole_faces.size() / 3])
	
	# 3. Configure RoadSurfacesCollision (Trimesh ConcavePolygonShape3D)
	var road_col = track_body.get_node_or_null("RoadSurfacesCollision") as CollisionShape3D
	if not road_col:
		road_col = CollisionShape3D.new()
		road_col.name = "RoadSurfacesCollision"
		track_body.add_child(road_col)
		road_col.owner = root
	var road_shape = ConcavePolygonShape3D.new()
	road_shape.set_faces(road_faces)
	road_shape.backface_collision = false
	road_col.shape = road_shape
	
	# 4. Configure PropsCollision (Trimesh ConcavePolygonShape3D)
	var props_col = CollisionShape3D.new()
	props_col.name = "PropsCollision"
	var props_shape = ConcavePolygonShape3D.new()
	props_shape.set_faces(prop_faces)
	props_shape.backface_collision = false
	props_col.shape = props_shape
	track_body.add_child(props_col)
	props_col.owner = root
	
	# 5. Configure PillarsAndPolesCollision (Trimesh ConcavePolygonShape3D)
	var poles_col = CollisionShape3D.new()
	poles_col.name = "PillarsAndPolesCollision"
	var poles_shape = ConcavePolygonShape3D.new()
	poles_shape.set_faces(pole_faces)
	poles_shape.backface_collision = false
	poles_col.shape = poles_shape
	track_body.add_child(poles_col)
	poles_col.owner = root
	
	# 6. Configure Boundaries outside city bounds (prevent transparent walls)
	var bound_south = track_body.get_node_or_null("BoundarySouth") as CollisionShape3D
	if bound_south:
		bound_south.position = Vector3(0.0, 40.0, 520.0)
		var s_ns = BoxShape3D.new()
		s_ns.size = Vector3(1800.0, 120.0, 20.0)
		bound_south.shape = s_ns
		
	var bound_north = track_body.get_node_or_null("BoundaryNorth") as CollisionShape3D
	if bound_north:
		bound_north.position = Vector3(0.0, 40.0, -820.0)
		var s_ns = BoxShape3D.new()
		s_ns.size = Vector3(1800.0, 120.0, 20.0)
		bound_north.shape = s_ns
		
	var bound_west = track_body.get_node_or_null("BoundaryWest") as CollisionShape3D
	if bound_west:
		bound_west.position = Vector3(-820.0, 40.0, -150.0)
		var s_ew = BoxShape3D.new()
		s_ew.size = Vector3(20.0, 120.0, 1600.0)
		bound_west.shape = s_ew
		
	var bound_east = track_body.get_node_or_null("BoundaryEast") as CollisionShape3D
	if bound_east:
		bound_east.position = Vector3(820.0, 40.0, -150.0)
		var s_ew = BoxShape3D.new()
		s_ew.size = Vector3(20.0, 120.0, 1600.0)
		bound_east.shape = s_ew
		
	# 7. Configure BottomSafetyNet below lowest road
	var bottom_net = track_body.get_node_or_null("BottomSafetyNet") as CollisionShape3D
	if bottom_net:
		bottom_net.position = Vector3(0.0, -15.0, -150.0)
		var s_bot = BoxShape3D.new()
		s_bot.size = Vector3(1800.0, 4.0, 1600.0)
		bottom_net.shape = s_bot
		
	# 8. Configure RaceCar3D collision shape with beveled anti-seam profile
	var car = root.get_node_or_null("RaceCar3D") as CharacterBody3D
	if car:
		car.safe_margin = 0.08
		car.floor_snap_length = 0.8
		car.floor_max_angle = deg_to_rad(55.0)
		var car_col = car.get_node_or_null("CarCollision") as CollisionShape3D
		if car_col:
			car_col.shape = create_anti_seam_car_shape()
			car_col.position = Vector3.ZERO
			
	# 9. Pack and save the scene
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		ResourceSaver.save(packed, path)
		print("SUCCESS: Successfully saved updated RaceTrack3D scene")
	else:
		print("FAIL: pack error ", err)
		
	root.free()
	quit(0)

func create_anti_seam_car_shape() -> ConvexPolygonShape3D:
	var w = 0.95
	var w_in = 0.80
	var y_top = 1.05
	var y_mid = 0.55
	var y_bot = 0.10
	var y_front = 0.28
	var y_rear = 0.24
	var z_front = -1.90
	var z_f_in = -1.35
	var z_r_in = 1.35
	var z_rear = 1.90
	
	var pts: PackedVector3Array = PackedVector3Array([
		Vector3(-w, y_top, z_front),
		Vector3( w, y_top, z_front),
		Vector3( w, y_top, z_rear),
		Vector3(-w, y_top, z_rear),
		Vector3(-w, y_mid, z_front),
		Vector3( w, y_mid, z_front),
		Vector3( w, y_mid, z_rear),
		Vector3(-w, y_mid, z_rear),
		Vector3(-w_in, y_front, z_front),
		Vector3( w_in, y_front, z_front),
		Vector3(-w_in, y_rear, z_rear),
		Vector3( w_in, y_rear, z_rear),
		Vector3(-w_in, y_bot, z_f_in),
		Vector3( w_in, y_bot, z_f_in),
		Vector3( w_in, y_bot, z_r_in),
		Vector3(-w_in, y_bot, z_r_in)
	])
	
	var shape = ConvexPolygonShape3D.new()
	shape.points = pts
	return shape

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for child in node.get_children():
		collect_meshes(child, out_list)

