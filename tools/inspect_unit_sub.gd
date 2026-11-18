@tool
extends SceneTree

# Inspect unit_sub contents and height distribution

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var scene = load(path)
	var inst = scene.instantiate()
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(inst, all_meshes)
	
	var sub_count = 0
	var tall_count = 0
	var flat_count = 0
	
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else ""
		var mname = mi.name
		if pname.begins_with("unit_") and "sub_" in mname:
			sub_count += 1
			var aabb = mi.mesh.get_aabb() if mi.mesh else AABB()
			if aabb.size.y > 10.0:
				tall_count += 1
			elif aabb.size.y < 1.0:
				flat_count += 1
				
	print("Total unit_sub meshes: ", sub_count)
	print("  Tall meshes (Y size > 10m, i.e. buildings/overpasses): ", tall_count)
	print("  Flat meshes (Y size < 1m, i.e. road surfaces): ", flat_count)
	print("  Medium meshes (1m <= Y size <= 10m, i.e. curbs/bridges/ramps): ", sub_count - tall_count - flat_count)
	
	inst.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for child in node.get_children():
		collect_meshes(child, out_list)

