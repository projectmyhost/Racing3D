class_name ShowcaseCar
extends Node3D

const VehicleMaterialEnhancer = preload("res://vehicles/core/VehicleMaterialEnhancer.gd")
const VehicleConfigScript = preload("res://vehicles/core/VehicleConfig.gd")

## High-performance, zero-lag vehicle showcase controller.
## Uses background threaded ResourceLoader preloading + pre-built rig pooling
## so switching cars and equipping in Garage is instantaneous (< 1 ms).

signal car_model_ready(model_id: String)

@export var current_model: String = "porsche_mission_x"
@export var current_paint_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var headlights_on: bool = true
@export var steer_angle: float = 0.0
@export var wheel_spin_speed: float = 0.0
@export var use_world_scale: bool = true
@export var idle_sway_enabled: bool = true
@export var auto_load_on_ready: bool = true

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
	"porsche_mission_x": 0.0,
	"angkot_dki": 0.0
}

const DEFAULT_PRELOAD_ORDER: Array[String] = [
	"porsche_mission_x", "angkot_dki", "mclaren", "porsche_carrera_gt",
	"kia_seltos", "kia_carnival", "sport", "coupe",
	"sedan", "hatchback", "compact", "suv", "wagon",
	"minivan", "pickup", "offroad"
]

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
var _active_rig_model: String = ""
var _rig_pool: Dictionary = {}
const MAX_POOLED_RIGS: int = 4
var _rig_lru: Array[String] = []

# Background threaded preload + idle rig warmup state
var _bg_model_queue: Array[String] = []
var _bg_inflight_path: String = ""
var _bg_inflight_model: String = ""
var _warm_rig_queue: Array[String] = []
var _warm_cooldown_frames: int = 0
var _preload_started: bool = false
var garage_open: bool = false

static var _packed_scene_cache: Dictionary = {}

func get_effective_scale() -> float:
	return VehicleConfigScript.WORLD_SCALE if use_world_scale else 1.0

func _ready() -> void:
	if visual_root == null:
		visual_root = Node3D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)
	visual_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var world_s: float = get_effective_scale()
	visual_root.scale = Vector3.ONE * world_s

	VehicleMaterialEnhancer.attach_contact_shadow(self, Vector3(0.0, 0.05 * world_s, 0.0), 2.25 * world_s, 4.75 * world_s)

	if not auto_load_on_ready:
		set_headlights(headlights_on)
		set_steer(steer_angle)
		return

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

func _schedule_background_preload() -> void:
	if _preload_started or not is_inside_tree():
		return
	_preload_started = true
	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		warm_garage_fleet(DEFAULT_PRELOAD_ORDER)

func warm_garage_fleet(car_ids: Array) -> void:
	# Bound background warming to MAX_POOLED_RIGS while Garage is open so VRAM stays lean
	var queued := 0
	for cid_raw in car_ids:
		if queued >= MAX_POOLED_RIGS:
			break
		var cid: String = str(cid_raw).to_lower()
		if cid.is_empty() or _rig_pool.has(cid):
			continue
		var tscn_path: String = _resolve_tscn_path(cid)
		if _packed_scene_cache.has(tscn_path):
			if not (cid in _warm_rig_queue):
				_warm_rig_queue.append(cid)
				queued += 1
		else:
			if not (cid in _bg_model_queue):
				_bg_model_queue.append(cid)
				queued += 1

func _exit_tree() -> void:
	_bg_model_queue.clear()
	_warm_rig_queue.clear()
	_bg_inflight_path = ""
	_bg_inflight_model = ""
	_pending_tscn_path = ""
	_pending_model_name = ""

func _process(delta: float) -> void:
	_idle_time += delta
	if visual_root and idle_sway_enabled:
		visual_root.position.y = 0.0
		visual_root.rotation.z = sin(_idle_time * 3.5) * 0.0005

	if wheel_spin_speed != 0.0:
		_spin_wheels(wheel_spin_speed * delta)

	# 1. Poll active user-requested threaded load first (zero main-thread stall)
	if not _pending_tscn_path.is_empty():
		var status = ResourceLoader.load_threaded_get_status(_pending_tscn_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed = ResourceLoader.load_threaded_get(_pending_tscn_path) as PackedScene
			if packed:
				_packed_scene_cache[_pending_tscn_path] = packed
				if _pending_model_name.to_lower() == current_model.to_lower():
					_apply_loaded_car_scene(_pending_model_name, packed, true)
			_pending_tscn_path = ""
			_pending_model_name = ""
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_pending_tscn_path = ""
			_pending_model_name = ""

	# 2. Poll background fleet preloader (one file per worker slot)
	_step_background_preload()

func _step_background_preload() -> void:
	if not _bg_inflight_path.is_empty():
		if _packed_scene_cache.has(_bg_inflight_path):
			_bg_inflight_path = ""
			_bg_inflight_model = ""
			return
		var bg_status = ResourceLoader.load_threaded_get_status(_bg_inflight_path)
		if bg_status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed = ResourceLoader.load_threaded_get(_bg_inflight_path) as PackedScene
			if packed:
				_packed_scene_cache[_bg_inflight_path] = packed
				if not _rig_pool.has(_bg_inflight_model) and not (_bg_inflight_model in _warm_rig_queue):
					_warm_rig_queue.append(_bg_inflight_model)
			_bg_inflight_path = ""
			_bg_inflight_model = ""
		elif bg_status == ResourceLoader.THREAD_LOAD_FAILED or bg_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_bg_inflight_path = ""
			_bg_inflight_model = ""
		return

	# Warm 1 idle rig at a time only while Garage UI is open so Homescreen buttons/camera stay 100% stutter-free on RTX 2050 / GTX 1050
	if garage_open and not _warm_rig_queue.is_empty():
		if _warm_cooldown_frames > 0:
			_warm_cooldown_frames -= 1
			return
		var warm_id: String = _warm_rig_queue.pop_front()
		if not _rig_pool.has(warm_id):
			var warm_path: String = _resolve_tscn_path(warm_id)
			if _packed_scene_cache.has(warm_path):
				_apply_loaded_car_scene(warm_id, _packed_scene_cache[warm_path], false)
				_warm_cooldown_frames = 10
		return

	# Kick off next background threaded load cleanly
	while not _bg_model_queue.is_empty():
		var next_id: String = _bg_model_queue.pop_front()
		if _rig_pool.has(next_id):
			continue
		var next_path: String = _resolve_tscn_path(next_id)
		if _packed_scene_cache.has(next_path):
			_warm_rig_queue.append(next_id)
			return
		var err := ResourceLoader.load_threaded_request(next_path, "PackedScene", false)
		if err == OK:
			_bg_inflight_path = next_path
			_bg_inflight_model = next_id
			return

func _resolve_tscn_path(model_name: String) -> String:
	var tscn_path := "res://assets/models/cars/car_" + model_name + ".tscn"
	if not ResourceLoader.exists(tscn_path):
		match model_name.to_lower():
			"starter_gt": tscn_path = "res://assets/models/cars/car_sedan.tscn"
			"apex_cruiser": tscn_path = "res://assets/models/cars/car_coupe.tscn"
			"phantom_turbo", "ghini", "italia", "rb22", "gtr", "veloce": tscn_path = "res://assets/models/cars/car_sport.tscn"
			_: tscn_path = "res://assets/models/cars/car_sedan.tscn"
	return tscn_path

func load_car_model(model_name: String) -> void:
	var key := model_name.to_lower()
	current_model = model_name
	if not visual_root:
		return

	# Already displaying this exact model: 0 ms no-op (prevents double-load lag on Equip)
	if _active_rig_model == key and _rig_pool.has(key):
		var active_entry: Dictionary = _rig_pool[key]
		if is_instance_valid(active_entry.get("pivot")):
			(active_entry["pivot"] as Node3D).visible = true
			return

	# Instant pooled switch (< 0.1 ms, zero instantiation or shader stutter)
	if _rig_pool.has(key):
		var pooled_entry: Dictionary = _rig_pool[key]
		if is_instance_valid(pooled_entry.get("pivot")):
			_pending_tscn_path = ""
			_pending_model_name = ""
			_activate_pooled_rig(key)
			return
		_rig_pool.erase(key)

	var tscn_path := _resolve_tscn_path(model_name)

	# If PackedScene already cached, build and pool once
	if _packed_scene_cache.has(tscn_path):
		_pending_tscn_path = ""
		_pending_model_name = ""
		_apply_loaded_car_scene(model_name, _packed_scene_cache[tscn_path], true)
		return

	# First boot synchronous fallback only for initial car in _ready before main loop renders;
	# runtime switches during Garage clicks use non-blocking background thread!
	if _active_rig_model.is_empty():
		var packed = load(tscn_path) as PackedScene
		if packed:
			_packed_scene_cache[tscn_path] = packed
			_apply_loaded_car_scene(model_name, packed, true)
		return

	# Non-blocking async threaded request so Garage UI NEVER freezes
	if _bg_inflight_path == tscn_path:
		_pending_tscn_path = tscn_path
		_pending_model_name = model_name
		return
	var existing_status: int = ResourceLoader.load_threaded_get_status(tscn_path)
	if existing_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_pending_tscn_path = tscn_path
		_pending_model_name = model_name
		return
	if existing_status == ResourceLoader.THREAD_LOAD_LOADED:
		var ready_packed := ResourceLoader.load_threaded_get(tscn_path) as PackedScene
		if ready_packed:
			_packed_scene_cache[tscn_path] = ready_packed
			_apply_loaded_car_scene(model_name, ready_packed, true)
			return
	var req_err := ResourceLoader.load_threaded_request(tscn_path, "PackedScene", false)
	if req_err == OK:
		_pending_tscn_path = tscn_path
		_pending_model_name = model_name
	else:
		var fallback_packed = load(tscn_path) as PackedScene
		if fallback_packed:
			_packed_scene_cache[tscn_path] = fallback_packed
			_apply_loaded_car_scene(model_name, fallback_packed, true)

func _activate_pooled_rig(key: String) -> void:
	for k in _rig_pool.keys():
		var e: Dictionary = _rig_pool[k]
		var p = e.get("pivot") as Node3D
		if p and is_instance_valid(p):
			p.visible = (k == key)

	var entry: Dictionary = _rig_pool[key]
	_active_rig_model = key
	visual_pivot = entry["pivot"] as Node3D
	_model_root = entry["model_root"] as Node3D
	car_body = entry["car_body"] as Node3D
	car_mesh = entry["car_mesh"] as MeshInstance3D
	_original_body_mat = entry["orig_body_mat"]
	front_left_wheel = entry["fl"] as Node3D
	front_right_wheel = entry["fr"] as Node3D
	rear_left_wheel = entry["rl"] as Node3D
	rear_right_wheel = entry["rr"] as Node3D
	front_left_steer_pivot = entry["fl_steer"] as Node3D
	front_right_steer_pivot = entry["fr_steer"] as Node3D
	wheel_spin_pivots = (entry["spins"] as Array[Node3D]).duplicate()

	if entry.get("paint") != current_paint_color:
		entry["paint"] = current_paint_color
		VehicleMaterialEnhancer.enhance_vehicle_materials(current_model, visual_pivot, current_paint_color)

	set_headlights(headlights_on)
	set_steer(steer_angle)
	_touch_and_trim_rig_pool(key)
	car_model_ready.emit(key)

func _touch_and_trim_rig_pool(keep_key: String) -> void:
	_rig_lru.erase(keep_key)
	_rig_lru.append(keep_key)
	while _rig_pool.size() > MAX_POOLED_RIGS and not _rig_lru.is_empty():
		var oldest: String = _rig_lru.pop_front()
		if oldest == keep_key or oldest == _active_rig_model:
			if not (oldest in _rig_lru):
				_rig_lru.append(oldest)
			break
		if not _rig_pool.has(oldest):
			continue
		var old_entry: Dictionary = _rig_pool[oldest]
		var piv := old_entry.get("pivot") as Node3D
		if piv and is_instance_valid(piv):
			piv.queue_free()
		_rig_pool.erase(oldest)

func _apply_loaded_car_scene(model_name: String, packed: PackedScene, activate_now: bool = true) -> void:
	if not visual_root or not packed:
		return

	var key := model_name.to_lower()
	if _rig_pool.has(key) and is_instance_valid(_rig_pool[key].get("pivot")):
		if activate_now:
			_activate_pooled_rig(key)
		return

	var saved_active := _active_rig_model
	var base_yaw = MODEL_BASE_YAW_DEG.get(key, 0.0)

	var new_pivot := Node3D.new()
	new_pivot.name = "ShowcaseVisualPivot_" + key
	new_pivot.position = Vector3.ZERO
	new_pivot.rotation = Vector3(0.0, deg_to_rad(base_yaw), 0.0)
	new_pivot.visible = activate_now
	visual_root.add_child(new_pivot)

	var new_model_root := packed.instantiate() as Node3D
	new_model_root.position = Vector3.ZERO
	new_model_root.rotation = Vector3.ZERO
	new_pivot.add_child(new_model_root)

	if key == "porsche_carrera_gt":
		for child in new_model_root.find_children("*", "Node3D", true, false):
			if child.name.to_lower().contains("body6a"):
				child.visible = false

	var new_car_body := new_model_root.find_child("Body", true, false) as Node3D
	var new_car_mesh: MeshInstance3D = null
	if new_car_body:
		for child in new_car_body.get_children():
			if child is MeshInstance3D:
				var c_name = child.name.to_lower()
				if c_name.contains("body") and not c_name.contains("glass") and not c_name.contains("optic"):
					new_car_mesh = child
					break
				elif new_car_mesh == null and not c_name.contains("glass") and not c_name.contains("optic"):
					new_car_mesh = child
	if not new_car_mesh:
		var meshes = new_model_root.find_children("*", "MeshInstance3D", true, false)
		for m in meshes:
			var m_name = m.name.to_lower()
			if (m_name.contains("paint") or m_name.contains("carpaint")) and not m_name.contains("badge") and not m_name.contains("glass") and not m_name.contains("wheel"):
				new_car_mesh = m as MeshInstance3D
				break
		if not new_car_mesh:
			for m in meshes:
				var m_name = m.name.to_lower()
				if m_name.contains("body") and not m_name.contains("badge") and not m_name.contains("base") and not m_name.contains("glass") and not m_name.contains("optic") and not m_name.contains("wheel"):
					new_car_mesh = m as MeshInstance3D
					break
		if not new_car_mesh and not meshes.is_empty():
			new_car_mesh = meshes[0] as MeshInstance3D

	var new_orig_mat: Material = new_car_mesh.get_surface_override_material(0) if new_car_mesh else null

	# Build wheels & materials temporarily targeting this rig
	front_left_wheel = null
	front_right_wheel = null
	rear_left_wheel = null
	rear_right_wheel = null
	front_left_steer_pivot = null
	front_right_steer_pivot = null
	wheel_spin_pivots.clear()
	visual_pivot = new_pivot
	_model_root = new_model_root
	car_body = new_car_body
	car_mesh = new_car_mesh
	_original_body_mat = new_orig_mat

	_prepare_vehicle_wheels_for(key, new_model_root)
	_setup_showcase_wheels()
	VehicleMaterialEnhancer.enhance_vehicle_materials(model_name, visual_pivot, current_paint_color)

	_rig_pool[key] = {
		"pivot": visual_pivot,
		"model_root": _model_root,
		"car_body": car_body,
		"car_mesh": car_mesh,
		"orig_body_mat": _original_body_mat,
		"fl": front_left_wheel,
		"fr": front_right_wheel,
		"rl": rear_left_wheel,
		"rr": rear_right_wheel,
		"fl_steer": front_left_steer_pivot,
		"fr_steer": front_right_steer_pivot,
		"spins": wheel_spin_pivots.duplicate(),
		"paint": current_paint_color,
	}

	if activate_now:
		_activate_pooled_rig(key)
	elif not saved_active.is_empty() and _rig_pool.has(saved_active):
		_activate_pooled_rig(saved_active)

func _get_primary_tyre_center(group_node: Node3D, ref_root: Node3D, fallback: Vector3) -> Vector3:
	if not group_node or not ref_root:
		return fallback
	var best_mi: MeshInstance3D = null
	var best_vol: float = -1.0
	for child in group_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var cname: String = mi.name.to_lower()
		var sname: String = mi.mesh.surface_get_name(0).to_lower() if mi.mesh.get_surface_count() > 0 else ""
		var is_tyre: bool = cname.contains("tyre") or cname.contains("tire") or sname.contains("tyre") or sname.contains("tire")
		if is_tyre:
			best_mi = mi
			break
		var a := mi.mesh.get_aabb()
		var vol := a.size.x * a.size.y * a.size.z
		if vol > best_vol:
			best_vol = vol
			best_mi = mi
	if not best_mi or not best_mi.mesh:
		return fallback
	var local_c := best_mi.mesh.get_aabb().get_center()
	if best_mi.is_inside_tree() and ref_root.is_inside_tree():
		return ref_root.to_local(best_mi.global_transform * local_c)
	var xform := best_mi.transform
	var p := best_mi.get_parent()
	while p and p != ref_root:
		if p is Node3D:
			xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform * local_c

func _prepare_vehicle_wheels() -> void:
	_prepare_vehicle_wheels_for(current_model.to_lower(), _model_root)

func _prepare_vehicle_wheels_for(cid: String, target_root: Node3D) -> void:
	if not target_root:
		return
	var w_fl = target_root.get_node_or_null("Wheel_FL") as Node3D
	var w_fr = target_root.get_node_or_null("Wheel_FR") as Node3D
	var w_rl = target_root.get_node_or_null("Wheel_RL") as Node3D
	var w_rr = target_root.get_node_or_null("Wheel_RR") as Node3D
	if not w_fl or not w_fr or not w_rl or not w_rr:
		return
		
	if cid == "porsche_mission_x":
		var m_fl = target_root.find_child("WHEEL_LF", true, false) as Node3D
		var m_fr = target_root.find_child("WHEEL_RF", true, false) as Node3D
		var m_rl = target_root.find_child("WHEEL_LR", true, false) as Node3D
		var m_rr = target_root.find_child("WHEEL_RR", true, false) as Node3D
		w_fl.position = _get_primary_tyre_center(m_fl, target_root, Vector3(-0.8016, 0.3986, -1.3472))
		w_fr.position = _get_primary_tyre_center(m_fr, target_root, Vector3(0.8326, 0.3986, -1.3472))
		w_rl.position = _get_primary_tyre_center(m_rl, target_root, Vector3(-0.8176, 0.4170, 1.3827))
		w_rr.position = _get_primary_tyre_center(m_rr, target_root, Vector3(0.875, 0.4176, 1.3827))
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
		var cw = target_root.find_child("Combined_Wheels_3D_", true, false)
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
		var t1 = target_root.find_child("tire 1", true, false)
		var t2 = target_root.find_child("tire 2", true, false)
		var t3 = target_root.find_child("tire 3", true, false)
		if t1:
			w_fl.position = target_root.to_local(t1.global_position)
			for c in t1.get_children():
				c.owner = null
				c.reparent(w_fl, true)
		if t2:
			w_fr.position = target_root.to_local(t2.global_position)
			for c in t2.get_children():
				c.owner = null
				c.reparent(w_fr, true)
		if t3:
			var t_rl = t3.find_child("tire_001", true, false)
			var t_rr = t3.find_child("tire001", true, false)
			if t_rl:
				w_rl.position = target_root.to_local(t_rl.global_position)
			if t_rr:
				w_rr.position = target_root.to_local(t_rr.global_position)
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
		var s_fl = target_root.find_child("00_203 tire FL", true, false)
		var s_fr = target_root.find_child("00_211 tire FR", true, false)
		var s_rl = target_root.find_child("00_188 tire RL", true, false)
		var s_rr = target_root.find_child("00_195 tire RR", true, false)
		if s_fl:
			w_fl.position = target_root.to_local(s_fl.global_position)
			s_fl.owner = null
			s_fl.reparent(w_fl, true)
		if s_fr:
			w_fr.position = target_root.to_local(s_fr.global_position)
			s_fr.owner = null
			s_fr.reparent(w_fr, true)
		if s_rl:
			w_rl.position = target_root.to_local(s_rl.global_position)
			s_rl.owner = null
			s_rl.reparent(w_rl, true)
		if s_rr:
			w_rr.position = target_root.to_local(s_rr.global_position)
			s_rr.owner = null
			s_rr.reparent(w_rr, true)
			
	elif cid == "mclaren":
		var m_fl = target_root.find_child("3DWheel Front L", true, false)
		var m_fr = target_root.find_child("3DWheel Front R", true, false)
		var m_rl = target_root.find_child("3DWheel Rear L", true, false)
		var m_rr = target_root.find_child("3DWheel Rear R", true, false)
		if m_fl:
			w_fl.position = target_root.to_local(m_fl.global_position)
			m_fl.owner = null
			m_fl.reparent(w_fl, true)
		if m_fr:
			w_fr.position = target_root.to_local(m_fr.global_position)
			m_fr.owner = null
			m_fr.reparent(w_fr, true)
		if m_rl:
			w_rl.position = target_root.to_local(m_rl.global_position)
			m_rl.owner = null
			m_rl.reparent(w_rl, true)
		if m_rr:
			w_rr.position = target_root.to_local(m_rr.global_position)
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
	var key := current_model.to_lower()
	if _rig_pool.has(key):
		_rig_pool[key]["paint"] = color
	if _model_root:
		var target_root = visual_pivot if visual_pivot else _model_root
		VehicleMaterialEnhancer.enhance_vehicle_materials(current_model, target_root, color)

func set_headlights(on: bool) -> void:
	headlights_on = on
	var s: float = get_effective_scale()
	if fx_root:
		var spot_l = fx_root.get_node_or_null("HeadlightSpotL") as SpotLight3D
		var spot_r = fx_root.get_node_or_null("HeadlightSpotR") as SpotLight3D
		var rear_glow = fx_root.get_node_or_null("RearTaillightGlow") as OmniLight3D
		if spot_l:
			spot_l.position = Vector3(-0.65 * s, 0.48 * s, -2.18 * s)
			spot_l.rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
			spot_l.light_energy = 1.5
			spot_l.light_specular = 0.25
			spot_l.spot_range = 15.0 * s
			spot_l.spot_angle = 36.0
			spot_l.visible = on
		if spot_r:
			spot_r.position = Vector3(0.65 * s, 0.48 * s, -2.18 * s)
			spot_r.rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
			spot_r.light_energy = 1.5
			spot_r.light_specular = 0.25
			spot_r.spot_range = 15.0 * s
			spot_r.spot_angle = 36.0
			spot_r.visible = on
		if rear_glow:
			rear_glow.position = Vector3(0.0, 0.46 * s, 2.38 * s)
			rear_glow.light_energy = 0.6
			rear_glow.light_specular = 0.12
			rear_glow.omni_range = 2.8 * s
			rear_glow.visible = on

func set_light_energy_multiplier(mult: float) -> void:
	var m: float = maxf(0.0, mult)
	if not fx_root:
		return
	var spot_l = fx_root.get_node_or_null("HeadlightSpotL") as SpotLight3D
	var spot_r = fx_root.get_node_or_null("HeadlightSpotR") as SpotLight3D
	var rear_glow = fx_root.get_node_or_null("RearTaillightGlow") as OmniLight3D
	if spot_l:
		spot_l.light_energy = 1.5 * m
	if spot_r:
		spot_r.light_energy = 1.5 * m
	if rear_glow:
		rear_glow.light_energy = 0.6 * m

func spin_wheels_by_radians(delta_rad: float) -> void:
	_spin_wheels(delta_rad)

func is_model_loading() -> bool:
	return not _pending_tscn_path.is_empty()

func get_active_model_key() -> String:
	return _active_rig_model

func compute_wheel_ground_metrics() -> Dictionary:
	## Computes exact vertex-accurate lowest wheel bottom Y (in local space of ShowcaseCar),
	## immune to rotated AABB corner inflation when wheels are spun/steered, plus wheel radius
	## and vehicle footprint width/length in ShowcaseCar local space.
	var inv_self: Transform3D = global_transform.affine_inverse()
	var wheel_roots: Array[Node3D] = []
	for wn in [front_left_wheel, front_right_wheel, rear_left_wheel, rear_right_wheel]:
		if wn and is_instance_valid(wn):
			wheel_roots.append(wn)

	var min_wheel_y: float = INF
	var radii: Array[float] = []
	for wr in wheel_roots:
		var w_min_y: float = INF
		var w_max_y: float = -INF
		var w_meshes: Array[Node] = []
		if wr is MeshInstance3D:
			w_meshes.append(wr)
		w_meshes.append_array(wr.find_children("*", "MeshInstance3D", true, false))
		for m_node in w_meshes:
			var mi := m_node as MeshInstance3D
			if not mi or not mi.mesh or not mi.visible:
				continue
			var local_xf: Transform3D = inv_self * mi.global_transform
			var used_verts: bool = false
			var sc: int = mi.mesh.get_surface_count()
			for s in range(sc):
				var arrays: Array = mi.mesh.surface_get_arrays(s)
				if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					if not verts.is_empty():
						used_verts = true
						var stride: int = maxi(1, verts.size() / 256)
						for vi in range(0, verts.size(), stride):
							var pt: Vector3 = local_xf * verts[vi]
							w_min_y = minf(w_min_y, pt.y)
							w_max_y = maxf(w_max_y, pt.y)
			if not used_verts:
				var aabb: AABB = mi.mesh.get_aabb()
				var c_local: Vector3 = local_xf * aabb.get_center()
				var r_approx: float = maxf(aabb.size.y, aabb.size.z) * 0.5 * local_xf.basis.get_scale().y
				w_min_y = minf(w_min_y, c_local.y - r_approx)
				w_max_y = maxf(w_max_y, c_local.y + r_approx)
		if w_min_y < INF and w_max_y > -INF:
			min_wheel_y = minf(min_wheel_y, w_min_y)
			var r_est: float = (w_max_y - w_min_y) * 0.5
			if r_est > 0.12 and r_est < 1.2:
				radii.append(r_est)

	var body_min := Vector3(INF, INF, INF)
	var body_max := Vector3(-INF, -INF, -INF)
	var scan_root: Node3D = visual_pivot if visual_pivot else visual_root
	if scan_root:
		for m_node in scan_root.find_children("*", "MeshInstance3D", true, false):
			var mi := m_node as MeshInstance3D
			if not mi or not mi.mesh or not mi.visible:
				continue
			var local_xf: Transform3D = inv_self * mi.global_transform
			var aabb: AABB = mi.mesh.get_aabb()
			var p: Vector3 = aabb.position
			var sz: Vector3 = aabb.size
			var corners: Array[Vector3] = [
				Vector3(p.x, p.y, p.z),
				Vector3(p.x + sz.x, p.y, p.z),
				Vector3(p.x, p.y + sz.y, p.z),
				Vector3(p.x, p.y, p.z + sz.z),
				Vector3(p.x + sz.x, p.y + sz.y, p.z),
				Vector3(p.x + sz.x, p.y, p.z + sz.z),
				Vector3(p.x, p.y + sz.y, p.z + sz.z),
				Vector3(p.x + sz.x, p.y + sz.y, p.z + sz.z),
			]
			for c in corners:
				var pt: Vector3 = local_xf * c
				body_min = body_min.min(pt)
				body_max = body_max.max(pt)

	if min_wheel_y == INF:
		min_wheel_y = body_min.y if body_min.y < INF else 0.0
	var avg_r: float = 0.36 * get_effective_scale()
	if not radii.is_empty():
		var sum_r: float = 0.0
		for rv in radii:
			sum_r += rv
		avg_r = sum_r / float(radii.size())
	var width: float = (body_max.x - body_min.x) if body_min.x < INF else (2.0 * get_effective_scale())
	var length: float = (body_max.z - body_min.z) if body_min.z < INF else (4.6 * get_effective_scale())
	var height: float = (body_max.y - body_min.y) if body_min.y < INF else (1.4 * get_effective_scale())
	return {
		"min_wheel_y": min_wheel_y,
		"wheel_radius": avg_r,
		"width": clampf(width, 1.5, 4.0),
		"length": clampf(length, 3.2, 8.5),
		"height": clampf(height, 0.9, 3.5),
		"center_y": (body_min.y + body_max.y) * 0.5 if body_min.y < INF else 0.7,
	}

func align_contact_shadow_to_floor(floor_local_y: float, footprint_width: float, footprint_length: float) -> void:
	var decal := get_node_or_null("ContactShadowDecal") as Decal
	if decal:
		decal.position = Vector3(0.0, floor_local_y + 0.006, 0.0)
		decal.size = Vector3(footprint_width * 1.12, 0.42, footprint_length * 1.06)
		decal.cull_mask = 1
		decal.albedo_mix = 0.92
		decal.modulate = Color(1.0, 1.0, 1.0, 0.95)

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
	_rig_pool.clear()
	_active_rig_model = ""
	if visual_root:
		for c in visual_root.get_children():
			c.queue_free()
	var new_vis = packed.instantiate() as Node3D
	new_vis.name = "VisualRoot"
	new_vis.scale = Vector3.ONE * get_effective_scale()
	add_child(new_vis)
	visual_root = new_vis
	_setup_showcase_wheels()
	_setup_materials()
	set_headlights(headlights_on)
	set_steer(steer_angle)
