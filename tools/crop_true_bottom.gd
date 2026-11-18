@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Daily missions: text is around y=960, progress bar is y=1010-1026, bottom is y=1040
	# Top border is around y=950
	var dm = img.get_region(Rect2i(40, 946, 325, 96))
	dm.save_png("assets/ui/textures/missions_card_true.png")

	# Mail: y from 930 to 1042 (h=112), x from 360 to 480 (w=120)
	var ml = img.get_region(Rect2i(360, 930, 120, 112))
	ml.save_png("assets/ui/textures/mail_card_true.png")

	# News: y from 940 to 1042 (h=102), x from 605 to 1335 (w=730)
	var nw = img.get_region(Rect2i(605, 940, 730, 102))
	nw.save_png("assets/ui/textures/news_card_true.png")

	# Season pass: y from 930 to 1045 (h=115), x from 1515 to 1895 (w=380)
	var sp = img.get_region(Rect2i(1515, 930, 380, 115))
	sp.save_png("assets/ui/textures/season_card_true.png")

	print("Saved true bottom cards")
	quit(0)

