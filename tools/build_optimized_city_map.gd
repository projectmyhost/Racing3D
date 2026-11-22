@tool
extends SceneTree

## Builds res://assets/models/environment/city_map/city_map_optimized.scn from raw Untitled.glb:
## 1) Instantiates source GLB at 100x scale so AABB & triangle area checks operate in true world meters.
## 2) Preserves backdrop_grp_* (8 nodes) & chevron_* untouched for CollisionGuard.gd (with standalone meshes/materials).
## 3) Merges unit_* & prop_* geometry into multi-surface spatial grid chunks:
##    - struct & road: 200m x 200m cells bucketed by triangle centroid (tight bounds for frustum + occlusion culling, huge draw-call reduction).
##    - prop & tiny: 100m x 100m cells bucketed by mesh center with 360-degree 220m (+30m fade) visibility_range (zero early fade, zero 180-deg whip-pan pop-in) and SHADOW_CASTING_SETTING_OFF on tiny props (<= 2.2m).
## 4) Extracts exact conservative ArrayOccluder3D from large opaque vertical tower walls (>= 16 m^2, >= 8m tall, solid CULL_BACK materials) shrunk 6% inward toward triangle centroid (mathematically impossible false occlusion).

const SRC_GLB := "res://assets/models/environment/city_map/source/Untitled.glb"
const OUT_SCN := "res://assets/models/environment/city_map/city_map_optimized.scn"
const STRUCT_CELL_SIZE := 200.0
const PROP_CELL_SIZE := 100.0
const OCC_MIN_AREA_M2 := 16.0
const OCC_MIN_HEIGHT_M := 8.0
const OCC_SHRINK_FACTOR := 0.06

const KEEP_DOUBLE_SIDED_MATS: Dictionary = {
	"Merged_materials": true,
	"material_041_0": true,
	"material_041_1": true,
	"material_041_2": true,
	"material_041_3": true,
	"material_041_4": true,
	"material_041_5": true,
	"material_041_6": true,
	"material_041_7": true,
	"material_041_8": true,
	"material_041_9": true,
	"material_041_10": true,
	"material_041_11": true,
	"material_041_12": true,
	"material_041_13": true,
	"material_041_14": true,
	"material_041_15": true,
	"material_041_23": true,
	"material_041_26": true,
	"material_041_28": true,
	"material_041_29": true,
	"material_041_30": true,
	"material_041_31": true,
	"material_041_32": true,
	"material_041_38": true,
	"material_041_42": true,
	"material_041_44": true,
	"material_041_45": true,
	"material_041_46": true,
	"material_041_47": true,
	"material_041_48": true,
	"material_041_51": true,
	"material_041_55": true,
	"material_041_64": true,
	"material_041_65": true,
	"material_041_68": true,
	"material_041_69": true,
	"material_041_71": true,
	"material_041_80": true,
}

var _shared_mats: Dictionary = {}

func _get_standalone_mat(mat: Material) -> Material:
	if not mat:
		return null
	var mid := mat.get_instance_id()
	if _shared_mats.has(mid):
		return _shared_mats[mid]
	var dup := mat.duplicate() as Material
	dup.resource_name = mat.resource_name
	_shared_mats[mid] = dup
	return dup

func _is_road_mat(mat: Material) -> bool:
	if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture:
		var rp := (mat as StandardMaterial3D).albedo_texture.resource_path.to_lower()
		return rp.ends_with("untitled_image_49.png") or rp.ends_with("untitled_image_72.png")
	return false

func _build_cell_mesh_instance(out_root: Node3D, chunk_name: String, mat_buckets: Dictionary, vis_end: float, no_shadow: bool) -> MeshInstance3D:
	var combined := ArrayMesh.new()
	var surf_idx := 0
	for mid in mat_buckets.keys():
		var mb: Dictionary = mat_buckets[mid]
		var tris: Array = mb["tris"]
		if tris.is_empty():
			continue
		var any_n := false
		var any_t := false
		var any_uv := false
		var any_col := false
		for t in tris:
			if t["has_n"]: any_n = true
			if t["has_t"]: any_t = true
			if t["has_uv"]: any_uv = true
			if t["has_col"]: any_col = true

		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for t in tris:
			for k in range(3):
				if any_n:
					st.set_normal(t["n"][k] if t["has_n"] else Vector3.UP)
				if any_t:
					st.set_tangent(t["t"][k] if t["has_t"] else Plane(1.0, 0.0, 0.0, 1.0))
				if any_uv:
					st.set_uv(t["uv"][k] if t["has_uv"] else Vector2.ZERO)
				if any_col:
					st.set_color(t["col"][k] if t["has_col"] else Color.WHITE)
				st.add_vertex(t["v"][k])
		st.index()
		st.commit(combined)
		combined.surface_set_material(surf_idx, mb["mat"])
		surf_idx += 1

	if combined.get_surface_count() == 0:
		return null

	var mi := MeshInstance3D.new()
	mi.name = chunk_name
	mi.mesh = combined
	if vis_end > 0.0:
		mi.visibility_range_end = vis_end
		mi.visibility_range_end_margin = 30.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if no_shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	out_root.add_child(mi)
	mi.owner = out_root
	return mi

func _init() -> void:
	var ps := load(SRC_GLB) as PackedScene
	var src := ps.instantiate() as Node3D
	# Match RaceTrack3D CityMap (100,100,100) scale so global positions & triangle areas are in true world meters
	src.scale = Vector3(100.0, 100.0, 100.0)
	get_root().add_child(src)
	await process_frame

	var out_root := Node3D.new()
	out_root.name = "CityMapOptimized"
	var src_inv := src.global_transform.affine_inverse()

	# cell_key ("tier|cx|cz") -> { "tier", "cx", "cz", "mats": { mat_id: { "mat", "tris": [] } } }
	var cells := {}
	var occ_verts := PackedVector3Array()
	var occ_idxs := PackedInt32Array()
	var kept_backdrop := 0
	var occ_tris := 0
	var total_src_tris := 0

	for node in src.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var local_xf: Transform3D = src_inv * mi.global_transform
		var world_xf: Transform3D = mi.global_transform

		# Preserve backdrop_grp_* (8 nodes) & chevron_* for CollisionGuard.gd with standalone mesh & materials
		if mi.name.begins_with("backdrop_grp_") or mi.name.begins_with("chevron"):
			var copy := MeshInstance3D.new()
			copy.name = mi.name
			copy.transform = local_xf
			var mesh_dup := mi.mesh.duplicate() as Mesh
			for s in range(mesh_dup.get_surface_count()):
				var sm_orig := mesh_dup.surface_get_material(s)
				if sm_orig:
					mesh_dup.surface_set_material(s, _get_standalone_mat(sm_orig))
			copy.mesh = mesh_dup
			out_root.add_child(copy)
			copy.owner = out_root
			kept_backdrop += 1
			continue

		var raw_aabb := mi.mesh.get_aabb()
		var world_aabb := world_xf * raw_aabb
		var world_center := world_aabb.get_center()
		var max_dim := maxf(world_aabb.size.x, maxf(world_aabb.size.y, world_aabb.size.z))
		var is_prop_node := mi.name.begins_with("prop_")
		var is_tiny_prop := is_prop_node and max_dim <= 2.2
		var is_small_prop := is_prop_node and max_dim <= 8.0

		var n_basis := local_xf.basis.inverse().transposed()
		var flip_winding := local_xf.basis.determinant() < 0.0
		var order := [0, 2, 1] if flip_winding else [0, 1, 2]
		var tan_sign := -1.0 if flip_winding else 1.0

		for s in range(mi.mesh.get_surface_count()):
			var raw_mat := mi.mesh.surface_get_material(s)
			if not raw_mat:
				continue
			var standalone_mat := _get_standalone_mat(raw_mat)
			var is_road := _is_road_mat(raw_mat)
			var tier := "tiny" if is_tiny_prop else ("prop" if is_small_prop else ("road" if is_road else "struct"))
			var cell_size := PROP_CELL_SIZE if (tier == "prop" or tier == "tiny") else STRUCT_CELL_SIZE
			var fixed_cx := int(floorf(world_center.x / cell_size))
			var fixed_cz := int(floorf(world_center.z / cell_size))

			var sm_std := raw_mat as StandardMaterial3D
			var safe_occ := mi.name.begins_with("unit_") and not is_road \
				and sm_std != null and sm_std.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
				and not KEEP_DOUBLE_SIDED_MATS.has(sm_std.resource_name)

			var mdt := MeshDataTool.new()
			if mdt.create_from_surface(mi.mesh, s) != OK:
				continue
			var fmt := mdt.get_format()
			var has_n := (fmt & Mesh.ARRAY_FORMAT_NORMAL) != 0
			var has_t := (fmt & Mesh.ARRAY_FORMAT_TANGENT) != 0
			var has_uv := (fmt & Mesh.ARRAY_FORMAT_TEX_UV) != 0
			var has_col := (fmt & Mesh.ARRAY_FORMAT_COLOR) != 0
			var mid := raw_mat.get_instance_id()

			for f in range(mdt.get_face_count()):
				total_src_tris += 1
				var vi0 := mdt.get_face_vertex(f, order[0])
				var vi1 := mdt.get_face_vertex(f, order[1])
				var vi2 := mdt.get_face_vertex(f, order[2])
				var rv0 := mdt.get_vertex(vi0)
				var rv1 := mdt.get_vertex(vi1)
				var rv2 := mdt.get_vertex(vi2)
				var lv0 := local_xf * rv0
				var lv1 := local_xf * rv1
				var lv2 := local_xf * rv2

				var cx := fixed_cx
				var cz := fixed_cz
				if tier == "struct" or tier == "road":
					var wc := (world_xf * rv0 + world_xf * rv1 + world_xf * rv2) / 3.0
					cx = int(floorf(wc.x / cell_size))
					cz = int(floorf(wc.z / cell_size))

				if safe_occ:
					var w0 := world_xf * rv0
					var w1 := world_xf * rv1
					var w2 := world_xf * rv2
					var cr := (w1 - w0).cross(w2 - w0)
					var area := cr.length() * 0.5
					if area >= OCC_MIN_AREA_M2 and maxf(w0.y, maxf(w1.y, w2.y)) >= OCC_MIN_HEIGHT_M:
						if absf(cr.normalized().y) < 0.30:
							var lc := (lv0 + lv1 + lv2) / 3.0
							var base := occ_verts.size()
							occ_verts.append(lv0.lerp(lc, OCC_SHRINK_FACTOR))
							occ_verts.append(lv1.lerp(lc, OCC_SHRINK_FACTOR))
							occ_verts.append(lv2.lerp(lc, OCC_SHRINK_FACTOR))
							occ_idxs.append(base)
							occ_idxs.append(base + 1)
							occ_idxs.append(base + 2)
							occ_tris += 1

				var cell_key := "%s|%d|%d" % [tier, cx, cz]
				if not cells.has(cell_key):
					cells[cell_key] = {"tier": tier, "cx": cx, "cz": cz, "mats": {}}
				var cmats: Dictionary = cells[cell_key]["mats"]
				if not cmats.has(mid):
					cmats[mid] = {"mat": standalone_mat, "tris": []}

				var tri_rec := {
					"v": [lv0, lv1, lv2],
					"has_n": has_n,
					"has_t": has_t,
					"has_uv": has_uv,
					"has_col": has_col,
				}
				if has_n:
					tri_rec["n"] = [
						(n_basis * mdt.get_vertex_normal(vi0)).normalized(),
						(n_basis * mdt.get_vertex_normal(vi1)).normalized(),
						(n_basis * mdt.get_vertex_normal(vi2)).normalized(),
					]
				if has_t:
					var t0 := mdt.get_vertex_tangent(vi0)
					var t1 := mdt.get_vertex_tangent(vi1)
					var t2 := mdt.get_vertex_tangent(vi2)
					var td0 := (n_basis * Vector3(t0.x, t0.y, t0.z)).normalized()
					var td1 := (n_basis * Vector3(t1.x, t1.y, t1.z)).normalized()
					var td2 := (n_basis * Vector3(t2.x, t2.y, t2.z)).normalized()
					tri_rec["t"] = [
						Plane(td0.x, td0.y, td0.z, t0.d * tan_sign),
						Plane(td1.x, td1.y, td1.z, t1.d * tan_sign),
						Plane(td2.x, td2.y, td2.z, t2.d * tan_sign),
					]
				if has_uv:
					tri_rec["uv"] = [mdt.get_vertex_uv(vi0), mdt.get_vertex_uv(vi1), mdt.get_vertex_uv(vi2)]
				if has_col:
					tri_rec["col"] = [mdt.get_vertex_color(vi0), mdt.get_vertex_color(vi1), mdt.get_vertex_color(vi2)]
				cmats[mid]["tris"].append(tri_rec)

	var chunk_count := 0
	var total_surfaces := 0
	var tier_counts := {"struct": 0, "road": 0, "prop": 0, "tiny": 0}
	for ck in cells.keys():
		var c: Dictionary = cells[ck]
		var tier: String = c["tier"]
		var vis_end := 220.0 if (tier == "prop" or tier == "tiny") else 0.0
		var no_sh := (tier == "tiny")
		var chunk_name := "Chunk_%s_%d_%d_%d" % [tier, c["cx"], c["cz"], chunk_count]
		var built := _build_cell_mesh_instance(out_root, chunk_name, c["mats"], vis_end, no_sh)
		if built != null:
			chunk_count += 1
			tier_counts[tier] += 1
			total_surfaces += built.mesh.get_surface_count()

	if not occ_idxs.is_empty():
		var occ := ArrayOccluder3D.new()
		occ.set_arrays(occ_verts, occ_idxs)
		var oi := OccluderInstance3D.new()
		oi.name = "CityTowerOccluders"
		oi.occluder = occ
		out_root.add_child(oi)
		oi.owner = out_root

	var packed := PackedScene.new()
	packed.pack(out_root)
	var err := ResourceSaver.save(packed, OUT_SCN)
	print("Built %s | backdrop_kept=%d | chunks=%d (tiers=%s) | total_surfaces=%d | src_tris=%d | occ_tris=%d | shared_mats=%d | err=%d" % [
		OUT_SCN, kept_backdrop, chunk_count, str(tier_counts), total_surfaces, total_src_tris, occ_tris, _shared_mats.size(), err
	])
	out_root.free()
	src.free()
	quit(0 if err == OK else 1)
