@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Daily missions: y: 940 to 1026 (h=86), x: 45 to 365 (w=320)
	var dm = img.get_region(Rect2i(45, 940, 320, 86))
	dm.save_png("assets/ui/textures/missions_card_clean.png")

	# Mail: y: 924 to 1026 (h=102), x: 366 to 482 (w=116)
	var ml = img.get_region(Rect2i(366, 924, 116, 102))
	ml.save_png("assets/ui/textures/mail_card_clean.png")

	# News: y: 942 to 1026 (h=84), x: 605 to 1335 (w=730)
	var nw = img.get_region(Rect2i(605, 942, 730, 84))
	nw.save_png("assets/ui/textures/news_card_clean.png")

	# Season pass: y: 932 to 1036 (h=104), x: 1520 to 1896 (w=376)
	var sp = img.get_region(Rect2i(1520, 932, 376, 104))
	sp.save_png("assets/ui/textures/season_card_clean.png")

	print("Saved clean bottom cards")
	quit(0)

