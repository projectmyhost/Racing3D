@tool
extends SceneTree

func _init():
	var scene_path = "res://scenes/race/RaceTrack3D.tscn"
	var packed = load(scene_path) as PackedScene
	if not packed:
		print("FAIL: cannot load RaceTrack3D.tscn")
		quit(1)
		return
		
	var root = packed.instantiate()
	get_root().add_child(root)
	
	var hud_root = root.get_node("HUD/HUDRoot")
	var fp = hud_root.get_node("FinishPanel")
	
	# Clear existing children of FinishPanel
	for c in fp.get_children():
		fp.remove_child(c)
		c.free()
		
	fp.custom_minimum_size = Vector2(520, 360)
	fp.offset_left = -260.0
	fp.offset_top = -180.0
	fp.offset_right = 260.0
	fp.offset_bottom = 180.0
	
	# Dark motorsport styled panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.08, 0.16, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.98, 0.76, 0.12, 0.85)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	fp.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	fp.add_child(margin)
	margin.owner = root
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	vbox.owner = root
	
	var title = Label.new()
	title.name = "FinishTitle"
	title.unique_name_in_owner = true
	title.text = "VICTORY // GRAND PRIX WINNER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(title)
	title.owner = root
	
	# Stars label
	var stars_lbl = Label.new()
	stars_lbl.name = "FinishStars"
	stars_lbl.unique_name_in_owner = true
	stars_lbl.text = "★ ★ ★"
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", 42)
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.15, 1.0))
	vbox.add_child(stars_lbl)
	stars_lbl.owner = root
	
	# Rank label
	var rank_lbl = Label.new()
	rank_lbl.name = "FinishRank"
	rank_lbl.unique_name_in_owner = true
	rank_lbl.text = "S RANK // SPEED DEMON"
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 16)
	rank_lbl.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0, 1.0))
	vbox.add_child(rank_lbl)
	rank_lbl.owner = root
	
	# Stats
	var stats = Label.new()
	stats.name = "FinishStats"
	stats.unique_name_in_owner = true
	stats.text = "TOTAL TIME: 00:42.15\nBEST LAP: 00:13.88"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94, 0.9))
	vbox.add_child(stats)
	stats.owner = root
	
	# Rewards
	var rewards = Label.new()
	rewards.name = "FinishRewards"
	rewards.unique_name_in_owner = true
	rewards.text = "REWARDS: +250 XP  |  +5,000 COINS"
	rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards.add_theme_font_size_override("font_size", 16)
	rewards.add_theme_color_override("font_color", Color(0.98, 0.80, 0.18, 1.0))
	vbox.add_child(rewards)
	rewards.owner = root
	
	# Buttons HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	hbox.owner = root
	
	var play_again_btn = Button.new()
	play_again_btn.name = "PlayAgainBtn"
	play_again_btn.unique_name_in_owner = true
	play_again_btn.text = "PLAY AGAIN"
	play_again_btn.custom_minimum_size = Vector2(170, 44)
	hbox.add_child(play_again_btn)
	play_again_btn.owner = root
	
	var home_btn = Button.new()
	home_btn.name = "FinishHomeBtn"
	home_btn.unique_name_in_owner = true
	home_btn.text = "RETURN TO MENU"
	home_btn.custom_minimum_size = Vector2(170, 44)
	hbox.add_child(home_btn)
	home_btn.owner = root

	var new_packed = PackedScene.new()
	var pack_res = new_packed.pack(root)
	if pack_res == OK:
		ResourceSaver.save(new_packed, scene_path)
		print("SUCCESS: Upgraded FinishPanel in RaceTrack3D.tscn!")
	else:
		print("FAIL: pack error ", pack_res)
	quit(0)

