class_name VehicleVisualAdapter
extends Node3D

const VehicleMaterialEnhancer = preload("res://vehicles/core/VehicleMaterialEnhancer.gd")

# Non-intrusive Visual Adapter for 3D Vehicle Assets.
# Mounts and wraps any vehicle model scene into runtime dual-pivot wheel rigs
# and body dynamic pivots without altering original .glb/.tscn source assets.

var config: VehicleConfig

var visual_root: Node3D
var visual_instance: Node3D
var body_pivot: Node3D
var body_node: Node3D

# Wheel rig references for each wheel index: 0=FL, 1=FR, 2=RL, 3=RR
var wheel_hubs: Array[Node3D] = [null, null, null, null]
var steer_pivots: Array[Node3D] = [null, null, null, null]
var spin_pivots: Array[Node3D] = [null, null, null, null]
var wheel_meshes: Array[Node3D] = [null, null, null, null]
var wheel_rest_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]

# Current visual dynamic state
var current_wheel_spins: Array[float] = [0.0, 0.0, 0.0, 0.0]
var in_situ_wheels: Array[Node3D] = [null, null, null, null]
var in_situ_initial_bases: Array[Basis] = [Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY]
var in_situ_initial_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var in_situ_rel_bases: Array[Basis] = [Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY]
var in_situ_parent_centers: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var in_situ_node_centers: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]

func setup(p_config: VehicleConfig) -> bool:
	config = p_config
	cleanup()
	
	if not config or config.visual_scene_path.strip_edges().is_empty():
		push_error("VehicleVisualAdapter: Invalid vehicle config or empty visual_scene_path.")
		return false
		
	var packed = load(config.visual_scene_path) as PackedScene
	if not packed:
		push_error("VehicleVisualAdapter: Failed to load visual scene: " + config.visual_scene_path)
		return false
		
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	visual_root.position = config.visual_offset
	visual_root.scale = config.visual_scale
	visual_root.rotation = Vector3(0.0, deg_to_rad(config.visual_yaw_offset_deg), 0.0)
	
	body_pivot = Node3D.new()
	body_pivot.name = "BodyPivot"
	visual_root.add_child(body_pivot)
	body_pivot.position = Vector3.ZERO
	body_pivot.rotation = Vector3.ZERO
	
	visual_instance = packed.instantiate() as Node3D
	visual_instance.name = "ModelInstance"
	body_pivot.add_child(visual_instance)
	visual_instance.position = Vector3.ZERO
	visual_instance.rotation = Vector3.ZERO
	
	if config and config.id.to_lower() == "porsche_carrera_gt":
		for child in visual_instance.find_children("*", "Node3D", true, false):
			if child.name.to_lower().contains("body6a"):
				child.visible = false
	
	_locate_body_node()
	_prepare_vehicle_wheels()
	_setup_wheel_rigs()
	_calibrate_visual_ride_height()
	_apply_enhanced_materials()
	
	return true

func cleanup() -> void:
	for i in range(4):
		wheel_hubs[i] = null
		steer_pivots[i] = null
		spin_pivots[i] = null
		wheel_meshes[i] = null
		in_situ_wheels[i] = null
		in_situ_initial_bases[i] = Basis.IDENTITY
		in_situ_initial_positions[i] = Vector3.ZERO
		in_situ_rel_bases[i] = Basis.IDENTITY
		wheel_rest_positions[i] = Vector3.ZERO
		current_wheel_spins[i] = 0.0
	body_pivot = null
	body_node = null
	visual_instance = null
	
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
		visual_root = null

# Updates wheel visual position glued to ground contact point with zero floating gap
func update_wheel_visual(wheel_idx: int, is_grounded: bool, contact_point: Vector3, contact_normal: Vector3, steer_angle: float, spin_step: float) -> void:
	if wheel_idx < 0 or wheel_idx >= 4 or not wheel_hubs[wheel_idx]:
		return
	var hub = wheel_hubs[wheel_idx]
	var rest_pos = wheel_rest_positions[wheel_idx]
	if is_grounded and visual_root and visual_root.is_inside_tree():
		var target_world_pos = contact_point + contact_normal * config.wheel_radius
		var local_target = visual_root.to_local(target_world_pos)
		
		# Realistic suspension bump-stop limit:
		# Prevents wheel from penetrating upward through fender arch during heavy compression, bumps, or gravity shock
		var max_upward = config.suspension_travel * 0.25
		if config and config.id.to_lower() == "porsche_mission_x":
			max_upward = 0.012
		var max_y = rest_pos.y + max_upward
		var min_y = rest_pos.y - config.suspension_travel
		var clamped_y = clampf(local_target.y, min_y, max_y)
		hub.position = Vector3(rest_pos.x, clamped_y, rest_pos.z)
	else:
		hub.position = rest_pos + Vector3(0.0, -config.suspension_travel, 0.0)
		
	current_wheel_spins[wheel_idx] = wrapf(current_wheel_spins[wheel_idx] + spin_step, -PI, PI)
	
	if steer_pivots[wheel_idx]:
		steer_pivots[wheel_idx].rotation.y = steer_angle
	if spin_pivots[wheel_idx]:
		spin_pivots[wheel_idx].rotation.x = current_wheel_spins[wheel_idx]
		
	# In-situ wheels embedded in model hierarchy
	var in_situ = in_situ_wheels[wheel_idx]
	if in_situ and is_instance_valid(in_situ):
		var st_ang = steer_angle if wheel_idx < 2 else 0.0
		var R_steer = Basis(Vector3.UP, st_ang)
		var steered_axle = R_steer * Vector3.RIGHT
		var R_spin = Basis(steered_axle, current_wheel_spins[wheel_idx])
		var R_net = R_spin * R_steer
		var b_rel = in_situ_rel_bases[wheel_idx]
		var R_local = b_rel.inverse() * R_net * b_rel
		var new_basis = in_situ_initial_bases[wheel_idx] * R_local
		in_situ.transform.basis = new_basis
		var C_par = in_situ_parent_centers[wheel_idx]
		var C_nod = in_situ_node_centers[wheel_idx]
		in_situ.transform.origin = C_par - new_basis * C_nod

# Backward compatibility wrappers
func set_wheel_suspension_offset(wheel_idx: int, compression_displacement: float) -> void:
	if wheel_idx >= 0 and wheel_idx < 4 and wheel_hubs[wheel_idx]:
		var rest_pos = wheel_rest_positions[wheel_idx]
		wheel_hubs[wheel_idx].position = rest_pos + Vector3(0.0, compression_displacement, 0.0)

func set_wheel_steer_angle(wheel_idx: int, steer_angle_rad: float) -> void:
	if wheel_idx >= 0 and wheel_idx < 4 and steer_pivots[wheel_idx]:
		steer_pivots[wheel_idx].rotation.y = steer_angle_rad

func add_wheel_spin(wheel_idx: int, delta_spin_rad: float) -> void:
	if wheel_idx >= 0 and wheel_idx < 4 and spin_pivots[wheel_idx]:
		current_wheel_spins[wheel_idx] = wrapf(current_wheel_spins[wheel_idx] + delta_spin_rad, -PI, PI)
		spin_pivots[wheel_idx].rotation.x = current_wheel_spins[wheel_idx]

# Updates chassis body roll, pitch, and heave generated by physics forces
func set_chassis_lean(pitch_rad: float, roll_rad: float, heave_m: float) -> void:
	if body_pivot:
		body_pivot.rotation = Vector3(pitch_rad, 0.0, roll_rad)
		var clamped_heave = heave_m
		if config:
			var max_squat = minf(config.suspension_travel * 0.15, 0.012)
			clamped_heave = clampf(heave_m, -max_squat, 0.01)
		body_pivot.position = Vector3(0.0, clamped_heave, 0.0)

func _calibrate_visual_ride_height() -> void:
	if not visual_root or not config:
		return
	var k_total = (config.spring_stiffness_front + config.spring_stiffness_rear) * 2.0
	var eq_compression = (config.mass * 9.8) / maxf(k_total, 1000.0)
	var eq_susp_len = config.suspension_rest_length - eq_compression
	var mount_y = config.suspension_rest_length * 0.5
	var local_wheel_center_y = mount_y - eq_susp_len
	
	var avg_model_wheel_y = 0.0
	var valid_wheels = 0
	for i in range(4):
		if wheel_rest_positions[i] != Vector3.ZERO:
			avg_model_wheel_y += wheel_rest_positions[i].y
			valid_wheels += 1
	if valid_wheels > 0:
		avg_model_wheel_y /= float(valid_wheels)
	else:
		avg_model_wheel_y = config.wheel_radius
		
	var visual_y_offset = local_wheel_center_y - avg_model_wheel_y
	visual_root.position = config.visual_offset + Vector3(0.0, visual_y_offset, 0.0)

func _locate_body_node() -> void:
	if not visual_instance:
		return
		
	if not config.body_node_path.strip_edges().is_empty():
		body_node = visual_instance.get_node_or_null(config.body_node_path) as Node3D
	if not body_node:
		body_node = visual_instance.find_child("Body", true, false) as Node3D
	if not body_node:
		var body_names = ["body", "chassis", "carbody", "hull", "frame"]
		var stack: Array[Node] = [visual_instance]
		while stack.size() > 0:
			var curr = stack.pop_back()
			if curr != visual_instance and curr is Node3D:
				var l_name = curr.name.to_lower().replace("-", "_")
				for b_name in body_names:
					if l_name == b_name or l_name.begins_with(b_name + "_") or l_name.ends_with("_" + b_name):
						body_node = curr as Node3D
						break
			if body_node:
				break
			for c in curr.get_children():
				stack.push_back(c)

func _prepare_vehicle_wheels() -> void:
	if not visual_instance or not config:
		return
	var cid = config.id.to_lower()
	var w_fl = visual_instance.get_node_or_null("Wheel_FL") as Node3D
	var w_fr = visual_instance.get_node_or_null("Wheel_FR") as Node3D
	var w_rl = visual_instance.get_node_or_null("Wheel_RL") as Node3D
	var w_rr = visual_instance.get_node_or_null("Wheel_RR") as Node3D
	if not w_fl or not w_fr or not w_rl or not w_rr:
		return
		
	if cid == "porsche_mission_x":
		var m_fl = visual_instance.find_child("WHEEL_LF", true, false)
		var m_fr = visual_instance.find_child("WHEEL_RF", true, false)
		var m_rl = visual_instance.find_child("WHEEL_LR", true, false)
		var m_rr = visual_instance.find_child("WHEEL_RR", true, false)
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
		var cw = visual_instance.find_child("Combined_Wheels_3D_", true, false)
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
		var t1 = visual_instance.find_child("tire 1", true, false)
		var t2 = visual_instance.find_child("tire 2", true, false)
		var t3 = visual_instance.find_child("tire 3", true, false)
		if t1:
			w_fl.position = visual_instance.to_local(t1.global_position)
			for c in t1.get_children():
				c.owner = null
				c.reparent(w_fl, true)
		if t2:
			w_fr.position = visual_instance.to_local(t2.global_position)
			for c in t2.get_children():
				c.owner = null
				c.reparent(w_fr, true)
		if t3:
			var t_rl = t3.find_child("tire_001", true, false)
			var t_rr = t3.find_child("tire001", true, false)
			if t_rl:
				w_rl.position = visual_instance.to_local(t_rl.global_position)
			if t_rr:
				w_rr.position = visual_instance.to_local(t_rr.global_position)
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
		var s_fl = visual_instance.find_child("00_203 tire FL", true, false)
		var s_fr = visual_instance.find_child("00_211 tire FR", true, false)
		var s_rl = visual_instance.find_child("00_188 tire RL", true, false)
		var s_rr = visual_instance.find_child("00_195 tire RR", true, false)
		if s_fl:
			w_fl.position = visual_instance.to_local(s_fl.global_position)
			s_fl.owner = null
			s_fl.reparent(w_fl, true)
		if s_fr:
			w_fr.position = visual_instance.to_local(s_fr.global_position)
			s_fr.owner = null
			s_fr.reparent(w_fr, true)
		if s_rl:
			w_rl.position = visual_instance.to_local(s_rl.global_position)
			s_rl.owner = null
			s_rl.reparent(w_rl, true)
		if s_rr:
			w_rr.position = visual_instance.to_local(s_rr.global_position)
			s_rr.owner = null
			s_rr.reparent(w_rr, true)
			
	elif cid == "mclaren":
		var m_fl = visual_instance.find_child("3DWheel Front L", true, false)
		var m_fr = visual_instance.find_child("3DWheel Front R", true, false)
		var m_rl = visual_instance.find_child("3DWheel Rear L", true, false)
		var m_rr = visual_instance.find_child("3DWheel Rear R", true, false)
		if m_fl:
			w_fl.position = visual_instance.to_local(m_fl.global_position)
			m_fl.owner = null
			m_fl.reparent(w_fl, true)
		if m_fr:
			w_fr.position = visual_instance.to_local(m_fr.global_position)
			m_fr.owner = null
			m_fr.reparent(w_fr, true)
		if m_rl:
			w_rl.position = visual_instance.to_local(m_rl.global_position)
			m_rl.owner = null
			m_rl.reparent(w_rl, true)
		if m_rr:
			w_rr.position = visual_instance.to_local(m_rr.global_position)
			m_rr.owner = null
			m_rr.reparent(w_rr, true)

func _setup_wheel_rigs() -> void:
	var wheel_tags = ["FL", "FR", "RL", "RR"]
	var wheel_paths = [
		config.fl_wheel_node_path,
		config.fr_wheel_node_path,
		config.rl_wheel_node_path,
		config.rr_wheel_node_path
	]
	
	var car_id = config.id.to_lower() if config else ""
	
	for i in range(4):
		var tag = wheel_tags[i]
		var w_node: Node3D = null
		
		# 1. Check configured path
		if not wheel_paths[i].strip_edges().is_empty():
			var cand = visual_instance.get_node_or_null(wheel_paths[i]) as Node3D
			if cand and _count_mesh_instances(cand) > 0:
				w_node = cand
		# 2. Check scene node Wheel_TAG if it has actual geometry
		if not w_node:
			var cand = visual_instance.find_child("Wheel_" + tag, true, false) as Node3D
			if cand and _count_mesh_instances(cand) > 0:
				w_node = cand
		# 3. Check by tag in name
		if not w_node:
			var cand = _find_wheel_by_tag(visual_instance, tag)
			if cand and _count_mesh_instances(cand) > 0:
				w_node = cand
		# 4. Fallback: resolve from complex imported hierarchy
		if not w_node:
			w_node = _resolve_fallback_wheel(visual_instance, car_id, tag.to_lower())
			
		if not w_node:
			continue
			
		wheel_meshes[i] = w_node
		
		# Compute geometric center in visual_root space
		var orig_pos = w_node.position if w_node.get_parent() == visual_instance else _get_wheel_center_local(w_node)
		wheel_rest_positions[i] = orig_pos
		
		# 1. WheelHub placed as child of visual_root
		var hub = Node3D.new()
		hub.name = "WheelHub_" + tag
		visual_root.add_child(hub)
		hub.position = orig_pos
		hub.rotation = Vector3.ZERO
		wheel_hubs[i] = hub
		
		# 2. SteerPivot placed as child of WheelHub
		var steer_pivot = Node3D.new()
		steer_pivot.name = "SteerPivot_" + tag
		hub.add_child(steer_pivot)
		steer_pivot.position = Vector3.ZERO
		steer_pivot.rotation = Vector3.ZERO
		steer_pivots[i] = steer_pivot
		
		# 3. SpinPivot placed as child of SteerPivot
		var spin_pivot = Node3D.new()
		spin_pivot.name = "SpinPivot_" + tag
		steer_pivot.add_child(spin_pivot)
		spin_pivot.position = Vector3.ZERO
		spin_pivot.rotation = Vector3.ZERO
		spin_pivots[i] = spin_pivot
		
		# 4. Rigging: reparent direct root wheels or retain in-situ for complex model hierarchies
		if w_node.get_parent() == visual_instance:
			var orig_basis = w_node.transform.basis
			w_node.owner = null
			var wp = w_node.get_parent()
			if wp:
				wp.remove_child(w_node)
			spin_pivot.add_child(w_node)
			w_node.position = Vector3.ZERO
			w_node.transform.basis = orig_basis
		else:
			in_situ_wheels[i] = w_node
			in_situ_initial_bases[i] = w_node.transform.basis
			in_situ_initial_positions[i] = w_node.transform.origin
			in_situ_rel_bases[i] = _get_relative_basis(w_node, visual_root)
			var p_parent = w_node.get_parent() as Node3D
			if p_parent and visual_root:
				var world_center = visual_root.to_global(orig_pos)
				in_situ_parent_centers[i] = p_parent.to_local(world_center)
				in_situ_node_centers[i] = w_node.to_local(world_center)
			else:
				in_situ_parent_centers[i] = w_node.transform.origin
				in_situ_node_centers[i] = Vector3.ZERO

func _get_relative_basis(node: Node3D, root_node: Node3D) -> Basis:
	if not node or not root_node:
		return Basis.IDENTITY
	if node.is_inside_tree() and root_node.is_inside_tree():
		return root_node.global_transform.basis.inverse() * node.global_transform.basis
	var b = Basis.IDENTITY
	var curr = node
	while curr and curr != root_node:
		b = curr.transform.basis * b
		curr = curr.get_parent() as Node3D
	return b

func _count_mesh_instances(node: Node) -> int:
	if not node:
		return 0
	var count = 1 if node is MeshInstance3D else 0
	return count + node.find_children("*", "MeshInstance3D", true, false).size()

func _get_wheel_center_local(node: Node3D) -> Vector3:
	if not node or not visual_root:
		return Vector3.ZERO
	var aabb = AABB()
	var first = true
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	var in_tree = node.is_inside_tree() and visual_root.is_inside_tree()
	for m in meshes:
		if m.mesh:
			var m_aabb = m.mesh.get_aabb()
			var c = (m.global_transform * m_aabb.get_center()) if in_tree else (m.transform * m_aabb.get_center())
			if first:
				aabb.position = c
				first = false
			else:
				aabb = aabb.expand(c)
	if first:
		return visual_root.to_local(node.global_position) if in_tree else node.position
	return visual_root.to_local(aabb.get_center()) if in_tree else aabb.get_center()

func _resolve_fallback_wheel(root_inst: Node3D, cid: String, tag: String) -> Node3D:
	if cid == "porsche_mission_x":
		match tag:
			"fl": return root_inst.find_child("WHEEL_LF", true, false)
			"fr": return root_inst.find_child("WHEEL_RF", true, false)
			"rl": return root_inst.find_child("WHEEL_LR", true, false)
			"rr": return root_inst.find_child("WHEEL_RR", true, false)
	elif cid == "mclaren":
		match tag:
			"fl": return root_inst.find_child("3DWheel Front L", true, false)
			"fr": return root_inst.find_child("3DWheel Front R", true, false)
			"rl": return root_inst.find_child("3DWheel Rear L", true, false)
			"rr": return root_inst.find_child("3DWheel Rear R", true, false)
	elif cid == "kia_seltos":
		match tag:
			"fl": return root_inst.find_child("00_203 tire FL", true, false)
			"fr": return root_inst.find_child("00_211 tire FR", true, false)
			"rl": return root_inst.find_child("00_188 tire RL", true, false)
			"rr": return root_inst.find_child("00_195 tire RR", true, false)
	elif cid == "kia_carnival":
		var t3 = root_inst.find_child("tire 3", true, false)
		if t3:
			var rl_cont = t3.get_node_or_null("Carnival_Wheel_RL") as Node3D
			var rr_cont = t3.get_node_or_null("Carnival_Wheel_RR") as Node3D
			if not rl_cont:
				var t_rl = t3.find_child("tire_001", true, false)
				if t_rl:
					rl_cont = Node3D.new()
					rl_cont.name = "Carnival_Wheel_RL"
					rl_cont.position = t_rl.position
					t3.add_child(rl_cont)
					var rl_mesh_names = ["tire_001", "GSMBiDim_108423", "brake_pad_003", "brake_003"]
					for nm in rl_mesh_names:
						var part = t3.find_child(nm, true, false)
						if part:
							part.owner = null
							part.reparent(rl_cont, true)
			if not rr_cont:
				var t_rr = t3.find_child("tire001", true, false)
				if t_rr:
					rr_cont = Node3D.new()
					rr_cont.name = "Carnival_Wheel_RR"
					rr_cont.position = t_rr.position
					t3.add_child(rr_cont)
					var rr_mesh_names = ["tire001", "GSMBiDim_108425"]
					for nm in rr_mesh_names:
						var part = t3.find_child(nm, true, false)
						if part:
							part.owner = null
							part.reparent(rr_cont, true)
			match tag:
				"fl": return root_inst.find_child("tire 1", true, false)
				"fr": return root_inst.find_child("tire 2", true, false)
				"rl": return rl_cont
				"rr": return rr_cont
	elif cid == "porsche_carrera_gt":
		var cw = root_inst.find_child("Combined_Wheels_3D_", true, false)
		if cw:
			var container_name = "Porsche_Wheel_" + tag.to_upper()
			var existing = cw.get_node_or_null(container_name) as Node3D
			if existing:
				return existing
			var fl_node = Node3D.new()
			fl_node.name = "Porsche_Wheel_FL"
			fl_node.position = Vector3(0.008, 0.00326, 0.01369)
			var fr_node = Node3D.new()
			fr_node.name = "Porsche_Wheel_FR"
			fr_node.position = Vector3(-0.008, 0.00326, 0.01369)
			var rl_node = Node3D.new()
			rl_node.name = "Porsche_Wheel_RL"
			rl_node.position = Vector3(0.00774, 0.00345, -0.01363)
			var rr_node = Node3D.new()
			rr_node.name = "Porsche_Wheel_RR"
			rr_node.position = Vector3(-0.00774, 0.00345, -0.01363)
			cw.add_child(fl_node)
			cw.add_child(fr_node)
			cw.add_child(rl_node)
			cw.add_child(rr_node)
			for m in cw.find_children("*", "MeshInstance3D", true, false):
				if m.mesh:
					var c = m.position
					m.owner = null
					if c.z >= 0 and c.x >= 0:
						m.reparent(fl_node, false)
						m.position = Vector3.ZERO
					elif c.z >= 0 and c.x < 0:
						m.reparent(fr_node, false)
						m.position = Vector3.ZERO
					elif c.z < 0 and c.x >= 0:
						m.reparent(rl_node, false)
						m.position = Vector3.ZERO
					elif c.z < 0 and c.x < 0:
						m.reparent(rr_node, false)
						m.position = Vector3.ZERO
			match tag:
				"fl": return fl_node
				"fr": return fr_node
				"rl": return rl_node
				"rr": return rr_node
	return null

func _find_wheel_by_tag(root_node: Node3D, tag: String) -> Node3D:
	var target = tag.to_lower()
	var stack: Array[Node] = [root_node]
	while stack.size() > 0:
		var curr = stack.pop_back()
		if curr != root_node and curr is Node3D:
			var nm = curr.name.to_lower()
			if nm.contains("wheel") and nm.contains(target):
				return curr as Node3D
		for c in curr.get_children():
			stack.push_back(c)
	return null

func _apply_enhanced_materials() -> void:
	if not visual_instance or not config:
		return
	var p_col = Color.WHITE
	if is_inside_tree() and has_node("/root/PlayerProfile"):
		var prof = get_node("/root/PlayerProfile")
		if prof.data and prof.data.get("custom_paint_color"):
			p_col = prof.data.custom_paint_color
	VehicleMaterialEnhancer.enhance_vehicle_materials(config.id, visual_root if visual_root else visual_instance, p_col)
