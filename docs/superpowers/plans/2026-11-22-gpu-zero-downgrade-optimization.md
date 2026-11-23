# GPU Optimization Without Visual Downgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce RTX 5050 Laptop GPU usage from 100% saturation down to comfortable 60 FPS headroom while strictly preserving (or sharpening) 100% of AAA visual fidelity and enforcing a 60 FPS release ceiling in game and Settings UI.

**Architecture:** Executed in two sequential verified phases: **Phase 1 (Tasks 1–6)** eliminates pure Forward+ rendering waste (`MSAA_2X + TAA` double AA, full-res SSAO, `420m` shadow over-reach, procedural sky FBM recomputation, heavy behind-camera exhaust particle shading, uncompressed VRAM `.import` textures, eager 16-car HomeScreen pre-warming, and unlocked FPS options). **Phase 2 (Tasks 7–11)** adds 3-Zone Zero-Pop-In visibility and geometry scaling (`ArrayOccluder3D` conservative city occlusion, `140m` spatial grid chunk batching on `CityMap`, micro-prop `visibility_range` outside a `360°` near-ring, safe `CULL_BACK` audit, and high-poly vehicle interior shadow/distance separation).

**Tech Stack:** Godot `v4.7.1.stable` (`Forward+` Vulkan renderer), GDScript, GLSL shaders (`.gdshader`), scene pre-baking tools (`@tool` `SceneTree` scripts).

**Spec:** [2026-11-22-gpu-zero-downgrade-optimization-design.md](file:///c:/Users/Pongo/OneDrive/Documents/racing/docs/superpowers/specs/2026-11-22-gpu-zero-downgrade-optimization-design.md)

## Global Constraints

1. **Zero Visual Downgrade:** Preserve `car_paint_aaa.gdshader` (`clearcoat`, flakes, orange peel), `asphalt_aaa.gdshader`, `AgX` tonemapping, `VolumetricFog`, `SSR`, `SSIL`, `SSAO`, `Glow`, and golden-hour sky colors/sun crispness at 100% quality.
2. **60 FPS Max Ceiling:** Maximum FPS in runtime AND Settings UI (`FpsOption`) is `60 FPS` (`30 FPS` and `60 FPS` only; `120 FPS` and `Unlocked` disabled/removed).
3. **Protect Asphalt Textures:** Never modify `assets/models/environment/city_map/source/Untitled_Image_49.png`, `Untitled_Image_72.png`, or their `.import` files.
4. **Protect Colliders & `backdrop_grp_*`:** Never break `CollisionGuard.gd` (`TrackColliders`, `BackdropRoadCollision`, `RoadSurfacesCollision`) or modify `backdrop_grp_*` meshes/hierarchy (`CollisionGuard` must report `0 anomalies`).
5. **Protect Vehicle Visual Exceptions:** Never alter `porsche_mission_x` rims/calipers/badges (`VehicleMaterialEnhancer.gd:178`) or unhide `porsche_carrera_gt` `body6a`.
6. **Godot CLI Executable:** Run headless Godot verification commands with `C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`.

## Review Focus

1. **Rapid 360° camera orbit pop-in or flicker** when player drags `ChaseCamera` quickly (`RaceTrack3D.gd`): Verify all geometry within `160m` 360° around camera stays resident (`visibility_range_end = 0.0` on buildings/roads; only micro-props `<8m` fade out past `170–210m` via hardware `VISIBILITY_RANGE_FADE_SELF`).
2. **Backface holes on thin `Untitled.glb` surfaces if `CULL_BACK` is applied blindly**: Audit and exclude `alphaMode=BLEND` (`material_041_38/42/55/68`) plus thin 1-sided/flipped-normal materials before enabling `CULL_BACK`, and verify visually on race & home screenshots.
3. **Premature occlusion hiding corners during turns (`ArrayOccluder3D`)**: Shrink each generated occluder box conservatively (`>= 2.0m` horizontal, `1.5m` top) strictly inside opaque `>=12m` tall, `>=6m` thick `unit_*` masses, and test corners visually in `RaceTrack3D`.
4. **`CollisionGuard.gd` / `asphalt_aaa.gdshader` regression after `CityMap` batching**: Keep `backdrop_grp_*` unmerged intact and keep batched road chunks inside `CityMap`'s exact `MODEL_MATRIX` coordinate frame so `v_world_pos` and road physics colliders match identically.
5. **Shadow clipping from `directional_shadow_pancake_size` or interior leak on open vehicles**: Verify `directional_shadow_pancake_size = 12.0` on elevated ramps (`RoadSurfacesCollision`) with screenshot inspection, and exclude open-cabin interior geometry (`angkot_dki` passengers/driver & convertible interiors within `90m`) from disappearing prematurely.

---

# PHASE 1: Pipeline, Shadow, Sky, VFX, VRAM & 60 FPS Ceiling

### Task 1: Baseline Performance Benchmark Tool & Toggleable `F3` GPU Overlay

**Files:**
- Create: `scripts/debug/gpu_perf_overlay.gd`
- Create: `tools/benchmark_gpu.gd`
- Modify: `project.godot:19-22` (register `GPUPerfOverlay` autoload, hidden by default)
- Test: `tools/benchmark_gpu.gd`

**Interfaces:**
- Produces: `GPUPerfOverlay` autoload exposing `sample_snapshot() -> Dictionary` (`fps`, `gpu_ms`, `cpu_ms`, `draw_calls`, `primitives`, `objects`, `vram_mb`).
- Consumes: Godot `RenderingServer` viewport timing APIs & `Performance` monitors.

- [x] **Step 1: Write `scripts/debug/gpu_perf_overlay.gd` (`F3` toggle HUD, hidden by default)**

```gdscript
extends CanvasLayer

## Lightweight F3-toggle performance telemetry overlay for GPU optimization verification.
## Hidden by default during normal gameplay; collects GPU frame time & draw call snapshots.

var _panel: PanelContainer
var _label: Label
var _visible_hud: bool = false
var _accum: float = 0.0
var _frames: int = 0
var _measured_vp_rid: RID

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enable_viewport_timing()
	_build_ui()
	_panel.visible = false

func _enable_viewport_timing() -> void:
	var vp := get_viewport()
	if vp:
		_measured_vp_rid = vp.get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(_measured_vp_rid, true)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "PerfPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = Vector2(16, 110)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.09, 0.82)
	sb.border_color = Color(0.25, 0.72, 1.0, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", sb)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	_panel.add_child(_label)
	add_child(_panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_visible_hud = not _visible_hud
		_panel.visible = _visible_hud

func sample_snapshot() -> Dictionary:
	if not _measured_vp_rid.is_valid():
		_enable_viewport_timing()
	var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(_measured_vp_rid) if _measured_vp_rid.is_valid() else 0.0
	var cpu_ms := RenderingServer.viewport_get_measured_render_time_cpu(_measured_vp_rid) if _measured_vp_rid.is_valid() else 0.0
	return {
		"fps": Engine.get_frames_per_second(),
		"gpu_ms": gpu_ms,
		"cpu_ms": cpu_ms,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0),
	}

func _process(delta: float) -> void:
	if not _visible_hud or not _panel.visible:
		return
	_accum += delta
	_frames += 1
	if _accum < 0.25:
		return
	var s := sample_snapshot()
	var adapter := RenderingServer.get_video_adapter_name()
	_label.text = "GPU: %s\nFPS: %.0f | GPU: %.2f ms | CPU: %.2f ms\nDraws: %d | Objs: %d | Tris/Prims: %d\nVRAM: %.1f MB" % [
		adapter, s["fps"], s["gpu_ms"], s["cpu_ms"],
		s["draw_calls"], s["objects"], s["primitives"], s["vram_mb"]
	]
	_accum = 0.0
	_frames = 0
```

- [x] **Step 2: Write windowed benchmark + screenshot script `tools/benchmark_gpu.gd`**

This script runs WITH rendering enabled (windowed short run, NOT `--headless` where Vulkan render time is `0.0`), records exact GPU `ms`, Draw Calls, Primitives, VRAM, plus captures baseline screenshots (`HomeScreen` + `RaceTrack3D` straightaway + elevated ramp + fast 180° orbit view) to `docs/validation/perf_baseline/`.

```gdscript
extends SceneTree

## Automated GPU telemetry + visual parity benchmark script.
## Usage:
##   Godot_v4.7.1-stable_win64_console.exe --path . --script tools/benchmark_gpu.gd -- --tag=baseline

var _tag: String = "baseline"
var _phase: int = 0
var _timer: float = 0.0
var _samples: Array[Dictionary] = []
var _out_dir: String = ""

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	_out_dir = "res://docs/validation/perf_" + _tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	print("=== GPU BENCHMARK START [tag=%s] adapter=%s ===" % [_tag, RenderingServer.get_video_adapter_name()])
	change_scene_to_file("res://scenes/main/home_screen.tscn")

func _sample_current_vp() -> Dictionary:
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

func _save_shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.save_png(_out_dir + "/" + name + ".png")
		print("Saved shot: %s/%s.png" % [_out_dir, name])

func _summarize(label: String) -> void:
	if _samples.is_empty():
		return
	var avg_gpu := 0.0
	var avg_cpu := 0.0
	var avg_dc := 0.0
	var avg_prims := 0.0
	var last_vram := 0.0
	for s in _samples:
		avg_gpu += s["gpu_ms"]
		avg_cpu += s["cpu_ms"]
		avg_dc += s["draw_calls"]
		avg_prims += s["primitives"]
		last_vram = s["vram_mb"]
	var n := float(_samples.size())
	print("[BENCH:%s:%s] GPU=%.2fms | CPU=%.2fms | Draws=%.0f | Prims=%.0f | VRAM=%.1fMB" % [
		_tag, label, avg_gpu / n, avg_cpu / n, avg_dc / n, avg_prims / n, last_vram
	])
	_samples.clear()

func _process(delta: float) -> bool:
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
```

- [x] **Step 3: Register `GPUPerfOverlay` autoload in `project.godot` & run baseline capture**

Edit `project.godot:20-23`:
```ini
[autoload]

PlayerProfile="*res://scripts/core/player_profile.gd"
QualitySettings="*res://scripts/core/quality_settings.gd"
GPUPerfOverlay="*res://scripts/debug/gpu_perf_overlay.gd"
```

Run baseline benchmark:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --path . --script tools/benchmark_gpu.gd -- --tag=baseline
```
Expected: Prints `[BENCH:baseline:HomeScreen] ...` and `[BENCH:baseline:RaceTrack_Start] ...` and `[BENCH:baseline:RaceTrack_RapidOrbit180] ...` and writes 3 baseline PNGs under `docs/validation/perf_baseline/`. Record these baseline numbers for Phase 1 and Phase 2 comparisons!

- [x] **Step 4: Commit**

```bash
git add project.godot scripts/debug/gpu_perf_overlay.gd tools/benchmark_gpu.gd
git commit -m "chore: add F3 GPU perf overlay and automated benchmark baseline runner"
```

---

### Task 2: Enforce 60 FPS Ceiling at Boot & Inside Settings UI

**Files:**
- Modify: `scenes/ui/home_screen_ui.tscn:1120-1158`
- Modify: `scripts/ui/home_screen_ui.gd:440-462, 682-708, 1223-1253`
- Modify: `scripts/autoload/SaveManager.gd:58-60` (keep consistent if referenced later)
- Test: `tools/test_fps_cap.gd` (headless check)

**Interfaces:**
- Consumes: `DisplayServer.screen_get_refresh_rate()`, `Engine.max_fps`.
- Produces: `HomeScreenUI._apply_fps_index(index: int)` clamping strictly to `[0, 1]` (`30` or `60` FPS), invoked automatically at `_ready()`.

- [x] **Step 1: Write failing test script `tools/test_fps_cap.gd` verifying max 2 FPS items & runtime cap <= 60**

```gdscript
extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/main/home_screen.tscn") as PackedScene
	var home := packed.instantiate()
	get_root().add_child(home)
	await process_frame
	var ui := home.get_node_or_null("UILayer/HomeScreenUI")
	assert(ui != null, "HomeScreenUI missing")
	var fps_opt := ui.fps_option as OptionButton
	assert(fps_opt != null, "FpsOption missing")
	assert(fps_opt.item_count == 2, "Expected strictly 2 FPS options (30 & 60), got %d" % fps_opt.item_count)
	assert(Engine.max_fps > 0 and Engine.max_fps <= 60, "Engine.max_fps must be locked <= 60, got %d" % Engine.max_fps)
	ui._on_fps_selected(3) # Attempt out-of-range unlimited index
	assert(Engine.max_fps > 0 and Engine.max_fps <= 60, "Engine.max_fps escaped 60 FPS clamp!")
	print("PASS: FPS UI count=%d, Engine.max_fps=%d" % [fps_opt.item_count, Engine.max_fps])
	home.queue_free()
	quit(0)
```

- [x] **Step 2: Run test to verify it currently FAILS**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_fps_cap.gd --quit
```
Expected: FAIL (`Assertion failed: Expected strictly 2 FPS options (30 & 60), got 4`).

- [x] **Step 3: Update `scenes/ui/home_screen_ui.tscn:1120-1158` (`FpsOption` 2 items + accurate `QualityOption` ULTRA description)**

In `scenes/ui/home_screen_ui.tscn`, update `QualityOption` `popup/item_3/text` (removing stale `SDFGI`) and shrink `FpsOption` to `item_count = 2`:
```ini
popup/item_3/text = "[ULTRA AAA] Max Realism (SSIL + Vol. Fog + 4K Shadows)"
popup/item_3/id = 3
```
and under `[node name="FpsOption" ...]`:
```ini
selected = 1
item_count = 2
popup/item_0/text = "30 FPS (Eco / Battery Saving)"
popup/item_0/id = 0
popup/item_1/text = "60 FPS (Smooth Target - Standard Cap)"
popup/item_1/id = 1
```

- [x] **Step 4: Update `scripts/ui/home_screen_ui.gd` so boot & Settings strictly clamp FPS <= 60**

In `scripts/ui/home_screen_ui.gd`:
1. In `_ready()` (after `_connect_modal_buttons()`), call `_apply_fps_index(_selected_fps_index)`.
2. Extract `_apply_fps_index(index: int) -> void` and reuse it from both `_ready()` and `_on_fps_selected(index: int)`:
```gdscript
func _apply_fps_index(index: int) -> void:
	_selected_fps_index = clampi(index, 0, 1)
	Engine.physics_jitter_fix = 0.0
	var screen_hz: float = DisplayServer.screen_get_refresh_rate()
	if _selected_fps_index == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 30
	else:
		# 60 FPS ceiling: use native VSync on 60Hz panels; use max_fps=60 without VSync mismatch on 120Hz+ panels
		if screen_hz > 0.0 and absf(screen_hz - 60.0) <= 2.0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 60

func _on_fps_selected(index: int) -> void:
	_apply_fps_index(index)
	if fps_option and fps_option.selected != _selected_fps_index:
		fps_option.select(_selected_fps_index)
	show_toast("[OK] Frame Rate Target locked to " + fps_option.get_item_text(_selected_fps_index))
```

- [x] **Step 5: Run `test_fps_cap.gd` & commit**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_fps_cap.gd --quit
```
Expected: `PASS: FPS UI count=2, Engine.max_fps=60`.

```bash
git add scenes/ui/home_screen_ui.tscn scripts/ui/home_screen_ui.gd tools/test_fps_cap.gd
git commit -m "feat: lock max release frame rate to 60 FPS at boot and in settings UI"
```

---

### Task 3: Zero-Downgrade `QualitySettings` & Shadow Atlas Tuning

**Files:**
- Modify: `scripts/core/quality_settings.gd:92-163, 287-297`
- Test: `tools/test_quality_profile.gd`

**Interfaces:**
- Consumes: `QualitySettings.TIER_PROFILES`, `_apply_to_current_scene()`.
- Produces: `Tier.ULTRA` without redundant `MSAA_2X + TAA`, `ssao_half = true` (retaining `HIGH`), `SHADOW_QUALITY_SOFT_MEDIUM`, `shadow_max_dist = 260.0`, `directional_shadow_pancake_size = 12.0`, `mesh_lod_threshold = 0.85`.

- [x] **Step 1: Write failing test `tools/test_quality_profile.gd`**

```gdscript
extends SceneTree

func _init() -> void:
	var qs := get_root().get_node_or_null("QualitySettings")
	assert(qs != null, "QualitySettings autoload missing")
	qs.apply_tier(qs.Tier.ULTRA, false)
	var vp := get_root()
	assert(vp.use_taa == true, "ULTRA must preserve TAA")
	assert(vp.msaa_3d == Viewport.MSAA_DISABLED, "ULTRA must not stack MSAA_2X on top of TAA")
	var u_cfg: Dictionary = qs.TIER_PROFILES[qs.Tier.ULTRA]
	assert(u_cfg["ssao_half"] == true, "ULTRA SSAO should use half-res while keeping HIGH quality")
	assert(float(u_cfg["shadow_max_dist"]) <= 280.0, "Shadow max distance should focus atlas density <= 280m")
	assert(u_cfg["shadow_quality"] == RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, "Expected SOFT_MEDIUM filter")
	print("PASS: QualitySettings Tier.ULTRA eliminates MSAA+TAA redundancy & tightens shadows")
	quit(0)
```

- [x] **Step 2: Run test to verify failure**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_quality_profile.gd --quit
```
Expected: FAIL (`Assertion failed: ULTRA must not stack MSAA_2X on top of TAA`).

- [x] **Step 3: Edit `scripts/core/quality_settings.gd:128-163, 287-297`**

Update `Tier.ULTRA` inside `TIER_PROFILES` (`scripts/core/quality_settings.gd:128-163`):
```gdscript
	Tier.ULTRA: {
		"shadow_size": 4096,
		"shadow_quality": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
		"shadow_mode": DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
		"shadow_max_dist": 260.0,
		"use_taa": true,
		"msaa": Viewport.MSAA_DISABLED,
		"ssaa": Viewport.SCREEN_SPACE_AA_DISABLED,
		"anisotropy": Viewport.ANISOTROPY_16X,
		"scaling_scale": 1.0,
		"mesh_lod_threshold": 0.85,
		"ssr": true,
		"ssr_steps": 32,
		"ssao": true,
		"ssao_quality": RenderingServer.ENV_SSAO_QUALITY_HIGH,
		"ssao_half": true,
		"ssil": true,
		"ssil_quality": RenderingServer.ENV_SSIL_QUALITY_MEDIUM,
		"ssil_half": true,
		"sdfgi": false,
		"gi_half": true,
		"volumetric_fog": true,
		"fog": true,
		"glow": true,
		"glow_bicubic": true,
		"shader_detail": 1.0,
		"exposure": 0.95,
		"ambient_energy": 0.52,
		"sky_contrib": 0.72,
		"sun_energy_scale": 1.0,
		"fill_energy_scale": 1.0,
		"sky_intensity": 1.45,
		"adj_brightness": 0.99,
		"adj_contrast": 1.14,
		"adj_saturation": 1.09,
	},
```
Also update `Tier.HIGH` `"shadow_max_dist"` from `350.0` → `220.0` (so `4096px` shadow texel density also improves in `HIGH`), and in `_apply_to_current_scene()` (`scripts/core/quality_settings.gd:287-291`), calibrate splits & pancake size:
```gdscript
		sun.directional_shadow_mode = cfg["shadow_mode"]
		sun.directional_shadow_blend_splits = true
		sun.directional_shadow_pancake_size = 12.0
		sun.directional_shadow_max_distance = float(cfg["shadow_max_dist"])
		sun.directional_shadow_split_1 = 0.06
		sun.directional_shadow_split_2 = 0.18
		sun.directional_shadow_split_3 = 0.45
```
(Also remove `"msaa": Viewport.MSAA_2X` from `Tier.MEDIUM` → `MSAA_DISABLED` if FXAA is already on, or keep `Tier.MEDIUM` clean with `MSAA_DISABLED + SCREEN_SPACE_AA_FXAA` so RTX 2050 doesn't suffer MSAA resolve bandwidth either — keep `Tier.MEDIUM` sharper with `MSAA_DISABLED + FXAA`.)

- [x] **Step 4: Run verification test & commit**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_quality_profile.gd --quit
```
Expected: `PASS: QualitySettings Tier.ULTRA eliminates MSAA+TAA redundancy & tightens shadows`.

```bash
git add scripts/core/quality_settings.gd tools/test_quality_profile.gd
git commit -m "perf: remove redundant MSAA+TAA, half-res SSAO, and focus 4K shadow cascade range"
```

---

### Task 4: Sky Panorama Pre-Baking, Exhaust Particle Fillrate Fix & HUD Redraw Throttling

**Files:**
- Create: `tools/bake_sunset_panorama.gd`
- Create: `assets/textures/environments/sky_sunset_clouds.exr` (generated)
- Create: `assets/textures/environments/sky_sunset_clouds.exr.import` (BPTC/VRAM or HDR half-float, `mipmaps=false` / equirectangular clean!)
- Create: `assets/shaders/sky_sunset_fast.gdshader`
- Modify: `assets/materials/environments/env_racetrack.tres:3-22`
- Modify: `scripts/core/quality_settings.gd:268-276` (`sky_sunset_fast` still uses `hdr_sky_intensity`!)
- Modify: `scripts/race/RaceCar3D.gd:111-132, 191`
- Modify: `scripts/race/ModernSpeedometer.gd:75-94`
- Modify: `scripts/race/ModernMinimap.gd:136-138`

- [x] **Step 1: Write `tools/bake_sunset_panorama.gd` reproducing `sky_sunset.gdshader` gradient & 5-octave FBM clouds to `2048×1024` HDR EXR**

```gdscript
@tool
extends SceneTree

## Pre-bakes the static atmospheric gradient + 5-octave FBM cloud deck from sky_sunset.gdshader
## into a 2048x1024 HDR EXR texture so runtime sky rendering avoids 10-octave per-pixel noise.

const OUT_PATH := "res://assets/textures/environments/sky_sunset_clouds.exr"

const COLOR_ZENITH := Color(0.09, 0.15, 0.34)
const COLOR_MID := Color(0.32, 0.25, 0.45)
const COLOR_PINK := Color(0.84, 0.40, 0.36)
const COLOR_HORIZON := Color(1.0, 0.60, 0.26)
const COLOR_SUN := Color(1.0, 0.94, 0.80)
const COLOR_SUN_GLOW := Color(1.0, 0.64, 0.24)
const COLOR_GROUND := Color(0.09, 0.09, 0.12)
const CLOUD_COV := 0.48
const SUN_DIR := Vector3(0.7217, 0.3909, 0.5713).normalized()

func _fract_f(x: float) -> float:
	return x - floorf(x)

func _hash21(px: float, py: float) -> float:
	var hx := _fract_f(px * 123.34)
	var hy := _fract_f(py * 456.21)
	var d := hx * (hx + 45.32) + hy * (hy + 45.32)
	hx += d
	hy += d
	return _fract_f(hx * hy)

func _noise2(p: Vector2) -> float:
	var ix := floorf(p.x)
	var iy := floorf(p.y)
	var fx := p.x - ix
	var fy := p.y - iy
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	var a := _hash21(ix, iy)
	var b := _hash21(ix + 1.0, iy)
	var c := _hash21(ix, iy + 1.0)
	var d := _hash21(ix + 1.0, iy + 1.0)
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy)

func _fbm(p: Vector2) -> float:
	var v := 0.0
	var amp := 0.5
	var cur := p
	for i in range(5):
		v += amp * _noise2(cur)
		# rot = mat2((0.8, -0.6), (0.6, 0.8)) -> col0=(0.8,-0.6), col1=(0.6,0.8)
		var rx := 0.8 * cur.x + 0.6 * cur.y
		var ry := -0.6 * cur.x + 0.8 * cur.y
		cur = Vector2(rx * 2.05 + 13.7, ry * 2.05 + 9.2)
		amp *= 0.5
	return v

func _eval_col(dir: Vector3) -> Color:
	var y := dir.y
	var sun_dot := maxf(dir.dot(SUN_DIR), 0.0)
	var col := COLOR_GROUND
	if y >= 0.0:
		if y < 0.14:
			col = COLOR_HORIZON.lerp(COLOR_PINK, smoothstep(0.0, 0.14, y))
		elif y < 0.42:
			col = COLOR_PINK.lerp(COLOR_MID, smoothstep(0.14, 0.42, y))
		else:
			col = COLOR_MID.lerp(COLOR_ZENITH, smoothstep(0.42, 0.95, y))

		var horizon_band := pow(1.0 - clampf(y, 0.0, 1.0), 5.0)
		col += COLOR_HORIZON * horizon_band * 0.42

		var mie_wide := pow(sun_dot, 4.0) * (0.45 + 0.55 * (1.0 - clampf(y, 0.0, 1.0)))
		col += COLOR_SUN_GLOW * mie_wide * 0.72

		if y > 0.015:
			var cloud_uv := Vector2(dir.x, dir.z) / (y + 0.16) * 0.85 + Vector2(0.18, -0.12)
			var n1 := _fbm(cloud_uv * 1.4)
			var n2 := _fbm(cloud_uv * 3.1 + Vector2(n1 * 0.7, -n1 * 0.5))
			var density := lerpf(n1, n2, 0.45)
			var mask := smoothstep(1.0 - CLOUD_COV - 0.18, 1.0 - CLOUD_COV + 0.25, density)
			var horizon_fade := smoothstep(0.015, 0.12, y) * (1.0 - smoothstep(0.75, 0.98, y))
			mask *= horizon_fade

			var sun_scatter := pow(sun_dot, 3.0)
			var cloud_dark := (COLOR_MID * 0.85).lerp(COLOR_PINK * 1.05, 0.45)
			var cloud_lit := (COLOR_PINK * 1.35).lerp(COLOR_SUN * 2.1, clampf(sun_scatter * 1.15 + (1.0 - density) * 0.4, 0.0, 1.0))
			var light_factor := clampf((1.0 - n2) * 0.7 + sun_scatter * 0.65, 0.0, 1.0)
			var cloud_col := cloud_dark.lerp(cloud_lit, light_factor)
			col = col.lerp(cloud_col, mask * 0.68)
	else:
		var t := clampf(-y * 8.0, 0.0, 1.0)
		col = (COLOR_HORIZON * 0.45).lerp(COLOR_GROUND, t)
	return col

func _init() -> void:
	var w := 1024
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBAF)
	for py in range(h):
		var v := (float(py) + 0.5) / float(h)
		var theta := v * PI # 0 = zenith (+Y), PI = nadir (-Y)
		var sin_t := sin(theta)
		var cos_t := cos(theta)
		for px in range(w):
			var u := (float(px) + 0.5) / float(w)
			var phi := u * TAU # azimuth
			var dir := Vector3(-sin_t * sin(phi), cos_t, -sin_t * cos(phi)).normalized()
			var c := _eval_col(dir)
			img.set_pixel(px, py, Color(c.r, c.g, c.b, 1.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/textures/environments"))
	var err := img.save_exr(OUT_PATH, false)
	print("Baked sky EXR -> ", OUT_PATH, " err=", err)
	quit(0 if err == OK else 1)
```
*(Verify in `sky_sunset_fast.gdshader` that `SKY_COORDS` maps identically to `dir = (-sin_t*sin(phi), cos_t, -sin_t*cos(phi))`, OR even simpler: use `SKY_COORDS` formula directly! Wait: in Godot 4 `sky()` shader, `SKY_COORDS.x` goes `0..1` around azimuth and `SKY_COORDS.y` goes `0..1` top-to-bottom matching Godot's equirectangular PanoramaSky UV (`u = atan(-dir.x, -dir.z)/TAU + 0.5` or matching `SKY_COORDS` directly — let's use exact `(u = SKY_COORDS.x, v = SKY_COORDS.y)` from a `2`D test or sample with `textureLod(baked_sky_tex, equirect_uv, 0.0)` using the exact inverse math of `EYEDIR` so there is ZERO seam or misalignment! Specifically: `u = fract(atan(-dir.x, -dir.z) / TAU)` if `phi = u * TAU`, `v = acos(clamp(dir.y, -1.0, 1.0)) / PI`! Verify sun-glow center aligns with `SUN_DIR` before committing!)*

- [x] **Step 2: Create `assets/shaders/sky_sunset_fast.gdshader` & update `env_racetrack.tres`**

```glsl
shader_type sky;

uniform sampler2D baked_sky_tex : source_color, filter_linear, repeat_enable;
uniform vec3 color_sun : source_color = vec3(1.0, 0.94, 0.80);
uniform vec3 color_sun_glow : source_color = vec3(1.0, 0.64, 0.24);
uniform float hdr_sky_intensity : hint_range(0.5, 4.0) = 1.45;
uniform vec3 sun_dir = vec3(0.7217, 0.3909, 0.5713);

const float INV_TAU = 0.15915494;
const float INV_PI = 0.31830989;

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 s_dir = normalize(sun_dir);

	float u = fract(atan(-dir.x, -dir.z) * INV_TAU);
	float v = acos(clamp(dir.y, -1.0, 1.0)) * INV_PI;
	vec3 col = textureLod(baked_sky_tex, vec2(u, v), 0.0).rgb;

	if (dir.y >= -0.02) {
		float sun_dot = max(dot(dir, s_dir), 0.0);
		float corona = pow(sun_dot, 36.0) * 1.85;
		float halo = pow(sun_dot, 180.0) * 3.2;
		col += color_sun_glow * corona + color_sun * halo;
		if (sun_dot > 0.9982) {
			float disc = smoothstep(0.9982, 0.9993, sun_dot);
			col = mix(col, color_sun * 8.5, disc);
		}
	}

	COLOR = col * hdr_sky_intensity;
}
```
Update `assets/materials/environments/env_racetrack.tres:1-22`:
```ini
[ext_resource type="Shader" path="res://assets/shaders/sky_sunset_fast.gdshader" id="1_sunset"]
[ext_resource type="Texture2D" path="res://assets/textures/environments/sky_sunset_clouds.exr" id="2_skytex"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_sunset"]
shader = ExtResource("1_sunset")
shader_parameter/baked_sky_tex = ExtResource("2_skytex")
shader_parameter/color_sun = Color(1, 0.94, 0.8, 1)
shader_parameter/color_sun_glow = Color(1, 0.64, 0.24, 1)
shader_parameter/hdr_sky_intensity = 1.45
shader_parameter/sun_dir = Vector3(0.7217, 0.3909, 0.5713)

[sub_resource type="Sky" id="Sky_sunset"]
sky_material = SubResource("ShaderMaterial_sunset")
process_mode = 2
radiance_size = 3
```

- [x] **Step 3: Optimize constant exhaust smoke material in `scripts/race/RaceCar3D.gd`**

Add `_build_exhaust_material(base_tint: Color) -> StandardMaterial3D` near line `133` and update line `191`:
```gdscript
func _build_exhaust_material(base_tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = base_tint
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _get_soft_smoke_texture()
	mat.texture_repeat = false
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return mat
```
And at line `191`:
```gdscript
	_exhaust_mat = _build_exhaust_material(Color(0.72, 0.74, 0.78, 0.32))
```
Keep `_build_smoke_material()` for `TireSmokeLeft/Right` (active only while drifting).

- [x] **Step 4: Throttle redundant 2D HUD redraws in `ModernSpeedometer.gd` & `ModernMinimap.gd`**

In `scripts/race/ModernSpeedometer.gd:84-94`:
```gdscript
var _last_drawn_speed: float = -1.0
var _last_drawn_angle: float = -99.0
var _last_drawn_gear: int = -99

func _process(delta: float) -> void:
	var safe_delta := clampf(delta, 0.0001, 0.05)
	_displayed_speed = lerpf(_displayed_speed, current_speed_kmh, 1.0 - exp(-14.0 * safe_delta))
	_displayed_rpm = lerpf(_displayed_rpm, current_rpm, 1.0 - exp(-16.0 * safe_delta))

	var rpm_ratio := clampf(_displayed_rpm / maxf(max_engine_rpm, 1000.0), 0.0, 1.0)
	var target_angle := lerpf(ANGLE_MIN, ANGLE_MAX, rpm_ratio)
	_needle_angle = lerpf(_needle_angle, target_angle, 1.0 - exp(-18.0 * safe_delta))
	if absf(_displayed_speed - _last_drawn_speed) > 0.15 or absf(_needle_angle - _last_drawn_angle) > 0.002 or current_gear != _last_drawn_gear:
		_last_drawn_speed = _displayed_speed
		_last_drawn_angle = _needle_angle
		_last_drawn_gear = current_gear
		queue_redraw()
```
In `scripts/race/ModernMinimap.gd:136-138`:
```gdscript
var _last_map_pos: Vector3 = Vector3(1e9, 0.0, 1e9)
var _last_map_yaw: float = -999.0

func _process(_delta: float) -> void:
	if car_node and is_instance_valid(car_node):
		var xf: Transform3D = car_node.get_global_transform_interpolated()
		var yaw := atan2(-xf.basis.z.z, -xf.basis.z.x)
		if xf.origin.distance_squared_to(_last_map_pos) > 0.04 or absf(angle_difference(yaw, _last_map_yaw)) > 0.008:
			_last_map_pos = xf.origin
			_last_map_yaw = yaw
			queue_redraw()
```

- [x] **Step 5: Generate sky EXR, verify shader & scene load cleanly, and commit**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/bake_sunset_panorama.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --import --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_racetrack.gd --quit
```
Expected: `Baked sky EXR -> res://assets/textures/environments/sky_sunset_clouds.exr err=0` and `SUCCESS: RaceTrack3D instantiated!`.

```bash
git add tools/bake_sunset_panorama.gd assets/textures/environments/sky_sunset_clouds.exr* assets/shaders/sky_sunset_fast.gdshader assets/materials/environments/env_racetrack.tres scripts/race/RaceCar3D.gd scripts/race/ModernSpeedometer.gd scripts/race/ModernMinimap.gd
git commit -m "perf: pre-bake static sunset cloud panorama, lighten exhaust particles, throttle HUD redraw"
```

---

### Task 5: VRAM Texture Compression (`compress/mode=2` BPTC/BC7) Audit & Conversion

**Files:**
- Modify: Large uncompressed 3D texture `.import` files (`>= 200KB` with `compress/mode=0`) under `assets/models/` and `assets/textures/`, **strictly excluding**:
  - `assets/models/environment/city_map/source/Untitled_Image_49.png.import`
  - `assets/models/environment/city_map/source/Untitled_Image_72.png.import`
  - All `assets/ui/**` `.import` files
  - `assets/textures/environments/sky_sunset_clouds.exr.import`
- Test: `tools/verify_all_cars.gd` + protected import `git diff` guard

- [x] **Step 1: Convert eligible `compress/mode=0` `.import` files `>= 200KB` to VRAM Compressed (`compress/mode=2`)**

Run PowerShell updater:
```powershell
$protected = @(
    "Untitled_Image_49.png.import",
    "Untitled_Image_72.png.import",
    "sky_sunset_clouds.exr.import"
)
$updated = 0
Get-ChildItem -Recurse assets/models,assets/textures -Include *.png.import,*.jpg.import | ForEach-Object {
    if ($_.FullName -like "*\assets\ui\*") { return }
    if ($protected -contains $_.Name) { return }
    $src = $_.FullName -replace '\.import$',''
    if (-not (Test-Path $src)) { return }
    if ((Get-Item $src).Length -lt 204800) { return }
    $raw = Get-Content $_.FullName -Raw
    if ($raw -match 'compress/mode=0') {
        $next = $raw -replace 'compress/mode=0', 'compress/mode=2'
        $next = $next -replace 'compress/high_quality=false', 'compress/high_quality=true'
        $next = $next -replace 'mipmaps/generate=false', 'mipmaps/generate=true'
        if ($src -match '(_nm|Normal|NRM)\.(png|jpg)$') {
            $next = $next -replace 'compress/normal_map=0', 'compress/normal_map=1'
            $next = $next -replace 'compress/normal_map=2', 'compress/normal_map=1'
        }
        Set-Content -Path $_.FullName -Value $next -NoNewline
        $updated++
    }
}
Write-Output "Updated .import files to BPTC VRAM compress/mode=2: $updated"
```

- [x] **Step 2: Run Godot headless `--import`, verify protected imports unchanged, and test all cars**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --import --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_all_cars.gd --quit
git diff -- assets/models/environment/city_map/source/Untitled_Image_49.png.import assets/models/environment/city_map/source/Untitled_Image_72.png.import assets/ui/
```
Expected: `Summary: 11/11 loaded successfully.` and empty `git diff` output on protected files.

- [x] **Step 3: Commit**

```bash
git add assets/models/ assets/textures/
git commit -m "perf: enable VRAM BPTC/BC7 compression on oversized uncompressed 3D textures"
```

---

### Task 6: HomeScreen Showroom Lightening & Lazy Garage Rig Warming

**Files:**
- Modify: `scripts/vehicle/showcase_car.gd:88-145, 259-340`
- Modify: `scripts/core/home_screen.gd:8-15`
- Test: Phase 1 Benchmark Gate (`tools/benchmark_gpu.gd -- --tag=phase1`)

**Interfaces:**
- Consumes: `HomeScreen`, `ShowcaseCar`.
- Produces: Zero startup 16-car background warmup (`MAX_POOLED_RIGS = 4` LRU eviction when garage browses) + `120m` directional shadow cap strictly on `HomeScreen`.

- [x] **Step 1: Disable startup 16-car warming & add LRU pool cap (`MAX_POOLED_RIGS = 4`) in `scripts/vehicle/showcase_car.gd`**

In `scripts/vehicle/showcase_car.gd`:
1. Remove `_schedule_background_preload.call_deferred()` from `_ready()` (`showcase_car.gd:128`) so entering the main menu never queues 16 unused cars in the background.
2. Add constant `const MAX_POOLED_RIGS: int = 4` and array `var _rig_lru: Array[String] = []`. Inside `_activate_pooled_rig(key)` / `_apply_loaded_car_scene`, erase & append `key` to `_rig_lru`, and whenever `_rig_pool.size() > MAX_POOLED_RIGS`:
```gdscript
func _trim_rig_pool(keep_key: String) -> void:
	while _rig_pool.size() > MAX_POOLED_RIGS and not _rig_lru.is_empty():
		var oldest: String = _rig_lru.pop_front()
		if oldest == keep_key or not _rig_pool.has(oldest):
			continue
		var entry: Dictionary = _rig_pool[oldest]
		var piv := entry.get("pivot") as Node3D
		if piv and is_instance_valid(piv):
			piv.queue_free()
		_rig_pool.erase(oldest)
```

- [x] **Step 2: Tighten `HomeScreen` showroom `SunLight` shadow distance to `120.0m` in `scripts/core/home_screen.gd`**

Add helper in `scripts/core/home_screen.gd` called after `apply_to_current_scene()` and connected to `qs.tier_changed`:
```gdscript
func _apply_showroom_shadow_clamp() -> void:
	var sun := get_node_or_null("SunLight") as DirectionalLight3D
	if sun:
		sun.directional_shadow_max_distance = minf(sun.directional_shadow_max_distance, 120.0)
```
In `_ready()`:
```gdscript
	if has_node("/root/QualitySettings"):
		var qs := get_node("/root/QualitySettings")
		qs.apply_to_current_scene()
		if not qs.tier_changed.is_connected(_on_quality_tier_changed):
			qs.tier_changed.connect(_on_quality_tier_changed)
	_apply_showroom_shadow_clamp()
```
With:
```gdscript
func _on_quality_tier_changed(_tier: int) -> void:
	_apply_showroom_shadow_clamp()
```

- [x] **Step 3: Run Phase 1 Benchmark & Visual Parity Gate**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --path . --script tools/benchmark_gpu.gd -- --tag=phase1
```
Inspect `docs/validation/perf_phase1/*.png` vs `docs/validation/perf_baseline/*.png` with `read_file` and compare `[BENCH:phase1:*]` vs `[BENCH:baseline:*]`. Confirm `0%` visual downgrade, sharper shadows around car, and major GPU `ms` & VRAM drop!

- [x] **Step 4: Commit**

```bash
git add scripts/vehicle/showcase_car.gd scripts/core/home_screen.gd
git commit -m "perf: defer garage fleet preloading with LRU cap and clamp showroom shadow range"
```

---

# PHASE 2: 3-Zone Zero-Pop-In Culling, Occlusion & Spatial Geometry Batching

### Task 7: Safe `CULL_BACK` Audit & City Facade Shader Streamlining

**Files:**
- Create: `tools/audit_city_materials.gd`
- Modify: `scripts/core/environment_material_enhancer.gd:60-122`

**Interfaces:**
- Produces: Verified safe `CULL_BACK` allowlist/exclusion logic in `EnvironmentMaterialEnhancer` (`alphaMode=BLEND` glass & thin prop surfaces stay `CULL_DISABLED`; solid tower/road structures enable `CULL_BACK`; building glass avoids expensive dual-lobe `clearcoat` while retaining full reflection).

- [x] **Step 1: Write & run `tools/audit_city_materials.gd` to classify `Untitled.glb` materials**

```gdscript
@tool
extends SceneTree

func _init() -> void:
	var ps := load("res://assets/models/environment/city_map/source/Untitled.glb") as PackedScene
	var root := ps.instantiate() as Node3D
	var stats := {}
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.mesh:
			continue
		var a := mi.mesh.get_aabb()
		var min_dim := minf(a.size.x, minf(a.size.y, a.size.z))
		var is_prop := mi.name.begins_with("prop_") or mi.name.begins_with("chevron")
		for s in range(mi.mesh.get_surface_count()):
			var sm := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if not sm:
				continue
			var key := sm.resource_name
			if not stats.has(key):
				stats[key] = {"count": 0, "prop_hits": 0, "thin_hits": 0, "trans": sm.transparency}
			stats[key]["count"] += 1
			if is_prop:
				stats[key]["prop_hits"] += 1
			if min_dim < 0.08:
				stats[key]["thin_hits"] += 1
	for k in stats.keys():
		var st: Dictionary = stats[k]
		if st["trans"] != BaseMaterial3D.TRANSPARENCY_DISABLED or st["prop_hits"] > 0 or st["thin_hits"] > 0:
			print("KEEP_DOUBLE_SIDED candidate: ", k, " -> ", st)
	root.free()
	quit(0)
```
Run `tools/audit_city_materials.gd` and inspect any printed candidates (note materials with `trans != DISABLED`, `prop_hits > 0`, or `thin_hits > 0` so they are never backface-culled!).

- [x] **Step 2: Update `scripts/core/environment_material_enhancer.gd` safely**

In `EnvironmentMaterialEnhancer`:
1. Keep `Untitled_Image_49.png` / `Untitled_Image_72.png` → `asphalt_aaa.gdshader` 100% unchanged.
2. Add `_can_use_backface_cull(sm: StandardMaterial3D, mi: MeshInstance3D) -> bool`: returns `false` if `sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED`, if `mi.name.begins_with("prop_")`, or if material name matches any thin/transparent candidate from Step 1; otherwise returns `true` and sets `out.cull_mode = BaseMaterial3D.CULL_BACK`. (Include `cull_safe` in cache key `"%d:%s" % [sm.get_instance_id(), "cull_back" if cull_safe else "cull_off"]` so cached materials stay distinct!).
3. On reflective glass skyscraper facades (`sm.metallic >= 0.5 and sm.roughness <= 0.15`), remove extra `clearcoat_enabled = true` lobe on buildings (`out.clearcoat_enabled = false`, `out.roughness = 0.055`, `out.metallic = maxf(sm.metallic, 0.74)`, `out.metallic_specular = 0.94`) to retain crisp HDR reflections without dual-specular PBR shader cost across skyscrapers.

- [x] **Step 3: Verify scene & visual parity on `HomeScreen` / `RaceTrack3D`, then commit**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/audit_city_materials.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_racetrack.gd --quit
```

```bash
git add tools/audit_city_materials.gd scripts/core/environment_material_enhancer.gd
git commit -m "perf: enable audited backface culling on solid city blocks and streamline building shaders"
```

---

### Task 8 & Task 9: Baked `ArrayOccluder3D` + Spatial Sector Chunking (`city_map_optimized.scn`)

**Files:**
- Create: `tools/build_optimized_city_map.gd`
- Create: `assets/models/environment/city_map/city_map_optimized.scn` (binary `PackedScene` for fast boot & compact size)
- Modify: `project.godot` (`occlusion_culling/use_occlusion_culling=true` under `[rendering]`)
- Modify: `scenes/race/RaceTrack3D.tscn:5, 320-321`
- Modify: `scenes/main/home_screen.tscn:5, 55-56`
- Test: `tools/test_city_optimization.gd`, `tools/verify_racetrack.gd`, `tools/verify_collision_system.gd`

**Interfaces:**
- Consumes: `assets/models/environment/city_map/source/Untitled.glb` (kept 100% unmodified).
- Produces: `city_map_optimized.scn` containing:
  - Preserved `backdrop_grp_*` & `chevron_*` nodes (required by `CollisionGuard.gd`).
  - Indexed & merged `140m × 140m` spatial grid `MeshInstance3D` chunks by `(cell_x, cell_z, material_key, bucket_type)`.
  - Dedicated `small_props` chunks (`<= 8.0m` max dim) with 360° zero-pop-in `visibility_range_end = 190.0`, `visibility_range_end_margin = 20.0`, `VISIBILITY_RANGE_FADE_SELF`, and `SHADOW_CASTING_SETTING_OFF` for micro-props `<= 2.2m`.
  - Conservative `OccluderInstance3D` (`ArrayOccluder3D`, ~394 tower blocks) shrunk inward inside tall opaque `unit_*` buildings.

- [x] **Step 1: Enable engine occlusion culling in `project.godot`**

Under `[rendering]` in `project.godot`:
```ini
occlusion_culling/use_occlusion_culling=true
```

- [x] **Step 2: Write `tools/build_optimized_city_map.gd` (Spatial Chunker + Conservative `ArrayOccluder3D` Builder)**

```gdscript
@tool
extends SceneTree

## Builds res://assets/models/environment/city_map/city_map_optimized.scn from raw Untitled.glb:
## 1) Instantiates source GLB at 100x scale so AABB checks operate in true world meters (1422m x 1212m map).
## 2) Keeps backdrop_grp_* (8 nodes) & chevron_* untouched for CollisionGuard.gd.
## 3) Merges unit_* and prop_* meshes into 140m x 140m spatial grid chunks grouped by material & prop tier.
## 4) Applies 360-degree 190m hardware fade visibility_range on small props (<= 8m) and disables tiny prop shadows (<= 2.2m).
## 5) Generates conservative inward-shrunk ArrayOccluder3D boxes for thick opaque tower blocks (>= 12m tall, >= 6m thick).

const SRC_GLB := "res://assets/models/environment/city_map/source/Untitled.glb"
const OUT_SCN := "res://assets/models/environment/city_map/city_map_optimized.scn"
const CELL_SIZE := 140.0

func _is_road_mat(mat: Material) -> bool:
	if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture:
		var rp := (mat as StandardMaterial3D).albedo_texture.resource_path.to_lower()
		return rp.ends_with("untitled_image_49.png") or rp.ends_with("untitled_image_72.png")
	return false

func _append_box_occluder(verts: PackedVector3Array, idxs: PackedInt32Array, mn: Vector3, mx: Vector3) -> void:
	var base := verts.size()
	verts.append(Vector3(mn.x, mn.y, mn.z)) # 0
	verts.append(Vector3(mx.x, mn.y, mn.z)) # 1
	verts.append(Vector3(mx.x, mn.y, mx.z)) # 2
	verts.append(Vector3(mn.x, mn.y, mx.z)) # 3
	verts.append(Vector3(mn.x, mx.y, mn.z)) # 4
	verts.append(Vector3(mx.x, mx.y, mn.z)) # 5
	verts.append(Vector3(mx.x, mx.y, mx.z)) # 6
	verts.append(Vector3(mn.x, mx.y, mx.z)) # 7
	var tris := [
		0, 1, 2, 0, 2, 3, # bottom
		4, 6, 5, 4, 7, 6, # top
		0, 4, 5, 0, 5, 1, # north
		2, 6, 7, 2, 7, 3, # south
		0, 3, 7, 0, 7, 4, # west
		1, 5, 6, 1, 6, 2  # east
	]
	for t in tris:
		idxs.append(base + t)

func _merge_bucket(out_root: Node3D, bucket_name: String, items: Array, vis_end: float, no_shadow: bool) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var first_mat: Material = items[0]["mat"]
	for item in items:
		var mdt := MeshDataTool.new()
		if mdt.create_from_surface(item["mesh"], item["surf"]) != OK:
			continue
		var xf: Transform3D = item["xform"]
		var n_basis := xf.basis.inverse().transposed().orthonormalized()
		var has_uv := (mdt.get_format() & Mesh.ARRAY_FORMAT_TEX_UV) != 0
		var has_n := (mdt.get_format() & Mesh.ARRAY_FORMAT_NORMAL) != 0
		var has_t := (mdt.get_format() & Mesh.ARRAY_FORMAT_TANGENT) != 0
		var has_col := (mdt.get_format() & Mesh.ARRAY_FORMAT_COLOR) != 0
		for f in range(mdt.get_face_count()):
			for k in range(3):
				var vi := mdt.get_face_vertex(f, k)
				if has_n:
					st.set_normal((n_basis * mdt.get_vertex_normal(vi)).normalized())
				if has_t:
					var tan := mdt.get_vertex_tangent(vi)
					var tdir := (n_basis * Vector3(tan.x, tan.y, tan.z)).normalized()
					st.set_tangent(Plane(tdir.x, tdir.y, tdir.z, tan.d))
				if has_uv:
					st.set_uv(mdt.get_vertex_uv(vi))
				if has_col:
					st.set_color(mdt.get_vertex_color(vi))
				st.add_vertex(xf * mdt.get_vertex(vi))
	st.index()
	var merged := st.commit()
	if not merged or merged.get_surface_count() == 0:
		return null
	merged.surface_set_material(0, first_mat)
	var mi := MeshInstance3D.new()
	mi.name = bucket_name
	mi.mesh = merged
	if vis_end > 0.0:
		mi.visibility_range_end = vis_end
		mi.visibility_range_end_margin = 20.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if no_shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	out_root.add_child(mi)
	mi.owner = out_root
	return mi

func _init() -> void:
	var ps := load(SRC_GLB) as PackedScene
	var src := ps.instantiate() as Node3D
	# Match RaceTrack3D CityMap (100,100,100) scale so global AABB sizes are in true world meters
	src.scale = Vector3(100.0, 100.0, 100.0)
	get_root().add_child(src)
	await process_frame

	var out_root := Node3D.new()
	out_root.name = "CityMapOptimized"
	var src_inv := src.global_transform.affine_inverse()

	var buckets := {}
	var occ_verts := PackedVector3Array()
	var occ_idxs := PackedInt32Array()
	var kept_backdrop := 0
	var occ_boxes := 0

	for node in src.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var local_xf: Transform3D = src_inv * mi.global_transform
		if mi.name.begins_with("backdrop_grp_") or mi.name.begins_with("chevron"):
			var copy := mi.duplicate() as MeshInstance3D
			copy.transform = local_xf
			out_root.add_child(copy)
			copy.owner = out_root
			kept_backdrop += 1
			continue

		var raw_aabb := mi.mesh.get_aabb()
		var world_aabb := mi.global_transform * raw_aabb
		var world_center := world_aabb.get_center()
		var max_dim := maxf(world_aabb.size.x, maxf(world_aabb.size.y, world_aabb.size.z))
		var cx := int(floorf(world_center.x / CELL_SIZE))
		var cz := int(floorf(world_center.z / CELL_SIZE))

		# Conservative Occluder check for thick opaque unit_* tower blocks (world meters)
		if mi.name.begins_with("unit_") and world_aabb.size.y >= 12.0 and minf(world_aabb.size.x, world_aabb.size.z) >= 6.0:
			var sm0 := mi.mesh.surface_get_material(0) as StandardMaterial3D
			if sm0 and sm0.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not _is_road_mat(sm0):
				var local_aabb := local_xf * raw_aabb
				var w_to_l := local_aabb.size.y / maxf(world_aabb.size.y, 0.001)
				var margin_local := Vector3(2.2, 1.5, 2.2) * w_to_l
				var mn := local_aabb.position + Vector3(margin_local.x, 0.0, margin_local.z)
				var mx := local_aabb.end - margin_local
				if mx.x > mn.x and mx.y > mn.y and mx.z > mn.z:
					_append_box_occluder(occ_verts, occ_idxs, mn, mx)
					occ_boxes += 1

		var is_small_prop := mi.name.begins_with("prop_") and max_dim <= 8.0
		var is_tiny_prop := mi.name.begins_with("prop_") and max_dim <= 2.2
		for s in range(mi.mesh.get_surface_count()):
			var mat := mi.mesh.surface_get_material(s)
			if not mat:
				continue
			var tier := "tiny" if is_tiny_prop else ("prop" if is_small_prop else ("road" if _is_road_mat(mat) else "struct"))
			var key := "%s|%d|%d|%d" % [tier, cx, cz, mat.get_instance_id()]
			if not buckets.has(key):
				buckets[key] = {"tier": tier, "cx": cx, "cz": cz, "mat": mat, "items": []}
			buckets[key]["items"].append({"mesh": mi.mesh, "surf": s, "xform": local_xf, "mat": mat})

	var chunk_count := 0
	for k in buckets.keys():
		var b: Dictionary = buckets[k]
		var vis_end := 190.0 if (b["tier"] == "prop" or b["tier"] == "tiny") else 0.0
		var no_sh := (b["tier"] == "tiny")
		var chunk_name := "Chunk_%s_%d_%d_%d" % [b["tier"], b["cx"], b["cz"], chunk_count]
		if _merge_bucket(out_root, chunk_name, b["items"], vis_end, no_sh) != null:
			chunk_count += 1

	if not occ_idxs.is_empty():
		var occ := ArrayOccluder3D.new()
		occ.set_arrays(occ_verts, occ_idxs)
		var oi := OccluderInstance3D.new()
		oi.name = "CityTowerOccluders"
		oi.occluder = occ
		out_root.add_child(oi)
		oi.owner = out_root

	var packed := PackedScene.new()
	packed.pack(out_root)
	var err := ResourceSaver.save(packed, OUT_SCN)
	print("Built %s | backdrop_kept=%d | chunks=%d | occluder_boxes=%d | err=%d" % [OUT_SCN, kept_backdrop, chunk_count, occ_boxes, err])
	out_root.free()
	src.free()
	quit(0 if err == OK else 1)
```

- [x] **Step 3: Swap scene `ExtResource` references in `RaceTrack3D.tscn` & `home_screen.tscn`**

Update `ExtResource("3_siyt7")` in `scenes/race/RaceTrack3D.tscn:5` and `ExtResource("2_stage")` in `scenes/main/home_screen.tscn:5` to:
`path="res://assets/models/environment/city_map/city_map_optimized.scn"`
Keep node names (`CityMap` and `Stage`) and transforms (`(100,100,100)` / showroom transform) identical!

- [x] **Step 4: Write & run structural test `tools/test_city_optimization.gd`**

```gdscript
extends SceneTree

func _init() -> void:
	var ps := load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	var track := ps.instantiate()
	get_root().add_child(track)
	await process_frame
	var cm := track.get_node_or_null("CityMap")
	assert(cm != null, "CityMap missing")
	var meshes := cm.find_children("*", "MeshInstance3D", true, false)
	var occs := cm.find_children("*", "OccluderInstance3D", true, false)
	assert(meshes.size() < 260, "Expected batched CityMap < 260 meshes, got %d" % meshes.size())
	assert(occs.size() >= 1, "Expected OccluderInstance3D inside CityMap")
	var road_shaders := 0
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi.get_surface_override_material(0) is ShaderMaterial:
			road_shaders += 1
	assert(road_shaders >= 1, "Expected asphalt ShaderMaterial on road chunks")
	assert(track.get_node_or_null("TrackColliders/BackdropRoadCollision") != null, "CollisionGuard must preserve BackdropRoadCollision")
	print("PASS: CityMap optimized -> meshes=%d occluders=%d road_shaders=%d" % [meshes.size(), occs.size(), road_shaders])
	track.queue_free()
	quit(0)
```

Run build & tests:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/build_optimized_city_map.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_city_optimization.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_racetrack.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_collision_system.gd --quit
```

- [x] **Step 5: Commit**

```bash
git add project.godot tools/build_optimized_city_map.gd assets/models/environment/city_map/city_map_optimized.scn scenes/race/RaceTrack3D.tscn scenes/main/home_screen.tscn tools/test_city_optimization.gd
git commit -m "perf: bake city spatial grid chunks, 360-near-ring props, and ArrayOccluder3D"
```

---

### Task 10: High-Poly Vehicle Interior Shadow & Distance Separation

**Files:**
- Modify: `vehicles/core/VehicleMaterialEnhancer.gd:139-145, 548-566`
- Test: `tools/test_car_interior_cull.gd` + `tools/verify_all_cars.gd`

**Interfaces:**
- Consumes: `VehicleMaterialEnhancer._is_interior(id_lower, m_name, mat_name)`.
- Produces: Interior-only sub-meshes skip redundant shadow casting (`SHADOW_CASTING_SETTING_OFF`) and fade out past `90m` (`120m` for open/crew vehicles like `angkot_dki`) without touching body shell, glass, tires, rims, or lights.

- [x] **Step 1: Write failing test `tools/test_car_interior_cull.gd`**

```gdscript
extends SceneTree

func _init() -> void:
	var enhancer := load("res://vehicles/core/VehicleMaterialEnhancer.gd")
	var seltos := (load("res://assets/models/cars/car_kia_seltos.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(seltos)
	enhancer.enhance_vehicle_materials("kia_seltos", seltos, Color.WHITE)
	var interior_shadow_off := 0
	var exterior_shadow_on := 0
	for n in seltos.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name.to_lower().contains("seat"):
			assert(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Seat mesh should not cast shadows")
			assert(mi.visibility_range_end >= 85.0, "Closed cabin interior should cull past ~90m")
			interior_shadow_off += 1
		elif mi.name.to_lower().contains("carpaint"):
			assert(mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Body shell must still cast shadow")
			assert(mi.visibility_range_end == 0.0, "Body shell must never cull")
			exterior_shadow_on += 1
	assert(interior_shadow_off > 0 and exterior_shadow_on > 0)
	print("PASS: interior_shadow_off=%d exterior_shadow_on=%d" % [interior_shadow_off, exterior_shadow_on])
	seltos.free()
	quit(0)
```

- [x] **Step 2: Run test to verify failure**

```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_car_interior_cull.gd --quit
```

- [x] **Step 3: Implement pure-interior shadow & distance culling in `vehicles/core/VehicleMaterialEnhancer.gd`**

Inside the `for m in meshes:` loop (`VehicleMaterialEnhancer.gd:139-175`), track whether all surfaces on `mi` are interior (`var all_interior := true`):
- Whenever a non-interior surface is handled (or skipped), set `all_interior = false`.
- After the `for s in range(mi.mesh.get_surface_count()):` loop completes, if `all_interior`:
  ```gdscript
  mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  if id_lower == "angkot_dki":
      mi.visibility_range_end = 120.0
  elif id_lower != "porsche_carrera_gt":
      mi.visibility_range_end = 90.0
  ```

- [x] **Step 4: Run verification tests & commit**

```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_car_interior_cull.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_all_cars.gd --quit
```

```bash
git add vehicles/core/VehicleMaterialEnhancer.gd tools/test_car_interior_cull.gd
git commit -m "perf: skip redundant interior shadow passes and cull distant closed-cabin car meshes"
```

---

### Task 11: Final Phase 2 Benchmark, 360° Rapid-Orbit Parity Check & Regression Gate

**Files:**
- Run: `tools/benchmark_gpu.gd -- --tag=phase2`
- Run: `tools/verify_racetrack.gd`, `tools/verify_collision_system.gd`, `tools/verify_all_cars.gd`, `tools/test_fps_cap.gd`, `tools/test_quality_profile.gd`, `tools/test_city_optimization.gd`

- [x] **Step 1: Run complete Phase 2 Benchmark & capture final screenshots**

Run:
```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --path . --script tools/benchmark_gpu.gd -- --tag=phase2
```

- [x] **Step 2: Visually compare `docs/validation/perf_baseline/*.png` vs `docs/validation/perf_phase2/*.png`**

Open all PNGs with `read_file` and verify side-by-side:
- Zero missing buildings / zero backface holes / zero pop-in on rapid 180° orbit spin.
- Road asphalt detail, reflections, sunset clouds/sun disc, car clearcoat paint, and shadows are equal or sharper.
- Compare `[BENCH:baseline:*]` vs `[BENCH:phase1:*]` vs `[BENCH:phase2:*]` metrics (GPU `ms`, Draw Calls, Primitives, VRAM) and verify target 60 FPS GPU headroom achieved.

- [x] **Step 3: Run full automated suite**

```powershell
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_racetrack.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_collision_system.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/verify_all_cars.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_fps_cap.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_quality_profile.gd --quit
& "C:\Users\Pongo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script tools/test_city_optimization.gd --quit
```
Expected: All 6 test scripts exit 0 cleanly with 0 leaks/anomalies.
