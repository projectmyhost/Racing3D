extends Node

signal currency_changed
signal profile_changed
signal car_selected(car_id: String)
signal customization_changed
signal settings_changed
signal progress_updated
signal save_reset

const SAVE_PATH: String = "user://racezone_save.cfg"
const MAX_CURRENCY: int = 2000000000

# Default data schema
var default_data: Dictionary = {
	"player": {
		"name": "DiazRaditya",
		"avatar_id": "avatar_1",
		"level": 0,
		"xp": 0,
		"total_distance": 0.0
	},
	"economy": {
		"coins": 250000,
		"diamonds": 500
	},
	"garage": {
		"selected_car": "sedan",
		"owned_cars": ["sedan"]
	},
	"customize": {
		"paint_id": "silver_red",
		"decal_id": "stripe_01",
		"wheel_id": "sport_01",
		"owned_paints": ["silver_red"],
		"owned_decals": ["stripe_01"],
		"owned_wheels": ["sport_01"]
	},
	"progress": {
		"races_completed": 0,
		"wins": 0,
		"event_races_completed": 0,
		"claimed_achievements": [],
		"last_daily_claim": "",
		"daily_streak": 0,
		"claimed_welcome_gift": false,
		"read_news": []
	},
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.7,
		"sfx_volume": 0.85,
		"mute_all": false,
		"music_enabled": true,
		"ui_sfx_enabled": true,
		"window_mode": "windowed",
		"resolution": "1600x900",
		"vsync": true,
		"fps_limit": 60,
		"graphics_quality": "high",
		"ui_scale": 1.0,
		"screen_shake": true,
		"reduced_motion": false,
		"steering_sensitivity": 5,
		"control_scheme": "keyboard",
		"auto_accelerate": false,
		"show_race_tutorial": true,
		"confirm_before_leaving_race": true,
		"language": "en",
		"high_contrast": false,
		"color_assist": "off",
		"text_size": "normal"
	},
	"records": {
		"sunset_circuit": 0.0,
		"harbor_run": 0.0,
		"neon_loop": 0.0
	}
}

var current_data: Dictionary = {}

func _ready() -> void:
	load_data()

func get_default_data_copy() -> Dictionary:
	return default_data.duplicate(true)

func load_data() -> void:
	current_data = get_default_data_copy()
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		for section in config.get_sections():
			if not current_data.has(section):
				current_data[section] = {}
			for key in config.get_section_keys(section):
				current_data[section][key] = config.get_value(section, key)
	else:
		save_data()
	
	_sanitize_data()

func _sanitize_data() -> void:
	# Ensure all required sections and keys exist
	var defs = get_default_data_copy()
	for sec in defs.keys():
		if not current_data.has(sec) or typeof(current_data[sec]) != TYPE_DICTIONARY:
			current_data[sec] = defs[sec].duplicate(true)
		else:
			for k in defs[sec].keys():
				if not current_data[sec].has(k):
					current_data[sec][k] = defs[sec][k]

	# Clamp economy
	current_data.economy.coins = clampi(int(current_data.economy.coins), 0, MAX_CURRENCY)
	current_data.economy.diamonds = clampi(int(current_data.economy.diamonds), 0, MAX_CURRENCY)

func save_data() -> void:
	var config = ConfigFile.new()
	for section in current_data.keys():
		var sec_dict = current_data[section]
		if typeof(sec_dict) == TYPE_DICTIONARY:
			for key in sec_dict.keys():
				config.set_value(section, key, sec_dict[key])
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save data to %s with error %d" % [SAVE_PATH, err])

# Economy methods
func get_coins() -> int:
	return int(current_data.economy.get("coins", 0))

func get_diamonds() -> int:
	return int(current_data.economy.get("diamonds", 0))

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	var new_val = clampi(get_coins() + amount, 0, MAX_CURRENCY)
	current_data.economy.coins = new_val
	save_data()
	emit_signal("currency_changed")

func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	var cur = get_coins()
	if cur >= amount:
		current_data.economy.coins = cur - amount
		save_data()
		emit_signal("currency_changed")
		return true
	return false

func add_diamonds(amount: int) -> void:
	if amount <= 0:
		return
	var new_val = clampi(get_diamonds() + amount, 0, MAX_CURRENCY)
	current_data.economy.diamonds = new_val
	save_data()
	emit_signal("currency_changed")

func spend_diamonds(amount: int) -> bool:
	if amount <= 0:
		return true
	var cur = get_diamonds()
	if cur >= amount:
		current_data.economy.diamonds = cur - amount
		save_data()
		emit_signal("currency_changed")
		return true
	return false

func format_currency(value: int) -> String:
	var s = str(value)
	var formatted = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		formatted = s[i] + formatted
		count += 1
		if count % 3 == 0 and i > 0 and s[i - 1] != "-":
			formatted = "," + formatted
	return formatted

# Player profile methods
func get_player_name() -> String:
	return str(current_data.player.get("name", "RacerX"))

func set_player_name(new_name: String) -> bool:
	var cleaned = new_name.strip_edges()
	if cleaned.length() < 3 or cleaned.length() > 16:
		return false
	current_data.player.name = cleaned
	save_data()
	emit_signal("profile_changed")
	return true

func get_avatar_id() -> String:
	return str(current_data.player.get("avatar_id", "avatar_1"))

func set_avatar_id(new_avatar: String) -> void:
	current_data.player.avatar_id = new_avatar
	save_data()
	emit_signal("profile_changed")

func get_player_level() -> int:
	return int(current_data.player.get("level", 12))

func get_player_xp() -> int:
	return int(current_data.player.get("xp", 420))

func add_xp(amount: int) -> void:
	var xp = get_player_xp() + amount
	var lvl = get_player_level()
	while xp >= 1000:
		xp -= 1000
		lvl += 1
	current_data.player.xp = xp
	current_data.player.level = lvl
	save_data()
	emit_signal("profile_changed")

# Garage & Car selection
func get_selected_car() -> String:
	return str(current_data.garage.get("selected_car", "sedan"))

func select_car(car_id: String) -> bool:
	if is_car_owned(car_id):
		current_data.garage.selected_car = car_id
		save_data()
		emit_signal("car_selected", car_id)
		return true
	return false

func get_owned_cars() -> Array:
	return current_data.garage.get("owned_cars", ["sedan"])

func is_car_owned(car_id: String) -> bool:
	var owned = get_owned_cars()
	return car_id in owned

func unlock_car(car_id: String) -> bool:
	var owned = get_owned_cars()
	if not (car_id in owned):
		owned.append(car_id)
		current_data.garage.owned_cars = owned
		save_data()
		return true
	return false

# Customization
func get_customization() -> Dictionary:
	return current_data.get("customize", {})

func set_customization(paint_id: String, decal_id: String, wheel_id: String) -> void:
	current_data.customize.paint_id = paint_id
	current_data.customize.decal_id = decal_id
	current_data.customize.wheel_id = wheel_id
	save_data()
	emit_signal("customization_changed")

func is_paint_owned(paint_id: String) -> bool:
	var owned: Array = current_data.customize.get("owned_paints", ["silver_red"])
	return paint_id in owned

func unlock_paint(paint_id: String) -> bool:
	var owned: Array = current_data.customize.get("owned_paints", ["silver_red"])
	if not (paint_id in owned):
		owned.append(paint_id)
		current_data.customize.owned_paints = owned
		save_data()
		emit_signal("customization_changed")
		return true
	return false

func is_decal_owned(decal_id: String) -> bool:
	var owned: Array = current_data.customize.get("owned_decals", ["stripe_01"])
	return decal_id in owned

func unlock_decal(decal_id: String) -> bool:
	var owned: Array = current_data.customize.get("owned_decals", ["stripe_01"])
	if not (decal_id in owned):
		owned.append(decal_id)
		current_data.customize.owned_decals = owned
		save_data()
		emit_signal("customization_changed")
		return true
	return false

func is_wheel_owned(wheel_id: String) -> bool:
	var owned: Array = current_data.customize.get("owned_wheels", ["sport_01"])
	return wheel_id in owned

func unlock_wheel(wheel_id: String) -> bool:
	var owned: Array = current_data.customize.get("owned_wheels", ["sport_01"])
	if not (wheel_id in owned):
		owned.append(wheel_id)
		current_data.customize.owned_wheels = owned
		save_data()
		emit_signal("customization_changed")
		return true
	return false

func set_paint(paint_id: String) -> void:
	current_data.customize.paint_id = paint_id
	save_data()
	emit_signal("customization_changed")

func set_decal(decal_id: String) -> void:
	current_data.customize.decal_id = decal_id
	save_data()
	emit_signal("customization_changed")

func set_wheel(wheel_id: String) -> void:
	current_data.customize.wheel_id = wheel_id
	save_data()
	emit_signal("customization_changed")

# Settings methods
func get_setting(key: String, default_val = null):
	if current_data.has("settings") and current_data["settings"] is Dictionary and current_data["settings"].has(key):
		return current_data["settings"][key]
	if default_data.has("settings") and default_data["settings"] is Dictionary and default_data["settings"].has(key):
		return default_data["settings"][key]
	return default_val

func set_setting(key: String, value, auto_save: bool = true) -> void:
	if not current_data.has("settings") or not (current_data["settings"] is Dictionary):
		current_data["settings"] = default_data["settings"].duplicate(true)
	current_data["settings"][key] = value
	if auto_save:
		save_data()
	emit_signal("settings_changed")

# Records
func get_best_time(track_id: String) -> float:
	return float(current_data.records.get(track_id, 0.0))

func set_best_time(track_id: String, time_sec: float) -> bool:
	var current_best = get_best_time(track_id)
	if current_best <= 0.0 or time_sec < current_best:
		current_data.records[track_id] = time_sec
		save_data()
		return true
	return false

# Progress & Achievements
func get_progress() -> Dictionary:
	return current_data.get("progress", {})

func is_achievement_claimed(ach_id: String) -> bool:
	var claimed = current_data.progress.get("claimed_achievements", [])
	return ach_id in claimed

func claim_achievement(ach_id: String, coin_reward: int) -> bool:
	var claimed = current_data.progress.get("claimed_achievements", [])
	if not (ach_id in claimed):
		claimed.append(ach_id)
		current_data.progress.claimed_achievements = claimed
		add_coins(coin_reward)
		save_data()
		emit_signal("progress_updated")
		return true
	return false

func record_race_finished(track_id: String, lap_time: float, is_win: bool, distance: float = 2.5) -> void:
	current_data.progress.races_completed = int(current_data.progress.get("races_completed", 0)) + 1
	if is_win:
		current_data.progress.wins = int(current_data.progress.get("wins", 0)) + 1
	current_data.progress.event_races_completed = int(current_data.progress.get("event_races_completed", 0)) + 1
	current_data.player.total_distance = float(current_data.player.get("total_distance", 0.0)) + distance
	set_best_time(track_id, lap_time)
	add_xp(80 if is_win else 40)
	save_data()
	emit_signal("progress_updated")

# Reset functions
func reset_to_defaults() -> void:
	# Resets settings to default only, preserving progression and inventory
	current_data.settings = default_data.settings.duplicate(true)
	save_data()
	emit_signal("settings_changed")

func reset_all_save_data() -> void:
	# Full reset wiping save file back to fresh default state
	current_data = get_default_data_copy()
	save_data()
	emit_signal("currency_changed")
	emit_signal("profile_changed")
	emit_signal("car_selected", "starter_gt")
	emit_signal("customization_changed")
	emit_signal("settings_changed")
	emit_signal("progress_updated")
	emit_signal("save_reset")
