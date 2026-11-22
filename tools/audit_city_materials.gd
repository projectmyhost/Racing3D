@tool
extends SceneTree

func _init() -> void:
	var ps := load("res://assets/models/environment/city_map/source/Untitled.glb") as PackedScene
	var src := ps.instantiate() as Node3D
	src.scale = Vector3(100.0, 100.0, 100.0)
	get_root().add_child(src)
	await process_frame
	var stats := {}
	for n in src.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.mesh:
			continue
		var wa := mi.global_transform * mi.mesh.get_aabb()
		var min_dim := minf(wa.size.x, minf(wa.size.y, wa.size.z))
		var is_prop := mi.name.begins_with("prop_") or mi.name.begins_with("chevron")
		for s in range(mi.mesh.get_surface_count()):
			var sm := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if not sm:
				continue
			var key := sm.resource_name
			if not stats.has(key):
				stats[key] = {"count": 0, "prop_hits": 0, "thin_hits": 0, "trans": sm.transparency, "tex": sm.albedo_texture.resource_path.get_file() if sm.albedo_texture else ""}
			stats[key]["count"] += 1
			if is_prop:
				stats[key]["prop_hits"] += 1
			if min_dim < 0.25:
				stats[key]["thin_hits"] += 1
	var safe_count := 0
	var keep_ds: Array[String] = []
	for k in stats.keys():
		var st: Dictionary = stats[k]
		if st["trans"] != BaseMaterial3D.TRANSPARENCY_DISABLED or st["prop_hits"] > 0 or st["thin_hits"] > 0:
			keep_ds.append(k)
			print("KEEP_DOUBLE_SIDED: %-18s count=%3d prop=%3d thin=%3d trans=%d tex=%s" % [k, st["count"], st["prop_hits"], st["thin_hits"], st["trans"], st["tex"]])
		else:
			safe_count += 1
	print("SUMMARY: total_mats=%d | safe_cull_back=%d | keep_double_sided=%d" % [stats.size(), safe_count, keep_ds.size()])
	src.free()
	quit(0)
