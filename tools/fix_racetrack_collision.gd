@tool
extends SceneTree

# Tool to fix collisions in scenes/race/RaceTrack3D.tscn

func _init() -> void:
	print("--- FIXING RACETRACK3D COLLISION SYSTEM ---")
	fix_racetrack()
	print("--- RACETRACK3D COLLISION SYSTEM FIXED ---")
	quit(0)

func fix_racetrack() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	if not p:
		print("FAIL: cannot load ", path)
		return
		
	var root = p.instantiate()
	get_root().add_child(root)
	
	var city_map = root.get_node_or_null("CityMap")
	if not city_map:
		print("FAIL: CityMap not found in root")
		root.free()
		return
		
	var track_body = root.get_node_or_null("TrackColliders") as StaticBody3D
	if not track_body:
		track_body = StaticBody3D.new()
		track_body.name = "TrackColliders"
		track_body.collision_layer = 1
		track_body.collision_mask = 2
		root.add_child(track_body)
		track_body.owner = root
		
	# 1. Remove LowerCityFloorGround (the 40cm ghost step slab)
	var lower_ground = track_body.get_node_or_null("LowerCityFloorGround")
	if lower_ground:
		track_body.remove_child(lower_ground)
		lower_ground.free()
		print("Removed ghost collider: LowerCityFloorGround")
		
	# 2. Fix outer boundaries to prevent transparent wall slicing into south city
	var bound_south = track_body.get_node_or_null("BoundarySouth") as CollisionShape3D
	if bound_south:
		bound_south.position = Vector3(0.0, 40.0, 520.0)
		print("Moved BoundarySouth outside city grid to Z=520")
		
	var bound_north = track_body.get_node_or_null("BoundaryNorth") as CollisionShape3D
	if bound_north:
		bound_north.position = Vector3(0.0, 40.0, -820.0)
		
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
		
	# 3. Position BottomSafetyNet safely below lowest road (-5.08)
	var bottom_net = track_body.get_node_or_null("BottomSafetyNet") as CollisionShape3D
	if bottom_net:
		bottom_net.position = Vector3(0.0, -15.0, -150.0)
		var s_bot = BoxShape3D.new()
		s_bot.size = Vector3(1800.0, 4.0, 1600.0)
		bottom_net.shape = s_bot
		print("Configured BottomSafetyNet at Y=-15.0")

	# 4. Extract solid props (chairs, tables, kiosks, bus stops, benches, trash cans)
	print("Extracting solid props and street furniture for Trimesh collision...")
	var all_city_meshes: Array[MeshInstance3D] = []
	collect_meshes(city_map, all_city_meshes)
	
	var prop_faces: PackedVector3Array = PackedVector3Array()
	var pole_faces: PackedVector3Array = PackedVector3Array()
	var prop_count = 0
	var pole_count = 0
	
	for mi in all_city_meshes:
		var pname = mi.get_parent().name.to_lower()
		var mname = mi.name.to_lower()
		
		# Skip foliage and distant backdrops
		if "backdrop" in pname or "chevron" in pname:
			continue
		if "mdl_009" in pname or "mdl_010" in pname:
			# Palm leaves and bushes
			continue
			
		# Props: chairs, tables, kiosks, phone booths, vending machines, benches, AC units
		if pname.begins_with("prop_"):
			if mi.mesh:
				var faces = mi.mesh.get_faces()
				var gt = mi.global_transform
				for v in faces:
					prop_faces.append(gt * v)
				prop_count += 1
		# Instanced poles and pillars: street lamps, overpass pillars, bollards
		elif pname.begins_with("unit_") and "inst_" in mname:
			if mi.mesh:
				var faces = mi.mesh.get_faces()
				var gt = mi.global_transform
				for v in faces:
					pole_faces.append(gt * v)
				pole_count += 1
				
	print("Extracted %d props (%d triangles)" % [prop_count, prop_faces.size() / 3])
	print("Extracted %d poles/pillars (%d triangles)" % [pole_count, pole_faces.size() / 3])
	
	# Add or update PropsCollision in TrackColliders
	var props_col = track_body.get_node_or_null("PropsCollision") as CollisionShape3D
	if not props_col:
		props_col = CollisionShape3D.new()
		props_col.name = "PropsCollision"
		track_body.add_child(props_col)
		props_col.owner = root
	var props_shape = ConcavePolygonShape3D.new()
	props_shape.set_faces(prop_faces)
	props_col.shape = props_shape
	
	# Add or update PolesCollision in TrackColliders
	var poles_col = track_body.get_node_or_null("PillarsAndPolesCollision") as CollisionShape3D
	if not poles_col:
		poles_col = CollisionShape3D.new()
		poles_col.name = "PillarsAndPolesCollision"
		track_body.add_child(poles_col)
		poles_col.owner = root
	var poles_shape = ConcavePolygonShape3D.new()
	poles_shape.set_faces(pole_faces)
	poles_col.shape = poles_shape
	
	# 5. Update CarCollision on RaceCar3D with beveled anti-seam convex shape
	var car = root.get_node_or_null("RaceCar3D") as CharacterBody3D
	if car:
		car.safe_margin = 0.08
		car.floor_snap_length = 0.8
		car.floor_max_angle = deg_to_rad(55.0)
		var car_col = car.get_node_or_null("CarCollision") as CollisionShape3D
		if car_col:
			var beveled_shape = create_anti_seam_car_shape()
			car_col.shape = beveled_shape
			car_col.position = Vector3.ZERO
			print("Updated RaceCar3D CarCollision with anti-seam beveled convex shape")

	# 6. Save updated scene
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		ResourceSaver.save(packed, path)
		print("SUCCESS: Saved updated RaceTrack3D scene")
	else:
		print("FAIL: pack error ", err)
		
	root.free()

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

