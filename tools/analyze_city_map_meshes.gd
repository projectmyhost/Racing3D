@tool
extends SceneTree

# Analyze Untitled.glb contents in detail

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var scene = load(path)
	if not scene:
		print("FAIL load")
		quit(1)
		return
	var inst = scene.instantiate()
	
	var categories: Dictionary = {}
	var prop_names: Dictionary = {}
	var unit_names: Dictionary = {}
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(inst, all_meshes)
	print("Total MeshInstance3D in Untitled.glb: ", all_meshes.size())
	
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else "root"
		var mname = mi.name
		
		var cat = "other"
		if pname.begins_with("unit_"):
			if "sub_" in mname:
				cat = "unit_sub"
			elif "inst_" in mname:
				cat = "unit_inst"
			else:
				cat = "unit_other"
		elif pname.begins_with("prop_"):
			cat = "prop"
		elif "backdrop" in pname or "backdrop" in mname:
			cat = "backdrop"
		
		categories[cat] = categories.get(cat, 0) + 1
		
		if cat == "prop":
			var base_prop = pname.substr(0, 15)
			prop_names[base_prop] = prop_names.get(base_prop, 0) + 1
		elif cat == "unit_inst":
			var base_inst = mname.substr(0, 15)
			unit_names[base_inst] = unit_names.get(base_inst, 0) + 1
	
	print("Categories count:")
	for c in categories:
		print("  %s: %d" % [c, categories[c]])
	
	print("\nSample prop parents (first 20):")
	var count = 0
	for p in prop_names:
		print("  %s: %d" % [p, prop_names[p]])
		count += 1
		if count >= 20:
			break
			
	print("\nSample unit_inst meshes (first 20):")
	count = 0
	for u in unit_names:
		print("  %s: %d" % [u, unit_names[u]])
		count += 1
		if count >= 20:
			break

	inst.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for c in node.get_children():
		collect_meshes(c, out_list)

