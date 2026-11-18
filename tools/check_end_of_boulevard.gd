@tool
extends SceneTree

# Inspect what is at (-253.77, 36.0, 142.0)

func _init() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	var root = p.instantiate()
	get_root().add_child(root)
	
	await process_frame
	await process_frame
	
	var city_map = root.get_node_or_null("CityMap") as Node3D
	var target = Vector3(-253.77, 36.0, 142.0)
	print("Checking objects near: ", target)
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(city_map, all_meshes)
	
	var nearby: Array[Dictionary] = []
	for mi in all_meshes:
		var gt = mi.global_transform
		var aabb = mi.mesh.get_aabb() if mi.mesh else AABB()
		var center = gt * (aabb.position + aabb.size * 0.5)
		var dist = center.distance_to(target)
		if dist < 25.0:
			nearby.append({
				"name": mi.name,
				"parent": mi.get_parent().name,
				"dist": dist,
				"center": center,
				"mesh_size": aabb.size
			})
			
	nearby.sort_custom(func(a, b): return a["dist"] < b["dist"])
	for i in range(mini(10, nearby.size())):
		var n = nearby[i]
		print("  %s (parent: %s) -> dist=%.1fm, center=%s, size=%s" % [
			n["name"], n["parent"], n["dist"], str(n["center"]), str(n["mesh_size"])
		])
		
	root.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for c in node.get_children():
		collect_meshes(c, out_list)

