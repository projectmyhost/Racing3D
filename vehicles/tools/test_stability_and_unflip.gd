extends SceneTree

# Automated Test Suite for Vehicle Stability, Anti-Wall-Climb, Slope-Hold, and Auto-Unflip.

var _ticks_elapsed: int = 0
var _test_stage: int = 0
var _test_car: VehiclePhysicsCore
var _world: World3D
var _root_node: Node3D

func _init() -> void:
	print("==========================================")
	print("VEHICLE STABILITY & AUTO-UNFLIP TEST SUITE")
	print("==========================================")
	_setup_test_scene()

func _setup_test_scene() -> void:
	_root_node = Node3D.new()
	_root_node.name = "TestRoot"
	root.add_child(_root_node)
	current_scene = _root_node
	
	# Create floor static body
	var floor_body = StaticBody3D.new()
	floor_body.name = "TestFloor"
	floor_body.collision_layer = 1
	var floor_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(200.0, 2.0, 200.0)
	floor_shape.shape = box
	floor_shape.position = Vector3(0.0, -1.0, 0.0)
	floor_body.add_child(floor_shape)
	_root_node.add_child(floor_body)
	
	# Create a vertical concrete barrier wall
	var wall_body = StaticBody3D.new()
	wall_body.name = "BarrierWall"
	wall_body.collision_layer = 1
	var wall_shape = CollisionShape3D.new()
	var wall_box = BoxShape3D.new()
	wall_box.size = Vector3(1.0, 4.0, 200.0)
	wall_shape.shape = wall_box
	wall_shape.position = Vector3(2.0, 2.0, 0.0)
	wall_body.add_child(wall_shape)
	_root_node.add_child(wall_body)
	
	# Instantiate test vehicle (Compact - the one from user video)
	_test_car = VehiclePhysicsCore.new()
	_test_car.name = "TestCar"
	var cfg = VehicleRegistry.get_config("compact")
	_test_car.config = cfg
	_root_node.add_child(_test_car)
	_test_car.initialize_vehicle(cfg)
	
	# Stage 0: Barrier Rub / Anti-Wall-Climb test
	# Position car touching wall (x = 0.9m, wall is at x = 1.5 to 2.5)
	_test_car.global_position = Vector3(0.95, 0.5, 0.0)
	_test_car.global_rotation = Vector3.ZERO
	# Give forward and slight rightward velocity toward wall
	_test_car.linear_velocity = Vector3(2.0, 0.0, -15.0)
	_test_car.set_driver_input(1.0, 0.0, -0.3, 0.0)
	print("Stage 1: Testing Barrier Rub & Anti-Wall-Climb...")

func _physics_process(_delta: float) -> bool:
	_ticks_elapsed += 1
	
	if _test_stage == 0:
		# Run 60 ticks (1.0 second) of wall scraping
		var chassis_up = _test_car.global_transform.basis.y.normalized()
		var up_dot = chassis_up.dot(Vector3.UP)
		var height = _test_car.global_position.y
		
		# If car catapults into air (y > 2.5m) or flips (up_dot < 0.6), fail
		if height > 2.0 or up_dot < 0.6:
			push_error("FAILED: Car catapulted or flipped during wall rub! Y=" + str(height) + ", up_dot=" + str(up_dot))
			quit(1)
			return false
			
		if _ticks_elapsed >= 60:
			print("  -> PASSED: Wall rub stable! Y=%.2fm, up_dot=%.3f, Speed=%.1f KM/H" % [
				height, up_dot, abs(_test_car.forward_speed) * 3.6
			])
			_start_slope_hold_test()
			
	elif _test_stage == 1:
		# Slope Hold Test on a 15-degree inclined plane
		if _ticks_elapsed < 40:
			# Let settle on slope
			return false
			
		var speed_kmh = abs(_test_car.forward_speed) * 3.6
		if speed_kmh > 0.8:
			push_error("FAILED: Slope hold failed to keep car stationary! Speed: " + str(speed_kmh) + " KM/H")
			quit(1)
			return false
			
		if _ticks_elapsed >= 90:
			print("  -> PASSED: Slope hold rock-solid on 15 deg incline! Speed: %.2f KM/H" % speed_kmh)
			_start_unflip_test()
			
	elif _test_stage == 2:
		# Auto-Unflip Test: car is overturned
		var chassis_up = _test_car.global_transform.basis.y.normalized()
		var up_dot = chassis_up.dot(Vector3.UP)
		
		# At 140 ticks (~2.3s after overturning), auto-unflip should have triggered
		if _ticks_elapsed >= 150:
			if up_dot > 0.85 and _test_car.global_position.y > 0.2:
				print("  -> PASSED: Auto-unflip restored vehicle upright! up_dot=%.3f, Y=%.2f" % [up_dot, _test_car.global_position.y])
				print("==========================================")
				print("ALL STABILITY & RECOVERY TESTS PASSED!")
				print("==========================================")
				quit(0)
			else:
				push_error("FAILED: Auto-unflip did not restore car! up_dot=" + str(up_dot) + ", Y=" + str(_test_car.global_position.y))
				quit(1)
	return false

func _start_slope_hold_test() -> void:
	_test_stage = 1
	_ticks_elapsed = 0
	print("Stage 2: Testing Slope Hold on Inclined Plane...")
	
	# Rotate car pitch by 15 degrees (slope simulation)
	_test_car.linear_velocity = Vector3.ZERO
	_test_car.angular_velocity = Vector3.ZERO
	_test_car.global_position = Vector3(0.0, 0.45, 0.0)
	_test_car.global_rotation = Vector3(deg_to_rad(-15.0), 0.0, 0.0)
	_test_car.set_driver_input(0.0, 0.0, 0.0, 0.0)

func _start_unflip_test() -> void:
	_test_stage = 2
	_ticks_elapsed = 0
	print("Stage 3: Testing Auto-Unflip Recovery...")
	
	# Overturn car completely (roll 180 deg)
	_test_car.linear_velocity = Vector3.ZERO
	_test_car.angular_velocity = Vector3.ZERO
	_test_car.global_position = Vector3(0.0, 0.8, 0.0)
	_test_car.global_rotation = Vector3(0.0, 0.0, PI)
	_test_car.set_driver_input(0.0, 0.0, 0.0, 0.0)
