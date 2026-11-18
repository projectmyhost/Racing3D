@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	img.convert(Image.FORMAT_RGBA8)

	# 1. Top Navigation Bar (HOME, CAREER, MULTIPLAYER, SHOP, COMMUNITY)
	# Bounds: x=586, y=36, w=735, h=52
	var top_bar = img.get_region(Rect2i(586, 36, 735, 52))
	# Mask top and bottom and slanted sides
	for y in range(top_bar.get_height()):
		var left_x = 14.0 * (1.0 - float(y) / float(top_bar.get_height()))
		var right_x = top_bar.get_width() - 14.0 * (float(y) / float(top_bar.get_height()))
		for x in range(top_bar.get_width()):
			if x < left_x or x > right_x:
				top_bar.set_pixel(x, y, Color(0, 0, 0, 0))
	top_bar.save_png("assets/ui/textures/top_nav_bar_clean.png")
	print("Saved top_nav_bar_clean.png")

	# 2. Currency Pill & Settings Gear & Notifications
	# Currency Pill: x=1345, y=34, w=456, h=52
	var cur_pill = img.get_region(Rect2i(1345, 34, 456, 52))
	for y in range(cur_pill.get_height()):
		for x in range(cur_pill.get_width()):
			if y < 1 or y >= cur_pill.get_height() - 1:
				if x < 4 or x > cur_pill.get_width() - 4:
					cur_pill.set_pixel(x, y, Color(0, 0, 0, 0))
	cur_pill.save_png("assets/ui/textures/currency_pill_clean.png")
	print("Saved currency_pill_clean.png")

	# Gear Hex Button: x=1812, y=26, w=74, h=74
	var gear_btn = img.get_region(Rect2i(1812, 26, 74, 74))
	gear_btn.save_png("assets/ui/textures/gear_btn_clean.png")
	print("Saved gear_btn_clean.png")

	# Notifications & MS: x=1576, y=94, w=290, h=38
	var notif_pill = img.get_region(Rect2i(1576, 94, 290, 38))
	notif_pill.save_png("assets/ui/textures/notif_ms_clean.png")
	print("Saved notif_ms_clean.png")

	# 3. Limited Time Event Card: x=1530, y=205, w=355, h=305
	var event_card = img.get_region(Rect2i(1530, 205, 355, 305))
	event_card.save_png("assets/ui/textures/event_card_clean.png")
	print("Saved event_card_clean.png")

	# 4. Online Friends Card: x=1530, y=530, w=355, h=260
	var friends_card = img.get_region(Rect2i(1530, 530, 355, 260))
	friends_card.save_png("assets/ui/textures/friends_card_clean.png")
	print("Saved friends_card_clean.png")

	# 5. Bottom: Daily Missions Card: x=45, y=938, w=310, h=72
	var missions_card = img.get_region(Rect2i(45, 938, 310, 72))
	for y in range(missions_card.get_height()):
		var left_x = 12.0 * (1.0 - float(y) / float(missions_card.get_height()))
		var right_x = missions_card.get_width() - 12.0 * (float(y) / float(missions_card.get_height()))
		for x in range(missions_card.get_width()):
			if x < left_x or x > right_x:
				missions_card.set_pixel(x, y, Color(0, 0, 0, 0))
	missions_card.save_png("assets/ui/textures/missions_card_clean.png")
	print("Saved missions_card_clean.png")

	# 6. Bottom: Mail Button: x=362, y=930, w=112, h=80
	var mail_card = img.get_region(Rect2i(362, 930, 112, 80))
	mail_card.save_png("assets/ui/textures/mail_card_clean.png")
	print("Saved mail_card_clean.png")

	# 7. Bottom: News & Updates: x=605, y=928, w=720, h=82
	var news_card = img.get_region(Rect2i(605, 928, 720, 82))
	news_card.save_png("assets/ui/textures/news_card_clean.png")
	print("Saved news_card_clean.png")

	# 8. Bottom: Season Pass Card: x=1518, y=915, w=375, h=95
	var season_card = img.get_region(Rect2i(1518, 915, 375, 95))
	season_card.save_png("assets/ui/textures/season_card_clean.png")
	print("Saved season_card_clean.png")

	# 9. Bottom: Version Label: x=1430, y=996, w=85, h=25
	var ver_label = img.get_region(Rect2i(1430, 996, 85, 25))
	ver_label.save_png("assets/ui/textures/ver_label_clean.png")
	print("Saved ver_label_clean.png")

	quit(0)

