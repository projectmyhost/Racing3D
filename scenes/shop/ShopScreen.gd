extends Control

@onready var back_button: RaceButton = %BackButton
@onready var coins_label: Label = %CoinsLabel
@onready var diamonds_label: Label = %DiamondsLabel

@onready var tab_all: Button = %TabAll
@onready var tab_paints: Button = %TabPaints
@onready var tab_decals: Button = %TabDecals
@onready var tab_wheels: Button = %TabWheels
@onready var tab_bundles: Button = %TabBundles

@onready var items_grid: GridContainer = %ItemsGrid

const SHOP_ITEMS: Array[Dictionary] = [
	# Paints
	{
		"id": "silver_red",
		"category": "paint",
		"name": "Silver Red Standard",
		"price": 0,
		"color": Color("#E0E5EC"),
		"accent_color": Color("#C83B43"),
		"desc": "Classic silver factory finish with crimson racing accents."
	},
	{
		"id": "racing_yellow",
		"category": "paint",
		"name": "Racing Yellow",
		"price": 600,
		"color": Color("#FFB51B"),
		"accent_color": Color("#1B1C22"),
		"desc": "High-visibility competition yellow. Stand out at the apex."
	},
	{
		"id": "crimson_red",
		"category": "paint",
		"name": "Crimson Red",
		"price": 800,
		"color": Color("#C83B43"),
		"accent_color": Color("#FFFFFF"),
		"desc": "Furious crimson red gloss finish with brilliant contrast."
	},
	{
		"id": "royal_blue",
		"category": "paint",
		"name": "Royal Blue",
		"price": 1000,
		"color": Color("#2662D9"),
		"accent_color": Color("#FFB51B"),
		"desc": "Deep royal metallic blue with electric undertones."
	},
	{
		"id": "stealth_black",
		"category": "paint",
		"name": "Stealth Black",
		"price": 1200,
		"color": Color("#1A1B22"),
		"accent_color": Color("#C83B43"),
		"desc": "Ultra-matte stealth black finish for covert night runs."
	},
	{
		"id": "emerald_green",
		"category": "paint",
		"name": "Emerald Green",
		"price": 1500,
		"color": Color("#249E5A"),
		"accent_color": Color("#FFB51B"),
		"desc": "British racing inspired deep emerald green pearl coat."
	},
	# Decals
	{
		"id": "stripe_01",
		"category": "decal",
		"name": "Twin Racing Stripes",
		"price": 0,
		"image": "res://assets/art/cars/decal_stripes.png",
		"desc": "Dual center racing stripes with competition roundel #07."
	},
	{
		"id": "flames_02",
		"category": "decal",
		"name": "Flame Surge Livery",
		"price": 1200,
		"image": "res://assets/art/cars/decal_flame.png",
		"desc": "Aggressive aerodynamic flame surge along the wheel arches."
	},
	{
		"id": "checkered_03",
		"category": "decal",
		"name": "Checkered Apex",
		"price": 1800,
		"image": "res://assets/art/cars/decal_checkered.png",
		"desc": "Victory checkered flag motif spanning rear quarters."
	},
	# Wheels
	{
		"id": "sport_01",
		"category": "wheel",
		"name": "Sport Star 5-Spoke",
		"price": 0,
		"image": "res://assets/art/cars/wheel_sport.png",
		"desc": "Forged 5-spoke lightweight alloys with red brake calipers."
	},
	{
		"id": "forged_gold",
		"category": "wheel",
		"name": "Aero Turbofan Gold",
		"price": 2000,
		"image": "res://assets/art/cars/wheel_aero.png",
		"desc": "Aerodynamic turbofan rims with anodized gold perimeter ring."
	},
	# Bundle
	{
		"id": "starter_bundle",
		"category": "bundle",
		"name": "Apex Starter Bundle",
		"price": 3000,
		"image": "res://assets/art/icons/icon_gift.png",
		"items": ["royal_blue", "flames_02", "forged_gold"],
		"desc": "Champion Pack: Unlocks Royal Blue paint, Flame Surge decal, and Aero Turbofan Gold wheels at a huge discount!"
	}
]

var _current_filter: String = "all"

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	tab_all.pressed.connect(func(): _set_filter("all"))
	tab_paints.pressed.connect(func(): _set_filter("paint"))
	tab_decals.pressed.connect(func(): _set_filter("decal"))
	tab_wheels.pressed.connect(func(): _set_filter("wheel"))
	tab_bundles.pressed.connect(func(): _set_filter("bundle"))
	
	if has_node("/root/SaveManager"):
		SaveManager.currency_changed.connect(_update_currency_display)
		SaveManager.customization_changed.connect(_refresh_items_grid)
	
	_update_currency_display()
	_update_tab_styles()
	_refresh_items_grid()

func _update_currency_display() -> void:
	if has_node("/root/SaveManager"):
		coins_label.text = SaveManager.format_currency(SaveManager.get_coins())
		diamonds_label.text = SaveManager.format_currency(SaveManager.get_diamonds())
	else:
		coins_label.text = "12,750"
		diamonds_label.text = "120"

func _set_filter(filter: String) -> void:
	_current_filter = filter
	_update_tab_styles()
	_refresh_items_grid()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _update_tab_styles() -> void:
	var tabs = [
		{"btn": tab_all, "id": "all"},
		{"btn": tab_paints, "id": "paint"},
		{"btn": tab_decals, "id": "decal"},
		{"btn": tab_wheels, "id": "wheel"},
		{"btn": tab_bundles, "id": "bundle"}
	]
	for t in tabs:
		var btn = t.btn as Button
		var is_active = (t.id == _current_filter)
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		if is_active:
			sb.bg_color = Color(1.0, 0.709, 0.106, 1.0)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.953, 0.416, 0.239, 1.0)
			btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.11, 1.0))
		else:
			sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
			btn.add_theme_color_override("font_color", Color(0.956, 0.949, 0.949, 1.0))
		btn.add_theme_stylebox_override("normal", sb)

func _refresh_items_grid() -> void:
	for child in items_grid.get_children():
		child.queue_free()
	
	for item in SHOP_ITEMS:
		if _current_filter != "all" and item.category != _current_filter:
			continue
		
		var card = _create_item_card(item)
		items_grid.add_child(card)

func _create_item_card(item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(350, 190)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.141, 0.149, 0.227, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.204, 0.212, 0.306, 1.0)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Top row: Preview + Title/Category + Price
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	vbox.add_child(top_row)
	
	# Preview thumbnail
	var thumb_box = PanelContainer.new()
	thumb_box.custom_minimum_size = Vector2(72, 72)
	var thumb_sb = StyleBoxFlat.new()
	thumb_sb.bg_color = Color(0.09, 0.10, 0.16, 1.0)
	thumb_sb.border_width_left = 2
	thumb_sb.border_width_top = 2
	thumb_sb.border_width_right = 2
	thumb_sb.border_width_bottom = 2
	thumb_sb.border_color = Color(0.25, 0.26, 0.38, 0.8)
	thumb_sb.corner_radius_top_left = 6
	thumb_sb.corner_radius_top_right = 6
	thumb_sb.corner_radius_bottom_right = 6
	thumb_sb.corner_radius_bottom_left = 6
	thumb_box.add_theme_stylebox_override("panel", thumb_sb)
	
	if item.category == "paint":
		var color_rect = ColorRect.new()
		color_rect.color = item.color
		color_rect.custom_minimum_size = Vector2(56, 56)
		color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb_box.add_child(color_rect)
	elif item.has("image") and ResourceLoader.exists(item.image):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(item.image)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(64, 64)
		thumb_box.add_child(tex_rect)
	
	top_row.add_child(thumb_box)
	
	# Item details
	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	top_row.add_child(details)
	
	var cat_label = Label.new()
	cat_label.text = item.category.to_upper()
	cat_label.add_theme_color_override("font_color", Color(1.0, 0.709, 0.106, 1.0))
	cat_label.add_theme_font_size_override("font_size", 12)
	details.add_child(cat_label)
	
	var title_label = Label.new()
	title_label.text = item.name
	title_label.add_theme_color_override("font_color", Color(0.957, 0.949, 0.949, 1.0))
	title_label.add_theme_font_size_override("font_size", 16)
	details.add_child(title_label)
	
	var price_label = Label.new()
	if item.price == 0:
		price_label.text = "FREE / DEFAULT"
		price_label.add_theme_color_override("font_color", Color(0.384, 0.773, 0.541, 1.0))
	else:
		price_label.text = "🪙 %s COINS" % (SaveManager.format_currency(item.price) if has_node("/root/SaveManager") else str(item.price))
		price_label.add_theme_color_override("font_color", Color(1.0, 0.709, 0.106, 1.0))
	price_label.add_theme_font_size_override("font_size", 14)
	details.add_child(price_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item.desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.659, 0.663, 0.722, 1.0))
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(desc_label)
	
	# Action button
	var btn = RaceButton.new()
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_vertical = Control.SIZE_SHRINK_END
	
	var is_owned = _is_item_owned(item)
	var is_equipped = _is_item_equipped(item)
	
	if item.category == "bundle":
		if is_owned:
			btn.text = "✓ BUNDLE UNLOCKED"
			btn.disabled = true
			btn.is_primary = false
		else:
			btn.text = "BUY BUNDLE // 🪙 %s" % (SaveManager.format_currency(item.price) if has_node("/root/SaveManager") else str(item.price))
			btn.is_primary = true
			btn.pressed.connect(func(): _buy_bundle(item))
	else:
		if is_equipped:
			btn.text = "● EQUIPPED"
			btn.disabled = true
			btn.is_primary = false
		elif is_owned:
			btn.text = "EQUIP"
			btn.is_primary = false
			btn.pressed.connect(func(): _equip_item(item))
		else:
			btn.text = "BUY // 🪙 %s" % (SaveManager.format_currency(item.price) if has_node("/root/SaveManager") else str(item.price))
			btn.is_primary = true
			btn.pressed.connect(func(): _buy_item(item))
	
	vbox.add_child(btn)
	return card

func _is_item_owned(item: Dictionary) -> bool:
	if not has_node("/root/SaveManager"):
		return item.price == 0
	
	match item.category:
		"paint":
			return SaveManager.is_paint_owned(item.id)
		"decal":
			return SaveManager.is_decal_owned(item.id)
		"wheel":
			return SaveManager.is_wheel_owned(item.id)
		"bundle":
			for itm_id in item.items:
				if not (SaveManager.is_paint_owned(itm_id) or SaveManager.is_decal_owned(itm_id) or SaveManager.is_wheel_owned(itm_id)):
					return false
			return true
	return false

func _is_item_equipped(item: Dictionary) -> bool:
	if not has_node("/root/SaveManager"):
		return false
	var cust = SaveManager.get_customization()
	match item.category:
		"paint":
			return cust.get("paint_id") == item.id
		"decal":
			return cust.get("decal_id") == item.id
		"wheel":
			return cust.get("wheel_id") == item.id
	return false

func _buy_item(item: Dictionary) -> void:
	if not has_node("/root/SaveManager"):
		return
	
	var price = int(item.price)
	var coins = SaveManager.get_coins()
	if coins >= price:
		var spent = SaveManager.spend_coins(price)
		if spent:
			match item.category:
				"paint":
					SaveManager.unlock_paint(item.id)
					SaveManager.set_paint(item.id)
				"decal":
					SaveManager.unlock_decal(item.id)
					SaveManager.set_decal(item.id)
				"wheel":
					SaveManager.unlock_wheel(item.id)
					SaveManager.set_wheel(item.id)
			
			if has_node("/root/ToastManager"):
				ToastManager.show_success("Purchased & equipped %s!" % item.name)
			_refresh_items_grid()
			_update_currency_display()
	else:
		var missing = price - coins
		if has_node("/root/ToastManager"):
			ToastManager.show_warning("Need %s more coins!" % SaveManager.format_currency(missing))

func _buy_bundle(bundle_item: Dictionary) -> void:
	if not has_node("/root/SaveManager"):
		return
	
	var price = int(bundle_item.price)
	var coins = SaveManager.get_coins()
	if coins >= price:
		var spent = SaveManager.spend_coins(price)
		if spent:
			SaveManager.unlock_paint("royal_blue")
			SaveManager.unlock_decal("flames_02")
			SaveManager.unlock_wheel("forged_gold")
			
			if has_node("/root/ToastManager"):
				ToastManager.show_success("Unlocked Apex Starter Bundle!")
			_refresh_items_grid()
			_update_currency_display()
	else:
		var missing = price - coins
		if has_node("/root/ToastManager"):
			ToastManager.show_warning("Need %s more coins for bundle!" % SaveManager.format_currency(missing))

func _equip_item(item: Dictionary) -> void:
	if not has_node("/root/SaveManager"):
		return
	
	match item.category:
		"paint":
			SaveManager.set_paint(item.id)
		"decal":
			SaveManager.set_decal(item.id)
		"wheel":
			SaveManager.set_wheel(item.id)
	
	if has_node("/root/ToastManager"):
		ToastManager.show_success("Equipped %s!" % item.name)
	_refresh_items_grid()

func _on_back_pressed() -> void:
	if has_node("/root/Navigation"):
		Navigation.pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
