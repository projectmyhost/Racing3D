extends SceneTree

func _init() -> void:
	var ps := load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	var track := ps.instantiate()
	get_root().add_child(track)
	await process_frame

	var cm := track.get_node_or_null("CityMap")
	if cm == null:
		printerr("FAIL: CityMap missing")
		quit(1)
		return

	var meshes := cm.find_children("*", "MeshInstance3D", true, false)
	var occs := cm.find_children("*", "OccluderInstance3D", true, false)
	if meshes.size() >= 260:
		printerr("FAIL: Expected batched CityMap < 260 MeshInstance3D nodes, got %d" % meshes.size())
		quit(1)
		return
	if occs.size() < 1:
		printerr("FAIL: Expected OccluderInstance3D inside CityMap")
		quit(1)
		return

	var road_shaders := 0
	var prop_fade_chunks := 0
	var tiny_no_shadow := 0
	var backdrop_kept := 0
	var cull_back_mats := 0
	var total_surfaces := 0
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		if mi.name.begins_with("backdrop_grp_"):
			backdrop_kept += 1
		if mi.name.begins_with("Chunk_prop_") or mi.name.begins_with("Chunk_tiny_"):
			if mi.visibility_range_end >= 190.0:
				prop_fade_chunks += 1
		if mi.name.begins_with("Chunk_tiny_") and mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			tiny_no_shadow += 1
		for s in range(mi.mesh.get_surface_count()):
			total_surfaces += 1
			var ov := mi.get_surface_override_material(s)
			if ov is ShaderMaterial:
				road_shaders += 1
			elif ov is StandardMaterial3D and (ov as StandardMaterial3D).cull_mode == BaseMaterial3D.CULL_BACK:
				cull_back_mats += 1

	if road_shaders < 1:
		printerr("FAIL: Expected asphalt ShaderMaterial on road chunks")
		quit(1)
		return
	if backdrop_kept != 8:
		printerr("FAIL: Expected 8 backdrop_grp_* nodes preserved, got %d" % backdrop_kept)
		quit(1)
		return
	if prop_fade_chunks < 1 or tiny_no_shadow < 1 or cull_back_mats < 1:
		printerr("FAIL: Missing optimization flags (prop_fade=%d tiny_no_shadow=%d cull_back=%d)" % [prop_fade_chunks, tiny_no_shadow, cull_back_mats])
		quit(1)
		return
	if track.get_node_or_null("TrackColliders/BackdropRoadCollision") == null:
		printerr("FAIL: CollisionGuard must preserve BackdropRoadCollision")
		quit(1)
		return

	# Also verify HomeScreen loads Stage cleanly with city_map_optimized.scn
	var hs_ps := load("res://scenes/main/home_screen.tscn") as PackedScene
	var hs := hs_ps.instantiate()
	get_root().add_child(hs)
	await process_frame
	var stage := hs.get_node_or_null("Stage")
	if stage == null or stage.find_children("*", "OccluderInstance3D", true, false).size() < 1:
		printerr("FAIL: HomeScreen Stage missing optimized occluders")
		quit(1)
		return

	print("PASS: CityMap optimized -> meshes=%d surfaces=%d occluders=%d road_shaders=%d prop_fade=%d tiny_noshadow=%d cull_back=%d backdrop=%d" % [
		meshes.size(), total_surfaces, occs.size(), road_shaders, prop_fade_chunks, tiny_no_shadow, cull_back_mats, backdrop_kept
	])
	hs.queue_free()
	track.queue_free()
	quit(0)
