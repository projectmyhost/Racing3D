@tool
extends SceneTree

func _init():
	print("Building home_screen_ui.tscn...")
	var root = Control.new()
	root.name = "HomeScreenUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = load("res://assets/ui/theme_racing.tres")
	root.set_script(load("res://scripts/ui/home_screen_ui.gd"))
	
	var font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	var font_semi = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")
	var font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")
	
	# 1. Vignettes and legibility gradients (Â§3.1)
	var left_gradient = ColorRect.new()
	left_gradient.name = "LeftLegibilityGradient"
	left_gradient.position = Vector2(0, 0)
	left_gradient.size = Vector2(800, 1080)
	left_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Left gradient shader / soft tint
	left_gradient.color = Color(0, 0, 0, 0.18)
	root.add_child(left_gradient)
	left_gradient.owner = root
	
	var bottom_gradient = ColorRect.new()
	bottom_gradient.name = "BottomGradient"
	bottom_gradient.position = Vector2(0, 900)
	bottom_gradient.size = Vector2(1920, 180)
	bottom_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_gradient.color = Color(0, 0, 0, 0.35)
	root.add_child(bottom_gradient)
	bottom_gradient.owner = root
	
	# 2. PROFILE CARD (46, 32), size 615x122
	var profile_card = Panel.new()
	profile_card.name = "ProfileCard"
	profile_card.position = Vector2(46, 32)
	profile_card.size = Vector2(615, 122)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.082, 0.09, 0.114, 0.85) # #15171D @ 85%
	p_style.border_color = Color(0.275, 0.282, 0.314, 0.5)
	p_style.border_width_bottom = 1
	profile_card.add_theme_stylebox_override("panel", p_style)
	root.add_child(profile_card)
	profile_card.owner = root
	
	# Avatar Frame (18, 9) inside card, size 104x104
	var avatar_frame = Panel.new()
	avatar_frame.name = "AvatarFrame"
	avatar_frame.position = Vector2(18, 9)
	avatar_frame.size = Vector2(104, 104)
	var af_style = StyleBoxFlat.new()
	af_style.bg_color = Color(0.1, 0.1, 0.12, 1.0)
	af_style.border_color = Color(0.275, 0.282, 0.314, 1.0) # #464850
	af_style.border_width_left = 2
	af_style.border_width_top = 2
	af_style.border_width_right = 2
	af_style.border_width_bottom = 2
	avatar_frame.add_theme_stylebox_override("panel", af_style)
	profile_card.add_child(avatar_frame)
	avatar_frame.owner = root
	
	var avatar_rect = TextureRect.new()
	avatar_rect.name = "AvatarRect"
	avatar_rect.unique_name_in_owner = true
	avatar_rect.position = Vector2(4, 4)
	avatar_rect.size = Vector2(96, 96)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if FileAccess.file_exists("res://assets/ui/textures/tex_ui_avatar_default.png"):
		avatar_rect.texture = load("res://assets/ui/textures/tex_ui_avatar_default.png")
	avatar_frame.add_child(avatar_rect)
	avatar_rect.owner = root
	
	# Nickname Label
	var nick = Label.new()
	nick.name = "NicknameLabel"
	nick.unique_name_in_owner = true
	nick.position = Vector2(140, 14)
	nick.text = "DiazRaditya"
	nick.add_theme_font_override("font", font_semi)
	nick.add_theme_font_size_override("font_size", 28)
	nick.add_theme_color_override("font_color", Color(0.957, 0.957, 0.949, 1.0))
	profile_card.add_child(nick)
	nick.owner = root
	
	# Level Label
	var lvl = Label.new()
	lvl.name = "LevelLabel"
	lvl.unique_name_in_owner = true
	lvl.position = Vector2(140, 50)
	lvl.text = "Lv. 12"
	lvl.add_theme_font_override("font", font_reg)
	lvl.add_theme_font_size_override("font_size", 20)
	lvl.add_theme_color_override("font_color", Color(0.957, 0.957, 0.949, 0.90))
	profile_card.add_child(lvl)
	lvl.owner = root
	
	# XP Bar (track #2A2C33, fill #FFC928)
	var xp = ProgressBar.new()
	xp.name = "XPBar"
	xp.unique_name_in_owner = true
	xp.position = Vector2(140, 84)
	xp.size = Vector2(262, 14)
	xp.show_percentage = false
	xp.max_value = 1200
	xp.value = 720
	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.165, 0.173, 0.20, 1.0) # #2A2C33
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color(1.0, 0.788, 0.157, 1.0) # #FFC928
	xp.add_theme_stylebox_override("background", xp_bg)
	xp.add_theme_stylebox_override("fill", xp_fill)
	profile_card.add_child(xp)
	xp.owner = root
	
	# XP Text
	var xp_txt = Label.new()
	xp_txt.name = "XPLabel"
	xp_txt.unique_name_in_owner = true
	xp_txt.position = Vector2(415, 78)
	xp_txt.text = "720 / 1,200 XP"
	xp_txt.add_theme_font_override("font", font_reg)
	xp_txt.add_theme_font_size_override("font_size", 19)
	xp_txt.add_theme_color_override("font_color", Color(0.957, 0.957, 0.949, 1.0))
	profile_card.add_child(xp_txt)
	xp_txt.owner = root
	
	# 3. CURRENCY PILL (1481, 46), size 327x44
	var curr_pill = Panel.new()
	curr_pill.name = "CurrencyPill"
	curr_pill.position = Vector2(1481, 46)
	curr_pill.size = Vector2(327, 44)
	var cp_style = StyleBoxFlat.new()
	cp_style.bg_color = Color(0.082, 0.09, 0.114, 0.85) # #15171D @ 75%
	cp_style.border_color = Color(0.275, 0.282, 0.314, 0.7)
	cp_style.border_width_left = 1
	cp_style.border_width_top = 1
	cp_style.border_width_right = 1
	cp_style.border_width_bottom = 1
	cp_style.corner_radius_top_left = 4
	cp_style.corner_radius_top_right = 4
	cp_style.corner_radius_bottom_right = 4
	cp_style.corner_radius_bottom_left = 4
	curr_pill.add_theme_stylebox_override("panel", cp_style)
	root.add_child(curr_pill)
	curr_pill.owner = root
	
	# Coin Icon (28px)
	var coin_ico = TextureRect.new()
	coin_ico.position = Vector2(10, 8)
	coin_ico.size = Vector2(28, 28)
	coin_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_ico.texture = load("res://assets/ui/icons/ico_coin.svg")
	curr_pill.add_child(coin_ico)
	coin_ico.owner = root
	
	# Coin Label
	var coin_lbl = Label.new()
	coin_lbl.name = "CoinLabel"
	coin_lbl.unique_name_in_owner = true
	coin_lbl.position = Vector2(46, 6)
	coin_lbl.text = "52,750"
	coin_lbl.add_theme_font_override("font", font_semi)
	coin_lbl.add_theme_font_size_override("font_size", 24)
	coin_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	curr_pill.add_child(coin_lbl)
	coin_lbl.owner = root
	
	# Divider (2x26)
	var div = ColorRect.new()
	div.position = Vector2(165, 9)
	div.size = Vector2(1.5, 26)
	div.color = Color(0.957, 0.957, 0.949, 0.6)
	curr_pill.add_child(div)
	div.owner = root
	
	# Gem Icon (28px)
	var gem_ico = TextureRect.new()
	gem_ico.position = Vector2(182, 8)
	gem_ico.size = Vector2(28, 28)
	gem_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem_ico.texture = load("res://assets/ui/icons/ico_gem.svg")
	curr_pill.add_child(gem_ico)
	gem_ico.owner = root
	
	# Gem Label
	var gem_lbl = Label.new()
	gem_lbl.name = "GemLabel"
	gem_lbl.unique_name_in_owner = true
	gem_lbl.position = Vector2(218, 6)
	gem_lbl.text = "120"
	gem_lbl.add_theme_font_override("font", font_semi)
	gem_lbl.add_theme_font_size_override("font_size", 24)
	gem_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	curr_pill.add_child(gem_lbl)
	gem_lbl.owner = root
	
	# Top Right Settings Gear Button (1851, 68) center -> (1831, 48)
	var gear_btn = TextureButton.new()
	gear_btn.name = "SettingsGearBtn"
	gear_btn.position = Vector2(1831, 48)
	gear_btn.size = Vector2(40, 40)
	gear_btn.ignore_texture_size = true
	gear_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	gear_btn.texture_normal = load("res://assets/ui/icons/ico_settings_gear.svg")
	root.add_child(gear_btn)
	gear_btn.owner = root
	
	# 4. NAVIGATION BUTTONS
	var skewed_script = load("res://scripts/ui/skewed_nav_button.gd")
	
	# PLAY button at (46, 304), size 511x101
	var play_b = Control.new()
	play_b.name = "PlayBtn"
	play_b.unique_name_in_owner = true
	play_b.set_script(skewed_script)
	play_b.position = Vector2(46, 304)
	play_b.size = Vector2(470, 96)
	play_b.set("is_play_button", true)
	play_b.set("button_text", "PLAY")
	play_b.set("icon_texture", load("res://assets/ui/icons/ico_play_flag.svg"))
	root.add_child(play_b)
	play_b.owner = root
	
	# 5 Nav buttons (x=57, width=460, height=80)
	var nav_configs = [
		{"name": "SettingsBtn", "text": "SETTINGS", "y": 425, "icon": "ico_settings_gear.svg"},
		{"name": "GarageBtn", "text": "GARAGE", "y": 520, "icon": "ico_garage_car.svg"},
		{"name": "TuningBtn", "text": "TUNING", "y": 614, "icon": "ico_tuning_wrench.svg"},
		{"name": "PaintShopBtn", "text": "PAINT SHOP", "y": 709, "icon": "ico_paint_spray.svg"},
		{"name": "ProfileBtn", "text": "PROFILE", "y": 799, "icon": "ico_profile_user.svg"}
	]
	
	for cfg in nav_configs:
		var btn = Control.new()
		btn.name = cfg["name"]
		btn.unique_name_in_owner = true
		btn.set_script(skewed_script)
		btn.position = Vector2(57, cfg["y"])
		btn.size = Vector2(460, 80)
		btn.set("is_play_button", false)
		btn.set("button_text", cfg["text"])
		btn.set("icon_texture", load("res://assets/ui/icons/" + cfg["icon"]))
		root.add_child(btn)
		btn.owner = root
		
	# 5. BOTTOM STRIP (0, 976), size 1920x64
	var bottom_strip = Panel.new()
	bottom_strip.name = "BottomStrip"
	bottom_strip.position = Vector2(0, 976)
	bottom_strip.size = Vector2(1920, 64)
	var bs_style = StyleBoxFlat.new()
	bs_style.bg_color = Color(0.082, 0.09, 0.114, 0.70) # #15171D @ 70%
	bottom_strip.add_theme_stylebox_override("panel", bs_style)
	root.add_child(bottom_strip)
	bottom_strip.owner = root
	
	# Info icon (32x32) at (48, 16)
	var info_ico = TextureRect.new()
	info_ico.position = Vector2(48, 16)
	info_ico.size = Vector2(32, 32)
	info_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_ico.texture = load("res://assets/ui/icons/ico_info.svg")
	bottom_strip.add_child(info_ico)
	info_ico.owner = root
	
	# Welcome Text
	var welcome_lbl = Label.new()
	welcome_lbl.name = "WelcomeLabel"
	welcome_lbl.position = Vector2(96, 17)
	welcome_lbl.text = "Welcome to the Racing World!"
	welcome_lbl.add_theme_font_override("font", font_reg)
	welcome_lbl.add_theme_font_size_override("font_size", 22)
	welcome_lbl.add_theme_color_override("font_color", Color(0.957, 0.957, 0.949, 0.85))
	bottom_strip.add_child(welcome_lbl)
	welcome_lbl.owner = root
	
	# ESC Keycap Pill + Back Text
	var esc_pill = Panel.new()
	esc_pill.position = Vector2(1536, 18)
	esc_pill.size = Vector2(50, 28)
	var key_style = StyleBoxFlat.new()
	key_style.bg_color = Color(0.12, 0.13, 0.16, 0.8)
	key_style.border_color = Color(0.957, 0.957, 0.949, 0.8)
	key_style.border_width_left = 1
	key_style.border_width_top = 1
	key_style.border_width_right = 1
	key_style.border_width_bottom = 1
	key_style.corner_radius_top_left = 3
	key_style.corner_radius_top_right = 3
	key_style.corner_radius_bottom_right = 3
	key_style.corner_radius_bottom_left = 3
	esc_pill.add_theme_stylebox_override("panel", key_style)
	bottom_strip.add_child(esc_pill)
	esc_pill.owner = root
	
	var esc_lbl = Label.new()
	esc_lbl.position = Vector2(0, 2)
	esc_lbl.size = Vector2(50, 26)
	esc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	esc_lbl.text = "ESC"
	esc_lbl.add_theme_font_override("font", font_bold)
	esc_lbl.add_theme_font_size_override("font_size", 16)
	esc_lbl.add_theme_color_override("font_color", Color(0.957, 0.957, 0.949, 1.0))
	esc_pill.add_child(esc_lbl)
	esc_lbl.owner = root
	
	var back_lbl = Label.new()
	back_lbl.position = Vector2(1598, 17)
	back_lbl.text = "Back"
	back_lbl.add_theme_font_override("font", font_reg)
	back_lbl.add_theme_font_size_override("font_size", 22)
	bottom_strip.add_child(back_lbl)
	back_lbl.owner = root
	
	# Divider
	var b_div = ColorRect.new()
	b_div.position = Vector2(1660, 18)
	b_div.size = Vector2(1.5, 28)
	b_div.color = Color(0.957, 0.957, 0.949, 0.5)
	bottom_strip.add_child(b_div)
	b_div.owner = root
	
	# ENTER Keycap Pill + Select Text
	var enter_pill = Panel.new()
	enter_pill.position = Vector2(1695, 18)
	enter_pill.size = Vector2(66, 28)
	enter_pill.add_theme_stylebox_override("panel", key_style)
	bottom_strip.add_child(enter_pill)
	enter_pill.owner = root
	
	var enter_lbl = Label.new()
	enter_lbl.position = Vector2(0, 2)
	enter_lbl.size = Vector2(66, 26)
	enter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter_lbl.text = "ENTER"
	enter_lbl.add_theme_font_override("font", font_bold)
	enter_lbl.add_theme_font_size_override("font_size", 16)
	enter_lbl.add_theme_color_override("font_color", Color(0.957, 0.957, 0.949, 1.0))
	enter_pill.add_child(enter_lbl)
	enter_lbl.owner = root
	
	var select_lbl = Label.new()
	select_lbl.position = Vector2(1775, 17)
	select_lbl.text = "Select"
	select_lbl.add_theme_font_override("font", font_reg)
	select_lbl.add_theme_font_size_override("font_size", 22)
	bottom_strip.add_child(select_lbl)
	select_lbl.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/ui/home_screen_ui.tscn")
	print("home_screen_ui.tscn built successfully!")
	quit()
