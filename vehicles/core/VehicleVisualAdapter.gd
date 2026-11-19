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
var wheel_spin_axes: Array[Vector3] = [Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT]
var wheel_visual_radii: Array[float] = [0.35, 0.35, 0.35, 0.35]

# Current visual dynamic state
var current_wheel_spins: Array[float] = [0.0, 0.0, 0.0, 0.0]
var wheel_angular_velocities: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _render_spin_driven: bool = false
var in_situ_wheels: Array[Node3D] = [null, null, null, null]
var in_situ_initial_bases: Array[Basis] = [Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY]
var in_situ_initial_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var in_situ_rel_bases: Array[Basis] = [Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY, Basis.IDENTITY]
var in_situ_parent_centers: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var in_situ_node_centers: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _measured_body_min_y: float = -0.30
var _visual_ground_clearance_offset: float = 0.0

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
	_calibrate_all_wheel_axes()
	_calibrate_visual_ride_height()
	_measure_body_floor_bounds()
	_apply_enhanced_materials()
	_attach_underbody_contact_shadow()
	
	return true

func _process(delta: float) -> void:
	if not _render_spin_driven:
		return
	var safe_delta := clampf(delta, 0.0, 0.05)
	for i in range(4):
		var spin_step := -wheel_angular_velocities[i] * safe_delta
		current_wheel_spins[i] = wrapf(current_wheel_spins[i] + spin_step, -PI, PI)
		if spin_pivots[i] and is_instance_valid(spin_pivots[i]):
			spin_pivots[i].transform.basis = Basis(wheel_spin_axes[i], current_wheel_spins[i])
		var in_situ = in_situ_wheels[i]
		if in_situ and is_instance_valid(in_situ):
			var st_ang: float = steer_pivots[i].rotation.y if (steer_pivots[i] and i < 2) else 0.0
			var R_steer := Basis(Vector3.UP, st_ang)
			var steered_axle := R_steer * wheel_spin_axes[i]
			var R_spin := Basis(steered_axle, current_wheel_spins[i])
			var R_net := R_spin * R_steer
			var b_rel := in_situ_rel_bases[i]
			var R_local := b_rel.inverse() * R_net * b_rel
			var new_basis := in_situ_initial_bases[i] * R_local
			in_situ.transform.basis = new_basis
			var C_par := in_situ_parent_centers[i]
			var C_nod := in_situ_node_centers[i]
			in_situ.transform.origin = C_par - new_basis * C_nod

func set_wheel_angular_velocity(wheel_idx: int, angular_vel: float) -> void:
	if wheel_idx >= 0 and wheel_idx < 4:
		_render_spin_driven = true
		wheel_angular_velocities[wheel_idx] = angular_vel

func get_visual_body_min_y() -> float:
	return _measured_body_min_y

func get_wheel_visual_radius(wheel_idx: int) -> float:
	if wheel_idx >= 0 and wheel_idx < 4:
		return wheel_visual_radii[wheel_idx]
	return config.wheel_radius if config else 0.35

func _attach_underbody_contact_shadow() -> void:
	if not config:
		return
	var max_tw := maxf(config.track_width_front, config.track_width_rear)
	var shadow_w := maxf(config.chassis_size.x, max_tw + config.wheel_width) * 1.12
	var shadow_l := config.chassis_size.z * 1.04
	var k_total := (config.spring_stiffness_front + config.spring_stiffness_rear) * 2.0
	var eq_comp := (config.mass * 9.8) / maxf(k_total, 1000.0)
	var mount_y := config.suspension_rest_length * 0.5
	var scale_y := visual_root.scale.y if visual_root else 1.0
	var ground_y := mount_y - (config.suspension_rest_length - eq_comp) - config.wheel_radius + 0.08 * scale_y
	VehicleMaterialEnhancer.attach_contact_shadow(self, Vector3(0.0, ground_y, 0.0), shadow_w, shadow_l)

func cleanup() -> void:
	_render_spin_driven = false
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
		wheel_spin_axes[i] = Vector3.RIGHT
		wheel_visual_radii[i] = config.wheel_radius if config else 0.35
		wheel_angular_velocities[i] = 0.0
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
	var scale_y := visual_root.scale.y if visual_root else 1.0
	var inv_sy := 1.0 / maxf(scale_y, 0.01)
	if is_grounded and visual_root and visual_root.is_inside_tree():
		var w_rad := wheel_visual_radii[wheel_idx] * scale_y
		var target_world_pos = contact_point + contact_normal * w_rad
		var local_target = visual_root.to_local(target_world_pos)
		
		# Allow full suspension bump travel while keeping tires seated flush on road
		var max_upward := (config.suspension_travel * 0.70) * inv_sy if config else 0.085
		var max_y = rest_pos.y + max_upward
		var min_y = rest_pos.y - ((config.suspension_travel * inv_sy) if config else 0.16)
		var clamped_y = clampf(local_target.y, min_y, max_y)
		hub.position = Vector3(rest_pos.x, clamped_y, rest_pos.z)
	else:
		hub.position = rest_pos + Vector3(0.0, -(config.suspension_travel * inv_sy if config else 0.16), 0.0)
		
	if steer_pivots[wheel_idx]:
		steer_pivots[wheel_idx].rotation.y = steer_angle

	# If not driven at render rate via set_wheel_angular_velocity, step spin here for test compatibility
	if not _render_spin_driven or absf(spin_step) > 0.00001:
		current_wheel_spins[wheel_idx] = wrapf(current_wheel_spins[wheel_idx] + spin_step, -PI, PI)
		if spin_pivots[wheel_idx]:
			spin_pivots[wheel_idx].transform.basis = Basis(wheel_spin_axes[wheel_idx], current_wheel_spins[wheel_idx])
		var in_situ = in_situ_wheels[wheel_idx]
		if in_situ and is_instance_valid(in_situ):
			var st_ang = steer_angle if wheel_idx < 2 else 0.0
			var R_steer = Basis(Vector3.UP, st_ang)
			var steered_axle = R_steer * wheel_spin_axes[wheel_idx]
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
		var inv_sy := 1.0 / maxf(visual_root.scale.y if visual_root else 1.0, 0.01)
		wheel_hubs[wheel_idx].position = rest_pos + Vector3(0.0, compression_displacement * inv_sy, 0.0)

func set_wheel_steer_angle(wheel_idx: int, steer_angle_rad: float) -> void:
	if wheel_idx >= 0 and wheel_idx < 4 and steer_pivots[wheel_idx]:
		steer_pivots[wheel_idx].rotation.y = steer_angle_rad

func add_wheel_spin(wheel_idx: int, delta_spin_rad: float) -> void:
	if wheel_idx >= 0 and wheel_idx < 4 and spin_pivots[wheel_idx]:
		current_wheel_spins[wheel_idx] = wrapf(current_wheel_spins[wheel_idx] + delta_spin_rad, -PI, PI)
		spin_pivots[wheel_idx].transform.basis = Basis(wheel_spin_axes[wheel_idx], current_wheel_spins[wheel_idx])

# Updates chassis body roll, pitch, and heave generated by physics forces
func set_chassis_lean(pitch_rad: float, roll_rad: float, heave_m: float) -> void:
	if body_pivot:
		var safe_pitch := clampf(pitch_rad, deg_to_rad(-1.6), deg_to_rad(1.8))
		var safe_roll := clampf(roll_rad, deg_to_rad(-3.2), deg_to_rad(3.2))
		body_pivot.rotation = Vector3(safe_pitch, 0.0, safe_roll)
		var inv_sy := 1.0 / maxf(visual_root.scale.y if visual_root else 1.0, 0.01)
		var clamped_heave = heave_m * inv_sy
		if config:
			var max_squat = minf(config.suspension_travel * 0.12 * inv_sy, 0.008)
			clamped_heave = clampf(clamped_heave, -max_squat, 0.008)
		body_pivot.position = Vector3(0.0, clamped_heave, 0.0)

func _calibrate_visual_ride_height() -> void:
	if not visual_root or not config:
		return
	var k_total := (config.spring_stiffness_front + config.spring_stiffness_rear) * 2.0
	var eq_compression := (config.mass * 9.8) / maxf(k_total, 1000.0)
	var eq_susp_len := config.suspension_rest_length - eq_compression
	var mount_y := config.suspension_rest_length * 0.5
	var eq_ground_local_y := mount_y - eq_susp_len - config.wheel_radius
	
	var avg_tire_bottom_y := 0.0
	var valid_wheels := 0
	var scale_y := visual_root.scale.y
	for i in range(4):
		if wheel_rest_positions[i] != Vector3.ZERO:
			avg_tire_bottom_y += (wheel_rest_positions[i].y * scale_y - wheel_visual_radii[i] * scale_y)
			valid_wheels += 1
	if valid_wheels > 0:
		avg_tire_bottom_y /= float(valid_wheels)
	else:
		avg_tire_bottom_y = 0.0
		
	var visual_y_offset := eq_ground_local_y - avg_tire_bottom_y
	visual_root.position = Vector3(config.visual_offset.x, visual_y_offset, config.visual_offset.z)

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

func _get_transform_in(node: Node3D, ancestor: Node3D) -> Transform3D:
	if not node or not ancestor:
		return Transform3D.IDENTITY
	var xform := Transform3D.IDENTITY
	var curr: Node = node
	while curr and curr != ancestor:
		if curr is Node3D:
			xform = (curr as Node3D).transform * xform
		curr = curr.get_parent()
	return xform

func _reparent_preserving_transform(child: Node3D, new_parent: Node3D, common_ancestor: Node3D) -> void:
	if not child or not new_parent or not common_ancestor:
		return
	var child_xform := _get_transform_in(child, common_ancestor)
	var parent_xform := _get_transform_in(new_parent, common_ancestor)
	child.owner = null
	var p := child.get_parent()
	if p:
		p.remove_child(child)
	new_parent.add_child(child)
	child.transform = parent_xform.affine_inverse() * child_xform

func _prepare_vehicle_wheels() -> void:
	if not visual_instance or not config:
		return
	var cid := config.id.to_lower()
	var w_fl := visual_instance.get_node_or_null("Wheel_FL") as Node3D
	var w_fr := visual_instance.get_node_or_null("Wheel_FR") as Node3D
	var w_rl := visual_instance.get_node_or_null("Wheel_RL") as Node3D
	var w_rr := visual_instance.get_node_or_null("Wheel_RR") as Node3D
	if not w_fl or not w_fr or not w_rl or not w_rr:
		return
		
	if cid == "porsche_mission_x":
		var mappings := [
			["WHEEL_LF", w_fl, Vector3(-0.8016, 0.3986, -1.3472)],
			["WHEEL_RF", w_fr, Vector3(0.8326, 0.3986, -1.3472)],
			["WHEEL_LR", w_rl, Vector3(-0.8176, 0.4170, 1.3827)],
			["WHEEL_RR", w_rr, Vector3(0.875, 0.4176, 1.3827)]
		]
		for entry in mappings:
			var m_node := visual_instance.find_child(entry[0], true, false) as Node3D
			var target_w: Node3D = entry[1]
			target_w.position = _get_primary_tyre_center(m_node, entry[2])
			if m_node:
				for c in m_node.get_children():
					if c is Node3D:
						_reparent_preserving_transform(c as Node3D, target_w, visual_instance)
				
	elif cid == "porsche_carrera_gt":
		w_fl.position = Vector3(-0.8, 0.326, -1.369)
		w_fr.position = Vector3(0.8, 0.326, -1.369)
		w_rl.position = Vector3(-0.774, 0.345, 1.363)
		w_rr.position = Vector3(0.774, 0.345, 1.363)
		var cw := visual_instance.find_child("Combined_Wheels_3D_", true, false)
		if cw:
			for m in cw.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				if mi and mi.mesh:
					var c := mi.position
					if c.z >= 0 and c.x >= 0:
						_reparent_preserving_transform(mi, w_fl, visual_instance)
					elif c.z >= 0 and c.x < 0:
						_reparent_preserving_transform(mi, w_fr, visual_instance)
					elif c.z < 0 and c.x >= 0:
						_reparent_preserving_transform(mi, w_rl, visual_instance)
					elif c.z < 0 and c.x < 0:
						_reparent_preserving_transform(mi, w_rr, visual_instance)
						
	elif cid == "kia_carnival":
		var t1 := visual_instance.find_child("tire 1", true, false) as Node3D
		var t2 := visual_instance.find_child("tire 2", true, false) as Node3D
		var t3 := visual_instance.find_child("tire 3", true, false) as Node3D
		if t1:
			w_fl.position = _get_transform_in(t1, visual_instance).origin
			for c in t1.get_children():
				if c is Node3D:
					_reparent_preserving_transform(c as Node3D, w_fl, visual_instance)
		if t2:
			w_fr.position = _get_transform_in(t2, visual_instance).origin
			for c in t2.get_children():
				if c is Node3D:
					_reparent_preserving_transform(c as Node3D, w_fr, visual_instance)
		if t3:
			var t_rl := t3.find_child("tire_001", true, false) as Node3D
			var t_rr := t3.find_child("tire001", true, false) as Node3D
			if t_rl:
				w_rl.position = _get_transform_in(t_rl, visual_instance).origin
			if t_rr:
				w_rr.position = _get_transform_in(t_rr, visual_instance).origin
			for nm in ["tire_001", "GSMBiDim_108423", "brake_pad_003", "brake_003"]:
				var p := t3.find_child(nm, true, false) as Node3D
				if p:
					_reparent_preserving_transform(p, w_rl, visual_instance)
			for nm in ["tire001", "GSMBiDim_108425"]:
				var p := t3.find_child(nm, true, false) as Node3D
				if p:
					_reparent_preserving_transform(p, w_rr, visual_instance)
					
	elif cid == "kia_seltos":
		for entry in [
			["00_203 tire FL", w_fl],
			["00_211 tire FR", w_fr],
			["00_188 tire RL", w_rl],
			["00_195 tire RR", w_rr]
		]:
			var s_node := visual_instance.find_child(entry[0], true, false) as Node3D
			var target_w: Node3D = entry[1]
			if s_node:
				target_w.position = _get_transform_in(s_node, visual_instance).origin
				_reparent_preserving_transform(s_node, target_w, visual_instance)
			
	elif cid == "mclaren":
		for entry in [
			["3DWheel Front L", w_fl],
			["3DWheel Front R", w_fr],
			["3DWheel Rear L", w_rl],
			["3DWheel Rear R", w_rr]
		]:
			var m_node := visual_instance.find_child(entry[0], true, false) as Node3D
			var target_w: Node3D = entry[1]
			if m_node:
				target_w.position = _get_transform_in(m_node, visual_instance).origin
				_reparent_preserving_transform(m_node, target_w, visual_instance)

func _get_primary_tyre_center(group_node: Node3D, fallback: Vector3) -> Vector3:
	if not group_node or not visual_instance:
		return fallback
	var best_mi := _find_primary_tyre_mesh(group_node)
	if not best_mi or not best_mi.mesh:
		return fallback
	var local_c := best_mi.mesh.get_aabb().get_center()
	return _get_transform_in(best_mi, visual_instance) * local_c

func _find_primary_tyre_mesh(group_node: Node3D) -> MeshInstance3D:
	if not group_node:
		return null
	var best_mi: MeshInstance3D = null
	var best_vol: float = -1.0
	for child in group_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var cname: String = mi.name.to_lower()
		var sname: String = mi.mesh.surface_get_name(0).to_lower() if mi.mesh.get_surface_count() > 0 else ""
		var is_tyre: bool = cname.contains("tyre") or cname.contains("tire") or sname.contains("tyre") or sname.contains("tire")
		var a := mi.mesh.get_aabb()
		var vol := a.size.x * a.size.y * a.size.z
		if is_tyre:
			vol += 1000.0
		if vol > best_vol:
			best_vol = vol
			best_mi = mi
	if best_mi == null and group_node is MeshInstance3D and (group_node as MeshInstance3D).mesh:
		return group_node as MeshInstance3D
	return best_mi

func _get_primary_tyre_center_in(group_node: Node3D, ancestor: Node3D) -> Vector3:
	var best_mi := _find_primary_tyre_mesh(group_node)
	if not best_mi or not best_mi.mesh or not ancestor:
		return Vector3.ZERO
	var local_c := best_mi.mesh.get_aabb().get_center()
	return _get_transform_in(best_mi, ancestor) * local_c

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
		spin_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
			var tyre_offset := _get_primary_tyre_center_in(w_node, spin_pivot)
			if tyre_offset.length_squared() > 1e-10:
				hub.position += tyre_offset
				w_node.position = -tyre_offset
				wheel_rest_positions[i] = hub.position
		else:
			w_node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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

func _is_static_caliper_mesh(mi: MeshInstance3D) -> bool:
	if not mi:
		return false
	var nm := mi.name.to_lower()
	if nm.contains("caliper") or nm.contains("disc brake") or nm.contains("brake_pad") or nm.contains("brake pad"):
		return true
	# Kia Carnival imported rear/front calipers with opaque CAD names
	if config and config.id.to_lower() == "kia_carnival":
		if nm.begins_with("mi217") or nm.begins_with("mi226") or nm.begins_with("brake_003"):
			return true
	return false

func _calibrate_all_wheel_axes() -> void:
	for i in range(4):
		var w_node := wheel_meshes[i]
		var spin_pivot := spin_pivots[i]
		var steer_pivot := steer_pivots[i]
		var hub := wheel_hubs[i]
		if not w_node or not spin_pivot or not steer_pivot or not hub or in_situ_wheels[i]:
			continue
		var all_verts: Array[Vector3] = []
		var calipers: Array[MeshInstance3D] = []
		var v_min := Vector3(1e9, 1e9, 1e9)
		var v_max := Vector3(-1e9, -1e9, -1e9)
		for m in spin_pivot.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if not mi or not mi.mesh:
				continue
			if _is_static_caliper_mesh(mi):
				calipers.append(mi)
				continue
			var rel_xf := _get_transform_in(mi, spin_pivot)
			for s in range(mi.mesh.get_surface_count()):
				var arr := mi.mesh.surface_get_arrays(s)
				if arr.size() <= Mesh.ARRAY_VERTEX:
					continue
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for v in verts:
					var p := rel_xf * v
					all_verts.append(p)
					v_min = v_min.min(p)
					v_max = v_max.max(p)
		if all_verts.is_empty():
			continue
		var c := (v_min + v_max) * 0.5
		var ring_thresh := (v_max.y - v_min.y) * 0.35
		var min_l := Vector3(1e9, 1e9, 1e9)
		var max_l := Vector3(-1e9, -1e9, -1e9)
		var min_r := Vector3(1e9, 1e9, 1e9)
		var max_r := Vector3(-1e9, -1e9, -1e9)
		var has_l := false
		var has_r := false
		for p in all_verts:
			var rel := p - c
			if Vector2(rel.y, rel.z).length() > ring_thresh:
				if rel.x < 0.0:
					min_l = min_l.min(rel)
					max_l = max_l.max(rel)
					has_l = true
				else:
					min_r = min_r.min(rel)
					max_r = max_r.max(rel)
					has_r = true
		var c_true := c
		var axis := Vector3.RIGHT
		if has_l and has_r:
			var cl := (min_l + max_l) * 0.5
			var cr := (min_r + max_r) * 0.5
			c_true = c + (cl + cr) * 0.5
			var diff := cr - cl
			if diff.length() > 0.01:
				axis = diff.normalized()
				if axis.x < 0.0:
					axis = -axis
		# Intersect the true wheel symmetry line (c_true + t*axis) with x=0 so wheel track X is unchanged
		var pivot_yz := c_true
		if absf(axis.x) > 0.5:
			pivot_yz = c_true - axis * (c_true.x / axis.x)
		pivot_yz.x = 0.0
		w_node.position -= pivot_yz
		hub.position += pivot_yz
		wheel_rest_positions[i] += pivot_yz
		wheel_spin_axes[i] = axis
		var measured_bottom_dist := -(v_min.y - pivot_yz.y)
		var measured_half_h := 0.5 * (v_max.y - v_min.y)
		wheel_visual_radii[i] = maxf(measured_bottom_dist, measured_half_h * 0.95)
		# Keep non-rotating brake calipers anchored to SteerPivot so they do not spin with the wheel
		for cal_mi in calipers:
			if is_instance_valid(cal_mi):
				_reparent_preserving_transform(cal_mi, steer_pivot, steer_pivot)

func _is_descendant_of_any(node: Node, roots: Array[Node3D]) -> bool:
	var curr: Node = node
	while curr:
		for r in roots:
			if curr == r:
				return true
		if curr == visual_root:
			break
		curr = curr.get_parent()
	return false

func _is_node_visible_to(node: Node, stop_at: Node) -> bool:
	var curr: Node = node
	while curr:
		if curr is Node3D and not (curr as Node3D).visible:
			return false
		if curr == stop_at:
			break
		curr = curr.get_parent()
	return true

func _measure_body_floor_bounds() -> void:
	if not visual_root:
		return
	var min_y := 1e9
	var found := false
	for m in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		if _is_descendant_of_any(mi, wheel_hubs):
			continue
		if not _is_node_visible_to(mi, visual_root):
			continue
		var nm := mi.name.to_lower()
		if nm.contains("shadow") or nm.contains("ground"):
			continue
		var xf := _get_transform_in(mi, self)
		var aabb: AABB = mi.mesh.get_aabb()
		if aabb.size.length_squared() <= 1e-8:
			continue
		for ci in range(8):
			var p: Vector3 = xf * aabb.get_endpoint(ci)
			if p.y < min_y:
				min_y = p.y
				found = true
	if found:
		_measured_body_min_y = min_y

func _apply_enhanced_materials() -> void:
	if not visual_instance or not config:
		return
	var p_col = Color.WHITE
	if is_inside_tree() and has_node("/root/PlayerProfile"):
		var prof = get_node("/root/PlayerProfile")
		if prof.data and prof.data.get("custom_paint_color"):
			p_col = prof.data.custom_paint_color
	VehicleMaterialEnhancer.enhance_vehicle_materials(config.id, visual_root if visual_root else visual_instance, p_col)
