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
	
	var track_body = root.get_node_or_null("TrackColliders") as StaticBody3D
	if not track_body:
		track_body = StaticBody3D.new()
		track_body.name = "TrackColliders"
		track_body.collision_layer = 1
		track_body.collision_mask = 2
		root.add_child(track_body)
		track_body.owner = root

	# Clear previous prop collision children (leave floor and outer barriers)
	var to_remove = []
	for c in track_body.get_children():
		if c.name.begins_with("PropCol_"):
			to_remove.append(c)
	for c in to_remove:
		track_body.remove_child(c)
		c.free()

	# 1. Trees Colliders (Cylinder shape for accurate trunk collision)
	var tree_positions = [
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
		Vector3(42.0, 0.0, 22.0),
		Vector3(30.0, 0.48, 36.0) # Roundabout center tree
	]
	
	var tree_shape = CylinderShape3D.new()
	tree_shape.radius = 0.95
	tree_shape.height = 7.0
	
	for i in range(tree_positions.size()):
		var col = CollisionShape3D.new()
		col.name = "PropCol_Tree_" + str(i)
		col.shape = tree_shape
		col.position = tree_positions[i] + Vector3(0.0, 3.5, 0.0)
		track_body.add_child(col)
		col.owner = root

	# 2. Street Lamps Colliders
	var lamp_positions = [
		Vector3(-5.4, 0.475, 4.0),
		Vector3(-5.4, 0.475, 28.0),
		Vector3(4.0, 0.475, 77.4),
		Vector3(32.0, 0.475, 77.4),
		Vector3(65.4, 0.475, 52.0),
		Vector3(65.4, 0.475, 18.0),
		Vector3(48.0, 0.475, -5.4),
		Vector3(16.0, 0.475, -5.4)
	]
	
	var lamp_shape = CylinderShape3D.new()
	lamp_shape.radius = 0.45
	lamp_shape.height = 8.0
	
	for i in range(lamp_positions.size()):
		var col = CollisionShape3D.new()
		col.name = "PropCol_Lamp_" + str(i)
		col.shape = lamp_shape
		col.position = lamp_positions[i] + Vector3(0.0, 4.0, 0.0)
		track_body.add_child(col)
		col.owner = root

	# 3. Pit Building & Grandstand Colliders
	var pit_shape = BoxShape3D.new()
	pit_shape.size = Vector3(6.5, 6.0, 44.0)
	var pit_col = CollisionShape3D.new()
	pit_col.name = "PropCol_PitBuilding"
	pit_col.shape = pit_shape
	pit_col.position = Vector3(9.2, 3.0, 24.0)
	track_body.add_child(pit_col)
	pit_col.owner = root

	# 4. Gantry Towers Colliders (Start/Finish Arch)
	var tower_shape = BoxShape3D.new()
	tower_shape.size = Vector3(1.6, 7.0, 1.6)
	
	var gantry_l = CollisionShape3D.new()
	gantry_l.name = "PropCol_GantryL"
	gantry_l.shape = tower_shape
	gantry_l.position = Vector3(-5.5, 3.5, 14.0)
	track_body.add_child(gantry_l)
	gantry_l.owner = root
	
	var gantry_r = CollisionShape3D.new()
	gantry_r.name = "PropCol_GantryR"
	gantry_r.shape = tower_shape
	gantry_r.position = Vector3(5.5, 3.5, 14.0)
	track_body.add_child(gantry_r)
	gantry_r.owner = root

	# 5. Striped Racing Arch Colliders
	var arch_l = CollisionShape3D.new()
	arch_l.name = "PropCol_ArchL"
	arch_l.shape = tower_shape
	arch_l.position = Vector3(-5.8, 3.0, 60.0)
	track_body.add_child(arch_l)
	arch_l.owner = root
	
	var arch_r = CollisionShape3D.new()
	arch_r.name = "PropCol_ArchR"
	arch_r.shape = tower_shape
	arch_r.position = Vector3(5.8, 3.0, 60.0)
	track_body.add_child(arch_r)
	arch_r.owner = root

	# 6. Roundabout Island Center Collider
	var island_shape = CylinderShape3D.new()
	island_shape.radius = 5.5
	island_shape.height = 1.2
	var island_col = CollisionShape3D.new()
	island_col.name = "PropCol_RoundaboutIsland"
	island_col.shape = island_shape
	island_col.position = Vector3(30.0, 0.6, 36.0)
	track_body.add_child(island_col)
	island_col.owner = root

	var new_packed = PackedScene.new()
	var pack_res = new_packed.pack(root)
	if pack_res == OK:
		ResourceSaver.save(new_packed, scene_path)
		print("SUCCESS: Added all prop colliders to scenes/race/RaceTrack3D.tscn!")
	else:
		print("FAIL: pack error ", pack_res)
	quit(0)

