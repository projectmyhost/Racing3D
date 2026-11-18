@tool
extends SceneTree

# Test exact transform calculation without tree dependence

func _init() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	var root = p.instantiate()
	get_root().add_child(root)
	
	var city_map = root.get_node_or_null("CityMap") as Node3D
	print("CityMap transform: ", city_map.transform)
	
	# Find a sample prop
	var prop: MeshInstance3D = null
	var stack = [city_map]
	while stack.size() > 0:
		var curr = stack.pop_back()
		if curr is MeshInstance3D and curr.get_parent().name.begins_with("prop_"):
			prop = curr
			break
		for c in curr.get_children():
			stack.append(c)
			
	if prop:
		print("Sample prop: ", prop.name, " parent: ", prop.get_parent().name)
		var rel_t = get_relative_transform(prop, city_map)
		var world_t = city_map.transform * rel_t
		print("Relative transform origin: ", rel_t.origin)
		print("World transform origin: ", world_t.origin)
		print("Mesh AABB size: ", prop.mesh.get_aabb().size)
		print("World AABB size: ", prop.mesh.get_aabb().size * 100.0)
		
	root.free()
	quit(0)

func get_relative_transform(node: Node3D, root_ancestor: Node3D) -> Transform3D:
	var t = Transform3D.IDENTITY
	var curr: Node3D = node
	while curr != null and curr != root_ancestor:
		t = curr.transform * t
		curr = curr.get_parent() as Node3D
	return t

