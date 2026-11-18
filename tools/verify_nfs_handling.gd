extends SceneTree

func _init() -> void:
	print("--- DEBUGGING BICYCLE KINEMATICS ---")
	var car = RaceCar3D.new()
	car.car_model_name = "sedan"
	root.add_child(car)
	car._setup_visual_car()

	car.position = Vector3(0.0, 10.0, 0.0)
	car.forward_speed = 18.0
	car.current_steer_angle = deg_to_rad(20.0)
	
	print("Before physics_process: speed=%f, steer=%f, rot_y=%f, pos=%s" % [car.forward_speed, car.current_steer_angle, car.rotation.y, str(car.position)])
	car._physics_process(0.016)
	print("After physics_process: speed=%f, steer=%f, rot_y=%f, pos=%s" % [car.forward_speed, car.current_steer_angle, car.rotation.y, str(car.position)])
	quit()
