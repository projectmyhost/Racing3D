extends SceneTree

# Generates calibrated VehicleConfig resources for all 11 existing cars
# and saves them into res://vehicles/configs/*.tres

const VehicleConfigScript = preload("res://vehicles/core/VehicleConfig.gd")

func _init() -> void:
	print("--- GENERATING DEFAULT VEHICLE CONFIGS ---")
	DirAccess.make_dir_recursive_absolute("res://vehicles/configs")
	
	var data: Array[Dictionary] = [
		{
			"id": "mclaren",
			"display_name": "McLaren Artura Spider",
			"vehicle_class": "Hypercar",
			"mass": 1490.0,
			"drivetrain": 1,
			"power_kw": 515.0,
			"max_rpm": 8500.0,
			"gear_ratios": [3.95, 2.65, 1.95, 1.52, 1.24, 1.02, 0.84],
			"wb": 2.759,
			"tw_f": 1.613,
			"tw_r": 1.567,
			"r_f": 0.340,
			"r_r": 0.374,
			"spring_f": 46000.0,
			"spring_r": 44000.0,
			"bump_f": 3400.0,
			"bump_r": 3200.0,
			"rebound_f": 5200.0,
			"rebound_r": 5000.0,
			"anti_roll_f": 8500.0,
			"anti_roll_r": 7500.0,
			"fric_long": 1.85,
			"fric_lat": 1.90,
			"drag": 0.30,
			"downforce": 0.75,
			"chassis_size": Vector3(1.92, 0.82, 4.54)
		},
		{
			"id": "sport",
			"display_name": "Phantom Turbo Sport",
			"vehicle_class": "Sport",
			"mass": 1420.0,
			"drivetrain": 1,
			"power_kw": 350.0,
			"max_rpm": 7800.0,
			"gear_ratios": [3.82, 2.36, 1.69, 1.31, 1.00, 0.79],
			"wb": 2.759,
			"tw_f": 1.562,
			"tw_r": 1.523,
			"r_f": 0.335,
			"r_r": 0.357,
			"spring_f": 40000.0,
			"spring_r": 38000.0,
			"bump_f": 3000.0,
			"bump_r": 2800.0,
			"rebound_f": 4400.0,
			"rebound_r": 4200.0,
			"anti_roll_f": 7500.0,
			"anti_roll_r": 6500.0,
			"fric_long": 1.75,
			"fric_lat": 1.80,
			"drag": 0.31,
			"downforce": 0.50,
			"chassis_size": Vector3(1.86, 0.84, 4.48)
		},
		{
			"id": "coupe",
			"display_name": "Apex Cruiser Coupe",
			"vehicle_class": "Performance Coupe",
			"mass": 1380.0,
			"drivetrain": 1,
			"power_kw": 260.0,
			"max_rpm": 7200.0,
			"gear_ratios": [3.70, 2.30, 1.62, 1.25, 0.98, 0.80],
			"wb": 2.715,
			"tw_f": 1.492,
			"tw_r": 1.492,
			"r_f": 0.335,
			"r_r": 0.335,
			"spring_f": 36000.0,
			"spring_r": 34000.0,
			"bump_f": 2700.0,
			"bump_r": 2500.0,
			"rebound_f": 4000.0,
			"rebound_r": 3800.0,
			"anti_roll_f": 6800.0,
			"anti_roll_r": 5800.0,
			"fric_long": 1.70,
			"fric_lat": 1.72,
			"drag": 0.32,
			"downforce": 0.35,
			"chassis_size": Vector3(1.80, 0.85, 4.38)
		},
		{
			"id": "sedan",
			"display_name": "Executive Sedan",
			"vehicle_class": "Standard",
			"mass": 1520.0,
			"drivetrain": 1,
			"power_kw": 180.0,
			"max_rpm": 6800.0,
			"gear_ratios": [3.65, 2.25, 1.55, 1.18, 0.95, 0.78],
			"wb": 2.943,
			"tw_f": 1.572,
			"tw_r": 1.569,
			"r_f": 0.347,
			"r_r": 0.345,
			"spring_f": 32000.0,
			"spring_r": 30000.0,
			"bump_f": 2400.0,
			"bump_r": 2200.0,
			"rebound_f": 3500.0,
			"rebound_r": 3300.0,
			"anti_roll_f": 5500.0,
			"anti_roll_r": 4800.0,
			"fric_long": 1.62,
			"fric_lat": 1.65,
			"drag": 0.33,
			"downforce": 0.25,
			"chassis_size": Vector3(1.86, 0.88, 4.65)
		},
		{
			"id": "wagon",
			"display_name": "Touring Estate Wagon",
			"vehicle_class": "Wagon",
			"mass": 1580.0,
			"drivetrain": 2,
			"power_kw": 190.0,
			"max_rpm": 6800.0,
			"gear_ratios": [3.65, 2.25, 1.55, 1.18, 0.95, 0.78],
			"wb": 2.963,
			"tw_f": 1.576,
			"tw_r": 1.576,
			"r_f": 0.347,
			"r_r": 0.347,
			"spring_f": 33000.0,
			"spring_r": 32000.0,
			"bump_f": 2500.0,
			"bump_r": 2400.0,
			"rebound_f": 3600.0,
			"rebound_r": 3500.0,
			"anti_roll_f": 5600.0,
			"anti_roll_r": 5000.0,
			"fric_long": 1.62,
			"fric_lat": 1.65,
			"drag": 0.34,
			"downforce": 0.25,
			"chassis_size": Vector3(1.86, 0.90, 4.70)
		},
		{
			"id": "hatchback",
			"display_name": "Hot Hatch Sport",
			"vehicle_class": "Hatchback",
			"mass": 1260.0,
			"drivetrain": 0,
			"power_kw": 170.0,
			"max_rpm": 7000.0,
			"gear_ratios": [3.55, 2.15, 1.48, 1.12, 0.90, 0.75],
			"wb": 2.705,
			"tw_f": 1.557,
			"tw_r": 1.557,
			"r_f": 0.342,
			"r_r": 0.342,
			"spring_f": 31000.0,
			"spring_r": 29000.0,
			"bump_f": 2300.0,
			"bump_r": 2100.0,
			"rebound_f": 3400.0,
			"rebound_r": 3200.0,
			"anti_roll_f": 5800.0,
			"anti_roll_r": 4500.0,
			"fric_long": 1.65,
			"fric_lat": 1.68,
			"drag": 0.33,
			"downforce": 0.28,
			"chassis_size": Vector3(1.82, 0.88, 4.25)
		},
		{
			"id": "compact",
			"display_name": "City Compact",
			"vehicle_class": "Compact",
			"mass": 1050.0,
			"drivetrain": 0,
			"power_kw": 110.0,
			"max_rpm": 6500.0,
			"gear_ratios": [3.45, 2.05, 1.40, 1.05, 0.85],
			"wb": 2.344,
			"tw_f": 1.230,
			"tw_r": 1.230,
			"r_f": 0.266,
			"r_r": 0.266,
			"spring_f": 26000.0,
			"spring_r": 24000.0,
			"bump_f": 2000.0,
			"bump_r": 1800.0,
			"rebound_f": 3000.0,
			"rebound_r": 2800.0,
			"anti_roll_f": 4800.0,
			"anti_roll_r": 3800.0,
			"fric_long": 1.60,
			"fric_lat": 1.62,
			"drag": 0.34,
			"downforce": 0.20,
			"chassis_size": Vector3(1.50, 0.85, 3.75)
		},
		{
			"id": "minivan",
			"display_name": "Grand Voyager Minivan",
			"vehicle_class": "Van",
			"mass": 1850.0,
			"drivetrain": 0,
			"power_kw": 180.0,
			"max_rpm": 6400.0,
			"gear_ratios": [3.75, 2.25, 1.50, 1.12, 0.88, 0.72],
			"wb": 3.196,
			"tw_f": 1.571,
			"tw_r": 1.571,
			"r_f": 0.353,
			"r_r": 0.353,
			"spring_f": 35000.0,
			"spring_r": 34000.0,
			"bump_f": 2600.0,
			"bump_r": 2500.0,
			"rebound_f": 3800.0,
			"rebound_r": 3700.0,
			"anti_roll_f": 6000.0,
			"anti_roll_r": 5200.0,
			"fric_long": 1.58,
			"fric_lat": 1.60,
			"drag": 0.36,
			"downforce": 0.20,
			"chassis_size": Vector3(1.88, 1.15, 4.95)
		},
		{
			"id": "suv",
			"display_name": "Titan Ridge SUV",
			"vehicle_class": "SUV",
			"mass": 2100.0,
			"drivetrain": 2,
			"power_kw": 240.0,
			"max_rpm": 6600.0,
			"gear_ratios": [3.85, 2.35, 1.58, 1.18, 0.92, 0.74],
			"wb": 3.073,
			"tw_f": 1.629,
			"tw_r": 1.629,
			"r_f": 0.420,
			"r_r": 0.420,
			"spring_f": 42000.0,
			"spring_r": 40000.0,
			"bump_f": 3000.0,
			"bump_r": 2800.0,
			"rebound_f": 4400.0,
			"rebound_r": 4200.0,
			"anti_roll_f": 7200.0,
			"anti_roll_r": 6400.0,
			"fric_long": 1.60,
			"fric_lat": 1.63,
			"drag": 0.38,
			"downforce": 0.25,
			"chassis_size": Vector3(1.95, 1.10, 4.85)
		},
		{
			"id": "pickup",
			"display_name": "Heavy Duty Pickup",
			"vehicle_class": "Pickup",
			"mass": 2250.0,
			"drivetrain": 2,
			"power_kw": 250.0,
			"max_rpm": 6200.0,
			"gear_ratios": [4.10, 2.45, 1.65, 1.20, 0.92, 0.72],
			"wb": 3.594,
			"tw_f": 1.641,
			"tw_r": 1.641,
			"r_f": 0.423,
			"r_r": 0.423,
			"spring_f": 45000.0,
			"spring_r": 48000.0,
			"bump_f": 3200.0,
			"bump_r": 3500.0,
			"rebound_f": 4600.0,
			"rebound_r": 5000.0,
			"anti_roll_f": 7500.0,
			"anti_roll_r": 6800.0,
			"fric_long": 1.58,
			"fric_lat": 1.60,
			"drag": 0.42,
			"downforce": 0.20,
			"chassis_size": Vector3(1.98, 1.05, 5.35)
		},
		{
			"id": "offroad",
			"display_name": "Trail Master 4x4",
			"vehicle_class": "Offroad",
			"mass": 1950.0,
			"drivetrain": 2,
			"power_kw": 210.0,
			"max_rpm": 6400.0,
			"gear_ratios": [4.20, 2.50, 1.70, 1.25, 0.95, 0.75],
			"wb": 2.611,
			"tw_f": 1.654,
			"tw_r": 1.654,
			"r_f": 0.402,
			"r_r": 0.402,
			"spring_f": 36000.0,
			"spring_r": 34000.0,
			"bump_f": 2800.0,
			"bump_r": 2600.0,
			"rebound_f": 4000.0,
			"rebound_r": 3800.0,
			"anti_roll_f": 6200.0,
			"anti_roll_r": 5500.0,
			"fric_long": 1.62,
			"fric_lat": 1.64,
			"drag": 0.40,
			"downforce": 0.22,
			"chassis_size": Vector3(1.92, 1.15, 4.35)
		}
	]
	
	for d in data:
		var cfg = VehicleConfigScript.new()
		cfg.id = d["id"]
		cfg.display_name = d["display_name"]
		cfg.vehicle_class = d["vehicle_class"]
		cfg.mass = d["mass"]
		cfg.drivetrain_type = d["drivetrain"]
		cfg.peak_power_kw = d["power_kw"]
		cfg.max_engine_rpm = d["max_rpm"]
		var ratios: Array[float] = []
		for r in d["gear_ratios"]:
			ratios.append(float(r))
		cfg.gear_ratios = ratios
		cfg.wheelbase = d["wb"]
		cfg.track_width_front = d["tw_f"]
		cfg.track_width_rear = d["tw_r"]
		cfg.wheel_radius = (d["r_f"] + d["r_r"]) * 0.5
		cfg.spring_stiffness_front = d["spring_f"]
		cfg.spring_stiffness_rear = d["spring_r"]
		cfg.bump_damping_front = d["bump_f"]
		cfg.bump_damping_rear = d["bump_r"]
		cfg.rebound_damping_front = d["rebound_f"]
		cfg.rebound_damping_rear = d["rebound_r"]
		cfg.anti_roll_front = d["anti_roll_f"]
		cfg.anti_roll_rear = d["anti_roll_r"]
		cfg.tire_longitudinal_friction = d["fric_long"]
		cfg.tire_lateral_friction = d["fric_lat"]
		cfg.drag_coefficient = d["drag"]
		cfg.downforce_coefficient = d["downforce"]
		cfg.chassis_size = d["chassis_size"]
		cfg.visual_scene_path = "res://assets/models/cars/car_" + d["id"] + ".tscn"
		
		var errs = cfg.validate()
		if not errs.is_empty():
			print("VALIDATION ERROR for ", d["id"], ": ", errs)
			continue
			
		var save_path = "res://vehicles/configs/" + d["id"] + ".tres"
		var save_err = ResourceSaver.save(cfg, save_path)
		if save_err == OK:
			print("SUCCESS: Saved ", save_path)
		else:
			print("ERROR saving ", save_path, ": ", save_err)
			
	print("--- GENERATION COMPLETED ---")
	quit()
