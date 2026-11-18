class_name ShowcaseCar
extends Node3D

const VehicleMaterialEnhancer = preload("res://vehicles/core/VehicleMaterialEnhancer.gd")

## High-performance, lightweight vehicle showcase controller.
## Dynamically loads vehicle models with universal orientation calibration,
## spatial wheel classification, dual-pivot steering, and smooth material styling.

@export var current_model: String = "porsche_mission_x"
@export var current_paint_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var headlights_on: bool = true
@export var steer_angle: float = 0.0
@export var wheel_spin_speed: float = 0.0

const MODEL_BASE_YAW_DEG: Dictionary = {
	"coupe": 0.0,
	"apex_cruiser": 0.0,
	"drift": 0.0,
	"sedan": 0.0,
	"starter_gt": 0.0,
	"sport": 0.0,
	"mclaren": 0.0,
	"phantom_turbo": 0.0,
	"ghini": 0.0,
	"italia": 0.0,
	"rb22": 0.0,
	"gtr": 0.0,
	"veloce": 0.0,
	"hatchback": 0.0,
	"compact": 0.0,
	"minivan": 0.0,
	"offroad": 0.0,
	"pickup": 0.0,
	"suv": 0.0,
	"wagon": 0.0,
	"kia_carnival": 0.0,
	"kia_seltos": 0.0,
	"porsche_carrera_gt": 0.0,
	"porsche_mission_x": 0.0
}

var _light_material: StandardMaterial3D
var _paint_material: StandardMaterial3D
var car_body: Node3D
var car_mesh: MeshInstance3D
var _original_body_mat: Material = null
var _model_root: Node3D
var visual_pivot: Node3D

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var fx_root: Node3D = get_node_or_null("VehicleEffects")

var body_mesh: MeshInstance3D:
	get:
		return car_mesh

var front_left_wheel: Node3D
var front_right_wheel: Node3D
var rear_left_wheel: Node3D
var rear_right_wheel: Node3D

var front_left_steer_pivot: Node3D
var front_right_steer_pivot: Node3D
var wheel_spin_pivots: Array[Node3D] = []

var _idle_time: float = 0.0

var headlights_node: Node3D:
	get:
		return fx_root.get_node_or_null("HeadlightSpotL") if fx_root else null

var taillights_node: Node3D:
	get:
		return fx_root.get_node_or_null("RearTaillightGlow") if fx_root else null

var _pending_model_name: String = ""
var _pending_tscn_path: String = ""
static var _packed_scene_cache: Dictionary = {}

func _ready() -> void:
	if visual_root == null:
		visual_root = Node3D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)
	visual_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var initial_car = current_model if not current_model.is_empty() else "porsche_mission_x"
	if has_node("/root/PlayerProfile"):
		var prof = get_node("/root/PlayerProfile")
		if prof.data and not prof.data.equipped_car.is_empty():
			initial_car = prof.data.equipped_car
	elif has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if sm.has_method("get_selected_car"):
			initial_car = sm.get_selected_car()

	load_car_model(initial_car)
	set_headlights(headlights_on)
	set_steer(steer_angle)

func _process(delta: float) -> void:
	_idle_time += delta
	if visual_root:
		visual_root.position.y = 0.0
		visual_root.rotation.z = sin(_idle_time * 3.5) * 0.0005

	if wheel_spin_speed != 0.0:
		_spin_wheels(wheel_spin_speed * delta)

	# Super lazy loading background thread polling
	if not _pending_tscn_path.is_empty():
		var status = ResourceLoader.load_threaded_get_status(_pending_tscn_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed = ResourceLoader.load_threaded_get(_pending_tscn_path) as PackedScene
			if packed:
				_packed_scene_cache[_pending_tscn_path] = packed
				if _pending_model_name == current_model:
					_apply_loaded_car_scene(_pending_model_name, packed)
			_pending_tscn_path = ""
			_pending_model_name = ""
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_pending_tscn_path = ""
			_pending_model_name = ""

func load_car_model(model_name: String) -> void:
	current_model = model_name
	if not visual_root:
		return

	var tscn_path = "res://assets/models/cars/car_" + model_name + ".tscn"
	if not ResourceLoader.exists(tscn_path):
		match model_name:
			"starter_gt": tscn_path = "res://assets/models/cars/car_sedan.tscn"
			"apex_cruiser": tscn_path = "res://assets/models/cars/car_coupe.tscn"
			"phantom_turbo", "ghini", "italia", "rb22", "gtr", "veloce": tscn_path = "res://assets/models/cars/car_sport.tscn"
			_: tscn_path = "res://assets/models/cars/car_sedan.tscn"

	# If cached in memory, instant switch with 0 lag
	if _packed_scene_cache.has(tscn_path):
		_pending_tscn_path = ""
		_pending_model_name = ""
		_apply_loaded_car_scene(model_name, _packed_scene_cache[tscn_path])
		return

	# Instant direct load with cache for zero lag and full reliability
	var packed = load(tscn_path) as PackedScene
	if packed:
		_packed_scene_cache[tscn_path] = packed
		_apply_loaded_car_scene(model_name, packed)

func _apply_loaded_car_scene(model_name: String, packed: PackedScene) -> void:
	if not visual_root or not packed:
		return

	front_left_wheel = null
	front_right_wheel = null
	rear_left_wheel = null
	rear_right_wheel = null
	front_left_steer_pivot = null
	front_right_steer_pivot = null
	wheel_spin_pivots.clear()
	car_body = null
	car_mesh = null
	_model_root = null
	visual_pivot = null

	for child in visual_root.get_children():
		child.queue_free()

	var base_yaw = MODEL_BASE_YAW_DEG.get(model_name.to_lower(), 0.0)

	visual_pivot = Node3D.new()
	visual_pivot.name = "ShowcaseVisualPivot"
	visual_pivot.position = Vector3.ZERO
	visual_pivot.rotation = Vector3(0.0, deg_to_rad(base_yaw), 0.0)
	visual_root.add_child(visual_pivot)

	_model_root = packed.instantiate() as Node3D
	_model_root.position = Vector3.ZERO
	_model_root.rotation = Vector3.ZERO
	visual_pivot.add_child(_model_root)

	if model_name.to_lower() == "porsche_carrera_gt":
		for child in _model_root.find_children("*", "Node3D", true, false):
			if child.name.to_lower().contains("body6a"):
				child.visible = false

	car_body = _model_root.find_child("Body", true, false) as Node3D
	if car_body:
		for child in car_body.get_children():
			if child is MeshInstance3D:
				var c_name = child.name.to_lower()
				if c_name.contains("body") and not c_name.contains("glass") and not c_name.contains("optic"):
					car_mesh = child
					break
				elif car_mesh == null and not c_name.contains("glass") and not c_name.contains("optic"):
					car_mesh = child
	if not car_mesh:
		var meshes = _model_root.find_children("*", "MeshInstance3D", true, false)
		for m in meshes:
			var m_name = m.name.to_lower()
			if (m_name.contains("paint") or m_name.contains("carpaint")) and not m_name.contains("badge") and not m_name.contains("glass") and not m_name.contains("wheel"):
				car_mesh = m as MeshInstance3D
				break
		if not car_mesh:
			for m in meshes:
				var m_name = m.name.to_lower()
				if m_name.contains("body") and not m_name.contains("badge") and not m_name.contains("base") and not m_name.contains("glass") and not m_name.contains("optic") and not m_name.contains("wheel"):
					car_mesh = m as MeshInstance3D
					break
		if not car_mesh and not meshes.is_empty():
			car_mesh = meshes[0] as MeshInstance3D

	if car_mesh:
		_original_body_mat = car_mesh.get_surface_override_material(0)

	_prepare_vehicle_wheels()
	_setup_showcase_wheels()
	_setup_materials()
	set_headlights(headlights_on)
	set_steer(steer_angle)

func _prepare_vehicle_wheels() -> void:
	if not _model_root:
		return
	var cid = current_model.to_lower()
	var w_fl = _model_root.get_node_or_null("Wheel_FL") as Node3D
	var w_fr = _model_root.get_node_or_null("Wheel_FR") as Node3D
	var w_rl = _model_root.get_node_or_null("Wheel_RL") as Node3D
	var w_rr = _model_root.get_node_or_null("Wheel_RR") as Node3D
	if not w_fl or not w_fr or not w_rl or not w_rr:
		return
		
	if cid == "porsche_mission_x":
		var m_fl = _model_root.find_child("WHEEL_LF", true, false)
		var m_fr = _model_root.find_child("WHEEL_RF", true, false)
		var m_rl = _model_root.find_child("WHEEL_LR", true, false)
		var m_rr = _model_root.find_child("WHEEL_RR", true, false)
		w_fl.position = Vector3(-0.8016, 0.3716, -1.3472)
		w_fr.position = Vector3(0.8326, 0.3716, -1.3472)
		w_rl.position = Vector3(-0.8176, 0.390, 1.3827)
		w_rr.position = Vector3(0.875, 0.390, 1.3827)
		if m_fl:
			for c in m_fl.get_children():
				c.owner = null
				c.reparent(w_fl, true)
		if m_fr:
			for c in m_fr.get_children():
				c.owner = null
				c.reparent(w_fr, true)
		if m_rl:
			for c in m_rl.get_children():
				c.owner = null
				c.reparent(w_rl, true)
		if m_rr:
			for c in m_rr.get_children():
				c.owner = null
				c.reparent(w_rr, true)
				
	elif cid == "porsche_carrera_gt":
		w_fl.position = Vector3(-0.8, 0.326, -1.369)
		w_fr.position = Vector3(0.8, 0.326, -1.369)
		w_rl.position = Vector3(-0.774, 0.345, 1.363)
		w_rr.position = Vector3(0.774, 0.345, 1.363)
		var cw = _model_root.find_child("Combined_Wheels_3D_", true, false)
		if cw:
			for m in cw.find_children("*", "MeshInstance3D", true, false):
				if m.mesh:
					var c = m.position
					m.owner = null
					if c.z >= 0 and c.x >= 0:
						m.reparent(w_fl, true)
					elif c.z >= 0 and c.x < 0:
						m.reparent(w_fr, true)
					elif c.z < 0 and c.x >= 0:
						m.reparent(w_rl, true)
					elif c.z < 0 and c.x < 0:
						m.reparent(w_rr, true)
						
	elif cid == "kia_carnival":
		var t1 = _model_root.find_child("tire 1", true, false)
		var t2 = _model_root.find_child("tire 2", true, false)
		var t3 = _model_root.find_child("tire 3", true, false)
		if t1:
			w_fl.position = _model_root.to_local(t1.global_position)
			for c in t1.get_children():
				c.owner = null
				c.reparent(w_fl, true)
		if t2:
			w_fr.position = _model_root.to_local(t2.global_position)
			for c in t2.get_children():
				c.owner = null
				c.reparent(w_fr, true)
		if t3:
			var t_rl = t3.find_child("tire_001", true, false)
			var t_rr = t3.find_child("tire001", true, false)
			if t_rl:
				w_rl.position = _model_root.to_local(t_rl.global_position)
			if t_rr:
				w_rr.position = _model_root.to_local(t_rr.global_position)
			for nm in ["tire_001", "GSMBiDim_108423", "brake_pad_003", "brake_003"]:
				var p = t3.find_child(nm, true, false)
				if p:
					p.owner = null
					p.reparent(w_rl, true)
			for nm in ["tire001", "GSMBiDim_108425"]:
				var p = t3.find_child(nm, true, false)
				if p:
					p.owner = null
					p.reparent(w_rr, true)
					
	elif cid == "kia_seltos":
		var s_fl = _model_root.find_child("00_203 tire FL", true, false)
		var s_fr = _model_root.find_child("00_211 tire FR", true, false)
		var s_rl = _model_root.find_child("00_188 tire RL", true, false)
		var s_rr = _model_root.find_child("00_195 tire RR", true, false)
		if s_fl:
			w_fl.position = _model_root.to_local(s_fl.global_position)
			s_fl.owner = null
			s_fl.reparent(w_fl, true)
		if s_fr:
			w_fr.position = _model_root.to_local(s_fr.global_position)
			s_fr.owner = null
			s_fr.reparent(w_fr, true)
		if s_rl:
			w_rl.position = _model_root.to_local(s_rl.global_position)
			s_rl.owner = null
			s_rl.reparent(w_rl, true)
		if s_rr:
			w_rr.position = _model_root.to_local(s_rr.global_position)
			s_rr.owner = null
			s_rr.reparent(w_rr, true)
			
	elif cid == "mclaren":
		var m_fl = _model_root.find_child("3DWheel Front L", true, false)
		var m_fr = _model_root.find_child("3DWheel Front R", true, false)
		var m_rl = _model_root.find_child("3DWheel Rear L", true, false)
		var m_rr = _model_root.find_child("3DWheel Rear R", true, false)
		if m_fl:
			w_fl.position = _model_root.to_local(m_fl.global_position)
			m_fl.owner = null
			m_fl.reparent(w_fl, true)
		if m_fr:
			w_fr.position = _model_root.to_local(m_fr.global_position)
			m_fr.owner = null
			m_fr.reparent(w_fr, true)
		if m_rl:
			w_rl.position = _model_root.to_local(m_rl.global_position)
			m_rl.owner = null
			m_rl.reparent(w_rl, true)
		if m_rr:
			w_rr.position = _model_root.to_local(m_rr.global_position)
			m_rr.owner = null
			m_rr.reparent(w_rr, true)

func _setup_showcase_wheels() -> void:
	if not _model_root or not visual_pivot:
		return

	var all_nodes: Array[Node3D] = []
	var stack: Array[Node] = [_model_root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n != _model_root and n is Node3D:
			all_nodes.append(n as Node3D)
		for c in n.get_children():
			stack.push_back(c)

	var wheel_candidates: Array[Node3D] = []
	for node in all_nodes:
		var nm = node.name.to_lower()
		if nm.contains("wheel") or nm.contains("tire") or nm.contains("tyre") or nm.contains("rim"):
			# Visual check: candidate must contain actual mesh geometry
			var mc = 1 if node is MeshInstance3D else node.find_children("*", "MeshInstance3D", true, false).size()
			if mc == 0:
				continue
			var parent_node = node.get_parent()
			var parent_is_wheel = false
			if parent_node is Node3D:
				var p_nm = parent_node.name.to_lower()
				if p_nm.contains("wheel") or p_nm.contains("tire") or p_nm.contains("tyre") or p_nm.contains("rim"):
					parent_is_wheel = true
			if not parent_is_wheel:
				wheel_candidates.append(node)

	var sorted_wheels = {"fl": null, "fr": null, "rl": null, "rr": null}
	for cand in wheel_candidates:
		var c_name = cand.name.to_lower()
		if c_name == "wheel_fl" or c_name.ends_with("_fl") or c_name.ends_with("_lf"):
			sorted_wheels["fl"] = cand
		elif c_name == "wheel_fr" or c_name.ends_with("_fr") or c_name.ends_with("_rf"):
			sorted_wheels["fr"] = cand
		elif c_name == "wheel_rl" or c_name.ends_with("_rl") or c_name.ends_with("_lr"):
			sorted_wheels["rl"] = cand
		elif c_name == "wheel_rr" or c_name.ends_with("_rr"):
			sorted_wheels["rr"] = cand

	for cand in wheel_candidates:
		if cand in sorted_wheels.values():
			continue
		var l_pos = Vector3.ZERO
		if cand.is_inside_tree() and visual_pivot.is_inside_tree():
			l_pos = visual_pivot.to_local(cand.global_position)
		else:
			l_pos = visual_pivot.transform.basis.inverse() * cand.position

		if l_pos.z < 0.0 and l_pos.x <= 0.0 and sorted_wheels["fl"] == null:
			sorted_wheels["fl"] = cand
		elif l_pos.z < 0.0 and l_pos.x > 0.0 and sorted_wheels["fr"] == null:
			sorted_wheels["fr"] = cand
		elif l_pos.z >= 0.0 and l_pos.x <= 0.0 and sorted_wheels["rl"] == null:
			sorted_wheels["rl"] = cand
		elif l_pos.z >= 0.0 and l_pos.x > 0.0 and sorted_wheels["rr"] == null:
			sorted_wheels["rr"] = cand

	# Protect complex imported hierarchies from destructive reparenting
	var can_reparent = true
	for tag in ["fl", "fr", "rl", "rr"]:
		var w = sorted_wheels[tag]
		if w and w.get_parent() != _model_root:
			can_reparent = false
			break

	front_left_wheel = sorted_wheels["fl"]
	front_right_wheel = sorted_wheels["fr"]
	rear_left_wheel = sorted_wheels["rl"]
	rear_right_wheel = sorted_wheels["rr"]

	if not can_reparent or wheel_candidates.is_empty():
		return

	if sorted_wheels["fr"] == null and sorted_wheels["fl"] != null:
		var cloned_fr = sorted_wheels["fl"].duplicate() as Node3D
		cloned_fr.name = "Wheel_FR_Mirrored"
		sorted_wheels["fl"].get_parent().add_child(cloned_fr)
		cloned_fr.position = Vector3(-sorted_wheels["fl"].position.x, sorted_wheels["fl"].position.y, sorted_wheels["fl"].position.z)
		sorted_wheels["fr"] = cloned_fr

	if sorted_wheels["fl"] == null and sorted_wheels["fr"] != null:
		var cloned_fl = sorted_wheels["fr"].duplicate() as Node3D
		cloned_fl.name = "Wheel_FL_Mirrored"
		sorted_wheels["fr"].get_parent().add_child(cloned_fl)
		cloned_fl.position = Vector3(-sorted_wheels["fr"].position.x, sorted_wheels["fr"].position.y, sorted_wheels["fr"].position.z)
		sorted_wheels["fl"] = cloned_fl

	if sorted_wheels["rr"] == null and sorted_wheels["rl"] != null:
		var cloned_rr = sorted_wheels["rl"].duplicate() as Node3D
		cloned_rr.name = "Wheel_RR_Mirrored"
		sorted_wheels["rl"].get_parent().add_child(cloned_rr)
		cloned_rr.position = Vector3(-sorted_wheels["rl"].position.x, sorted_wheels["rl"].position.y, sorted_wheels["rl"].position.z)
		sorted_wheels["rr"] = cloned_rr

	if sorted_wheels["rl"] == null and sorted_wheels["rr"] != null:
		var cloned_rl = sorted_wheels["rr"].duplicate() as Node3D
		cloned_rl.name = "Wheel_RL_Mirrored"
		sorted_wheels["rr"].get_parent().add_child(cloned_rl)
		cloned_rl.position = Vector3(-sorted_wheels["rr"].position.x, sorted_wheels["rr"].position.y, sorted_wheels["rr"].position.z)
		sorted_wheels["rl"] = cloned_rl

	front_left_wheel = sorted_wheels["fl"]
	front_right_wheel = sorted_wheels["fr"]
	rear_left_wheel = sorted_wheels["rl"]
	rear_right_wheel = sorted_wheels["rr"]

	for tag in ["fl", "fr", "rl", "rr"]:
		var w_node = sorted_wheels[tag]
		if not w_node:
			continue
		var w_pos = Vector3.ZERO
		if w_node.is_inside_tree() and visual_pivot.is_inside_tree():
			w_pos = visual_pivot.to_local(w_node.global_position)
		else:
			w_pos = visual_pivot.transform.basis.inverse() * w_node.position

		var steer_pivot = Node3D.new()
		steer_pivot.name = "ShowcaseWheel_" + tag.to_upper() + "_SteerPivot"
		visual_pivot.add_child(steer_pivot)
		steer_pivot.position = w_pos
		steer_pivot.rotation = Vector3.ZERO

		var spin_pivot = Node3D.new()
		spin_pivot.name = "ShowcaseWheel_" + tag.to_upper() + "_SpinPivot"
		steer_pivot.add_child(spin_pivot)
		spin_pivot.position = Vector3.ZERO
		spin_pivot.rotation = Vector3.ZERO

		if tag == "fl":
			front_left_steer_pivot = steer_pivot
		elif tag == "fr":
			front_right_steer_pivot = steer_pivot
		wheel_spin_pivots.append(spin_pivot)

		w_node.owner = null
		var wp = w_node.get_parent()
		if wp:
			wp.remove_child(w_node)
		spin_pivot.add_child(w_node)
		w_node.position = Vector3.ZERO
		w_node.rotation = Vector3.ZERO

func _setup_materials() -> void:
	if not _model_root:
		return
	var target_root = visual_pivot if visual_pivot else _model_root
	VehicleMaterialEnhancer.enhance_vehicle_materials(current_model, target_root, current_paint_color)

func set_paint_color(color: Color) -> void:
	current_paint_color = color
	if _model_root:
		var target_root = visual_pivot if visual_pivot else _model_root
		VehicleMaterialEnhancer.enhance_vehicle_materials(current_model, target_root, color)

func set_headlights(on: bool) -> void:
	headlights_on = on
	if fx_root:
		var spot_l = fx_root.get_node_or_null("HeadlightSpotL") as SpotLight3D
		var spot_r = fx_root.get_node_or_null("HeadlightSpotR") as SpotLight3D
		var rear_glow = fx_root.get_node_or_null("RearTaillightGlow") as OmniLight3D
		if spot_l:
			spot_l.position = Vector3(-0.65, 0.45, -2.15)
			spot_l.rotation = Vector3(deg_to_rad(-6.0), 0.0, 0.0)
			spot_l.visible = on
		if spot_r:
			spot_r.position = Vector3(0.65, 0.45, -2.15)
			spot_r.rotation = Vector3(deg_to_rad(-6.0), 0.0, 0.0)
			spot_r.visible = on
		if rear_glow:
			rear_glow.position = Vector3(0.0, 0.45, 2.15)
			rear_glow.light_energy = 0.8
			rear_glow.omni_range = 3.5
			rear_glow.visible = on

func set_steer(angle_deg: float) -> void:
	steer_angle = angle_deg
	var rad = deg_to_rad(angle_deg)
	if front_left_steer_pivot:
		front_left_steer_pivot.rotation.y = rad
	elif front_left_wheel:
		front_left_wheel.rotation.y = rad
		
	if front_right_steer_pivot:
		front_right_steer_pivot.rotation.y = rad
	elif front_right_wheel:
		front_right_wheel.rotation.y = rad

func set_wheel_spin(speed: float) -> void:
	wheel_spin_speed = speed

func _spin_wheels(delta_rad: float) -> void:
	if not wheel_spin_pivots.is_empty():
		for sp in wheel_spin_pivots:
			if sp:
				sp.rotation.x = wrapf(sp.rotation.x - delta_rad, -PI, PI)
	else:
		for w in [front_left_wheel, front_right_wheel, rear_left_wheel, rear_right_wheel]:
			if w:
				w.rotate_x(delta_rad)

func apply_visual_scene(packed: PackedScene) -> void:
	if not packed:
		return
	if visual_root:
		for c in visual_root.get_children():
			c.queue_free()
	var new_vis = packed.instantiate() as Node3D
	new_vis.name = "VisualRoot"
	add_child(new_vis)
	visual_root = new_vis
	_setup_showcase_wheels()
	_setup_materials()
	set_headlights(headlights_on)
	set_steer(steer_angle)
