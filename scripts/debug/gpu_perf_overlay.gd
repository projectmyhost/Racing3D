extends CanvasLayer

## Lightweight F3-toggle performance telemetry overlay for GPU optimization verification.
## Hidden by default during normal gameplay; collects GPU frame time & draw call snapshots.

var _panel: PanelContainer
var _label: Label
var _visible_hud: bool = false
var _accum: float = 0.0
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
	if _accum < 0.25:
		return
	var s := sample_snapshot()
	var adapter := RenderingServer.get_video_adapter_name()
	_label.text = "GPU: %s\nFPS: %.0f | GPU: %.2f ms | CPU: %.2f ms\nDraws: %d | Objs: %d | Tris/Prims: %d\nVRAM: %.1f MB" % [
		adapter, s["fps"], s["gpu_ms"], s["cpu_ms"],
		s["draw_calls"], s["objects"], s["primitives"], s["vram_mb"]
	]
	_accum = 0.0
