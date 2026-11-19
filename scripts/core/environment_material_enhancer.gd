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
			var mat_id: int = sm.get_instance_id()
			if _global_mat_cache.has(mat_id):
				var entry: Dictionary = _global_mat_cache[mat_id]
				if is_instance_valid(entry["src"].get_ref()) and entry["src"].get_ref() == sm:
					var cached_out := entry["out"] as Material
					if is_instance_valid(cached_out):
						mi.set_surface_override_material(s, cached_out)
						continue

			var enhanced := _calibrate_material(sm)
			_global_mat_cache[mat_id] = {"src": weakref(sm), "out": enhanced}
			mi.set_surface_override_material(s, enhanced)

static func _calibrate_material(sm: StandardMaterial3D) -> Material:
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
		road_std.roughness = 0.60
		road_std.metallic = 0.0
		road_std.metallic_specular = 0.36
		road_std.clearcoat_enabled = false
		return road_std

	var out := sm.duplicate() as StandardMaterial3D
	out.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	# 2. Reflective Glass Skyscraper Facades
	if sm.metallic >= 0.5 and sm.roughness <= 0.15:
		out.roughness = 0.045
		out.metallic = maxf(sm.metallic, 0.74)
		out.metallic_specular = 0.94
		out.clearcoat_enabled = true
		out.clearcoat = 0.85
		out.clearcoat_roughness = 0.03
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
