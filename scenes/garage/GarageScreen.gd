extends Control

@onready var back_button: RaceButton = %BackButton
@onready var prev_car_button: RaceButton = %PrevCarButton
@onready var next_car_button: RaceButton = %NextCarButton
@onready var action_button: RaceButton = %ActionButton

@onready var car_preview: TextureRect = %CarPreview
@onready var car_name_label: Label = %CarNameLabel
@onready var car_class_label: Label = %CarClassLabel
@onready var car_desc_label: Label = %CarDescLabel
@onready var ownership_badge: Label = %OwnershipBadge

@onready var speed_bar: ProgressBar = %SpeedBar
@onready var speed_val_label: Label = %SpeedValLabel
@onready var accel_bar: ProgressBar = %AccelBar
@onready var accel_val_label: Label = %AccelValLabel
@onready var handling_bar: ProgressBar = %HandlingBar
@onready var handling_val_label: Label = %HandlingValLabel

@onready var coins_label: Label = %CoinsLabel
@onready var diamonds_label: Label = %DiamondsLabel
@onready var car_list_container: HBoxContainer = %CarListContainer

const CAR_DATABASE: Array[Dictionary] = [
	{
		"id": "starter_gt",
		"name": "Starter GT",
		"class": "CLASS C // BALANCED COUPE",
		"price": 0,
		"speed_val": "180 KM/H",
		"speed_pct": 70,
		"accel_val": "4.2s (0-100)",
		"accel_pct": 65,
		"handling_val": "75%",
		"handling_pct": 75,
		"desc": "Rear-wheel-drive club sport coupe. Responsive handling with predictable turn-in and excellent balance for rookie racers.",
		"image": "res://assets/art/cars/car_starter_gt.png"
	},
	{
		"id": "apex_cruiser",
		"name": "Apex Cruiser",
		"class": "CLASS B // AERO SPEC",
		"price": 8000,
		"speed_val": "210 KM/H",
		"speed_pct": 82,
		"accel_val": "3.6s (0-100)",
		"accel_pct": 80,
		"handling_val": "85%",
		"handling_pct": 85,
		"desc": "Mid-engine track specialist with optimized downforce, carbon diffuser, and competition slick grip.",
		"image": "res://assets/art/cars/car_apex_cruiser.png"
	},
	{
		"id": "phantom_turbo",
		"name": "Phantom Turbo",
		"class": "CLASS S // TWIN-TURBO HYPERCAR",
		"price": 18000,
		"speed_val": "245 KM/H",
		"speed_pct": 95,
		"accel_val": "3.1s (0-100)",
		"accel_pct": 92,
		"handling_val": "90%",
		"handling_pct": 90,
		"desc": "All-wheel-drive twin-turbo weapon engineered for extreme top speed, razor turn-in, and lightning acceleration.",
		"image": "res://assets/art/cars/car_phantom_turbo.png"
	}
]

var _current_index: int = 0

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	prev_car_button.pressed.connect(_on_prev_car_pressed)
	next_car_button.pressed.connect(_on_next_car_pressed)
	action_button.pressed.connect(_on_action_button_pressed)
	
	if has_node("/root/SaveManager"):
		SaveManager.currency_changed.connect(_update_currency_display)
		SaveManager.car_selected.connect(func(_id): _update_car_display())
		
		# Set initial index to currently selected car
		var sel = SaveManager.get_selected_car()
		for i in range(CAR_DATABASE.size()):
			if CAR_DATABASE[i].id == sel:
				_current_index = i
				break
	
	_update_currency_display()
	_setup_car_tabs()
	_update_car_display()

func _update_currency_display() -> void:
	if has_node("/root/SaveManager"):
		coins_label.text = SaveManager.format_currency(SaveManager.get_coins())
		diamonds_label.text = SaveManager.format_currency(SaveManager.get_diamonds())
	else:
		coins_label.text = "12,750"
		diamonds_label.text = "120"

func _setup_car_tabs() -> void:
	for child in car_list_container.get_children():
		child.queue_free()
	
	for i in range(CAR_DATABASE.size()):
		var car = CAR_DATABASE[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 44)
		btn.text = car.name
		btn.focus_mode = Control.FOCUS_ALL
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		btn.add_theme_stylebox_override("normal", sb)
		
		var idx = i
		btn.pressed.connect(func(): _switch_car_index(idx))
		btn.name = "TabBtn_" + str(i)
		car_list_container.add_child(btn)

func _switch_car_index(idx: int) -> void:
	_current_index = clampi(idx, 0, CAR_DATABASE.size() - 1)
	_update_car_display()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _on_prev_car_pressed() -> void:
	_current_index = (_current_index - 1 + CAR_DATABASE.size()) % CAR_DATABASE.size()
	_update_car_display()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _on_next_car_pressed() -> void:
	_current_index = (_current_index + 1) % CAR_DATABASE.size()
	_update_car_display()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _update_car_display() -> void:
	var car = CAR_DATABASE[_current_index]
	car_name_label.text = car.name
	car_class_label.text = car.class
	car_desc_label.text = car.desc
	
	speed_val_label.text = car.speed_val
	speed_bar.value = car.speed_pct
	accel_val_label.text = car.accel_val
	accel_bar.value = car.accel_pct
	handling_val_label.text = car.handling_val
	handling_bar.value = car.handling_pct
	
	if ResourceLoader.exists(car.image):
		car_preview.texture = load(car.image)
	
	var is_owned = true
	var is_selected = false
	
	if has_node("/root/SaveManager"):
		is_owned = SaveManager.is_car_owned(car.id)
		is_selected = (SaveManager.get_selected_car() == car.id)
	
	if is_selected:
		ownership_badge.text = "● CURRENT VEHICLE"
		ownership_badge.modulate = Color(0.384, 0.773, 0.541, 1.0) # Green
		action_button.text = "ACTIVE VEHICLE"
		action_button.disabled = true
		action_button.is_primary = false
	elif is_owned:
		ownership_badge.text = "OWNED IN GARAGE"
		ownership_badge.modulate = Color(1.0, 0.709, 0.106, 1.0) # Yellow
		action_button.text = "SELECT VEHICLE"
		action_button.disabled = false
		action_button.is_primary = true
	else:
		ownership_badge.text = "LOCKED // %s COINS" % (SaveManager.format_currency(car.price) if has_node("/root/SaveManager") else str(car.price))
		ownership_badge.modulate = Color(0.953, 0.416, 0.239, 1.0) # Orange
		action_button.text = "UNLOCK // 🪙 %s" % (SaveManager.format_currency(car.price) if has_node("/root/SaveManager") else str(car.price))
		action_button.disabled = false
		action_button.is_primary = true
	
	# Update tab highlights
	for i in range(car_list_container.get_child_count()):
		var child = car_list_container.get_child(i)
		if child is Button:
			var sb = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if sb:
				if i == _current_index:
					sb.border_color = Color(1.0, 0.71, 0.11, 1.0)
					sb.border_width_left = 2
					sb.border_width_top = 2
					sb.border_width_right = 2
					sb.border_width_bottom = 2
					sb.bg_color = Color(0.20, 0.22, 0.32, 1.0)
				else:
					sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
					sb.border_width_left = 1
					sb.border_width_top = 1
					sb.border_width_right = 1
					sb.border_width_bottom = 1
					sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
				child.add_theme_stylebox_override("normal", sb)

func _on_action_button_pressed() -> void:
	var car = CAR_DATABASE[_current_index]
	if not has_node("/root/SaveManager"):
		return
	
	var is_owned = SaveManager.is_car_owned(car.id)
	
	if is_owned:
		SaveManager.select_car(car.id)
		if has_node("/root/ToastManager"):
			ToastManager.show_success("Selected %s as active vehicle!" % car.name)
		if has_node("/root/AudioManager"):
			AudioManager.play_click_sfx()
		_update_car_display()
	else:
		# Attempt purchase
		var price = int(car.price)
		var current_coins = SaveManager.get_coins()
		if current_coins >= price:
			var spent = SaveManager.spend_coins(price)
			if spent:
				SaveManager.unlock_car(car.id)
				SaveManager.select_car(car.id)
				if has_node("/root/ToastManager"):
					ToastManager.show_success("Unlocked and selected %s!" % car.name)
				if has_node("/root/AudioManager"):
					AudioManager.play_click_sfx()
				_update_car_display()
				_update_currency_display()
		else:
			var missing = price - current_coins
			if has_node("/root/ToastManager"):
				ToastManager.show_warning("Not enough coins! Need %s more coins." % SaveManager.format_currency(missing))
			if has_node("/root/AudioManager"):
				AudioManager.play_click_sfx()

func _on_back_pressed() -> void:
	if has_node("/root/Navigation"):
		Navigation.pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("steer_left"):
		_on_prev_car_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("steer_right"):
		_on_next_car_pressed()
		get_viewport().set_input_as_handled()
