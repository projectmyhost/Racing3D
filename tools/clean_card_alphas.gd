@tool
extends SceneTree

func _init():
	# 1. Event card: rectangle from x=2 to w-2, y=2 to h-2
	_clean_rect("assets/ui/textures/event_card_exact.png", "assets/ui/textures/event_card_ready.png", 3, 3, 3, 3)
	
	# 2. Friends card: rectangle
	_clean_rect("assets/ui/textures/friends_card_test_long.png", "assets/ui/textures/friends_card_ready.png", 2, 2, 2, 2)
	
	# 3. Season pass card: slanted left and right edges
	_clean_slanted("assets/ui/textures/season_card_full.png", "assets/ui/textures/season_card_ready.png", 14.0)

	# 4. Missions card: slanted left and right edges
	_clean_slanted("assets/ui/textures/missions_card_true.png", "assets/ui/textures/missions_card_ready.png", 14.0)

	# 5. Mail card: slanted edges
	_clean_slanted("assets/ui/textures/mail_card_true.png", "assets/ui/textures/mail_card_ready.png", 14.0)

	# 6. News banner: slanted edges
	_clean_slanted("assets/ui/textures/news_card_true.png", "assets/ui/textures/news_card_ready.png", 14.0)

	print("Cleaned all card alphas")
	quit(0)

func _clean_rect(src: String, dst: String, pad_l: int, pad_t: int, pad_r: int, pad_b: int) -> void:
	var img = Image.load_from_file(src)
	if not img: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			if x < pad_l or x >= w - pad_r or y < pad_t or y >= h - pad_b:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	img.save_png(dst)

func _clean_slanted(src: String, dst: String, skew: float) -> void:
	var img = Image.load_from_file(src)
	if not img: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		var lx = skew * (1.0 - float(y) / float(h)) + 2.0
		var rx = float(w) - skew * (float(y) / float(h)) - 3.0
		for x in range(w):
			if x < lx or x > rx or y < 3 or y >= h - 3:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	img.save_png(dst)

