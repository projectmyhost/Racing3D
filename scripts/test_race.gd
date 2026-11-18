extends SceneTree

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("--- BEGINNING RACE SUBSYSTEM INTEGRATION TESTS ---")

	# Obtain singletons from root
	var sm = root.get_node("/root/SaveManager")
	var audio = root.get_node("/root/AudioManager")
	var nav = root.get_node("/root/Navigation")
	var toast = root.get_node("/root/ToastManager")
	var loc = root.get_node("/root/Localization")

	await process_frame

	# Test 1: Load RaceSetupScreen
	var setup_scene = load("res://scenes/race/RaceSetupScreen.tscn")
	assert(setup_scene != null, "FAIL: Could not load RaceSetupScreen.tscn")
	var setup_inst = setup_scene.instantiate()
	root.add_child(setup_inst)
	await process_frame
	print("PASS: RaceSetupScreen instantiated successfully")

	# Test 2: Verify Track Selection logic
	setup_inst._select_track("sunset_circuit")
	assert(setup_inst.selected_track_id == "sunset_circuit", "Track selection sunset failed")
	setup_inst._select_track("harbor_run")
	assert(setup_inst.selected_track_id == "harbor_run", "Track selection harbor failed")
	setup_inst._select_track("neon_loop")
	assert(setup_inst.selected_track_id == "neon_loop", "Track selection neon failed")
	print("PASS: Track selection switching verified for all 3 circuits")

	# Test 3: Verify Difficulty Selection logic
	setup_inst._select_difficulty("easy")
	assert(setup_inst.selected_difficulty == "easy", "Difficulty easy failed")
	setup_inst._select_difficulty("normal")
	assert(setup_inst.selected_difficulty == "normal", "Difficulty normal failed")
	setup_inst._select_difficulty("hard")
	assert(setup_inst.selected_difficulty == "hard", "Difficulty hard failed")
	print("PASS: Difficulty selection verified for Easy, Normal, Hard")

	setup_inst.queue_free()
	await process_frame

	# Test 4: Instantiate Track directly
	for trk_id in ["sunset_circuit", "harbor_run", "neon_loop"]:
		var trk = Track.new()
		trk.setup_track(trk_id)
		assert(trk.waypoints.size() >= 8, "Track waypoints count too low for " + trk_id)
		assert(trk.checkpoints.size() == trk.waypoints.size(), "Checkpoints mismatch for " + trk_id)
		assert(trk.grid_positions.size() == 4, "Grid positions must be 4 for " + trk_id)
		trk.queue_free()
	print("PASS: Track procedural generation verified for Sunset Circuit, Harbor Run, Neon Loop")

	# Test 5: Test RaceCar physics & stats
	for car_id in ["starter_gt", "apex_cruiser", "phantom_turbo"]:
		var car = RaceCar.new()
		car.car_id = car_id
		root.add_child(car)
		await process_frame
		assert(car.max_speed > 400.0, "Car max speed invalid")
		assert(car.accel_rate > 300.0, "Car accel rate invalid")
		car.queue_free()
	print("PASS: RaceCar stats applied correctly for all 3 vehicle classes")

	# Test 6: Load RaceScene and simulate gameplay loop
	var race_scene = load("res://scenes/race/RaceScene.tscn")
	var race_inst = race_scene.instantiate()
	root.add_child(race_inst)
	await process_frame
	print("PASS: RaceScene instantiated successfully")

	# Verify player and AI cars exist
	assert(race_inst.player_car != null, "Player car missing in RaceScene")
	assert(race_inst.ai_cars.size() == 3, "Expected 3 AI cars, got %d" % race_inst.ai_cars.size())
	assert(race_inst.all_cars.size() == 4, "Expected 4 total cars, got %d" % race_inst.all_cars.size())

	# Test checkpoint progression and lap completion
	var p_car = race_inst.player_car
	p_car.is_active = true
	var num_chk = p_car.total_checkpoints_count

	var initial_coins = sm.get_coins()

	# Start race: cross start line (checkpoint 0)
	p_car.notify_checkpoint(0)

	# Simulate completing Lap 1 (checkpoints 1..N-1, then 0 finish line)
	p_car.current_lap_time = 48.5
	p_car.total_time = 48.5
	for i in range(1, num_chk):
		p_car.notify_checkpoint(i)
	p_car.notify_checkpoint(0)
	assert(p_car.current_lap == 2, "Car did not advance to Lap 2")
	print("PASS: Lap 1 completed and advanced to Lap 2")

	# Simulate completing Lap 2 (checkpoints 1..N-1, then 0 finish line)
	p_car.current_lap_time = 46.2
	p_car.total_time = 94.7
	for i in range(1, num_chk):
		p_car.notify_checkpoint(i)
	p_car.notify_checkpoint(0)
	assert(p_car.is_finished, "Car should be finished after 2 laps")
	print("PASS: Race finished after 2 laps")

	# Verify Result screen and SaveManager progression update
	assert(race_inst.result_layer.visible, "Result layer should be visible upon race finish")
	var new_coins = sm.get_coins()
	assert(new_coins > initial_coins, "Coins were not awarded to player")
	print("PASS: SaveManager awarded coins successfully (+%d coins)" % (new_coins - initial_coins))

	var prog = sm.get_progress()
	assert(int(prog.get("races_completed", 0)) > 0, "Races completed not updated")
	assert(int(prog.get("event_races_completed", 0)) > 0, "Event races completed not updated")
	print("PASS: SaveManager races_completed and event_races_completed updated")

	# Verify best lap recorded
	var rec = sm.get_best_time(race_inst.track_id)
	assert(rec > 0.0, "Best lap record not saved in SaveManager")
	print("PASS: Track record saved in SaveManager: %f s" % rec)

	# Test pause menu
	race_inst._toggle_pause()
	assert(race_inst.pause_layer.visible, "Pause layer should be visible when paused")
	race_inst._on_resume_pressed()
	assert(not race_inst.pause_layer.visible, "Pause layer should be hidden when resumed")
	print("PASS: Pause and resume toggling verified")

	race_inst.queue_free()

	print("--- ALL 6 RACE INTEGRATION TESTS PASSED WITH 100% SUCCESS ---")
	quit(0)
