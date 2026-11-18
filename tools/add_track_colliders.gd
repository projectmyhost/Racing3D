@tool
extends SceneTree

func _init():
	var scene_path = "res://scenes/race/RaceTrack3D.tscn"
	var packed = load(scene_path) as PackedScene
	if not packed:
		print("FAIL: cannot load RaceTrack3D.tscn")
		quit(1)
		return
		
	var root = packed.instantiate()
	get_root().add_child(root)
	
	# Check if TrackColliders already exists
	var existing = root.get_node_or_null("TrackColliders")
	if existing:
		root.remove_child(existing)
		existing.free()
		
	var track_body = StaticBody3D.new()
	track_body.name = "TrackColliders"
	track_body.collision_layer = 1
	track_body.collision_mask = 2
	root.add_child(track_body)
	track_body.owner = root
	
	# 1. Main Road Floor: covers 600x600m at exact road height Y = 0.20m
	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(600.0, 2.0, 600.0)
	var floor_col = CollisionShape3D.new()
	floor_col.name = "RoadFloorCollision"
	floor_col.shape = floor_shape
	floor_col.position = Vector3(30.0, -0.80, 36.0)
	track_body.add_child(floor_col)
	floor_col.owner = root
	
	# 2. Elevated Overpass Bridge Deck at Y = 4.5m
	var bridge_shape = BoxShape3D.new()
	bridge_shape.size = Vector3(16.0, 1.0, 52.0)
	var bridge_col = CollisionShape3D.new()
	bridge_col.name = "BridgeDeckCollision"
	bridge_col.shape = bridge_shape
	bridge_col.position = Vector3(24.0, 4.0, 36.0)
	track_body.add_child(bridge_col)
	bridge_col.owner = root
	
	# 3-6. Track Boundary Safety Walls (prevents flying out into void)
	var wall_north = CollisionShape3D.new()
	wall_north.name = "WallNorth"
	var s_ns = BoxShape3D.new()
	s_ns.size = Vector3(600.0, 20.0, 8.0)
	wall_north.shape = s_ns
	wall_north.position = Vector3(30.0, 6.0, -35.0)
	track_body.add_child(wall_north)
	wall_north.owner = root
	
	var wall_south = CollisionShape3D.new()
	wall_south.name = "WallSouth"
	wall_south.shape = s_ns
	wall_south.position = Vector3(30.0, 6.0, 115.0)
	track_body.add_child(wall_south)
	wall_south.owner = root
	
	var wall_west = CollisionShape3D.new()
	wall_west.name = "WallWest"
	var s_ew = BoxShape3D.new()
	s_ew.size = Vector3(8.0, 20.0, 600.0)
	wall_west.shape = s_ew
	wall_west.position = Vector3(-35.0, 6.0, 36.0)
	track_body.add_child(wall_west)
	wall_west.owner = root
	
	var wall_east = CollisionShape3D.new()
	wall_east.name = "WallEast"
	wall_east.shape = s_ew
	wall_east.position = Vector3(100.0, 6.0, 36.0)
	track_body.add_child(wall_east)
	wall_east.owner = root
	
	# Ensure car collision mask interacts with track colliders (mask 1)
	var car = root.get_node_or_null("RaceCar3D") as CharacterBody3D
	if car:
		car.collision_layer = 2
		car.collision_mask = 1
		# Ensure initial spawn height is clean on top of road
		car.position = Vector3(0.0, 0.22, 6.0)
		
	var new_packed = PackedScene.new()
	var pack_res = new_packed.pack(root)
	if pack_res == OK:
		ResourceSaver.save(new_packed, scene_path)
		print("SUCCESS: Added TrackColliders to scenes/race/RaceTrack3D.tscn!")
	else:
		print("FAIL: pack error ", pack_res)
	quit(0)

