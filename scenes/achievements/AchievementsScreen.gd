extends Control

@onready var back_button: RaceButton = %BackButton
@onready var coins_label: Label = %CoinsLabel
@onready var diamonds_label: Label = %DiamondsLabel
@onready var total_claimed_label: Label = %TotalClaimedLabel
@onready var achievements_container: VBoxContainer = %AchievementsContainer

const ACHIEVEMENTS_LIST: Array[Dictionary] = [
	{
		"id": "first_lap",
		"title": "First Lap",
		"desc": "Complete your first race on any circuit.",
		"target": 1,
		"reward": 500,
		"type": "races",
		"icon": "🏁"
	},
	{
		"id": "rookie_driver",
		"title": "Rookie Driver",
		"desc": "Complete 5 races across any circuits.",
		"target": 5,
		"reward": 1500,
		"type": "races",
		"icon": "🏎"
	},
	{
		"id": "clean_run",
		"title": "Clean Run",
		"desc": "Finish a race cleanly without major collisions.",
		"target": 1,
		"reward": 1000,
		"type": "clean",
		"icon": "✨"
	},
	{
		"id": "speed_freak",
		"title": "Speed Freak",
		"desc": "Hit top speed over 200 km/h in a race.",
		"target": 1,
		"reward": 2000,
		"type": "speed",
		"icon": "⚡"
	},
	{
		"id": "collector",
		"title": "Collector",
		"desc": "Own all 3 vehicles in your garage.",
		"target": 3,
		"reward": 2500,
		"type": "cars",
		"icon": "🏆"
	},
	{
		"id": "festival_starter",
		"title": "Festival Starter",
		"desc": "Complete 3 Racing Festival event races.",
		"target": 3,
		"reward": 3000,
		"type": "event_races",
		"icon": "🎖"
	}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	if has_node("/root/SaveManager"):
		SaveManager.currency_changed.connect(_update_currency_display)
		SaveManager.progress_updated.connect(_refresh_achievements)
	
	_update_currency_display()
	_refresh_achievements()

func _update_currency_display() -> void:
	if has_node("/root/SaveManager"):
		coins_label.text = SaveManager.format_currency(SaveManager.get_coins())
		diamonds_label.text = SaveManager.format_currency(SaveManager.get_diamonds())
	else:
		coins_label.text = "12,750"
		diamonds_label.text = "120"

func _get_achievement_progress(ach: Dictionary) -> int:
	if not has_node("/root/SaveManager"):
		return 0
	
	var prog = SaveManager.get_progress()
	match ach.type:
		"races":
			return int(prog.get("races_completed", 0))
		"event_races":
			return int(prog.get("event_races_completed", 0))
		"cars":
			return SaveManager.get_owned_cars().size()
		"clean":
			return 1 if int(prog.get("races_completed", 0)) >= 1 else 0
		"speed":
			# Unlocks if player owns faster cars or completed races
			var owns_fast = SaveManager.is_car_owned("apex_cruiser") or SaveManager.is_car_owned("phantom_turbo")
			return 1 if (owns_fast or int(prog.get("races_completed", 0)) >= 2) else 0
	return 0

func _refresh_achievements() -> void:
	for child in achievements_container.get_children():
		child.queue_free()
	
	var claimed_count = 0
	
	for ach in ACHIEVEMENTS_LIST:
		var current_val = _get_achievement_progress(ach)
		var is_claimed = false
		if has_node("/root/SaveManager"):
			is_claimed = SaveManager.is_achievement_claimed(ach.id)
		
		if is_claimed:
			claimed_count += 1
		
		var card = _create_achievement_card(ach, current_val, is_claimed)
		achievements_container.add_child(card)
	
	total_claimed_label.text = "%d / %d COMPLETED" % [claimed_count, ACHIEVEMENTS_LIST.size()]

func _create_achievement_card(ach: Dictionary, current_val: int, is_claimed: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 95)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.141, 0.149, 0.227, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	
	var is_ready = (current_val >= ach.target and not is_claimed)
	if is_ready:
		sb.border_color = Color(1.0, 0.709, 0.106, 1.0)
	elif is_claimed:
		sb.border_color = Color(0.20, 0.50, 0.35, 0.8)
	else:
		sb.border_color = Color(0.204, 0.212, 0.306, 1.0)
	
	card.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Icon box
	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(60, 60)
	var icon_sb = StyleBoxFlat.new()
	icon_sb.bg_color = Color(0.10, 0.11, 0.18, 1.0)
	icon_sb.border_width_left = 2
	icon_sb.border_width_top = 2
	icon_sb.border_width_right = 2
	icon_sb.border_width_bottom = 2
	icon_sb.border_color = Color(1.0, 0.709, 0.106, 0.6) if (is_ready or is_claimed) else Color(0.25, 0.26, 0.38, 0.6)
	icon_sb.corner_radius_top_left = 6
	icon_sb.corner_radius_top_right = 6
	icon_sb.corner_radius_bottom_right = 6
	icon_sb.corner_radius_bottom_left = 6
	icon_box.add_theme_stylebox_override("panel", icon_sb)
	
	var icon_lbl = Label.new()
	icon_lbl.text = ach.icon
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_box.add_child(icon_lbl)
	hbox.add_child(icon_box)
	
	# Text & progress info
	var info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 6)
	hbox.add_child(info_box)
	
	var title_row = HBoxContainer.new()
	info_box.add_child(title_row)
	
	var title_lbl = Label.new()
	title_lbl.text = ach.title
	title_lbl.add_theme_color_override("font_color", Color(0.957, 0.949, 0.949, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_row.add_child(title_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	
	var reward_lbl = Label.new()
	reward_lbl.text = "🪙 +%s COINS" % (SaveManager.format_currency(ach.reward) if has_node("/root/SaveManager") else str(ach.reward))
	reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.709, 0.106, 1.0))
	reward_lbl.add_theme_font_size_override("font_size", 16)
	title_row.add_child(reward_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = ach.desc
	desc_lbl.add_theme_color_override("font_color", Color(0.659, 0.663, 0.722, 1.0))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	info_box.add_child(desc_lbl)
	
	# Progress Bar row
	var prog_row = HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 12)
	info_box.add_child(prog_row)
	
	var pbar = ProgressBar.new()
	pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbar.custom_minimum_size = Vector2(0, 14)
	pbar.max_value = float(ach.target)
	pbar.value = float(clampi(current_val, 0, ach.target))
	pbar.show_percentage = false
	prog_row.add_child(pbar)
	
	var ptext = Label.new()
	ptext.text = "%d / %d" % [clampi(current_val, 0, ach.target), ach.target]
	ptext.add_theme_color_override("font_color", Color(0.659, 0.663, 0.722, 1.0))
	ptext.add_theme_font_size_override("font_size", 13)
	prog_row.add_child(ptext)
	
	# Action button
	var btn = RaceButton.new()
	btn.custom_minimum_size = Vector2(170, 48)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	if is_claimed:
		btn.text = "✓ CLAIMED"
		btn.disabled = true
		btn.is_primary = false
	elif is_ready:
		btn.text = "CLAIM REWARD"
		btn.is_primary = true
		btn.pressed.connect(func(): _claim_achievement(ach))
	else:
		btn.text = "LOCKED"
		btn.disabled = true
		btn.is_primary = false
	
	hbox.add_child(btn)
	return card

func _claim_achievement(ach: Dictionary) -> void:
	if not has_node("/root/SaveManager"):
		return
	
	var claimed = SaveManager.claim_achievement(ach.id, ach.reward)
	if claimed:
		if has_node("/root/ToastManager"):
			ToastManager.show_success("Claimed %s coins for '%s'!" % [SaveManager.format_currency(ach.reward), ach.title])
		if has_node("/root/AudioManager"):
			AudioManager.play_click_sfx()
		_refresh_achievements()
		_update_currency_display()

func _on_back_pressed() -> void:
	if has_node("/root/Navigation"):
		Navigation.pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
