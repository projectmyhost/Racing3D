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
	if fps_opt.item_count != 2:
		printerr("FAIL: Expected strictly 2 FPS options (30 & 60), got %d" % fps_opt.item_count)
		home.queue_free()
		quit(1)
		return
	if Engine.max_fps <= 0 or Engine.max_fps > 60:
		printerr("FAIL: Engine.max_fps must be locked <= 60, got %d" % Engine.max_fps)
		home.queue_free()
		quit(1)
		return
	ui._on_fps_selected(3) # Attempt out-of-range unlimited index
	if Engine.max_fps <= 0 or Engine.max_fps > 60:
		printerr("FAIL: Engine.max_fps escaped 60 FPS clamp! got %d" % Engine.max_fps)
		home.queue_free()
		quit(1)
		return
	print("PASS: FPS UI count=%d, Engine.max_fps=%d" % [fps_opt.item_count, Engine.max_fps])
	home.queue_free()
	quit(0)
