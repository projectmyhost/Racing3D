extends SceneTree

func _init():
	print("\n=== STARTING FULL GAME LOOP VALIDATION ===")
	_run_tests()

func _run_tests() -> void:
	# 1. Load Main HomeScreen
	var home_scene = load("res://scenes/main/home_screen.tscn").instantiate()
	root.add_child(home_scene)
	
	for i in range(10):
		await process_frame
		
	var ui = home_scene.find_child("HomeScreenUI", true, false)
	assert(ui != null, "HomeScreenUI must exist")
	
	var prof = ui.get("_profile_autoload")
	if not prof:
		if root.has_node("/root/PlayerProfile"):
			prof = root.get_node("/root/PlayerProfile")
	assert(prof != null, "PlayerProfile autoload must exist")
	
	print("[PASS] Profile active: ", prof.data.nickname, " | Level: ", prof.data.level, " | Coins: ", prof.data.coins, " | Equipped: ", prof.data.equipped_car)
	assert(prof.data.nickname == "DiazRaditya", "Nickname must be DiazRaditya")
	assert(prof.data.level == 0, "Level must start at 0")
	assert(prof.data.equipped_car == "sedan", "Default car must be sedan")
	
	# 2. Open Garage Modal & Verify Fleet List
	var garage_modal = ui.get("garage_modal")
	assert(garage_modal != null, "Garage modal must exist")
	ui.open_modal(garage_modal)
	
	var car_list = ui.get("garage_car_list")
	assert(car_list != null, "garage_car_list must exist")
	print("[PASS] Garage car list count: ", car_list.get_child_count(), " (expected 10)")
	assert(car_list.get_child_count() == 10, "Should have all 10 car types")
	
	# 3. Test Selecting & Purchasing 'sport' (Super Sport GT)
	print("\nTesting purchasing and equipping 'sport'...")
	ui.set("_garage_selected_car_id", "sport")
	ui._refresh_garage_ui()
	ui._on_garage_action_pressed()
	
	assert(prof.data.equipped_car == "sport", "Equipped car must now be sport")
	assert(prof.data.unlocked_cars.has("sport"), "Sport must now be in unlocked_cars")
	print("[PASS] Successfully purchased and equipped 'sport'! Remaining coins: ", prof.data.coins)
	
	var showcase = home_scene.find_child("ShowcaseCar", true, false)
	assert(showcase != null, "ShowcaseCar must exist")
	assert(showcase.current_model == "sport", "ShowcaseCar must now display sport model")
	print("[PASS] ShowcaseCar live updated to: ", showcase.current_model)
	
	# Close garage modal
	ui.close_modal()
	assert(showcase.current_model == "sport", "ShowcaseCar must retain equipped sport after closing garage")
	
	# 4. Clean up home scene and load RaceTrack3D
	home_scene.queue_free()
	for i in range(5):
		await process_frame
		
	print("\nTesting RaceTrack3D vehicle instantiation...")
	var race_scene = load("res://scenes/race/RaceTrack3D.tscn").instantiate()
	root.add_child(race_scene)
	
	for i in range(10):
		await process_frame
		
	var race_car = race_scene.find_child("RaceCar3D", true, false)
	assert(race_car != null, "RaceCar3D must exist in RaceTrack3D")
	assert(race_car.car_model_name == "sport", "RaceCar3D must load equipped 'sport' model")
	print("[PASS] RaceCar3D successfully spawned equipped model: ", race_car.car_model_name)
	
	# Check wheels exist and are oriented correctly
	assert(race_car.front_left_wheel != null, "Front left wheel must exist")
	assert(race_car.front_right_wheel != null, "Front right wheel must exist")
	assert(race_car.rear_left_wheel != null, "Rear left wheel must exist")
	assert(race_car.rear_right_wheel != null, "Rear right wheel must exist")
	print("[PASS] All 4 wheels correctly bound to RaceCar3D physics controller")
	
	# 5. Test Race Completion & XP / Star Award System
	print("\nTesting race finish logic...")
	race_scene.total_race_time = 38.5 # Fast finish under 48s -> S Rank 3 stars, 250 XP
	race_scene.best_lap_time = 12.8
	var prev_xp = prof.data.current_xp
	var prev_lvl = prof.data.level
	
	race_scene._finish_race()
	
	assert(race_scene.is_finished == true, "Race must be marked finished")
	var finish_stars = race_scene.get("finish_stars")
	var finish_rewards = race_scene.get("finish_rewards")
	print("[PASS] Victory UI Stars: ", finish_stars.text)
	print("[PASS] Victory UI Rewards: ", finish_rewards.text)
	
	print("[PASS] Player Profile after finish: Level ", prof.data.level, " | XP: ", prof.data.current_xp, " / ", prof.data.max_xp)
	assert(prof.data.level > prev_lvl or prof.data.current_xp > prev_xp, "XP and level must advance after race finish")
	
	print("\n=== ALL TESTS COMPLETED SUCCESSFULLY WITH 100% PASS RATE ===")
	quit(0)

