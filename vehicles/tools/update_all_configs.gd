extends SceneTree

# Calibrates all 11 vehicle configs to adhere strictly to the stability contract:
# 1. Mass between 1100.0 and 1600.0 kg
# 2. Low center of mass (y between -0.35 and -0.50 m)
# 3. Suspension travel between 0.12 and 0.22 m
# 4. Explosion-proof damping and bump-stop calibration

const CONFIG_DIR = "res://vehicles/configs/"

const CALIBRATIONS = {
	"compact": {
		"mass": 1150.0,
		"com": Vector3(0.0, -0.42, -0.04),
		"rest_len": 0.30,
		"travel": 0.14,
		"k_f": 28000.0, "k_r": 26000.0,
		"d_bump_f": 2600.0, "d_bump_r": 2400.0,
		"d_reb_f": 3600.0, "d_reb_r": 3400.0
	},
	"hatchback": {
		"mass": 1220.0,
		"com": Vector3(0.0, -0.42, -0.04),
		"rest_len": 0.31,
		"travel": 0.15,
		"k_f": 29000.0, "k_r": 27000.0,
		"d_bump_f": 2700.0, "d_bump_r": 2500.0,
		"d_reb_f": 3700.0, "d_reb_r": 3500.0
	},
	"coupe": {
		"mass": 1320.0,
		"com": Vector3(0.0, -0.44, -0.05),
		"rest_len": 0.30,
		"travel": 0.14,
		"k_f": 32000.0, "k_r": 30000.0,
		"d_bump_f": 2800.0, "d_bump_r": 2600.0,
		"d_reb_f": 3800.0, "d_reb_r": 3600.0
	},
	"sport": {
		"mass": 1380.0,
		"com": Vector3(0.0, -0.45, -0.06),
		"rest_len": 0.29,
		"travel": 0.13,
		"k_f": 35000.0, "k_r": 33000.0,
		"d_bump_f": 2900.0, "d_bump_r": 2700.0,
		"d_reb_f": 3900.0, "d_reb_r": 3700.0
	},
	"mclaren": {
		"mass": 1420.0,
		"com": Vector3(0.0, -0.46, -0.06),
		"rest_len": 0.28,
		"travel": 0.13,
		"k_f": 38000.0, "k_r": 36000.0,
		"d_bump_f": 3000.0, "d_bump_r": 2800.0,
		"d_reb_f": 4000.0, "d_reb_r": 3800.0
	},
	"sedan": {
		"mass": 1360.0,
		"com": Vector3(0.0, -0.42, -0.05),
		"rest_len": 0.32,
		"travel": 0.15,
		"k_f": 33000.0, "k_r": 31000.0,
		"d_bump_f": 2800.0, "d_bump_r": 2600.0,
		"d_reb_f": 3800.0, "d_reb_r": 3600.0
	},
	"wagon": {
		"mass": 1440.0,
		"com": Vector3(0.0, -0.42, -0.05),
		"rest_len": 0.32,
		"travel": 0.15,
		"k_f": 34000.0, "k_r": 32000.0,
		"d_bump_f": 2800.0, "d_bump_r": 2600.0,
		"d_reb_f": 3800.0, "d_reb_r": 3600.0
	},
	"minivan": {
		"mass": 1520.0,
		"com": Vector3(0.0, -0.40, -0.04),
		"rest_len": 0.34,
		"travel": 0.16,
		"k_f": 36000.0, "k_r": 34000.0,
		"d_bump_f": 2900.0, "d_bump_r": 2700.0,
		"d_reb_f": 3900.0, "d_reb_r": 3700.0
	},
	"suv": {
		"mass": 1560.0,
		"com": Vector3(0.0, -0.40, -0.05),
		"rest_len": 0.35,
		"travel": 0.17,
		"k_f": 37000.0, "k_r": 35000.0,
		"d_bump_f": 3000.0, "d_bump_r": 2800.0,
		"d_reb_f": 4000.0, "d_reb_r": 3800.0
	},
	"offroad": {
		"mass": 1580.0,
		"com": Vector3(0.0, -0.40, -0.05),
		"rest_len": 0.36,
		"travel": 0.18,
		"k_f": 38000.0, "k_r": 36000.0,
		"d_bump_f": 3000.0, "d_bump_r": 2800.0,
		"d_reb_f": 4000.0, "d_reb_r": 3800.0
	},
	"pickup": {
		"mass": 1600.0,
		"com": Vector3(0.0, -0.40, -0.05),
		"rest_len": 0.36,
		"travel": 0.18,
		"k_f": 39000.0, "k_r": 37000.0,
		"d_bump_f": 3100.0, "d_bump_r": 2900.0,
		"d_reb_f": 4100.0, "d_reb_r": 3900.0
	}
}

func _init() -> void:
	print("Starting vehicle config overhaul...")
	var dir = DirAccess.open(CONFIG_DIR)
	if not dir:
		push_error("Failed to open " + CONFIG_DIR)
		quit(1)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var updated_count = 0
	
	while not file_name.is_empty():
		if file_name.ends_with(".tres"):
			var car_id = file_name.get_basename()
			var path = CONFIG_DIR + file_name
			var cfg = load(path) as VehicleConfig
			if cfg and car_id in CALIBRATIONS:
				var cal = CALIBRATIONS[car_id]
				cfg.mass = cal["mass"]
				cfg.center_of_mass_offset = cal["com"]
				cfg.suspension_rest_length = cal["rest_len"]
				cfg.suspension_travel = cal["travel"]
				cfg.spring_stiffness_front = cal["k_f"]
				cfg.spring_stiffness_rear = cal["k_r"]
				cfg.bump_damping_front = cal["d_bump_f"]
				cfg.bump_damping_rear = cal["d_bump_r"]
				cfg.rebound_damping_front = cal["d_reb_f"]
				cfg.rebound_damping_rear = cal["d_reb_r"]
				cfg.bump_stop_stiffness = 18000.0
				cfg.anti_roll_front = 6500.0
				cfg.anti_roll_rear = 5500.0
				
				var errs = cfg.validate()
				if errs.is_empty():
					ResourceSaver.save(cfg, path)
					print("Updated & Validated: ", car_id, " (Mass: ", cfg.mass, "kg, COM Y: ", cfg.center_of_mass_offset.y, "m, Travel: ", cfg.suspension_travel, "m)")
					updated_count += 1
				else:
					push_error("Validation errors for " + car_id + ": " + str(errs))
		file_name = dir.get_next()
		
	print("Successfully updated %d vehicle configs." % updated_count)
	quit(0)

