@tool
extends SceneTree

# Inspect all 15 environment prefab scenes

func _init() -> void:
	var env_dir = "res://assets/environments"
	var files: Array[String] = []
	find_tscn(env_dir, files)
	
	for path in files:
		print("\n--- SCENE: ", path)
		var p = load(path) as PackedScene
		if not p:
			print("  Could not load")
			continue
		var inst = p.instantiate()
		print_tree_details(inst, "  ")
		inst.free()
		
	quit(0)

func find_tscn(dir_path: String, out_files: Array[String]) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir: return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			find_tscn(dir_path.path_join(file_name), out_files)
		elif file_name.ends_with(".tscn"):
			out_files.append(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

func print_tree_details(node: Node, indent: String) -> void:
	var extra = ""
	if node is MeshInstance3D:
		var aabb = (node as MeshInstance3D).get_aabb()
		extra = " [Mesh AABB: %s]" % str(aabb.size)
	elif node is CollisionShape3D:
		var cs = node as CollisionShape3D
		var s = cs.shape
		extra = " [ColShape: %s, disabled=%s]" % [s.get_class() if s else "null", str(cs.disabled)]
	elif node is StaticBody3D:
		extra = " [StaticBody3D]"
		
	print("%s%s (%s)%s visible=%s" % [indent, node.name, node.get_class(), extra, str(node.get("visible") if "visible" in node else "n/a")])
	for c in node.get_children():
		print_tree_details(c, indent + "  ")

