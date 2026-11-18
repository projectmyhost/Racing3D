extends Control

@onready var back_button: RaceButton = %BackButton
@onready var apply_button: RaceButton = %ApplyButton
@onready var reset_button: RaceButton = %ResetButton
@onready var cancel_button: RaceButton = %CancelButton

@onready var car_preview: TextureRect = %CarPreview
@onready var decal_overlay: TextureRect = %DecalOverlay
@onready var wheel_preview: TextureRect = %WheelPreview
@onready var wheel_label: Label = %WheelLabel
@onready var active_car_title: Label = %ActiveCarTitle
@onready var status_notice: Label = %StatusNotice

@onready var paint_grid: HBoxContainer = %PaintGrid
@onready var decal_grid: HBoxContainer = %DecalGrid
@onready var wheel_grid: HBoxContainer = %WheelGrid

const PAINTS: Array[Dictionary] = [
	{"id": "silver_red", "name": "Silver / Red", "color": Color(0.95, 0.96, 0.98, 1.0), "modulate": Color(1.0, 1.0, 1.0, 1.0)},
	{"id": "racing_yellow", "name": "Racing Yellow", "color": Color(1.0, 0.709, 0.106, 1.0), "modulate": Color(1.0, 0.88, 0.35, 1.0)},
	{"id": "crimson_red", "name": "Crimson Red", "color": Color(0.784, 0.231, 0.263, 1.0), "modulate": Color(1.0, 0.40, 0.40, 1.0)},
	{"id": "royal_blue", "name": "Royal Blue", "color": Color(0.149, 0.384, 0.851, 1.0), "modulate": Color(0.40, 0.65, 1.0, 1.0)},
	{"id": "stealth_black", "name": "Stealth Black", "color": Color(0.11, 0.118, 0.14, 1.0), "modulate": Color(0.35, 0.35, 0.38, 1.0)},
	{"id": "emerald_green", "name": "Emerald Green", "color": Color(0.141, 0.620, 0.353, 1.0), "modulate": Color(0.40, 0.95, 0.55, 1.0)}
]

const DECALS: Array[Dictionary] = [
	{"id": "stripe_01", "name": "Twin Stripes", "path": "res://assets/art/cars/decal_stripes.png"},
	{"id": "flames_02", "name": "Flame Surge", "path": "res://assets/art/cars/decal_flame.png"},
	{"id": "checkered_03", "name": "Checkered", "path": "res://assets/art/cars/decal_checkered.png"},
	{"id": "none", "name": "Clean / None", "path": ""}
]

const WHEELS: Array[Dictionary] = [
	{"id": "sport_01", "name": "Sport Star 5-Spoke", "path": "res://assets/art/cars/wheel_sport.png"},
	{"id": "forged_gold", "name": "Aero Turbofan Gold", "path": "res://assets/art/cars/wheel_aero.png"}
]

var _pending_paint_id: String = "silver_red"
var _pending_decal_id: String = "stripe_01"
var _pending_wheel_id: String = "sport_01"

var _saved_paint_id: String = "silver_red"
var _saved_decal_id: String = "stripe_01"
var _saved_wheel_id: String = "sport_01"

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	_load_saved_customization()
	_setup_paint_swatches()
	_setup_decal_buttons()
	_setup_wheel_buttons()
	_update_car_model_preview()
	_update_visual_preview()

func _load_saved_customization() -> void:
	if has_node("/root/SaveManager"):
		var cust = SaveManager.get_customization()
		_saved_paint_id = cust.get("paint_id", "silver_red")
		_saved_decal_id = cust.get("decal_id", "stripe_01")
		_saved_wheel_id = cust.get("wheel_id", "sport_01")
	else:
		_saved_paint_id = "silver_red"
		_saved_decal_id = "stripe_01"
		_saved_wheel_id = "sport_01"
	
	_pending_paint_id = _saved_paint_id
	_pending_decal_id = _saved_decal_id
	_pending_wheel_id = _saved_wheel_id

func _update_car_model_preview() -> void:
	var selected_car = "starter_gt"
	if has_node("/root/SaveManager"):
		selected_car = SaveManager.get_selected_car()
	
	var car_path = "res://assets/art/cars/car_%s.png" % selected_car
	if ResourceLoader.exists(car_path):
		car_preview.texture = load(car_path)
	
	var names = {
		"starter_gt": "Starter GT",
		"apex_cruiser": "Apex Cruiser",
		"phantom_turbo": "Phantom Turbo"
	}
	active_car_title.text = "CUSTOMIZING: " + names.get(selected_car, "Active Vehicle").to_upper()

func _setup_paint_swatches() -> void:
	for child in paint_grid.get_children():
		child.queue_free()
	
	for paint in PAINTS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 50)
		btn.text = ""
		btn.focus_mode = Control.FOCUS_ALL
		btn.tooltip_text = paint.name
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = paint.color
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = Color(0.20, 0.22, 0.32, 1.0)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", sb)
		
		var p_id = paint.id
		btn.pressed.connect(func(): _select_paint(p_id))
		btn.name = "PaintBtn_" + p_id
		paint_grid.add_child(btn)

func _setup_decal_buttons() -> void:
	for child in decal_grid.get_children():
		child.queue_free()
	
	for decal in DECALS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 48)
		btn.text = decal.name
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
		
		var d_id = decal.id
		btn.pressed.connect(func(): _select_decal(d_id))
		btn.name = "DecalBtn_" + d_id
		decal_grid.add_child(btn)

func _setup_wheel_buttons() -> void:
	for child in wheel_grid.get_children():
		child.queue_free()
	
	for wheel in WHEELS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 48)
		btn.text = wheel.name
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
		
		var w_id = wheel.id
		btn.pressed.connect(func(): _select_wheel(w_id))
		btn.name = "WheelBtn_" + w_id
		wheel_grid.add_child(btn)

func _select_paint(paint_id: String) -> void:
	_pending_paint_id = paint_id
	_update_visual_preview()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _select_decal(decal_id: String) -> void:
	_pending_decal_id = decal_id
	_update_visual_preview()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _select_wheel(wheel_id: String) -> void:
	_pending_wheel_id = wheel_id
	_update_visual_preview()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _update_visual_preview() -> void:
	# 1. Update paint color modulation
	var mod_color = Color.WHITE
	for p in PAINTS:
		if p.id == _pending_paint_id:
			mod_color = p.modulate
			break
	car_preview.modulate = mod_color
	
	# 2. Update decal overlay
	var decal_path = ""
	for d in DECALS:
		if d.id == _pending_decal_id:
			decal_path = d.path
			break
	
	if decal_path != "" and ResourceLoader.exists(decal_path):
		decal_overlay.texture = load(decal_path)
		decal_overlay.visible = true
	else:
		decal_overlay.texture = null
		decal_overlay.visible = false
	
	# 3. Update wheel preview
	var wheel_path = ""
	var wheel_name = ""
	for w in WHEELS:
		if w.id == _pending_wheel_id:
			wheel_path = w.path
			wheel_name = w.name
			break
	
	if wheel_path != "" and ResourceLoader.exists(wheel_path):
		wheel_preview.texture = load(wheel_path)
	wheel_label.text = wheel_name
	
	# 4. Update UI button selection highlights
	_update_highlights()
	
	# 5. Check if modified
	var is_modified = (_pending_paint_id != _saved_paint_id or _pending_decal_id != _saved_decal_id or _pending_wheel_id != _saved_wheel_id)
	if is_modified:
		status_notice.text = "● PREVIEWING UNSAVED CHANGES"
		status_notice.modulate = Color(1.0, 0.709, 0.106, 1.0)
	else:
		status_notice.text = "✓ CONFIGURATION SYNCED WITH SAVE"
		status_notice.modulate = Color(0.384, 0.773, 0.541, 1.0)

func _update_highlights() -> void:
	# Paint highlights
	for child in paint_grid.get_children():
		if child is Button:
			var is_sel = (child.name == "PaintBtn_" + _pending_paint_id)
			var sb = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if sb:
				if is_sel:
					sb.border_color = Color(1.0, 0.71, 0.11, 1.0)
					sb.border_width_left = 4
					sb.border_width_top = 4
					sb.border_width_right = 4
					sb.border_width_bottom = 4
				else:
					sb.border_color = Color(0.20, 0.22, 0.32, 1.0)
					sb.border_width_left = 2
					sb.border_width_top = 2
					sb.border_width_right = 2
					sb.border_width_bottom = 2
				child.add_theme_stylebox_override("normal", sb)
	
	# Decal highlights
	for child in decal_grid.get_children():
		if child is Button:
			var is_sel = (child.name == "DecalBtn_" + _pending_decal_id)
			var sb = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if sb:
				if is_sel:
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
	
	# Wheel highlights
	for child in wheel_grid.get_children():
		if child is Button:
			var is_sel = (child.name == "WheelBtn_" + _pending_wheel_id)
			var sb = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if sb:
				if is_sel:
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

func _on_apply_pressed() -> void:
	if has_node("/root/SaveManager"):
		SaveManager.set_customization(_pending_paint_id, _pending_decal_id, _pending_wheel_id)
		_saved_paint_id = _pending_paint_id
		_saved_decal_id = _pending_decal_id
		_saved_wheel_id = _pending_wheel_id
	
	if has_node("/root/ToastManager"):
		ToastManager.show_success("Customization saved!")
	
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()
	
	_update_visual_preview()

func _on_reset_pressed() -> void:
	_pending_paint_id = _saved_paint_id
	_pending_decal_id = _saved_decal_id
	_pending_wheel_id = _saved_wheel_id
	
	if has_node("/root/ToastManager"):
		ToastManager.show_toast("Restored saved setup", 1.5, "↺")
	
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()
	
	_update_visual_preview()

func _on_cancel_pressed() -> void:
	_on_reset_pressed()
	_on_back_pressed()

func _on_back_pressed() -> void:
	if has_node("/root/Navigation"):
		Navigation.pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
