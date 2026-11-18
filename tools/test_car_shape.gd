@tool
extends SceneTree

# Test create beveled car convex shape

func _init() -> void:
	var shape = create_beveled_car_shape()
	print("Car convex shape created with points: ", shape.points.size())
	for p in shape.points:
		print("  Point: ", p)
	quit(0)

func create_beveled_car_shape() -> ConvexPolygonShape3D:
	var w = 0.95
	var w_in = 0.80
	var y_top = 1.05
	var y_mid = 0.55
	var y_bot = 0.10
	var y_front = 0.28
	var y_rear = 0.24
	var z_front = -1.90
	var z_f_in = -1.35
	var z_r_in = 1.35
	var z_rear = 1.90
	
	var pts: PackedVector3Array = PackedVector3Array([
		# Top points
		Vector3(-w, y_top, z_front),
		Vector3( w, y_top, z_front),
		Vector3( w, y_top, z_rear),
		Vector3(-w, y_top, z_rear),
		
		# Mid waist points
		Vector3(-w, y_mid, z_front),
		Vector3( w, y_mid, z_front),
		Vector3( w, y_mid, z_rear),
		Vector3(-w, y_mid, z_rear),
		
		# Front raised bumper points (ski slope approach angle)
		Vector3(-w_in, y_front, z_front),
		Vector3( w_in, y_front, z_front),
		
		# Rear raised bumper points (departure angle)
		Vector3(-w_in, y_rear, z_rear),
		Vector3( w_in, y_rear, z_rear),
		
		# Bottom flat chassis points
		Vector3(-w_in, y_bot, z_f_in),
		Vector3( w_in, y_bot, z_f_in),
		Vector3( w_in, y_bot, z_r_in),
		Vector3(-w_in, y_bot, z_r_in)
	])
	
	var shape = ConvexPolygonShape3D.new()
	shape.points = pts
	return shape

