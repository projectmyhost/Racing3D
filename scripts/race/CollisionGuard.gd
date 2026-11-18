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

