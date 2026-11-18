@tool
extends SceneTree

# Test deferred global transform update

func _init() -> void:
	test_deferred.call_deferred()

func test_deferred() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	var root = p.instantiate()
	get_root().add_child(root)
	
	await process_frame
	await process_frame
	
	var city_map = root.get_node_or_null("CityMap") as Node3D
	var road_col = root.get_node_or_null("TrackColliders/RoadSurfacesCollision") as CollisionShape3D
	var existing_road_faces = (road_col.shape as ConcavePolygonShape3D).get_faces()
	print("Existing road faces points: ", existing_road_faces.size())
	print("Sample existing road vertex: ", existing_road_faces[0])
	
	# Find first unit_sub in city_map
	var stack = [city_map]
	var found_sub: MeshInstance3D = null
	var found_prop: MeshInstance3D = null
	while stack.size() > 0:
		var curr = stack.pop_back()
		if curr is MeshInstance3D:
			var pname = curr.get_parent().name if curr.get_parent() else ""
			if not found_sub and pname.begins_with("unit_") and "sub_" in curr.name:
				found_sub = curr
			elif not found_prop and pname.begins_with("prop_"):
				found_prop = curr
		for c in curr.get_children():
			stack.append(c)
			
	if found_sub:
		var gt = found_sub.global_transform
		var v0 = found_sub.mesh.get_faces()[0]
		var world_v0 = gt * v0
		print("found_sub name: ", found_sub.name)
		print("  found_sub gt: ", gt)
		print("  found_sub world v0: ", world_v0)
		
	if found_prop:
		var gt = found_prop.global_transform
		var v0 = found_prop.mesh.get_faces()[0]
		var world_v0 = gt * v0
		print("found_prop name: ", found_prop.name)
		print("  found_prop gt: ", gt)
		print("  found_prop world v0: ", world_v0)
		
	root.free()
	quit(0)

