class_name VehicleMaterialEnhancer
extends RefCounted

# Universal PBR Material Enhancer for 3D Vehicles.
# Calibrates raw imported mesh materials (FBX/GLB) into high-fidelity automotive finishes:
# - Automotive metallic clearcoat lacquer for body panels (eliminates dull/chalky/burik look)
# - Realistic tinted glass with reflection and transparency
# - High-gloss metallic alloy rims and brake calipers
# - Woven carbon fiber with specularity and clearcoat
# - Headlight and taillight optical emission

const MCLAREN_PAPAYA_ORANGE = Color(1.0, 0.46, 0.01, 1.0)
const PORSCHE_GT_SILVER = Color(0.88, 0.90, 0.92, 1.0)
const PORSCHE_ROCKET_BRONZE = Color(0.74, 0.68, 0.62, 1.0)
const KIA_CERAMIC_SILVER = Color(0.88, 0.90, 0.92, 1.0)
const KIA_STARBRIGHT_YELLOW = Color(0.96, 0.78, 0.10, 1.0)

static func enhance_vehicle_materials(car_id: String, root_node: Node3D, custom_paint: Color = Color.WHITE) -> void:
	if not root_node:
		return
		
	var id_lower = car_id.to_lower()
	
	# Hide mutually exclusive or corrupted body variants (e.g. Porsche Carrera GT coupe roof Body6a)
	if id_lower == "porsche_carrera_gt":
		for child in root_node.find_children("*", "Node3D", true, false):
			if child.name.to_lower().contains("body6a"):
				child.visible = false
				
	var meshes = root_node.find_children("*", "MeshInstance3D", true, false)
	
	for m in meshes:
		var mi = m as MeshInstance3D
		if not mi.mesh:
			continue
			
		var m_name = mi.name.to_lower()
		for s in range(mi.mesh.get_surface_count()):
			var active_mat = mi.get_active_material(s)
			if not active_mat:
				active_mat = mi.mesh.surface_get_material(s)
			if not (active_mat is StandardMaterial3D):
				continue
				
			var sm = active_mat as StandardMaterial3D
			var mat_name = sm.resource_name.to_lower()
			
			# Strictly preserve Porsche Mission X velg (rims/calipers/badges) untouched as requested by user
			if id_lower == "porsche_mission_x" and _is_porsche_mission_x_rim(m_name, mat_name):
				continue
				
			# 1. Optical Headlight Lens Covers (Crystal Clear Glass)
			if _is_headlight_lens(id_lower, m_name, mat_name):
				var lens_mat = sm.duplicate() as StandardMaterial3D
				lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				lens_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.18)
				lens_mat.metallic = 0.1
				lens_mat.metallic_specular = 1.0
				lens_mat.roughness = 0.03
				lens_mat.clearcoat_enabled = true
				lens_mat.clearcoat = 1.0
				lens_mat.clearcoat_roughness = 0.02
				mi.set_surface_override_material(s, lens_mat)
				continue
			
			# 2. Optics / Lights / Taillights (Checked before general glass)
			if _is_light(id_lower, m_name, mat_name):
				var light_mat = sm.duplicate() as StandardMaterial3D
				light_mat.roughness = 0.05
				light_mat.metallic = 0.15
				light_mat.clearcoat_enabled = true
				light_mat.clearcoat = 1.0
				if id_lower == "porsche_carrera_gt" and (mat_name == "c1_light" or m_name.contains("body3b")):
					# Porsche Carrera GT realistic xenon projector: photographic texture with chrome reflector housing
					if sm.albedo_texture != null:
						light_mat.albedo_texture = sm.albedo_texture
						light_mat.albedo_color = Color.WHITE
					light_mat.metallic = 0.8
					light_mat.roughness = 0.1
					light_mat.clearcoat_enabled = true
					light_mat.clearcoat = 1.0
					light_mat.emission_enabled = false
				elif mat_name.contains("rojo"):
					# Deep ruby red taillight optic
					light_mat.albedo_color = Color(0.70, 0.04, 0.02, 1.0)
					light_mat.emission_enabled = true
					light_mat.emission = Color(0.85, 0.05, 0.02, 1.0)
					light_mat.emission_energy_multiplier = 1.2
				elif mat_name.contains("red") or mat_name == "mat_199247480" or mat_name == "mat_200069275" or mat_name == "mat_199247509":
					light_mat.albedo_color = Color(0.95, 0.05, 0.02, 1.0)
					light_mat.emission_enabled = true
					light_mat.emission = Color(1.0, 0.06, 0.02, 1.0)
					light_mat.emission_energy_multiplier = 3.0
				elif sm.albedo_texture != null:
					light_mat.emission_enabled = true
					light_mat.emission_texture = sm.albedo_texture
					light_mat.emission_energy_multiplier = 2.2
					light_mat.emission = Color(1.0, 0.98, 0.92, 1.0)
				elif mat_name.begins_with("light_"):
					light_mat.emission_enabled = true
					light_mat.emission = Color(1.0, 0.3, 0.1) if mat_name.contains("rear") else Color(1.0, 0.95, 0.85)
					light_mat.emission_energy_multiplier = 2.2
				mi.set_surface_override_material(s, light_mat)
				continue
			
			# 3. Exterior Black Trim & Grilles
			if _is_black_trim(id_lower, m_name, mat_name):
				var trim_mat = sm.duplicate() as StandardMaterial3D
				# Kia Carnival chrome surround & garnish
				if id_lower == "kia_carnival" and (mat_name == "mat_199247463" or mat_name == "mat_199247464"):
					trim_mat.albedo_color = Color(0.88, 0.89, 0.92, 1.0)
					trim_mat.metallic = 0.85
					trim_mat.roughness = 0.18
					trim_mat.metallic_specular = 1.0
					trim_mat.clearcoat_enabled = true
					trim_mat.clearcoat = 0.8
					trim_mat.clearcoat_roughness = 0.03
					trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
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
					trim_mat.roughness = 0.5
					trim_mat.metallic = 0.2
					trim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				else:
					trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					trim_mat.albedo_texture = null
					trim_mat.albedo_color = Color(0.02, 0.02, 0.02, 1.0)
					trim_mat.roughness = 0.88
					trim_mat.metallic = 0.04
					trim_mat.metallic_specular = 0.1
					trim_mat.clearcoat_enabled = false
					trim_mat.emission_enabled = false
				mi.set_surface_override_material(s, trim_mat)
				continue
				
			# 4. Window Glass - Luxury dark tinted glass (with subtle transparency so headlights shine through)
			if _is_glass(id_lower, m_name, mat_name):
				var glass_mat = sm.duplicate() as StandardMaterial3D
				if id_lower == "porsche_carrera_gt":
					glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					glass_mat.albedo_color = Color(0.04, 0.05, 0.07, 0.70)
				else:
					glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					glass_mat.albedo_color = Color(0.012, 0.012, 0.015, 1.0)
				glass_mat.metallic = 0.15
				glass_mat.metallic_specular = 1.0
				glass_mat.roughness = 0.02
				glass_mat.clearcoat_enabled = true
				glass_mat.clearcoat = 1.0
				glass_mat.clearcoat_roughness = 0.02
				mi.set_surface_override_material(s, glass_mat)
				continue
				
			# 5. Tires (Dark Charcoal Matte Rubber)
			if _is_tire(id_lower, m_name, mat_name):
				var tire_mat = sm.duplicate() as StandardMaterial3D
				if id_lower == "porsche_mission_x":
					var tex_di = load("res://assets/models/cars/porsche_mission_x/tyre_Di.png") as Texture2D
					var tex_nm = load("res://assets/models/cars/porsche_mission_x/tyre_nm.png") as Texture2D
					if tex_di:
						tire_mat.albedo_texture = tex_di
						tire_mat.albedo_color = Color(0.85, 0.85, 0.85, 1.0)
					else:
						tire_mat.albedo_color = Color(0.12, 0.12, 0.12, 1.0)
					if tex_nm:
						tire_mat.normal_enabled = true
						tire_mat.normal_texture = tex_nm
				else:
					tire_mat.albedo_color = Color(0.12, 0.12, 0.13, 1.0)
				tire_mat.roughness = 0.88
				tire_mat.metallic = 0.0
				tire_mat.metallic_specular = 0.25
				tire_mat.clearcoat_enabled = false
				tire_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mi.set_surface_override_material(s, tire_mat)
				continue
				
			# 6. Wheels / Rims / Calipers
			if _is_wheel(id_lower, m_name, mat_name):
				var wheel_mat = sm.duplicate() as StandardMaterial3D
				wheel_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				wheel_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				if sm.albedo_texture != null:
					wheel_mat.albedo_texture = sm.albedo_texture
					wheel_mat.albedo_color = Color.WHITE
				elif sm.albedo_color.r > 0.4 and sm.albedo_color.g > 0.4 and sm.albedo_color.b > 0.4:
					wheel_mat.albedo_color = Color(0.85, 0.87, 0.90, 1.0)
				if sm.normal_texture != null:
					wheel_mat.normal_enabled = true
					wheel_mat.normal_texture = sm.normal_texture
				if mat_name.contains("caliper") or mat_name.contains("calliper") or mat_name == "mat_199247461":
					wheel_mat.metallic = 0.2
					wheel_mat.roughness = 0.18
					wheel_mat.clearcoat_enabled = true
					wheel_mat.clearcoat = 0.8
					wheel_mat.clearcoat_roughness = 0.04
				else:
					wheel_mat.metallic = 0.65
					wheel_mat.metallic_specular = 0.95
					wheel_mat.roughness = 0.22
					wheel_mat.clearcoat_enabled = true
					wheel_mat.clearcoat = 0.5
					wheel_mat.clearcoat_roughness = 0.04
				mi.set_surface_override_material(s, wheel_mat)
				continue
				
			# 7. Carbon Fiber & Aero Trim
			if _is_carbon(id_lower, m_name, mat_name) or (id_lower == "porsche_mission_x" and m_name == "0_t"):
				var carbon_mat = sm.duplicate() as StandardMaterial3D
				if sm.albedo_texture != null:
					carbon_mat.albedo_texture = sm.albedo_texture
					carbon_mat.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
				else:
					carbon_mat.albedo_color = Color(0.08, 0.08, 0.09, 1.0)
				if sm.normal_texture != null:
					carbon_mat.normal_enabled = true
					carbon_mat.normal_texture = sm.normal_texture
				carbon_mat.roughness = 0.24
				carbon_mat.metallic = 0.12
				carbon_mat.metallic_specular = 0.7
				carbon_mat.clearcoat_enabled = true
				carbon_mat.clearcoat = 0.8
				carbon_mat.clearcoat_roughness = 0.04
				mi.set_surface_override_material(s, carbon_mat)
				continue
				
			# 8. Body Paint (Vibrant, high-gloss automotive lacquer with 3D contour depth)
			if _is_paint(id_lower, m_name, mat_name):
				var paint_mat = sm.duplicate() as StandardMaterial3D
				
				# Determine base factory color
				var target_color = Color.WHITE
				if custom_paint != Color.WHITE and custom_paint != Color(1.0, 1.0, 1.0, 1.0):
					target_color = custom_paint
				elif sm.albedo_texture != null and id_lower != "porsche_carrera_gt":
					target_color = Color.WHITE
				else:
					target_color = _get_default_factory_color(id_lower, sm.albedo_color)
					
				paint_mat.albedo_color = target_color
				
				# Dielectric base with fine metallic micro-flakes preserves full color brilliance
				if id_lower == "mclaren":
					paint_mat.metallic = 0.18
					paint_mat.roughness = 0.14
					paint_mat.metallic_specular = 0.95
				elif id_lower == "porsche_carrera_gt":
					paint_mat.metallic = 0.65
					paint_mat.roughness = 0.12
					paint_mat.metallic_specular = 0.98
				elif id_lower == "porsche_mission_x":
					paint_mat.metallic = 0.40
					paint_mat.roughness = 0.16
					paint_mat.metallic_specular = 0.95
				elif id_lower == "kia_carnival":
					paint_mat.metallic = 0.35
					paint_mat.roughness = 0.14
					paint_mat.metallic_specular = 0.95
				elif sm.albedo_texture != null:
					paint_mat.metallic = 0.22
					paint_mat.roughness = 0.18
					paint_mat.metallic_specular = 0.92
				else:
					paint_mat.metallic = 0.28
					paint_mat.roughness = 0.16
					paint_mat.metallic_specular = 0.95
					
				paint_mat.clearcoat_enabled = true
				paint_mat.clearcoat = 1.0
				paint_mat.clearcoat_roughness = 0.03
				
				# Fresnel rim lighting brings out 3D curvature and depth
				paint_mat.rim_enabled = true
				paint_mat.rim = 0.38
				paint_mat.rim_tint = 0.2
				
				mi.set_surface_override_material(s, paint_mat)
				continue
				
			# 9. Interior & Cockpit Trim (Solid, non-transparent, double-sided to prevent see-through holes)
			if _is_interior(id_lower, m_name, mat_name):
				var int_mat = sm.duplicate() as StandardMaterial3D
				int_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				int_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				int_mat.roughness = 0.58
				int_mat.metallic = 0.05
				int_mat.metallic_specular = 0.35
				int_mat.clearcoat_enabled = false
				if sm.albedo_texture != null:
					int_mat.albedo_texture = sm.albedo_texture
					int_mat.albedo_color = Color.WHITE
				else:
					int_mat.albedo_color = sm.albedo_color
				mi.set_surface_override_material(s, int_mat)
				continue

			# 10. General matte cleanup (if imported FBX left roughness at 1.0)
			if sm.roughness >= 0.95 and not _is_interior(id_lower, m_name, mat_name):
				var clean_mat = sm.duplicate() as StandardMaterial3D
				clean_mat.roughness = 0.25
				clean_mat.metallic_specular = 0.8
				mi.set_surface_override_material(s, clean_mat)

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
	return mesh_name.contains("wheel") or mesh_name.contains("rim") or mesh_name.contains("caliper") or mesh_name.contains("brake") \
		or mat_name.contains("wheel") or mat_name.contains("rim") or mat_name.contains("caliper") or mat_name.contains("brake")

static func _is_tire(car_id: String, mesh_name: String, mat_name: String) -> bool:
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
	return mat_name.contains("ext_black") or mat_name.contains("grid") or mat_name.contains("gris_b") or mat_name.contains("front_refrac") or mat_name.contains("bulb_int")

static func _is_light(car_id: String, mesh_name: String, mat_name: String) -> bool:
	if car_id == "porsche_carrera_gt":
		return mat_name == "c1_light" or mat_name == "c1_vidiro_rojo" or mesh_name.contains("body3b")
	if car_id == "kia_carnival":
		if mat_name.begins_with("light_") or mat_name == "mat_199247469" or mat_name == "mat_199550067" \
			or mat_name == "mat_199247480" or mat_name == "mat_200069275" or mat_name == "mat_200078058" \
			or mat_name == "mat_199247553" or mat_name == "mat_199247509" or mat_name == "mat_199247558":
			return true
	return mesh_name.contains("light") or mesh_name.contains("optic") or mesh_name.contains("faro") or mesh_name.contains("lamp") \
		or mat_name.contains("light") or mat_name.contains("optic") or mat_name.contains("faro") or mat_name.contains("lamp")

static func _is_interior(car_id: String, mesh_name: String, mat_name: String) -> bool:
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
