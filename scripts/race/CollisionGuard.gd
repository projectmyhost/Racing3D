class_name CollisionGuard
extends RefCounted

# Runtime Anti-Bug Collision Guard
# Validates scene hierarchy on map load, disables ghost colliders in hidden nodes,
# and verifies collider proportions against visual meshes to eliminate invisible walls.

static func run_guard(scene_root: Node) -> Dictionary:
	print("--- [COLLISION GUARD] STARTING RUNTIME AUDIT ---")
	var stats = {
		"total_colliders": 0,
		"ghost_colliders_disabled": 0,
		"anomalies_detected": 0,
		"valid_colliders": 0
	}
	
	if not scene_root:
		print("[COLLISION GUARD] Error: scene_root is null")
		return stats
		
	_harden_track_colliders(scene_root)
	_audit_node_recursive(scene_root, stats)
	
	print("[COLLISION GUARD] AUDIT COMPLETE:")
	print("  Total colliders scanned: %d" % stats["total_colliders"])
	print("  Ghost colliders disabled: %d" % stats["ghost_colliders_disabled"])
	print("  Anomalies reported: %d" % stats["anomalies_detected"])
	print("  Valid active colliders: %d" % stats["valid_colliders"])
	print("--- [COLLISION GUARD] MAP IS PROTECTED ---")
	return stats

static func _audit_node_recursive(node: Node, stats: Dictionary) -> void:
	if node is CollisionShape3D:
		stats["total_colliders"] += 1
		_process_collision_shape(node as CollisionShape3D, stats)
	elif node is CollisionPolygon3D:
		stats["total_colliders"] += 1
		_process_collision_polygon(node as CollisionPolygon3D, stats)
		
	for child in node.get_children():
		_audit_node_recursive(child, stats)

static func _process_collision_shape(cs: CollisionShape3D, stats: Dictionary) -> void:
	# 1. Check if node or any ancestor is hidden (ghost collider check)
	var is_hidden_in_hierarchy = false
	var curr: Node = cs
	while curr != null:
		if curr is Node3D and not (curr as Node3D).visible:
			is_hidden_in_hierarchy = true
			break
		elif curr is CanvasItem and not (curr as CanvasItem).visible:
			is_hidden_in_hierarchy = true
			break
		curr = curr.get_parent()
		
	if is_hidden_in_hierarchy:
		if not cs.disabled:
			cs.disabled = true
			stats["ghost_colliders_disabled"] += 1
			print("[COLLISION GUARD] Disabled active collider under hidden branch: ", cs.get_path())
		return
		
	# 2. If already disabled, ignore
	if cs.disabled:
		return
		
	stats["valid_colliders"] += 1
	
	# 3. Check for associated visual mesh
	var shape = cs.shape
	if not shape:
		print("[COLLISION GUARD] Warning: CollisionShape3D has no shape resource: ", cs.get_path())
		stats["anomalies_detected"] += 1
		return
		
	var parent = cs.get_parent()
	if parent is Area3D:
		# Area3D checkpoint trigger - valid non-blocking volume
		return
		
	var associated_mesh: MeshInstance3D = null
	if parent is MeshInstance3D:
		associated_mesh = parent as MeshInstance3D
	elif parent:
		for sibling in parent.get_children():
			if sibling is MeshInstance3D:
				associated_mesh = sibling as MeshInstance3D
				break
				
	# 4. AABB ratio check if visual mesh exists
	if associated_mesh and associated_mesh.mesh and shape is BoxShape3D:
		var mesh_size = associated_mesh.mesh.get_aabb().size * associated_mesh.scale
		var col_size = (shape as BoxShape3D).size * cs.scale
		var mesh_vol = mesh_size.x * mesh_size.y * mesh_size.z
		var col_vol = col_size.x * col_size.y * col_size.z
		
		if mesh_vol > 0.001:
			var ratio = col_vol / mesh_vol
			if ratio > 2.5:
				print("[COLLISION GUARD] Warning: Oversized box collider at '%s' (Ratio: %.2f vs visual mesh '%s')" % [
					cs.get_path(), ratio, associated_mesh.name
				])
				stats["anomalies_detected"] += 1

static func _process_collision_polygon(cp: CollisionPolygon3D, stats: Dictionary) -> void:
	var is_hidden_in_hierarchy = false
	var curr: Node = cp
	while curr != null:
		if curr is Node3D and not (curr as Node3D).visible:
			is_hidden_in_hierarchy = true
			break
		curr = curr.get_parent()
		
	if is_hidden_in_hierarchy and not cp.disabled:
		cp.disabled = true
		stats["ghost_colliders_disabled"] += 1
		print("[COLLISION GUARD] Disabled active polygon collider under hidden branch: ", cp.get_path())

static func _harden_track_colliders(scene_root: Node) -> void:
	var track_colliders := scene_root.get_node_or_null("TrackColliders") as StaticBody3D
	if not track_colliders:
		return
	
	# Enable smooth wall-glancing physics material so barrier scrapes don't catch or launch chassis
	if track_colliders.physics_material_override == null:
		var track_mat := PhysicsMaterial.new()
		track_mat.bounce = 0.0
		track_mat.absorbent = true
		track_mat.friction = 0.08
		track_colliders.physics_material_override = track_mat
	
	# Fix reverse-wound CityMap trimesh faces across all track colliders so downward wheel rays never pass through
	var backface_fixed := 0
	for child in track_colliders.get_children():
		if child is CollisionShape3D:
			var cs := child as CollisionShape3D
			if not cs.disabled and cs.shape is ConcavePolygonShape3D:
				var concave := cs.shape as ConcavePolygonShape3D
				if not concave.backface_collision:
					concave.backface_collision = true
					backface_fixed += 1
	
	# Build trimesh collider for drivable CityMap backdrop_* road meshes omitted from RoadSurfacesCollision
	if track_colliders.get_node_or_null("BackdropRoadCollision") == null:
		var city_map := scene_root.get_node_or_null("CityMap")
		if city_map:
			var road_faces := PackedVector3Array()
			var tc_inv: Transform3D = track_colliders.global_transform.affine_inverse()
			_collect_backdrop_road_faces(city_map, tc_inv, road_faces)
			if road_faces.size() >= 3:
				var bd_shape := ConcavePolygonShape3D.new()
				bd_shape.backface_collision = true
				bd_shape.set_faces(road_faces)
				var bd_col := CollisionShape3D.new()
				bd_col.name = "BackdropRoadCollision"
				bd_col.shape = bd_shape
				track_colliders.add_child(bd_col)
				print("[COLLISION GUARD] Added BackdropRoadCollision (%d tris), hardened %d concave colliders" % [road_faces.size() / 3, backface_fixed])
				return
	if backface_fixed > 0:
		print("[COLLISION GUARD] Enabled double-sided collision on %d concave track colliders" % backface_fixed)

static func _collect_backdrop_road_faces(node: Node, tc_inv: Transform3D, out_faces: PackedVector3Array) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.visible and mi.mesh and mi.name.begins_with("backdrop_grp_"):
			var xform: Transform3D = tc_inv * mi.global_transform
			var faces: PackedVector3Array = mi.mesh.get_faces()
			var tri_count := faces.size() / 3
			for i in range(tri_count):
				var idx := i * 3
				var a: Vector3 = xform * faces[idx]
				var b: Vector3 = xform * faces[idx + 1]
				var c: Vector3 = xform * faces[idx + 2]
				var n: Vector3 = (b - a).cross(c - a)
				# Keep horizontal / ramp road surfaces and curbs; skip pure vertical distant scenery billboards
				if n.length_squared() > 1e-8 and absf(n.normalized().y) > 0.35:
					out_faces.append(a)
					out_faces.append(b)
					out_faces.append(c)
	for child in node.get_children():
		if child is Node3D and not (child as Node3D).visible:
			continue
		_collect_backdrop_road_faces(child, tc_inv, out_faces)

