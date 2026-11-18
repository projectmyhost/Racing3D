extends SceneTree

# Vehicle Configuration and Asset Validation Tool.
# Validates any vehicle by id or .tres path against the vehicle contract:
# 1. Parameter ranges and physical sanity
# 2. Visual scene loading and node hierarchy
# 3. 4-wheel detection (FL, FR, RL, RR)
# 4. Procedural chassis collision generation

const VehicleConfigScript = preload("res://vehicles/core/VehicleConfig.gd")
const VehicleCollisionBuilderScript = preload("res://vehicles/core/VehicleCollisionBuilder.gd")
const VehicleVisualAdapterScript = preload("res://vehicles/core/VehicleVisualAdapter.gd")
const VehicleRegistryScript = preload("res://vehicles/registry/VehicleRegistry.gd")

func _init() -> void:
	var args = OS.get_cmdline_user_args()
	var target_id = ""
	if args.size() > 0:
		target_id = args[0]
		
	print("==========================================")
	print("VEHICLE CONTRACT VALIDATION SUITE")
	print("==========================================")
	
	var configs_to_test: Array[VehicleConfig] = []
	if not target_id.is_empty():
		if target_id.ends_with(".tres") and ResourceLoader.exists(target_id):
			var c = load(target_id) as VehicleConfig
			if c: configs_to_test.append(c)
		else:
			var c = VehicleRegistryScript.get_config(target_id)
			if c: configs_to_test.append(c)
	else:
		configs_to_test = VehicleRegistryScript.get_all_configs()
		
	if configs_to_test.is_empty():
		print("FAILED: No vehicle configurations found to validate.")
		quit(1)
		return
		
	var all_passed = true
	var total_count = configs_to_test.size()
	var pass_count = 0
	
	for cfg in configs_to_test:
		var ok = _validate_single_vehicle(cfg)
		if ok:
			pass_count += 1
		else:
			all_passed = false
			
	print("==========================================")
	print("RESULTS: %d / %d VEHICLES PASSED" % [pass_count, total_count])
	print("==========================================")
	
	if all_passed:
		print("VERIFICATION STATUS: SUCCESS")
		quit(0)
	else:
		print("VERIFICATION STATUS: FAILED")
		quit(1)

func _validate_single_vehicle(cfg: VehicleConfig) -> bool:
	print("Validating vehicle: [%s] (%s)" % [cfg.id, cfg.display_name])
	var errors: Array[String] = []
	
	# 1. Parameter validation
	var cfg_errs = cfg.validate()
	for e in cfg_errs:
		errors.append("Parameter error: " + e)
		
	# 2. Visual scene loading
	if not ResourceLoader.exists(cfg.visual_scene_path):
		errors.append("Visual scene path does not exist: " + cfg.visual_scene_path)
	else:
		var packed = load(cfg.visual_scene_path) as PackedScene
		if not packed:
			errors.append("Visual scene could not be loaded: " + cfg.visual_scene_path)
		else:
			var inst = packed.instantiate() as Node3D
			if not inst:
				errors.append("Visual scene failed to instantiate as Node3D: " + cfg.visual_scene_path)
			else:
				root.add_child(inst)
				
				# 3. Wheel detection contract check
				var w_fl = inst.find_child("Wheel_FL", true, false)
				var w_fr = inst.find_child("Wheel_FR", true, false)
				var w_rl = inst.find_child("Wheel_RL", true, false)
				var w_rr = inst.find_child("Wheel_RR", true, false)
				
				if not w_fl: errors.append("Missing wheel node: Wheel_FL")
				if not w_fr: errors.append("Missing wheel node: Wheel_FR")
				if not w_rl: errors.append("Missing wheel node: Wheel_RL")
				if not w_rr: errors.append("Missing wheel node: Wheel_RR")
				
				# 4. Body detection check
				var body_node = inst.find_child("Body", true, false)
				if not body_node:
					print("  [WARN] Node 'Body' not found directly; visual adapter will use fuzzy search.")
					
				inst.queue_free()
				
	# 5. Collision builder check
	var shape = VehicleCollisionBuilderScript.build_chassis_shape(cfg)
	if not shape or shape.points.size() < 8:
		errors.append("VehicleCollisionBuilder failed to generate valid convex shape.")
		
	if errors.is_empty():
		print("  -> PASSED: All contracts verified.")
		return true
	else:
		for err in errors:
			print("  -> ERROR: ", err)
		return false

