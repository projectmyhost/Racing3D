@tool
extends SceneTree

# Targeted collision audit for all 3D environment, car, and race scenes

func _init() -> void:
	print("=== TARGETED 3D COLLISION AUDIT ===")
	audit_3d_scenes()
	quit()

func audit_3d_scenes() -> void:
	var target_dirs = [
		"res://assets/environments",
		"res://assets/models/cars",
		"res://scenes/race",
		"res://scenes/environment"
	]
	
	var files: Array[String] = []
	for dir in target_dirs:
		find_tscn_files(dir, files)
	
	print("Found %d target 3D scenes" % files.size())
	for f in files:
		audit_scene(f)

func find_tscn_files(dir_path: String, out_files: Array[String]) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				find_tscn_files(dir_path.path_join(file_name), out_files)
		else:
			if file_name.ends_with(".tscn"):
				out_files.append(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

func audit_scene(path: String) -> void:
	var packed: PackedScene = load(path)
	if not packed:
		print("ERROR: Could not load scene: ", path)
		return
	
	var root = packed.instantiate()
	if not root:
		print("ERROR: Could not instantiate scene: ", path)
		return
	
	print("\n>>> AUDITING SCENE: ", path)
	var col_shapes: Array[CollisionShape3D] = []
	var col_polys: Array[CollisionPolygon3D] = []
	var mesh_instances: Array[MeshInstance3D] = []
	
	collect_nodes(root, col_shapes, col_polys, mesh_instances)
	print("  Meshes: %d | CollisionShapes: %d | CollisionPolys: %d" % [mesh_instances.size(), col_shapes.size(), col_polys.size()])
	
	for cs in col_shapes:
		var parent = cs.get_parent()
		var p_name = parent.name if parent else "None"
		var shape = cs.shape
		var s_type = shape.get_class() if shape else "null"
		
		# Check hidden ancestor
		var ancestor_hidden = false
		var curr: Node = cs
		while curr != null:
			if curr is Node3D and not (curr as Node3D).visible:
				ancestor_hidden = true
				break
			curr = curr.get_parent()
		
		var is_ghost = ancestor_hidden and not cs.disabled
		
		# Check shape details
		var info_extra = ""
		if shape is BoxShape3D:
			info_extra = "size=" + str(shape.size)
		elif shape is ConcavePolygonShape3D:
			info_extra = "triangles=" + str(shape.get_faces().size() / 3)
		elif shape is ConvexPolygonShape3D:
			info_extra = "points=" + str(shape.points.size())
		elif shape is CapsuleShape3D:
			info_extra = "r=%.2f, h=%.2f" % [shape.radius, shape.height]
		
		print("  [ColShape] path: %s | shape: %s (%s) | disabled: %s | ghost: %s" % [
			cs.get_path(), s_type, info_extra, str(cs.disabled), str(is_ghost)
		])
		
		if is_ghost:
			print("    *** DANGER: Ghost Collider in hidden branch! ***")
		
		# Check if parent is road / ramp / curb but using single convex
		var p_lower = p_name.to_lower()
		var path_lower = cs.get_path().get_concatenated_names().to_lower()
		if ("road" in p_lower or "highway" in p_lower or "ramp" in p_lower or "bridge" in p_lower or "curb" in p_lower):
			if shape is ConvexPolygonShape3D:
				print("    *** WARNING: Road/Ramp using ConvexPolygonShape3D! Should be Trimesh ConcavePolygonShape3D! ***")
	
	root.free()

func collect_nodes(node: Node, col_shapes: Array[CollisionShape3D], col_polys: Array[CollisionPolygon3D], meshes: Array[MeshInstance3D]) -> void:
	if node is CollisionShape3D:
		col_shapes.append(node)
	elif node is CollisionPolygon3D:
		col_polys.append(node)
	elif node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		collect_nodes(child, col_shapes, col_polys, meshes)
