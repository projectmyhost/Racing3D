@tool
extends SceneTree

# Map all mdl types in Untitled.glb

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var scene = load(path)
	var inst = scene.instantiate()
	
	var mdl_map: Dictionary = {}
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(inst, all_meshes)
	
	var regex = RegEx.new()
	regex.compile("mdl_\\d+")
	
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else ""
		var mname = mi.name
		var text = pname + " " + mname
		var m = regex.search(text)
		var mdl_id = m.get_string() if m else "no_mdl"
		
		if not mdl_map.has(mdl_id):
			mdl_map[mdl_id] = {
				"count": 0,
				"sample_pname": pname,
				"aabb": mi.mesh.get_aabb() if mi.mesh else AABB(),
				"faces": (mi.mesh.get_faces().size() / 3) if mi.mesh else 0
			}
		mdl_map[mdl_id]["count"] += 1

	print("Unique mdl identifiers found: ", mdl_map.size())
	for k in mdl_map:
		var d = mdl_map[k]
		print("  %s: count=%d | aabb=%s | faces=%d | sample=%s" % [
			k, d["count"], str(d["aabb"].size), d["faces"], d["sample_pname"]
		])

	inst.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for child in node.get_children():
		collect_meshes(child, out_list)

