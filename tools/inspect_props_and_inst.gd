@tool
extends SceneTree

# Inspect prop models and unit_inst models in Untitled.glb

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var scene = load(path)
	var inst = scene.instantiate()
	
	var prop_models: Dictionary = {}
	var unit_inst_models: Dictionary = {}
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(inst, all_meshes)
	
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else "root"
		var mname = mi.name
		var aabb = mi.mesh.get_aabb() if mi.mesh else AABB()
		var face_count = (mi.mesh.get_faces().size() / 3) if mi.mesh else 0
		
		if pname.begins_with("prop_"):
			# e.g. prop_000_mdl_001
			var key = pname
			if not prop_models.has(key):
				prop_models[key] = {
					"count": 0,
					"mesh_name": mname,
					"aabb": aabb,
					"faces": face_count
				}
			prop_models[key]["count"] += 1
		elif "inst_" in mname:
			# e.g. unit_000_inst_001
			var key = mname
			if not unit_inst_models.has(key):
				unit_inst_models[key] = {
					"count": 0,
					"parent_name": pname,
					"aabb": aabb,
					"faces": face_count
				}
			unit_inst_models[key]["count"] += 1

	print("Unique prop parents: ", prop_models.size())
	print("Unique unit_inst mesh names: ", unit_inst_models.size())
	
	print("\nSample prop models:")
	var c = 0
	for k in prop_models:
		var d = prop_models[k]
		print("  %s -> mesh: %s | aabb size: %s | faces: %d" % [k, d["mesh_name"], str(d["aabb"].size), d["faces"]])
		c += 1
		if c >= 15:
			break
			
	print("\nSample unit_inst models:")
	c = 0
	for k in unit_inst_models:
		var d = unit_inst_models[k]
		print("  %s (parent: %s) -> aabb size: %s | faces: %d" % [k, d["parent_name"], str(d["aabb"].size), d["faces"]])
		c += 1
		if c >= 15:
			break

	inst.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for child in node.get_children():
		collect_meshes(child, out_list)

