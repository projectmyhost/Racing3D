@tool
extends SceneTree

# Check vertex scale of unit_sub vs prop vs unit_inst in Untitled.glb

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var p = load(path) as PackedScene
	var inst = p.instantiate()
	
	var all_meshes: Array[MeshInstance3D] = []
	collect_meshes(inst, all_meshes)
	
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else ""
		var mname = mi.name
		if pname.begins_with("unit_") and "sub_" in mname:
			var faces = mi.mesh.get_faces()
			print("Sample unit_sub: ", mname, " faces count=", faces.size())
			print("  local aabb: ", mi.mesh.get_aabb())
			print("  parent transform: ", mi.get_parent().transform)
			print("  mesh transform: ", mi.transform)
			break
			
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else ""
		var mname = mi.name
		if pname.begins_with("prop_"):
			var faces = mi.mesh.get_faces()
			print("Sample prop: ", mname, " faces count=", faces.size())
			print("  local aabb: ", mi.mesh.get_aabb())
			print("  parent transform: ", mi.get_parent().transform)
			print("  mesh transform: ", mi.transform)
			break
			
	for mi in all_meshes:
		var pname = mi.get_parent().name if mi.get_parent() else ""
		var mname = mi.name
		if pname.begins_with("unit_") and "inst_" in mname:
			var faces = mi.mesh.get_faces()
			print("Sample unit_inst: ", mname, " faces count=", faces.size())
			print("  local aabb: ", mi.mesh.get_aabb())
			print("  parent transform: ", mi.get_parent().transform)
			print("  mesh transform: ", mi.transform)
			break
			
	inst.free()
	quit(0)

func collect_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for c in node.get_children():
		collect_meshes(c, out_list)

