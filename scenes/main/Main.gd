extends Control

func _ready() -> void:
	_apply_saved_settings()
	call_deferred("_navigate_to_home")

func _apply_saved_settings() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")

	# 1. Localization
	var lang = str(sm.get_setting("language", "en"))
	if has_node("/root/Localization"):
		get_node("/root/Localization").set_language(lang)

	# 2. Display / Graphics Settings
	var win_mode = str(sm.get_setting("window_mode", "windowed"))
	match win_mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	# Resolution (if windowed)
	if win_mode == "windowed":
		var res_str = str(sm.get_setting("resolution", "1600x900"))
		var parts = res_str.split("x")
		if parts.size() == 2:
			var w = int(parts[0])
			var h = int(parts[1])
			if w > 0 and h > 0:
				DisplayServer.window_set_size(Vector2i(w, h))

	# VSync
	var vsync = bool(sm.get_setting("vsync", true))
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# FPS Limit
	var fps_limit = int(sm.get_setting("fps_limit", 60))
	Engine.max_fps = fps_limit

	# 3. Audio settings
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("_sync_from_save_manager"):
			am._sync_from_save_manager()

func _navigate_to_home() -> void:
	var home_path = "res://scenes/home/HomeScreen.tscn"
	if ResourceLoader.exists(home_path):
		if has_node("/root/Navigation"):
			get_node("/root/Navigation").change_scene(home_path)
		else:
			get_tree().change_scene_to_file(home_path)
	else:
		push_warning("HomeScreen.tscn could not be found.")
