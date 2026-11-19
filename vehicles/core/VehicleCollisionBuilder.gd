class_name VehicleCollisionBuilder
extends RefCounted

# Procedural Vehicle Chassis Collision Builder.
# Generates a chamfered convex hull from VehicleConfig dimensions
# preventing front/rear bumper snagging on road seams, ramps, and curbs,
# and enforcing anti-wall-climb geometry so rubbing walls never flips the vehicle.

static func build_chassis_shape(config: VehicleConfig, visual_body_min_y: float = -999.0) -> ConvexPolygonShape3D:
	var s: float = config.get_world_scale()
	var max_tw = maxf(config.track_width_front, config.track_width_rear)
	var wheel_outer = (max_tw * 0.5) + (config.wheel_width * 0.5)
	
	# Body width covers wheels plus safe margin
	var half_w = maxf(config.chassis_size.x * 0.5, wheel_outer + 0.02 * s)
	var half_h = config.chassis_size.y * 0.5
	var half_l = config.chassis_size.z * 0.5
	var center = config.chassis_offset
	
	# Bottom width extends to wheel edge with safe bevel
	var w_bot = maxf(half_w - 0.03 * s, wheel_outer)
	var w_inner = maxf(half_w - 0.10 * s, half_w * 0.85)
	var l_inner = maxf(half_l - 0.45 * s, half_l * 0.75)
	
	var y_top = center.y + half_h
	var y_mid = center.y
	# Align chassis floor collision with actual visual underbody so bumpers/undertray never clip into road
	var mount_y = config.suspension_rest_length * 0.5
	var k_total = maxf((config.spring_stiffness_front + config.spring_stiffness_rear) * 2.0, 1000.0)
	var eq_comp = (config.mass * 9.8) / k_total
	var eq_ground_local_y = mount_y - (config.suspension_rest_length - eq_comp) - config.wheel_radius
	var bump_ground_local_y = mount_y - (config.suspension_rest_length - config.suspension_travel) - config.wheel_radius
	var y_bot = maxf(bump_ground_local_y + 0.015 * s, eq_ground_local_y + 0.045 * s)
	if visual_body_min_y > -50.0:
		# Place protective skidplate below lowest visual bodywork by ~1.5cm*s to absorb solver penetration
		y_bot = minf(visual_body_min_y - 0.015 * s, y_mid - 0.12 * s)
		y_bot = maxf(y_bot, eq_ground_local_y + 0.020 * s)
	var y_front_lift = y_bot + 0.045 * s
	var y_rear_lift = y_bot + 0.040 * s
	
	var z_front = center.z - half_l
	var z_rear = center.z + half_l
	var z_f_in = center.z - l_inner
	var z_r_in = center.z + l_inner
	
	var pts: PackedVector3Array = PackedVector3Array([
		# Roof vertices
		Vector3(-half_w, y_top, z_front + 0.35 * s),
		Vector3( half_w, y_top, z_front + 0.35 * s),
		Vector3( half_w, y_top, z_rear - 0.25 * s),
		Vector3(-half_w, y_top, z_rear - 0.25 * s),
		
		# Waistline / Beltline vertices (outermost width)
		Vector3(-half_w, y_mid, z_front),
		Vector3( half_w, y_mid, z_front),
		Vector3( half_w, y_mid, z_rear),
		Vector3(-half_w, y_mid, z_rear),
		
		# Lower side rub rail vertices (anti-wall-climb barrier plates)
		Vector3(-w_bot, y_bot + 0.10 * s, z_front + 0.20 * s),
		Vector3( w_bot, y_bot + 0.10 * s, z_front + 0.20 * s),
		Vector3( w_bot, y_bot + 0.10 * s, z_rear - 0.20 * s),
		Vector3(-w_bot, y_bot + 0.10 * s, z_rear - 0.20 * s),
		
		# Front bumper ski-ramp chamfer
		Vector3(-w_inner, y_front_lift, z_front),
		Vector3( w_inner, y_front_lift, z_front),
		
		# Rear bumper ski-ramp chamfer
		Vector3(-w_inner, y_rear_lift, z_rear),
		Vector3( w_inner, y_rear_lift, z_rear),
		
		# Flat floor bottom vertices
		Vector3(-w_inner, y_bot, z_f_in),
		Vector3( w_inner, y_bot, z_f_in),
		Vector3( w_inner, y_bot, z_r_in),
		Vector3(-w_inner, y_bot, z_r_in)
	])
	
	var shape = ConvexPolygonShape3D.new()
	shape.points = pts
	return shape

