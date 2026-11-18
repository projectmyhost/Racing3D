@tool
extends SceneTree

func _init():
	var scene_path = "res://scenes/ui/home_screen_ui.tscn"
	var packed = load(scene_path) as PackedScene
	if not packed:
		quit(1)
		return
		
	var root = packed.instantiate()
	get_root().add_child(root)
	
	var hud = root.get_node("HUD")
	var pc = hud.get_node("ProfileCard")
	
	# Clear children of ProfileCard
	for c in pc.get_children():
		pc.remove_child(c)
		c.free()
		
	pc.custom_minimum_size = Vector2(512, 170.5)
	pc.offset_left = 40.0
	pc.offset_top = 24.0
	pc.offset_right = 552.0
	pc.offset_bottom = 194.5
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Empty StyleBox for ProfileCard
	var empty_style = StyleBoxEmpty.new()
	pc.add_theme_stylebox_override("panel", empty_style)
	
	# Background TextureRect
	var bg_tex = TextureRect.new()
	bg_tex.name = "CardBG"
	bg_tex.layout_mode = 1
	bg_tex.anchors_preset = Control.PRESET_FULL_RECT
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	pc.add_child(bg_tex)
	bg_tex.owner = root
	
	# Subtitle / Category
	var cat_lbl = Label.new()
	cat_lbl.name = "CategoryLabel"
	cat_lbl.text = "FIA SUPER LICENSE // CATEGORY S1"
	cat_lbl.offset_left = 134.0
	cat_lbl.offset_top = 22.0
	cat_lbl.offset_right = 350.0
	cat_lbl.offset_bottom = 38.0
	cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cat_lbl.add_theme_font_size_override("font_size", 10)
	cat_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.98, 0.85))
	pc.add_child(cat_lbl)
	cat_lbl.owner = root
	
	# Nickname
	var nick_lbl = Label.new()
	nick_lbl.name = "NicknameLabel"
	nick_lbl.text = "DiazRaditya"
	nick_lbl.offset_left = 134.0
	nick_lbl.offset_top = 44.0
	nick_lbl.offset_right = 360.0
	nick_lbl.offset_bottom = 82.0
	nick_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nick_lbl.add_theme_font_size_override("font_size", 28)
	nick_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	nick_lbl.add_theme_color_override("font_shadow_color", Color(0.04, 0.08, 0.22, 0.8))
	nick_lbl.add_theme_constant_override("shadow_offset_x", 1)
	nick_lbl.add_theme_constant_override("shadow_offset_y", 2)
	pc.add_child(nick_lbl)
	nick_lbl.owner = root
	nick_lbl.unique_name_in_owner = true
	
	# Subtag
	var sub_lbl = Label.new()
	sub_lbl.name = "SubtagLabel"
	sub_lbl.text = "PILOT ID #44-DR // RED BULL ACADEMY"
	sub_lbl.offset_left = 134.0
	sub_lbl.offset_top = 84.0
	sub_lbl.offset_right = 360.0
	sub_lbl.offset_bottom = 100.0
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.98, 0.85))
	pc.add_child(sub_lbl)
	sub_lbl.owner = root
	
	# LevelLabel inside golden badge
	var lvl_lbl = Label.new()
	lvl_lbl.name = "LevelLabel"
	lvl_lbl.text = "Lv. 0"
	lvl_lbl.offset_left = 405.0
	lvl_lbl.offset_top = 56.0
	lvl_lbl.offset_right = 475.0
	lvl_lbl.offset_bottom = 88.0
	lvl_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lvl_lbl.add_theme_font_size_override("font_size", 24)
	lvl_lbl.add_theme_color_override("font_color", Color(0.12, 0.16, 0.32, 1.0))
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(lvl_lbl)
	lvl_lbl.owner = root
	lvl_lbl.unique_name_in_owner = true
	
	# XPBar
	var xp_bar = ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.offset_left = 115.0
	xp_bar.offset_top = 114.0
	xp_bar.offset_right = 295.0
	xp_bar.offset_bottom = 134.0
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bar.show_percentage = false
	xp_bar.max_value = 500.0
	xp_bar.value = 0.0
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.06, 0.09, 0.20, 0.85)
	bar_bg.corner_radius_top_left = 8
	bar_bg.corner_radius_top_right = 8
	bar_bg.corner_radius_bottom_left = 8
	bar_bg.corner_radius_bottom_right = 8
	xp_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(1.0, 0.78, 0.14, 1.0)
	bar_fill.corner_radius_top_left = 8
	bar_fill.corner_radius_top_right = 8
	bar_fill.corner_radius_bottom_left = 8
	bar_fill.corner_radius_bottom_right = 8
	xp_bar.add_theme_stylebox_override("fill", bar_fill)
	pc.add_child(xp_bar)
	xp_bar.owner = root
	xp_bar.unique_name_in_owner = true
	
	# XPLabel
	var xp_lbl = Label.new()
	xp_lbl.name = "XPLabel"
	xp_lbl.text = "0 / 500 XP"
	xp_lbl.offset_left = 370.0
	xp_lbl.offset_top = 114.0
	xp_lbl.offset_right = 478.0
	xp_lbl.offset_bottom = 134.0
	xp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_lbl.add_theme_font_size_override("font_size", 13)
	xp_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 0.95))
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(xp_lbl)
	xp_lbl.owner = root
	xp_lbl.unique_name_in_owner = true
	
	# AvatarRect
	var av_rect = TextureRect.new()
	av_rect.name = "AvatarRect"
	av_rect.visible = false
	av_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(av_rect)
	av_rect.owner = root
	av_rect.unique_name_in_owner = true

	var new_packed = PackedScene.new()
	var pack_res = new_packed.pack(root)
	if pack_res == OK:
		ResourceSaver.save(new_packed, scene_path)
		print("SUCCESS: Packed and saved UI scene!")
	else:
		print("FAIL: pack returned ", pack_res)
	quit(0)
