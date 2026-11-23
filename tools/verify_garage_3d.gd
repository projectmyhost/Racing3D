extends SceneTree

## Comprehensive Vulkan Verification & Visual Capture Suite for Garage3D.
## Run on real Vulkan (1920x1080, ULTRA AAA):
##   Godot --path <repo> --resolution 1920x1080 --script res://tools/verify_garage_3d.gd

const GARAGE_SCENE_PATH: String = "res://scenes/garage/Garage3D.tscn"
const OUT_DIR: String = "res://docs/validation/garage_3d"
const VehicleCatalogScript = preload("res://scripts/core/vehicle_catalog.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame

	# Ensure output directory exists
	var abs_out: String = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_out)

	var failures: Array[String] = []

	# Save original PlayerProfile state so verification never dirties user save
	var prof := get_root().get_node_or_null("PlayerProfile")
	var orig_equipped: String = "sedan"
	var orig_paint: Color = Color.WHITE
	var orig_coins: int = 250000
	var orig_unlocked: Array[String] = ["sedan", "angkot_dki"]
	if prof and prof.data:
		orig_equipped = prof.data.equipped_car
		orig_paint = prof.data.custom_paint_color
		orig_coins = prof.data.coins
		orig_unlocked = prof.data.unlocked_cars.duplicate()
		# Start hero capture with Porsche Mission X equipped (or keep clean baseline)
		if not prof.data.unlocked_cars.has("porsche_mission_x"):
			prof.data.unlocked_cars.append("porsche_mission_x")
		prof.data.equipped_car = "porsche_mission_x"
		prof.data.custom_paint_color = Color.WHITE

	# Force ULTRA AAA for verification
	var qs := get_root().get_node_or_null("QualitySettings")
	if qs:
		qs.apply_tier(qs.Tier.ULTRA, false)

	# Load Garage3D as active current_scene
	var err: Error = change_scene_to_file(GARAGE_SCENE_PATH)
	if err != OK:
		printerr("FAIL: Could not load Garage3D.tscn (err=%d)" % err)
		quit(1)
		return

	# Wait for scene ready + fade-in + ReflectionProbe bake
	await _wait_frames(35)

	var garage := current_scene as Garage3DController
	if not garage:
		printerr("FAIL: current_scene is not Garage3DController")
		quit(1)
		return

	var cam_rig: GarageCameraRig = garage.camera_rig
	var car: ShowcaseCar = garage.showcase_car
	var hud: GarageHudV2 = garage.hud

	# 1. Material Audit Check (zero missing textures)
	var mat_rep: Dictionary = garage.material_audit_report
	print("CHECK 1 [Materials]: ", mat_rep)
	if int(mat_rep.get("missing_textures", 1)) != 0:
		failures.append("Missing textures reported: %d" % int(mat_rep.get("missing_textures", 1)))
	if int(mat_rep.get("surfaces", 0)) < 3:
		failures.append("Expected >= 3 warehouse surfaces, got %d" % int(mat_rep.get("surfaces", 0)))

	# 2. QualitySettings Indoor Lighting Protection Check
	var env: Environment = garage.world_env.environment
	var exp_before: float = env.tonemap_exposure
	var amb_before: float = env.ambient_light_energy
	var fog_before: bool = env.fog_enabled
	var adj_before: float = env.adjustment_contrast
	if qs:
		qs.apply_tier(qs.Tier.ULTRA, false)
	await _wait_frames(2)
	print("CHECK 2 [IndoorLightingGuard]: exp=%.3f->%.3f amb=%.3f->%.3f fog=%s->%s adj=%.3f->%.3f ssr_steps=%d" % [
		exp_before, env.tonemap_exposure,
		amb_before, env.ambient_light_energy,
		str(fog_before), str(env.fog_enabled),
		adj_before, env.adjustment_contrast,
		env.ssr_max_steps
	])
	if absf(env.tonemap_exposure - exp_before) > 0.001 or absf(env.ambient_light_energy - amb_before) > 0.001:
		failures.append("QualitySettings overwrote handcrafted indoor lighting!")
	if env.ssr_max_steps < 32:
		failures.append("Expected ULTRA indoor SSR max_steps >= 32, got %d" % env.ssr_max_steps)

	# 3. Capture Screenshot 01: Hero 3/4 Default View (Porsche Mission X)
	cam_rig.set_auto_orbit(false)
	cam_rig.set_preset("hero_34", true)
	await _wait_frames(8)
	await _capture_png("01_garage_hero_default.png")

	# 4. Capture Screenshot 02: 180-deg Rear Orbit View
	cam_rig.set_preset("rear", true)
	await _wait_frames(6)
	await _capture_png("02_garage_orbit_rear_180.png")

	# 5. Capture Screenshot 04: Close-up Wheel/Rim + Tire-to-Floor Contact Shadow
	cam_rig.set_preset("wheel", true)
	await _wait_frames(6)
	await _capture_png("04_garage_closeup_wheel.png")

	# 6. Capture Screenshot 05: Clean VIEW CAR Mode (V)
	cam_rig.set_preset("hero_34", true)
	hud.set_view_mode(true)
	await _wait_frames(20)
	await _capture_png("05_garage_view_mode_clean.png")
	hud.set_view_mode(false)
	await _wait_frames(18)

	# 7. Preview-Before-Equip Check + Screenshot 03 (Car Switched to McLaren / Angkot)
	var equipped_before: String = prof.data.equipped_car if (prof and prof.data) else "porsche_mission_x"
	garage.select_preview_car("mclaren", true)
	# Wait for full NFS Roll-In entrance animation to complete (~0.75s)
	await create_timer(0.85).timeout
	await _wait_frames(6)
	var equipped_after_preview: String = prof.data.equipped_car if (prof and prof.data) else ""
	print("CHECK 3 [PreviewBeforeEquip]: equipped_before=%s equipped_after_preview=%s active_model=%s" % [
		equipped_before, equipped_after_preview, car.get_active_model_key()
	])
	if equipped_after_preview != equipped_before:
		failures.append("Previewing a car mutated PlayerProfile.data.equipped_car!")
	if car.get_active_model_key() != "mclaren":
		failures.append("Expected previewed model 'mclaren', got '%s'" % car.get_active_model_key())
	await _capture_png("03_garage_car_switched.png")

	# 8. All 16 Vehicles Grounding Check (tolerance < 0.015m)
	print("CHECK 4 [All 16 Vehicles Grounding]:")
	var max_ground_err: float = 0.0
	for cid in VehicleCatalogScript.ORDER:
		garage.select_preview_car(cid, false)
		var timeout_f: int = 0
		while car.get_active_model_key() != cid.to_lower() and timeout_f < 180:
			await process_frame
			timeout_f += 1
		await _wait_frames(2)
		var bottom_y: float = garage.measure_active_tire_world_bottom_y()
		var err_y: float = absf(bottom_y - 0.0)
		max_ground_err = maxf(max_ground_err, err_y)
		print("  %-18s | tire_bottom_y=%+.4fm | err=%.4fm | %s" % [
			cid, bottom_y, err_y, "OK" if err_y < 0.015 else "FAIL"
		])
		if err_y >= 0.015:
			failures.append("Vehicle '%s' grounding error %.4fm >= 0.015m" % [cid, err_y])

	# 9. Unlimited 360+ Continuous Orbit + Indoor Anti-Clip Check
	cam_rig.set_continuous_angles_deg(0.0, 14.0, 5.4, true)
	for step_i in range(1, 22):
		cam_rig.orbit_by_degrees(20.0, 0.0, true)
		if not cam_rig.is_camera_within_bounds(0.05):
			failures.append("Camera clipped outside bounds at +yaw=%.1f pos=%s" % [
				cam_rig.get_current_yaw_deg(), str(cam_rig.get_camera_world_pos())
			])
	var pos_420: float = cam_rig.get_current_yaw_deg()

	cam_rig.set_continuous_angles_deg(0.0, 48.0, 7.4, true)
	for step_i in range(1, 22):
		cam_rig.orbit_by_degrees(-20.0, 0.0, true)
		if not cam_rig.is_camera_within_bounds(0.05):
			failures.append("Camera clipped outside bounds at -yaw=%.1f high-pitch pos=%s" % [
				cam_rig.get_current_yaw_deg(), str(cam_rig.get_camera_world_pos())
			])
	var neg_420: float = cam_rig.get_current_yaw_deg()
	print("CHECK 5 [Orbit 360+ & Anti-Clip]: pos_yaw=%.1f deg, neg_yaw=%.1f deg" % [pos_420, neg_420])
	if pos_420 < 415.0 or neg_420 > -415.0:
		failures.append("Continuous orbit clamped/wrapped! pos=%.1f neg=%.1f" % [pos_420, neg_420])

	# 10. Rapid Spam-Switch Safety (5 clicks in 0.4s)
	var spam_seq: Array[String] = ["sedan", "coupe", "suv", "porsche_carrera_gt", "angkot_dki"]
	for scid in spam_seq:
		garage.select_preview_car(scid, true)
		await create_timer(0.08).timeout
	await create_timer(1.05).timeout
	await _wait_frames(4)
	var final_model: String = car.get_active_model_key()
	var final_z: float = absf(car.position.z)
	var final_tire_y: float = absf(garage.measure_active_tire_world_bottom_y())
	var final_steer: float = car.steer_angle
	print("CHECK 6 [Spam-Switch Safety]: final_model=%s z_err=%.4fm tire_err=%.4fm steer=%.1fdeg" % [
		final_model, final_z, final_tire_y, final_steer
	])
	if final_model != "angkot_dki":
		failures.append("Spam-switch ended on '%s' instead of 'angkot_dki'" % final_model)
	if final_z > 0.02:
		failures.append("Spam-switch car not centered on pad: z=%.4f" % final_z)
	if final_tire_y >= 0.015:
		failures.append("Spam-switch car not grounded: tire_y=%.4f" % final_tire_y)
	if absf(final_steer - 14.0) > 1.5:
		failures.append("Spam-switch front wheels misaligned: steer=%.1f" % final_steer)

	# 11. Live Vulkan GPU Performance Telemetry (60 frames on Hero 3/4 ULTRA AAA)
	garage.select_preview_car("porsche_mission_x", false)
	cam_rig.set_preset("hero_34", true)
	await _wait_frames(15)
	var t0_usec: int = Time.get_ticks_usec()
	var sample_frames: int = 60
	var sum_draws: float = 0.0
	var sum_prims: float = 0.0
	for _f in range(sample_frames):
		await process_frame
		sum_draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		sum_prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var elapsed_ms: float = float(Time.get_ticks_usec() - t0_usec) / 1000.0
	var avg_ms: float = elapsed_ms / float(sample_frames)
	var avg_fps: float = 1000.0 / maxf(avg_ms, 0.001)
	var vram_mb: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0)
	var gpu_name: String = RenderingServer.get_video_adapter_name()
	print("CHECK 7 [GPU Telemetry ULTRA AAA @ 1920x1080]: adapter='%s' | avg_ms=%.2fms | avg_fps=%.1f | draws=%.0f | prims=%.0f | vram=%.1fMB" % [
		gpu_name, avg_ms, avg_fps, sum_draws / sample_frames, sum_prims / sample_frames, vram_mb
	])

	# Restore user PlayerProfile cleanly
	if prof and prof.data:
		prof.data.equipped_car = orig_equipped
		prof.data.custom_paint_color = orig_paint
		prof.data.coins = orig_coins
		prof.data.unlocked_cars = orig_unlocked
		prof.save_profile()

	if failures.is_empty():
		print("PASS: Garage3D full Vulkan verification succeeded! Max grounding err=%.4fm" % max_ground_err)
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)

func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _capture_png(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	var full_path: String = ProjectSettings.globalize_path(OUT_DIR.path_join(filename))
	var err: Error = img.save_png(full_path)
	if err == OK:
		print("SAVED SCREENSHOT: %s (%dx%d)" % [filename, img.get_width(), img.get_height()])
	else:
		printerr("FAILED TO SAVE SCREENSHOT %s (err=%d)" % [filename, err])
