extends SceneTree

## Automated GPU telemetry + visual parity benchmark script.
## Usage:
##   Godot_v4.7.1-stable_win64_console.exe --path . --script tools/benchmark_gpu.gd -- --tag=baseline [--tier=ultra]

var _tag: String = "baseline"
var _forced_tier: String = ""
var _phase: int = 0
var _timer: float = 0.0
var _samples: Array[Dictionary] = []
var _out_dir: String = ""
var _booted: bool = false

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--tier="):
			_forced_tier = arg.trim_prefix("--tier=").to_lower()
	_out_dir = "res://docs/validation/perf_" + _tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

func _start_benchmark() -> void:
	var qs := root.get_node_or_null("QualitySettings")
	if qs and not _forced_tier.is_empty():
		var tier_map := {"low": 0, "medium": 1, "high": 2, "ultra": 3}
		if tier_map.has(_forced_tier):
			qs.apply_tier(tier_map[_forced_tier], false)
	var tier_label: String = qs.get_tier_name() if qs else "UNKNOWN"
	var overlay := root.get_node_or_null("GPUPerfOverlay")
	print("=== GPU BENCHMARK START [tag=%s] adapter=%s tier=%s overlay=%s ===" % [
		_tag, RenderingServer.get_video_adapter_name(), tier_label, overlay != null
	])
	change_scene_to_file("res://scenes/main/home_screen.tscn")

func _sample_current_vp() -> Dictionary:
	var overlay := root.get_node_or_null("GPUPerfOverlay")
	if overlay and overlay.has_method("sample_snapshot"):
		return overlay.sample_snapshot()
	var vp := root.get_viewport()
	var rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	return {
		"fps": Engine.get_frames_per_second(),
		"gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
		"cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0),
	}

func _save_shot(shot_name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.save_png(_out_dir + "/" + shot_name + ".png")
		print("Saved shot: %s/%s.png" % [_out_dir, shot_name])

func _summarize(label: String) -> void:
	if _samples.is_empty():
		return
	var avg_fps := 0.0
	var avg_gpu := 0.0
	var avg_cpu := 0.0
	var avg_dc := 0.0
	var avg_objs := 0.0
	var avg_prims := 0.0
	var last_vram := 0.0
	for s in _samples:
		avg_fps += float(s["fps"])
		avg_gpu += float(s["gpu_ms"])
		avg_cpu += float(s["cpu_ms"])
		avg_dc += float(s["draw_calls"])
		avg_objs += float(s["objects"])
		avg_prims += float(s["primitives"])
		last_vram = float(s["vram_mb"])
	var n := float(_samples.size())
	print("[BENCH:%s:%s] FPS=%.1f | GPU=%.2fms | CPU=%.2fms | Draws=%.0f | Objs=%.0f | Prims=%.0f | VRAM=%.1fMB" % [
		_tag, label, avg_fps / n, avg_gpu / n, avg_cpu / n, avg_dc / n, avg_objs / n, avg_prims / n, last_vram
	])
	_samples.clear()

func _process(delta: float) -> bool:
	if not _booted:
		_booted = true
		_start_benchmark()
		return false

	_timer += delta
	match _phase:
		0:
			var rid := root.get_viewport().get_viewport_rid()
			RenderingServer.viewport_set_measure_render_time(rid, true)
			if _timer >= 2.0:
				_samples.append(_sample_current_vp())
			if _timer >= 3.2:
				_summarize("HomeScreen")
				_save_shot("01_homescreen")
				_phase = 1
				_timer = 0.0
				change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
		1:
			var rid := root.get_viewport().get_viewport_rid()
			RenderingServer.viewport_set_measure_render_time(rid, true)
			if _timer >= 2.0:
				_samples.append(_sample_current_vp())
			if _timer >= 3.5:
				_summarize("RaceTrack_Start")
				_save_shot("02_racetrack_start")
				# Simulate rapid 180-deg camera yaw spin to check pop-in & worst-case frame time
				var track := current_scene
				if track and "_cam_world_yaw" in track and "_is_manual_mode" in track:
					track.set("_is_manual_mode", true)
					track.set("_cam_world_yaw", float(track.get("_cam_world_yaw")) + PI)
				_phase = 2
				_timer = 0.0
		2:
			if _timer >= 0.35:
				_samples.append(_sample_current_vp())
			if _timer >= 1.5:
				_summarize("RaceTrack_RapidOrbit180")
				_save_shot("03_racetrack_orbit180")
				quit(0)
				return true
	return false
