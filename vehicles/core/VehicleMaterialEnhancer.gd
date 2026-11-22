class_name VehicleMaterialEnhancer
extends RefCounted

# Universal PBR Material Enhancer for 3D Vehicles.
# Calibrates raw imported mesh materials (FBX/GLB) into high-fidelity automotive finishes:
# - Automotive metallic clearcoat lacquer for body panels (eliminates dull/chalky/burik look)
# - Realistic tinted glass with reflection and transparency
# - High-gloss metallic alloy rims and brake calipers
# - Woven carbon fiber with specularity and clearcoat
# - Headlight and taillight optical emission

const MCLAREN_PAPAYA_ORANGE = Color(0.96, 0.36, 0.01, 1.0)
const PORSCHE_GT_SILVER = Color(0.84, 0.87, 0.90, 1.0)
const PORSCHE_ROCKET_BRONZE = Color(0.68, 0.61, 0.55, 1.0)
const KIA_CERAMIC_SILVER = Color(0.84, 0.87, 0.90, 1.0)
const KIA_STARBRIGHT_YELLOW = Color(0.94, 0.74, 0.08, 1.0)

static var _paint_shader: Shader = null
static var _paint_mat_refs: Array[WeakRef] = []
static var _contact_shadow_tex: ImageTexture = null
static var _tire_detail_normal: ImageTexture = null
static var _current_quality_detail: float = 1.0

static func set_quality_detail(detail_level: float) -> void:
	_current_quality_detail = clampf(detail_level, 0.0, 1.0)
	var alive: Array[WeakRef] = []
	for wr in _paint_mat_refs:
		var mat = wr.get_ref() as ShaderMaterial
		if is_instance_valid(mat):
			mat.set_shader_parameter("quality_detail", _current_quality_detail)
			alive.append(wr)
	_paint_mat_refs = alive

static func attach_contact_shadow(parent_node: Node3D, local_pos: Vector3, width: float, length: float) -> Decal:
	if not parent_node:
		return null
	var existing := parent_node.get_node_or_null("ContactShadowDecal") as Decal
	if existing:
		existing.position = local_pos
		existing.size = Vector3(width, 0.95, length)
		return existing
	if _contact_shadow_tex == null:
		_contact_shadow_tex = _build_contact_shadow_texture()
	var decal := Decal.new()
	decal.name = "ContactShadowDecal"
	decal.position = local_pos
	decal.size = Vector3(width, 0.95, length)
	decal.texture_albedo = _contact_shadow_tex
	decal.albedo_mix = 0.90
	decal.modulate = Color(1.0, 1.0, 1.0, 0.94)
	decal.upper_fade = 0.35
	decal.lower_fade = 0.55
	decal.distance_fade_enabled = true
	decal.distance_fade_begin = 90.0
	decal.distance_fade_length = 30.0
	decal.cull_mask = 1
	parent_node.add_child(decal)
	return decal

static func _build_contact_shadow_texture() -> ImageTexture:
	var w: int = 128
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var wheel_spots := [
		Vector2(-0.72, -0.60),
		Vector2(0.72, -0.60),
		Vector2(-0.72, 0.60),
		Vector2(0.72, 0.60),
	]
	for y in range(h):
		var ny: float = (float(y) + 0.5) / float(h) * 2.0 - 1.0
		for x in range(w):
			var nx: float = (float(x) + 0.5) / float(w) * 2.0 - 1.0
			# Rounded-box superellipse matches automotive underbody footprint
			var box_d: float = pow(pow(absf(nx), 2.8) + pow(absf(ny), 3.6), 1.0 / 3.2)
			var core_alpha: float = clampf(1.0 - smoothstep(0.28, 0.98, box_d), 0.0, 1.0)
			core_alpha = core_alpha * core_alpha * 0.88
			# Concentrated dark wheel-well / tire contact patches
			var wheel_alpha: float = 0.0
			for ws in wheel_spots:
				var dx: float = (nx - ws.x) / 0.24
				var dy: float = (ny - ws.y) / 0.26
				var wd: float = sqrt(dx * dx + dy * dy)
				var w_fade: float = clampf(1.0 - smoothstep(0.18, 1.0, wd), 0.0, 1.0)
				wheel_alpha = maxf(wheel_alpha, w_fade * w_fade * 0.96)
			var alpha: float = clampf(maxf(core_alpha, wheel_alpha), 0.0, 0.96)
			img.set_pixel(x, y, Color(0.01, 0.01, 0.014, alpha))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _get_tire_detail_normal() -> ImageTexture:
	if _tire_detail_normal != null:
		return _tire_detail_normal
	var sz: int = 128
	var hmap := PackedFloat32Array()
	hmap.resize(sz * sz)
	for y in range(sz):
		var vy: float = float(y) / float(sz)
		for x in range(sz):
			var ux: float = float(x) / float(sz)
			var ribs: float = 0.5 + 0.5 * cos(ux * TAU * 4.0)
			var sipes: float = 0.5 + 0.5 * sin((vy * 8.0 + absf(ux - 0.5) * 3.0) * TAU)
			var g_raw: float = sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
			var grain: float = g_raw - floor(g_raw)
			hmap[y * sz + x] = ribs * 0.55 + sipes * 0.30 + grain * 0.15
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var strength: float = 2.4
	for y in range(sz):
		var ym: int = (y - 1 + sz) % sz
		var yp: int = (y + 1) % sz
		for x in range(sz):
			var xm: int = (x - 1 + sz) % sz
			var xp: int = (x + 1) % sz
			var dx: float = (hmap[y * sz + xp] - hmap[y * sz + xm]) * strength
			var dy: float = (hmap[yp * sz + x] - hmap[ym * sz + x]) * strength
			var n := Vector3(-dx, -dy, 1.0).normalized()
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	img.generate_mipmaps()
	_tire_detail_normal = ImageTexture.create_from_image(img)
	return _tire_detail_normal

static func enhance_vehicle_materials(car_id: String, root_node: Node3D, custom_paint: Color = Color.WHITE) -> void:
	if not root_node:
		return
	if _paint_shader == null:
		_paint_shader = load("res://assets/shaders/car_paint_aaa.gdshader") as Shader
		
	var id_lower = car_id.to_lower()
	
	# Hide mutually exclusive or corrupted body variants (e.g. Porsche Carrera GT coupe roof Body6a)
	if id_lower == "porsche_carrera_gt":
		for child in root_node.find_children("*", "Node3D", true, false):
			if child.name.to_lower().contains("body6a"):
				child.visible = false
				
	var meshes = root_node.find_children("*", "MeshInstance3D", true, false)
	var mat_cache: Dictionary = {}
	
	for m in meshes:
		var mi = m as MeshInstance3D
		if not mi.mesh:
			continue
		# Move vehicle geometry off Layer 1 so under-car ContactShadowDecal (cull_mask = 1) never projects onto skirts/tires
		mi.layers = 2
			
		var m_name = mi.name.to_lower()
		var surf_count: int = mi.mesh.get_surface_count()
		var all_interior: bool = surf_count > 0
		for s in range(surf_count):
			var active_mat = mi.get_active_material(s)
			if not active_mat:
				active_mat = mi.mesh.surface_get_material(s)

			# Fast path (< 0.01ms): re-tint already-enhanced custom car paint ShaderMaterial
			if active_mat is ShaderMaterial and (active_mat as ShaderMaterial).shader == _paint_shader:
				all_interior = false
				var base_sm := mi.mesh.surface_get_material(s) as StandardMaterial3D
				var fallback_col: Color = base_sm.albedo_color if base_sm else Color.WHITE
				var has_tex: bool = base_sm != null and base_sm.albedo_texture != null
				var new_col := Color.WHITE
				if custom_paint != Color.WHITE and custom_paint != Color(1.0, 1.0, 1.0, 1.0):
					new_col = custom_paint
				elif id_lower == "porsche_mission_x":
					new_col = Color(0.86, 0.80, 0.74, 1.0)
				elif has_tex and id_lower != "porsche_carrera_gt":
					new_col = Color.WHITE
				else:
					new_col = _get_default_factory_color(id_lower, fallback_col)
				(active_mat as ShaderMaterial).set_shader_parameter("albedo_color", new_col)
				continue

			if not (active_mat is StandardMaterial3D):
				all_interior = false
				continue
			if active_mat.has_meta("_vm_enhanced"):
				if not active_mat.has_meta("_vm_is_interior"):
					all_interior = false
				continue
				
			var sm = active_mat as StandardMaterial3D
			var mat_name = sm.resource_name.to_lower()
			
			# Strictly preserve Porsche Mission X velg (rims/calipers/badges) untouched as requested by user
			if id_lower == "porsche_mission_x" and _is_porsche_mission_x_rim(m_name, mat_name):
				all_interior = false
				continue

			var cache_key := "%d:%s" % [sm.get_instance_id(), m_name if id_lower == "porsche_carrera_gt" else mat_name]
			if mat_cache.has(cache_key):
				var cached_mat: Material = mat_cache[cache_key]
				if not cached_mat.has_meta("_vm_is_interior"):
					all_interior = false
				mi.set_surface_override_material(s, cached_mat)
				continue
				
			# 1. Optical Headlight Lens Covers (Crystal Clear Glass)
			if _is_headlight_lens(id_lower, m_name, mat_name):
				all_interior = false
				var lens_mat = sm.duplicate() as StandardMaterial3D
				lens_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				lens_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.18)
				lens_mat.metallic = 0.15
				lens_mat.metallic_specular = 1.0
				lens_mat.roughness = 0.02
				lens_mat.clearcoat_enabled = true
				lens_mat.clearcoat = 1.0
				lens_mat.clearcoat_roughness = 0.015
				lens_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = lens_mat
				mi.set_surface_override_material(s, lens_mat)
				continue
			
			# 2. Optics / Lights / Taillights (Checked before general glass)
			if _is_light(id_lower, m_name, mat_name):
				all_interior = false
				var light_mat = sm.duplicate() as StandardMaterial3D
				light_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				light_mat.roughness = 0.04
				light_mat.metallic = 0.18
				light_mat.clearcoat_enabled = true
				light_mat.clearcoat = 1.0
				if id_lower == "porsche_carrera_gt" and (mat_name == "c1_light" or m_name.contains("body3b")):
					# Porsche Carrera GT realistic xenon projector: photographic texture with chrome reflector housing
					if sm.albedo_texture != null:
						light_mat.albedo_texture = sm.albedo_texture
						light_mat.albedo_color = Color.WHITE
					light_mat.metallic = 0.85
					light_mat.roughness = 0.08
					light_mat.clearcoat_enabled = true
					light_mat.clearcoat = 1.0
					light_mat.emission_enabled = false
				elif id_lower == "angkot_dki":
					if sm.albedo_texture != null:
						light_mat.albedo_texture = sm.albedo_texture
					light_mat.albedo_color = Color.WHITE
					light_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					light_mat.metallic = 0.12
					light_mat.roughness = 0.14
					light_mat.clearcoat_enabled = true
					light_mat.clearcoat = 1.0
					if m_name.contains("indicator") or mat_name == "material_8":
						light_mat.emission_enabled = true
						light_mat.emission_texture = sm.albedo_texture
						light_mat.emission_energy_multiplier = 0.65
					elif sm.albedo_texture != null:
						light_mat.emission_enabled = true
						light_mat.emission_texture = sm.albedo_texture
						light_mat.emission_energy_multiplier = 1.35
				elif mat_name.contains("rojo") or mat_name == "rear_led" or mat_name == "t_b_l":
					# Deep ruby red taillight / rear LED lightbar optic
					light_mat.albedo_color = Color(0.85, 0.04, 0.02, 1.0)
					light_mat.emission_enabled = true
					light_mat.emission = Color(1.0, 0.06, 0.02, 1.0)
					light_mat.emission_texture = null
					light_mat.emission_energy_multiplier = 3.2
				elif mat_name.contains("red") or mat_name == "mat_199247480" or mat_name == "mat_200069275" or mat_name == "mat_199247509" or (mat_name.begins_with("light_") and mat_name.contains("rear")):
					light_mat.albedo_color = Color(0.95, 0.05, 0.02, 1.0)
					light_mat.emission_enabled = true
					light_mat.emission = Color(1.0, 0.07, 0.02, 1.0)
					light_mat.emission_texture = null
					light_mat.emission_energy_multiplier = 3.6
				elif sm.albedo_texture != null:
					light_mat.emission_enabled = true
					light_mat.emission_texture = sm.albedo_texture
					light_mat.emission_energy_multiplier = 3.2
					light_mat.emission = Color(1.0, 0.98, 0.92, 1.0)
				elif mat_name.begins_with("light_"):
					light_mat.emission_enabled = true
					light_mat.emission = Color(1.0, 0.95, 0.88)
					light_mat.emission_energy_multiplier = 3.2
				light_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = light_mat
				mi.set_surface_override_material(s, light_mat)
				continue
			
			# 3. Exterior Black Trim & Grilles
			if _is_black_trim(id_lower, m_name, mat_name):
				all_interior = false
				var trim_mat = sm.duplicate() as StandardMaterial3D
				trim_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				# Kia Carnival chrome surround & garnish
				if id_lower == "kia_carnival" and (mat_name == "mat_199247463" or mat_name == "mat_199247464"):
					trim_mat.albedo_color = Color(0.88, 0.89, 0.92, 1.0)
					trim_mat.metallic = 0.88
					trim_mat.roughness = 0.14
					trim_mat.metallic_specular = 1.0
					trim_mat.clearcoat_enabled = true
					trim_mat.clearcoat = 0.85
					trim_mat.clearcoat_roughness = 0.03
					trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					trim_mat.set_meta("_vm_enhanced", true)
					mat_cache[cache_key] = trim_mat
					mi.set_surface_override_material(s, trim_mat)
					continue
				if id_lower == "angkot_dki":
					trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					trim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					if sm.albedo_texture != null:
						trim_mat.albedo_texture = sm.albedo_texture
						trim_mat.albedo_color = Color.WHITE
					else:
						trim_mat.albedo_color = Color(0.08, 0.09, 0.10, 1.0)
					trim_mat.roughness = 0.42
					trim_mat.metallic = 0.25
					trim_mat.metallic_specular = 0.45
					trim_mat.clearcoat_enabled = false
					trim_mat.emission_enabled = false
					trim_mat.set_meta("_vm_enhanced", true)
					mat_cache[cache_key] = trim_mat
					mi.set_surface_override_material(s, trim_mat)
					continue
				# Perforated Grille Meshes (preserve honeycomb texture with alpha scissor)
				if sm.albedo_texture != null and (mat_name.contains("grill") or mat_name.contains("grilla") or mat_name == "mat_199247473"):
					trim_mat.albedo_texture = sm.albedo_texture
					trim_mat.albedo_color = Color(0.35, 0.35, 0.35, 1.0)
					if sm.normal_texture != null:
						trim_mat.normal_enabled = true
						trim_mat.normal_texture = sm.normal_texture
					trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					trim_mat.alpha_scissor_threshold = 0.5
					trim_mat.roughness = 0.48
					trim_mat.metallic = 0.25
					trim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				else:
					trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					trim_mat.albedo_texture = null
					trim_mat.albedo_color = Color(0.02, 0.02, 0.02, 1.0)
					trim_mat.roughness = 0.72
					trim_mat.metallic = 0.06
					trim_mat.metallic_specular = 0.22
					trim_mat.clearcoat_enabled = false
					trim_mat.emission_enabled = false
				trim_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = trim_mat
				mi.set_surface_override_material(s, trim_mat)
				continue
				
			# 4. Window Glass - Luxury dark tinted glass (crisp Forward+ Sky + SSR reflections)
			if _is_glass(id_lower, m_name, mat_name):
				all_interior = false
				var glass_mat = sm.duplicate() as StandardMaterial3D
				glass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if id_lower == "porsche_carrera_gt":
					glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					glass_mat.albedo_color = Color(0.04, 0.05, 0.07, 0.70)
				elif id_lower == "angkot_dki":
					glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					glass_mat.albedo_texture = null
					glass_mat.albedo_color = Color(0.08, 0.11, 0.14, 0.28)
					glass_mat.metallic = 0.15
					glass_mat.roughness = 0.02
				else:
					glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					glass_mat.albedo_color = Color(0.015, 0.016, 0.022, 1.0)
				glass_mat.metallic = 0.24
				glass_mat.metallic_specular = 1.0
				glass_mat.roughness = 0.015
				glass_mat.clearcoat_enabled = true
				glass_mat.clearcoat = 1.0
				glass_mat.clearcoat_roughness = 0.01
				glass_mat.emission_enabled = false
				glass_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = glass_mat
				mi.set_surface_override_material(s, glass_mat)
				continue
				
			# 5. Tires (Dark Charcoal Matte Rubber + Procedural Tread Normal Map)
			if _is_tire(id_lower, m_name, mat_name):
				all_interior = false
				var tire_mat = sm.duplicate() as StandardMaterial3D
				tire_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if id_lower == "porsche_mission_x":
					var tex_di = load("res://assets/models/cars/porsche_mission_x/tyre_Di.png") as Texture2D
					var tex_nm = load("res://assets/models/cars/porsche_mission_x/tyre_nm.png") as Texture2D
					if tex_di:
						tire_mat.albedo_texture = tex_di
						tire_mat.albedo_color = Color(0.75, 0.75, 0.76, 1.0)
					else:
						tire_mat.albedo_color = Color(0.11, 0.11, 0.12, 1.0)
					if tex_nm:
						tire_mat.normal_enabled = true
						tire_mat.normal_texture = tex_nm
				elif sm.albedo_texture != null:
					tire_mat.albedo_texture = sm.albedo_texture
					tire_mat.albedo_color = Color(0.86, 0.86, 0.88, 1.0)
				else:
					tire_mat.albedo_color = Color(0.10, 0.10, 0.11, 1.0)
				if not tire_mat.normal_enabled or tire_mat.normal_texture == null:
					var tread_nm := _get_tire_detail_normal()
					if tread_nm:
						tire_mat.normal_enabled = true
						tire_mat.normal_texture = tread_nm
						tire_mat.normal_scale = 0.55
				tire_mat.roughness = 0.82
				tire_mat.metallic = 0.0
				tire_mat.metallic_specular = 0.24
				tire_mat.clearcoat_enabled = false
				tire_mat.emission_enabled = false
				tire_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				tire_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = tire_mat
				mi.set_surface_override_material(s, tire_mat)
				continue
				
			# 6. Wheels / Rims / Calipers
			if _is_wheel(id_lower, m_name, mat_name):
				all_interior = false
				var wheel_mat = sm.duplicate() as StandardMaterial3D
				wheel_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				wheel_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				wheel_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				wheel_mat.emission_enabled = false
				if sm.albedo_texture != null:
					wheel_mat.albedo_texture = sm.albedo_texture
					wheel_mat.albedo_color = Color.WHITE
				elif sm.albedo_color.r > 0.4 and sm.albedo_color.g > 0.4 and sm.albedo_color.b > 0.4:
					wheel_mat.albedo_color = Color(0.85, 0.87, 0.90, 1.0)
				if sm.normal_texture != null:
					wheel_mat.normal_enabled = true
					wheel_mat.normal_texture = sm.normal_texture
				if mat_name.contains("caliper") or mat_name.contains("calliper") or mat_name == "mat_199247461":
					wheel_mat.metallic = 0.25
					wheel_mat.roughness = 0.16
					wheel_mat.clearcoat_enabled = true
					wheel_mat.clearcoat = 0.85
					wheel_mat.clearcoat_roughness = 0.03
				else:
					wheel_mat.metallic = 0.82
					wheel_mat.metallic_specular = 1.0
					wheel_mat.roughness = 0.17
					wheel_mat.clearcoat_enabled = true
					wheel_mat.clearcoat = 0.65
					wheel_mat.clearcoat_roughness = 0.03
				wheel_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = wheel_mat
				mi.set_surface_override_material(s, wheel_mat)
				continue
				
			# 7. Carbon Fiber & Aero Trim
			if _is_carbon(id_lower, m_name, mat_name) or (id_lower == "porsche_mission_x" and m_name == "0_t"):
				all_interior = false
				var carbon_mat = sm.duplicate() as StandardMaterial3D
				carbon_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if sm.albedo_texture != null:
					carbon_mat.albedo_texture = sm.albedo_texture
					carbon_mat.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
				else:
					carbon_mat.albedo_color = Color(0.08, 0.08, 0.09, 1.0)
				if sm.normal_texture != null:
					carbon_mat.normal_enabled = true
					carbon_mat.normal_texture = sm.normal_texture
				carbon_mat.roughness = 0.20
				carbon_mat.metallic = 0.16
				carbon_mat.metallic_specular = 0.85
				carbon_mat.clearcoat_enabled = true
				carbon_mat.clearcoat = 0.90
				carbon_mat.clearcoat_roughness = 0.03
				carbon_mat.emission_enabled = false
				carbon_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = carbon_mat
				mi.set_surface_override_material(s, carbon_mat)
				continue
				
			# 8. Body Paint (GTA V Dual-Layer Automotive Clearcoat + Micro-Flake PBR Shader)
			if _is_paint(id_lower, m_name, mat_name):
				all_interior = false
				var target_color = Color.WHITE
				if custom_paint != Color.WHITE and custom_paint != Color(1.0, 1.0, 1.0, 1.0):
					target_color = custom_paint
				elif sm.albedo_texture != null and id_lower != "porsche_carrera_gt":
					target_color = Color.WHITE
				else:
					target_color = _get_default_factory_color(id_lower, sm.albedo_color)

				var metal_val: float = 0.36
				var rough_val: float = 0.16
				var flake_val: float = 0.24
				var tint_col: Color = target_color

				if id_lower == "mclaren":
					metal_val = 0.32
					rough_val = 0.15
					flake_val = 0.30
				elif id_lower == "porsche_carrera_gt":
					metal_val = 0.72
					rough_val = 0.12
					flake_val = 0.32
				elif id_lower == "porsche_mission_x":
					# Deep metallic tungsten/bronze tint when keeping default texture
					if custom_paint == Color.WHITE or custom_paint == Color(1.0, 1.0, 1.0, 1.0):
						tint_col = Color(0.86, 0.80, 0.74, 1.0)
					metal_val = 0.56
					rough_val = 0.13
					flake_val = 0.30
				elif id_lower == "kia_carnival":
					metal_val = 0.44
					rough_val = 0.16
					flake_val = 0.22
				elif id_lower == "angkot_dki":
					var enamel_mat := StandardMaterial3D.new()
					enamel_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					enamel_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					enamel_mat.albedo_texture = sm.albedo_texture
					enamel_mat.albedo_color = tint_col
					enamel_mat.metallic = 0.04
					enamel_mat.roughness = 0.22
					enamel_mat.metallic_specular = 0.48
					enamel_mat.clearcoat_enabled = true
					enamel_mat.clearcoat = 0.72
					enamel_mat.clearcoat_roughness = 0.05
					enamel_mat.emission_enabled = false
					enamel_mat.set_meta("_vm_enhanced", true)
					mat_cache[cache_key] = enamel_mat
					mi.set_surface_override_material(s, enamel_mat)
					continue
				elif sm.albedo_texture != null:
					metal_val = 0.26
					rough_val = 0.17
					flake_val = 0.18

				if _paint_shader != null:
					var paint_shader_mat := ShaderMaterial.new()
					paint_shader_mat.shader = _paint_shader
					paint_shader_mat.set_shader_parameter("albedo_color", tint_col)
					paint_shader_mat.set_shader_parameter("has_albedo_tex", sm.albedo_texture != null)
					if sm.albedo_texture != null:
						paint_shader_mat.set_shader_parameter("albedo_tex", sm.albedo_texture)
					paint_shader_mat.set_shader_parameter("has_normal_tex", sm.normal_texture != null)
					if sm.normal_texture != null:
						paint_shader_mat.set_shader_parameter("normal_tex", sm.normal_texture)
						paint_shader_mat.set_shader_parameter("normal_scale", sm.normal_scale)
					paint_shader_mat.set_shader_parameter("metallic_base", metal_val)
					paint_shader_mat.set_shader_parameter("base_roughness", rough_val)
					paint_shader_mat.set_shader_parameter("clearcoat_strength", 1.0)
					paint_shader_mat.set_shader_parameter("clearcoat_roughness", 0.018)
					paint_shader_mat.set_shader_parameter("flake_intensity", flake_val)
					paint_shader_mat.set_shader_parameter("flake_scale", 220.0)
					paint_shader_mat.set_shader_parameter("orange_peel", 0.011)
					paint_shader_mat.set_shader_parameter("fresnel_richness", 0.30)
					paint_shader_mat.set_shader_parameter("ao_sill_strength", 0.28)
					paint_shader_mat.set_shader_parameter("quality_detail", _current_quality_detail)
					_paint_mat_refs.append(weakref(paint_shader_mat))
					mat_cache[cache_key] = paint_shader_mat
					mi.set_surface_override_material(s, paint_shader_mat)
					continue

				var paint_mat = sm.duplicate() as StandardMaterial3D
				paint_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				paint_mat.albedo_color = tint_col
				paint_mat.metallic = metal_val
				paint_mat.roughness = rough_val
				paint_mat.metallic_specular = 1.0
				paint_mat.emission_enabled = false
				paint_mat.clearcoat_enabled = true
				paint_mat.clearcoat = 1.0
				paint_mat.clearcoat_roughness = 0.02
				paint_mat.rim_enabled = false
				paint_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = paint_mat
				mi.set_surface_override_material(s, paint_mat)
				continue
				
			# 9. Interior, Cockpit & Cabin Characters (Solid, non-transparent, double-sided to prevent see-through holes)
			if _is_interior(id_lower, m_name, mat_name):
				var int_mat = sm.duplicate() as StandardMaterial3D
				int_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				int_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				int_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				int_mat.roughness = 0.65 if m_name.contains("character_") else (0.48 if id_lower == "angkot_dki" else 0.56)
				int_mat.metallic = 0.02 if m_name.contains("character_") else 0.05
				int_mat.metallic_specular = 0.35
				int_mat.clearcoat_enabled = false
				int_mat.emission_enabled = false
				if sm.albedo_texture != null:
					int_mat.albedo_texture = sm.albedo_texture
					int_mat.albedo_color = Color.WHITE
				else:
					int_mat.albedo_color = sm.albedo_color
				int_mat.set_meta("_vm_enhanced", true)
				int_mat.set_meta("_vm_is_interior", true)
				mat_cache[cache_key] = int_mat
				mi.set_surface_override_material(s, int_mat)
				continue

			# 10. General matte cleanup (if imported FBX left roughness at 1.0)
			all_interior = false
			if sm.roughness >= 0.95 and not _is_interior(id_lower, m_name, mat_name):
				var clean_mat = sm.duplicate() as StandardMaterial3D
				clean_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				clean_mat.roughness = 0.24
				clean_mat.metallic_specular = 0.85
				clean_mat.emission_enabled = false
				clean_mat.set_meta("_vm_enhanced", true)
				mat_cache[cache_key] = clean_mat
				mi.set_surface_override_material(s, clean_mat)

		if all_interior:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if id_lower == "angkot_dki":
				mi.visibility_range_end = 120.0
			elif id_lower != "porsche_carrera_gt":
				mi.visibility_range_end = 90.0

static func _is_headlight_lens(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "porsche_carrera_gt":
		return mesh_name.contains("body3a") or (mat_name == "c1_vidrios_tr" and mesh_name.contains("base"))
	if car_id == "kia_carnival":
		return mat_name == "mat_199247494" or mat_name == "mat_199247477" or mesh_name.contains("fl cover") or mesh_name.contains("otr lens")
	return false

static func _is_glass(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if _is_headlight_lens(car_id, mesh_name, mat_name):
		return false
	if mat_name.contains("front_refrac") or mat_name.contains("wheel_glass"):
		return false
	if car_id == "kia_carnival":
		return mat_name == "mat_199550035" \
			or mat_name == "mat_199247462" or mat_name == "mat_199247551" or mat_name == "mat_199247550" \
			or mesh_name.contains("roof glass") or mesh_name.contains("win glass")
	if car_id == "angkot_dki":
		return mesh_name == "body_glass" or mat_name == "material_0"
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_vidrios_tr"
	return mesh_name.contains("glass") or mesh_name.contains("window") or mesh_name.contains("vidrio") \
		or mat_name.contains("glass") or mat_name.contains("window") or mat_name.contains("vidrio") \
		or mat_name.contains("refrac") or mesh_name.contains("refrac")

static func _is_porsche_mission_x_rim(mesh_name: String, mat_name: String) -> bool:
	return mat_name.contains("rim") or mat_name.contains("badge") \
		or mat_name.contains("wheel_glass") or mat_name.contains("brake") \
		or mat_name == "material #266" or mat_name.contains("caliper") \
		or mesh_name.begins_with("0_t1") or mesh_name.begins_with("4_t") \
		or mesh_name.begins_with("7_t") or mesh_name.begins_with("5_t") \
		or mesh_name.begins_with("28_t") or mesh_name.begins_with("19_t") \
		or mesh_name.begins_with("246") or mesh_name.begins_with("242") \
		or mesh_name.begins_with("143") or mesh_name.begins_with("1614") \
		or mesh_name.begins_with("1824") or mesh_name == "18" \
		or mesh_name.begins_with("b_") or mesh_name.begins_with("c_")

static func _is_wheel(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "porsche_mission_x":
		# Strictly protect velg/rims of Porsche Mission X:
		return false
	if car_id == "kia_carnival":
		return mat_name == "mat_199247458" or mat_name == "mat_199247470" or mat_name == "mat_199247461" \
			or mat_name == "mat_199550092" or mat_name == "mat_199550083"
	if car_id == "porsche_carrera_gt":
		return mat_name.contains("wheel1a") or mat_name.contains("calliper") or mesh_name.contains("polysurface") \
			or mesh_name.contains("wheel")
	if car_id == "angkot_dki":
		return mesh_name.begins_with("rim_") or mat_name == "material_10"
	return mesh_name.contains("wheel") or mesh_name.contains("rim") or mesh_name.contains("caliper") or mesh_name.contains("brake") \
		or mat_name.contains("wheel") or mat_name.contains("rim") or mat_name.contains("caliper") or mat_name.contains("brake")

static func _is_tire(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "angkot_dki":
		return mesh_name.begins_with("a_tyre_") or mat_name == "material_9"
	if car_id == "kia_carnival":
		return mat_name == "mat_199247457"
	return mesh_name.contains("tyre") or mesh_name.contains("tire") \
		or mat_name.contains("tyre") or mat_name.contains("tire")

static func _is_carbon(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_carbon" or mesh_name.contains("carbon")
	return mesh_name.contains("carbon") or mat_name.contains("carbon") \
		or mat_name.contains("underbody") or mesh_name.contains("underbody") \
		or mesh_name.contains("diffuser") or mesh_name.contains("splitter")

static func _is_black_trim(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_color_plastico_negro" or mat_name == "c1_base" or mat_name == "default_material" \
			or mat_name.begins_with("c1_grilla") or mat_name.contains("grilla") or mat_name.contains("grille")
	if car_id == "kia_carnival":
		return mat_name == "mat_199247473" or mat_name == "mat_199247479" or mat_name == "mat_199532827" \
			or mat_name == "mat_199247463" or mat_name == "mat_199247464" \
			or mat_name == "mat_199247463_uvless" or mat_name == "mat_199247468" or mat_name == "mat_200102849_uvless" \
			or mesh_name.contains("fg black") or mesh_name.contains("bk line") or mesh_name.contains("dr rub frame")
	if car_id == "angkot_dki":
		return mesh_name == "body_mirrors_and_frame" or mat_name == "material_12" or mat_name == "material_-4"
	return mat_name.contains("ext_black") or mat_name.contains("grid") or mat_name.contains("gris_b") or mat_name.contains("front_refrac") or mat_name.contains("bulb_int")

static func _is_light(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "angkot_dki":
		return mesh_name == "body_lights" or mesh_name == "body_dashboard_indicators" or mat_name == "material_1" or mat_name == "material_8"
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_light" or mat_name == "c1_vidiro_rojo" or mesh_name.contains("body3b")
	if car_id == "kia_carnival":
		if mat_name.begins_with("light_") or mat_name == "mat_199247469" or mat_name == "mat_199550067" \
			or mat_name == "mat_199247480" or mat_name == "mat_200069275" or mat_name == "mat_200078058" \
			or mat_name == "mat_199247553" or mat_name == "mat_199247509" or mat_name == "mat_199247558":
			return true
	return mesh_name.contains("light") or mesh_name.contains("optic") or mesh_name.contains("faro") or mesh_name.contains("lamp") \
		or mat_name.contains("light") or mat_name.contains("optic") or mat_name.contains("faro") or mat_name.contains("lamp") \
		or mat_name == "rear_led" or mat_name == "t_b_l"

static func _is_interior(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "angkot_dki":
		return mesh_name == "body_interior_dashboard" or mesh_name == "body_interior_mirror" or mesh_name.begins_with("character_") or mat_name == "material_2" or mat_name == "material_3" or mat_name == "material_4" or mat_name == "material_5" or mat_name == "material_6" or mat_name == "material_7" or mat_name == "material_-4"
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_interior" or mat_name == "c1_bealt" or mat_name == "c1_warning" \
			or mat_name == "c1_gilla_int" or mat_name == "c1_grilla_2" or mat_name == "c1_grilla_n" \
			or mat_name.begins_with("c1_engine") or mat_name == "c1_mat_in_ex_1" \
			or mesh_name.contains("interior") or mesh_name.contains("engine")
	if car_id == "kia_carnival":
		return mat_name == "mat_199247484" or mat_name == "mat_199247521" or mat_name == "mat_199643507" \
			or mat_name == "mat_199247552" or mat_name == "mat_199247512" or mat_name == "mat_199247512_uvless" \
			or mat_name == "mat_199247554" or mat_name == "mat_199247483" or mat_name == "mat_199247556" \
			or mat_name == "mat_199247523" or mat_name == "mat_199247492" or mat_name == "mat_199247517" \
			or mat_name == "mat_199247518" or mat_name == "mat_199247519" or mat_name == "mat_199247543" \
			or mat_name == "mat_199247531" or mat_name == "mat_203703430" or mat_name == "mat_199247532" \
			or mat_name == "mat_200102840" or mat_name == "mat_199247535" or mat_name == "mat_199247536" \
			or mesh_name.contains("dr int") or mesh_name.contains("dr leather") or mesh_name.contains("dash") \
			or mesh_name.contains("seat") or mesh_name.contains("str whl") or mesh_name.contains("str wheel")
	return mesh_name.contains("interior") or mesh_name.contains("seat") or mesh_name.contains("dash") \
		or mat_name.contains("interior") or mat_name.contains("seat") or mat_name.contains("dash")

static func _is_paint(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if _is_headlight_lens(car_id, mesh_name, mat_name) or _is_glass(car_id, mesh_name, mat_name) or _is_wheel(car_id, mesh_name, mat_name) \
		or _is_tire(car_id, mesh_name, mat_name) or _is_carbon(car_id, mesh_name, mat_name) or _is_black_trim(car_id, mesh_name, mat_name) \
		or _is_light(car_id, mesh_name, mat_name) or _is_interior(car_id, mesh_name, mat_name):
		return false
	if car_id == "kia_carnival":
		return mat_name == "mat_199247467" or mat_name == "mat_199247491" or mat_name == "mat_199247471" \
			or mat_name == "mat_203792732" or mat_name == "mat_199247496_uvless" or mat_name == "mat_199247466_uvless" \
			or mesh_name.contains("carpaint") or mesh_name.contains("sm carpaint")
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_paint" or mesh_name.contains("body6a_paint") or mesh_name.contains("body7a_paint")
	if car_id == "porsche_mission_x":
		return mat_name.contains("ext_body")
	if car_id == "angkot_dki":
		return mesh_name == "body_paint_shell" or mat_name == "material_11"
	return mesh_name.contains("paint") or mesh_name.contains("body") or mesh_name.contains("carpaint") or mesh_name.contains("coloured") \
		or mat_name.contains("paint") or mat_name.contains("body") or mat_name.contains("carpaint") or mat_name.contains("c1_paint") \
		or mesh_name.contains("bonet") or mesh_name.contains("roof") or mesh_name.begins_with("124") or mesh_name.begins_with("125")

static func _get_default_factory_color(id_lower: String, fallback_color: Color) -> Color:
	match id_lower:
		"mclaren":
			return MCLAREN_PAPAYA_ORANGE
		"porsche_carrera_gt":
			return PORSCHE_GT_SILVER
		"porsche_mission_x":
			return PORSCHE_ROCKET_BRONZE
		"kia_carnival":
			return KIA_CERAMIC_SILVER
		"kia_seltos":
			return KIA_STARBRIGHT_YELLOW
		_:
			if fallback_color != Color.WHITE and fallback_color.a > 0.05:
				return fallback_color
			return Color(0.95, 0.95, 0.96, 1.0)
