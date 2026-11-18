@tool
extends SceneTree

# Complete 3D collision verification report generator

const CollisionGuard = preload("res://scripts/race/CollisionGuard.gd")

func _init() -> void:
	generate_report.call_deferred()

func generate_report() -> void:
	print("=================================================================")
	print("     COMPREHENSIVE FINAL 3D COLLISION AUDIT & VERIFICATION REPORT ")
	print("=================================================================")
	
	var target_dirs = [
		"res://assets/environments",
		"res://assets/models/cars",
		"res://scenes/race",
		"res://scenes/environment"
	]
	
	var all_scenes: Array[String] = []
	for d in target_dirs:
		find_tscn(d, all_scenes)
	
	var audited_scenes: Array[Dictionary] = []
	
	for path in all_scenes:
		var p = load(path) as PackedScene
		if not p: continue
		var root = p.instantiate()
		get_root().add_child(root)
		
		# Allow one frame for node hierarchy
		await process_frame
		
		var col_shapes: Array[CollisionShape3D] = []
		var col_polys: Array[CollisionPolygon3D] = []
		var static_bodies: Array[StaticBody3D] = []
		var meshes: Array[MeshInstance3D] = []
		
		collect_elements(root, col_shapes, col_polys, static_bodies, meshes)
		
		if col_shapes.size() > 0 or col_polys.size() > 0 or static_bodies.size() > 0:
			var report = {
				"path": path,
				"col_shapes": col_shapes.size(),
				"col_polys": col_polys.size(),
				"static_bodies": static_bodies.size(),
				"meshes": meshes.size(),
				"details": []
			}
			
			for cs in col_shapes:
				var s = cs.shape
				var s_type = s.get_class() if s else "null"
				var info = ""
				if s is ConcavePolygonShape3D:
					info = "Trimesh triangles=" + str((s as ConcavePolygonShape3D).get_faces().size() / 3)
				elif s is BoxShape3D:
					info = "Box=" + str((s as BoxShape3D).size)
				elif s is ConvexPolygonShape3D:
					info = "Convex points=" + str((s as ConvexPolygonShape3D).points.size())
				elif s is CylinderShape3D:
					info = "Cylinder r=%.2f h=%.2f" % [(s as CylinderShape3D).radius, (s as CylinderShape3D).height]
				
				report["details"].append("%s: %s (%s) pos=%s disabled=%s" % [
					cs.name, s_type, info, str(cs.position), str(cs.disabled)
				])
			
			audited_scenes.append(report)
			
		root.free()
		
	print("\nAudited %d scenes with collision elements:" % audited_scenes.size())
	for scene_info in audited_scenes:
		print("\n[SCENE] ", scene_info["path"])
		print("  Meshes: %d | StaticBodies: %d | ColShapes: %d" % [
			scene_info["meshes"], scene_info["static_bodies"], scene_info["col_shapes"]
		])
		for d in scene_info["details"]:
			print("    -> ", d)
			
	print("\n=================================================================")
	print("                 AUDIT COMPLETED SUCCESSFULLY                    ")
	print("=================================================================")
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

func collect_elements(node: Node, col_shapes: Array[CollisionShape3D], col_polys: Array[CollisionPolygon3D], static_bodies: Array[StaticBody3D], meshes: Array[MeshInstance3D]) -> void:
	if node is CollisionShape3D:
		col_shapes.append(node)
	elif node is CollisionPolygon3D:
		col_polys.append(node)
	elif node is StaticBody3D:
		static_bodies.append(node)
	elif node is MeshInstance3D:
		meshes.append(node)
		
	for c in node.get_children():
		collect_elements(c, col_shapes, col_polys, static_bodies, meshes)
