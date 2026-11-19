extends Node

## PlayerProfile Autoload conforming to DESIGN.md Â§11.6 and Â§16.

signal profile_updated
signal currency_changed(coins: int, gems: int)

var data: PlayerProfileData

const SAVE_PATH = "user://player_profile.tres"
const DEFAULT_DATA_PATH = "res://data/player_profile.tres"
const VALID_CARS = [
	"sedan", "compact", "hatchback", "coupe", "wagon", "minivan",
	"suv", "pickup", "offroad", "sport", "mclaren",
	"kia_carnival", "kia_seltos", "porsche_carrera_gt", "porsche_mission_x",
	"angkot_dki"
]

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		data = ResourceLoader.load(SAVE_PATH) as PlayerProfileData
	elif ResourceLoader.exists(DEFAULT_DATA_PATH):
		data = ResourceLoader.load(DEFAULT_DATA_PATH) as PlayerProfileData
	
	if data == null:
		data = PlayerProfileData.new()
		data.nickname = "DiazRaditya"
		data.level = 0
		data.current_xp = 0
		data.max_xp = 250
		data.equipped_car = "sedan"
		data.unlocked_cars = ["sedan"]
		save_profile()
	else:
		var changed = false
		if data.nickname.is_empty() or data.nickname == "Player" or data.nickname == "diaz":
			data.nickname = "DiazRaditya"
			changed = true
		if data.level == 12:
			data.level = 0
			data.current_xp = 0
			data.max_xp = 250
			changed = true
		if not (data.equipped_car in VALID_CARS):
			data.equipped_car = "sedan"
			changed = true
		# Filter unlocked cars to only valid car pack models
		var valid_unlocked: Array[String] = []
		for c in data.unlocked_cars:
			if c in VALID_CARS and not (c in valid_unlocked):
				valid_unlocked.append(c)
		if not ("sedan" in valid_unlocked):
			valid_unlocked.append("sedan")
		if not ("angkot_dki" in valid_unlocked):
			valid_unlocked.append("angkot_dki")
		if valid_unlocked.size() != data.unlocked_cars.size():
			data.unlocked_cars = valid_unlocked
			changed = true
		if changed:
			save_profile()
		
	profile_updated.emit()

func save_profile() -> void:
	if data:
		DirAccess.make_dir_recursive_absolute("user://")
		ResourceSaver.save(data, SAVE_PATH)

func set_nickname(new_name: String) -> void:
	if data and not new_name.strip_edges().is_empty():
		data.nickname = new_name.strip_edges()
		save_profile()
		profile_updated.emit()

func add_xp(xp_amount: int) -> void:
	if not data: return
	data.current_xp += xp_amount
	while data.current_xp >= data.max_xp:
		data.current_xp -= data.max_xp
		data.level += 1
		data.max_xp = int(data.max_xp * 1.35)
	save_profile()
	profile_updated.emit()

func set_avatar_image(image: Image) -> void:
	if image:
		DirAccess.make_dir_recursive_absolute("user://profile")
		var save_dest = "user://profile/avatar.png"
		image.save_png(save_dest)
		data.avatar_path = save_dest
		save_profile()
		profile_updated.emit()

func add_currency(coin_delta: int, gem_delta: int) -> void:
	if data:
		data.coins += coin_delta
		data.gems += gem_delta
		save_profile()
		currency_changed.emit(data.coins, data.gems)
		profile_updated.emit()

func has_car(car_id: String) -> bool:
	if not data: return false
	return data.unlocked_cars.has(car_id)

func buy_car(car_id: String, coins_cost: int, gems_cost: int) -> bool:
	if not data: return false
	if data.unlocked_cars.has(car_id):
		equip_car(car_id)
		return true
	if data.coins >= coins_cost and data.gems >= gems_cost:
		data.coins -= coins_cost
		data.gems -= gems_cost
		data.unlocked_cars.append(car_id)
		data.equipped_car = car_id
		save_profile()
		currency_changed.emit(data.coins, data.gems)
		profile_updated.emit()
		return true
	return false

func equip_car(car_id: String) -> void:
	if data and data.unlocked_cars.has(car_id):
		data.equipped_car = car_id
		save_profile()
		profile_updated.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			var current_mode = DisplayServer.window_get_mode()
			if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

