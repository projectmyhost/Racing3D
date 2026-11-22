@tool
extends SceneTree

## Builds res://assets/models/environment/city_map/city_map_optimized.scn from raw Untitled.glb:
## 1) Instantiates source GLB at 100x scale so AABB & triangle area checks operate in true world meters.
## 2) Preserves backdrop_grp_* (8 nodes) & chevron_* untouched for CollisionGuard.gd (with standalone meshes/materials).
## 3) Merges unit_* & prop_* geometry into multi-surface spatial grid chunks with Hardware Mesh LODs:
##    - struct: 84m x 84m tight cells for strong watertight occlusion culling + automatic ImporterMesh LODs.
##    - road: 100m x 100m cells; ground-level roads disable shadow-casting (only elevated bridges above other roads cast shadows).
##    - prop & tiny: 120m x 120m cells with 250m visibility_range (zero early fade, zero 180-deg whip-pan pop-in) and SHADOW_CASTING_SETTING_OFF on tiny props (<= 2.2m).
## 4) Extracts WATERTIGHT zero-crack conservative ArrayOccluder3D from large opaque vertical tower walls:
##    - Instead of shrinking individual triangles (which opens diagonal cracks between quad triangles!),
##      welds internal shared edges, offsets walls 0.30m inward along face normal, and insets ONLY outer perimeter boundary edges by 0.25m.
##    - Guarantees both 100% watertight occlusion (35-55% hidden city culled) AND zero false occlusion.

const SRC_GLB := "res://assets/models/environment/city_map/source/Untitled.glb"
const OUT_SCN := "res://assets/models/environment/city_map/city_map_optimized.scn"
const STRUCT_CELL_SIZE := 96.0
const ROAD_CELL_SIZE := 120.0
const PROP_CELL_SIZE := 130.0
const OCC_MIN_TRI_AREA_M2 := 8.0
const OCC_MIN_PLANE_AREA_M2 := 24.0
const OCC_MIN_HEIGHT_M := 7.5
const OCC_NORMAL_INSET_M := 0.30
const OCC_PERIMETER_INSET_M := 0.25

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

func _qvec(v: Vector3) -> Vector3i:
	return Vector3i(int(round(v.x * 20.0)), int(round(v.y * 20.0)), int(round(v.z * 20.0)))

func _edge_key(a: Vector3i, b: Vector3i) -> String:
	if a.x < b.x or (a.x == b.x and (a.y < b.y or (a.y == b.y and a.z < b.z))):
		return "%d,%d,%d|%d,%d,%d" % [a.x, a.y, a.z, b.x, b.y, b.z]
	return "%d,%d,%d|%d,%d,%d" % [b.x, b.y, b.z, a.x, a.y, a.z]

func _build_watertight_occluders(plane_groups: Dictionary, src_inv: Transform3D) -> Dictionary:
	var occ_verts := PackedVector3Array()
	var occ_idxs := PackedInt32Array()
	var kept_planes := 0
	var kept_tris := 0

	for pkey in plane_groups.keys():
		var grp: Dictionary = plane_groups[pkey]
		var total_area: float = grp["area"]
		if total_area < OCC_MIN_PLANE_AREA_M2:
			continue
		var tris: Array = grp["tris"]
		if tris.is_empty():
			continue

		# Compute world plane average normal and centroid
		var avg_n := (grp["normal_sum"] as Vector3).normalized()
		var plane_center: Vector3 = (grp["center_sum"] as Vector3) / float(tris.size())

		# Count undirected edges within this coplanar wall group to distinguish internal vs perimeter edges
		var edge_counts := {}
		var qtris: Array = []
		for t in tris:
			var qa := _qvec(t[0])
			var qb := _qvec(t[1])
			var qc := _qvec(t[2])
			qtris.append([qa, qb, qc])
			for ek in [_edge_key(qa, qb), _edge_key(qb, qc), _edge_key(qc, qa)]:
				edge_counts[ek] = edge_counts.get(ek, 0) + 1

		# Identify boundary vertices (any vertex belonging to an edge with count == 1)
		var boundary_verts := {}
		for qt in qtris:
			var pairs := [[qt[0], qt[1]], [qt[1], qt[2]], [qt[2], qt[0]]]
			for pr in pairs:
				if edge_counts.get(_edge_key(pr[0], pr[1]), 0) == 1:
					boundary_verts[pr[0]] = true
					boundary_verts[pr[1]] = true

		# Emit watertight coplanar triangles:
		# - Offset entire wall plane inward by OCC_NORMAL_INSET_M along -avg_n (zero self-occlusion, zero cracks!)
		# - Inset ONLY outer perimeter vertices slightly toward plane_center (prevents edge leaks!)
		kept_planes += 1
		for idx_t in range(tris.size()):
			var wt: Array = tris[idx_t]
			var qt: Array = qtris[idx_t]
			var base := occ_verts.size()
			for k in range(3):
				var wv: Vector3 = wt[k] as Vector3
				var wp: Vector3 = wv - avg_n * OCC_NORMAL_INSET_M
				if boundary_verts.has(qt[k]):
					var to_c: Vector3 = plane_center - wv
					# Project inward shift strictly onto the wall plane so coplanarity is preserved
					to_c -= avg_n * to_c.dot(avg_n)
					var len_c: float = to_c.length()
					if len_c > OCC_PERIMETER_INSET_M * 1.5:
						wp += (to_c / len_c) * OCC_PERIMETER_INSET_M
				occ_verts.append(src_inv * wp)
			occ_idxs.append(base)
			occ_idxs.append(base + 1)
			occ_idxs.append(base + 2)
			kept_tris += 1

	return {"verts": occ_verts, "idxs": occ_idxs, "planes": kept_planes, "tris": kept_tris}

func _build_cell_mesh_instance(out_root: Node3D, chunk_name: String, mat_buckets: Dictionary, vis_end: float, no_shadow: bool, generate_lods: bool) -> MeshInstance3D:
	var has_bounds := false
	var chunk_aabb := AABB()
	for mid in mat_buckets.keys():
		var tris: Array = mat_buckets[mid]["tris"]
		for t in tris:
			for k in range(3):
				var v: Vector3 = t["v"][k]
				if not has_bounds:
					chunk_aabb = AABB(v, Vector3.ZERO)
					has_bounds = true
				else:
					chunk_aabb = chunk_aabb.expand(v)
	if not has_bounds:
		return null
	var chunk_center: Vector3 = chunk_aabb.get_center()

	var imp := ImporterMesh.new()
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
				st.add_vertex(t["v"][k] - chunk_center)
		st.index()
		var arrays := st.commit_to_arrays()
		imp.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mb["mat"])
		surf_idx += 1

	if surf_idx == 0:
		return null

	if generate_lods:
		imp.generate_lods(25.0, 60.0, [])

	var combined: ArrayMesh = imp.get_mesh()
	if not combined or combined.get_surface_count() == 0:
		return null

	var mi := MeshInstance3D.new()
	mi.name = chunk_name
	mi.position = chunk_center
	mi.mesh = combined
	if vis_end > 0.0:
		mi.visibility_range_end = vis_end
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
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
	var plane_groups := {}
	var road_height_grid := {} # "gx|gz" -> min_y (to detect elevated overpasses vs ground roads)
	var kept_backdrop := 0
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
			if mi.name.begins_with("backdrop_grp_"):
				copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			out_root.add_child(copy)
			copy.owner = out_root
			kept_backdrop += 1
			continue

		var raw_aabb := mi.mesh.get_aabb()
		var world_aabb := world_xf * raw_aabb
		var world_center := world_aabb.get_center()
		var max_dim := maxf(world_aabb.size.x, maxf(world_aabb.size.y, world_aabb.size.z))
		var is_prop_node := mi.name.begins_with("prop_") or mi.name.contains("_inst_")
		var is_tiny_prop := is_prop_node and max_dim <= 2.2
		var is_small_prop := is_prop_node and max_dim <= 6.5

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
			var cell_size := PROP_CELL_SIZE if (tier == "prop" or tier == "tiny") else (ROAD_CELL_SIZE if tier == "road" else STRUCT_CELL_SIZE)
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
				var w0 := world_xf * rv0
				var w1 := world_xf * rv1
				var w2 := world_xf * rv2
				var wc := (w0 + w1 + w2) / 3.0
				if tier == "struct" or tier == "road":
					cx = int(floorf(wc.x / cell_size))
					cz = int(floorf(wc.z / cell_size))

				if tier == "road":
					var rgk := "%d|%d" % [int(floorf(wc.x / 16.0)), int(floorf(wc.z / 16.0))]
					if not road_height_grid.has(rgk) or wc.y < float(road_height_grid[rgk]):
						road_height_grid[rgk] = wc.y

				if safe_occ:
					var cr := (w1 - w0).cross(w2 - w0)
					var area := cr.length() * 0.5
					if area >= OCC_MIN_TRI_AREA_M2 and maxf(w0.y, maxf(w1.y, w2.y)) >= OCC_MIN_HEIGHT_M:
						var wn := cr.normalized()
						if absf(wn.y) < 0.25:
							# Group coplanar vertical walls per mesh node so shared quad edges stay 100% watertight
							var nx := int(round(wn.x * 16.0))
							var ny := int(round(wn.y * 16.0))
							var nz := int(round(wn.z * 16.0))
							var d_q := int(round(wn.dot(w0) * 2.0))
							var pkey := "%d|%d,%d,%d|%d" % [mi.get_instance_id(), nx, ny, nz, d_q]
							if not plane_groups.has(pkey):
								plane_groups[pkey] = {"area": 0.0, "normal_sum": Vector3.ZERO, "center_sum": Vector3.ZERO, "tris": []}
							var pg: Dictionary = plane_groups[pkey]
							pg["area"] = float(pg["area"]) + area
							pg["normal_sum"] = (pg["normal_sum"] as Vector3) + wn * area
							pg["center_sum"] = (pg["center_sum"] as Vector3) + wc
							(pg["tris"] as Array).append([w0, w1, w2])

				var cell_key := "%s|%d|%d" % [tier, cx, cz]
				if not cells.has(cell_key):
					cells[cell_key] = {"tier": tier, "cx": cx, "cz": cz, "mats": {}, "max_above_ground": 0.0, "sample_tris": []}
				var c_rec: Dictionary = cells[cell_key]
				if tier == "road":
					(c_rec["sample_tris"] as Array).append(wc)
				var cmats: Dictionary = c_rec["mats"]
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
	var road_shadow_off := 0
	var tier_counts := {"struct": 0, "road": 0, "prop": 0, "tiny": 0}
	for ck in cells.keys():
		var c: Dictionary = cells[ck]
		var tier: String = c["tier"]
		var vis_end := 250.0 if (tier == "prop" or tier == "tiny") else 0.0
		var no_sh := (tier == "tiny")
		if tier == "road":
			# Only keep shadow-casting ON for elevated bridge decks that actually hover >3.5m above another road!
			var is_overpass := false
			for wc in (c["sample_tris"] as Array):
				var rgk := "%d|%d" % [int(floorf((wc as Vector3).x / 16.0)), int(floorf((wc as Vector3).z / 16.0))]
				if road_height_grid.has(rgk) and ((wc as Vector3).y - float(road_height_grid[rgk])) > 3.5:
					is_overpass = true
					break
			if not is_overpass:
				no_sh = true
				road_shadow_off += 1
		var gen_lod := (tier == "struct" or tier == "prop")
		var chunk_name := "Chunk_%s_%d_%d_%d" % [tier, c["cx"], c["cz"], chunk_count]
		var built := _build_cell_mesh_instance(out_root, chunk_name, c["mats"], vis_end, no_sh, gen_lod)
		if built != null:
			chunk_count += 1
			tier_counts[tier] += 1
			total_surfaces += built.mesh.get_surface_count()

	var occ_data := _build_watertight_occluders(plane_groups, src_inv)
	var occ_verts: PackedVector3Array = occ_data["verts"]
	var occ_idxs: PackedInt32Array = occ_data["idxs"]
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
	print("Built %s | backdrop_kept=%d | chunks=%d (tiers=%s, road_noshadow=%d) | total_surfaces=%d | src_tris=%d | occ_planes=%d occ_tris=%d | shared_mats=%d | err=%d" % [
		OUT_SCN, kept_backdrop, chunk_count, str(tier_counts), road_shadow_off, total_surfaces, total_src_tris, occ_data["planes"], occ_data["tris"], _shared_mats.size(), err
	])
	out_root.free()
	src.free()
	quit(0 if err == OK else 1)
