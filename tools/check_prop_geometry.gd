@tool
extends SceneTree

# Check prop meshes in Untitled.glb and their geometry

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var scene = load(path)
	var inst = scene.instantiate()
	
	var prop_meshes: Array[MeshInstance3D] = []
	var inst_meshes: Array[MeshInstance3D] = []
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(inst, all_meshes)
	
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else ""
		var mname = mi.name
		if pname.begins_with("prop_"):
			prop_meshes.append(mi)
		elif "inst_" in mname and pname.begins_with("unit_"):
			inst_meshes.append(mi)
			
	print("Prop meshes: ", prop_meshes.size())
	print("Inst meshes: ", inst_meshes.size())
	
	var total_prop_triangles = 0
	for mi in prop_meshes:
		if mi.mesh:
			total_prop_triangles += mi.mesh.get_faces().size() / 3
			
	var total_inst_triangles = 0
	for mi in inst_meshes:
		if mi.mesh:
			total_inst_triangles += mi.mesh.get_faces().size() / 3
			
	print("Total prop triangles: ", total_prop_triangles)
	print("Total inst triangles: ", total_inst_triangles)
	
	inst.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for child in node.get_children():
		collect_meshes(child, out_list)

