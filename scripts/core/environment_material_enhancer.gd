class_name EnvironmentMaterialEnhancer
extends RefCounted

## Runtime PBR & Shader calibrator for city environment meshes (Stage / CityMap).
## Applies 16x anisotropic filtering, world-space procedural asphalt gravel normal/roughness
## (preserving Untitled_Image_49.png albedo & .import 100%), and glass/metal/facade contrast.

static var _asphalt_shader: Shader = null
static var _asphalt_detail_normal: ImageTexture = null
static var _asphalt_mat_refs: Array[WeakRef] = []
static var _global_mat_cache: Dictionary = {}
static var _current_quality_detail: float = 1.0

# Audited from Untitled.glb via tools/audit_city_materials.gd:
# Materials used by transparent surfaces, props, chevrons, or thin (<0.25m) geometry stay double-sided.
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
	"material_041_66": true,
	"material_041_68": true,
	"material_041_69": true,
	"material_041_71": true,
	"material_041_80": true,
}

static func _can_use_backface_cull(sm: StandardMaterial3D, mi: MeshInstance3D) -> bool:
	if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return false
	var nm := mi.name
	if nm.begins_with("prop_") or nm.begins_with("chevron") or nm.begins_with("Chunk_prop_") or nm.begins_with("Chunk_tiny_"):
		return false
	if KEEP_DOUBLE_SIDED_MATS.has(sm.resource_name):
		return false
	return true

static func set_quality_detail(detail_level: float) -> void:
	_current_quality_detail = clampf(detail_level, 0.0, 1.0)
	var alive: Array[WeakRef] = []
	for wr in _asphalt_mat_refs:
		var mat = wr.get_ref() as ShaderMaterial
		if is_instance_valid(mat):
			mat.set_shader_parameter("quality_detail", _current_quality_detail)
			alive.append(wr)
	_asphalt_mat_refs = alive

static func enhance_city_stage(stage_root: Node) -> void:
	if not stage_root:
		return

	if _asphalt_shader == null:
		_asphalt_shader = load("res://assets/shaders/asphalt_aaa.gdshader") as Shader
	if _asphalt_detail_normal == null:
		_asphalt_detail_normal = _build_asphalt_detail_normal()

	var meshes: Array[Node] = stage_root.find_children("*", "MeshInstance3D", true, false)

	for node in meshes:
		var mi := node as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var active_mat: Material = mi.get_active_material(s)
			if not active_mat:
				active_mat = mi.mesh.surface_get_material(s)
			if not (active_mat is StandardMaterial3D):
				continue

			var sm := active_mat as StandardMaterial3D
			var cull_safe: bool = _can_use_backface_cull(sm, mi)
			var cache_key := "%d:%s" % [sm.get_instance_id(), "cull_back" if cull_safe else "cull_off"]
			if _global_mat_cache.has(cache_key):
				var entry: Dictionary = _global_mat_cache[cache_key]
				if is_instance_valid(entry["src"].get_ref()) and entry["src"].get_ref() == sm:
					var cached_out := entry["out"] as Material
					if is_instance_valid(cached_out):
						mi.set_surface_override_material(s, cached_out)
						continue

			var enhanced := _calibrate_material(sm, cull_safe)
			_global_mat_cache[cache_key] = {"src": weakref(sm), "out": enhanced}
			mi.set_surface_override_material(s, enhanced)

static func _calibrate_material(sm: StandardMaterial3D, cull_safe: bool) -> Material:
	var tex_path := ""
	if sm.albedo_texture:
		tex_path = sm.albedo_texture.resource_path.to_lower()

	# 1. Asphalt Road Surfaces (preserve albedo 100%, upgrade with procedural world-space gravel normal & wear)
	if tex_path.ends_with("untitled_image_49.png") or tex_path.ends_with("untitled_image_72.png"):
		if _asphalt_shader != null and sm.albedo_texture != null:
			var road_mat := ShaderMaterial.new()
			road_mat.shader = _asphalt_shader
			road_mat.set_shader_parameter("albedo_tex", sm.albedo_texture)
			road_mat.set_shader_parameter("albedo_tint", Color(0.95, 0.95, 0.96, 1.0))
			if _asphalt_detail_normal != null:
				road_mat.set_shader_parameter("detail_normal_tex", _asphalt_detail_normal)
				road_mat.set_shader_parameter("has_detail_normal", true)
			road_mat.set_shader_parameter("detail_scale", 1.75)
			road_mat.set_shader_parameter("detail_normal_strength", 0.62)
			road_mat.set_shader_parameter("base_roughness", 0.56)
			road_mat.set_shader_parameter("specular_level", 0.36)
			road_mat.set_shader_parameter("wear_variation", 0.22)
			road_mat.set_shader_parameter("quality_detail", _current_quality_detail)
			_asphalt_mat_refs.append(weakref(road_mat))
			return road_mat

		var road_std := sm.duplicate() as StandardMaterial3D
		road_std.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if cull_safe:
			road_std.cull_mode = BaseMaterial3D.CULL_BACK
		road_std.roughness = 0.60
		road_std.metallic = 0.0
		road_std.metallic_specular = 0.36
		road_std.clearcoat_enabled = false
		return road_std

	var out := sm.duplicate() as StandardMaterial3D
	out.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if cull_safe:
		out.cull_mode = BaseMaterial3D.CULL_BACK

	# 2. Reflective Glass Skyscraper Facades (crisp HDR reflections without dual-lobe clearcoat cost)
	if sm.metallic >= 0.5 and sm.roughness <= 0.15:
		out.roughness = 0.055
		out.metallic = maxf(sm.metallic, 0.74)
		out.metallic_specular = 0.94
		out.clearcoat_enabled = false
		return out

	# 3. Structural Metals / Guardrails / Street Poles
	if sm.metallic >= 0.5:
		out.roughness = clampf(sm.roughness, 0.22, 0.45)
		out.metallic_specular = 0.85
		return out

	# 4. Architectural Concrete / Urban Facades (add crisp surface depth & micro-normal relief)
	if sm.roughness >= 0.70:
		if sm.roughness >= 0.90:
			out.roughness = 0.78
		out.metallic_specular = 0.36
		if sm.albedo_texture != null and not sm.normal_enabled and _asphalt_detail_normal != null:
			out.normal_enabled = true
			out.normal_texture = _asphalt_detail_normal
			out.normal_scale = 0.22

	return out

static func _build_asphalt_detail_normal() -> ImageTexture:
	# Tileable 128x128 heightfield converted to tangent normal map for crisp asphalt aggregate
	var size: int = 128
	var hmap := PackedFloat32Array()
	hmap.resize(size * size)
	for y in range(size):
		for x in range(size):
			# Multi-frequency deterministic seamless aggregate hash
			var h1: float = _tile_hash(x, y, size, 17.0)
			var h2: float = _tile_hash(x / 2, y / 2, size / 2, 53.0)
			var h3: float = _tile_hash(x / 4, y / 4, size / 4, 97.0)
			hmap[y * size + x] = h1 * 0.50 + h2 * 0.32 + h3 * 0.18

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var strength: float = 2.6
	for y in range(size):
		var ym: int = (y - 1 + size) % size
		var yp: int = (y + 1) % size
		for x in range(size):
			var xm: int = (x - 1 + size) % size
			var xp: int = (x + 1) % size
			var dx: float = (hmap[y * size + xp] - hmap[y * size + xm]) * strength
			var dy: float = (hmap[yp * size + x] - hmap[ym * size + x]) * strength
			var n := Vector3(-dx, -dy, 1.0).normalized()
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _tile_hash(x: int, y: int, period: int, seed_val: float) -> float:
	var px: int = posmod(x, period)
	var py: int = posmod(y, period)
	var v: float = sin(float(px) * 12.9898 + float(py) * 78.233 + seed_val) * 43758.5453
	return v - floor(v)
