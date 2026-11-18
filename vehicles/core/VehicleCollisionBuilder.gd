class_name VehicleCollisionBuilder
extends RefCounted

# Procedural Vehicle Chassis Collision Builder.
# Generates a chamfered convex hull from VehicleConfig dimensions
# preventing front/rear bumper snagging on road seams, ramps, and curbs,
# and enforcing anti-wall-climb geometry so rubbing walls never flips the vehicle.

static func build_chassis_shape(config: VehicleConfig) -> ConvexPolygonShape3D:
	var max_tw = maxf(config.track_width_front, config.track_width_rear)
	var wheel_outer = (max_tw * 0.5) + (config.wheel_width * 0.5)
	
	# Body width covers wheels plus safe margin
	var half_w = maxf(config.chassis_size.x * 0.5, wheel_outer + 0.02)
	var half_h = config.chassis_size.y * 0.5
	var half_l = config.chassis_size.z * 0.5
	var center = config.chassis_offset
	var chamfer = config.ground_clearance_chamfer
	
	# Bottom width extends to wheel edge with safe bevel
	var w_bot = maxf(half_w - 0.03, wheel_outer)
	var w_inner = maxf(half_w - 0.10, half_w * 0.85)
	var l_inner = maxf(half_l - 0.45, half_l * 0.75)
	
	var y_top = center.y + half_h
	var y_mid = center.y
	# Ensure chassis floor matches suspension full-bump height with protective anti-clip margin
	var mount_y = config.suspension_rest_length * 0.5
	var min_ground_to_origin = maxf((config.suspension_rest_length - config.suspension_travel) + config.wheel_radius - mount_y, 0.25)
	var floor_protect_y = maxf(center.y - half_h + chamfer, -min_ground_to_origin + 0.08)
	var y_bot = floor_protect_y
	var y_front_lift = y_bot + 0.18
	var y_rear_lift = y_bot + 0.14
	
	var z_front = center.z - half_l
	var z_rear = center.z + half_l
	var z_f_in = center.z - l_inner
	var z_r_in = center.z + l_inner
	
	var pts: PackedVector3Array = PackedVector3Array([
		# Roof vertices
		Vector3(-half_w, y_top, z_front + 0.35),
		Vector3( half_w, y_top, z_front + 0.35),
		Vector3( half_w, y_top, z_rear - 0.25),
		Vector3(-half_w, y_top, z_rear - 0.25),
		
		# Waistline / Beltline vertices (outermost width)
		Vector3(-half_w, y_mid, z_front),
		Vector3( half_w, y_mid, z_front),
		Vector3( half_w, y_mid, z_rear),
		Vector3(-half_w, y_mid, z_rear),
		
		# Lower side rub rail vertices (anti-wall-climb barrier plates)
		Vector3(-w_bot, y_bot + 0.10, z_front + 0.20),
		Vector3( w_bot, y_bot + 0.10, z_front + 0.20),
		Vector3( w_bot, y_bot + 0.10, z_rear - 0.20),
		Vector3(-w_bot, y_bot + 0.10, z_rear - 0.20),
		
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

